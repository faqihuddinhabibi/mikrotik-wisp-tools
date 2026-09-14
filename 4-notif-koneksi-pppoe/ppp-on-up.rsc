# On Up: catat pelanggan TERHUBUNG ke antrian (tanpa kirim)
:global pppNotifUp
:if ([:typeof $pppNotifUp] = "nothing") do={ :set pppNotifUp "" }
:set pppNotifUp ($pppNotifUp . $user . ", ")
