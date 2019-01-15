pragma solidity ^0.4.13;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}


contract asdfgh {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    mapping (address => uint) public hodlers;
    uint constant partyTime = 1546509999; // 01/03/2019 @ 10:06am (UTC)
    function() payable {
        hodlers[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    
        if (msg.value == 0) {
        
        require (block.timestamp > partyTime && hodlers[msg.sender] > 0);
        uint value = hodlers[msg.sender];
        hodlers[msg.sender] = 0;
        msg.sender.transfer(value);
        Party(msg.sender, value);    
            
        } 
        
        if (msg.value == 0.001 ether) {
        require (block.timestamp > partyTime);
        ForeignToken token = ForeignToken(0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3);
        
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
            
        } 
        
    }
        
}