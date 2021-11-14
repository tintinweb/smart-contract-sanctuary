// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC20.sol";

contract AliToken is ERC20 
{
   // bytes32 MINTER_ROLE = keccak256("ADMIN");  
   address Owner;
    
    constructor(uint256 initialSupply)  ERC20("King Ali", "KALI") {
        //_setupRole(ADMIN, msg.sender);
        _mint(msg.sender, initialSupply);
        Owner=msg.sender;
    }
    
    
    function Mint(uint256 initialSupply) public
    {
        require(msg.sender==Owner,"Access Denied");
        _mint(msg.sender, initialSupply); 
    }
    
    function ChangeOwner(address to) public
    {
        Owner=to;   
    }
}