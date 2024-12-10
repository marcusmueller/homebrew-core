class Scala < Formula
  desc "JVM-based programming language"
  homepage "https://www.scala-lang.org/"
  url "https://github.com/scala/scala3/releases/download/3.6.2/scala3-3.6.2.tar.gz"
  sha256 "9525b93f8b9488330ecbdb85df3046d3ef46c6760ac23248902c4d89194c5206"
  license "Apache-2.0"

  livecheck do
    url "https://www.scala-lang.org/download/"
    regex(%r{href=.*?download/v?(\d+(?:\.\d+)+)\.html}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "7a0c887cea761759face114d09e5b29559dac305e7695dd9c0273f039f8edf1e"
  end

  # JDK Compatibility: https://docs.scala-lang.org/overviews/jdk-compatibility/overview.html
  depends_on "openjdk"

  conflicts_with "pwntools", because: "both install `common` binaries"

  def install
    # fix `scala-cli.jar` path, upstream pr ref, https://github.com/scala/scala3/pull/22185
    inreplace "libexec/cli-common-platform", "bin/scala-cli", "libexec/scala-cli"

    rm Dir["bin/*.bat"]

    libexec.install "lib", "maven2", "VERSION", "libexec"
    prefix.install "bin"
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env

    # Set up an IntelliJ compatible symlink farm in 'idea'
    idea = prefix/"idea"
    idea.install_symlink libexec/"lib"
  end

  def caveats
    <<~EOS
      To use with IntelliJ, set the Scala home to:
        #{opt_prefix}/idea
    EOS
  end

  test do
    file = testpath/"Test.scala"
    file.write <<~SCALA
      object Test {
        def main(args: Array[String]): Unit = {
          println(s"${2 + 2}")
        }
      }
    SCALA

    out = shell_output("#{bin}/scala #{file}").strip

    assert_equal "4", out
  end
end
