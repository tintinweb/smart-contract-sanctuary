// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0-solc-0.7/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20.sol";

contract AliOmraniToken is ERC20 
{


    address Owner;
    
    constructor (uint256 initialSupply) 
        ERC20("Smart Data Test1", "DTPTEST") 
    {
        _mint(msg.sender, initialSupply);
        Owner=msg.sender;
    }
    
     function Mint(uint256 initialSupply) public returns(string memory)
    {
        require(msg.sender==Owner,"Access Denied");
        _mint(msg.sender, initialSupply); 
        return "Success";
    }
    
    
    
    function ChangeOwner(address to) public
    {
        Owner=to;   
    }
}