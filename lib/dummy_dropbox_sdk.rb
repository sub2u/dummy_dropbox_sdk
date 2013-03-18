begin
  require 'dropbox_sdk'
rescue LoadError
  require 'rubygems'
  require 'dropbox_sdk'
end
require 'ostruct'
require 'mime/types'

GIGA_SIZE = 1073741824.0
MEGA_SIZE = 1048576.0
KILO_SIZE = 1024.0

# Return the file size with a readable style.
def readable_file_size(size, precision)
  case
  when size == 1 
    "1 Byte"
  when size < KILO_SIZE 
    "%d Bytes" % size
  when size < MEGA_SIZE 
    "%.#{precision}f KB" % (size / KILO_SIZE)
  when size < GIGA_SIZE 
    "%.#{precision}f MB" % (size / MEGA_SIZE)
  else 
    "%.#{precision}f GB" % (size / GIGA_SIZE)
  end
end

module DummyDropbox
  @@root_path = File.expand_path( "./test/fixtures/dropbox" )

  def self.root_path=(path)
    @@root_path = path
  end

  def self.root_path
    @@root_path
  end
end

class DropboxSession
  def initialize(oauth_key, oauth_secret, options={})
    @ssl = false
    @consumer = OpenStruct.new( :key => "dummy key consumer" )
    @request_token = "dummy request token"
  end

  def self.deserialize(data)
    return DropboxSession.new( 'dummy_key', 'dummy_secret' )
  end

  def get_authorize_url(*args)
    return 'https://www.dropbox.com/0/oauth/authorize'
  end

  def serialize
    return 'dummy serial'.to_yaml
  end

  def authorized?
    return true
  end

  def dummy?
    return true
  end

end

class DropboxClient

  def initialize(session, root="app_folder", locale=nil)
    @session = session
  end

  def file_create_folder(path, options={})
    file_path = File.join(DummyDropbox::root_path, path)
    raise DropboxError.new("Folder exists!") if File.exists?(file_path)
    FileUtils.mkdir(file_path)
    # intercepted result:
    # {"modified"=>"Wed, 23 Nov 2011 10:24:37 +0000", "bytes"=>0, "size"=>"0
    # bytes", "is_dir"=>true, "rev"=>"2f04dc6147", "icon"=>"folder",
    # "root"=>"app_folder", "path"=>"/test_from_console", "thumb_exists"=>false,
    # "revision"=>47}
    return self.metadata(path)
  end

  def metadata(path, options={})
    dummy_path = File.join(DummyDropbox::root_path, path)
    raise DropboxError.new("File not found") unless File.exists?(dummy_path)

    list_hash_files = []
    if File.directory?(dummy_path)
      Dir.entries(dummy_path).each do |file_name|
        file_path = File.join(dummy_path, file_name)
        unless File.directory?(file_path)
          list_hash_files << {"size" => readable_file_size(File.size(file_path), 2),
                              "bytes" => File.size(file_path),
                              "is_dir" => false,
                              "modified" => File.mtime(file_path),
                              "mime_type" => MIME::Types.type_for(file_path)[0].content_type,
                              "path" => File.join(path, file_name)}
        end
      end

    end

    response =
      {
        "thumb_exists" => false,
        "bytes" => File.size(dummy_path),
        "modified" => "Tue, 04 Nov 2008 02:52:28 +0000",
        "path" => path,
        "is_dir" => File.directory?( "#{DummyDropbox::root_path}/#{path}" ),
        "size" => readable_file_size(File.size(dummy_path), 2),
        "root" => "dropbox",
        "icon" => "page_white_acrobat",
        "hash" => "theHash",
        "contents" => list_hash_files
      }

    return response
  end

  def put_file(to_path, file_obj, overwrite=false, parent_rev=nil)
    file_path = File.join(DummyDropbox::root_path, to_path)
    # FileUtils.copy_file(file_obj.path, File.join(DummyDropbox::root_path, to_path))
    File.open(file_path, "w") do |f|
      f.write(file_obj)
    end

    return self.metadata(to_path)
  end

  def account_info()
    {
      'display_name' => 'Dummy Dropbox SDK',
      'email' => 'dummy_dropbox@example.com'
    }
  end

  def get_file(path)
    dummy_file_path = File.join(DummyDropbox::root_path, path)
    raise DropboxError.new("File not found") unless File.exists?(dummy_file_path)

    File.read(dummy_file_path)
  end

  def file_delete(path)
    dummy_file_path = File.join(DummyDropbox::root_path, path)
    raise DropboxError.new("File not found") unless File.exists?(dummy_file_path)

    metadata = self.metadata(path)
    FileUtils.rm_rf(dummy_file_path)

    return metadata
  end

  # TODO these methods I don't used yet. They are commented out because they
  #      have to be checked against the api if the signature match

  # def download(path, options={})
  #   File.read( "#{Dropbox.files_root_path}/#{path}" )
  # end
  #
  # def delete(path, options={})
  #   FileUtils.rm_rf( "#{Dropbox.files_root_path}/#{path}" )
  #
  #   return true
  # end
  #
  # def upload(local_file_path, remote_folder_path, options={})
  # end
  #
  #
  # def list(path, options={})
  #   result = []
  #
  #   Dir["#{Dropbox.files_root_path}/#{path}/**"].each do |element_path|
  #     element_path.gsub!( "#{Dropbox.files_root_path}/", '' )
  #
  #     element =
  #       OpenStruct.new(
  #         :icon => 'folder',
  #         :'directory?' => File.directory?( "#{Dropbox.files_root_path}/#{element_path}" ),
  #         :path => element_path,
  #         :thumb_exists => false,
  #         :modified => Time.parse( '2010-01-01 10:10:10' ),
  #         :revision => 1,
  #         :bytes => 0,
  #         :is_dir => File.directory?( "#{Dropbox.files_root_path}/#{element_path}" ),
  #         :size => '0 bytes'
  #       )
  #
  #     result << element
  #   end
  #
  #   return result
  # end
  #
  # def account
  #   response = <<-RESPONSE
  #   {
  #       "country": "",
  #       "display_name": "John Q. User",
  #       "email": "john@user.com",
  #       "quota_info": {
  #           "shared": 37378890,
  #           "quota": 62277025792,
  #           "normal": 263758550
  #       },
  #       "uid": "174"
  #   }
  #   RESPONSE
  #
  #   return JSON.parse(response).symbolize_keys_recursively.to_struct_recursively
  # end

end
