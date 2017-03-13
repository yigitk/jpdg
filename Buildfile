#!/usr/bin/env ruby

require 'rubygems'
require 'buildr'

## repositories.remote << 'http://mirrors.ibiblio.org/pub/mirrors/maven2/'
repositories.remote << 'http://repo1.maven.org/'
## repositories.remote << 'https://oss.sonatype.org/content/repositories/releases/'
repositories.remote << 'http://central.maven.org/maven2/'

require 'rake'
Java.load
require "antwrap"


## if File::exists?('parsemis/Buildfile')
##   pwd = Dir.pwd
##   Dir.chdir File::join(pwd, 'parsemis')
##   load "./Buildfile"
##   puts project('parsemis').base_dir
##   Dir.chdir pwd
## end

Project.local_task :run


baksmali_url = 'https://bitbucket.org/JesusFreke/smali/downloads/baksmali-2.0.2.jar'
baksmali_2 = "baksmali:baksmali:jar:2.0.2"
download(artifact(baksmali_2)=>baksmali_url)

smali_url = 'https://bitbucket.org/JesusFreke/smali/downloads/smali-2.0.2.jar'
smali_2 = "smali:smali:jar:2.0.2"
download(artifact(smali_2)=>smali_url)

heros_libs = [
  'com.google.guava:guava:jar:14.0.1',
  'org.slf4j:slf4j-api:jar:1.7.5',
  'org.slf4j:slf4j-simple:jar:1.7.5',
]

jasmin_libs = [
  'libs/java-cup-11a.jar',
]

soot_libs = [
  'libs/util-2.0.6-dev.jar',
  'libs/dexlib2-2.0.6-dev.jar',
  'soot/libs/polyglot.jar',
  'soot/libs/AXMLPrinter2.jar',
  'org.apache.commons:commons-lang3:jar:3.4',
  'org.ow2.asm:asm-debug-all:jar:5.0.3',
  'com.google.guava:guava:jar:18.0',
  baksmali_2,
] + jasmin_libs

soot_test_libs = [
  'org.hamcrest:hamcrest-all:jar:1.3',
  'org.mockito:mockito-all:jar:1.10.8',
  #'org.powermock:powermock-mockito-release-full:jar:1.6.1',

  'org.powermock:powermock-module-junit4:jar:1.6.1',
  'org.powermock:powermock-module-junit4-common:jar:1.6.1',
  'org.powermock:powermock-api-mockito:jar:1.6.1',
  'org.powermock:powermock-reflect:jar:1.6.1',
  'org.powermock:powermock-core:jar:1.6.1',
  'org.powermock:powermock-api-support:jar:1.6.1',

  'org.javassist:javassist:jar:3.18.2-GA',
]

ant_lib = [
  'org.apache.ant:ant:jar:1.7.0',
]

parsemis_libs = [
  'antlr:antlr:jar:2.7.6',
  'org.prefuse:prefuse:jar:beta-20071021',
]

jpdg_libs = [
  #'org.javatuples:javatuples:jar:1.2',
  #'com.cedarsoftware:json-io:jar:2.4.1',
  'com.google.code.gson:gson:jar:2.2.4',
  'org.apache.commons:commons-io:jar:1.3.2',
  'commons-codec:commons-codec:jar:1.4',
  'commons-lang:commons-lang:jar:2.6',
  'commons-cli:commons-cli:jar:1.2',
]

jpdg_extra = [
  'libs/dexlib2-2.0.6-dev.jar',
]

task :jas do
  jas = ant("jas") do |ant|
    ant.mkdir(dir:"jasmin/target")
    ant.mkdir(dir:"jasmin/target/classes")
    ant.javac(
      destdir:"jasmin/target/classes",
      optimize:"true",
      source:"1.5",
      target:"1.5",
    ) do |ant|
      ant.src(path:"jasmin/lib/jas/src/jas")
    end
  end
  ant("autogen_compile") do |ant|
    ant.javac(
      destdir:"jasmin/target/classes",
      classpath:"jasmin/target/classes",
      optimize:"true",
      source:"1.5",
      target:"1.5",
    ) do |ant|
      ant.src(path:"jasmin/lib/jas/src/scm/autogen")
    end
  end
  ant("autogen_run") do |ant|
    ant.mkdir(dir:"jasmin/target/generated")
    ant.mkdir(dir:"jasmin/target/generated/scm")
    ant.java(
      classname:"autogen",
      classpath:"jasmin/target/classes",
      dir:"jasmin/target/generated/scm",
      fork:true,
    )
  end
  ant("autogen_compile") do |ant|
    ant.javac(
      destdir:"jasmin/target/classes",
      classpath:"jasmin/target/classes",
      optimize:"true",
      source:"1.5",
      target:"1.5",
    ) do |ant|
      ant.src(path:"jasmin/lib/jas/src/scm")
      ant.src(path:"jasmin/target/generated/scm")
    end
  end
end

jpdg_layout = Layout.new
jpdg_layout[:source] = "source"

define 'jpdg', layout: jpdg_layout do |soot|
  project.version = 'git-master'
  run.using main: ['edu.cwru.jpdg.JPDG']
  package(:jar).with(:manifest => {
    'Main-Class'=>'edu.cwru.jpdg.JPDG'
  }).merge(
    [ 'libs/soot.jar' ] + jpdg_libs + jpdg_extra
  )
  compile.with [ 'libs/soot.jar' ] + jpdg_libs
  test_libs = [
     'org.hamcrest:hamcrest-all:jar:1.3',
  ]
  test.with test_libs
  test.using :java_args => ['-ea']
  task :export_libs do |t|
    for lib in jpdg_libs
      artifact(lib).invoke
    end
    for lib in test_libs
      artifact(lib).invoke
    end
    mkdir_p _("libs/ext")
    lib_paths = Array.new(project.compile.dependencies).reject do |t|
      ## remove dependencies which are not downloaded artifacts
      t.class != Buildr::Artifact
    end .collect do |t|
      t.to_s
    end
    cp lib_paths, _("libs/ext")
    test_paths = Array.new(project.test.dependencies).reject do |t|
      ## remove dependencies which are not downloaded artifacts
      t.class != Buildr::Artifact
    end .collect do |t|
      t.to_s
    end
    cp test_paths, _("libs/ext")
  end
end


jasmin_layout = Layout.new
jasmin_layout[:source, :main, :java] = "src"
jasmin_layout[:target,] = "target"
jasmin_layout[:target, :main] = "target/main"
jasmin_layout[:target, :main, :classes] = "target/main/classes"


define 'jasmin', base_dir: "jasmin", layout: jasmin_layout do
  project.version = 'git-master'
  mkdir_p _('target/classes')
  compile.enhance([:jas])
  compile.with jasmin_libs + [_('target/classes')]
  compile.options.target = '1.5'
  compile.options.source = '1.5'
  package(:jar)
end

def git_commit(dir)
  commit = `git --git-dir='#{dir}' rev-parse HEAD`.strip()
  puts "the commit = " + commit
  return commit
end

jasmin_jar = File::join(project('jpdg').base_dir, 'libs', 'jasmin.jar')

task jasmin_jar do
  if File::exists?('jasmin-version') and File::exists?(jasmin_jar)
    f = File::open('jasmin-version')
    built_commit = f.read().strip()
    f.close()
  else
    build_commit = 'none'
  end
  git_dir = File::join(project('jpdg').base_dir, '.git', 'modules', 'jasmin')
  cur_commit = git_commit(git_dir)
  if built_commit != cur_commit
      project('jasmin')::task('package').invoke
      cp File::join(project('jasmin').base_dir, 'target', 'jasmin-git-master.jar'), jasmin_jar
      f = File::open('jasmin-version', 'w')
      f.write(cur_commit)
      f.close()
  end
end

#parsemis_layout = Layout.new
#parsemis_layout[:source, :main, :java] = "src"
##parsemis_layout[:target,] = "target"
##parsemis_layout[:target, :main] = "target/main"
##parsemis_layout[:target, :main, :classes] = "target/main/classes"


#define 'parsemis', base_dir: "parsemis", layout: parsemis_layout do
  #project.version = 'git-master'
  #mkdir_p _('target/classes')
  #compile.with parsemis_libs
  ##compile.options.target = '1.5'
  ##compile.options.source = '1.5'
  #package(:jar)
#end

heros_layout = Layout.new
heros_layout[:source, :main, :java] = "src"
heros_layout[:target,] = "target"
heros_layout[:target, :main] = "target/main"
heros_layout[:target, :main, :classes] = "target/main/classes"

define 'heros', base_dir: "heros", layout: heros_layout do
  project.version = 'git-master'
  package(:jar)
  compile.with heros_libs
  compile.using :lint => 'unchecked', :target => '1.5', :source => '1.5'
  test.with 'org.hamcrest:hamcrest-all:jar:1.3'
  test.using :java_args => ['-ea']
end

soot_layout = Layout.new
soot_layout[:source, :main, :java] = "src"
soot_layout[:source, :test, :java] = "tests"

define 'soot', base_dir: "soot", layout: soot_layout do |soot|
  project.version = 'git-master'
  package(:jar).with(:manifest => {
    'Main-Class'=>'soot.Main'
  }).merge(
    soot_libs + heros_libs + jasmin_libs + [ 'libs/jasmin.jar', project('heros') ]
  )
  compile.with soot_libs + ant_lib + jasmin_libs + [ 'libs/jasmin.jar', project('heros') ]
  compile.using :lint => 'none'
  compile.from [
    "soot/generated/singletons",
    "soot/generated/options",
    "soot/generated/sablecc",
    "soot/generated/jastadd",
  ]
  test.with soot_test_libs
  test.using :java_args => ['-ea']

  mkdir_p _("target/main/classes/soot/baf/toolkits/base/")
  cp _("src/soot/baf/toolkits/base/peephole.dat"), _("target/main/classes/soot/baf/toolkits/base/")

  mkdir_p _("target/main/classes/soot/jimple/parser/parser/")
  cp _("generated/sablecc/soot/jimple/parser/parser/parser.dat"), _("target/main/classes/soot/jimple/parser/parser/parser.dat")
  mkdir_p _("target/main/classes/soot/jimple/parser/lexer/")
  cp _("generated/sablecc/soot/jimple/parser/lexer/lexer.dat"), _("target/main/classes/soot/jimple/parser/lexer/lexer.dat")
end

