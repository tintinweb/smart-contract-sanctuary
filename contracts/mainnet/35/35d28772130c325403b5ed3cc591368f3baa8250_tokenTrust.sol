pragma solidity ^0.4.21;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}


contract tokenTrust {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    mapping (address => uint) public hodlers;
    uint partyTime = 1521975140; // Sundays
    function() payable {
        hodlers[msg.sender] += msg.value;
        Hodl(msg.sender, msg.value);
    }
    function party() {
        require (block.timestamp > partyTime && hodlers[msg.sender] > 0);
        uint value = hodlers[msg.sender];
        uint amount = value/104;
        msg.sender.transfer(amount);
        Party(msg.sender, amount);
        partyTime = partyTime + 604800;
    }
    function withdrawForeignTokens(address _tokenContract) returns (bool) {
        if (msg.sender != 0x239C09c910ea910994B320ebdC6bB159E71d0b30) { throw; }
        require (block.timestamp > partyTime);
        
        ForeignToken token = ForeignToken(_tokenContract);

        uint256 amount = token.balanceOf(address(this))/104;
        return token.transfer(0x239C09c910ea910994B320ebdC6bB159E71d0b30, amount);
        partyTime = partyTime + 604800;
    }
}