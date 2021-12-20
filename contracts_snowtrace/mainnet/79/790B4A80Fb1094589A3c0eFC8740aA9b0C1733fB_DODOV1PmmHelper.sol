/**
 *Submitted for verification at snowtrace.io on 2021-12-20
*/

// File: contracts/SmartRoute/intf/IDODOV1.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IDODOV1 {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote);

    function depositBaseTo(address to, uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external returns (address);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _R_STATUS_() external view returns (uint8);

    function _QUOTE_BALANCE_() external view returns (uint256);

    function _BASE_BALANCE_() external view returns (uint256);

    function _K_() external view returns (uint256);

    function _MT_FEE_RATE_() external view returns (uint256);

    function _LP_FEE_RATE_() external view returns (uint256);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function getOraclePrice() external view returns (uint256);

    function getMidPrice() external view returns (uint256 midPrice); 
}

// File: contracts/SmartRoute/helper/DODOV1PmmHelper.sol


contract DODOV1PmmHelper {
    
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

    function getPairDetail(address pool) external view returns (PairDetail[] memory res) {
        res = new PairDetail[](1);
        PairDetail memory curRes = PairDetail(0,0,0,0,0,0,0,0,0,address(0),address(0),pool,1);
        curRes.i = IDODOV1(pool).getOraclePrice();
        curRes.K = IDODOV1(pool)._K_();
        curRes.B = IDODOV1(pool)._BASE_BALANCE_();
        curRes.Q = IDODOV1(pool)._QUOTE_BALANCE_();
        (curRes.B0,curRes.Q0) = IDODOV1(pool).getExpectedTarget();
        curRes.R = IDODOV1(pool)._R_STATUS_();
        curRes.lpFeeRate = IDODOV1(pool)._LP_FEE_RATE_();
        curRes.mtFeeRate = IDODOV1(pool)._MT_FEE_RATE_();
        curRes.baseToken = IDODOV1(pool)._BASE_TOKEN_();
        curRes.quoteToken =  IDODOV1(pool)._QUOTE_TOKEN_();
        res[0] = curRes;
    }
}