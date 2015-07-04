require_relative '../spec_helper'
require 'logger'
require 'active_record'
require 'data_mapper'
require 'resque-delay'
require 'mongoid'

describe 'performable_method' do
  
  class TheARecord < ActiveRecord::Base
    def play
      @played = true
    end
  end
  
  class TheDataMapper
    include DataMapper::Resource
    def play
      @played = true
    end
  end
  
  class TheMongoid 
    include Mongoid::Document
    def play
      @played = true
    end
  end
  
  let(:ar) {
    ar = instance_double("TheARecord")
    allow(ar).to receive(:kind_of?).and_return(false)
    allow(ar).to receive(:kind_of?).with(ActiveRecord::Base).and_return(true)
    allow(ar).to receive(:id).and_return(1)
    allow(ar).to receive(:class).and_return(TheARecord)
    ar
  }
  
  let(:ar_key) { 'AR:TheARecord:1' }
  
  let(:klass) { 3.class }
  
  let(:klass_key) { 'CLASS:Fixnum' }
  
  let(:dm) {
    dm = instance_double("TheDataMapper")
    allow(dm).to receive(:kind_of?).and_return(false)
    allow(dm).to receive(:kind_of?).with(DataMapper::Resource).and_return(true)
    allow(dm).to receive(:key).and_return([1,2])
    allow(dm).to receive(:class).and_return(TheDataMapper)
    dm
  }
  
  let(:dm_key) { 'DM:TheDataMapper:1:2' }
  
  let(:mg) {
    mg = instance_double("TheMongoid")
    allow(mg).to receive(:kind_of?).and_return(false)
    allow(mg).to receive(:kind_of?).with(Mongoid::Document).and_return(true)
    allow(mg).to receive(:id).and_return(1)
    allow(mg).to receive(:class).and_return(TheMongoid)
    mg
  } 
  
  let(:mg_key) {'MG:TheMongoid:1'}
  
  before(:each) do
    allow(TheARecord).to receive(:find).with("1").and_return(ar)
    allow(TheDataMapper).to receive('get!'.to_sym).with("1","2").and_return(dm)
    allow(TheMongoid).to receive(:find).with("1").and_return(mg)
  end
  
  describe '.dump' do
    it 'returns AR name' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(pm.send(:dump, ar)).to eq(ar_key)
    end
    
    it 'returns DM name' do
      pm = ResqueDelay::PerformableMethod.new(dm, :play, [], nil, nil)
      expect(pm.send(:dump, dm)).to eq(dm_key)
    end
    
    it 'returns MG name' do
      pm = ResqueDelay::PerformableMethod.new(mg, :play, [], nil, nil)
      expect(pm.send(:dump, mg)).to eq(mg_key)
    end
    
    it 'returns Class name' do
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(pm.send(:dump, klass)).to eq(klass_key)
    end
  end
  
  describe '.display_name' do
    it 'prints ARs' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(pm.display_name).to eq('TheARecord#play')
    end
    it 'prints DMs' do
      pm = ResqueDelay::PerformableMethod.new(dm, :play, [], nil, nil)
      expect(pm.display_name).to eq('TheDataMapper#play')
    end
    it 'prints MGs' do
      pm = ResqueDelay::PerformableMethod.new(mg, :play, [], nil, nil)
      expect(pm.display_name).to eq('TheMongoid#play')
    end
    it 'prints Classes' do
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(pm.display_name).to eq('Fixnum.to_s')
    end
    it 'prints Unknowns' do
      pm = ResqueDelay::PerformableMethod.new("I'm not exptected", :to_s, [], nil, nil)
      expect(pm.display_name).to eq('Unknown#to_s')
    end
  end
  
  describe '.load' do
    it 'loads ARs' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(pm.send(:load, ar_key)).to eq(ar)
    end
    it 'loads DMs' do
      pm = ResqueDelay::PerformableMethod.new(dm, :play, [], nil, nil)
      expect(pm.send(:load, dm_key)).to eq(dm)
    end
    it 'loads MGs' do
      pm = ResqueDelay::PerformableMethod.new(mg, :play, [], nil, nil)
      expect(pm.send(:load, mg_key)).to eq(mg)
    end
    it 'loads Classes' do
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(pm.send(:load, klass_key)).to eq(klass)
    end
    it 'loads other' do
      obj = 'hello'
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(pm.send(:load, obj)).to eq(obj)
    end
  end
  
  describe '.perform' do
    it 'executes AR methods' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(ar).to receive(:play)
      pm.perform
    end
    it 'executes DM methods' do
      pm = ResqueDelay::PerformableMethod.new(dm, :play, [], nil, nil)
      expect(dm).to receive(:play)
      pm.perform
    end
    it 'executes Class methods' do
      pm = ResqueDelay::PerformableMethod.new(klass, :to_s, [], nil, nil)
      expect(klass).to receive(:to_s)
      pm.perform
    end
    it 'eats ActiveRecord::NotFound exceptions' do
      pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
      expect(ar).to receive(:play).and_raise(ActiveRecord::RecordNotFound)
      pm.perform
    end
    it 'does NOT eat exceptions other than ActiveRecord::NotFound' do
      expect do
        pm = ResqueDelay::PerformableMethod.new(ar, :play, [], nil, nil)
        expect(ar).to receive(:play).and_raise(::RuntimeError)
        pm.perform
      end.to raise_error(::RuntimeError)
    end
  end
end
