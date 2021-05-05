/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.4.26;

contract NGO {
    address manager;
    uint88 public noOfDonations;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function sendEthToContract() public payable {
        require(msg.value > 0.99 ether);
        noOfDonations++;
    }
    
    function sendEthToChildren(address _childrenAddress) external payable restricted {
        _childrenAddress.transfer(address(this).balance);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}