pragma solidity 0.5.16;

import "./Token.sol";

contract TokenFactory is Ownable {
    address[] public tokens;
    
    event CreateToken(address token,string name, string symbol, uint8 decimals, uint256 totalSupply);
    
    constructor () public {
        
    }
    
    function Create(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) public onlyOwner{
        Token token = new Token(name_, symbol_, decimals_, totalSupply_);
        tokens.push(address(token));
        emit CreateToken(address(token), name_, symbol_, decimals_, totalSupply_);
    }
}