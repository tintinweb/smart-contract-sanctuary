// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
  
import "./TimeLock.sol";
import "./IERC20.sol";


//1640998799
contract MONA__LiquidityLock is TokenTimelock { 
    constructor(IERC20 _token, uint256 _releaseTime) public TokenTimelock(_token, msg.sender, _releaseTime) {}
}