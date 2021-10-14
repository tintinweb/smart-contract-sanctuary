/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Resolver {

    struct spell {
        string connector;
        bytes data;
    }

    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }
        
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }
    
    enum ErrorCode {
        noOk,
        ok
    }

    struct PositionData {
        bool isOk;
        ErrorCode errorCode;
        uint256 ratio;
        uint256 maxRatio;
        uint256 liquidationRatio;
        uint256 maxLiquidationRatio;
        uint256 totalSupply;
        uint256 totalBorrow;
        uint256 price;
    }

    function checkAavePosition(address userAddress, Position memory position, uint256 safeRatioPercentage, bool isTarget) public view returns(PositionData memory p) {
        p.isOk = true;
        return (p);
    }

    function checkLiquidity(
        address liquidityAddress,
        address[] memory tokens,
        uint256 totalSupply,
        uint256 totalBorrow,
        uint256 safeLiquidityRatioPercentage,
        bool isTarget
        )
    public view returns(PositionData memory p) {
         p.isOk = true;
        return (p);
    }
}