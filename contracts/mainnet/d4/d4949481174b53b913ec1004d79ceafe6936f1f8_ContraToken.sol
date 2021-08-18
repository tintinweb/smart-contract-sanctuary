/**

🌎WWW: www.contratoken.art

💬TELEGRAM: https://t.me/ContraToken

🐧TWITTER: https://twitter.com/ContraToken

*/


// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract ContraToken is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 125000000 * 10**18;
  
  constructor() ERC20("Contra Token | t.me/ContraToken", "CONTRA") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}