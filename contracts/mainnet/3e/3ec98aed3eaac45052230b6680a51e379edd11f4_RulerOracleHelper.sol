/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// File contracts/interfaces/IChainLinkOracle.sol

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}


// File contracts/interfaces/IRouter.sol

pragma solidity ^0.8.0;

interface IRouter {
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] calldata);
}


// File contracts/RulerOracleHelper.sol

pragma solidity ^0.8.0;
contract RulerOracleHelper is IChainLinkOracle {
    IRouter constant public router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    address constant public ruler = 0x2aECCB42482cc64E087b6D2e5Da39f5A7A7001f8;
    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IChainLinkOracle constant public ethFeed = IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() external override view returns (uint256 answer) {
        address[] memory path = new address[](2);
        path[0] = ruler;
        path[1] = weth;
        uint256 rulerEthPrice = router.getAmountsOut(10 ** 18, path)[1];
        uint256 ethPrice = ethFeed.latestAnswer();
        answer = rulerEthPrice * ethPrice /1e18;
    }
}