// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract HETH_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address heth) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(heth);
        fbg = IERC20(fbg_);
    }
    
}