# cloudstack_userdata.rb:
#
# This script will load the userdata associated with a CloudStack
# guest VM into a collection of puppet facts. It is assumed that
# the userdata is formated as key=value pairs, one pair per line.
# For example, if you set your userdata to "role=foo\nenv=development\n"
# two facts would be created, "role" and "env", with values
# "foo" and "development", respectively. 
#
# A guest VM can get access to its userdata by making an http
# call to its virtual router. We can determine the IP address
# of the virtual router by inspecting the dhcp lease file on 
# the guest VM.
#
# Copyright (c) 2012 Jason Hancock <jsnbyh@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'facter'

ENV['PATH']='/bin:/sbin:/usr/bin:/usr/sbin'

# The dirs to search for the dhcp lease files in. Works for RHEL/CentOS and Ubuntu
dirs = ['/var/lib/dhclient', '/var/lib/dhcp3']

regex = Regexp.new(/dhclient.+lease/)

dirs.each do |lease_dir|
    if !File.directory? lease_dir 
        next 
    end

    Dir.entries(lease_dir).each do |file|
        result = regex.match(file)
    
        # Expand file back into the absolute path
        file = lease_dir + '/' + file

        if result && File.size?(file) != nil
            cmd = sprintf("grep dhcp-server-identifier %s | tail -1 | awk '{print $NF}' | /usr/bin/tr '\;' ' '", file)
        
            virtual_router = `#{cmd}`
            virtual_router.strip!

            cmd = sprintf('wget -q -O - http://%s/latest/user-data', virtual_router)
            result = `#{cmd}`

            lines = result.split("\n")

            lines.each do |line|
                if line =~ /^(.+)=(.+)$/
                    var = $1; val = $2

                    Facter.add(var) do
                        setcode { val }
                    end
                end
            end

            # use the older method of http://virtual_router_ip/latest/{metadata-type}
            # because the newer http://virtual_router_ip/latest/meta-data/{metadata-type}
            # was 404'ing on CloudStack v2.2.12 
            cmd = sprintf('wget -q -O - http://%s/latest/instance-id', virtual_router)
            result = `#{cmd}`

            Facter.add('instance_id') do
                setcode { result }
            end
        end
    end
end
