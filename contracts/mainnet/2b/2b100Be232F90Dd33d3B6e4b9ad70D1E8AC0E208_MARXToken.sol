// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./TokenRecover.sol";
import "./ERC20Pausable.sol";

contract MARXToken is ERC20Detailed, TokenRecover, ERC20Pausable {
    
    uint256 private constant _initialSupply = 2100000000;
    
    constructor () public ERC20Detailed ( "MarX", "MARX", 18 ) 
    { _mint(_msgSender(), _initialSupply * (10 ** uint256(decimals()))); }

    function initialSupply() public pure returns ( uint256 ){
        return _initialSupply;
    }
}