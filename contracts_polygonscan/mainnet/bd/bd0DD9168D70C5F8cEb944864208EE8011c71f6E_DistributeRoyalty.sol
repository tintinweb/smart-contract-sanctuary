/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.8.7;

//SPDX-License-Identifier: MIT

contract DistributeRoyalty {
    address public owner1;
    address public owner2;
    
    constructor (address _owner1, address _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }


    function Withdraw() public payable {
        require (msg.sender == owner1 || msg.sender == owner2);
        
        uint percentage = 50;
        uint value = (address(this).balance)*percentage/100;

        payable(owner1).transfer(value);
        payable(owner2).transfer(value);
    }
}