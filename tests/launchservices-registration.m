// Real CFBundle + FMDB/SQLite registration integration; run in a disposable prefix.
#include "../src/frameworks/CoreServices/src/LaunchServices/launchservicesd/LSBundle.m"
#define main registration_main
#include "../src/frameworks/CoreServices/src/LaunchServices/launchservicesd/launchservicesd.m"
#undef main
#include <assert.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

static NSString* makeBundle(const char* name) {
    NSString* path = [NSString stringWithFormat:@"/tmp/%s.app",name];
    assert(mkdir([path fileSystemRepresentation],0700)==0);
    NSString* contents = [path stringByAppendingPathComponent:@"Contents"];
    assert(mkdir([contents fileSystemRepresentation],0700)==0);
    NSString* plist = [contents stringByAppendingPathComponent:@"Info.plist"];
    FILE* file = fopen([plist fileSystemRepresentation],"w"); assert(file);
    fprintf(file,"<?xml version=\"1.0\"?><plist version=\"1.0\"><dict>"
        "<key>CFBundleIdentifier</key><string>org.darling.registration.%s</string>"
        "<key>CFBundleExecutable</key><string>fixture</string>"
        "<key>CFBundleDocumentTypes</key><array><dict>"
        "<key>CFBundleTypeName</key><string>Fixture</string>"
        "<key>CFBundleTypeRole</key><string>Editor</string>"
        "<key>CFBundleTypeExtensions</key><array><string>fixture</string></array>"
        "</dict><dict><key>CFBundleTypeName</key><string>UTI Fixture</string>"
        "<key>LSItemContentTypes</key><array><string>org.darling.fixture</string></array>"
        "</dict><dict><key>CFBundleTypeMIMETypes</key><array><string>application/x-fixture</string></array>"
        "</dict></array>"
        "<key>UTExportedTypeDeclarations</key><array><dict>"
        "<key>UTTypeIdentifier</key><string>org.darling.fixture</string>"
        "<key>UTTypeDescription</key><string>Fixture type</string>"
        "<key>UTTypeConformsTo</key><string>public.data</string>"
        "<key>UTTypeIconFile</key><string>fixture.icns</string>"
        "<key>UTTypeTagSpecification</key><dict><key>public.filename-extension</key><string>fixture</string></dict>"
        "</dict></array>"
        "<key>CFBundleURLTypes</key><array><dict><key>CFBundleURLName</key><string>Fixture URL</string>"
        "<key>CFBundleURLSchemes</key><array><string>fixture</string></array></dict></array>"
        "</dict></plist>",name);
    assert(fclose(file)==0);
    file=fopen([[contents stringByAppendingPathComponent:@"PkgInfo"] fileSystemRepresentation],"w");
    assert(file && fwrite("APPLTst!",1,8,file)==8 && fclose(file)==0);
    return path;
}
static int countRows(NSString* table) {
    FMResultSet* result=[g_database executeQuery:[NSString stringWithFormat:@"select count(*) as n from %@",table]];
    assert(result && [result next]);
    int count=[result intForColumn:@"n"]; [result close]; return count;
}
int main(void) {
    @autoreleasepool {
        const char* directories[]={"/tmp","/private","/private/var","/private/var/db"};
        for (unsigned i=0;i<sizeof(directories)/sizeof(*directories);++i)
            assert(mkdir(directories[i],0700)==0 || errno==EEXIST);
        assert(![LSBundle registerBundleAtPath:nil]);
        assert(![LSBundle registerBundleAtPath:@"/no-such-registration-bundle.app"]);
        const char* badArgs[]={"launchservicesd","--register"};
        assert(registration_main(2,badArgs)==2);
        NSString* path=makeBundle("registration-success");
        int before=countRows(@"bundle"), docs=countRows(@"app_doc");
        assert([LSBundle registerBundleAtPath:path]);
        assert(countRows(@"bundle")==before+1 && countRows(@"app_doc")==docs+3);
        const char* successArgs[]={"launchservicesd","--register",[path fileSystemRepresentation]};
        assert(registration_main(3,successArgs)==0);
        FMResultSet* row=[g_database executeQuery:@"select package_type,creator from bundle where path=?",path];
        assert([row next]);
        assert([[row stringForColumn:@"package_type"] isEqual:@"APPL"]);
        assert([[row stringForColumn:@"creator"] isEqual:@"Tst!"]);
        [row close];
        assert([LSBundle registerBundleAtPath:path]);
        assert(countRows(@"bundle")==before+1 && countRows(@"app_doc")==docs+3);
        NSArray* tables=@[@"bundle",@"uti",@"uti_conforms",@"uti_icon",@"uti_tag",
            @"app_doc",@"app_doc_uti",@"app_doc_extension",@"app_doc_mime",@"bundle_url_type",@"bundle_url_type_scheme"];
        unsigned iteration=0;
        for (NSString* table in tables) {
            NSMutableArray* counts=[NSMutableArray array];
            for (NSString* observed in tables) [counts addObject:@(countRows(observed))];
            NSString* trigger=[NSString stringWithFormat:@"create temp trigger fail_registration before insert on %@ begin select raise(ABORT,'fixture failure'); end",table];
            assert([g_database executeUpdate:trigger]);
            NSString* name=[NSString stringWithFormat:@"registration-rollback-%u",iteration++];
            NSString* failedPath=makeBundle([name UTF8String]);
            const char* failureArgs[]={"launchservicesd","--register",[failedPath fileSystemRepresentation]};
            assert(registration_main(3,failureArgs)==1);
            for (unsigned i=0;i<[tables count];++i)
                assert(countRows([tables objectAtIndex:i])==[[counts objectAtIndex:i] intValue]);
            assert([g_database executeUpdate:@"drop trigger fail_registration"]);
            assert([LSBundle registerBundleAtPath:failedPath]);
            assert(countRows(@"bundle")==before+1+(int)iteration);
        }
        // Exercise existing-UTI updates directly inside a transaction, then
        // roll back so the bundle checksum and original fixture stay coherent.
        CFBundleRef original=CFBundleCreate(NULL,(CFURLRef)[NSURL fileURLWithPath:path isDirectory:YES]);
        assert(original);
        LSBundle* entry=[[[LSBundle alloc] initWithBundle:original] autorelease];
        CFRelease(original);
        NSArray* updated=@[@{(NSString*)kUTTypeIdentifierKey:@"org.darling.fixture",
            (NSString*)kUTTypeDescriptionKey:@"Updated fixture description"}];
        BOOL needed=YES;
        assert([g_database beginTransaction] && [entry setupBundleID:&needed] && !needed);
        assert([entry processUTIs:updated]);
        NSNumber* bundleID=@(entry.bundleId);
        row=[g_database executeQuery:@"select description from uti where bundle=?",bundleID];
        assert([row next] && [[row stringForColumn:@"description"] isEqual:@"Updated fixture description"]);
        [row close];
        assert([entry processUTIs:nil]);
        row=[g_database executeQuery:@"select count(*) as n from uti where bundle=?",bundleID];
        assert([row next] && [row intForColumn:@"n"]==0); [row close];
        assert([g_database rollback]);
        assert([g_database executeUpdate:@"create temp trigger fail_uti_update before update on uti begin select raise(ABORT,'update failure'); end"]);
        assert([g_database beginTransaction] && [entry setupBundleID:&needed]);
        assert(![entry processUTIs:updated]);
        assert([g_database rollback]);
        assert([g_database executeUpdate:@"drop trigger fail_uti_update"]);
        row=[g_database executeQuery:@"select description from uti where bundle=?",bundleID];
        assert([row next] && [[row stringForColumn:@"description"] isEqual:@"Fixture type"]);
        [row close];
        puts("PASS existing UTI description update, removed declarations and failed-update rollback");
        puts("PASS registration, PkgInfo metadata, unchanged success, SQLite rollback and retry");
    }
}
