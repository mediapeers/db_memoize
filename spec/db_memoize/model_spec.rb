require 'spec_helper'

describe DbMemoize::Model do
  let(:klass) { Bicycle }

  it 'loads the module' do
    expect(klass).to respond_to(:db_memoize)
  end

  it 'creates an original method alias' do
    expect(klass.new).to respond_to(:gears_count_without_memoize)
  end

  it 'defines association' do
    expect(klass.new).to respond_to(:memoized_values)
  end

  context 'reading/writing' do
    let(:instance) { create(:bicycle) }

    it 'creates a new memoized value in db' do
      expect {
        instance.gears_count
      }.to change { DbMemoize::Value.count }.by(1)
    end

    it 'returns correct value from cache' do
      instance.gears_count # writes to cache
      expect(instance.gears_count).to eq(5)
    end

    it 'calls original method only once' do
      expect(instance).to receive(:gears_count_without_memoize).once.and_call_original

      instance.gears_count
      instance.gears_count # from cache
    end

    context 'method with parameters' do
      it 'creates a cached value for each parameter set' do
        expect {
          instance.shift(1)
          instance.shift(2)
        }.to change { DbMemoize::Value.count }.by(2)
      end

      it 'returns correct cached values for given parameters' do
        expect_any_instance_of(Bicycle).to receive(:shift_without_memoize).exactly(2).times.and_call_original

        instance.shift(1)
        instance.shift(2)

        expect(instance.shift(1)).to eq('1 shifted!')
        expect(instance.shift(2)).to eq('2 shifted!')
      end
    end

    context 'custom key' do
      it 'calls original method again if custom key has changed' do
        expect(instance).to receive(:gears_count_without_memoize).exactly(2).times.and_call_original

        DbMemoize.default_custom_key = 'v1'
        instance.gears_count

        DbMemoize.default_custom_key = 'v2'
        instance.gears_count
      end
    end
  end

  context 'cache wiping' do
    before do
      @rec1 = create(:bicycle)
      @rec2 = create(:bicycle)
      @rec3 = create(:bicycle)
      [@rec1, @rec2, @rec3].each do |r|
        r.gears_count
        r.shift(1)
        r.facilities
      end

      expect(DbMemoize::Value.count).to eq(9)
    end

    describe '.unmemoize' do
      it 'wipes cached values for given records' do
        expect { Bicycle.unmemoize([@rec1, @rec2]) }
          .to change { DbMemoize::Value.count }.by(-6)
      end

      it 'wipes cached values for given ids' do
        expect { Bicycle.unmemoize([@rec1.id, @rec3.id]) }
          .to change { DbMemoize::Value.count }.by(-6)
      end
    end

    describe '#unmemoize' do
      it 'wipes cached values for given record' do
        expect { @rec1.unmemoize }
          .to change { DbMemoize::Value.count }.by(-3)
      end
    end

    context 'specific method only' do
      describe '.unmemoize' do
        it 'wipes cached values for given records' do
          expect { Bicycle.unmemoize([@rec1, @rec2], :gears_count) }
            .to change { DbMemoize::Value.count }.by(-2)
        end
      end

      describe '#unmemoize' do
        it 'wipes cached values for given record' do
          expect { @rec1.unmemoize(:facilities) }
            .to change { DbMemoize::Value.count }.by(-1)
        end
      end
    end
  end
end
