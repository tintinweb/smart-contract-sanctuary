/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.6;

/// @title Balancer Weighted Pool Proxy
/// @author Gauntlet
/// @dev This contract is used as a proxy to call the Balancer WeightedPools setSwapFee
contract PoolTest {
    uint public swapFeePercentage;
    function setSwapFeePercentage(uint256 _swapFeePercentage) public {
        swapFeePercentage = _swapFeePercentage;
    }
    function getSwapFeePercentage() view public returns (uint256){
        return swapFeePercentage;
    }
}