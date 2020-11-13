// SPDX-License-Identifier: MIT
// Address: 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038
pragma solidity >=0.6.0 <0.7.0;

interface IDssProxyActions {
    function cdpAllow(
        address manager,
        uint256 cdp,
        address usr,
        uint256 ok
    ) external;

    function daiJoin_join(
        address apt,
        address urn,
        uint256 wad
    ) external;

    function draw(
        address manager,
        address jug,
        address daiJoin,
        uint256 cdp,
        uint256 wad
    ) external;

    function enter(
        address manager,
        address src,
        uint256 cdp
    ) external;

    function ethJoin_join(address apt, address urn) external payable;

    function exitETH(
        address manager,
        address ethJoin,
        uint256 cdp,
        uint256 wad
    ) external;

    function exitGem(
        address manager,
        address gemJoin,
        uint256 cdp,
        uint256 amt
    ) external;

    function flux(
        address manager,
        uint256 cdp,
        address dst,
        uint256 wad
    ) external;

    function freeETH(
        address manager,
        address ethJoin,
        uint256 cdp,
        uint256 wad
    ) external;

    function freeGem(
        address manager,
        address gemJoin,
        uint256 cdp,
        uint256 amt
    ) external;

    function frob(
        address manager,
        uint256 cdp,
        int256 dink,
        int256 dart
    ) external;

    function gemJoin_join(
        address apt,
        address urn,
        uint256 amt,
        bool transferFrom
    ) external;

    function give(
        address manager,
        uint256 cdp,
        address usr
    ) external;

    function giveToProxy(
        address proxyRegistry,
        address manager,
        uint256 cdp,
        address dst
    ) external;

    function hope(address obj, address usr) external;

    function lockETH(
        address manager,
        address ethJoin,
        uint256 cdp
    ) external payable;

    function lockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadD
    ) external payable;

    function lockGem(
        address manager,
        address gemJoin,
        uint256 cdp,
        uint256 amt,
        bool transferFrom
    ) external;

    function lockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 amtC,
        uint256 wadD,
        bool transferFrom
    ) external;

    function makeGemBag(address gemJoin) external returns (address bag);

    function move(
        address manager,
        uint256 cdp,
        address dst,
        uint256 rad
    ) external;

    function nope(address obj, address usr) external;

    function open(
        address manager,
        bytes32 ilk,
        address usr
    ) external returns (uint256 cdp);

    function openLockETHAndDraw(
        address manager,
        address jug,
        address ethJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 wadD
    ) external payable returns (uint256 cdp);

    function openLockGNTAndDraw(
        address manager,
        address jug,
        address gntJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 amtC,
        uint256 wadD
    ) external returns (address bag, uint256 cdp);

    function openLockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint256 amtC,
        uint256 wadD,
        bool transferFrom
    ) external returns (uint256 cdp);

    function quit(
        address manager,
        uint256 cdp,
        address dst
    ) external;

    function safeLockETH(
        address manager,
        address ethJoin,
        uint256 cdp,
        address owner
    ) external payable;

    function safeLockGem(
        address manager,
        address gemJoin,
        uint256 cdp,
        uint256 amt,
        bool transferFrom,
        address owner
    ) external;

    function safeWipe(
        address manager,
        address daiJoin,
        uint256 cdp,
        uint256 wad,
        address owner
    ) external;

    function safeWipeAll(
        address manager,
        address daiJoin,
        uint256 cdp,
        address owner
    ) external;

    function shift(
        address manager,
        uint256 cdpSrc,
        uint256 cdpOrg
    ) external;

    function transfer(
        address gem,
        address dst,
        uint256 amt
    ) external;

    function urnAllow(
        address manager,
        address usr,
        uint256 ok
    ) external;

    function wipe(
        address manager,
        address daiJoin,
        uint256 cdp,
        uint256 wad
    ) external;

    function wipeAll(
        address manager,
        address daiJoin,
        uint256 cdp
    ) external;

    function wipeAllAndFreeETH(
        address manager,
        address ethJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadC
    ) external;

    function wipeAllAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 amtC
    ) external;

    function wipeAndFreeETH(
        address manager,
        address ethJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadC,
        uint256 wadD
    ) external;

    function wipeAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 amtC,
        uint256 wadD
    ) external;
}
