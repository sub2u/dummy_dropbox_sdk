require 'test/unit'
require "#{File.dirname(__FILE__)}/../lib/dummy_dropbox_sdk.rb"

class DummyDropboxSdkTest < Test::Unit::TestCase
  def setup
    @session = DropboxSession.new('key', 'secret')
    @client = DropboxClient.new(@session)
  end

  def test_serialize
    assert_equal("--- dummy serial\n", @session.serialize )
  end

  def test_get_authorize_url
    assert_not_nil(@session.get_authorize_url)
  end

  def test_deserialize
    assert_not_nil(DropboxSession.deserialize(nil))
  end

  def test_metadata
    assert( !@client.metadata( '/file1.txt' )['is_dir'] )
    assert(  @client.metadata( '/folder1' )['is_dir'] )
  end

  def test_create_folder
    FileUtils.rm_r( "#{DummyDropbox.root_path}/tmp_folder" )  if File.exists?( "#{DummyDropbox.root_path}/tmp_folder" )
    metadata = @client.file_create_folder '/tmp_folder'
    assert( File.directory?( "#{DummyDropbox.root_path}/tmp_folder" ) )
    assert_equal(true, metadata["is_dir"])

    FileUtils.rm_r( "#{DummyDropbox.root_path}/tmp_folder" )
  end

  def test_upload
    FileUtils.rm_r( "#{DummyDropbox.root_path}/file.txt" )  if File.exists?( "#{DummyDropbox.root_path}/file.txt" )
    File.open("test/file.txt", "w"){|f| f.write("file content")}
    DummyDropbox.root_path = "test/"

    file_fixture = File.new("#{File.dirname(__FILE__)}/file.txt")
    metadata = @client.put_file('file.txt', file_fixture)
    assert_equal(
      File.read("#{File.dirname(__FILE__)}/file.txt"),
      File.read( "#{DummyDropbox.root_path}/file.txt" )
    )
    assert(!metadata["is_dir"])
    FileUtils.rm_r( "#{DummyDropbox.root_path}/file.txt" )
  end

  # TODO these methods I don't used yet. They are commented out because they
  #      have to be checked against the api if the signature match

  # def test_download
  #   assert_equal( "File 1", @session.download( '/file1.txt' ) )
  # end
  #
  # def test_list
  #   assert_equal(['/file1.txt', '/folder1'], @session.list('').map{ |e| e.path } )
  #   assert_equal(['folder1/file2.txt', 'folder1/file3.txt'], @session.list('folder1').map{ |e| e.path } )
  # end
  #
  # def test_delete
  #   FileUtils.mkdir_p( "#{DummyDropbox.root_path}/tmp_folder" )
  #   3.times { |i| FileUtils.touch( "#{DummyDropbox.root_path}/tmp_folder/#{i}.txt" ) }
  #
  #   assert( File.exists?( "#{DummyDropbox.root_path}/tmp_folder" ) )
  #   assert( File.exists?( "#{DummyDropbox.root_path}/tmp_folder/0.txt" ) )
  #
  #   metadata = @session.delete '/tmp_folder/0.txt'
  #   assert( !File.exists?( "#{DummyDropbox.root_path}/tmp_folder/0.txt" ) )
  #
  #   metadata = @session.delete '/tmp_folder'
  #   assert( !File.exists?( "#{DummyDropbox.root_path}/tmp_folder" ) )
  # end

end

