pragma solidity ^0.4.23;

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

contract Ack {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    function tokenFallback(address _from, uint _amountOfTokens, bytes _data)
    public 
    returns (bool) {
        
        emit Transfer(_from, msg.sender, _amountOfTokens);
        return true;  
    }
}