require 'gitlab'
require 'modulesync/util'

module ModuleSync::PR
  class GitLab
    def initialize(token, endpoint)
      @api = Gitlab::Client.new(
        :endpoint => endpoint,
        :private_token => token,
      )
    end

    def manage(namespace, module_name, options)
      repo_path = File.join(namespace, module_name)

      head = "#{namespace}:#{options[:branch]}"
      merge_requests = @api.merge_requests(repo_path,
                                           :state => 'opened',
                                           :source_branch => head,
                                           :target_branch => 'master')
      if merge_requests.empty?
        mr_labels = ModuleSync::Util.parse_list(options[:pr_labels])
        mr = @api.create_merge_request(repo_path, options[:pr_title],
                                       :source_branch => options[:branch],
                                       :target_branch => 'master',
                                       :labels => mr_labels)
        $stdout.puts "Submitted MR '#{options[:pr_title]}' to #{repo_path} - merges #{options[:branch]} into master"
        return if mr_labels.empty?
        $stdout.puts "Attached the following labels to MR #{mr.iid}: #{mr_labels.join(', ')}"
      else
        # Skip creating the MR if it exists already.
        $stdout.puts "Skipped! #{merge_requests.length} MRs found for branch #{options[:branch]}"
      end
    end
  end
end
