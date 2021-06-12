// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ISovWrapper.sol";
import "../interfaces/ISmartPool.sol";
import "../interfaces/IMintableERC20.sol";

contract PoolRouter {
    using SafeMath for uint256;

    uint256 public constant LIQ_FEE_DECIMALS = 1000000; // 6 decimals
    uint256 public constant PROTOCOL_FEE_DECIMALS = 100000; // 5 decimals

    uint256 public protocolFee = 99950; // 100% - 0.050%

    ISmartPool public smartPool;
    ISovWrapper public wrappingContract;
    IMintableERC20 public sovToken;

    address public reignDao;
    address public treasury;

    constructor(
        address _smartPool,
        address _wrappingContract,
        address _treasury,
        address _sovToken,
        uint256 _protocolFee
    ) {
        smartPool = ISmartPool(_smartPool);
        wrappingContract = ISovWrapper(_wrappingContract);
        sovToken = IMintableERC20(_sovToken);
        treasury = _treasury;
        protocolFee = _protocolFee;
    }

    /**
        This methods performs the following actions:
            1. pull token for user
            2. joinswap into balancer pool, recieving lp
            3. stake lp tokens into Wrapping Contrat which mints SOV to User
    */
    function deposit(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        uint256 liquidationFee
    ) public {
        // pull underlying token here
        IERC20(tokenIn).transferFrom(msg.sender, address(this), tokenAmountIn);

        //take fee before swap
        uint256 amountMinusFee =
            tokenAmountIn.mul(protocolFee).div(PROTOCOL_FEE_DECIMALS);
        uint256 poolAmountMinusFee =
            minPoolAmountOut.mul(protocolFee).div(PROTOCOL_FEE_DECIMALS);

        IERC20(tokenIn).approve(address(smartPool), amountMinusFee);

        // swap underlying token for LP
        smartPool.joinswapExternAmountIn(
            tokenIn,
            amountMinusFee,
            poolAmountMinusFee
        );

        // deposit LP for sender
        uint256 balance = smartPool.balanceOf(address(this));
        smartPool.approve(address(wrappingContract), balance);
        wrappingContract.deposit(msg.sender, balance, liquidationFee);

        // mint SOV
        sovToken.mint(msg.sender, balance);
    }

    /**
        This methods performs the following actions:
            1. pull tokens for user
            2. join into balancer pool, recieving lp
            3. stake lp tokens into Wrapping Contrat which mints SOV to User
    */
    function depositAll(
        uint256[] memory maxTokensAmountIn,
        uint256 poolAmountOut,
        uint256 liquidationFee
    ) public {
        address[] memory tokens = getPoolTokens();
        uint256[] memory amountsIn =
            getAmountsTokensIn(poolAmountOut, maxTokensAmountIn);

        uint256[] memory amountsInMinusFee = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenIn = tokens[i];
            uint256 tokenAmountIn = amountsIn[i];
            // pull underlying token here
            IERC20(tokenIn).transferFrom(
                msg.sender,
                address(this),
                tokenAmountIn
            );

            //take fee before swap
            uint256 amountMinusFee =
                tokenAmountIn.mul(protocolFee).div(PROTOCOL_FEE_DECIMALS);

            amountsInMinusFee[i] = amountMinusFee;

            IERC20(tokenIn).approve(address(smartPool), amountMinusFee);
        }

        uint256 poolAmountMinusFee =
            poolAmountOut.mul(protocolFee).div(PROTOCOL_FEE_DECIMALS);

        // swap underlying token for LP
        smartPool.joinPool(poolAmountMinusFee, amountsInMinusFee);

        // deposit LP for sender
        uint256 balance = smartPool.balanceOf(address(this));
        smartPool.approve(address(wrappingContract), balance);
        wrappingContract.deposit(msg.sender, balance, liquidationFee);

        // mint SOV
        sovToken.mint(msg.sender, balance);
    }

    /**
        This methods performs the following actions:
            1. burn SOV from user and unstake lp
            2. exitswap lp into one of the underlyings
            3. send the underlying to the User
    */
    function withdraw(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) public {
        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        //recieve LP from sender to here
        wrappingContract.withdraw(msg.sender, poolAmountIn);

        //get balance before exitswap
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        //swaps LP for underlying
        smartPool.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        //get balance after exitswap
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        //take fee before transfer out
        uint256 amountMinusFee =
            (balanceAfter.sub(balanceBefore)).mul(protocolFee).div(
                PROTOCOL_FEE_DECIMALS
            );

        IERC20(tokenOut).transfer(msg.sender, amountMinusFee);
    }

    /**
        This methods performs the following actions:
            1. burn SOV from user and unstake lp
            2. exitswap lp into all of the underlyings
            3. send the underlyings to the User
    */
    function withdrawAll(uint256 poolAmountIn, uint256[] memory minAmountsOut)
        public
    {
        address[] memory tokens = getPoolTokens();

        uint256[] memory balancesBefore = new uint256[](tokens.length);

        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        //recieve LP from sender to here
        wrappingContract.withdraw(msg.sender, poolAmountIn);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];

            //get balance before exitswap
            balancesBefore[i] = IERC20(tokenOut).balanceOf(address(this));
        }

        //swaps LP for underlying
        smartPool.exitPool(poolAmountIn, minAmountsOut);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];

            //get balance after exitswap
            uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

            //take fee before transfer out
            uint256 amountMinusFee =
                (balanceAfter.sub(balancesBefore[i])).mul(protocolFee).div(
                    100000
                );

            IERC20(tokenOut).transfer(msg.sender, amountMinusFee);
        }
    }

    /**
        This methods performs the following actions:
            1. burn SOV from caller and unstake lp of liquidatedUser
            2. exitswap lp into one of the underlyings
            3. send the underlying to the caller
            4. transfer fee from caller to liquidatedUser
    */
    function liquidate(
        address liquidatedUser,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) public {
        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        // recieve LP to here
        wrappingContract.liquidate(msg.sender, liquidatedUser, poolAmountIn);

        //get balance before exitswap
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        //swaps LP for underlying
        smartPool.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        //get balance after exitswap
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        //take protocol fee before transfer
        uint256 amountMinusFee =
            (balanceAfter.sub(balanceBefore)).mul(protocolFee).div(100000);

        IERC20(tokenOut).transfer(msg.sender, amountMinusFee);

        // liquidation fee is paid in tokenOut tokens, it is set by lpOwner at deposit
        uint256 liquidationFeeAmount =
            (balanceAfter.sub(balanceBefore))
                .mul(wrappingContract.liquidationFee(liquidatedUser))
                .div(LIQ_FEE_DECIMALS);

        require(
            IERC20(tokenOut).allowance(msg.sender, address(this)) >=
                liquidationFeeAmount,
            "Insuffiecient allowance for liquidation Fee"
        );

        // transfer liquidation fee from liquidator to original owner
        IERC20(tokenOut).transferFrom(
            msg.sender,
            liquidatedUser,
            liquidationFeeAmount
        );
    }

    // transfer the entire fees collected in this contract to DAO treasury
    function collectFeesToDAO(address token) public {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, balance);
    }

    /**
        VIEWS
     */

    // gets all tokens currently in the pool
    function getPoolTokens() public view returns (address[] memory) {
        BPool bPool = smartPool.bPool();
        return bPool.getCurrentTokens();
    }

    // gets all tokens currently in the pool
    function getTokenWeights() public view returns (uint256[] memory) {
        address[] memory tokens = getPoolTokens();
        uint256[] memory weights = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            weights[i] = smartPool.getDenormalizedWeight(tokens[i]);
        }
        return weights;
    }

    // NOTE: The follwing lines are not covered by unit test, they just forwards the data from SmartPoolManager

    // gets current LP exchange rate for all
    function getAmountsTokensIn(
        uint256 poolAmountOut,
        uint256[] memory maxAmountsIn
    ) public view returns (uint256[] memory) {
        address manager = smartPool.getSmartPoolManagerVersion();
        return
            SmartPoolManager(manager).joinPool(
                ConfigurableRightsPool(address(this)),
                smartPool.bPool(),
                poolAmountOut,
                maxAmountsIn
            );
    }

    // gets current LP exchange rate for single Asset
    function getAmountsTokensInSingle(
        address tokenIn,
        uint256 amountTokenIn,
        uint256 minPoolAmountOut
    ) public view returns (uint256) {
        address manager = smartPool.getSmartPoolManagerVersion();
        return
            SmartPoolManager(manager).joinswapExternAmountIn(
                ConfigurableRightsPool(address(this)),
                smartPool.bPool(),
                tokenIn,
                amountTokenIn,
                minPoolAmountOut
            );
    }

    // gets current LP exchange rate for all
    function getAmountPoolOut(
        uint256 poolAmountIn,
        uint256[] memory minAmountsOut
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        address manager = smartPool.getSmartPoolManagerVersion();
        return
            SmartPoolManager(manager).exitPool(
                ConfigurableRightsPool(address(this)),
                smartPool.bPool(),
                poolAmountIn,
                minAmountsOut
            );
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ISovWrapper {
    function deposit(
        address user,
        uint256 amount,
        uint256 liquidationPrice
    ) external;

    function withdraw(address lpOwner, uint256 amount) external;

    function liquidate(
        address liquidator,
        address from,
        uint256 amount
    ) external;

    function liquidationFee(address) external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function epoch1Start() external view returns (uint256);

    function getEpochUserBalance(address user, uint128 epoch)
        external
        view
        returns (uint256);

    function getEpochPoolSize(uint128 epoch) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract BalancerOwnable {
    function setController(address controller) external virtual;
}

abstract contract AbstractPool is BalancerOwnable {
    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;
}

abstract contract ConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint256[] tokenBalances;
        uint256[] tokenWeights;
        uint256 swapFee;
    }

    struct CrpParams {
        uint256 initialSupply;
        uint256 minimumWeightChangeBlockPeriod;
        uint256 addTokenTimeLockInBlocks;
    }

    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriod,
        uint256 addTokenTimeLockInBlocks
    ) external virtual;

    function createPool(uint256 initialSupply) external virtual;

    function setCap(uint256 newCap) external virtual;

    function updateWeight(address token, uint256 newWeight) external virtual;

    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external virtual;

    function commitAddToken(
        address token,
        uint256 balance,
        uint256 denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function removeToken(address token) external virtual;

    function whitelistLiquidityProvider(address provider) external virtual;

    function removeWhitelistedLiquidityProvider(address provider)
        external
        virtual;

    function bPool() external view virtual returns (BPool);
}

abstract contract BPool is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens()
        external
        view
        virtual
        returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint256);
}

abstract contract ISmartPool is BalancerOwnable {
    function updateWeightsGradually(
        uint256[] memory,
        uint256,
        uint256
    ) external virtual;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external virtual returns (uint256);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external virtual returns (uint256);

    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool);

    function balanceOf(address owner) external view virtual returns (uint256);

    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function getDenormalizedWeight(address token)
        external
        view
        virtual
        returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        virtual;

    function bPool() external view virtual returns (BPool);

    function applyAddToken() external virtual;

    function getSmartPoolManagerVersion()
        external
        view
        virtual
        returns (address);
}

abstract contract SmartPoolManager {
    function joinPool(
        ConfigurableRightsPool,
        BPool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external view virtual returns (uint256[] memory actualAmountsIn);

    function exitPool(
        ConfigurableRightsPool self,
        BPool bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
        external
        view
        virtual
        returns (
            uint256 exitFee,
            uint256 pAiAfterExitFee,
            uint256[] memory actualAmountsOut
        );

    function joinswapExternAmountIn(
        ConfigurableRightsPool self,
        BPool bPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external view virtual returns (uint256 poolAmountOut);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 value) external returns (bool);

    function burn(address from, uint256 value) external returns (bool);
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}