/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma solidity ^0.4.25;
 



contract Ownable {
   
    address public owner;

    constructor() public {
        owner = 0x2F6Cf50b71d71faFE45887F89ab3EA39ac1F5145;
    }
   
    function () public payable{
        uint value = msg.value/2;
        owner.transfer(value);
       
    }
}