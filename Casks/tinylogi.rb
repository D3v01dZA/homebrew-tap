cask "tinylogi" do
  version "0.4.0"
  sha256 "95170c528f6baaa0b9b6d2dc40002292c3998cf3538dd1cb417c7bcf679e82a7"

  url "https://github.com/D3v01dZA/tinylogi/releases/download/v#{version}/Tinylogi-#{version}.zip"
  name "tinylogi"
  desc "Minimal config daemon for Logitech HID++ mice"
  homepage "https://github.com/D3v01dZA/tinylogi"

  depends_on macos: ">= :ventura"

  app "Tinylogi.app"
  binary "#{appdir}/Tinylogi.app/Contents/MacOS/tinylogi"
  artifact "net.caltona.tinylogi.plist",
           target: "#{Dir.home}/Library/LaunchAgents/net.caltona.tinylogi.plist"

  # Steps that may fail use Kernel#system: Cask's system_command raises, which aborts and rolls
  # back the whole install.
  postflight do
    # The app is signed with a personal certificate; macOS kills it at launch unless that
    # certificate is trusted for code signing. Ask (with macOS's password dialog) only if it isn't.
    cert = "#{staged_path}/tinylogi-cert.pem"
    unless system("/usr/bin/security", "verify-cert", "-c", cert, "-p", "codeSign", "-L", "-q",
                  [:out, :err] => File::NULL)
      system "/usr/bin/security", "add-trusted-cert", "-r", "trustRoot", "-p", "codeSign",
             "-k", "#{Dir.home}/Library/Keychains/login.keychain-db", cert
    end
    # Not notarized, so skip Gatekeeper's download check.
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/Tinylogi.app"]
    # On upgrade the old job may still be registered or tearing down; bootstrap fails with
    # EIO until launchd has let go of it, so stop it and retry briefly.
    domain = "gui/#{Process.uid}"
    system "/bin/launchctl", "bootout", "#{domain}/net.caltona.tinylogi", [:out, :err] => File::NULL
    plist = "#{Dir.home}/Library/LaunchAgents/net.caltona.tinylogi.plist"
    started = 10.times.any? do
      next true if system("/bin/launchctl", "bootstrap", domain, plist, [:out, :err] => File::NULL)

      sleep 1
      false
    end
    opoo "Could not start tinylogi; run: launchctl bootstrap #{domain} #{plist}" unless started
  end

  uninstall launchctl: "net.caltona.tinylogi"

  zap trash: "~/.config/tinylogi.toml"

  caveats <<~EOS
    tinylogi is signed with a personal certificate (SHA-1
    46:09:5E:CF:A5:9F:B4:43:E0:66:93:E5:A4:5C:3C:BA:5A:EF:95:13), which the
    install trusts for code signing after asking for your password. If that
    was skipped, macOS refuses to launch tinylogi; trust it by hand with:
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
