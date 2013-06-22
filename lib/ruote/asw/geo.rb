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

  # S3
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

  S3_REGIONS =
    [
      %w[ eu-west-1 eu europe ireland euro ],
      %w[ us-west-1 oregon ],
      %w[ us-west-2 california cali norcal ],
      %w[ ap-southeast-1 singapore ],
      %w[ ap-southeast-2 sidney australia oz ],
      %w[ ap-northeast-1 tokyo edo japan nippon yamato ],
      %w[ sa-east-1 saopaulo brazil ]
    ].inject({}) { |h, a| h[a.first] = a; h }

  # Given a [S3] region nickname (or full name), returns the regiion fullname
  # (endpoint host).
  #
  def self.lookup_s3_region(name)

    n = name.to_s.downcase

    region =
      if n.match(/^[a-z]{2}-[a-z]+-\d+$/)
        # accept 'new' endpoints specified directly
        n
      else
        (S3_REGIONS.find { |k, v| v.include?(n) } || []).first
      end

    raise ArgumentError.new(
      "unknown S3 region: #{name.inspect}"
    ) unless region

    region
  end
end

