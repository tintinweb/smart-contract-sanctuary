// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract HFIL_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address hfil) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(hfil);
        fbg = IERC20(fbg_);
    }
    
}