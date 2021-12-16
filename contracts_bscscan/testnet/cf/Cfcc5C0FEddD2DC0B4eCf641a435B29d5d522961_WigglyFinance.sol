// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './ERC20.sol';
import './Ownable.sol';

contract WigglyFinance is ERC20, Ownable{
  constructor(uint256 _supply) ERC20 ("WigglyFinance","WGL"){
        _mint(msg.sender, _supply * ( 10 ** decimals()));
    }
}