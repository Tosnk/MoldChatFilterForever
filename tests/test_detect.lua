-- Tests for Core/Detect.lua. Receives (ns, T) from tests/run_tests.py.
local ns, T = ...

T.case("IsCyrillic: Russian text", function()
    T.ok(ns.IsCyrillic("Привет, кто в УБРС?"))
end)

T.case("IsCyrillic: Ukrainian-only letters і ї є ґ", function()
    T.ok(ns.IsCyrillic("і"))
    T.ok(ns.IsCyrillic("ї"))
    T.ok(ns.IsCyrillic("є"))
    T.ok(ns.IsCyrillic("ґ"))
end)

T.case("IsCyrillic: Serbian ђ and Cyrillic Supplement edges", function()
    T.ok(ns.IsCyrillic("ђ"))
    T.ok(ns.IsCyrillic("\208\128"), "U+0400")          -- first Cyrillic
    T.ok(ns.IsCyrillic("\211\191"), "U+04FF")          -- last of main block
    T.ok(ns.IsCyrillic("\212\128"), "U+0500")          -- first of Supplement
    T.ok(ns.IsCyrillic("\212\175"), "U+052F")          -- last of Supplement
end)

T.case("IsCyrillic: single Cyrillic letter inside Latin text", function()
    T.ok(ns.IsCyrillic("WTS [Шлем] 50g"))
end)

T.case("IsCyrillic: plain ASCII is not Cyrillic", function()
    T.no(ns.IsCyrillic("LFM UBRS need healer, pst"))
    T.no(ns.IsCyrillic("privet prodam gold"))
    T.no(ns.IsCyrillic("1234 !@#$ |cff00ff00|Hitem:123|h[Thing]|h|r"))
end)

T.case("IsCyrillic: accented Latin, Greek, CJK, emoji are not Cyrillic", function()
    T.no(ns.IsCyrillic("Ärger über Löwenherz çà ñ ø"))
    T.no(ns.IsCyrillic("αβγ Ωμέγα"))
    T.no(ns.IsCyrillic("日本語 한국어"))
    T.no(ns.IsCyrillic("😀🔥"))
end)

T.case("IsCyrillic: Armenian (right after Supplement) is not Cyrillic", function()
    T.no(ns.IsCyrillic("\212\176"), "U+0530")
    T.no(ns.IsCyrillic("Հայերեն"))
end)

T.case("IsCyrillic: nil and empty", function()
    T.no(ns.IsCyrillic(nil))
    T.no(ns.IsCyrillic(""))
end)

T.case("NameIsCyrillic: Cyrillic name with realm", function()
    T.ok(ns.NameIsCyrillic("Иван-Firemaw"))
    T.ok(ns.NameIsCyrillic("Иван"))
end)

T.case("NameIsCyrillic: Latin name, Cyrillic realm part ignored", function()
    T.no(ns.NameIsCyrillic("Bob-Реалм"))
    T.no(ns.NameIsCyrillic("Bob-Firemaw"))
    T.no(ns.NameIsCyrillic("Bob"))
end)

T.case("NameIsCyrillic: nil and empty", function()
    T.no(ns.NameIsCyrillic(nil))
    T.no(ns.NameIsCyrillic(""))
end)
