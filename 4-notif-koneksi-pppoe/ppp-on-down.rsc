# On Down: catat pelanggan TERPUTUS ke antrian (tanpa kirim)
:global pppNotifDown
:if ([:typeof $pppNotifDown] = "nothing") do={ :set pppNotifDown "" }
:set pppNotifDown ($pppNotifDown . $user . ", ")
