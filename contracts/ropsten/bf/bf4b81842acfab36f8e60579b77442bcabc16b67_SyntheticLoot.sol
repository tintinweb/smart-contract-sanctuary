/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: Unlicense

/*

    Synthetic Loot

    This contract creates a "virtual NFT" of Loot based
    on a given wallet address.

    Because the wallet address is used as the deterministic
    seed, there can only be one Loot bag per wallet.

    Because it's not a real NFT, there is no
    minting, transferability, etc.

    Creators building on top of Loot can choose to recognize
    Synthetic Loot as a way to allow a wider range of
    adventurers to participate in the ecosystem, while
    still being able to differentiate between
    "original" Loot and Synthetic Loot.

    Anyone with an Ethereum wallet has Synthetic Loot.

    -----

    Also optionally returns data in LootComponents format:

    Call weaponComponents(), chestComponents(), etc. to get
    an array of attributes that correspond to the item.

    The return format is:

    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)

    See the item and attribute tables below for corresponding IDs.

    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

pragma solidity ^0.8.4;

contract SyntheticLoot {

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function a(address walletAddress) public view returns (bytes memory) {
        return abi.encodePacked(walletAddress);
    }

    function b(string memory keyPrefix, address walletAddress) public view returns (bytes memory) {
        return abi.encodePacked(keyPrefix, a(walletAddress));
    }

    function c(string memory keyPrefix, address walletAddress) public view returns (string memory) {
        return string(b(keyPrefix, walletAddress));
    }

    function d(string memory keyPrefix, address walletAddress) public view returns (uint256) {
        return random(c(keyPrefix, walletAddress));
    }
}