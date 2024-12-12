class WebtorrentCli < Formula
  desc "Command-line streaming torrent client"
  homepage "https://webtorrent.io/"
  url "https://registry.npmjs.org/webtorrent-cli/-/webtorrent-cli-5.1.3.tgz"
  sha256 "54a53ecdacbccf0f6855bd4ef18f4f154576f8346e3b7aef3792b66dd5aaaa1b"
  license "MIT"

  bottle do
    sha256                               arm64_sequoia:  "ecd646330d6ddbc709a443847e787cf35abc23b43865aa5ba3de186971b5118f"
    sha256                               arm64_sonoma:   "15ab8aafa171323e2e057633f8cfff9f23347cdf7f79777082a5b059d26eb19f"
    sha256                               arm64_ventura:  "be8479b3f65c2a5c11794f53d04ee02357a76bf3c65f5bc410ffc09e805906f8"
    sha256                               arm64_monterey: "0e582b5e95bd7ae1462caca1b66e796fa83553b75dcf9c1b98b7e4e36f2f57bf"
    sha256                               arm64_big_sur:  "4658471f872e03c58d8f1ace044942a3debb7e6ad9dbf2a1ac9546e93efde890"
    sha256                               sonoma:         "94a07b753cec7f30b5270432acd7002e577cd89f76df36ac1c0834c94dad7743"
    sha256                               ventura:        "7fabff21cbe0391c790a9c05b0a98694ce054223981e012c1d0e65932ff8f63a"
    sha256                               monterey:       "257f5b960d1291aa153aff64eb1785ae36512bb78516d7d2d132d52a9ff44671"
    sha256                               big_sur:        "3dc242aefbede7812f1bf60486f7f6627590942b96e44af31197cfaf088e7d0f"
    sha256                               catalina:       "066aab7a937b40b19e50cc2efe6e336aa89dccbd958022d79e8956a10aa4eaa3"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "5b87f6ede3b7fa60052d477c30c12c72f2cf0d2c50223376d05579c5f43e7ee1"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]

    nm = libexec/"lib/node_modules/webtorrent-cli/node_modules"

    # Avoid references to the Homebrew shims directory
    sb = nm/"node-datachannel/build"
    shims_references = Dir[
      sb/"CMakeFiles/CMakeConfigureLog.yaml",
      sb/"CMakeFiles/rules.ninja",
      sb/"CMakeFiles/3.31.2/CMakeCXXCompiler.cmake",
      sb/"CMakeFiles/3.31.2/CMakeCCompiler.cmake",
      sb/"_deps/libdatachannel-subbuild/CMakeLists.txt",
      sb/"_deps/libdatachannel-subbuild/libdatachannel-populate-prefix/tmp/libdatachannel-populate-gitclone.cmake",
      sb/"_deps/libdatachannel-subbuild/libdatachannel-populate-prefix/tmp/libdatachannel-populate-gitupdate.cmake",
      sb/"CMakeCache.txt",
    ].select { |f| File.file? f }
    inreplace shims_references,
              Superenv.shims_path.to_s,
              "<**Reference to the Homebrew shims directory**>",
              audit_result: false

    # Remove incompatible pre-built binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    libexec.glob(nm/"{bare-fs,bare-os,bufferutil,fs-native-extensions,utp-native,utf-8-validate}/prebuilds/*")
           .each do |dir|
      rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}"
    end
  end

  test do
    magnet_uri = <<~EOS.gsub(/\s+/, "").strip
      magnet:?xt=urn:btih:9eae210fe47a073f991c83561e75d439887be3f3
      &dn=archlinux-2017.02.01-x86_64.iso
      &tr=udp://tracker.archlinux.org:6969
      &tr=https://tracker.archlinux.org:443/announce
    EOS

    expected_output_raw = <<~JSON
      {
        "xt": "urn:btih:9eae210fe47a073f991c83561e75d439887be3f3",
        "dn": "archlinux-2017.02.01-x86_64.iso",
        "tr": [
          "https://tracker.archlinux.org:443/announce",
          "udp://tracker.archlinux.org:6969"
        ],
        "infoHash": "9eae210fe47a073f991c83561e75d439887be3f3",
        "name": "archlinux-2017.02.01-x86_64.iso",
        "announce": [
          "https://tracker.archlinux.org:443/announce",
          "udp://tracker.archlinux.org:6969"
        ],
        "urlList": []
      }
    JSON
    expected_json = JSON.parse(expected_output_raw)
    actual_output_raw = shell_output("#{bin}/webtorrent info '#{magnet_uri}'")
    actual_json = JSON.parse(actual_output_raw)
    assert_equal expected_json["tr"].to_set, actual_json["tr"].to_set
    assert_equal expected_json["announce"].to_set, actual_json["announce"].to_set
  end
end
