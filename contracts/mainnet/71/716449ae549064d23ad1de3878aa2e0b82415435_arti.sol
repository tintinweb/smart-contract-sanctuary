// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import  "./ERC20-v0.8.0.sol";

contract arti is ERC20 {
    
    address owner;
    string Name = 'arti';
    string Symbol = 'ARTI';
  
 constructor( address _owner) ERC20(Name, Symbol){
        
        owner =_owner;
        uint256 initialSupply = 2000000000*10**8;
        _mint(owner, initialSupply);
        
    }

      modifier onlyOwner() {
            require(owner == msg.sender, 'caller is not admin'); 
            _;
          
      }
      
      function BeginTokenLock() external onlyOwner{
          tokenLocked = true;
      }
      
    function EndTokenLock() external onlyOwner{
          tokenLocked = false;
      }


    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
         require(tokenLocked == false, 'token locked');
        _mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external onlyOwner {
         require(tokenLocked == false, 'token locked');
        _burn(recipient, amount);
    }
}