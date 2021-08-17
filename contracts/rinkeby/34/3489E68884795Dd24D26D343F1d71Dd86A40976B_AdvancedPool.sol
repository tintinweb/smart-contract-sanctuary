/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract AdvancedPool {
    IERC20 coin = IERC20(0x92D97AB672F71e029DfbC18f01E615c3637b1c95);
    IERC20 poolTokenCon = IERC20(0x301d9DA1219658D04E61F2d2d51A8dd2E3c55a88);
    uint256 poolTokenPriceVar = 1000000;

    function updatePollTokenPrice(uint256 _newPrice) public {
        poolTokenPriceVar = _newPrice;
    }
    
    function stake(uint256 amount) external returns(uint256){
        coin.transferFrom(msg.sender, address(this), amount);
        poolTokenCon.mint(msg.sender, (amount * 10**6)/poolTokenPriceVar);
        return 1;
    }

    function unstake(uint256 amount) external returns(uint256){
        coin.transfer(msg.sender, amount);
        poolTokenCon.burn(msg.sender, amount/poolTokenPriceVar);  
        return 1;
    }
    
/****OTHER FUNCTIONS****/

    function poolTokenPrice() public view returns(uint256){
        return poolTokenPriceVar;
        
    }

    function poolToken() public view returns(address){
        return address(poolTokenCon);
    }
    
    receive() external payable {
    }
}