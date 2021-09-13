/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.4.24;

contract AutoSendCashier {
    address public owner;

    constructor() public payable {
        owner = msg.sender;
    }
    
    function give(address _address) payable public {
        _address.transfer(msg.value);
    }
}