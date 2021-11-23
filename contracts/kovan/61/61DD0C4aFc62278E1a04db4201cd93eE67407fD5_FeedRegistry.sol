/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/feedregistry.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

////// src/feedregistry.sol
/* pragma solidity >=0.7.6; */

interface FeedRegistryLike {
    function latestRoundData(address base, address quote) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals(address base, address quote) external view returns (uint);
}

interface UniswapOracle {
    function observe(uint32[] memory secondsAgos) external view returns (int56[] memory, uint160[] memory);
}

contract FeedRegistry {

    FeedRegistryLike immutable fallbackFeedRegistry;
    UniswapOracle immutable usdcWcfgPool;
    address immutable wcfg;

    constructor(address fallbackFeedRegistry_, address usdcWcfgPool_, address wcfg_) {
        fallbackFeedRegistry = FeedRegistryLike(fallbackFeedRegistry_); // 0xAa7F6f7f507457a1EE157fE97F6c7DB2BEec5cD0 on kovan
        usdcWcfgPool = UniswapOracle(usdcWcfgPool_); // 0x7270233cCAE676e776a659AFfc35219e6FCfbB10 on kovan 
        wcfg = wcfg_; // 0xd4fc010E195eaa4ACE923e7456feE062BB3Fc5c8 on kovan
    }

    function latestRoundData(address base, address quote) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        if (quote != address(0) || base != wcfg) {
            return fallbackFeedRegistry.latestRoundData(base, quote);
        }

        // (int56[] memory observations,) = usdcWcfgPool.observe([0, 1]);
        return (0, 99953417, 0, block.timestamp, 0);
    }

    function decimals(address base, address quote) external view returns (uint) {
        if (quote != address(0) || base != wcfg) {
            return fallbackFeedRegistry.decimals(base, quote);
        }
        
        return 18;
    }

}