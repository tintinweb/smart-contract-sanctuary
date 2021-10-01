/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    function hello() public pure returns (string memory) {
        return "Hello World.";
    }
}

contract MsgCallTest {
    function testCall(HelloWorld helloWorldAddr) public pure returns (string memory) {
        return helloWorldAddr.hello();
    }
}

contract Sink {
    
    event EthReceived(address, uint);
    
    constructor() payable {
        
    }

    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }
    
    function getSelfBalance() external view returns (uint) {
        return address(this).balance;
    }
}