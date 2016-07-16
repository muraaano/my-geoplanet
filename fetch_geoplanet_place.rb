require 'geoplanet'
require 'yaml'
require 'pry'

# Constant
APPID = ENV['GEOPLANET_APPID']
PLACE_ATTR = {
  lang: 'ja',
  count: 0,
  type: [7, 8, 9],
  select: 'long',
}
JAPAN_WOEID = 23424856

# Argument
place_woeid = (ARGV[0] || JAPAN_WOEID).to_i
file_name = (ARGV[1] || "geoplanet.yml")
debug_mode = (ARGV[2] || false)

# method
module GeoPlanet
  class Place
    def to_hash(parent)
      hash = {
        self.woeid => {
          parent: parent ? parent.woeid : nil,
          children: {}
        }
      }
      hash[self.woeid].merge! Hash[instance_variables.map {|i| [i.to_s.sub("@", ""), instance_variable_get(i)] }]
      return hash
    end
  end
end

def get_children_tree(place, parent, _array, _tree)
  yield place if block_given?

  hash = place.to_hash(parent)
  _array.merge!(hash)
  _tree.merge!(hash)

  children = place.children(PLACE_ATTR) || []
  children.each do |c|
    get_children_tree(c, place, _array, _tree[place.woeid][:children]) {|place| yield place if block_given?}
  end
end

# main
GeoPlanet.appid = APPID
GeoPlanet.debug = debug_mode

place = GeoPlanet::Place.new(place_woeid, lang:'ja')

array_hash = {}
tree_hash = {}
$place_num = 0
get_children_tree(place, nil, array_hash, tree_hash) { |place|
  $place_num += 1
  puts "fetching (" + $place_num.to_s + "): " + place.name + ", " + place.placetype
}

file_path = Dir.pwd + "/" + file_name
File.write(file_path, array_hash.to_yaml)

puts file_path + " successfully generated."
