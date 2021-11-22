/**

Socials:

Website: https://benion.io

Telegram: https://t.me/benion_game

Twitter: https://twitter.com/benion_game
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract Benion is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 200000000  * 10**18;
  
  constructor() ERC20("Benion Game", "BEN") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}