// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract CoinsEmpire is ERC20, Pausable, Ownable {
    uint256 _MaxSupply;
    constructor() ERC20("Coins Empire", "CEMP") {
         _MaxSupply = 5000000000000000000000000000;
        _mint(msg.sender, 250000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    
 
    function mint(address to, uint256 amount) public onlyOwner {
      uint256 curSupply;
      curSupply = totalSupply() + amount;
      require( curSupply <= _MaxSupply, "error: not permitted to exceed maximun supply.");
      _mint(to, amount);
    }
    
    
    function MaxSupply() public view returns (uint256) {
        return _MaxSupply;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}