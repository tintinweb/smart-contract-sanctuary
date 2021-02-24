/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract ZippieREG {
    mapping(address => mapping(uint256 => bytes)) public latest;
    event Publish(address indexed sender, uint256 indexed stream, bytes cid);

    function publish(uint256 stream, bytes calldata cid) public {
        latest[msg.sender][stream] = cid;
        emit Publish(msg.sender, stream, cid);
    }
    
}