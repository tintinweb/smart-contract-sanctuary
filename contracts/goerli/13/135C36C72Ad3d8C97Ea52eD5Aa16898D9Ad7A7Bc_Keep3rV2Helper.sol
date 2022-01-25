/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IChainLinkFeed {
    function latestAnswer() external view returns (int256);
}

interface IKeep3rV1 {
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
    function votes(address keeper) external view returns (uint);
}

interface IKeep3rV2Oracle {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint amountOut, uint lastUpdatedAgo);
}

contract Keep3rV2Helper {

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    IKeep3rV2Oracle public constant KV2O = IKeep3rV2Oracle(0xe20B3f175F9f4e1EDDf333f96b72Bba138c9e83a);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint constant public MIN = 11;
    uint constant public MAX = 12;
    uint constant public BASE = 10;
    uint constant public SWAP = 300000;
    uint constant public TARGETBOND = 200e18;
    
    function quote(uint eth) public view returns (uint amountOut) {
        (amountOut,) = KV2O.quote(address(WETH), eth, address(KP3R), 1);
    }

    function getFastGas() external view returns (uint) {
        return uint(FASTGAS.latestAnswer());
    }

    function bonds(address keeper) public view returns (uint) {
        return KP3R.bonds(keeper, address(KP3R)) + (KP3R.votes(keeper));
    }

    function getQuoteLimitFor(address origin, uint gasUsed) public view returns (uint) {
        uint _quote = quote((gasUsed+SWAP)*(uint(FASTGAS.latestAnswer())));
        uint _min = _quote * MIN / BASE;
        uint _boost = _quote * MAX / BASE;
        uint _bond = Math.min(bonds(origin), TARGETBOND);
        return Math.max(_min, _boost * _bond / TARGETBOND);
    }

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        return getQuoteLimitFor(tx.origin, gasUsed);
    }
}