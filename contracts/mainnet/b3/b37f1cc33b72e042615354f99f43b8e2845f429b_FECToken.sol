// FECtoken project

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FECToken is ERC20{ 

    string public Fecname = "FECToken";
    string public Fecsymbol = "FEC";
    uint8 public dec = 18;
    uint public INITIAL_SUPPLY = 10000000000;
    uint256 public _totalSupply = INITIAL_SUPPLY * (10**uint(dec));
    
   constructor () ERC20(Fecname, Fecsymbol) public{ 
   _mint(msg.sender, _totalSupply); 
   } 
}