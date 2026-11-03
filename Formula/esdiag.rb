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
      url "https://github.com/elastic/esdiag/releases/download/0.17.1/esdiag-0.17.1-aarch64-apple-darwin.tar.gz"
      sha256 "a35a6697216c9f8d5e2e59bb892859ce82891f5b1d2fe480f92164dde024ef66"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/archive/refs/tags/0.17.1.tar.gz"
      sha256 "6db95eb1b3eaaab953ed46e863ff344eb41b670ccd191cd0376849b0f2d23b28"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.17.1/esdiag-0.17.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "916fa8f3322e759ba0ff68970b5eb2f22869a64b08eba39b41e9667a409c286e"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/releases/download/0.17.1/esdiag-0.17.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a98cd571fa357ac17ba5f7babde4c880e8d8503e5272a78e0c1144f42dc71494"
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
