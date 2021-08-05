/**
 *Submitted for verification at Etherscan.io on 2020-09-25
*/

pragma solidity >=0.4.22 <0.7.0;

contract ContractSender {
    bool public canReceiveEther;
    address payable public owner;
    constructor() public {
        canReceiveEther = true;
        owner = msg.sender;
    }
    
    function send(address payable to) payable public {
        to.transfer(msg.value);
    }
    
    function  refund() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
    
    function switchReceive() public returns(bool) {
        require(msg.sender == owner);
        canReceiveEther = !canReceiveEther;
        return canReceiveEther;
    }
    
    receive() payable external {
        require(canReceiveEther);
    }
}