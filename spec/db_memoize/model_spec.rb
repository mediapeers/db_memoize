require 'spec_helper'
require 'benchmark'

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

  describe '.db_memoized_methods' do
    EXPECTED_METHODS = [ :fuel_consumption, :gears_count, :facilities, :wise_saying, :generic_value ]

    it 'returns list of methods to be memoized' do
      expect(Bicycle.db_memoized_methods).to contain_exactly(*EXPECTED_METHODS)
    end

    it 'returns list of all methods to be memoized for subclass' do
      expect(ElectricBicycle.db_memoized_methods).to contain_exactly(*EXPECTED_METHODS, :max_speed)
    end
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

    context 'method returning nil' do
      it 'calls original method only once' do
        expect(instance).to receive(:wise_saying_without_memoize).once.and_call_original

        instance.wise_saying
        instance.wise_saying # from cache
      end
    end

    context 'when called with parameters' do
      it 'raises an error' do
        expect {
          instance.gears_count(23)
        }.to raise_error(ArgumentError)
      end
    end

    context 'dirty record' do
      let(:instance) do
        rec = create(:bicycle)
        rec.name = 'dirrrrty'
        rec
      end

      it 'should not create a cache record' do
        expect {
          instance.gears_count
        }.not_to change { DbMemoize::Value.count }
      end

      it 'should call original method' do
        expect(instance).to receive(:gears_count_without_memoize).exactly(2).times.and_call_original
        instance.gears_count
        instance.gears_count
      end
    end

    context 'unsaved record' do
      let(:instance) do
        build(:bicycle)
      end

      it 'should not create a cache record' do
        expect {
          instance.gears_count
        }.not_to change { DbMemoize::Value.count }
      end

      it 'should call original method (every time)' do
        expect(instance).to receive(:gears_count_without_memoize).exactly(2).times.and_call_original
        instance.gears_count
        instance.gears_count
      end
    end

    describe '.memoize_values' do
      it 'saves correct values' do
        instance2 = create(:bicycle)

        klass.memoize_values([instance, instance2], gears_count: 7)

        expect(klass.find(instance.id).gears_count).to eq(7)
        expect(klass.find(instance2.id).gears_count).to eq(7)
      end

      it 'performs benchmark for a number of values to be 7' do
        cnt = 1_000
        cnt.times { klass.create! }

        ids = klass.all.pluck(:id)
        benchmark = Benchmark.measure do
          klass.memoize_values(ids, gears_count: 7)
        end
        STDERR.puts "storing #{cnt} values took #{benchmark.total.round(3)}s"
      end
    end

    describe '#memoize_values' do
      it 'creates memoized values' do
        expect { instance.memoize_values(gears_count: 7) }
          .to change { DbMemoize::Value.count }.by(1)
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
        r.facilities
      end
      expect(DbMemoize::Value.count).to eq(6)
    end

    describe '.unmemoize' do
      it 'wipes cached values for given records' do
        expect { Bicycle.unmemoize([@rec1, @rec2]) }
          .to change { DbMemoize::Value.count }.by(-4)
      end

      it 'wipes cached values for given ids' do
        expect { Bicycle.unmemoize([@rec1.id, @rec3.id]) }
          .to change { DbMemoize::Value.count }.by(-4)
      end
    end

    describe '#unmemoize' do
      it 'wipes cached values for given record' do
        expect { @rec1.unmemoize }
          .to change { DbMemoize::Value.count }.by(-2)
      end

      it 'does not use the cached value after unmemoizing any longer' do
        @rec1.unmemoize
        expect_any_instance_of(Bicycle).to receive(:facilities_without_memoize)
        @rec1.facilities
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

        it 'does not use the cached value after unmemoizing any longer' do
          @rec1.unmemoize(:facilities)
          expect_any_instance_of(Bicycle).to receive(:facilities_without_memoize)
          @rec1.facilities
        end
      end
    end
  end

  context 'entity destruction' do
    it 'destroys cached values when entity gets destroyed' do
      bicycle = create(:bicycle)
      bicycle2 = create(:bicycle)
      bicycle.gears_count
      bicycle2.gears_count

      expect { bicycle.destroy }
        .to change { DbMemoize::Value.count }.by(-1)
    end
  end
end
