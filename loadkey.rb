# sunaemonRT-univ と同じ

module LoadKey
  def load_key(file)
    keypath = File.expand_path("../secret/#{file}", __FILE__)
    open(keypath) {|input|
      return input.read.chomp
    }
  end
end
