/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity 0.8.7;

contract TestA {
    address public immutable owner;
    
    constructor(){
        owner=msg.sender;
    }
    function getSender() external view returns (address){
        return msg.sender;
    }
}