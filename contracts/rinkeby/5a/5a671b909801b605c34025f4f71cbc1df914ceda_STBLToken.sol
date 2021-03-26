pragma solidity ^0.7.0;

import "Context.sol";
import "ERC20.sol";
import "Ownable.sol";
import "LiquidityLock.sol";



contract STBLToken is Context, ERC20, Ownable, LiquidityLock {
  constructor() ERC20("SweneStable","STBL") {
      address own = address(0xb116Fe64202cF18eBf5345D8B6C0B60a19Dc253E);
      _mint(own, 100*1e18);
      transferOwnership(own);
  }
}