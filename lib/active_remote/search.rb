module ActiveRemote
  module Search
    def self.included(klass)
      klass.class_eval do
        extend ::ActiveRemote::Search::ClassMethods
        include ::ActiveRemote::Persistence
        include ::ActiveRemote::RPC
      end
    end

    module ClassMethods

      # Tries to load the first record; if it fails, an exception is raised.
      #
      def find(args)
        remote = self.search(args).first
        raise RemoteRecordNotFound if remote.nil?

        return remote
      end

      # Tries to load the first record; if it fails, then create is called
      # with the same arguments.
      #
      def first_or_create(attributes)
        remote = self.search(attributes).first
        remote ||= self.create(attributes)
        remote
      end

      # Tries to load the first record; if it fails, then create! is called
      # with the same arguments.
      #
      def first_or_create!(attributes)
        remote = self.search(attributes).first
        remote ||= self.create!(attributes)
        remote
      end

      # Tries to load the first record; if it fails, then a new record is
      # initialized with the same arguments.
      #
      def first_or_initialize(attributes)
        remote = self.search(attributes).first
        remote ||= self.new(attributes)
        remote
      end

      def paginated_search(args)
        args = _active_remote_search_args(args)

        remote = self.new
        remote._active_remote_search(args)
        records = remote.serialize_records

        if records.respond_to?(:paginate)
          pagination_options = remote.last_response.try(:options).try(:pagination).try(:to_hash) || {}
          records = records.paginate(pagination_options)
        end

        records
      end

      def search(args)
        args = _active_remote_search_args(args)

        remote = self.new
        remote._active_remote_search(args)
        remote.serialize_records
      end

      def _active_remote_search_args(args)
        unless args.is_a?(Hash)
          if args.respond_to?(:to_hash)
            args = args.to_hash
          else
            raise "Invalid parameter: #{args}. First parameter must respond to :to_hash."
          end
        end

        args
      end
    end

    # Search for the given resource.
    #
    def _active_remote_search(args)
      auto_paging = _auto_paging?(args)

      remote_records = []
      page = 0
      total_pages = 1

      run_callbacks :search do
        while page < total_pages do
          page += 1
          args = _auto_paging(args, page) if auto_paging

          _execute(:search, args)

          total_pages = _total_pages if auto_paging
          remote_records += last_response.records
        end

        last_response.records = remote_records
      end
    end

    def reload
      _active_remote_search(:guid => self.guid)
      assign_attributes(last_response.to_hash)
    end

  private

    def _auto_paging(args, page = 1)
      args[:options] ||= {}
      args[:options].merge!({
        :pagination => {
          :page => page,
          :per_page => self.class.auto_paging_size
        }
      })

      args
    end

    def _auto_paging?(args)
      options = args[:options]
      pagination = options[:pagination] unless options.nil?

      return pagination.nil?
    end

    def _options
      last_response.try(:options) if last_response.respond_to?(:options)
    end

    def _pagination
      options = _options
      pagination = options.try(:pagination) if options.respond_to?(:pagination)
      pagination
    end

    def _total_pages
      pagination = _pagination
      total_pages = pagination.total_pages if pagination.respond_to?(:total_pages)
      total_pages || 1
    end
  end
end
