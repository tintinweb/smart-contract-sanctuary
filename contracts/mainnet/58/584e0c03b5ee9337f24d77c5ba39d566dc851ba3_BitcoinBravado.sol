pragma solidity ^0.4.0;

contract BitcoinBravado {
    
    address public owner;
    
    mapping(address => bool) paidUsers;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function BitcoinBravado() public {
        owner = msg.sender;
    }
    
    function payEntryFee() public payable  {
        if (msg.value >= 0.1 ether) {
            paidUsers[msg.sender] = true;
        }
    }
    
    function getUser (address _user) public view returns (bool _isUser) {
        return paidUsers[_user];
    }
    
    function withdrawAll() onlyOwner() public {
        owner.transfer(address(this).balance);
    }
}