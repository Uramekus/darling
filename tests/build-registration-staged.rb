#!/usr/bin/env ruby
# Reuse an existing stage's compiler/linker recipes without modifying its files.
require 'open3'
require 'shellwords'
require 'tmpdir'
build, source = ARGV.map { |path| File.realpath(path) }
abort 'usage: ruby tests/build-registration-staged.rb STAGE_BUILD LOCAL_SOURCE' unless build && source
target='src/frameworks/CoreServices/src/LaunchServices/launchservicesd/launchservicesd'
output,status=Open3.capture2('ninja','-C',build,'-t','commands',target)
abort 'recipe lookup failed' unless status.success?
compile=output.lines.find { |line| line.include?(' -c ') && line.include?('/LSBundle.m') }
abort 'compile recipe missing' unless compile
remap=lambda { |arg| arg.gsub('/work/source',source).gsub('/work/build',build) }
dir=Dir.mktmpdir('launchservices-registration-')
args=Shellwords.split(compile.split(' -MD ').first).map(&remap)
system(*args,'-c',File.join(__dir__,'launchservices-registration.m'),'-o',"#{dir}/probe.o",exception:true)
link=output.lines.last
abort 'unexpected link recipe' unless link.start_with?(': && ') && link.strip.end_with?(' && :')
args=Shellwords.split(link.sub(/\A: && /,'').sub(/ && :\s*$/,'')).map(&remap)
args.reject! { |arg| arg.start_with?(target.sub(%r{/launchservicesd$},'/CMakeFiles/launchservicesd.dir/')) && arg.end_with?('.o') }
args.map! { |arg| arg==target ? "#{dir}/probe" : arg }
system(*args,"#{dir}/probe.o",chdir:build,exception:true)
puts "artifact=#{dir}/probe"
