require 'polynomial'

AUTHOR = 'Adriano Mitre'  # can also be an array of Authors
EMAIL = "adriano@mitre.com.br"
DESCRIPTION = <<EOS
EOS
GEM_NAME = 'polynomial' # what ppl will type to install your gem
RUBYFORGE_PROJECT = 'polynomial' # The unix name for your project
HOMEPATH = "http://adrianomitre.github.com/Polynomial/website/index.html"
DOWNLOAD_PATH = "https://github.com/adrianomitre/Polynomial/archives/master"
EXTRA_DEPENDENCIES = [
#  ['activesupport', '>= 1.3.1']
]    # An array of rubygem dependencies [name, version]

@config_file = "~/.rubyforge/user-config.yml"
@config = nil
RUBYFORGE_USERNAME = "unknown"
def rubyforge_username
  unless @config
    begin
      @config = YAML.load(File.read(File.expand_path(@config_file)))
    rescue
      puts <<-EOS
ERROR: No rubyforge config file found: #{@config_file}
Run 'rubyforge setup' to prepare your env for access to Rubyforge
 - See http://newgem.rubyforge.org/rubyforge.html for more details
      EOS
      exit
    end
  end
  RUBYFORGE_USERNAME.replace @config["username"]
end


REV = nil
# UNCOMMENT IF REQUIRED:
# REV = YAML.load(`svn info`)['Revision']
VERS = Polynomial::VERSION
RDOC_OPTS = ['--quiet', '--title', 'polynomial documentation',
    "--opname", "index.html",
    "--line-numbers",
    "--main", "README",
    "--inline-source"]

class Hoe
  def extra_deps
    @extra_deps.reject! { |x| Array(x).first == 'hoe' }
    @extra_deps
  end
end

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec(GEM_NAME) do |p|
  p.developer(AUTHOR, EMAIL)
  p.description = DESCRIPTION
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.version = VERS
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/test_*.rb", "test/**/tc_*.rb"]
  p.clean_globs |= ['**/.*.sw?', '*.gem', '.config', '**/.DS_Store']  #An array of file patterns to delete on clean.

  p.readme_file = 'README.rdoc'
  p.extra_rdoc_files << 'README.rdoc'

  #~ p.files = FileList["{tests,lib}/**/*"].exclude("rdoc").to_a 


  # == Optional
  p.changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  #p.extra_deps = EXTRA_DEPENDENCIES

    #p.spec_extras = {}    # A hash of extra values to set in the gemspec.
  p.spec_extras = {:files => FileList["{tests,lib}/**/*"].exclude("rdoc").to_a}
  end

CHANGES = $hoe.paragraphs_of('History.txt', 0..1).join("\\n\\n")
PATH    = (RUBYFORGE_PROJECT == GEM_NAME) ? RUBYFORGE_PROJECT : "#{RUBYFORGE_PROJECT}/#{GEM_NAME}"
$hoe.remote_rdoc_dir = File.join(PATH.gsub(/^#{RUBYFORGE_PROJECT}\/?/,''), 'rdoc')
$hoe.rsync_args = '-av --delete --ignore-errors'
$hoe.spec.post_install_message = File.open(File.dirname(__FILE__) + "/../PostInstall.txt").read rescue ""
