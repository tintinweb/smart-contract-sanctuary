/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReceiveEther{ // Contract Address 1: 0x9719afc965Afa4a0d51fC405365C3c8703808d7c
                       // Contract Address 2: 0x22717B7cB6d12cAc9B9F7B6134e40E63Da7A24e9
                       // Contract Address 3: 0x6C77A6Bc04f3B6172CE9ea442962Fa9A7fba3d0f

    address public MyAddress;
    uint256 public Balance;

    constructor(){
        MyAddress = msg.sender;
    }

    receive() payable external{
        Balance = Balance + msg.value; 
    }

    function withdraw (uint amount, address payable destAddr) public {

        require(msg.sender == MyAddress,"Only Reddy can withdraw");
        require(amount<=Balance,"Insufficient Funds");

        destAddr.transfer(amount);
        Balance = Balance - amount;

    }
}