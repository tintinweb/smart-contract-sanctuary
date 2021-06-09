/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
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
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }


    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract IWETH is IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, bytes memory initCode) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initCode // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB, bytes memory initCode) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, initCode)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, bytes memory initCode, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], initCode);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path, bytes memory initCode, uint fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], initCode);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, fee);
        }
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IMdexSwapMining {
    function takerWithdraw() external;
}

contract swapV1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event EVTCallExProxy (address indexed _in, address indexed _out, address indexed _trader, address _ex, uint256 _outAmount);
    event EVTSwapExactTokensForTokens(address indexed _in, address indexed _out, address indexed _trader, address _ex, uint256 _outAmount);
    event EVTSwapTokensForExactTokens(address indexed _in, address indexed _out, address indexed _trader, address _ex, uint256 _outAmount);
    event SwapToolCreated(address indexed router);


    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }


    //TODO
    uint256  feeFlag;
    address  payable private feeAddr = 0xF18463BD447597a3b7c4035EA1E7BcDc5d99F330;
    address public constant  WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 feeRate = 1;
    uint256 feePercent1000 = 1000;
    uint256 userFundsRate = feePercent1000 - feeRate;
    //TODO
    address private _owner;
    address emptyAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) routerMap;
    mapping(address => bytes) factoryMap;
    mapping(address => uint256) factoryFeeMap;
    IWETH wethToken;


    constructor() public {
        wethToken = IWETH(WETH);
        _owner = msg.sender;
        feeFlag = 1;
        emit SwapToolCreated(address(this));

        factoryMap[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';
        factoryFeeMap[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = 9970;
        factoryMap[0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac] = hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303';
        factoryFeeMap[0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac] = 9970;

        routerMap[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        routerMap[0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F] = true;

    }


    function pairFor(address factory, address tokenA, address tokenB, bytes memory initCode) public pure returns (address pair) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB, initCode);
    }

    modifier onlyOwner() {
        require(tx.origin == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    function addRouter(address router) public onlyOwner {
        routerMap[router] = true;

    }

    function isRouter(address router) public view returns (bool){
        return routerMap[router];
    }

    function addFactory(address _factory, uint256 fee, bytes memory initCode) public onlyOwner {
        factoryMap[_factory] = initCode;
        factoryFeeMap[_factory] = fee;
    }

    function setFeeFlag(uint256 f) public onlyOwner {
        feeFlag = f;
    }

    function setFeeRate(uint256 fee) public onlyOwner {
        require(fee > 0 && fee <= 10, "1-10");
        feeRate = fee;
    }

    function _needFee() internal view returns (bool){
        return feeFlag == 1;
    }


    function callExProxy(address router, IERC20 inToken, IERC20 outToken, uint256 amountIn, uint256 amountOutMin, bytes memory data) public payable {
        require(router != address(this), "Illegal");
        require(amountOutMin > 0, 'Limit Amount must be set');
        require(isRouter(router), "Illegal router address");

        if (address(inToken) != emptyAddr) {
            require(msg.value == 0, "eth 0");
            transferFromUser(inToken, msg.sender, amountIn);
        }

        approve(inToken, router);
        //swap
        (bool success,) = router.call.value(msg.value)(data);
        require(success, "call ex fail");

        uint256 tradeReturn = viewBalance(outToken, address(this));
        require(tradeReturn >= amountOutMin, 'Trade returned less than the minimum amount');

        // return any unspent funds
        uint256 leftover = viewBalance(inToken, address(this));
        if (leftover > 0) {
            sendFunds(inToken, msg.sender, leftover);
        }

        if (_needFee()) {
            sendFunds(outToken, msg.sender, tradeReturn.mul(userFundsRate).div(feePercent1000));
            sendFunds(outToken, feeAddr, tradeReturn.mul(feeRate).div(feePercent1000));
        } else {
            sendFunds(outToken, msg.sender, tradeReturn);
        }
        emit EVTCallExProxy(address(inToken), address(outToken), msg.sender, router, tradeReturn);

    }

    function swapExactTokensForTokens(address factory, IERC20 inToken, IERC20 outToken, uint256 amountIn, uint256 amountOutMin, uint deadline, address[] memory path) public payable ensure(deadline) {
        require(factory != address(this), "Illegal");
        require(amountOutMin > 0, 'Limit Amount must be set');
        require(factoryMap[factory].length > 0, "add factory before");
        bytes memory initCode = factoryMap[factory];
        uint[] memory amounts = new uint[](path.length);
        {
            uint fee = factoryFeeMap[factory];
            amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path, initCode, fee);
        }
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        address firstPair = UniswapV2Library.pairFor(factory, path[0], path[1], initCode);
        if (address(inToken) != emptyAddr) {
            require(msg.value == 0, "eth 0");
            safeTransferFrom(address(inToken), msg.sender, firstPair, amountIn);
        } else {
            inToken = IERC20(WETH);
            wethToken.deposit.value(msg.value)();
            inToken.safeTransfer(firstPair, msg.value);
        }
        if (_needFee()) {
            {
                _swap(factory, amounts, path, address(this), initCode);
            }

            if (address(outToken) == emptyAddr) {
                wethToken.withdraw(wethToken.balanceOf(address(this)));
            }

            uint256 tradeReturn = viewBalance(outToken, address(this));
            require(tradeReturn >= amountOutMin, 'Trade returned less than the minimum amount');

            uint256 leftover = viewBalance(inToken, address(this));
            if (leftover > 0) {
                sendFunds(inToken, msg.sender, leftover);
            }
            sendFunds(outToken, msg.sender, tradeReturn.mul(userFundsRate).div(feePercent1000));
            sendFunds(outToken, feeAddr, tradeReturn.mul(feeRate).div(feePercent1000));
        } else {

            if (address(outToken) == emptyAddr) {
                _swap(factory, amounts, path, address(this), initCode);
                uint256 tradeReturn = wethToken.balanceOf(address(this));
                wethToken.withdraw(tradeReturn);
                sendFunds(outToken, msg.sender, tradeReturn);
            } else {
                _swap(factory, amounts, path, msg.sender, initCode);
            }

        }
        emit EVTSwapExactTokensForTokens(address(inToken), address(outToken), msg.sender, factory, amounts[amounts.length - 1]);
    }


    function swapTokensForExactTokens(address factory, IERC20 inToken, IERC20 outToken, uint256 amountInMax, uint256 amountOut, uint deadline, address[] memory path) public payable ensure(deadline) {
        require(factory != address(this), "Illegal");
        require(factoryMap[factory].length > 0, "add factory before");
        bytes memory initCode = factoryMap[factory];
        uint[] memory amounts = new uint[](path.length);
        {
            uint fee = factoryFeeMap[factory];
            amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path, initCode, fee);
        }
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        address firstPair = UniswapV2Library.pairFor(factory, path[0], path[1], initCode);
        if (address(inToken) != emptyAddr) {
            require(msg.value == 0, "eth 0");
            safeTransferFrom(address(inToken), msg.sender, firstPair, amounts[0]);
        } else {
            require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
            inToken = IERC20(WETH);
            wethToken.deposit.value(amounts[0])();
            inToken.safeTransfer(firstPair, amounts[0]);
        }
        if (_needFee()) {
            {
                _swap(factory, amounts, path, address(this), initCode);
            }

            if (address(outToken) == emptyAddr) {
                wethToken.withdraw(wethToken.balanceOf(address(this)));
            }

            sendFunds(outToken, msg.sender, amountOut.mul(userFundsRate).div(feePercent1000));
            sendFunds(outToken, feeAddr, amountOut.mul(feeRate).div(feePercent1000));
        } else {

            if (address(outToken) == emptyAddr) {
                _swap(factory, amounts, path, address(this), initCode);
                uint256 tradeReturn = wethToken.balanceOf(address(this));
                wethToken.withdraw(tradeReturn);
                sendFunds(outToken, msg.sender, tradeReturn);
            } else {
                _swap(factory, amounts, path, msg.sender, initCode);
            }

        }
        if (msg.value > amounts[0]) {
            //eth
            msg.sender.transfer(msg.value.sub(amounts[0]));
        }

        emit EVTSwapTokensForExactTokens(address(inToken), address(outToken), msg.sender, factory, amountOut);
    }


    function transferFromUser(IERC20 erc, address _from, uint256 _inAmount) internal {
        if (
            address(erc) != emptyAddr &&
        erc.allowance(_from, address(this)) >= _inAmount
        ) {
            safeTransferFrom(address(erc), _from, address(this), _inAmount);
        }
    }

    function approve(IERC20 erc, address approvee) internal {
        if (
            address(erc) != emptyAddr &&
            erc.allowance(address(this), approvee) == 0
        ) {
            erc.safeApprove(approvee, uint256(- 1));
        }
    }

    function viewBalance(IERC20 erc, address owner) internal view returns (uint256) {
        if (address(erc) == emptyAddr) {
            return owner.balance;
        } else {
            return erc.balanceOf(owner);
        }
    }

    function sendFunds(IERC20 erc, address payable receiver, uint256 funds) internal {
        if (address(erc) == emptyAddr) {
            receiver.transfer(funds);
        } else {
            safeTransfer(address(erc), receiver, funds);
        }
    }


    function _swap(address factory, uint[] memory amounts, address[] memory path, address _to, bytes memory initCode) internal {
        //
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2], initCode) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output, initCode)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAnyToken(IERC20 erc) external onlyOwner {
        safeTransfer(address(erc), msg.sender, erc.balanceOf(address(this)));
    }

    function() external payable {
        require(msg.sender != tx.origin, "233333");
    }

}