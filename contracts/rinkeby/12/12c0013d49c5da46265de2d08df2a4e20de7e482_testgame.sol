/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract testgame{

    event win(address);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        return uint(ramdon) % 1000;
    }

    function play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()>=500){
            payable(msg.sender).transfer(0.02 ether);
            emit win(msg.sender);
        }
    }

    receive() external payable{
        require(msg.value == 1 ether);
    }
    
    constructor () payable{
        require(msg.value == 1 ether);
    }
}