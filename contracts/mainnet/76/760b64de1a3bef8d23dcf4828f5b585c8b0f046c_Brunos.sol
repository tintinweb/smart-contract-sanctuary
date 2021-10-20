/**

  ____  _____  _    _ _   _  ____   _____ 
 |  _ \|  __ \| |  | | \ | |/ __ \ / ____|
 | |_) | |__) | |  | |  \| | |  | | (___  
 |  _ <|  _  /| |  | | . ` | |  | |\___ \ 
 | |_) | | \ \| |__| | |\  | |__| |____) |
 |____/|_|  \_\\____/|_| \_|\____/|_____/
 

Telegram: https://t.me/brunosoff

Twitter: https://twitter.com/brunos_off

Website: https://brunos.io
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract Brunos is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 1000000000  * 10**18;
  
  constructor() ERC20("Brunos Game | t.me/brunosoff", "BRN") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}