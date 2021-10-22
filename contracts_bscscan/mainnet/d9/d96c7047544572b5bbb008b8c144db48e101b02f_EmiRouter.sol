/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IEmiswap.sol


pragma solidity ^0.6.0;


interface IEmiswapRegistry {
    function pools(IERC20 token1, IERC20 token2)
        external
        view
        returns (IEmiswap);

    function isPool(address addr) external view returns (bool);

    function deploy(IERC20 tokenA, IERC20 tokenB) external returns (IEmiswap);
    function getAllPools() external view returns (IEmiswap[] memory);
}

interface IEmiswap {
    function fee() external view returns (uint256);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[] calldata amounts,
        uint256[] calldata minAmounts,
        address referral
    ) external payable returns (uint256 fairSupply);

    function withdraw(uint256 amount, uint256[] calldata minReturns) external;

    function getBalanceForAddition(IERC20 token)
        external
        view
        returns (uint256);

    function getBalanceForRemoval(IERC20 token) external view returns (uint256);

    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) external view returns (uint256, uint256);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        address to,
        address referral
    ) external payable returns (uint256 returnAmount);

    function initialize(IERC20[] calldata assets) external;
}

// File: contracts/libraries/EmiswapLib.sol

pragma solidity ^0.6.0;




library EmiswapLib {
    using SafeMath for uint256;
    uint256 public constant FEE_DENOMINATOR = 1e18;

    function previewSwapExactTokenForToken(
        address factory,
        address tokenFrom,
        address tokenTo,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(tokenFrom), IERC20(tokenTo));

        if (pairContract != IEmiswap(0)) {
            (,ammountTo) = pairContract.getReturn(
                IERC20(tokenFrom),
                IERC20(tokenTo),
                ammountFrom
            );
        }
    }

    /**************************************************************************************
     * get preview result of virtual swap by route of tokens
     **************************************************************************************/
    function previewSwapbyRoute(
        address factory,
        address[] memory path,
        uint256 ammountFrom
    ) internal view returns (uint256 ammountTo) {
        for (uint256 i = 0; i < path.length - 1; i++) {
            if (path.length >= 2) {
                ammountTo = previewSwapExactTokenForToken(
                    factory,
                    path[i],
                    path[i + 1],
                    ammountFrom
                );

                if (i == (path.length - 2)) {
                    return (ammountTo);
                } else {
                    ammountFrom = ammountTo;
                }
            }
        }
    }

    function fee(address factory) internal view returns (uint256) {
        return IEmiswap(factory).fee();
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        address factory,
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "EmiswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "EmiswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator =
            reserveOut.sub(amountOut).mul(
                uint256(1000000000000000000).sub(fee(factory)).div(1e15)
            ); // 997
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        address factory,
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) {
            return (0);
        }

        uint256 amountInWithFee =
            amountIn.mul(
                uint256(1000000000000000000).sub(fee(factory)).div(1e15)
            ); //997
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = (denominator == 0 ? 0 : amountOut =
            numerator /
            denominator);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IEmiswap pairContract =
                IEmiswapRegistry(factory).pools(
                    IERC20(IERC20(path[i])),
                    IERC20(path[i - 1])
                );

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(
                    IERC20(path[i - 1])
                );
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(
                    IERC20(path[i])
                );
            }

            amounts[i - 1] = getAmountIn(
                factory,
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "EmiswapLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            IEmiswap pairContract =
                IEmiswapRegistry(factory).pools(
                    IERC20(IERC20(path[i])),
                    IERC20(path[i + 1])
                );

            uint256 reserveIn;
            uint256 reserveOut;

            if (address(pairContract) != address(0)) {
                reserveIn = IEmiswap(pairContract).getBalanceForAddition(
                    IERC20(path[i])
                );
                reserveOut = IEmiswap(pairContract).getBalanceForRemoval(
                    IERC20(path[i + 1])
                );
            }

            amounts[i + 1] = getAmountOut(
                factory,
                amounts[i],
                reserveIn,
                reserveOut
            );
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "EmiswapLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "EmiswapLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

// File: contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/interfaces/IWETH.sol


pragma solidity ^0.6.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/EmiRouter.sol


pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;







contract EmiRouter {
    using SafeMath for uint256;

    address public factory;
    address public WETH;

    struct PoolData {
        IEmiswap pool;
        uint256 balanceA;
        uint256 balanceB;
    }

    event Log(uint256 a, uint256 b);

    constructor(address _factory, address _wEth) public {
        factory = _factory;
        WETH = _wEth;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** Pool Info ****

    function tokenToIERC(IERC20 _token) public view returns (IERC20) {
        return (address(_token) == address(0) ? IERC20(WETH) : _token);
    }

    function getPoolDataList(
        IERC20[] memory tokenAList,
        IERC20[] memory tokenBList
    ) public view returns (PoolData[] memory dataList) {
        if (tokenAList.length > 0 && tokenAList.length == tokenBList.length) {
            dataList = new PoolData[](tokenAList.length);
            for (uint256 i = 0; i < tokenAList.length; i++) {
                if (
                    address(
                        IEmiswapRegistry(address(factory)).pools(
                            tokenToIERC(tokenAList[i]),
                            tokenToIERC(tokenBList[i])
                        )
                    ) != address(0)
                ) {
                    dataList[i].pool = IEmiswapRegistry(address(factory)).pools(
                        tokenToIERC(tokenAList[i]),
                        tokenToIERC(tokenBList[i])
                    );
                    dataList[i].balanceA = IEmiswap(address(dataList[i].pool))
                        .getBalanceForAddition(tokenToIERC(tokenAList[i]));
                    dataList[i].balanceB = IEmiswap(address(dataList[i].pool))
                        .getBalanceForAddition(tokenToIERC(tokenBList[i]));
                }
            }
        } else {
            dataList = new PoolData[](1);
        }
    }

    function getReservesByPool(address pool)
        public
        view
        returns (uint256 _reserve0, uint256 _reserve1)
    {
        _reserve0 = IEmiswap(pool).getBalanceForAddition(
            IEmiswap(pool).tokens(0)
        );
        _reserve1 = IEmiswap(pool).getBalanceForAddition(
            IEmiswap(pool).tokens(1)
        );
    }

    function getReserves(IERC20 token0, IERC20 token1)
        public
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            address poolAddresss
        )
    {
        if (
            address(
                IEmiswapRegistry(address(factory)).pools(
                    tokenToIERC(token0),
                    tokenToIERC(token1)
                )
            ) != address(0)
        ) {
            _reserve0 = IEmiswapRegistry(address(factory))
                .pools(tokenToIERC(token0), tokenToIERC(token1))
                .getBalanceForAddition(tokenToIERC(token0));
            _reserve1 = IEmiswapRegistry(address(factory))
                .pools(tokenToIERC(token0), tokenToIERC(token1))
                .getBalanceForAddition(tokenToIERC(token1));
            poolAddresss = address(
                IEmiswapRegistry(address(factory)).pools(
                    tokenToIERC(token0),
                    tokenToIERC(token1)
                )
            );
        }
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    )
        public
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        address[] memory path;
        path = new address[](2);
        path[0] = address(tokenToIERC(fromToken));
        path[1] = address(tokenToIERC(destToken));

        returnAmount = getAmountsOut(amount, path)[1];
        uint256[] memory _distribution;
        _distribution = new uint256[](34);
        _distribution[12] = 1;
        distribution = _distribution;
    }

    function resetAllowance(address token, address pairContract) public {
        if (IERC20(token).allowance(address(this), pairContract) > 0) {
            TransferHelper.safeApprove(token, pairContract, 0);
        }
    }


    // **** Liquidity ****
    /**
     * @param tokenA address of first token in pair
     * @param tokenB address of second token in pair
     * @return LP balance
     */
    function getLiquidity(address tokenA, address tokenB)
        external
        view
        returns (uint256)
    {
        return (
            IERC20(
                address(
                    IEmiswapRegistry(factory).pools(
                        IERC20(tokenA),
                        IERC20(tokenB)
                    )
                )
            )
                .balanceOf(msg.sender)
        );
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        IERC20 ERC20tokenA = IERC20(tokenA);
        IERC20 ERC20tokenB = IERC20(tokenB);
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(ERC20tokenA, ERC20tokenB);
        // create the pair if it doesn't exist yet
        if (pairContract == IEmiswap(0)) {
            pairContract = IEmiswapRegistry(factory).deploy(
                ERC20tokenA,
                ERC20tokenB
            );
        }

        uint256 reserveA = pairContract.getBalanceForAddition(ERC20tokenA);
        uint256 reserveB = pairContract.getBalanceForRemoval(ERC20tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal =
                EmiswapLib.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "EmiRouter:INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal =
                    EmiswapLib.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "EmiRouter:INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @param tokenA address of first token in pair
     * @param tokenB address of second token in pair
     * @param amountADesired desired amount of first token
     * @param amountBDesired desired amount of second token
     * @param amountAMin minimum amount of first token
     * @param amountBMin minimum amount of second token
     * @param ref referral address
     * @return amountA added liquidity of first token
     * @return amountB added liquidity of second token
     * @return liquidity
     */

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address ref
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(tokenA), IERC20(tokenB));

        TransferHelper.safeTransferFrom(
            tokenA,
            msg.sender,
            address(this),
            amountA
        );
        TransferHelper.safeTransferFrom(
            tokenB,
            msg.sender,
            address(this),
            amountB
        );

        resetAllowance(tokenA, address(pairContract));
        resetAllowance(tokenB, address(pairContract));
        TransferHelper.safeApprove(tokenA, address(pairContract), amountA);
        TransferHelper.safeApprove(tokenB, address(pairContract), amountB);

        uint256[] memory amounts;
        amounts = new uint256[](2);
        uint256[] memory minAmounts;
        minAmounts = new uint256[](2);

        if (tokenA < tokenB) {
            amounts[0] = amountA;
            amounts[1] = amountB;
            minAmounts[0] = amountAMin;
            minAmounts[1] = amountBMin;
        } else {
            amounts[0] = amountB;
            amounts[1] = amountA;
            minAmounts[0] = amountBMin;
            minAmounts[1] = amountAMin;
        }

        //emit Log(amounts[0], amounts[1]);
        liquidity = IEmiswap(pairContract).deposit(amounts, minAmounts, ref);

        TransferHelper.safeTransfer(
            address(pairContract),
            msg.sender,
            liquidity
        );
    }

    /**
     * @param token address of token
     * @param amountTokenDesired desired amount of token
     * @param amountTokenMin minimum amount of token
     * @param amountETHMin minimum amount of ETH
     * @param ref referral address
     * @return amountToken added liquidity of token
     * @return amountETH added liquidity of ETH
     * @return liquidity
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address ref
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(token), IERC20(WETH));
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amountToken
        );
        // set allowance to 0
        resetAllowance(token, address(pairContract));        
        TransferHelper.safeApprove(token, address(pairContract), amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        resetAllowance(WETH, address(pairContract));
        TransferHelper.safeApprove(WETH, address(pairContract), amountETH);

        uint256[] memory amounts;
        amounts = new uint256[](2);
        uint256[] memory minAmounts;
        minAmounts = new uint256[](2);

        if (token < WETH) {
            amounts[0] = amountToken;
            amounts[1] = amountETH;
            minAmounts[0] = amountTokenMin;
            minAmounts[1] = amountETHMin;
        } else {
            amounts[0] = amountETH;
            amounts[1] = amountToken;
            minAmounts[0] = amountETHMin;
            minAmounts[1] = amountTokenMin;
        }
        liquidity = IEmiswap(pairContract).deposit(amounts, minAmounts, ref);
        TransferHelper.safeTransfer(
            address(pairContract),
            msg.sender,
            liquidity
        );
    }

    // **** REMOVE LIQUIDITY ****
    /**
     * @param tokenA address of first token in pair
     * @param tokenB address of second token in pair
     * @param liquidity LP token
     * @param amountAMin minimum amount of first token
     * @param amountBMin minimum amount of second token
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) public {
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(tokenA), IERC20(tokenB));
        TransferHelper.safeTransferFrom(
            address(pairContract),
            msg.sender,
            address(this),
            liquidity
        ); // send liquidity to this

        uint256[] memory minReturns;
        minReturns = new uint256[](2);

        if (tokenA < tokenB) {
            minReturns[0] = amountAMin;
            minReturns[1] = amountBMin;
        } else {
            minReturns[0] = amountBMin;
            minReturns[1] = amountAMin;
        }
        uint256 tokenAbalance = IERC20(tokenA).balanceOf(address(this));
        uint256 tokenBbalance = IERC20(tokenB).balanceOf(address(this));

        pairContract.withdraw(liquidity, minReturns);

        tokenAbalance = IERC20(tokenA).balanceOf(address(this)).sub(
            tokenAbalance
        );
        tokenBbalance = IERC20(tokenB).balanceOf(address(this)).sub(
            tokenBbalance
        );

        TransferHelper.safeTransfer(tokenA, msg.sender, tokenAbalance);
        TransferHelper.safeTransfer(tokenB, msg.sender, tokenBbalance);
    }

    /**
     * @param token address of token
     * @param liquidity LP token amount
     * @param amountTokenMin minimum amount of token
     * @param amountETHMin minimum amount of ETH
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) public {
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(token), IERC20(WETH));
        TransferHelper.safeTransferFrom(
            address(pairContract),
            msg.sender,
            address(this),
            liquidity
        ); // send liquidity to this

        uint256[] memory minReturns;
        minReturns = new uint256[](2);

        if (token < WETH) {
            minReturns[0] = amountTokenMin;
            minReturns[1] = amountETHMin;
        } else {
            minReturns[0] = amountETHMin;
            minReturns[1] = amountTokenMin;
        }

        uint256 tokenbalance = IERC20(token).balanceOf(address(this));
        uint256 WETHbalance = IERC20(WETH).balanceOf(address(this));

        pairContract.withdraw(liquidity, minReturns);

        tokenbalance = IERC20(token).balanceOf(address(this)).sub(tokenbalance);
        WETHbalance = IERC20(WETH).balanceOf(address(this)).sub(WETHbalance);

        TransferHelper.safeTransfer(token, msg.sender, tokenbalance);

        // convert WETH and send back raw ETH
        IWETH(WETH).withdraw(WETHbalance);
        TransferHelper.safeTransferETH(msg.sender, WETHbalance);
    }

    // **** SWAP ****

    function _swap_(
        address tokenFrom,
        address tokenTo,
        uint256 ammountFrom,
        address to,
        address ref
    ) internal returns (uint256 ammountTo) {
        IEmiswap pairContract =
            IEmiswapRegistry(factory).pools(IERC20(tokenFrom), IERC20(tokenTo));

        (, uint256 amt1) = pairContract.getReturn(
                IERC20(tokenFrom),
                IERC20(tokenTo),
                ammountFrom
            );
        if (amt1 > 0) {
            resetAllowance(tokenFrom, address(pairContract));
            TransferHelper.safeApprove(
                tokenFrom,
                address(pairContract),
                ammountFrom
            );            
            ammountTo = pairContract.swap(
                IERC20(tokenFrom),
                IERC20(tokenTo),
                ammountFrom,
                0,
                to,
                ref
            );
        }
    }

    function _swapbyRoute(
        address[] memory path,
        uint256 ammountFrom,
        address to,
        address ref
    ) internal returns (uint256 ammountTo) {
        for (uint256 i = 0; i < path.length - 1; i++) {
            if (path.length >= 2) {
                uint256 _ammountTo =
                    _swap_(
                        path[i],
                        path[i + 1],
                        ammountFrom,
                        (i == (path.length - 2) ? to : address(this)),
                        ref
                    );
                if (i == (path.length - 2)) {
                    return (_ammountTo);
                } else {
                    ammountFrom = _ammountTo;
                }
            }
        }
    }

    /**
     * @param amountIn exact in value of source token
     * @param amountOutMin minimum amount value of result token
     * @param path array of token addresses, represent the path for swaps
     * @param to send result token to
     * @param ref referral
     * @return amounts result amount
     */

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address ref
    ) external returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "EmiRouter:INSUFFICIENT_OUTPUT_AMOUNT"
        );

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        _swapbyRoute(path, amountIn, to, ref);
    }

    /**
     * @param amountOut exact in value of result token
     * @param amountInMax maximum amount value of source token
     * @param path array of token addresses, represent the path for swaps
     * @param to send result token to
     * @param ref referral
     * @return amounts result amount values
     */

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address ref
    ) external returns (uint256[] memory amounts) {
        amounts = getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "EmiRouter:EXCESSIVE_INPUT_AMOUNT"
        );

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        _swapbyRoute(path, amounts[0], to, ref);
    }

    /**
     * @param amountOutMin minimum amount value of result token
     * @param path array of token addresses, represent the path for swaps
     * @param to send result token to
     * @param ref referral
     * @return amounts result token amount values
     */

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address ref
    ) external payable returns (uint256[] memory amounts) {
        require(path[0] == WETH, "EmiRouter:INVALID_PATH");
        amounts = getAmountsOut(msg.value, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "EmiRouter:INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        _swapbyRoute(path, amounts[0], to, ref);
    }

    /**
     * @param amountOut amount value of result ETH
     * @param amountInMax maximum amount of source token
     * @param path array of token addresses, represent the path for swaps, (WETH for ETH)
     * @param to send result token to
     * @param ref referral
     * @return amounts result token amount values
     */

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        address ref
    ) external returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "EmiRouter:INVALID_PATH");
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, "EmiRouter:EXCESSIVE_AMOUNT");

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );

        uint256 result = _swapbyRoute(path, amounts[0], address(this), ref);

        IWETH(WETH).withdraw(result);
        TransferHelper.safeTransferETH(to, result);
    }

    /**
     * @param amountIn amount value of source token
     * @param path array of token addresses, represent the path for swaps, (WETH for ETH)
     * @param to send result token to
     * @param ref referral
     */

    function swapExactTokensForETH(
        uint256 amountIn,
        address[] calldata path,
        address to,
        address ref
    ) external {
        require(path[path.length - 1] == WETH, "EmiRouter:INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );

        uint256 result = _swapbyRoute(path, amountIn, address(this), ref);

        IWETH(WETH).withdraw(result);
        TransferHelper.safeTransferETH(to, result);
    }

    /**
     * @param amountOut amount of result tokens
     * @param path array of token addresses, represent the path for swaps, (WETH for ETH)
     * @param to send result token to
     * @param ref referral
     * @return amounts result token amount values
     */

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        address ref
    ) external payable returns (uint256[] memory amounts) {
        require(path[0] == WETH, "EmiRouter:INVALID_PATH");
        amounts = getAmountsIn(amountOut, path);
        require(
            amounts[0] <= msg.value,
            "EmiRouter:EXCESSIVE_INPUT_AMOUNT"
        );

        IWETH(WETH).deposit{value: amounts[0]}();

        _swapbyRoute(path, amounts[0], to, ref);
    }

    // **** LIBRARY FUNCTIONS ****
    /**
     * @param amountIn amount of source token
     * @param path array of token addresses, represent the path for swaps, (WETH for ETH)
     * @return amounts result token amount values
     */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        return EmiswapLib.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @param amountOut amount of result token
     * @param path array of token addresses, represent the path for swaps, (WETH for ETH)
     * @return amounts result token amount values
     */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        return EmiswapLib.getAmountsIn(factory, amountOut, path);
    }
}