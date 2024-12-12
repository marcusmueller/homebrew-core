class Pyqt < Formula
  desc "Python bindings for v6 of Qt"
  homepage "https://www.riverbankcomputing.com/software/pyqt/intro"
  url "https://files.pythonhosted.org/packages/e9/0a/accbebed526158ab2aedd5c84d238159754bd99f481082b3fe7f374c6a3b/PyQt6-6.8.0.tar.gz"
  sha256 "6d8628de4c2a050f0b74462e4c9cb97f839bf6ffabbca91711722ffb281570d9"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:  "594fb397445a17b36d912f2cf432ddc211078592c6cb7b1c70fbc39aab3036de"
    sha256 cellar: :any,                 arm64_ventura: "886205540f0ec40b9f48e78e7574d8004164303da0c6ca77befdd6a0d7e2b03c"
    sha256 cellar: :any,                 sonoma:        "c4dea7eaef2da2fd9536ec568655c37f40136a76bd43b3513323da363d966515"
    sha256 cellar: :any,                 ventura:       "affd2a13886660f7292c28cffcfdd5464493cfc981cb9b3686ee73c653011698"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "ee5627b9d9e5c5715d46f4029b0daabf95d5aeb60acb6a906bb3f89aac68fdf0"
  end

  depends_on "pyqt-builder" => :build
  depends_on "python@3.12"
  depends_on "qt"

  # extra components
  resource "pyqt6-3d" do
    url "https://files.pythonhosted.org/packages/13/15/4eef4a5087e4af01638baee8fd1c22e97fce2eb593e73c7f1cf9f59dffa9/PyQt6_3D-6.8.0.tar.gz"
    sha256 "f62790a787cfc99fcd84c774fa952b83c877dd2175355a3a6609d37fe1a1c7a3"
  end

  resource "pyqt6-charts" do
    url "https://files.pythonhosted.org/packages/94/51/d37e1527dcf0e2bf5bfdba4200c2297a4224e299d79c4d4cfbe1a363e01b/PyQt6_Charts-6.8.0.tar.gz"
    sha256 "f86705b8740e3041667ce211aeaa205b750eb6baf4c908f4e3f6dc8c720d10f1"
  end

  resource "pyqt6-datavisualization" do
    url "https://files.pythonhosted.org/packages/3c/26/9006f1ff80fe800df3ea1b6f26bf61323e19acede5a3e55a115908638689/PyQt6_DataVisualization-6.8.0.tar.gz"
    sha256 "822a94163b8177b9dd507988aff4da7c79ce26bc47fc5f9780dea6989c531171"
  end

  resource "pyqt6-networkauth" do
    url "https://files.pythonhosted.org/packages/ee/79/3d67110608e7e6b55c501359699826dd861c21c668ccc9a8fbc99bfc528b/PyQt6_NetworkAuth-6.8.0.tar.gz"
    sha256 "2a1043ff6d03fc19e7bc87fad4f32d4d7e56d2bf1bb89b2a43287c0161457d59"
  end

  resource "pyqt6-sip" do
    url "https://files.pythonhosted.org/packages/2a/e4/f39ca1fd6de7d4823d964a3ec33e85b6f51a9c2a7a1e95956b7a92c8acc9/pyqt6_sip-13.9.1.tar.gz"
    sha256 "15be741d1ae8c82bb7afe9a61f3cf8c50457f7d61229a1c39c24cd6e8f4d86dc"
  end

  resource "pyqt6-webengine" do
    url "https://files.pythonhosted.org/packages/cd/c8/cadaa950eaf97f29e48c435e274ea5a81c051e745a3e2f5d9d994b7a6cda/PyQt6_WebEngine-6.8.0.tar.gz"
    sha256 "64045ea622b6a41882c2b18f55ae9714b8660acff06a54e910eb72822c2f3ff2"
  end

  def python3
    "python3.12"
  end

  def install
    # HACK: there is no option to set the plugindir
    inreplace "project.py", "builder.qt_configuration['QT_INSTALL_PLUGINS']", "'#{share}/qt/plugins'"

    sip_install = Formula["pyqt-builder"].opt_libexec/"bin/sip-install"
    site_packages = prefix/Language::Python.site_packages(python3)
    args = %W[
      --target-dir #{site_packages}
      --scripts-dir #{bin}
      --confirm-license
    ]
    system sip_install, *args

    resource("pyqt6-sip").stage do
      system python3, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."
    end

    resources.each do |r|
      next if r.name == "pyqt6-sip"
      # Don't build WebEngineCore bindings on macOS if the SDK is too old to have built qtwebengine in qt.
      next if r.name == "pyqt6-webengine" && OS.mac? && DevelopmentTools.clang_build_version <= 1200

      r.stage do
        inreplace "pyproject.toml", "[tool.sip.project]", <<~TOML
          [tool.sip.project]
          sip-include-dirs = ["#{site_packages}/PyQt#{version.major}/bindings"]
        TOML
        system sip_install, "--target-dir", site_packages
      end
    end
  end

  test do
    system bin/"pyuic#{version.major}", "-V"
    system bin/"pylupdate#{version.major}", "-V"

    system python3, "-c", "import PyQt#{version.major}"
    pyqt_modules = %w[
      3DAnimation
      3DCore
      3DExtras
      3DInput
      3DLogic
      3DRender
      Gui
      Multimedia
      Network
      NetworkAuth
      Positioning
      Quick
      Svg
      Widgets
      Xml
    ]
    # Don't test WebEngineCore bindings on macOS if the SDK is too old to have built qtwebengine in qt.
    pyqt_modules << "WebEngineCore" if OS.linux? || DevelopmentTools.clang_build_version > 1200
    pyqt_modules.each { |mod| system python3, "-c", "import PyQt#{version.major}.Qt#{mod}" }

    # Make sure plugin is installed as it currently gets skipped on wheel build,  e.g. `pip install`
    assert_predicate share/"qt/plugins/designer"/shared_library("libpyqt#{version.major}"), :exist?
  end
end
