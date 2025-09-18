{ config, lib, pkgs, ... }:
let
  sdk =  pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
      cloud-run-proxy
      cloud-sql-proxy
      log-streaming
      bq
    ]);
in
{
  home.packages = [ sdk ];
}
