require 'spec_helper'

describe 'middleman helpers' do

  include_context 'tmp_dirs'

  before do
    FileUtils.cp_r File.join('master_middleman/.'), tmpdir
    FileUtils.mkdir_p source_dir
  end

  let(:source_dir) {File.join(tmpdir, 'source')}

  def write_markdown_source_file(path_under_source_dir, title, content = nil)
    full_path = File.join(source_dir, path_under_source_dir)
    full_pathname = Pathname.new(full_path)
    FileUtils.mkdir_p full_pathname.dirname
    final_content = "---\ntitle: #{title}\n---\n#{content}"
    File.open(full_path, 'w') {|f| f.write(final_content)}
  end

  def run_middleman
    # awful hacks to eliminate the impact of global state in middleman. when will it end?
    Middleman::Cli::Build.instance_variable_set(:@_shared_instance, nil)
    ENV["MM_ROOT"] = tmpdir

    Dir.chdir(tmpdir) do
      build_command = Middleman::Cli::Build.new [], {}, {}
      build_command.invoke :build, [], {'instrument' => 'false'}
    end
  end

  describe '#trail_nav' do
    context 'when invoked in the top-level index file' do
      before do
        write_markdown_source_file 'index.md.erb', 'dogs'
      end

      it 'displays nothing' do
        run_middleman
        output = File.read File.join(tmpdir, 'build', 'index.html')
        expect(output).to be_empty
      end
    end

    context 'when invoked in an index file in a sub-dir' do
      before do
        write_markdown_source_file 'index.md.erb', 'Dogs'
        write_markdown_source_file File.join('sub-dir', 'index.md.erb'), 'Big Dogs', '<%= trail_nav %>'
      end

      it 'creates a two-level breadcrumb for the two levels of the hierarchy' do
        run_middleman
        output = File.read File.join(tmpdir, 'build', 'sub-dir', 'index.html')
        doc = Nokogiri::HTML(output)
        expect(doc.at('ul li:first-child').text).to eq('Dogs')
      end
    end
  end
end