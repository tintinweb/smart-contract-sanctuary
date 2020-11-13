// SPDX-License-Identifier: MIT


/**
 * KP2R.NETWORK
 * A standard implementation of kp3rv1 protocol
 * Optimized Dapp
 * Scalability
 * Clean & tested code
 */

pragma solidity ^0.5.17;


library SafeMath {
   
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
          if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }
  function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
       if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
  function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }
  function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
  function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }
 function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

  interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
  function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: reverted");
    }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: < 0");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: !contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: !succeed");
        }
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
   function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IKeep2r {
    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool);
    function worked(address keeper) external;
}


interface ICERC20 {
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

interface ICEther {
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function borrowBalanceStored(address account) external view returns (uint);
}

interface IComptroller {
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function closeFactorMantissa() external view returns (uint);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint reserve0, uint reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWETH9 {
    function deposit() external payable;
}

contract CompoundFlashLiquidationsKeep2r {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IComptroller constant public Comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IUniswapV2Factory constant public FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router constant public ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public cETH = address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    modifier upkeep() {
        require(KP2R.isMinKeeper(tx.origin, 100e18, 0, 0), "::isKeeper: keeper is not registered");
        _;
        KP2R.worked(msg.sender);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    IKeep2r public constant KP2R = IKeep2r(0x9BdE098Be22658d057C3F1F185e3Fd4653E2fbD1);

    function pairFor(address borrowed) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(borrowed, WETH);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                FACTORY,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    function calcRepayAmount(IUniswapV2Pair pair, uint amount0, uint amount1) public view returns (uint) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        uint val = 0;
        if (amount0 == 0) {
            val = amount1.mul(reserve0).div(reserve1);
        } else {
            val = amount0.mul(reserve1).div(reserve0);
        }

        return (val
                .add(val.mul(301).div(100000)))
                .mul(reserve0.mul(reserve1))
                .div(IERC20(pair.token0()).balanceOf(address(pair))
                .mul(IERC20(pair.token1()).balanceOf(address(pair))));
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        uint amountInWithFee = amountIn.mul(997);
        return amountInWithFee.mul(reserveOut) / reserveIn.mul(1000).add(amountInWithFee);
    }

    function _swap(address suppliedUnderlying, address supplied, IUniswapV2Pair toPair) internal {
        address _underlying = suppliedUnderlying;
        if (supplied == cETH) {
            _underlying = WETH;
            IWETH9(WETH).deposit.value(address(this).balance)();
        } else {
            (uint reserve0, uint reserve1,) = toPair.getReserves();
            uint amountIn = IERC20(_underlying).balanceOf(address(this));
            IERC20(_underlying).transfer(address(toPair), amountIn);
            if (_underlying == toPair.token0()) {
                toPair.swap(0, getAmountOut(amountIn, reserve0, reserve1), address(this), new bytes(0));
            } else {
                toPair.swap(getAmountOut(amountIn, reserve1, reserve0), 0, address(this), new bytes(0));
            }
        }
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        uint liquidatableAmount = (amount0 == 0 ? amount1 : amount0);
        (address borrower, address borrowed, address supplied, address fromPair, address toPair, address suppliedUnderlying) = decode(data);

        ICERC20(borrowed).liquidateBorrow(borrower, liquidatableAmount, supplied);
        ICERC20(supplied).redeem(ICERC20(supplied).balanceOf(address(this)));

        _swap(suppliedUnderlying, supplied, IUniswapV2Pair(toPair));

        IERC20(WETH).transfer(fromPair, calcRepayAmount(IUniswapV2Pair(fromPair), amount0, amount1));
        IERC20(WETH).transfer(tx.origin, IERC20(WETH).balanceOf(address(this)));
    }

    function underlying(address token) external view returns (address) {
        return ICERC20(token).underlying();
    }

    function underlyingPair(address token) external view returns (address) {
        return pairFor(ICERC20(token).underlying());
    }

    function () external payable { }

    function liquidatable(address borrower, address borrowed) external view returns (uint) {
        (,,uint256 shortFall) = Comptroller.getAccountLiquidity(borrower);
        require(shortFall > 0, "liquidate:shortFall == 0");

        uint256 liquidatableAmount = ICERC20(borrowed).borrowBalanceStored(borrower);

        require(liquidatableAmount > 0, "liquidate:borrowBalanceStored == 0");

        return liquidatableAmount.mul(Comptroller.closeFactorMantissa()).div(1e18);
    }

    function calculate(address borrower, address borrowed, address supplied) external view returns (address fromPair, address toPair, address borrowedUnderlying, address suppliedUnderlying, uint amount) {
        amount = ICERC20(borrowed).borrowBalanceStored(borrower);
        amount = amount.mul(Comptroller.closeFactorMantissa()).div(1e18);
        borrowedUnderlying = ICERC20(borrowed).underlying();

        fromPair = pairFor(borrowedUnderlying);
        suppliedUnderlying = ICERC20(supplied).underlying();
        toPair = pairFor(suppliedUnderlying);
    }

    function liquidate(address borrower, address borrowed, address supplied) external {
        (,,uint256 shortFall) = Comptroller.getAccountLiquidity(borrower);
        require(shortFall > 0, "liquidate:shortFall == 0");

        uint256 amount = ICERC20(borrowed).borrowBalanceStored(borrower);
        require(amount > 0, "liquidate:borrowBalanceStored == 0");
        amount = amount.mul(Comptroller.closeFactorMantissa()).div(1e18);
        require(amount > 0, "liquidate:liquidatableAmount == 0");

        address borrowedUnderlying = ICERC20(borrowed).underlying();

        address fromPair = pairFor(borrowedUnderlying);
        address suppliedUnderlying = ICERC20(supplied).underlying();
        address toPair = pairFor(suppliedUnderlying);

        liquidateCalculated(borrower, borrowed, supplied, fromPair, toPair, borrowedUnderlying, suppliedUnderlying, amount);
    }

    function encode(address borrower, address borrowed, address supplied, address fromPair, address toPair, address suppliedUnderlying) internal pure returns (bytes memory) {
        return abi.encode(borrower, borrowed, supplied, fromPair, toPair, suppliedUnderlying);
    }

    function decode(bytes memory b) internal pure returns (address, address, address, address, address, address) {
        return abi.decode(b, (address, address, address, address, address, address));
    }

    function liquidateCalculated(
        address borrower,
        address borrowed,
        address supplied,
        address fromPair,
        address toPair,
        address borrowedUnderlying,
        address suppliedUnderlying,
        uint amount
    ) public upkeep {
        IERC20(borrowedUnderlying).safeIncreaseAllowance(borrowed, amount);
        (uint _amount0, uint _amount1) = (borrowedUnderlying == IUniswapV2Pair(fromPair).token0() ? (amount, uint(0)) : (uint(0), amount));
        IUniswapV2Pair(fromPair).swap(_amount0, _amount1, address(this), encode(borrower, borrowed, supplied, fromPair, toPair, suppliedUnderlying));
    }
}