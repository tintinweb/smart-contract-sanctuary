pragma solidity ^0.7.0;

import "Context.sol";
import "ERC20.sol";
import "Ownable.sol";
import "LiquidityLock.sol";



contract STBLToken is Context, ERC20, Ownable, LiquidityLock {
  constructor() ERC20("SweneStable","STBL") {}
}