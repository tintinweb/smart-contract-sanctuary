pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT
/**
 * @title MockRugZombieNft
 * Satisfies nft interface needed for DrFrankenstein
 */

import "./Ownable.sol";

contract MockRugZombieNft is Ownable {
    uint256 public count;

    event MintNft(address to, uint256 index);

    function reviveRug(address recipient) onlyOwner public {
        emit MintNft(recipient, count);
        count += 1;
    }
}