/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity 0.8.7;

contract TestA {
    address public immutable owner;
    address public last_caller;
    uint public last_value;
    
    constructor(){
        owner=msg.sender;
    }
    function call1(uint _val) external returns (address) {
        last_caller=msg.sender;
        last_value=_val;
        return msg.sender;
    }
}