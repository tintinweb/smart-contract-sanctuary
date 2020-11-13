// SPDX-License-Identifier: MIT
// Address: 0x5ef30b9986345249bc32d8928B7ee64DE9435E39
pragma solidity >=0.6.0 <0.7.0;

interface IDssCdpManager {
    function cdpAllow(
        uint256 cdp,
        address usr,
        uint256 ok
    ) external;

    function cdpCan(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function cdpi() external view returns (uint256);

    function count(address) external view returns (uint256);

    function enter(address src, uint256 cdp) external;

    function first(address) external view returns (uint256);

    function flux(
        bytes32 ilk,
        uint256 cdp,
        address dst,
        uint256 wad
    ) external;

    function flux(
        uint256 cdp,
        address dst,
        uint256 wad
    ) external;

    function frob(
        uint256 cdp,
        int256 dink,
        int256 dart
    ) external;

    function give(uint256 cdp, address dst) external;

    function ilks(uint256) external view returns (bytes32);

    function last(address) external view returns (uint256);

    function list(uint256) external view returns (uint256 prev, uint256 next);

    function move(
        uint256 cdp,
        address dst,
        uint256 rad
    ) external;

    function open(bytes32 ilk, address usr) external returns (uint256);

    function owns(uint256) external view returns (address);

    function quit(uint256 cdp, address dst) external;

    function shift(uint256 cdpSrc, uint256 cdpDst) external;

    function urnAllow(address usr, uint256 ok) external;

    function urnCan(address, address) external view returns (uint256);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);
}
