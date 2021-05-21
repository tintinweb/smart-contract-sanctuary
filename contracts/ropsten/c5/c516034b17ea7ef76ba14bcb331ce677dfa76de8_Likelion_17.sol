/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//yeong hae
pragma solidity 0.8.0;

contract Likelion_17{
    
    function getPay() public view returns(uint){
        return msg.sender.balance;
    }
}