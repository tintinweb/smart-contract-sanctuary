/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

interface calcContract {
    struct CalcInputParams {
        address poolAddress;
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
  function calcAmount ( CalcInputParams memory inputParams ) external returns ( int256 amount0, int256 amount1 );
}

contract calcTester {
    event CalcResult(int256 amount0, int256 amount1);
    
    function TestCalc(address contractAddress, address poolAddress, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96) external {
        calcContract targetPool = calcContract(contractAddress);
        calcContract.CalcInputParams memory inputParams;
        inputParams.poolAddress = poolAddress;
        inputParams.zeroForOne = zeroForOne;
        inputParams.amountSpecified = amountSpecified;
        inputParams.sqrtPriceLimitX96 = sqrtPriceLimitX96;
        
        (int256 amount0, int256 amount1) = targetPool.calcAmount(inputParams);
        emit CalcResult(amount0, amount1);
    }
}