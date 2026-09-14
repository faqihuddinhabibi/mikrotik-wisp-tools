# On Down: hitung berapa kali user PUTUS (deteksi flap). Cuma :set, tanpa fetch.
# Pasang di kolom "On Down" profil PELANGGAN.
:global pppFlap
:if ([:typeof $pppFlap] = "nothing") do={ :set pppFlap [:toarray ""] }
:local c ($pppFlap->$user)
:if ([:typeof $c] = "nothing") do={ :set c 0 }
:set ($pppFlap->$user) ($c + 1)
