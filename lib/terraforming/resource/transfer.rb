module Terraforming
    module Resource
        class Transfer
            include Terraforming::Util
            require 'pry'

            def self.tf(client: Aws::Transfer::Client.new)
                self.new(client).tf
            end

            def self.tfstate(client: Aws::Transfer::Client.new)
                self.new(client).tfstate
            end

            def initialize(client)
                @client = client
            end

            def tf
                apply_template(@client, "tf/transfer")
            end

            def tfstate
                # vpcs.inject({}) do |resources, vpc|
                #   attributes = {
                #     "cidr_block" => vpc.cidr_block,
                #     "enable_dns_hostnames" => enable_dns_hostnames?(vpc).to_s,
                #     "enable_dns_support" => enable_dns_support?(vpc).to_s,
                #     "id" => vpc.vpc_id,
                #     "instance_tenancy" => vpc.instance_tenancy,
                #     "tags.#" => vpc.tags.length.to_s,
                #   }
                #   resources["aws_vpc.#{module_name_of(vpc)}"] = {
                #     "type" => "aws_vpc",
                #     "primary" => {
                #       "id" => vpc.vpc_id,
                #       "attributes" => attributes
                #     }
                #   }

                #   resources
                # end
                raise "Error"
            end

            # private

            # def enable_dns_hostnames?(vpc)
            #   vpc_attribute(vpc, :enableDnsHostnames).enable_dns_hostnames.value
            # end

            # def enable_dns_support?(vpc)
            #   vpc_attribute(vpc, :enableDnsSupport).enable_dns_support.value
            # end

            # def module_name_of(vpc)
            #   normalize_module_name(name_from_tag(vpc, vpc.vpc_id))
            # end

            # def vpcs
            #   @client.describe_vpcs.map(&:vpcs).flatten
            # end

            # def vpc_attribute(vpc, attribute)
            #   @client.describe_vpc_attribute(vpc_id: vpc.vpc_id, attribute: attribute)
            # end

            def instances()
                resp = server_ids().map{ |server_id| 
                    describe_instance(server_id)
                }
                resp
            end

            def server_ids()
                token = nil
                server_ids = []

                loop do
                    resp = @client.list_servers(next_token: token)
                    server_ids += resp.servers.map(&:server_id).flatten
                    token = resp.next_token
                    break if token.nil?
                end

                server_ids
            end


            def describe_instance(server_id) 
                server = @client.describe_server({server_id: server_id}).map(&:server)[0]
                {
                    :server => server, 
                    :users => users(server_id)
                }
            end

            def users(server_id) 
                token = nil
                users = []
                loop do
                    resp = @client.list_users( {server_id: server_id, next_token: token} )
                    users += resp.map(&:users).flatten
                    token = resp.next_token
                    break if token.nil?
                end
                users.map{ |user|
                    @client.describe_user(server_id: server_id, user_name: user.user_name).user
                } 
            end
        end
    end
end
