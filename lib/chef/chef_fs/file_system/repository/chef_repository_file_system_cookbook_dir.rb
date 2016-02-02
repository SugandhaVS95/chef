#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbook_entry"
require "chef/chef_fs/file_system/chef_server/cookbook_dir"
require "chef/chef_fs/file_system/chef_server/versioned_cookbook_dir"
require "chef/chef_fs/file_system/not_found_error"
require "chef/cookbook/chefignore"
require "chef/cookbook/cookbook_version_loader"

class Chef
  module ChefFS
    module FileSystem
      module Repository
        class ChefRepositoryFileSystemCookbookDir < ChefRepositoryFileSystemCookbookEntry
          def chef_object
            begin
              cb = cookbook_version
              if !cb
                Chef::Log.error("Cookbook #{file_path} empty.")
                raise "Cookbook #{file_path} empty."
              end
              cb
            rescue => e
              Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{e}")
              Chef::Log.error(e.backtrace.join("\n"))
              raise
            end
          end

          def children
            super.select { |entry| !(entry.dir? && entry.children.size == 0 ) }
          end

          def can_have_child?(name, is_dir)
            if is_dir
              # Only the given directories will be uploaded.
              return Chef::ChefFS::FileSystem::ChefServer::CookbookDir::COOKBOOK_SEGMENT_INFO.keys.include?(name.to_sym) && name != "root_files"
            elsif name == Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE
              return false
            end
            super(name, is_dir)
          end

          # Exposed as a class method so that it can be used elsewhere
          def self.canonical_cookbook_name(entry_name)
            name_match = Chef::ChefFS::FileSystem::ChefServer::VersionedCookbookDir::VALID_VERSIONED_COOKBOOK_NAME.match(entry_name)
            return nil if name_match.nil?
            return name_match[1]
          end

          def canonical_cookbook_name(entry_name)
            self.class.canonical_cookbook_name(entry_name)
          end

          def uploaded_cookbook_version_path
            File.join(file_path, Chef::Cookbook::CookbookVersionLoader::UPLOADED_COOKBOOK_VERSION_FILE)
          end

          def can_upload?
            File.exists?(uploaded_cookbook_version_path) || children.size > 0
          end

          protected

          def make_child_entry(child_name)
            segment_info = Chef::ChefFS::FileSystem::ChefServer::CookbookDir::COOKBOOK_SEGMENT_INFO[child_name.to_sym] || {}
            ChefRepositoryFileSystemCookbookEntry.new(child_name, self, nil, segment_info[:ruby_only], segment_info[:recursive])
          end

          def cookbook_version
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            loader.load_cookbooks
            cb = loader.cookbook_version
          end
        end
      end
    end
  end
end
