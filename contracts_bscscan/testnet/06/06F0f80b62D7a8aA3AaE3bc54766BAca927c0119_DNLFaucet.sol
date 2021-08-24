// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

contract DNLFaucet {
    address tokenAddress;
    uint decimals = 18;
    
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }
    
    function totalFreeToken() external view returns(uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function claimFreeToken() external {    
        IERC20 dnlToken = IERC20(tokenAddress);
        dnlToken.transfer(msg.sender, 100 * 10**decimals);
    }
}