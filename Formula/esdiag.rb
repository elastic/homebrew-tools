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
      url "https://github.com/elastic/esdiag/releases/download/0.16.5/esdiag-0.16.5-aarch64-apple-darwin.tar.gz"
      sha256 "c6840956502d3087c02fb82e9c108c7336d2c3ec6f3cdc4c5fccf68a6ac3445f"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/archive/refs/tags/0.16.5.tar.gz"
      sha256 "afa6dddb168f5ab18e0bdd04136ef7ff7a1de80e9863b4d59f2a882816df33bd"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.16.5/esdiag-0.16.5-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "844515ca3fa6337bd04a7d2eb6c0c0d4076fe4e8365b91e98bd114457041d555"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/releases/download/0.16.5/esdiag-0.16.5-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "32a5152fb4cfd32e58e1752157a947d34ba25f7c3ca866adf0d0c32b876cc78b"
    end
  end

  def install
    if (buildpath/"Cargo.toml").exist?
      ENV["ESDIAG_GENERATE_NOTICE"] = "0"
      system "cargo", "install", *std_cargo_args
    else
      bin.install "esdiag"
    end
    prefix.install "LICENSE.txt", "NOTICE.txt"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/esdiag --version")
  end
end
