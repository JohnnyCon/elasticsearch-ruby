module Elasticsearch
  module API

    # Generic utility methods
    #
    module Utils

      # URL-escape a string
      #
      # @example
      #     __escape('bar^bam') # => 'bar%5Ebam'
      #
      # @api private
      def __escape(string)
        URI.encode(string.to_s)
      end

      # Create a "list" of values from arguments, ignoring nil values
      #
      # @example Create a list from array
      #     __listify(['A','B']) # => 'A,B'
      #
      # @example Create a list from arguments
      #     __listify('A','B') # => 'A,B'
      #
      # @api private
      def __listify(*list)
        Array(list).flatten.compact.join(',')
      end

      # Create a path (URL part) from arguments, ignoring nil values and empty strings,
      # and encoding special characters
      #
      # @example Create a path from array
      #     __pathify(['foo', '', nil, 'bar']) # => 'foo/bar'
      #
      # @example Create a path from arguments
      #     __pathify('foo', '', nil, 'bar') # => 'foo/bar'
      #
      # # @example Encode special characters
      #     __pathify(['foo', 'bar^bam']) # => 'foo/bar%5Ebam'
      #
      # @api private
      def __pathify(*segments)
        Array(segments).flatten.
          compact.
          reject { |s| s.to_s =~ /^\s*$/ }.
          map    { |s| __escape(s) }.
          join('/').
          squeeze('/')
      end

      # Convert an array of payloads into Elasticsearch `header\ndata` format
      #
      #     Elasticsearch::API::Utils.__bulkify [
      #       { :index =>  { :_index => 'myindexA', :_type => 'mytype', :_id => '1', :data => { :title => 'Test' } } },
      #       { :update => { :_index => 'myindexB', :_type => 'mytype', :_id => '2', :data => { :doc => { :title => 'Update' } } } }
      #     ]
      #
      #     # => {"index":{"_index":"myindexA","_type":"mytype","_id":"1"}}
      #     # => {"title":"Test"}
      #     # => {"update":{"_index":"myindexB","_type":"mytype","_id":"2"}}
      #     # => {"doc":{"title":"Update"}}
      #
      def __bulkify(payload)
        case
        # Hashes with `:data`
        when payload.any? { |d| d.is_a?(Hash) && d.values.first.is_a?(Hash) && (d.values.first[:data] || d.values.first['data']) }
          payload = payload.
          inject([]) do |sum, item|
            operation, meta = item.to_a.first
            data            = meta.delete(:data) || meta.delete('data')

            sum << { operation => meta }
            sum << data if data
            sum
          end.
          map { |item| MultiJson.dump(item) }
          payload << "" unless payload.empty?

        # Array of strings
        when payload.all? { |d| d.is_a? String }
          payload << ''

        # Header/Data pairs
        else
          payload = payload.map { |item| MultiJson.dump(item) }
          payload << ''
        end

        payload = payload.join("\n")
      end

      extend self
    end
  end
end
