/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CurveGauge {
    function claimable_reward_write(address _addr, address _token) external view returns(uint256);
    
    function claimable_reward(address _addr, address _token) external view returns(uint256);
    
    //function claimable_reward_write(address _addr, address _token) external returns(uint256);
}

contract checkCurve {
    
    CurveGauge public constant CURVE_GAUGE =
        CurveGauge(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);
        
    function getClaimableRewardW(address who, address Token) public view returns (uint256) {
        return CURVE_GAUGE.claimable_reward_write(who, Token);
    }
    
    function getClaimableReward(address who, address Token) public view returns (uint256) {
        return CURVE_GAUGE.claimable_reward(who, Token);
    }
    
    function getClaimableRewardABI(address who, address Token) public view returns (bool success, bytes memory result) {
        (success, result) = address(CURVE_GAUGE).staticcall(
            abi.encodeWithSignature("claimable_reward_write(address, address)", who, Token)
        );
    }
    
}