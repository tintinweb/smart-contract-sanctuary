/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.6.0;

contract Storage {
    mapping (address => uint) private contributions;
    address public owner;
    
    constructor() public payable {
        owner = msg.sender;
        contributions[msg.sender] = msg.value;
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }
    
    function contribute() public payable {
        contributions[msg.sender] += msg.value;
    }
    
    function getContribution() public view returns (uint) {
        return contributions[msg.sender];
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function close() public { 
        selfdestruct(msg.sender); 
    }
}