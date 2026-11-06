# /// script
# requires-python = ">=3.10"
# dependencies = ["lupa>=2.0"]
# ///
"""Out-of-game test harness for MoldFilterForver's Core/ logic.

Loads the addon's Core files into a Lua runtime exactly as the game would (each file is
compiled and called with ("MoldFilterForver", ns)), then runs every tests/test_*.lua, which
register cases with T.case(name, fn). Exit code is non-zero on any failure.

Run with:  uv run tests/run_tests.py
"""
import pathlib
import sys

try:
    from lupa.luajit21 import LuaRuntime  # Lua 5.1 semantics, closest to the WoW client
except ImportError:  # pragma: no cover
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError:
        from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = "MoldFilterForver"
CORE_FILES = [
    ROOT / ADDON / "Core" / "Detect.lua",
    ROOT / ADDON / "Core" / "Sources.lua",
    ROOT / ADDON / "Core" / "Config.lua",
    ROOT / ADDON / "Core" / "Filter.lua",
]

PRELUDE = b"""
local T = { cases = {} }
function T.case(name, fn) T.cases[#T.cases + 1] = { name = name, fn = fn } end
function T.eq(got, want, msg)
    if got ~= want then
        error((msg or "value") .. ": expected " .. tostring(want) .. ", got " .. tostring(got), 2)
    end
end
function T.ok(v, msg) if not v then error(msg or "expected truthy", 2) end end
function T.no(v, msg) if v then error(msg or "expected falsy", 2) end end
return T
"""


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_chunk = lua.eval("loadstring or load")

    def compile_or_exit(code: bytes, name: str):
        # loadstring/load return one value (the chunk) on success, (nil, err) on failure
        result = compile_chunk(code, name)
        if isinstance(result, tuple):
            raise SystemExit(f"compile error in {name}: {result[1]}")
        return result

    def load(path: pathlib.Path, *args):
        return compile_or_exit(path.read_bytes(), "@" + path.name)(*args)

    ns = lua.table()
    for core in CORE_FILES:
        load(core, ADDON, ns)

    T = compile_or_exit(PRELUDE, "@prelude")()

    for test_file in sorted((ROOT / "tests").glob("test_*.lua")):
        load(test_file, ns, T)

    pcall = lua.globals().pcall
    passed = failed = 0
    for i in range(1, len(T.cases) + 1):
        case = T.cases[i]
        result = pcall(case.fn, ns)
        ok, err = (result, None) if not isinstance(result, tuple) else (result[0], result[1])
        if ok:
            passed += 1
            print(f"ok    {case.name}")
        else:
            failed += 1
            print(f"FAIL  {case.name}\n      {err}")
    print(f"\n{passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
