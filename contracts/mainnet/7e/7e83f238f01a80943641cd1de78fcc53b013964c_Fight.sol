/**

   _____ _______     _______ _______ ____    ______ _____ _____ _    _ _______ 
  / ____|  __ \ \   / /  __ \__   __/ __ \  |  ____|_   _/ ____| |  | |__   __|
 | |    | |__) \ \_/ /| |__) | | | | |  | | | |__    | || |  __| |__| |  | |   
 | |    |  _  / \   / |  ___/  | | | |  | | |  __|   | || | |_ |  __  |  | |   
 | |____| | \ \  | |  | |      | | | |__| | | |     _| || |__| | |  | |  | |   
  \_____|_|  \_\ |_|  |_|      |_|  \____/  |_|    |_____\_____|_|  |_|  |_|  
 

Telegram: https://t.me/fightcrypto

Twitter: https://twitter.com/cryptofight4

Website: https://cryptofight.co
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract Fight is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 100000000  * 10**18;
  
  constructor() ERC20("CryptoFight", "FIGHT") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}