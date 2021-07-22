// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';  
//erc20 상속받기
contract Bbadatoken is ERC20 {
 uint public INITIAL_SUPPLY = 21000000; 
 constructor() public ERC20("BBADA TOKEN", "BDT"){
     _mint(msg.sender,INITIAL_SUPPLY * 10 ** (uint(decimals())));  //소주점이하18자리까지하겠다. erc20.sol에서 찾으면나옴.
    
 }

}