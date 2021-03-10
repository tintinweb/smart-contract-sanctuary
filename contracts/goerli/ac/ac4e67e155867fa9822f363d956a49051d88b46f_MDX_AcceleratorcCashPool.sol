// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract MDX_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address mdx) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(mdx);
        fbg = IERC20(fbg_);
    }
    
}