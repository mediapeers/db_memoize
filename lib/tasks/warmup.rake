namespace :db_memoize do
  desc "generates memoized values (pass e.g. 'class=Product methods=to_document,to_hash')"
  task warmup: :environment do
    require 'ruby-progressbar'

    klass_name = ENV['class']
    methods    = ENV['methods'].split(',')
    klass      = klass_name.constantize
    count      = klass.count

    progressbar = ProgressBar.create(
      title: "db_memoize warmup run for #{klass_name}",
      starting_at: 0,
      total: count,
      format: "%t [#{count}] |%bᗧ%i| %p%% %e",
      progress_mark: ' ',
      remainder_mark: '.'
    )

    klass_name.constantize.find_each do |record|
      methods.each do |meth|
        record.send(meth)
      end

      progressbar.increment
    end
  end
end
