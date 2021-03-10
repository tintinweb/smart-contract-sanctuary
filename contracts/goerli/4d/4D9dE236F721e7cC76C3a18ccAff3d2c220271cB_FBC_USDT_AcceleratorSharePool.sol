pragma solidity ^0.6.0;

import "./OneTokenAcceleratorSharePool.sol";

contract FBC_USDT_AcceleratorSharePool is OneTokenAcceleratorSharePool{
    
    constructor(address basisShare_, address fbg_, address fbc_usdt_lpt_) public {
        basisShare = IERC20(basisShare_);
        token = IERC20(fbc_usdt_lpt_);
        fbg = IERC20(fbg_);
    }
    
}