/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Distr {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function dist(address payable[] memory addrs, uint256[] memory blncs) public payable {
        require(msg.sender == owner, "NO");
        require(addrs.length == blncs.length);
        for(uint256 i = 0; i < addrs.length; i++) {
            (bool s, ) = addrs[i].call{value: blncs[i], gas: 35000}("");

            require(s, "failed");
        }

        payable(msg.sender).call{value: address(this).balance}("");
    }
}