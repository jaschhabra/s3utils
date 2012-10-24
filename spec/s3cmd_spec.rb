require 'spec_helper'
describe "S3cmd"  do
  before :each do
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
    before :each do
      time = Time.now.to_i
      @prefix = "s3cmd_test_file"
      @key_name = "#{@prefix}_#{time}"
      @test_file = File.expand_path(File.dirname(__FILE__)) + "/data/test.txt"
      `#{@s3cmd} put #{@bucket_name}:#{@key_name}1 #{@test_file}`
      $?.success?.should be_true
      # Create two more keys in bucket to be able to test non-empty deletes
      `#{@s3cmd} put #{@bucket_name}:#{@key_name}2 #{@test_file}`
      $?.success?.should be_true
      $?.success?.should be_true
    end

    describe "gettimestamp" do
      it "should return integer timestamp" do
        o = `#{@s3cmd} get_timestamp #{@bucket_name}:#{@key_name}1`
        $?.success?.should be_true
        o = Integer o
        o.should be_a_kind_of(Fixnum)
      end
    end

    describe "list bucket" do
      it "should get the bucket keys successfully" do
        o = `#{@s3cmd} list #{@bucket_name}:#{@prefix}`
        $?.success?.should be_true
        o.should include("#{@key_name}1")
      end
    end

    describe "get bucket:key file" do
      it "should get the file successfully" do
        `#{@s3cmd} get #{@bucket_name}:#{@key_name}1 /tmp/#{@key_name}1`
        $?.success?.should be_true
        s1 = File.open("/tmp/#{@key_name}1", "r") {|f| f.read}
        s2 = File.open(@test_file, "r") {|f| f.read}
        s1.should eql(s2)
      end
    end

    describe "deletekeys with prefix" do
      it "should delete the keys with prefix successfully" do
        prefix = "s3testfiles"
        `#{@s3cmd} put #{@bucket_name}:#{prefix}1 #{@test_file}`
        $?.success?.should be_true
        `#{@s3cmd} put #{@bucket_name}:#{prefix}2 #{@test_file}`
        $?.success?.should be_true
        `#{@s3cmd} put #{@bucket_name}:#{prefix}3 #{@test_file}`
        $?.success?.should be_true

        `#{@s3cmd} deletekey #{@bucket_name}:#{@prefix} --prefix`
        $?.success?.should be_true
        o = `#{@s3cmd} list #{@bucket_name}:#{@prefix}`
        o.should_not include("#{@prefix}")

      end
    end

    describe "copy file from one bucket to another" do
      it "should not copy non-existent file successfully" do
       `#{@s3cmd} copy #{@bucket_name}:junkkeyname #{@bucket_name}:#{@key_name}3`
       $?.success?.should_not be_true
      end
      it "should copy file successfully" do
        `#{@s3cmd} copy #{@bucket_name}:#{@key_name}1 #{@bucket_name}:#{@key_name}3`
        o = `#{@s3cmd} list #{@bucket_name}:#{@prefix}`
        $?.success?.should be_true
        o.should include("#{@key_name}3")
        o.should include("#{@key_name}1")
      end
    end

    describe "move file from one bucket to another" do
      it "should not move non-existent file successfully" do
       `#{@s3cmd} move #{@bucket_name}:junkkeyname #{@bucket_name}:#{@key_name}3`
       $?.success?.should_not be_true
      end
      it "should move file successfully" do
        `#{@s3cmd} move #{@bucket_name}:#{@key_name}1 #{@bucket_name}:#{@key_name}3`
        o = `#{@s3cmd} list #{@bucket_name}:#{@prefix}`
        $?.success?.should be_true
        o.should include("#{@key_name}3")
        o.should_not include("#{@key_name}1")
      end
    end

    after :each do
      `#{@s3cmd} deletekey #{@bucket_name}:#{@prefix} --prefix`
      $?.success?.should be_true
    end

  end
  after :each do
    # Since one key is left this will try to delete a non-empty bucket
    `#{@s3cmd} deletebucket  #{@bucket_name}  --force`
    abort "Could not create delete test bucket #{@bucket_name}" unless $?.success?
  end
end
