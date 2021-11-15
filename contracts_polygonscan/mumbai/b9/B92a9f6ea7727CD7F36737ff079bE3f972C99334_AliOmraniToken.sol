// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC20.sol";

contract AliOmraniToken is ERC20 
{


    address Owner;
    
    constructor (uint256 initialSupply) 
        ERC20("MiladKarimi", "KRM") 
    {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
        Owner=msg.sender;
    }
    
     function Mint(uint256 initialSupply) public
    {
        require(msg.sender==Owner,"Access Denied");
        _mint(msg.sender, initialSupply* (10 ** uint256(decimals()))); 
    }
    
    function ChangeOwner(address to) public
    {
        Owner=to;   
    }
}