/**

Socials:

Website: https://lanstar.me

Telegram: https://t.me/lanstar_meta

Twitter: https://twitter.com/lanstar_meta
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract LanStar is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 1000000000  * 10**18;
  
  constructor() ERC20("LanStar Metaverse", "LSTAR") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}