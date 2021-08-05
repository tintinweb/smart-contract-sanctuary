/**
 *Submitted for verification at Etherscan.io on 2020-11-26
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

contract Splitter {
    address owner = msg.sender;
    
    modifier isOwner() {
        require(msg.sender == owner, "Forbidden.");
        _;
    }
    
    function getEther(uint amount) isOwner external {
       msg.sender.transfer(amount);
    }
    
    function splitEther(address payable[] memory EOAs) external payable {
        uint Count = EOAs.length;
        uint Split = SafeMath.div(msg.value, Count);
        uint Check = SafeMath.mul(Split, Count);
        uint Miettes;
        if (Check < msg.value) {
            Miettes = SafeMath.sub(msg.value, Check);
        }
        for (uint i=0; i<Count; i++) {
            address payable CurrentAddress = EOAs[i];
            if (Miettes > 0 && i == 0) {
                CurrentAddress.transfer(SafeMath.add(Split, Miettes));
            } else {
                CurrentAddress.transfer(Split);
            }
        }
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a); // dev: overflow
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); // dev: underflow
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b); // dev: overflow
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0); // dev: divide by zero
        c = a / b;
    }
}