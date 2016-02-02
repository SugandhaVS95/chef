#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Will Albenzi (<walbenzi@gmail.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Knife::RoleEnvRunListSet do
  before(:each) do
    Chef::Config[:role_name]  = "will"
    Chef::Config[:env_name]  = "QA"
    @setup = Chef::Knife::RoleEnvRunListAdd.new
    @setup.name_args = [ "will", "QA", "role[monkey]", "role[person]", "role[bucket]" ]

    @knife = Chef::Knife::RoleEnvRunListSet.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = [ "will", "QA", "role[owen]", "role[mauntel]" ]
    allow(@knife).to receive(:output).and_return(true)

    @role = Chef::Role.new()
    @role.name("will")
    allow(@role).to receive(:save).and_return(true)

    allow(@knife.ui).to receive(:confirm).and_return(true)
    allow(Chef::Role).to receive(:load).and_return(@role)

  end



  describe "run" do


#    it "should display all the things" do
#      @knife.run
#      @role.to_json.should == 'show all the things'
#    end

    it "should load the node" do
      expect(Chef::Role).to receive(:load).with("will").and_return(@role)
      @knife.run
    end

    it "should replace all the items in the runlist with what is specified" do
      @setup.run
      @knife.run
      expect(@role.run_list_for("QA")[0]).to eq("role[owen]") 
      expect(@role.run_list_for("QA")[1]).to eq("role[mauntel]") 
      expect(@role.run_list_for("QA")[2]).to be_nil
      expect(@role.run_list[0]).to be_nil
    end

    it "should save the node" do
      expect(@role).to receive(:save).and_return(true)
      @knife.run
    end

    it "should print the run list" do
      expect(@knife).to receive(:output).and_return(true)
      @knife.config[:print_after] = true
      @setup.run
      @knife.run
    end

    describe "should clear an environmental run list of roles and recipes" do
      it "should remove the items from the run list" do
        @setup.name_args = [ "will", "QA", "recipe[orange::chicken]", "role[monkey]", "recipe[duck::type]", "role[person]", "role[bird]", "role[town]" ]
        @setup.run
        @setup.name_args = [ "will", "PRD", "recipe[orange::chicken]", "role[monkey]", "recipe[duck::type]", "role[person]", "role[bird]", "role[town]" ]
        @setup.run
        @knife.name_args = [ "will", "QA", "role[coke]", "role[pepsi]" ]
        @knife.run
        expect(@role.run_list_for("QA")[0]).to eq("role[coke]")
        expect(@role.run_list_for("QA")[1]).to eq("role[pepsi]")
        expect(@role.run_list_for("QA")[2]).to be_nil
        expect(@role.run_list_for("PRD")[0]).to eq("recipe[orange::chicken]")
        expect(@role.run_list_for("PRD")[1]).to eq("role[monkey]")
        expect(@role.run_list_for("PRD")[2]).to eq("recipe[duck::type]")
        expect(@role.run_list_for("PRD")[3]).to eq("role[person]")
        expect(@role.run_list_for("PRD")[4]).to eq("role[bird]")
        expect(@role.run_list_for("PRD")[5]).to eq("role[town]")
        expect(@role.run_list[0]).to be_nil
      end
    end
  end
end
