module Fog
  module Bouncer
    module CLI
      class DiffCommand < AbstractCommand
        def execute
          specific_groups = groups

          doorlist = Fog::Bouncer.load(file)
          doorlist.import_remote_groups
          groups = doorlist.groups
          groups = groups.select { |g| specific_groups.include?(g.name) } if specific_groups.any?

          groups.each do |group|
            if group.local? && !group.remote?
              puts "ec2-create-group #{group.name} -d '#{group.description}'"
            end

            group.sources.each do |source|
              source.protocols.each do |protocol|
                if protocol.local? && !protocol.remote?
                  authorize_cmd = "ec2-authorize #{protocol.group.name} -P #{protocol.type}"
                  if protocol.type == "icmp"
                    authorize_cmd << " -t #{protocol.from}:#{protocol.to}"
                  else
                    authorize_cmd << " -p #{protocol.from}-#{protocol.to}"
                  end

                  if source.is_a?(Fog::Bouncer::Sources::CIDR)
                    authorize_cmd << " -s #{source.range}"
                  else
                    authorize_cmd << " -u #{source.user_id} -o #{source.name}"
                  end

                  puts authorize_cmd
                elsif !protocol.local? && protocol.remote?
                  revoke_cmd = "ec2-revoke #{protocol.group.name} -P #{protocol.type}"
                  if protocol.type == "icmp"
                    revoke_cmd << " -t #{protocol.from}:#{protocol.to}"
                  else
                    revoke_cmd << " -p #{protocol.from}-#{protocol.to}"
                  end

                  puts revoke_cmd
                end
              end
            end

            if group.remote? && !group.local?
              puts "ec2-delete-group #{group.name}"
            end
          end
        end
      end
    end
  end
end
