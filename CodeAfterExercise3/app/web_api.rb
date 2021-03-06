require_relative 'posts'

class WebApi
  class << self
    def index(event:,context:)
      posts = Posts.scan(limit: 25).page.map { |p| p.to_h }
      return {
        statusCode: 200,
        body: { posts: posts }.to_json
      }
    end

    def get(event:,context:)
      post_id = event["pathParameters"]["uuid"]
      post = Posts.find(post_uuid: post_id)
      if post
        return {
          statusCode: 200,
          body: { post: post.to_h }.to_json
        }
      else
        return {
          statusCode: 404,
          body: { error: "Post #{post_id} not found!" }.to_json
        }
      end
    end

    def create(event:,context:)
      params = _create_params(event["body"])
      params[:post_uuid] = SecureRandom.uuid
      params[:created_at] = Time.now
      post = Posts.new(params)
      if post.save
        return {
          statusCode: 200,
          body: { post: post.to_h }.to_json
        }
      else
        return {
          statusCode: 500,
          body: { error: "Failed to create new post." }
        }
      end
    end

    def delete_all(event:,context:)
      _sqs_client.send_message(
        queue_url: _sqs_queue_url,
        message_body: "DELETE_ALL"
      )
      return {
        statusCode: 204
      }
    end

    private
    def _create_params(body_input)
      ret = {}
      json = JSON.parse(body_input, symbolize_names: true)
      ret[:title] = json[:title]
      ret[:body] = json[:body]
      ret
    end

    def _sqs_client
      require 'aws-sdk-sqs'
      @@sqs_client ||= Aws::SQS::Client.new
      @@sqs_client
    end

    def _sqs_queue_url
      ENV["SQS_QUEUE_URL"]
    end
  end
end
