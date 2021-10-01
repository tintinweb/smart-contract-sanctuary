/**

 #####  ######  #     # ######  ####### #######     #####  #     #    #    #    # ####### 
#     # #     #  #   #  #     #    #    #     #    #     # ##    #   # #   #   #  #       
#       #     #   # #   #     #    #    #     #    #       # #   #  #   #  #  #   #       
#       ######     #    ######     #    #     #     #####  #  #  # #     # ###    #####   
#       #   #      #    #          #    #     #          # #   # # ####### #  #   #       
#     # #    #     #    #          #    #     #    #     # #    ## #     # #   #  #       
 #####  #     #    #    #          #    #######     #####  #     # #     # #    # ####### 
 

Telegram: https://t.me/cryptosnakeoff

Twitter: https://twitter.com/cryptosnakeoff

Website: https://cryptosnake.co
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract SNAKE is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 100000000000  * 10**18;
  
  constructor() ERC20("CryptoSnake | t.me/cryptosnakeoff", "SNAKE") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}