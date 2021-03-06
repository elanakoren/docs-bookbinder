require 'spec_helper'

describe Cli::Publish do
  include_context 'tmp_dirs'

  around_with_fixture_repo do |spec|
    spec.run
  end

  let(:config_hash) { {
      'book_repo' => 'fantastic/fixture-book-title',
      'sections' => [
          {'repository' => {'name' => 'fantastic/dogs-repo', 'ref' => 'dog-sha'}, 'directory' => 'dogs', 'subnav_template' => 'dogs'},
          {'repository' => {'name' => 'fantastic/my-docs-repo', 'ref' => 'my-docs-sha'}, 'directory' => 'foods/sweet', 'subnav_template' => 'fruits'},
          {'repository' => {'name' => 'fantastic/my-other-docs-repo', 'ref' => 'my-other-sha'}, 'directory' => 'foods/savory', 'subnav_template' => 'vegetables'}
      ],
      'public_host' => 'host.example.com'
  } }
  let(:config) { Configuration.new(config_hash) }
  let(:publish_command) { Cli::Publish.new(config) }

  before { Spider.any_instance.stub(:generate_sitemap) }

  context 'local' do
    it 'creates some static HTML' do
      publish_command.run ['local']

      index_html = File.read File.join('final_app', 'public', 'dogs', 'index.html')
      index_html.should include 'Woof'
    end
  end

  context 'github' do
    before do
      GitClient.any_instance.stub(:archive_link)
      stub_github_for 'fantastic/dogs-repo', 'dog-sha'
      stub_github_for 'fantastic/my-docs-repo', 'my-docs-sha'
      stub_github_for 'fantastic/my-other-docs-repo', 'my-other-sha'
    end

    it 'creates some static HTML' do
      publish_command.run ['github']

      index_html = File.read File.join('final_app', 'public', 'foods', 'sweet', 'index.html')
      index_html.should include 'This is a Markdown Page'
    end

    context 'when a tag is provided' do
      let(:desired_tag) { 'foo-1.7.12' }
      let(:cli_args) { ['github', desired_tag] }
      let(:fixture_repo_name) { 'fantastic/fixture-book-title' }

      it 'gets the book at that tag' do
        stub_github_for 'fantastic/dogs-repo', desired_tag
        stub_github_for 'fantastic/my-docs-repo', desired_tag
        stub_github_for 'fantastic/my-other-docs-repo', desired_tag

        zipped_repo_url = "https://github.com/#{fixture_repo_name}/archive/#{desired_tag}.tar.gz"

        zipped_repo = RepoFixture.tarball 'fantastic/book'.split('/').last, desired_tag
        stub_request(:get, zipped_repo_url).to_return(
            :body => zipped_repo, :headers => {'Content-Type' => 'application/x-gzip'}
        )

        stub_refs_for_repo(fixture_repo_name, [desired_tag])

        expect(GitClient.get_instance).to receive(:archive_link).with(fixture_repo_name, ref: desired_tag).once.and_return zipped_repo_url

        publish_command.run cli_args
      end

      pending 'when a constituent repository does not have the tag'
      pending 'when a book does not have the tag'
    end
  end

  context 'when a pdf is specified' do
    pending 'creates the pdf'
  end

  describe 'invalid arguments' do
    it 'raises Cli::InvalidArguments' do
      expect {
        publish_command.run ['blah', 'blah', 'whatever']
      }.to raise_error(Cli::InvalidArguments)

      expect {
        publish_command.run []
      }.to raise_error(Cli::InvalidArguments)
    end
  end
end
