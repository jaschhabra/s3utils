require 'spec_helper'
describe "S3cmd"  do
  before :all do
    @s3cmd = File.expand_path(File.dirname(__FILE__)) + "/../bin/s3cmd"
    time = Time.now.to_i
    @bucket_name = "s3cmd_test_bucket_#{time}"
    `#{@s3cmd} createbucket #{@bucket_name}`
    abort "Could not create test bucket" unless $?.success?
  end

  describe "list buckets" do
    it "should list #{@bucket_name}" do
      o = `#{@s3cmd} listbuckets`
      $?.success?.should be_true
      o.should include(@bucket_name)
    end
  end

  describe "key/file commands" do
    before :all do
      time = Time.now.to_i
      @prefix = "s3cmd_test_file"
      @key_name = "#{@prefix}_#{time}"
      @test_file = File.expand_path(File.dirname(__FILE__)) + "/data/test.txt"
      `#{@s3cmd} put #{@bucket_name}:#{@key_name} #{@test_file}`
      $?.success?.should be_true
    end

    describe "get_timestamp" do
      it "should return integer timestamp" do
        o = `#{@s3cmd} get_timestamp #{@bucket_name}:#{@key_name}`
        $?.success?.should be_true
        o = Integer o
        o.should be_a_kind_of(Fixnum)
      end
    end

    describe "list bucket" do
      it "should get the bucket keys successfully" do
        o = `#{@s3cmd} list #{@bucket_name}:#{@prefix}`
        $?.success?.should be_true
        o.should include(@key_name)
      end
    end
    describe "get bucket:key file" do
      it "should get the file successfully" do
        `#{@s3cmd} get #{@bucket_name}:#{@key_name} /tmp/#{@key_name}`
        $?.success?.should be_true
        s1 = File.open("/tmp/#{@key_name}", "r") {|f| f.read}
        s2 = File.open(@test_file, "r") {|f| f.read}
        s1.should eql(s2)
      end
    end

    after :all do
      `#{@s3cmd} deletekey #{@bucket_name}:#{@key_name}`
      $?.success?.should be_true
    end

  end
  after :all do
    `#{@s3cmd} deletebucket #{@bucket_name}`
    abort "Could not create delete test bucket #{@bucket_name}" unless $?.success?
  end
end
