/**

🌐WEBSITE:  https://play2earn.digital/
 
🎮TWITTER:  https://twitter.com/Play2earnDG

🎮MEDIUM:   https://medium.com/@play2earnDigital

🎮TELEGRAM: https://t.me/play2earnDigital

🎮ANNOUNCEMENTS: https://t.me/Play2EarnDigitalCh

*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract Play2Earn  is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 100000000  * 10**18;
  
  constructor() ERC20("Play2Earn Digital" , "P2E") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}