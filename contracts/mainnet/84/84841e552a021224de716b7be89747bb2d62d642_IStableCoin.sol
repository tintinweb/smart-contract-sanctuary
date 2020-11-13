// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IStableCoin {
    function init(
        string calldata name,
        string calldata symbol,
        address doubleProxy,
        address[] calldata allowedPairs,
        uint256[] calldata rebalanceRewardMultiplier,
        uint256[] calldata timeWindows,
        uint256[] calldata mintables
    ) external;

    function tierData() external view returns(uint256[] memory, uint256[] memory);

    function availableToMint() external view returns(uint256);

    function doubleProxy() external view returns (address);

    function setDoubleProxy(address newDoubleProxy) external;

    function allowedPairs() external view returns (address[] memory);

    function setAllowedPairs(address[] calldata newAllowedPairs) external;

    function rebalanceRewardMultiplier()
        external
        view
        returns (uint256[] memory);

    function differences() external view returns (uint256, uint256);

    function calculateRebalanceByDebtReward(uint256 burnt)
        external
        view
        returns (uint256);

    function fromTokenToStable(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function mint(
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256);

    function burn(
        uint256 pairIndex,
        uint256 pairAmount,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256, uint256);

    function rebalanceByCredit(
        uint256 pairIndex,
        uint256 pairAmount,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256);

    function rebalanceByDebt(uint256 amount) external returns(uint256);
}

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getToken() external view returns (address);

    function getMVDFunctionalitiesManagerAddress()
        external
        view
        returns (address);

    function getMVDWalletAddress() external view returns (address);

    function getStateHolderAddress() external view returns (address);

    function submit(string calldata codeName, bytes calldata data)
        external
        payable
        returns (bytes memory returnData);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality)
        external
        view
        returns (bool);
}

interface IStateHolder {
    function getBool(string calldata varName) external view returns (bool);
    function getUint256(string calldata varName) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}