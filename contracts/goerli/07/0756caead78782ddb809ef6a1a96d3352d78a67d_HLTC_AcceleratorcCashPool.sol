// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./OneTokenAcceleratorCashPool.sol";

contract HLTC_AcceleratorcCashPool is OneTokenAcceleratorCashPool{
    
    constructor(address basisCash_, address fbg_, address hltc) public {
        basisCash = IERC20(basisCash_);
        token = IERC20(hltc);
        fbg = IERC20(fbg_);
    }
    
}