pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract USDT_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address usdt_) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(usdt_);
        fbg = IERC20(fbg_);
    }
    
}