/**

 Website -  https://www.terminalwars.rocks/
 
 Telegram - https://t.me/TerminalWars
 
 Twiter -   https://twitter.com/WarTerminal
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract TerminalWarToken is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 500000000  * 10**18;
  
  constructor() ERC20("Termina War | t.me/TerminalWar", "TWAR") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}