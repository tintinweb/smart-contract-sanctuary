/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

// This governance contract calculcates total STBZ held by a particular address
// It first gets the STBZ tokens held in wallet
// Then STBZ held in staking pool
// Then LP tokens held in wallet to calculate STBZ held by user
// Then LP tokens held in operator contract pool
// Then STBZ as unclaimed rewards
// Finally STBZ in stabinol staker

pragma solidity =0.6.6;

interface Operator {
    function poolBalance(uint256, address) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function rewardEarned(uint256, address) external view returns (uint256);
}

interface StakingPool {
    function poolBalance(address) external view returns (uint256);
}

interface StabinolStaker{
    function getSTBZBalance(address _user) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract StabilizeGovernanceCalculator {
    
    address constant OPERATOR_ADDRESS = address(0xEe9156C93ebB836513968F92B4A67721f3cEa08a);
    address constant STBZ_ADDRESS = address(0xB987D48Ed8f2C468D52D6405624EADBa5e76d723);
    address constant UNILP_ADDRESS = address(0xDB28312a8d26D59978D9B86cA185707B1A26725b);
    address constant STAKING_ADDRESS = address(0x8c17bE13e034f7fa2a6496bC83B6010be6305204);
    address constant STABINOL_ADDRESS = address(0x4d44545cB6AE1f0Efb972be59379c5ae406E676C);
    
    function calculateTotalSTBZ(address _address) external view returns (uint256) {
        IERC20 stbz = IERC20(STBZ_ADDRESS);
        uint256 mySTBZ = stbz.balanceOf(_address); // First get the token balance of STBZ in the wallet
        mySTBZ = mySTBZ + StakingPool(STAKING_ADDRESS).poolBalance(_address); // Get STBZ being staked
        IERC20 lp = IERC20(UNILP_ADDRESS);
        uint256 myLP = lp.balanceOf(_address); // Get amount of LP in wallet
        myLP = myLP + Operator(OPERATOR_ADDRESS).poolBalance(0, _address);
        // Now we have our LP balance and must calculate how much STBZ we have in it
        uint256 stbzInLP = stbz.balanceOf(UNILP_ADDRESS);
        stbzInLP = stbzInLP * myLP / lp.totalSupply();
        mySTBZ = mySTBZ + stbzInLP;
        // Now calculate the unclaimed rewards in all the pools
        uint256 _poolLength = Operator(OPERATOR_ADDRESS).poolLength();
        for(uint256 i = 0; i < _poolLength; i++){
            mySTBZ = mySTBZ + Operator(OPERATOR_ADDRESS).rewardEarned(i, _address);
        }
        // Now calculate the STBZ in the stabinol staker
        mySTBZ = mySTBZ + StabinolStaker(STABINOL_ADDRESS).getSTBZBalance(_address);
        return mySTBZ;
    }

}