{ pkgs, ... }:

{
  packages = [ pkgs.nodejs pkgs.lua ];

  scripts.test.exec = "node test/run.js";
  scripts.test-live.exec = "node test/live.js";
}
