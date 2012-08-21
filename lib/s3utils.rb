require 'rubygems'
require 'aws-sdk'
require 'thor'

module S3Utils
  require "s3utils/version"

  class Main < Thor
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


    desc "deletekey bucket:key", "deletes a key in the given bucket"
    def deletekey(bucket_key)
      with_error_handling do
        abort "Error: incorrect bucket:key format" unless bucket_key =~ /(.+):(.+)/
        s3.buckets[$1].objects[$2].delete
      end
    end

    desc "deletebucket name [--force] ", "deletes a bucket. --force will delete a non-empty bucket"
    method_options :force => false
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


    desc "list bucket:prefix", "list the keys of a bucket"
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

    private
    def with_error_handling
      begin
        yield
      rescue Exception => e
        abort "Error: " + e.message
      end
    end
    def s3
      @s3 ||= begin
                access_key, secret_key = nil, nil

                if ENV["AWS_CREDENTIAL_FILE"]
                  File.open(ENV["AWS_CREDENTIAL_FILE"]) do |file|
                    file.lines.each do |line|
                      access_key = $1 if line =~ /^AWSAccessKeyId=(.*)$/
                      secret_key = $1 if line =~ /^AWSSecretKey=(.*)$/
                    end
                  end
                elsif ENV["AWS_ACCESS_KEY"] || ENV["AWS_SECRET_KEY"]
                  access_key = ENV["AWS_ACCESS_KEY"]
                  secret_key = ENV["AWS_SECRET_KEY"]
                end

                opt =  ENV["HTTPS_PROXY"] ? {:proxy_uri => ENV["HTTPS_PROXY"]} : {}
                AWS.config({ :access_key_id => access_key,
                             :secret_access_key => secret_key}.merge opt)
                begin
                  s3 = AWS::S3.new
                  #test connection by checking for 1 bucket name
                  s3.buckets.each do |bucket|
                    bucket.name
                    break
                  end
                rescue Exception => e
                  abort "Error: " + e.message
                end
                s3
              end
    end
  end
end
