// File: contracts/interfaces/IUniswapV2ERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IUniswapV2ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// File: contracts/interfaces/IUniswapV2Router2.sol

pragma solidity ^0.6.12;

interface IUniswapV2Router2 {
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

// File: contracts/PickleJar.sol

pragma solidity ^0.6.12;




// PickleJAR contract helps you swap your UNIV2 LP tokens around,
// using uniswap's permit functionality, so only 1 tx is needed
// e.g. from ETH/USDC LP tokens to ETH/USDT LP tokens
contract PickleJar {
    IUniswapV2Router2 router = IUniswapV2Router2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    function convertWETHPair(
        address fromLP,
        address toLP,
        uint256 value
    ) public {
        IUniswapV2Pair fromPair = IUniswapV2Pair(fromLP);
        IUniswapV2Pair toPair = IUniswapV2Pair(toLP);

        address weth = router.WETH();

        // Only for WETH/<TOKEN> pairs
        if (!(fromPair.token0() == weth || fromPair.token1() == weth)) {
            revert("!eth-from");
        }
        if (!(toPair.token0() == weth || toPair.token1() == weth)) {
            revert("!eth-to");
        }

        // Get non-eth token from pairs
        address _from = fromPair.token0() != weth
            ? fromPair.token0()
            : fromPair.token1();

        address _to = toPair.token0() != weth
            ? toPair.token0()
            : toPair.token1();

        // Transfer
        IUniswapV2ERC20(fromLP).transferFrom(msg.sender, address(this), value);

        // Remove liquidity
        IUniswapV2ERC20(fromLP).approve(address(router), value);
        router.removeLiquidity(
            fromPair.token0(),
            fromPair.token1(),
            value,
            0,
            0,
            address(this),
            now + 60
        );

        // Convert to target token
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = weth;
        path[2] = _to;
        IUniswapV2ERC20(_from).approve(address(router), uint256(-1));
        router.swapExactTokensForTokens(
            IUniswapV2ERC20(_from).balanceOf(address(this)),
            0,
            path,
            address(this),
            now + 60
        );

        // Supply liquidity
        IUniswapV2ERC20(weth).approve(address(router), uint256(-1));
        IUniswapV2ERC20(_to).approve(address(router), uint256(-1));
        router.addLiquidity(
            weth,
            _to,
            IUniswapV2ERC20(weth).balanceOf(address(this)),
            IUniswapV2ERC20(_to).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            now + 60
        );

        // Refund sender any remaining tokens
        IUniswapV2ERC20(weth).transfer(
            msg.sender,
            IUniswapV2ERC20(weth).balanceOf(address(this))
        );
        IUniswapV2ERC20(_to).transfer(
            msg.sender,
            IUniswapV2ERC20(_to).balanceOf(address(this))
        );
    }

    function convertWETHPairWithPermit(
        address fromLP,
        address toLP,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Permit
        IUniswapV2ERC20(fromLP).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        convertWETHPair(fromLP, toLP, value);
    }
}