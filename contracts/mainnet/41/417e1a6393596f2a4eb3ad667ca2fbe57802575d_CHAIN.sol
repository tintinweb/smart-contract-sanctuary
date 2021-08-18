/**

    _,aaaaaaaaaaaaaaaaaaa,_                _,aaaaaaaaaaaaaaaaaaa,_
  ,P"                     "Y,            ,P"                     "Y,
 d'    ,aaaaaaaaaaaaaaa,    `b          d'    ,aaaaaaaaaaaaaaa,    `b
d'   ,d"            ,aaabaaaa8aaaaaaaaaa8aaaadaaa,            "b,   `b
I    I              I                            I              I    I
Y,   `Y,            `aaaaaaaaaaaaaaaaaaaaaaaaaaaa'            ,P'   ,P
 Y,   `baaaaaaaaaaaaaaad'   ,P          Y,   `baaaaaaaaaaaaaaId'   ,P
  `b,                     ,d'            `b,                     ,d'
    `baaaaaaaaaaaaaaaaaaad'                `baaaaaaaaaaaaaaaaaIaad'            

             _|_|_|  _|    _|    _|_|    _|_|_|  _|      _|  
           _|        _|    _|  _|    _|    _|    _|_|    _|  
           _|        _|_|_|_|  _|_|_|_|    _|    _|  _|  _|  
           _|        _|    _|  _|    _|    _|    _|    _|_|  
             _|_|_|  _|    _|  _|    _|  _|_|_|  _|      _|    
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./ERC20.sol";
import "./Address.sol";

contract CHAIN is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;
    uint256 private _initialSupply = 80000  * 10**18;
  
  constructor() ERC20("CHAIN FURY | t.me/ChainFury", "CHAIN") {
    
    _totalSupply += _initialSupply;
    _balances[msg.sender] += _initialSupply;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }
    
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}