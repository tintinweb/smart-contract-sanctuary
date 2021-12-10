/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Finna {
    event Set(address indexed sender, bytes32 indexed key, bytes data);

    function set(bytes32 _key, bytes calldata _data) external {
        emit Set(msg.sender, _key, _data);
    }
}