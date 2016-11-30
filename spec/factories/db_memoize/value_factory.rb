FactoryGirl.define do
  factory :value, class: DbMemoize::Value do
    entity_type    'Car'
    entity_id      '1'
    method_name    'shift'
    arguments_hash ::Digest::MD5.hexdigest('1 up')
    value          ::Marshal.dump('second gear')
  end
end
