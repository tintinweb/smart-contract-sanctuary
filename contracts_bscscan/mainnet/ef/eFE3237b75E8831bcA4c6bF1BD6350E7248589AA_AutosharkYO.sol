pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IFinsPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IFinsRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapFeeReward() external pure returns (address);

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract AutosharkYO {

    using SafeMath for uint256;

    address private constant PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant SHARK_ROUTER_ADDRESS = 0xB0EeB0632bAB15F120735e5838908378936bd484;

    address private constant FINS_TOKEN_ADDRESS = 0x1b219Aca875f8C74c33CFF9fF98f3a9b62fCbff5;
    address private constant BNB_TOKEN_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant ATLAS_TOKEN_ADDRESS = 0xcf87Ccf958d728f50d8ae5E4f15Bc4cA5733cDf5;
    address private constant BUSD_TOKEN_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    address private constant FINS_BNB_TOKEN_ADDRESS = 0x14B5a6d26577970953F9E6608d6604e4676Ac5b7;
    address private constant ATLAS_BUSD_TOKEN_ADDRESS = 0x8eC2dCc0B88ef879C885B0b31e87aBa14543a8cd;

    address private constant PANCAKE_BNB_BUSD_TOKEN_ADDRESS = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;
    address private constant SHARK_BNB_BUSD_TOKEN_ADDRESS = 0xD636EA3609615ad8Aa667509c50946098454EaD2;
    
    IPancakeRouter02 private constant pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS);
    IFinsRouter02 private constant sharkRouter = IFinsRouter02(SHARK_ROUTER_ADDRESS);
    address payable private immutable owner;

    constructor(address payable _owner) public {
        require(msg.sender == _owner);
        owner = _owner;
        approveRouterToSpendMyTokens();
    }

    function approveRouterToSpendMyTokens() internal {
        IERC20 tokenApi = IERC20(FINS_TOKEN_ADDRESS);
        uint256 allowance = tokenApi.allowance(address(this), SHARK_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(SHARK_ROUTER_ADDRESS, 1e27);
        }
        tokenApi = IERC20(BNB_TOKEN_ADDRESS);
        allowance = tokenApi.allowance(address(this), SHARK_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(SHARK_ROUTER_ADDRESS, 1e27);
        }
        tokenApi = IERC20(ATLAS_TOKEN_ADDRESS);
        allowance = tokenApi.allowance(address(this), SHARK_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(SHARK_ROUTER_ADDRESS, 1e27);
        }
        tokenApi = IERC20(BUSD_TOKEN_ADDRESS);
        allowance = tokenApi.allowance(address(this), SHARK_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(SHARK_ROUTER_ADDRESS, 1e27);
        }
        allowance = tokenApi.allowance(address(this), PANCAKE_ROUTER_ADDRESS);
        if (allowance < 1e27) {
            tokenApi.approve(PANCAKE_ROUTER_ADDRESS, 1e27);
        }
    }

    function transferTokensToOwner(IERC20 tokenApi) internal {
        uint256 balance = tokenApi.balanceOf(address(this));
        if (balance > 0) {
            tokenApi.transfer(owner, balance);
        }
    }

    function escapeHatch() external {
        require(msg.sender == owner);
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        transferTokensToOwner(IERC20(BNB_TOKEN_ADDRESS));
        transferTokensToOwner(IERC20(FINS_TOKEN_ADDRESS));
        transferTokensToOwner(IERC20(ATLAS_TOKEN_ADDRESS));
        transferTokensToOwner(IERC20(BUSD_TOKEN_ADDRESS));
    }

    receive() external payable {}

    function getSharkAmountOut(IFinsPair pair, uint amountIn, bool invert) internal view returns (uint amountOut) {
        uint reserveIn;
        uint reserveOut;
        if (invert) {
            (reserveOut, reserveIn,) = pair.getReserves();
        } else {
            (reserveIn, reserveOut,) = pair.getReserves();
        }
        require(amountIn > 0, 'getSharkAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getSharkAmountOut: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(uint(10000).sub(pair.swapFee()+13));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getPancakeAmountOut(IPancakePair pair, uint amountIn, bool invert) internal view returns (uint amountOut) {
        uint reserveIn;
        uint reserveOut;
        if (invert) {
            (reserveOut, reserveIn,) = pair.getReserves();
        } else {
            (reserveIn, reserveOut,) = pair.getReserves();
        }
        require(amountIn > 0, 'getPancakeAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'getPancakeAmountOut: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(uint(10000).sub(30));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _swapToBnb(uint256 finsAmount, address to) internal returns (uint amountReceived) {
        address[] memory path = new address[](2);
        path[0] = address(FINS_TOKEN_ADDRESS);
        path[1] = address(BNB_TOKEN_ADDRESS);
        return sharkRouter.swapExactTokensForETH(
            finsAmount,
            getSharkAmountOut(IFinsPair(FINS_BNB_TOKEN_ADDRESS), finsAmount, false),
            path,
            payable(to),
            block.timestamp + (1000 * 60 * 5)
        )[1];
    }

    function swapToBnb(uint256 finsAmount) external {
        transferFinsFromSender(finsAmount, msg.sender);
        _swapToBnb(finsAmount, msg.sender);
    }

    function transferFinsFromSender(uint amount, address sender) internal returns (uint finsAmount) {
        IERC20 tokenApi = IERC20(FINS_TOKEN_ADDRESS);
        if (amount == 0) {
            finsAmount = tokenApi.balanceOf(sender);
        } else {
            finsAmount = amount;
        }
        require(finsAmount > 0, "0fins");
        tokenApi.transferFrom(sender, payable(address(this)), finsAmount);
        return finsAmount;
    }

    function swapBusdToAtlasBusd() external {
        IERC20 tokenApi = IERC20(BUSD_TOKEN_ADDRESS);
        uint busdAmount = tokenApi.balanceOf(msg.sender);
        busdAmount = busdAmount/2; //only half is converted to atlas
        require(busdAmount > 0, "0busd");
        tokenApi.transferFrom(msg.sender, payable(address(this)), busdAmount);
        address[] memory path = new address[](2);
        path[0] = address(BUSD_TOKEN_ADDRESS);
        path[1] = address(ATLAS_TOKEN_ADDRESS);
        IERC20(BUSD_TOKEN_ADDRESS).approve(SHARK_ROUTER_ADDRESS, 1e27);
        IERC20(ATLAS_TOKEN_ADDRESS).approve(SHARK_ROUTER_ADDRESS, 1e27);
        uint amountReceived = sharkRouter.swapExactTokensForTokens(
            busdAmount,
            getSharkAmountOut(IFinsPair(ATLAS_BUSD_TOKEN_ADDRESS), busdAmount, true),
            path,
            payable(address(this)),
            block.timestamp + (1000 * 60 * 5)
        )[1];
        // amountReceived = atlas
        sharkRouter.addLiquidity(
            ATLAS_TOKEN_ADDRESS,
            BUSD_TOKEN_ADDRESS,
            amountReceived,
            busdAmount,
            (amountReceived*995)/1000,
            (busdAmount*995)/1000,
            payable(msg.sender),
            block.timestamp + (1000*60*10)
        );
    }

    function swapToAtlasBusd() external {
        uint finsAmount = transferFinsFromSender(0, msg.sender);
        uint amountReceived = _swapToBnb(finsAmount, payable(address(this)));
        // amountReceived = bnb
        uint  sharkAmountOut = getSharkAmountOut(IFinsPair(SHARK_BNB_BUSD_TOKEN_ADDRESS), amountReceived, false);
        uint  pancakeAmountOut = getPancakeAmountOut(IPancakePair(PANCAKE_BNB_BUSD_TOKEN_ADDRESS), amountReceived, false);
        address[] memory path = new address[](2);
        path[0] = address(BNB_TOKEN_ADDRESS);
        path[1] = address(BUSD_TOKEN_ADDRESS);
        if (pancakeAmountOut > sharkAmountOut) {
            amountReceived = pancakeRouter.swapExactETHForTokens{value: amountReceived}(
                pancakeAmountOut,
                path,
                payable(address(this)),
                block.timestamp + (1000 * 60 * 5)
            )[1];
        } else {
            amountReceived = sharkRouter.swapExactETHForTokens{value: amountReceived}(
                pancakeAmountOut,
                path,
                payable(address(this)),
                block.timestamp + (1000 * 60 * 5)
            )[1];
        }
        // amountReceived = busd
        path[0] = address(BUSD_TOKEN_ADDRESS);
        path[1] = address(ATLAS_TOKEN_ADDRESS);
        uint busdAmount = amountReceived/2;
        amountReceived = sharkRouter.swapExactTokensForTokens(
            busdAmount,
            getSharkAmountOut(IFinsPair(ATLAS_BUSD_TOKEN_ADDRESS), busdAmount, true),
            path,
            payable(address(this)),
            block.timestamp + (1000 * 60 * 5)
        )[1];
        // amountReceived = atlas
        sharkRouter.addLiquidity(
            ATLAS_TOKEN_ADDRESS,
            BUSD_TOKEN_ADDRESS,
            amountReceived,
            busdAmount,
            (amountReceived*995)/1000,
            (busdAmount*995)/1000,
            payable(msg.sender),
            block.timestamp + (1000*60*10)
        );
    }

    function swapToFinsBnb() external {
        uint finsAmount = transferFinsFromSender(0, msg.sender);
        finsAmount = finsAmount/2;
        uint bnbAmount = _swapToBnb(finsAmount, payable(address(this)));
        IWETH(BNB_TOKEN_ADDRESS).deposit{value: bnbAmount}();
        sharkRouter.addLiquidity(
            FINS_TOKEN_ADDRESS,
            BNB_TOKEN_ADDRESS,
            finsAmount,
            bnbAmount,
            (finsAmount*995)/1000,
            (bnbAmount*995)/1000,
            payable(msg.sender),
            block.timestamp + (1000*60*10)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}