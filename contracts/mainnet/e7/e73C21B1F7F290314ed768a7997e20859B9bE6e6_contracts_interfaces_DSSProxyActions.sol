pragma solidity ^0.6.0;

abstract contract GemLike {
    function approve(address, uint) public virtual;
    function transfer(address, uint) public virtual;
    function transferFrom(address, address, uint) public virtual;
    function deposit() public virtual payable;
    function withdraw(uint) public virtual;
}

abstract contract ManagerLike {
    function cdpCan(address, uint, address) public virtual view returns (uint);
    function ilks(uint) public virtual view returns (bytes32);
    function owns(uint) public virtual view returns (address);
    function urns(uint) public virtual view returns (address);
    function vat() public virtual view returns (address);
    function open(bytes32) public virtual returns (uint);
    function give(uint, address) public virtual;
    function cdpAllow(uint, address, uint) public virtual;
    function urnAllow(address, uint) public virtual;
    function frob(uint, int, int) public virtual;
    function frob(uint, address, int, int) public virtual;
    function flux(uint, address, uint) public virtual;
    function move(uint, address, uint) public virtual;
    function exit(address, uint, address, uint) public virtual;
    function quit(uint, address) public virtual;
    function enter(address, uint) public virtual;
    function shift(uint, uint) public virtual;
}

abstract contract VatLike {
    function can(address, address) public virtual view returns (uint);
    function ilks(bytes32) public virtual view returns (uint, uint, uint, uint, uint);
    function dai(address) public virtual view returns (uint);
    function urns(bytes32, address) public virtual view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public virtual;
    function hope(address) public virtual;
    function move(address, address, uint) public virtual;
}

abstract contract GemJoinLike {
    function dec() public virtual returns (uint);
    function gem() public virtual returns (GemLike);
    function join(address, uint) public virtual payable;
    function exit(address, uint) public virtual;
}

abstract contract GNTJoinLike {
    function bags(address) public virtual view returns (address);
    function make(address) public virtual returns (address);
}

abstract contract DaiJoinLike {
    function vat() public virtual returns (VatLike);
    function dai() public virtual returns (GemLike);
    function join(address, uint) public virtual payable;
    function exit(address, uint) public virtual;
}

abstract contract HopeLike {
    function hope(address) public virtual;
    function nope(address) public virtual;
}

abstract contract EndLike {
    function fix(bytes32) public virtual view returns (uint);
    function cash(bytes32, uint) public virtual;
    function free(bytes32) public virtual;
    function pack(uint) public virtual;
    function skim(bytes32, address) public virtual;
}

abstract contract JugLike {
    function drip(bytes32) public virtual;
}

abstract contract PotLike {
    function chi() public virtual view returns (uint);
    function pie(address) public virtual view returns (uint);
    function drip() public virtual;
    function join(uint) public virtual;
    function exit(uint) public virtual;
}

abstract contract ProxyRegistryLike {
    function proxies(address) public virtual view returns (address);
    function build(address) public virtual returns (address);
}

abstract contract ProxyLike {
    function owner() public virtual view returns (address);
}

abstract contract DssProxyActions {
    function daiJoin_join(address apt, address urn, uint wad) public virtual;
    function transfer(address gem, address dst, uint wad) public virtual;
    function ethJoin_join(address apt, address urn) public virtual payable;
    function gemJoin_join(address apt, address urn, uint wad, bool transferFrom) public virtual payable;

    function hope(address obj, address usr) public virtual;
    function nope(address obj, address usr) public virtual;

    function open(address manager, bytes32 ilk, address usr) public virtual returns (uint cdp);
    function give(address manager, uint cdp, address usr) public virtual;
    function giveToProxy(address proxyRegistry, address manager, uint cdp, address dst) public virtual;

    function cdpAllow(address manager, uint cdp, address usr, uint ok) public virtual;
    function urnAllow(address manager, address usr, uint ok) public virtual;
    function flux(address manager, uint cdp, address dst, uint wad) public virtual;
    function move(address manager, uint cdp, address dst, uint rad) public virtual;
    function frob(address manager, uint cdp, int dink, int dart) public virtual;
    function frob(address manager, uint cdp, address dst, int dink, int dart) public virtual;
    function quit(address manager, uint cdp, address dst) public virtual;
    function enter(address manager, address src, uint cdp) public virtual;
    function shift(address manager, uint cdpSrc, uint cdpOrg) public virtual;
    function makeGemBag(address gemJoin) public virtual returns (address bag);

    function lockETH(address manager, address ethJoin, uint cdp) public virtual payable;
    function safeLockETH(address manager, address ethJoin, uint cdp, address owner) public virtual payable;
    function lockGem(address manager, address gemJoin, uint cdp, uint wad, bool transferFrom) public virtual;
    function safeLockGem(address manager, address gemJoin, uint cdp, uint wad, bool transferFrom, address owner) public virtual;
    function freeETH(address manager, address ethJoin, uint cdp, uint wad) public virtual;
    function freeGem(address manager, address gemJoin, uint cdp, uint wad) public virtual;
    function draw(address manager, address jug, address daiJoin, uint cdp, uint wad) public virtual;

    function wipe(address manager, address daiJoin, uint cdp, uint wad) public virtual;
    function safeWipe(address manager, address daiJoin, uint cdp, uint wad, address owner) public virtual;
    function wipeAll(address manager, address daiJoin, uint cdp) public virtual;
    function safeWipeAll(address manager, address daiJoin, uint cdp, address owner) public virtual;
    function lockETHAndDraw(address manager, address jug, address ethJoin, address daiJoin, uint cdp, uint wadD) public virtual payable;
    function openLockETHAndDraw(address manager, address jug, address ethJoin, address daiJoin, bytes32 ilk, uint wadD) public virtual payable returns (uint cdp);
    function lockGemAndDraw(address manager, address jug, address gemJoin, address daiJoin, uint cdp, uint wadC, uint wadD, bool transferFrom) public virtual;
    function openLockGemAndDraw(address manager, address jug, address gemJoin, address daiJoin, bytes32 ilk, uint wadC, uint wadD, bool transferFrom) public virtual returns (uint cdp);

    function openLockGNTAndDraw(address manager, address jug, address gntJoin, address daiJoin, bytes32 ilk, uint wadC, uint wadD) public virtual returns (address bag, uint cdp);
    function wipeAndFreeETH(address manager, address ethJoin, address daiJoin, uint cdp, uint wadC, uint wadD) public virtual;
    function wipeAllAndFreeETH(address manager, address ethJoin, address daiJoin, uint cdp, uint wadC) public virtual;
    function wipeAndFreeGem(address manager, address gemJoin, address daiJoin, uint cdp, uint wadC, uint wadD) public virtual;
    function wipeAllAndFreeGem(address manager, address gemJoin, address daiJoin, uint cdp, uint wadC) public virtual;
}

