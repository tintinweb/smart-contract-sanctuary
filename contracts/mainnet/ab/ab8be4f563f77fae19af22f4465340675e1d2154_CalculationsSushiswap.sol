// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";

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

contract CalculationsSushiswap is Ownable {
    address public defaultRouterAddress;
    address public wethAddress;
    address public usdcAddress;
    PriceRouter defaultRouter;
    mapping(address => address) public routerOverrides;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    constructor(
        address _defaultRouterAddress,
        address _usdcAddress
    ) {
        defaultRouterAddress = _defaultRouterAddress;
        usdcAddress = _usdcAddress;
        defaultRouter = PriceRouter(defaultRouterAddress);
        wethAddress = defaultRouter.WETH();
    }
    
    function setRouterOverrideForToken(address tokenAddress, address routerAddress) public onlyOwner {
        routerOverrides[tokenAddress] = routerAddress;
    }

    // Uniswap/Sushiswap
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
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = wethAddress;
        }
        if (token1Address == ethAddress) {
            token1Address = wethAddress;
        }

        address[] memory path;
        uint8 numberOfJumps;
        bool inputTokenIsWeth =
            token0Address == wethAddress || token1Address == wethAddress;
        if (inputTokenIsWeth) {
            // path = [token0, weth] or [weth, token1]
            numberOfJumps = 1;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            numberOfJumps = 2;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = wethAddress;
            path[2] = token1Address;
        }

        IERC20 token0 = IERC20(token0Address);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut;

        PriceRouter router = defaultRouter;
        address routerOverrideAddress = routerOverrides[token0Address];
        if (routerOverrideAddress != zeroAddress) {
            router = PriceRouter(routerOverrideAddress);
        }
        amountsOut = router.getAmountsOut(amountIn, path);

        // Return raw price (without fees)
        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 30; // .3% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * numberOfJumps));
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
        if (tokenAddress == ethAddress) {
            return false;
        }
        Pair lpToken = Pair(tokenAddress);
        try lpToken.factory() {
            return true;
        } catch {
            return false;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/*******************************************************
 *                     Ownable
 *******************************************************/
contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}