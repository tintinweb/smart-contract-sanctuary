/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.4.26;

contract SendEther {
    address public human;
    
    function enter() public payable {
        require(msg.value > .1 ether);
        human = msg.sender;
    }
    
    function sendEth() public restricted {
        human.transfer(address(this).balance);
    }
    
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getHumanBalance() public view returns (uint) {
        return human.balance;
    }
    
    modifier restricted() {
        require(msg.sender == human);
        _;
    }
}