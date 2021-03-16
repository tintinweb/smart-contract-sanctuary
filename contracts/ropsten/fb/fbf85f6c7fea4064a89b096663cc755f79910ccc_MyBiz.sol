pragma solidity ^0.6.0;

import "./ERC20Detailed.sol";
import "./ERC20.sol";
import "./Roles.sol";
import "./Ownable.sol";


contract MyBiz is ERC20,ERC20Detailed,Ownable{
    
    constructor(
        uint256 maximumcoin,
        string memory name, 
        string memory symbol, 
        uint8 decimals 
        )public ERC20Detailed(name, symbol, decimals){

            _totalSupply = _balances[msg.sender] = maximumcoin;
    }
}