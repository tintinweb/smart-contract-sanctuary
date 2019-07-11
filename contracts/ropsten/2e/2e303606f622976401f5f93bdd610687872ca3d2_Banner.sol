/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.1;

contract ERC20Token {
    function transferFrom (address from, address to, uint value) public;
}

contract Banner {
    
    event writeMessage(string);
    ERC20Token token;
    address payable owner;
    
    constructor () public {
        owner = msg.sender;
    }
    
    function setToken(address _token) public {
        require(msg.sender == owner);
        token = ERC20Token(_token);
    }
    
    function write(string memory _message) public {
        token.transferFrom(msg.sender, owner, 1);    
        emit writeMessage(_message);
    }
}