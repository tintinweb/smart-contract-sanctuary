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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// File: contracts/RoutingManagement.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;



contract RoutingManagement is Ownable {
    /**
    * @dev Struct of trading route
    * @param name Name of trading route.
    * @param enable The flag of trading route to check is trading route enable.
    * @param route The address of trading route.
    */
    struct Route {
      string name;
      bool enable;
      INarwhalTradingRoute route;
    }

    event AddedTradingRoute(
        address indexed addedBy,
        string name,
        INarwhalTradingRoute indexed routingAddress,
        uint256 indexed index
    );

    event EnabledTradingRoute(
        address indexed enabledBy,
        string name,
        INarwhalTradingRoute indexed routingAddress,
        uint256 indexed index
    );

    event DisabledTradingRoute(
        address indexed disabledBy,
        string name,
        INarwhalTradingRoute indexed routingAddress,
        uint256 indexed index
    );

    Route[] public tradingRoutes; // list of trading routes

    modifier onlyTradingRouteEnabled(uint _index) {
        require(tradingRoutes[_index].enable == true, "This trading route is disabled");
        _;
    }

    modifier onlyTradingRouteDisabled(uint _index) {
        require(tradingRoutes[_index].enable == false, "This trading route is enabled");
        _;
    }

    /**
    * @dev Function for adding new trading route
    * @param _name Name of trading route.
    * @param _routingAddress The address of trading route.
    * @return length of trading routes.
    */
    function addTradingRoute(
        string memory _name,
        INarwhalTradingRoute _routingAddress
    )
      public
      onlyOwner
    {
        tradingRoutes.push(Route({
            name: _name,
            enable: true,
            route: _routingAddress
        }));
        emit AddedTradingRoute(msg.sender, _name, _routingAddress, tradingRoutes.length - 1);
    }

    /**
    * @dev Function for disable trading route by index
    * @param _index The uint256 of trading route index.
    * @return length of trading routes.
    */
    function disableTradingRoute(
        uint256 _index
    )
        public
        onlyOwner
        onlyTradingRouteEnabled(_index)
    {
        tradingRoutes[_index].enable = false;
        emit DisabledTradingRoute(msg.sender, tradingRoutes[_index].name, tradingRoutes[_index].route, _index);
    }

    /**
    * @dev Function for enale trading route by index
    * @param _index The uint256 of trading route index.
    * @return length of trading routes.
    */
    function enableTradingRoute(
        uint256 _index
    )
        public
        onlyOwner
        onlyTradingRouteDisabled(_index)
    {
        tradingRoutes[_index].enable = true;
        emit EnabledTradingRoute(msg.sender, tradingRoutes[_index].name, tradingRoutes[_index].route, _index);
    }

    /**
    * @dev Function for get amount of trading route
    * @return Amount of trading routes.
    */
    function allRoutesLength() public view returns (uint256) {
        return tradingRoutes.length;
    }

    /**
    * @dev Function for get enable status of trading route
    * @param _index The uint256 of trading route index.
    * @return enable status of trading route.
    */
    function isTradingRouteEnabled(uint256 _index) public view returns (bool) {
        return tradingRoutes[_index].enable;
    }
}

// File: contracts/Partnership.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;




/*
* Fee collection by partner reference
*/
contract Partnership is RoutingManagement {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
    * @dev Platform Fee collection
    * @param partnerIndex Partner or Wallet provider that integrate to Warden
    * @param token Token address
    * @param wallet Partner or Wallet provider wallet
    * @param amount Fee amount
    */
    event CollectFee(
      uint256 indexed partnerIndex,
      IERC20   indexed token,
      address indexed wallet,
      uint256         amount
    );

    /**
    * @dev Updating partner info
    * @param index Partner index
    * @param wallet Partner wallet
    * @param fee Fee in bps
    * @param name partner name
    */
    event UpdatePartner(
      uint256 indexed index,
      address indexed wallet,
      uint16 fee,
      bytes16 name
    );

    struct Partner {
      address wallet;       // To receive fee on the Warden Swap network
      uint16 fee;           // fee in bps
      bytes16 name;         // Partner reference
    }

    IERC20 public constant etherERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(uint256 => Partner) public partners;

    constructor() public {
        Partner memory partner = Partner(msg.sender, 10, "NAR"); // 0.1%
        partners[0] = partner;
        emit UpdatePartner(0, msg.sender, 10, "NAR");
    }

    function updatePartner(uint256 index, address wallet, uint16 fee, bytes16 name)
        external
        onlyOwner
    {
        require(fee <= 100, "fee: no more than 1%");
        Partner memory partner = Partner(wallet, fee, name);
        partners[index] = partner;
        emit UpdatePartner(index, wallet, fee, name);
    }

    function _amountWithFee(uint256 amount, uint256 partnerIndex)
        internal
        view
        returns(uint256 remainingAmount)
    {
        Partner storage partner = partners[partnerIndex];
        if (partner.wallet == 0x0000000000000000000000000000000000000000) {
          partner = partners[0];
        }
        if (partner.fee == 0) {
            return amount;
        }
        uint256 fee = amount.mul(partner.fee).div(10000);
        return amount.sub(fee);
    }

    function _collectFee(uint256 partnerIndex, uint256 amount, IERC20 token)
        internal
        returns(uint256 remainingAmount)
    {
        Partner storage partner = partners[partnerIndex];
        if (partner.wallet == 0x0000000000000000000000000000000000000000) {
            partnerIndex = 0;
            partner = partners[0];
        }
        if (partner.fee == 0) {
            return amount;
        }
        uint256 fee = amount.mul(partner.fee).div(10000);
        require(fee < amount, "fee exceeds return amount!");
        if (etherERC20 == token) {
            (bool success, ) = partner.wallet.call.value(fee)(""); // Send back ether to sender
            require(success, "Transfer fee of ether failed.");
        } else {
            token.safeTransfer(partner.wallet, fee);
        }
        emit CollectFee(partnerIndex, token, partner.wallet, fee);

        return amount.sub(fee);
    }
}

// File: contracts/WhitelistFeeOnTransfer.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;




/*
* Whitelist of Fee On Transfer Token
*/
contract WhitelistFeeOnTransfer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event AddFeeOnTransferToken(IERC20 indexed token);
    event DisabledFeeOnTransferToken(IERC20 indexed token);

    mapping(address => bool) public FeeOnTransferToken;

    function addFeeOnTransferToken(
        IERC20  token
    )
        public
        onlyOwner
    {
        FeeOnTransferToken[address(token)] = true;
        emit AddFeeOnTransferToken(token);
    }

    function disableFeeOnTransferToken(
        IERC20  token
    )
        public
        onlyOwner
    {
        FeeOnTransferToken[address(token)] = false;
        emit DisabledFeeOnTransferToken(token);
    }

    function isFeeOnTransferToken(IERC20 token)
        public
        view
        returns (bool)
    {
        return FeeOnTransferToken[address(token)];
    }
}

// File: contracts/NarwhalSwap.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;




contract NarwhalTokenPriviledge is Partnership {
    uint256 public eligibleAmount = 10 ether; // 10 NAR
    IERC20 public eligibleToken;

    event UpdateEligibleToken(IERC20 indexed token);
    event UpdateEligibleAmount(uint256 amount);

    function updateEligibleToken(
        IERC20 _token
    )
        public
        onlyOwner
    {
        eligibleToken = _token;
        emit UpdateEligibleToken(_token);
    }

    function updateEligibleAmount(
        uint256 _amount
    )
        public
        onlyOwner
    {
        eligibleAmount = _amount;
        emit UpdateEligibleAmount(_amount);
    }

    function isEligibleForFreeTrade(address user)
        public
        view
        returns (bool)
    {
        if (address(eligibleToken) == 0x0000000000000000000000000000000000000000) {
            return false;
        }

        return eligibleToken.balanceOf(user) >= eligibleAmount;
    }

}

contract NarwhalSwap is NarwhalTokenPriviledge, WhitelistFeeOnTransfer, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
    * @dev when new trade occure (and success), this event will be boardcast.
    * @param srcAsset Source token
    * @param srcAmount amount of source token
    * @param destAsset Destination token
    * @param destAmount amount of destination token
    * @param trader user address
    */
    event Trade(
        address indexed srcAsset, // Source
        uint256         srcAmount,
        address indexed destAsset, // Destination
        uint256         destAmount,
        address indexed trader // User
    );

    event DestAmount(uint256 _destAmount, uint256 _order);

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between Ether to token by tradingRouteIndex
    * @param tradingRouteIndex index of trading route
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @return amount of actual destination tokens
    */
    function _tradeEtherToToken(
        uint256 tradingRouteIndex,
        uint256 srcAmount,
        IERC20 dest
    )
        private
        returns(uint256)
    {
        // Load trading route
        INarwhalTradingRoute tradingRoute = tradingRoutes[tradingRouteIndex].route;
        // Trade to route
        uint256 destAmount = tradingRoute.trade.value(srcAmount)(
            etherERC20,
            dest,
            srcAmount
        );
        return destAmount;
    }

    // Receive ETH in case of trade Token -> ETH, will get ETH back from trading route
    function () external payable {}

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between token to Ether by tradingRouteIndex
    * @param tradingRouteIndex index of trading route
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @return amount of actual destination tokens
    */
    function _tradeTokenToEther(
        uint256 tradingRouteIndex,
        IERC20 src,
        uint256 srcAmount
    )
        private
        returns(uint256)
    {
        // Load trading route
        INarwhalTradingRoute tradingRoute = tradingRoutes[tradingRouteIndex].route;
        // Approve to TradingRoute
        src.safeApprove(address(tradingRoute), srcAmount);
        // Trande to route
        uint256 destAmount = tradingRoute.trade(
            src,
            etherERC20,
            srcAmount
        );
        return destAmount;
    }

    /**
    * @dev makes a trade between token to token by tradingRouteIndex
    * @param tradingRouteIndex index of trading route
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @return amount of actual destination tokens
    */
    function _tradeTokenToToken(
        uint256 tradingRouteIndex,
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest
    )
        private
        returns(uint256)
    {
        // Load trading route
        INarwhalTradingRoute tradingRoute = tradingRoutes[tradingRouteIndex].route;
        // Approve to TradingRoute
        src.safeApprove(address(tradingRoute), srcAmount);
        // Trande to route
        uint256 destAmount = tradingRoute.trade(
            src,
            dest,
            srcAmount
        );
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token by tradingRouteIndex
    * Ex1: trade 0.5 ETH -> DAI
    * 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    * Ex2: trade 30 DAI -> ETH
    * 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    * @param _tradingRouteIndex index of trading route
    * @param _src Source token
    * @param _srcAmount amount of source tokens
    * @param _dest Destination token
    * @return amount of actual destination tokens
    */
    function _trade(
        uint256             _tradingRouteIndex,
        IERC20              _src,
        uint256             _srcAmount,
        IERC20              _dest
    )
        private
        onlyTradingRouteEnabled(_tradingRouteIndex)
        returns(uint256)
    {
        // Destination amount
        uint256 destAmount;
        // Record src/dest asset for later consistency check.
        uint256 srcAmountBefore;
        uint256 destAmountBefore;

        if (etherERC20 == _src) { // Source
            srcAmountBefore = address(this).balance;
        } else {
            srcAmountBefore = _src.balanceOf(address(this));
        }
        if (etherERC20 == _dest) { // Dest
            destAmountBefore = address(this).balance;
        } else {
            destAmountBefore = _dest.balanceOf(address(this));
        }
        if (etherERC20 == _src) { // Trade ETH -> Token
            destAmount = _tradeEtherToToken(_tradingRouteIndex, _srcAmount, _dest);
        } else if (etherERC20 == _dest) { // Trade Token -> ETH
            destAmount = _tradeTokenToEther(_tradingRouteIndex, _src, _srcAmount);
        } else { // Trade Token -> Token
            destAmount = _tradeTokenToToken(_tradingRouteIndex, _src, _srcAmount, _dest);
        }

        // Recheck if src/dest amount correct
        if (etherERC20 == _src) { // Source
            require(address(this).balance == srcAmountBefore.sub(_srcAmount), "source(ETH) amount mismatch after trade");
        } else {
            require(_src.balanceOf(address(this)) == srcAmountBefore.sub(_srcAmount), "source amount mismatch after trade");
        }
        if (etherERC20 == _dest) { // Dest
            require(address(this).balance == destAmountBefore.add(destAmount), "destination(ETH) amount mismatch after trade");
        } else {
            require(_dest.balanceOf(address(this)) <= destAmountBefore.add(destAmount), "destination amount mismatch after trade");
        }
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade between src and dest token by tradingRouteIndex
    * Ex1: trade 0.5 ETH -> DAI
    * 0, "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "500000000000000000", "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "21003850000000000000"
    * Ex2: trade 30 DAI -> ETH
    * 0, "0xd3c64BbA75859Eb808ACE6F2A6048ecdb2d70817", "30000000000000000000", "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", "740825000000000000"
    * @param tradingRouteIndex index of trading route
    * @param src Source token
    * @param srcAmount amount of source tokens
    * @param dest Destination token
    * @param minDestAmount minimun destination amount
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */
    function trade(
        uint256   tradingRouteIndex,
        IERC20    src,
        uint256   srcAmount,
        IERC20    dest,
        uint256   minDestAmount,
        uint256   partnerIndex
    )
        external
        payable
        nonReentrant
        returns(uint256)
    {
        uint256 destAmount;
        // Prepare source's asset
        uint256 _before;
        uint256 _beforeSrc;
        uint256 _afterSrc;
        if (etherERC20 != src) {
            _beforeSrc = src.balanceOf(address(this));
            src.safeTransferFrom(msg.sender, address(this), srcAmount); // Transfer token to this address
            _afterSrc = src.balanceOf(address(this));
            srcAmount = _afterSrc.sub(_beforeSrc);
        }

        if(etherERC20 != dest){
          _before = dest.balanceOf(address(this));
        }

        // Trade to route
        destAmount = _trade(tradingRouteIndex, src, srcAmount, dest);
        if (!isEligibleForFreeTrade(msg.sender)) {
            destAmount = _collectFee(partnerIndex, destAmount, dest);
        }

        // Throw exception if destination amount doesn't meet user requirement.
        require(destAmount >= minDestAmount, "destination amount is too low.");
        if (etherERC20 == dest) {
            (bool success, ) = msg.sender.call.value(destAmount)(""); // Send back ether to sender
            require(success, "Transfer ether back to caller failed.");
        } else { // Send back token to sender

            uint256 _after = dest.balanceOf(address(this));
            uint256 _current = _after.sub(_before);

            if(isFeeOnTransferToken(dest) || isFeeOnTransferToken(src)){
              destAmount = _current;
              dest.safeTransfer(msg.sender, destAmount);
            }else{
              dest.safeTransfer(msg.sender, destAmount);
            }
        }

        emit Trade(address(src), srcAmount, address(dest), destAmount, msg.sender);
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev makes a trade with split volumes to multiple-routes ex. UNI -> ETH (5%, 15% and 80%)
    * @param routes Trading paths
    * @param src Source token
    * @param srcAmounts amount of source tokens
    * @param dest Destination token
    * @param minDestAmount minimun destination amount
    * @param partnerIndex index of partnership for revenue sharing
    * @return amount of actual destination tokens
    */

    function splitTrades(
        uint256[] calldata routes,
        IERC20    src,
        uint256   totalSrcAmount,
        uint256[] calldata srcAmounts,
        IERC20    dest,
        uint256   minDestAmount,
        uint256   partnerIndex
    )
        external
        payable
        nonReentrant
        returns(uint256)
    {
        require(routes.length > 0, "routes can not be empty");
        require(routes.length == srcAmounts.length, "routes and srcAmounts lengths mismatch");
        uint256 destAmount = 0;

        // Prepare source's asset
        uint256 _before;
        uint256 _currentTotal;


        if (etherERC20 != src) {
            uint256 _beforeSrc = src.balanceOf(address(this));
            src.safeTransferFrom(msg.sender, address(this), totalSrcAmount); // Transfer token to this address
            uint256 _afterSrc = src.balanceOf(address(this));
            _currentTotal = _afterSrc.sub(_beforeSrc);
        }else{
          _currentTotal = totalSrcAmount;
        }

        uint256[] memory splitAmounts = new uint256[](srcAmounts.length);

        for (uint k = 0; k < srcAmounts.length; k++) {
          uint256 x = srcAmounts[k];
          splitAmounts[k] = x.mul(_currentTotal).div(totalSrcAmount);
        }

        if(etherERC20 != dest){
          _before = dest.balanceOf(address(this));
        }

        // Trade with routes
        for (uint i = 0; i < routes.length; i++) {
            uint256 tradingRouteIndex = routes[i];
            uint256 amount = splitAmounts[i];
            IERC20 _src = src;
            IERC20 _dest = dest;
            destAmount = destAmount.add(_trade(tradingRouteIndex, _src, amount, _dest));
        }

        // Collect fee
        if (!isEligibleForFreeTrade(msg.sender)) {
            destAmount = _collectFee(partnerIndex, destAmount, dest);
        }

        // Throw exception if destination amount doesn't meet user requirement.
        require(destAmount >= minDestAmount, "destination amount is too low.");
        if (etherERC20 == dest) {
            (bool success, ) = msg.sender.call.value(destAmount)(""); // Send back ether to sender
            require(success, "Transfer ether back to caller failed.");
        } else { // Send back token to sender
            uint256 _after = dest.balanceOf(address(this));
            uint256 _current = _after.sub(_before);

            if(isFeeOnTransferToken(dest) || isFeeOnTransferToken(src)){
              destAmount = _current;
              dest.safeTransfer(msg.sender, destAmount);
            }else{
              dest.safeTransfer(msg.sender, destAmount);
            }

        }

        emit Trade(address(src), totalSrcAmount, address(dest), destAmount, msg.sender);
        return destAmount;
    }

    /**
    * @notice use token address 0xeee...eee for ether
    * @dev get amount of destination token for given source token amount
    * @param tradingRouteIndex index of trading route
    * @param src Source token
    * @param dest Destination token
    * @param srcAmount amount of source tokens
    * @return amount of actual destination tokens
    */
    function getDestinationReturnAmount(
        uint256 tradingRouteIndex,
        IERC20  src,
        IERC20  dest,
        uint256 srcAmount,
        uint256 partnerIndex
    )
        external
        view
        returns(uint256)
    {
        // Load trading route
        INarwhalTradingRoute tradingRoute = tradingRoutes[tradingRouteIndex].route;
        uint256 destAmount = tradingRoute.getDestinationReturnAmount(src, dest, srcAmount);
        return _amountWithFee(destAmount, partnerIndex);
    }

    function getDestinationReturnAmountForSplitTrades(
        uint256[] calldata routes,
        IERC20    src,
        uint256[] calldata srcAmounts,
        IERC20    dest,
        uint256   partnerIndex
    )
        external
        view
        returns(uint256)
    {
        require(routes.length > 0, "routes can not be empty");
        require(routes.length == srcAmounts.length, "routes and srcAmounts lengths mismatch");
        uint256 destAmount = 0;

        for (uint i = 0; i < routes.length; i++) {
            uint256 tradingRouteIndex = routes[i];
            uint256 amount = srcAmounts[i];
            // Load trading route
            INarwhalTradingRoute tradingRoute = tradingRoutes[tradingRouteIndex].route;
            destAmount = destAmount.add(tradingRoute.getDestinationReturnAmount(src, dest, amount));
        }
        return _amountWithFee(destAmount, partnerIndex);
    }

    // In case of expected and unexpected event that have some token amounts remain in this contract, owner can call to collect them.
    function collectRemainingToken(
        IERC20  token,
        uint256 amount
    )
      public
      onlyOwner
    {
        token.safeTransfer(msg.sender, amount);
    }

    // In case of expected and unexpected event that have some ether amounts remain in this contract, owner can call to collect them.
    function collectRemainingEther(
        uint256 amount
    )
      public
      onlyOwner
    {
        (bool success, ) = msg.sender.call.value(amount)(""); // Send back ether to sender
        require(success, "Transfer ether back to caller failed.");
    }
}