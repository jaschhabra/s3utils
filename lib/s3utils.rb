require 'rubygems'
require 'aws-sdk'
require 'thor'

module S3Utils
  require "s3utils/version"

  class Main < Thor

    desc "version", " gives the version of s3utils gem"
    def version
      puts S3Utils::VERSION
    end
    desc "listbuckets", "lists all of the buckets in your account"
    def listbuckets
      with_error_handling do
        s3.buckets.each do |bucket|
          puts bucket.name
        end
      end

    end

    desc "createbucket name", "creates a bucket"
    def createbucket(name)
      with_error_handling do
        bucket = s3.buckets.create(name)
      end
    end


    desc "deletekey bucket:key", "deletes a key in the given bucket."
    method_option :prefix, :default => false, :desc => "delete all keys in a bucket with the prefix"
    def deletekey(bucket_key)
      with_error_handling do
        abort "Error: incorrect bucket:key format" unless bucket_key =~ /(.+):(.+)/
        if options.prefix?
          objects =  s3.buckets[$1].objects.with_prefix($2)
          objects.each do |o|
            o.delete
          end
        else
          s3.buckets[$1].objects[$2].delete
        end
      end
    end



    desc "deletebucket name ", "deletes a bucket."
    method_option :force, :default => false, :desc => "force delete a bucket after deleting all the keys in the bucket"
    def deletebucket(name)
      with_error_handling do
        if options.force?
          objects =  s3.buckets[name].objects
          objects.each do |o|
            o.delete
          end
        end
        s3.buckets[name].delete
      end
    end


    desc "list bucket[:prefix]", "list the keys of a bucket. prefix is optional argument"
    def list(bucket_prefix)
      with_error_handling do
        if  bucket_prefix =~ /(.+):(.+)/
          objects =  s3.buckets[$1].objects.with_prefix($2)
        else
          objects =  s3.buckets[bucket_prefix].objects
        end
        objects.each do |o|
          puts o.key
        end
      end
    end

    desc "gettimestamp bucket:key", "get the last modified integer timestamp for the key from the bucket"
    def get_timestamp(bucket_key)
      with_error_handling do
        abort "Error: incorrect bucket:key format" unless bucket_key =~ /(.+):(.+)/
        o = s3.buckets[$1].objects[$2]
        puts o.last_modified.to_i
      end
    end

    desc "get bucket:key file", "get the file for the key from the bucket"
    def get(bucket_key, file)
      with_error_handling do
        abort "Error: incorrect bucket:key format" unless bucket_key =~ /(.+):(.+)/
        o = s3.buckets[$1].objects[$2]
        File.open(file, "w"){|f| f.write(o.read)}
      end
    end

    desc "put bucket:key file", "puts a file for the key in the bucket"
    def put(bucket_key, file)
      with_error_handling do
        abort "Error: incorrect bucket:key format" unless bucket_key =~ /(.+):(.+)/
        File.open(file, "r") { |f| s3.buckets[$1].objects.create($2, :data => f.read)}
      end
    end

    desc "copy bucket:key bucket:key", "copy a file from one bucket:key to another bucket:key"
    def copy(from, to)
      with_error_handling do 
        abort "Error: incorrect bucket:key format" unless from =~ /(.+):(.+)/ &&  to =~ /(.+):(.+)/
        from =~ /(.+):(.+)/
        o_from = s3.buckets[$1].objects[$2]
        raise "Object #{from} does not exist" unless o_from.exists?

        to =~ /(.+):(.+)/
        o_to = s3.buckets[$1].objects.create($2, :data => o_from.read)
      end
    end


    desc "move bucket:key bucket:key", "moves a file from one bucket:key to another bucket:key"
    def move(from, to)
      with_error_handling do 
        abort "Error: incorrect bucket:key format" unless from =~ /(.+):(.+)/ &&  to =~ /(.+):(.+)/
        from =~ /(.+):(.+)/
        o_from = s3.buckets[$1].objects[$2]
        raise "Object #{from} does not exist" unless o_from.exists?

        to =~ /(.+):(.+)/
        o_to = s3.buckets[$1].objects.create($2, :data => o_from.read)
        o_from.delete
      end
    end

    private
    def with_error_handling
      begin
        yield
      rescue Exception => e
        abort "Error: " + e.message
      end
    end
    def test_aws_config(s3)
      begin
        #test connection by checking for 1 bucket name
        s3.buckets.each do |bucket|
          break
        end
      rescue Exception => e
        abort "Error: " + e.message
      end

    end
    def s3
      @s3 ||= begin
                aws_key_opts = {}

                if ENV["AWS_CREDENTIAL_FILE"]
                  File.open(ENV["AWS_CREDENTIAL_FILE"]) do |file|
                    file.lines.each do |line|
                      aws_key_opts[:access_key_id] = $1 if line =~ /^AWSAccessKeyId=(.*)$/
                      aws_key_opts[:secret_access_key] = $1 if line =~ /^AWSSecretKey=(.*)$/
                    end
                  end
                end

                opt =  ENV["HTTPS_PROXY"] ? {:proxy_uri => ENV["HTTPS_PROXY"]} : {}
                AWS.config(aws_key_opts.merge opt)
                s3 = AWS::S3.new
                test_aws_config(s3)
                s3
              end
    end
  end
end
