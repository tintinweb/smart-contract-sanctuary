//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract NFTStorage {
    uint256[] nftstrg = [1, 2, 3, 4 ,5];

    function getArrayLength() public view returns(uint256) {
        return nftstrg.length;
    }
}