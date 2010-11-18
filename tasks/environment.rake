task :ruby_env do
  RUBY_APP = if RUBY_PLATFORM =~ /java/
    "jruby"
  else
    "ruby"
  end unless defined? RUBY_APP
end

task :clean_rbc do
  cmd = %q[find -regex '^.*\.rbc$' -exec rm '{}' \;]
  puts(cmd)
  system(cmd)
end

