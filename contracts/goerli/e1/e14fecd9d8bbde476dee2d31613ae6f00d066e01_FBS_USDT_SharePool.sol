pragma solidity ^0.6.0;

import "./OneTokenSharePool.sol";

contract FBS_USDT_SharePool is OneTokenSharePool{
    
    constructor(address basisShare_, address fbs_usdt_lpt_) public {
        basisShare = IERC20(basisShare_);
        token = IERC20(fbs_usdt_lpt_);
    }

}