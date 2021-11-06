/**

HVB is the ERC-20 token that allows token holders to play, exchange, 
invest and also be a part of the game ecosystem development. 
Taking advantage of cryptocurrency assets, HVB has strong security manners, 
high liquidity, and is easy to exchange. That can help users to play, enjoy, 
and make profits from the game. 

Telegram: https://t.me/heavybomb

Twitter: https://twitter.com/heavybombgame

Website: https://heavybomb.io
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract HeavyBomb is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 10000000  * 10**18;
  
  constructor() ERC20("HeavyBomb Game", "HVB") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}