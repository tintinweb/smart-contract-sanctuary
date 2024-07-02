/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-07
*/

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return div(a, b, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.0;




/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/interfaces/INarwhalTradingRoute.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.5.17;


/**
 * @title Warden Trading Route
 * @dev The Warden trading route interface has an standard functions and event
 * for other smart contract to implement to join Warden Swap as Market Maker.
 */
interface INarwhalTradingRoute {
    /**
    * @dev when new trade occure (and success), this event will be boardcast.
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest   Destination token
    * @return _destAmount: amount of actual destination tokens
    */
    event Trade(
        IERC20 indexed _src,
        uint256 _srcAmount,
        IERC20 indexed _dest,
        uint256 _destAmount
    );

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token
    * @param _src Source token
    * @param _dest   Destination token
    * @param _srcAmount amount of source tokens
    * @return _destAmount: amount of actual destination tokens
    */
    function trade(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        external
        payable
        returns(uint256 _destAmount);

    /**
    * @dev provide destinationm token amount for given source amount
    * @param _src Source token
    * @param _dest Destination token
    * @param _srcAmount Amount of source tokens
    * @return _destAmount: amount of expected destination tokens
    */
    function getDestinationReturnAmount(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        external
        view
        returns(uint256 _destAmount);

    /**
    * @dev provide source token amount for given destination amount
    * @param _src Source token
    * @param _dest Destination token
    * @param _destAmount Amount of destination tokens
    * @return _srcAmount: amount of expected source tokens
    */
    // function getSourceReturnAmount(
    //     IERC20 _src,
    //     IERC20 _dest,
    //     uint256 _destAmount
    // )
    //     external
    //     view
    //     returns(uint256 _srcAmount);
}

// File: contracts/interfaces/IStableSwap.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;


interface IStableSwap {
    /// EVENTS
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event TokenExchange(
        address indexed buyer,
        uint256 soldId,
        uint256 tokensSold,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

    event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 A, uint256 timestamp);

    event NewFee(uint256 fee, uint256 adminFee);

    event CollectProtocolFee(address token, uint256 amount);

    event FeeControllerChanged(address newController);

    event FeeDistributorChanged(address newController);

    // pool data view functions
    function getLpToken() external view returns (IERC20 lpToken);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokens() external view returns (IERC20[] memory);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getTokenBalances() external view returns (uint256[] memory);

    function getNumberOfTokens() external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
        external
        view
        returns (uint256 availableTokenAmount);

    function getAdminBalances() external view returns (uint256[] memory adminBalances);

    function getAdminBalance(uint8 index) external view returns (uint256);

    // state modifying functions
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function withdrawAdminFee() external;
}

// File: contracts/interfaces/IStableSwapRouter.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;


interface IStableSwapRouter {

    function calculateSwapFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateSwapToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function swapToBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapFromBase(
        IStableSwap pool,
        IStableSwap basePool,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

}

// File: contracts/routes/NarwhalSolarMultichainRouter.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;







contract NarwhalSolarMultichainRouter is INarwhalTradingRoute, WhitelistedRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant amountOutMin = 1;
    uint256 public constant deadline = 2 ** 256 - 1;

    IStableSwapRouter public constant stablePool = IStableSwapRouter(0x6ebfD1BD4f3246856e008c9F6f0Da0A4b0bfF8dc);
    IStableSwap public constant pool = IStableSwap(	0xF8c6475CdD237D597539914b228f6F63EBb2B7dB);
    IStableSwap public constant basePool = IStableSwap(0x91416C884190122F6D8911dE1Ef401cf2ADEC627);
    IERC20 public constant usdcMulti = IERC20(0x818ec0A7Fe18Ff94269904fCED6AE3DaE6d6dC0b); // 0
    IERC20 public constant busdMulti = IERC20(0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F); // 1
    IERC20 public constant usdtMulti = IERC20(0xeFAeeE334F0Fd1712f9a8cc375f427D9Cdd40d73); // 2

    IERC20 public constant usdc = IERC20(0x8f552a71EFE5eeFc207Bf75485b356A0b3f01eC9); // 0
    IERC20 public constant dai = IERC20(0xc234A67a4F840E61adE794be47de455361b52413); // 1
    IERC20 public constant usdt = IERC20(0x8e70cD5B4Ff3f62659049e74b6649c6603A0E594); // 2

    function trade(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        public
        payable
        onlyWhitelisted
        nonReentrant
        returns(uint256 _destAmount)
    {
        (uint256 i, uint256 j) = getTokenIndexes(_src, _dest);
        (bool isMultichain, bool toBase) = isMultichainToken(_src, _dest);

        require(isMultichain, "Source or Destination must be MultichainToken");

        uint256 balanceBefore = _dest.balanceOf(address(this));
        _src.safeTransferFrom(msg.sender, address(this), _srcAmount);
        _src.safeApprove(address(stablePool), _srcAmount);

        if(toBase){
          stablePool.swapToBase(
            pool,
            basePool,
            uint8(i),
            uint8(j),
            _srcAmount,
            amountOutMin,
            deadline
          );
        }else{
          stablePool.swapFromBase(
            pool,
            basePool,
            uint8(i),
            uint8(j),
            _srcAmount,
            amountOutMin,
            deadline
          );
        }

        uint256 balanceAfter = _dest.balanceOf(address(this));
        _destAmount = balanceAfter.sub(balanceBefore);
        _dest.safeTransfer(msg.sender, _destAmount);
        emit Trade(_src, _srcAmount, _dest, _destAmount);
    }

    function getDestinationReturnAmount(
        IERC20 _src,
        IERC20 _dest,
        uint256 _srcAmount
    )
        public
        view
        returns(uint256 _destAmount)
    {
        (uint256 i, uint256 j) = getTokenIndexes(_src, _dest);
        (bool isMultichain, bool toBase) = isMultichainToken(_src, _dest);
        require(isMultichain, "Source or Destination must be MultichainToken");

        if(toBase){
          return stablePool.calculateSwapToBase(
            pool,
            basePool,
            uint8(i),
            uint8(j),
            _srcAmount
          );
        }

        return stablePool.calculateSwapFromBase(
          pool,
          basePool,
          uint8(i),
          uint8(j),
          _srcAmount
        );
    }

    function isMultichainToken(
        IERC20 _src,
        IERC20 _dest
    )
        public
        pure
        returns(bool isMulti, bool toBase)
    {
      if(_src == usdcMulti || _src == busdMulti || _src == usdtMulti){
        toBase = true;
        isMulti = true;
      }

      if(_dest == usdcMulti || _dest == busdMulti || _dest == usdtMulti){
        toBase = false;
        isMulti = true;
      }
    }

    function getTokenIndexes(
        IERC20 _src,
        IERC20 _dest
    )
        public
        pure
        returns(uint256 i, uint256 j)
    {
        require(_src != _dest, "NarCurveRouter: Destination token can not be source token");

        i = uint256(-1);
        j = uint256(-1);
        i = _src == usdcMulti ? 0 : i;
        i = _src == busdMulti ? 1 : i;
        i = _src == usdtMulti ? 2 : i;
        i = _src == usdc ? 0 : i;
        i = _src == dai ? 1 : i;
        i = _src == usdt ? 2 : i;

        j = _dest == usdcMulti ? 0 : j;
        j = _dest == busdMulti ? 1 : j;
        j = _dest == usdtMulti ? 2 : j;
        j = _dest == usdc ? 0 : j;
        j = _dest == dai ? 1 : j;
        j = _dest == usdt ? 2 : j;
        require(i != uint256(-1) && j != uint256(-1), "NarCurveRouter: Tokens not supported!");
    }
}