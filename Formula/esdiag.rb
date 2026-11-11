class Esdiag < Formula
  desc "Collect and process Elastic Stack diagnostic bundles"
  homepage "https://github.com/elastic/esdiag"
  license "Elastic-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.17.2/esdiag-0.17.2-aarch64-apple-darwin.tar.gz"
      sha256 "9d2c11265a803c65d5c0044dc4ba72a557dcae2bb0510b6e936095780105f9a3"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/archive/refs/tags/0.17.2.tar.gz"
      sha256 "a9117b20822db7a8cfcd56a4fa4d6ca6654e441130841bc48154630bcc72d484"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.17.2/esdiag-0.17.2-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "5c6564ef6d341667033de88ef946f4ce56b7e11d09e3447b42db976a7459b09a"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/releases/download/0.17.2/esdiag-0.17.2-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "e4a4f17c3f95711a18ecbf0e0721b73b17b833cd69d741a9645e3a29adc2eaba"
    end
  end

  def install
    if (buildpath/"Cargo.toml").exist?
      ENV["ESDIAG_GENERATE_NOTICE"] = "0"
      system "cargo", "install", *std_cargo_args
    else
      bin.install "esdiag"
    end
    prefix.install "LICENSE.txt", "NOTICES.md"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/esdiag --version")
  end
end
