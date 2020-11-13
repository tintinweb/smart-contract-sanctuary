// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface WETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);
}
