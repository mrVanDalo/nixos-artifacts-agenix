let
  mrvandalo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILE1jxUxvujFaj8kSjwJuNVRUinNuHsGeXUGVG6/lA1O";
  users = [ mrvandalo ];
in
{
  # todo generate this
  "secrets/per-machine/example/attic/env.age".publicKeys = users;
  "secrets/per-machine/example/test/secret.age".publicKeys = users;
}
