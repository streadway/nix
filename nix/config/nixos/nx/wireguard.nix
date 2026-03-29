{ pkgs, ... }:
{
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  networking.nftables.enable = true;
  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.allowedTCPPorts = [ 31369 ];
  networking.useNetworkd = true;
  networking.firewall.checkReversePath = "loose";

  systemd.network = {
    enable = true;
    networks."50-wg0" = {
      matchConfig.Name = "wg0";
      address = [
        "fc00:bbbb:bbbb:bb01::4:d65d/128"
        "10.67.214.94/32"
      ];
      domains = [ "~." ];
      dns = [ "10.64.0.1" ];
      networkConfig = {
        DNSDefaultRoute = true;
      };
      routingPolicyRules = [
        {
          Priority = 8;
          To = "193.138.7.157/32";
        }
        {
          Priority = 9;
          User = "tm";
          Family = "both";
          SuppressPrefixLength = 0;
          Table = "main";
        }
        {
          Priority = 10;
          User = "tm";
          Family = "both";
          Table = 1000;
        }
      ];
    };

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };

      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = "/etc/wireguard/great_salmon.key";
        FirewallMark = 42;
      };

      wireguardPeers = [
        {
          PublicKey = "xeHVhXxyyFqUEE+nsu5Tzd/t9en+++4fVFcSFngpcAU=";
          AllowedIPs = [
            "::0/0"
            "0.0.0.0/0"
          ];
          Endpoint = "193.138.7.157:51820";
          RouteTable = 1000;
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    iproute2
    nftables
  ];
}
