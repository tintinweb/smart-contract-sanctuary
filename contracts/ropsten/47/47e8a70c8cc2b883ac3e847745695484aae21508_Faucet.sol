/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity ^0.4.22;

contract Faucet {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        msg.sender.transfer (withdraw_amount);
    }
    
    function () public payable {}
    
    function destroy () public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}