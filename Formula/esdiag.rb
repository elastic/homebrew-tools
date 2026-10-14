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
      url "https://github.com/elastic/esdiag/releases/download/0.17.0/esdiag-0.17.0-aarch64-apple-darwin.tar.gz"
      sha256 "a6ce62fea1aab9370163d30b7ada1e85e0804fffddeb3e2d8703467d5872fc0a"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/archive/refs/tags/0.17.0.tar.gz"
      sha256 "29ca82da3a90537de6b74631fd99bae779bcd7f2fb24d3d71e9a87cabeb3742a"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.17.0/esdiag-0.17.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "c2972d975b0bcdc5f187d05bb6e149d08b638f351bd62e4d0cf8edc59fcf415c"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/releases/download/0.17.0/esdiag-0.17.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "e46cedc21f6ea92233cba27ff96fa9104cb72a515f74acdb4416d645f48407c7"
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
