/**
 *Submitted for verification at FtmScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface PriceRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external view returns (address);
}


interface Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
}

contract PriceCalculations {
    address public primaryRouterAddress;
    address public primaryFactoryAddress;
    address public secondaryRouterAddress;
    address public secondaryFactoryAddress;
    address public wftmAddress;
    address public usdcAddress;
    PriceRouter primaryRouter;
    PriceRouter secondaryRouter;


    address ftmAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    constructor(
        address _primaryRouterAddress,
        address _primaryFactoryAddress,
        address _secondaryRouterAddress,
        address _secondaryFactoryAddress,
        address _usdcAddress
    ) {
        primaryRouterAddress = _primaryRouterAddress;
        primaryFactoryAddress = _primaryFactoryAddress;
        secondaryRouterAddress = _secondaryRouterAddress;
        secondaryFactoryAddress = _secondaryFactoryAddress;
        usdcAddress = _usdcAddress;
        primaryRouter = PriceRouter(primaryRouterAddress);
        secondaryRouter = PriceRouter(secondaryRouterAddress);
        wftmAddress = primaryRouter.WETH();
    }

    // Spirit/Spooky
    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        if (isLpToken(tokenAddress)) {
            return getLpTokenPriceUsdc(tokenAddress);
        }
        return getPriceFromRouterUsdc(tokenAddress);
    }
    

    function getPriceFromRouter(address token0Address, address token1Address)
        public
        view
        returns (uint256)
    {
        // Convert FTM address (0xEeee...) to WFTM
        if (token0Address == ftmAddress) {
            token0Address = wftmAddress;
        }
        if (token1Address == ftmAddress) {
            token1Address = wftmAddress;
        }

        address[] memory path;
        uint8 numberOfJumps;
        bool inputTokenIsWftm =
            token0Address == wftmAddress || token1Address == wftmAddress;
        if (inputTokenIsWftm) {
            // path = [token0, wftm] or [wftm, token1]
            numberOfJumps = 1;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, wftm, token1]
            numberOfJumps = 2;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = wftmAddress;
            path[2] = token1Address;
        }

        IERC20 token0 = IERC20(token0Address);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut;

        bool fallbackRouterExists = secondaryRouterAddress != zeroAddress;
        if (fallbackRouterExists) {
            try primaryRouter.getAmountsOut(amountIn, path) returns (
                uint256[] memory _amountsOut
            ) {
                amountsOut = _amountsOut;
            } catch {
                amountsOut = secondaryRouter.getAmountsOut(amountIn, path);
            }
        } else {
            amountsOut = primaryRouter.getAmountsOut(amountIn, path);
        }

        // Return raw price (without fees)
        uint256 amountOut = amountsOut[amountsOut.length - 1];
        
        return amountOut;
    }

    function getPriceFromRouterUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return getPriceFromRouter(tokenAddress, usdcAddress);
    }

    function isLpToken(address tokenAddress) public view returns (bool) {
        if (tokenAddress == ftmAddress) {
            return false;
        }
        Pair lpToken = Pair(tokenAddress);
        try lpToken.factory() {
            return true;
        } catch {
            return false;
        }
    }

    function getRouterForLpToken(address tokenAddress)
        public
        view
        returns (PriceRouter)
    {
        Pair lpToken = Pair(tokenAddress);
        address factoryAddress = lpToken.factory();
        if (factoryAddress == primaryFactoryAddress) {
            return primaryRouter;
        } else if (factoryAddress == secondaryFactoryAddress) {
            return secondaryRouter;
        }
        revert();
    }

    function getLpTokenTotalLiquidityUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        uint8 token0Decimals = token0.decimals();
        uint8 token1Decimals = token1.decimals();
        uint256 token0Price = getPriceUsdc(token0Address);
        uint256 token1Price = getPriceUsdc(token1Address);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 totalLiquidity =
            ((reserve0 / 10**token0Decimals) * token0Price) +
                ((reserve1 / 10**token1Decimals) * token1Price);
        return totalLiquidity;
    }

    function getLpTokenPriceUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        uint256 totalLiquidity = getLpTokenTotalLiquidityUsdc(tokenAddress);
        uint256 totalSupply = pair.totalSupply();
        uint8 pairDecimals = pair.decimals();
        uint256 pricePerLpTokenUsdc =
            (totalLiquidity * 10**pairDecimals) / totalSupply;
        return pricePerLpTokenUsdc;
    }
}