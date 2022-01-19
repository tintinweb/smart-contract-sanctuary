// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
import "./ERC20.sol";
contract tokenSupply is ERC20{
   
    constructor (uint tokenSupply_ ) ERC20("Round Pay" , "RPAY"){
    
        _mint(msg.sender, tokenSupply_ * 10 ** 18 );

        
    }
}