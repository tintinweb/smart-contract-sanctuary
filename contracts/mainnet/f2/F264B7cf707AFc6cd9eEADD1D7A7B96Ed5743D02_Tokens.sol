pragma solidity ^0.4.24;

contract Tokens {
    struct Token {
        address _address;
        string _websiteUrl;
    }
    
    Token[] public tokens;
    address public owner;

    constructor() public {
        owner = 0x5fa344f3B7AfD345377A37B62Ce87DDE01c1D414;
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;      
    }

    function addToken(address _address, string _websiteUrl) public {
        require(msg.sender == owner);
        tokens.push(Token(_address, _websiteUrl));
    }

    function deleteToken(uint _tokenId) public {
        require(msg.sender == owner);
        delete tokens[_tokenId];      
    }

    function getTokensCount() public view returns(uint) {
        return tokens.length;
    }
}