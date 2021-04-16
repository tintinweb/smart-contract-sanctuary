/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddressArrays {
    event LastAddress(address a);

    function dynamic(address[] memory addrs) public {
        emit LastAddress(addrs[addrs.length - 1]);
    }

    function three(address[3] memory addrs) public {
        emit LastAddress(addrs[2]);
    }
}