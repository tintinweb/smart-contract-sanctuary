/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// This governance contract calculcates total STBZ held by a particular address
// It first gets the STBZ tokens held in wallet
// Then STBZ held in staking pool
// Then LP tokens held in wallet to calculate STBZ held by user
// Finally LP tokens held in operator contract pool

pragma solidity ^0.6.6;

interface Operator {
    function poolBalance(uint256, address) external view returns (uint256);
}

interface StakingPool {
    function poolBalance(address) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract StabilizeGovernanceCalculator {
    
    address constant operatorAddress = address(0xEe9156C93ebB836513968F92B4A67721f3cEa08a);
    address constant stbzAddress = address(0xB987D48Ed8f2C468D52D6405624EADBa5e76d723);
    address constant uniLpAddress = address(0xDB28312a8d26D59978D9B86cA185707B1A26725b);
    address constant stakingAddress = address(0x8c17bE13e034f7fa2a6496bC83B6010be6305204);
    
    function calculateTotalSTBZ(address _address) external view returns (uint256) {
        IERC20 stbz = IERC20(stbzAddress);
        uint256 mySTBZ = stbz.balanceOf(_address); // First get the token balance of STBZ in the wallet
        mySTBZ = mySTBZ + StakingPool(stakingAddress).poolBalance(_address); // Get STBZ being staked
        IERC20 lp = IERC20(uniLpAddress);
        uint256 myLP = lp.balanceOf(_address); // Get amount of LP in wallet
        myLP = myLP + Operator(operatorAddress).poolBalance(0, _address);
        // Now we have our LP balance and must calculate how much STBZ we have in it
        uint256 stbzInLP = stbz.balanceOf(uniLpAddress);
        stbzInLP = stbzInLP * myLP / lp.totalSupply();
        return mySTBZ + stbzInLP;
    }

}