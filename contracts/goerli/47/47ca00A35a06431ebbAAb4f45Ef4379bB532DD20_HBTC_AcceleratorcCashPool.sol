// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract HBTC_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address hbtc) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(hbtc);
        fbg = IERC20(fbg_);
    }
    
}