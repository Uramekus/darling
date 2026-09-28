#!/usr/bin/env python3
"""Execute LSGetApplicationForInfo's extension SQL against the real schema.

This covers unknown type/creator and kLSRolesAll, not FMDB, FSRef creation,
registration, or LaunchServices runtime integration. Python's sqlite3 suffices.
An optional source argument supports running against the unchanged baseline.
"""
import pathlib
import re
import sqlite3
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LS = ROOT / "src/frameworks/CoreServices/src/LaunchServices"
SOURCE = pathlib.Path(sys.argv.pop(1)) if len(sys.argv) > 1 else LS / "LSInfo.m"
function = SOURCE.read_text().split("LSGetApplicationForInfo(", 1)[1].split(
    "CFURLRef LSCopyDefaultApplicationURLForContentType", 1
)[0]


def literals(text):
    return "".join(re.findall(r'@"([^"\n]*)"', text))


base = re.search(r'NSString\* query = (@"[^"\n]*");', function).group(1)
extension = re.search(
    r'query = \[query stringByAppendingFormat:(.*?),\s*escaped, escaped\];',
    function, re.S,
).group(1)
ordering = re.search(
    r'query = \[query stringByAppendingString:(.*?)\];', function, re.S
).group(1)
QUERY = literals(base) + literals(extension) + literals(ordering)
assert QUERY.count("%@") == 2


class ExtensionQuery(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        self.db.execute("PRAGMA foreign_keys=ON")
        self.db.executescript((LS / "launchservicesd/schema.sql").read_text())

    def document(self, ident, cls, rank="Default", package="APPL"):
        self.db.execute(
            "INSERT INTO bundle(id,path,bundle_id,checksum,package_type) VALUES(?,?,?,?,?)",
            (ident, f"/Applications/Fixture{ident}.app", f"test.fixture{ident}", 1, package),
        )
        self.db.execute(
            "INSERT INTO app_doc(id,bundle,class,role,rank) VALUES(?,?,?,?,?)",
            (ident, ident, cls, "Editor", rank),
        )

    def extension(self, ident, extension):
        self.db.execute("INSERT INTO app_doc_extension(doc,extension) VALUES(?,?)", (ident, extension))

    def lookup(self, extension):
        query = QUERY.replace("%@", extension.replace("'", "''"))
        return [row[0] for row in self.db.execute(query)]

    def test_class_name_is_not_a_document_id(self):
        self.document(17, "FixtureDocument")
        self.extension(17, "fixture")
        self.assertEqual(self.lookup("fixture"), ["/Applications/Fixture17.app"])
        self.assertEqual(self.lookup("unknown"), [])

    def test_document_class_is_optional(self):
        self.document(18, None)
        self.extension(18, "no-class")
        self.assertEqual(self.lookup("no-class"), ["/Applications/Fixture18.app"])

    def test_numeric_class_must_not_match_another_document(self):
        self.document(19, "OtherDocument")
        self.document(20, "19", rank="Owner")
        self.extension(19, "fixture")
        self.assertEqual(self.lookup("fixture"), ["/Applications/Fixture19.app"])

    def test_rank_order_and_application_filter(self):
        for ident, rank in [(21, "Alternate"), (22, "Owner"), (23, "Default")]:
            self.document(ident, "FixtureDocument", rank=rank)
            self.extension(ident, "fixture")
        self.document(24, "FixtureDocument", rank="Owner", package="BNDL")
        self.extension(24, "fixture")
        self.assertEqual(self.lookup("fixture"), [f"/Applications/Fixture{i}.app" for i in (22, 23, 21)])

    def test_uti_extension_route_remains_available(self):
        self.document(25, "FixtureDocument")
        self.db.execute("INSERT INTO uti(id,type_identifier,bundle) VALUES(1,'test.fixture',25)")
        self.db.execute("INSERT INTO uti_tag(uti,tag,value) VALUES(1,'public.filename-extension','uti-fixture')")
        self.db.execute("INSERT INTO app_doc_uti(doc,uti) VALUES(25,'test.fixture')")
        self.assertEqual(self.lookup("uti-fixture"), ["/Applications/Fixture25.app"])


unittest.main()
