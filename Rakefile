
require 'rubygems'

require 'rake'
require 'rake/clean'
#require 'rake/packagetask'
#require 'rake/gempackagetask'
#require 'rake/rdoctask'
require 'rake/testtask'


RUOTE_LIB = "~/ruote/lib"
#SINATRA_LIB = "~/sinatra/lib"

#
# tasks

CLEAN.include 'work_test', 'work_development', 'log', 'tmp'

#task :default => [ :clean, :repackage ]


#
# TESTING

#
#   rake test
#
Rake::TestTask.new(:test) do |t|

  t.libs << 'test'
  t.libs << 'conf'
  t.libs << 'vendor'
  t.libs << RUOTE_LIB
  #t.libs << SINATRA_LIB
  t.test_files = FileList['test/test.rb']
  t.verbose = true
end


#
# other tasks

load 'tasks/ruote.rake'
load 'tasks/mysql.rake'

