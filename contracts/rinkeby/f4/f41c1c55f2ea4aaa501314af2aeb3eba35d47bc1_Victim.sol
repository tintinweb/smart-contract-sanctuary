/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;

contract Victim {
    event Win(uint256, uint256,uint256,bytes32);
    event Lose(uint256,uint256,uint256,bytes32);
    receive() payable external{}
    function roll() payable public {
        require(msg.value * 2 <= address(this).balance);
        uint256 num =  random() % 2; 
        if(num == 0){
           (payable(msg.sender)).transfer(msg.value*2);
            emit Win(msg.value*2, num, block.timestamp, blockhash(block.number));
        }
        else{
            emit Lose(msg.value, num,block.timestamp, blockhash(block.number));
        }
    }
    function random() pure internal returns(uint256){
        //......some logic......
        return 0;
    }
}