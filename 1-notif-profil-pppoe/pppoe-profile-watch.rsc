# PPPoE Profile Watcher -> Telegram (profil berubah / baru / dihapus)

# ---- GANTI ----
:local botToken "GANTI_BOT_TOKEN"
:local chatId   "GANTI_CHAT_ID"
# ---------------

:global pppoeProfileState
:global pppoeWatchBusy
:if ([:typeof $pppoeWatchBusy] = "nothing") do={ :set pppoeWatchBusy false }
:if ($pppoeWatchBusy = true) do={
    :log warning "pppoe-watch: run sebelumnya masih jalan, dilewati"
} else={
:set pppoeWatchBusy true
:do {

:local firstRun ([:typeof $pppoeProfileState] = "nothing")
:local prev $pppoeProfileState
:if ($firstRun) do={ :set prev [:toarray ""] }

:local bersih do={
    :local out ""
    :local n [:len $1]
    :if ($n > 0) do={
        :for i from=0 to=($n - 1) do={
            :local ch [:pick $1 $i ($i + 1)]
            :if ($ch = "\"" || $ch = "\\") do={ :set ch "'" }
            :set out ($out . $ch)
        }
    }
    :return $out
}

:local newState [:toarray ""]
:local baris ""
:local jml 0

:foreach r in=[/ppp secret print as-value] do={
    :local nama ($r->"name")
    :local prof ($r->"profile")
    :if ([:typeof ($newState->$nama)] != "nothing") do={
        :log warning ("pppoe-watch: nama secret duplikat dilewati: " . $nama)
    } else={
        :set ($newState->$nama) $prof
        :local old ($prev->$nama)
        :if ([:typeof $old] = "nothing") do={
            :if (!$firstRun) do={
                :set baris ($baris . [$bersih $nama] . ": BARU (" . [$bersih $prof] . ")\\n")
                :set jml ($jml + 1)
            }
        } else={
            :if ($old != $prof) do={
                :set baris ($baris . [$bersih $nama] . ": " . [$bersih $old] . " -> " . [$bersih $prof] . "\\n")
                :set jml ($jml + 1)
            }
        }
    }
}

:foreach nm,pr in=$prev do={
    :if ([:typeof ($newState->$nm)] = "nothing") do={
        :set baris ($baris . [$bersih $nm] . ": DIHAPUS (" . [$bersih $pr] . ")\\n")
        :set jml ($jml + 1)
    }
}

:local ok true
:if ((!$firstRun) && ($jml > 0)) do={
    :local sisa $baris
    :local pertama true
    :while (([:len $sisa] > 0) && $ok) do={
        :local potong $sisa
        :if ([:len $sisa] > 3500) do={
            :local cut [:find $sisa "\\n" 3400]
            :if ([:typeof $cut] = "num") do={ :set potong [:pick $sisa 0 ($cut + 2)] }
        }
        :set sisa [:pick $sisa [:len $potong] [:len $sisa]]
        :local teks ""
        :if ($pertama) do={
            :set teks ("Perubahan PPPoE (" . $jml . ")\\n" . $potong)
        } else={
            :set teks ("(lanjutan)\\n" . $potong)
        }
        :do {
            /tool fetch keep-result=no http-method=post \
                http-header-field="Content-Type: application/json" \
                url=("https://api.telegram.org/bot" . $botToken . "/sendMessage") \
                http-data=("{\"chat_id\":\"" . $chatId . "\",\"text\":\"" . $teks . "\"}")
        } on-error={
            :set ok false
            :log warning "pppoe-watch: gagal kirim Telegram, diulang run berikutnya"
        }
        :set pertama false
        :if (([:len $sisa] > 0) && $ok) do={ :delay 3s }
    }
}

:if ($firstRun || ($jml = 0) || $ok) do={ :set pppoeProfileState $newState }

} on-error={ :log error "pppoe-watch: error tak terduga, state tidak diubah" }
:set pppoeWatchBusy false
}
