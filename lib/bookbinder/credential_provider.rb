require 'rubygems/package'
require 'zlib'

class CredentialProvider
  include BookbinderLogger

  def initialize(repository)
    @repository = repository
  end

  def credentials
    log 'Processing ' + @repository.full_name.cyan
    untar tarball
  end

  private

  def tarball
    @tarball ||= @repository.download_archive
  end

  def untar(tarball)
    z = Zlib::GzipReader.new(StringIO.new(tarball))
    unzipped = StringIO.new(z.read)

    our_yaml = ''
    Gem::Package::TarReader.new unzipped do |tar|
      tar.each do |file|
        if file.full_name.match('credentials.yml')
          our_yaml = YAML.load file.read
        end
      end
    end

    z.close

    our_yaml
  end
end
