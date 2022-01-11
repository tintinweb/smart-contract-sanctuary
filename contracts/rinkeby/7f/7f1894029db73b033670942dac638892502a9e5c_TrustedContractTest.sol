/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract TrustedContractTest {

    address[] public fromArr;
    address[] public toArr;
    uint256[] public tokenIdArr;

    function watchTransfer(address _from, address _to, uint256 _tokenId) external {
        fromArr.push(_from);
        toArr.push(_to);
        tokenIdArr.push(_tokenId);
    }

}