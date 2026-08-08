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
      url "https://github.com/elastic/esdiag/releases/download/0.16.4/esdiag-0.16.4-aarch64-apple-darwin.tar.gz"
      sha256 "4c0033ab6c6fd285051cdea93ac10935ddba3dfd7f17507b07b2e8a9adab774f"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/archive/refs/tags/0.16.4.tar.gz"
      sha256 "71de0f7cb34b13cab7b4a0878efffba860d310a23e171cce0bccb7c2eae9ed51"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/elastic/esdiag/releases/download/0.16.4/esdiag-0.16.4-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "0a4df39cf6f1c2193c8ba875cd2dc5af9c82bc897a05e81d7618b4911ed0ad20"
    end

    on_intel do
      url "https://github.com/elastic/esdiag/releases/download/0.16.4/esdiag-0.16.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "c6934c53c39121b4faa51526a10e2a6474eadeff1aeb71dd679e0f3467b26acb"
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
