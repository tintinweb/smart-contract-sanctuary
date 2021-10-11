/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// File: contracts/SmartRoute/intf/IDODOV2.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IDODOV2 {

    //========== Common ==================

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function getVaultReserve() external view returns (uint256 baseReserve, uint256 quoteReserve);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function getPMMStateForCall() external view returns (
            uint256 i,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
    );

    function getUserFeeRate(address user) external view returns (uint256 lpFeeRate, uint256 mtFeeRate);

    
    function getDODOPoolBidirection(address token0, address token1) external view returns (address[] memory, address[] memory);

    //========== DODOVendingMachine ========
    
    function createDODOVendingMachine(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newVendingMachine);
    
    function buyShares(address to) external returns (uint256,uint256,uint256);


    //========== DODOPrivatePool ===========

    function createDODOPrivatePool() external returns (address newPrivatePool);

    function initDODOPrivatePool(
        address dppAddress,
        address creator,
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 k,
        uint256 i,
        bool isOpenTwap
    ) external;

    function reset(
        address operator,
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 baseOutAmount,
        uint256 quoteOutAmount,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool); 


    function _OWNER_() external returns (address);
    
    //========== CrowdPooling ===========

    function createCrowdPooling() external returns (address payable newCrowdPooling);

    function initCrowdPooling(
        address cpAddress,
        address creator,
        address baseToken,
        address quoteToken,
        uint256[] memory timeLine,
        uint256[] memory valueList,
        bool isOpenTWAP
    ) external;

    function bid(address to) external;
}

// File: contracts/SmartRoute/helper/DODOV2RouteHelper.sol



contract DODOV2RouteHelper {
    address public immutable _DVM_FACTORY_;
    address public immutable _DPP_FACTORY_;
    address public immutable _DSP_FACTORY_;

    struct PairDetail {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 Q;
        uint256 B0;
        uint256 Q0;
        uint256 R;
        uint256 lpFeeRate;
        uint256 mtFeeRate;
        address baseToken;
        address quoteToken;
        address curPair;
        uint256 pairVersion;
    }

    constructor(address dvmFactory,address dppFactory,address dspFactory) public {
        _DVM_FACTORY_ = dvmFactory;
        _DPP_FACTORY_ = dppFactory;
        _DSP_FACTORY_ = dspFactory;
    }

    function getPairDetail(address token0,address token1,address userAddr) external view returns (PairDetail[] memory res) {
        (address[] memory baseToken0DVM, address[] memory baseToken1DVM) = IDODOV2(_DVM_FACTORY_).getDODOPoolBidirection(token0,token1);
        (address[] memory baseToken0DPP, address[] memory baseToken1DPP) = IDODOV2(_DPP_FACTORY_).getDODOPoolBidirection(token0,token1);
        (address[] memory baseToken0DSP, address[] memory baseToken1DSP) = IDODOV2(_DSP_FACTORY_).getDODOPoolBidirection(token0,token1);

        uint256 len = baseToken0DVM.length + baseToken1DVM.length + baseToken0DPP.length + baseToken1DPP.length + baseToken0DSP.length + baseToken1DSP.length;
        res = new PairDetail[](len);
        for(uint8 i = 0; i < len; i++) {
            PairDetail memory curRes = PairDetail(0,0,0,0,0,0,0,0,0,address(0),address(0),address(0),2);
            address cur;
            if(i < baseToken0DVM.length) {
                cur = baseToken0DVM[i];
                curRes.baseToken = token0;
                curRes.quoteToken = token1;
            } else if(i < baseToken0DVM.length + baseToken1DVM.length) {
                cur = baseToken1DVM[i - baseToken0DVM.length];
                curRes.baseToken = token1;
                curRes.quoteToken = token0;
            } else if(i < baseToken0DVM.length + baseToken1DVM.length + baseToken0DPP.length) {
                cur = baseToken0DPP[i - baseToken0DVM.length - baseToken1DVM.length];
                curRes.baseToken = token0;
                curRes.quoteToken = token1;
            } else if(i < baseToken0DVM.length + baseToken1DVM.length + baseToken0DPP.length + baseToken1DPP.length)  {
                cur = baseToken1DPP[i - baseToken0DVM.length - baseToken1DVM.length - baseToken0DPP.length];
                curRes.baseToken = token1;
                curRes.quoteToken = token0;
            } else if(i < baseToken0DVM.length + baseToken1DVM.length + baseToken0DPP.length + baseToken1DPP.length + baseToken0DSP.length)  {
                cur = baseToken0DSP[i - baseToken0DVM.length - baseToken1DVM.length - baseToken0DPP.length - baseToken1DPP.length];
                curRes.baseToken = token0;
                curRes.quoteToken = token1;
            } else {
                cur = baseToken1DSP[i - baseToken0DVM.length - baseToken1DVM.length - baseToken0DPP.length - baseToken1DPP.length - baseToken0DSP.length];
                curRes.baseToken = token1;
                curRes.quoteToken = token0;
            }

            (            
                curRes.i,
                curRes.K,
                curRes.B,
                curRes.Q,
                curRes.B0,
                curRes.Q0,
                curRes.R
            ) = IDODOV2(cur).getPMMStateForCall();

            (curRes.lpFeeRate, curRes.mtFeeRate) = IDODOV2(cur).getUserFeeRate(userAddr);
            curRes.curPair = cur;
            res[i] = curRes;
        }
    }
}