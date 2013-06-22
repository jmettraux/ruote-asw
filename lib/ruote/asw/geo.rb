#--
# Copyright (c) 2012-2013, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote::Asw

  # AWS SWF
  #
  # http://docs.aws.amazon.com/general/latest/gr/rande.html
  #
  # 2013/06/22
  #
  # US East (Northern Virginia) Region     swf.us-east-1.amazonaws.com
  # US West (Oregon) Region                swf.us-west-2.amazonaws.com
  # US West (Northern California) Region   swf.us-west-1.amazonaws.com
  # EU (Ireland) Region                    swf.eu-west-1.amazonaws.com
  # Asia Pacific (Singapore) Region        swf.ap-southeast-1.amazonaws.com
  # Asia Pacific (Sydney) Region           swf.ap-southeast-2.amazonaws.com
  # Asia Pacific (Tokyo) Region            swf.ap-northeast-1.amazonaws.com
  # South America (Sao Paulo) Region       swf.sa-east-1.amazonaws.com

  # AWS S3
  #
  # http://docs.aws.amazon.com/general/latest/gr/rande.html
  #
  # 2013/06/22
  #
  # US Standard *               s3.amazonaws.com
  # US West (Oregon)            s3-us-west-2.amazonaws.com us-west-2
  # US West (Nor. California)   s3-us-west-1.amazonaws.com us-west-1
  # EU (Ireland)                s3-eu-west-1.amazonaws.com
  # Asia Pac. (Singapore)       s3-ap-southeast-1.amazonaws.com ap-southeast-1
  # Asia Pac. (Sydney)          s3-ap-southeast-2.amazonaws.com ap-southeast-2
  # Asia Pacific (Tokyo)        s3-ap-northeast-1.amazonaws.com ap-northeast-1
  # South America (Sao Paulo)   s3-sa-east-1.amazonaws.com sa-east-1

  POINTS =
    [
      %w[ eu-west-1 eu ireland ie ],
      %w[ us-east-1 va virginia east1 ],
      %w[ us-west-2 or oregon west2 ],
      %w[ us-west-1 ca california cali norcal west1 ],
      %w[ ap-southeast-1 singapore sin ],
      %w[ ap-southeast-2 sydney aus australia oz ],
      %w[ ap-northeast-1 tokyo edo japan nippon yamato ],
      %w[ sa-east-1 saopaulo brazil ],
    ].inject({}) { |h, a| h[a.first] = a; h }

  def self.lookup_point(name)

    n = name.to_s.downcase

    return n if n.match(/^[a-z]{2}-[a-z]+-\d+$/)
      # accept endpoints specified directly

    (POINTS.find { |k, v| v.include?(n) } || []).first
  end

  # Given a [S3] region nickname (or full name), returns the region fullname
  # (endpoint host).
  #
  def self.lookup_s3_region(name)

    region = lookup_point(name)

    raise ArgumentError.new(
      "unknown S3 region: #{name.inspect}"
    ) unless region

    region
  end

  # Given an SWF endpoint nickname (or full name), return the endpoint full
  # host name.
  #
  def self.lookup_swf_endpoint(name)

    name ||= 'east1'

    return name.chomp('/') if name.match(/^https:\/\/swf\./)
      # if the endpoint if fed as is, let's return it

    point = lookup_point(name)

    raise ArgumentError.new(
      "unknown SWF endpoint: #{name.inspect}"
    ) unless point

    "https://swf.#{point}.amazonaws.com"
  end
end

