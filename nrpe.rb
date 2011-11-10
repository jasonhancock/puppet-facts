# nrpe.rb: A fact to be used in conjunction with puppet that outlines
#          how to load a particular installed rpm package's version
#          number into a fact
#
# Copyright (C) 2011 Jason Hancock http://geek.jasonhancock.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
#along with this program.  If not, see http://www.gnu.org/licenses/.

require 'facter'
 
result = %x{/bin/rpm -qa --queryformat "%{VERSION}-%{RELEASE}" nrpe}
 
Facter.add('nrpe') do
    setcode do
        result
    end
end
