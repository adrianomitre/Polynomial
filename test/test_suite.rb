#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__))

class String
  def same_file?(other)
    File.expand_path(self) == File.expand_path(other)
  end
end

candidates = Dir.glob('test_*.rb')
to_exclude = [__FILE__, 'test_helper.rb']

test_files = candidates.reject {|f| to_exclude.any? {|ex| f.same_file?(ex) } }

test_files.each do |tf|
  system "ruby #{tf}"
end

