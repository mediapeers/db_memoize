namespace :db_memoize do
  desc "generates memoized values (pass e.g. 'CLASS=Product [ METHODS=to_document,to_hash ]')"
  task warmup: :environment do
    require 'ruby-progressbar'

    klass_name = ENV['class'] || ENV['CLASS'] || raise('Missing CLASS environment value')
    klass      = klass_name.constantize

    methods    = ENV['methods'] || ENV['METHODS']
    methods    = methods.split(',') if methods
    methods    ||= klass.db_memoized_methods.map(&:to_s)

    count      = klass.count

    progressbar = ProgressBar.create(
      title: "db_memoize warmup run for #{klass_name}",
      starting_at: 0,
      total: count,
      format: "%t [#{count}] |%bᗧ%i| %p%% %e",
      progress_mark: ' ',
      remainder_mark: '.'
    )

    klass.find_each do |record|
      # calling each method will build the cached entries for these objects.
      methods.each do |meth|
        record.send(meth)
      end

      progressbar.increment
    end
  end
end
