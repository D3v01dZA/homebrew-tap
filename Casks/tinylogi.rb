cask "tinylogi" do
  version "0.3.0"
  sha256 "507b212d61831ebb9b4b13fe9f3148d81012fd049446a365f8e7850a366af640"

  url "https://github.com/D3v01dZA/tinylogi/releases/download/v#{version}/Tinylogi-#{version}.zip"
  name "tinylogi"
  desc "Minimal config daemon for Logitech HID++ mice"
  homepage "https://github.com/D3v01dZA/tinylogi"

  depends_on macos: ">= :ventura"

  app "Tinylogi.app"
  binary "#{appdir}/Tinylogi.app/Contents/MacOS/tinylogi"
  artifact "net.caltona.tinylogi.plist",
           target: "#{Dir.home}/Library/LaunchAgents/net.caltona.tinylogi.plist"

  postflight do
    # Signed with a self-signed certificate, not notarized, so skip Gatekeeper's download check.
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/Tinylogi.app"]
    system_command "/bin/launchctl",
                   args: ["bootstrap", "gui/#{Process.uid}",
                          "#{Dir.home}/Library/LaunchAgents/net.caltona.tinylogi.plist"]
  end

  uninstall launchctl: "net.caltona.tinylogi"

  zap trash: "~/.config/tinylogi.toml"

  caveats <<~EOS
    tinylogi is signed with a personal certificate. Trust it once on this Mac
    or macOS will refuse to launch it (SHA-1 46:09:5E:CF:A5:9F:B4:43:E0:66:93:E5:A4:5C:3C:BA:5A:EF:95:13):
      curl -fsSLO https://raw.githubusercontent.com/D3v01dZA/tinylogi/master/macos/tinylogi-cert.pem
      security add-trusted-cert -r trustRoot -p codeSign \\
        -k ~/Library/Keychains/login.keychain-db tinylogi-cert.pem

    Then:
      1. Create ~/.config/tinylogi.toml (see the example in the release zip or repo).
      2. Allow Tinylogi under System Settings → Privacy & Security →
         Input Monitoring and Accessibility, and also Device Control & Data
         Access if your macOS has it. It restarts by itself within 30s.

    After editing the config, apply it with: tinylogi --reload
    Log: /tmp/tinylogi.log
  EOS
end
