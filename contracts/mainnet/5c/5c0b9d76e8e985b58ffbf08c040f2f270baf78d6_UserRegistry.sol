/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Claimer.sol

pragma solidity 0.6.10;




/**
 * @title Reclaimer
 * @author Protofire
 * @dev Allows owner to claim ERC20 tokens ot ETH sent to this contract.
 */
abstract contract Claimer is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev send all token balance of an arbitrary erc20 token
     * in the contract to another address
     * @param token token to reclaim
     * @param _to address to send eth balance to
     */
    function claimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    /**
     * @dev send all eth balance in the contract to another address
     * @param _to address to send eth balance to
     */
    function claimEther(address payable _to) external onlyOwner {
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}

// File: contracts/Registry.sol

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;


abstract contract Registry is Claimer {
    struct AttributeData {
        uint256 value;
        address updatedBy;
        uint256 timestamp;
    }

    mapping(address => mapping(bytes32 => AttributeData)) public attributes;

    event SetAttribute(
        address indexed who,
        bytes32 attribute,
        uint256 value,
        address indexed updatedBy
    );

    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public onlyOwner {
        attributes[_who][_attribute] = AttributeData(
            _value,
            msg.sender,
            block.timestamp
        );
        emit SetAttribute(_who, _attribute, _value, msg.sender);
    }

    function hasAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (bool)
    {
        return attributes[_who][_attribute].value != 0;
    }

    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (AttributeData memory data)
    {
        data = attributes[_who][_attribute];
    }

    function getAttributeValue(address _who, bytes32 _attribute)
        public
        view
        returns (uint256)
    {
        return attributes[_who][_attribute].value;
    }
}

// File: contracts/interfaces/IUserRegistry.sol


pragma solidity 0.6.10;

/**
 * @dev Interface of the Registry contract.
 */
interface IUserRegistry {
    function canTransfer(address _from, address _to) external view;

    function canTransferFrom(
        address _spender,
        address _from,
        address _to
    ) external view;

    function canMint(address _to) external view;

    function canBurn(address _from, uint256 _amount) external view;

    function canWipe(address _account) external view;

    function isRedeem(address _sender, address _recipient)
        external
        view
        returns (bool);

    function isRedeemFrom(
        address _caller,
        address _sender,
        address _recipient
    ) external view returns (bool);
}

// File: contracts/UserRegistry.sol

pragma solidity 0.6.10;




contract UserRegistry is Registry, IUserRegistry {
    uint256 public constant REDEMPTION_ADDRESS_COUNT = 0x100000;
    bytes32 public constant IS_BLOCKLISTED = "IS_BLOCKLISTED";
    bytes32 public constant KYC_AML_VERIFIED = "KYC_AML_VERIFIED";
    bytes32 public constant CAN_BURN = "CAN_BURN";
    bytes32 public constant USER_REDEEM_ADDRESS = "USER_REDEEM_ADDRESS";
    bytes32 public constant REDEEM_ADDRESS_USER = "REDEEM_ADDRESS_USER";

    address public token;

    mapping(address => string) private usersId;
    mapping(string => address) private usersById;

    uint256 private redemptionAddressCount;

    uint256 public minBurnBound;
    uint256 public maxBurnBound;

    struct User {
        address account;
        string id;
        address redeemAddress;
        bool blocked;
        bool KYC; // solhint-disable-line var-name-mixedcase
        bool canBurn;
    }

    event RegisterNewUser(
        address indexed account,
        address indexed redeemAddress
    );

    event UserKycVerified(address indexed account);

    event UserKycUnverified(address indexed account);

    event EnableRedeemAddress(address indexed account);

    event DisableRedeemAddress(address indexed account);

    event BlockAccount(address indexed account);

    event UnblockAccount(address indexed account);

    event MinBurnBound(uint256 minBurn);

    event MaxBurnBound(uint256 minBurn);

    constructor(
        address _token,
        uint256 _minBurnBound,
        uint256 _maxBurnBound
    ) public {
        require(_minBurnBound <= _maxBurnBound, "min bigger than max");
        token = _token;
        minBurnBound = _minBurnBound;
        maxBurnBound = _maxBurnBound;
    }

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setMinBurnBound(uint256 _minBurnBound) public onlyOwner {
        require(_minBurnBound <= maxBurnBound, "min bigger than max");
        minBurnBound = _minBurnBound;

        emit MinBurnBound(_minBurnBound);
    }

    function setMaxBurnBound(uint256 _maxBurnBound) public onlyOwner {
        require(minBurnBound <= _maxBurnBound, "min bigger than max");
        maxBurnBound = _maxBurnBound;

        emit MaxBurnBound(_maxBurnBound);
    }

    /**
     * @dev Adds a new user in the registry.
     *      Sets {REDEEM_ADDRESS_USER} attribute for redeemAddress as `_account`.
     *      Sets {USER_REDEEM_ADDRESS} attribute for `_account` as redeemAddress.
     *
     * Emits a {RegisterNewUser} event.
     *
     * Requirements:
     *
     * - `_account` should not be a registered as user.
     * - number of redeem address should not be greater than max availables.
     */
    function registerNewUser(address _account, string calldata _id)
        public
        onlyOwner
    {
        require(!_isUser(_account), "user exist");
        require(usersById[_id] == address(0), "id already taken");

        redemptionAddressCount++;
        require(
            REDEMPTION_ADDRESS_COUNT > redemptionAddressCount,
            "max allowed users"
        );

        setAttribute(
            address(redemptionAddressCount),
            REDEEM_ADDRESS_USER,
            uint256(_account)
        );

        setAttribute(_account, USER_REDEEM_ADDRESS, redemptionAddressCount);

        usersId[_account] = _id;
        usersById[_id] = _account;

        emit RegisterNewUser(_account, address(redemptionAddressCount));
    }

    /**
     * @dev Gets user's data.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     */
    function getUser(address _account)
        public
        view
        onlyOwner
        returns (User memory user)
    {
        user.account = _account;
        user.id = usersId[_account];
        user.redeemAddress = getRedeemAddress(_account);
        user.blocked = _isBlocked(_account);
        user.KYC = _isKyced(_account);
        user.canBurn =
            getAttributeValue(getRedeemAddress(_account), CAN_BURN) == 1;
    }

    /**
     * @dev Gets user by its id.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     */
    function getUserById(string calldata _id)
        public
        view
        onlyOwner
        returns (User memory user)
    {
        return getUser(usersById[_id]);
    }

    /**
     * @dev Sets user id.
     *
     * Requirements:
     *
     * - the caller should be the owner.
     * - `_account` should be a registered as user.
     * - `_id` should not be taken.
     */
    function setUserId(address _account, string calldata _id) public onlyOwner {
        require(_isUser(_account), "not a user");
        require(usersById[_id] == address(0), "id already taken");
        string memory prevId = usersId[_account];
        usersId[_account] = _id;
        usersById[_id] = _account;
        delete usersById[prevId];
    }

    /**
     * @dev Sets user as KYC verified.
     *
     * Emits a {UserKycVerified} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function userKycVerified(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 1);

        emit UserKycVerified(_account);
    }

    /**
     * @dev Sets user as KYC un-verified.
     *
     * Emits a {UserKycVerified} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function userKycUnverified(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 0);

        emit UserKycUnverified(_account);
    }

    /**
     * @dev Enables `_account` redeem address to burn.
     *
     * Emits a {EnableUserRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     * - `_account` should be KYC verified.
     */
    function enableRedeemAddress(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");
        require(_isKyced(_account), "user has not KYC");

        setAttribute(getRedeemAddress(_account), CAN_BURN, 1);

        emit EnableRedeemAddress(_account);
    }

    /**
     * @dev Disables `_account` redeem address to burn.
     *
     * Emits a {DisableRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function disableRedeemAddress(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(getRedeemAddress(_account), CAN_BURN, 0);

        emit DisableRedeemAddress(_account);
    }

    /**
     * @dev Sets user as KYC verified.
     *      Enables `_account` redeem address to burn.
     *
     * Emits a {UserKycVerified} event.
     * Emits a {EnableUserRedeemAddress} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function verifyKycEnableRedeem(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 1);
        setAttribute(getRedeemAddress(_account), CAN_BURN, 1);

        emit UserKycVerified(_account);
        emit EnableRedeemAddress(getRedeemAddress(_account));
    }

    /**
     * @dev Sets user as KYC un-verified.
     *      Disables `_account` redeem address to burn.
     *
     * Emits a {UserKycVerified} event.
     * Emits a {v} event.
     *
     * Requirements:
     *
     * - `_account` should be a registered as user.
     */
    function unverifyKycDisableRedeem(address _account) public onlyOwner {
        require(_isUser(_account), "not a user");

        setAttribute(_account, KYC_AML_VERIFIED, 0);
        setAttribute(getRedeemAddress(_account), CAN_BURN, 0);

        emit UserKycUnverified(_account);
        emit DisableRedeemAddress(getRedeemAddress(_account));
    }

    /**
     * @dev Registers `_account` as blocked.
     *
     * Emits a {BlockAccount} event.
     *
     * Requirements:
     *
     * - `_account` should not be already blocked.
     */
    function blockAccount(address _account) public onlyOwner {
        require(!_isBlocked(_account), "user already blocked");
        setAttribute(_account, IS_BLOCKLISTED, 1);

        emit BlockAccount(_account);
    }

    /**
     * @dev Registers `_account` as un-blocked.
     *
     * Emits a {UnblockAccount} event.
     *
     * Requirements:
     *
     * - `_account` should be blocked.
     */
    function unblockAccount(address _account) public onlyOwner {
        require(_isBlocked(_account), "user not blocked");
        setAttribute(_account, IS_BLOCKLISTED, 0);

        emit UnblockAccount(_account);
    }

    /**
     * @dev Gets user's account associated to a given `_redeemAddress`.
     */
    function getUserByRedeemAddress(address _redeemAddress)
        public
        view
        returns (address)
    {
        return address(getAttributeValue(_redeemAddress, REDEEM_ADDRESS_USER));
    }

    /**
     * @dev Gets redeem address associated to a given `_account`
     */
    function getRedeemAddress(address _account) public view returns (address) {
        return address(getAttributeValue(_account, USER_REDEEM_ADDRESS));
    }

    /**
     * @dev Checks if the given `_account` is a registered user.
     */
    function _isUser(address _account) internal view returns (bool) {
        return getAttributeValue(_account, USER_REDEEM_ADDRESS) != 0;
    }

    /**
     * @dev Checks if the given `_account` is blocked.
     */
    function _isBlocked(address _account) internal view returns (bool) {
        return getAttributeValue(_account, IS_BLOCKLISTED) == 1;
    }

    /**
     * @dev Checks if the given `_account` is KYC verified.
     */
    function _isKyced(address _account) internal view returns (bool) {
        return getAttributeValue(_account, KYC_AML_VERIFIED) != 0;
    }

    /**
     * @dev Checks if the given `_account` is a redeeming address.
     */
    function _isRedemptionAddress(address _account)
        internal
        pure
        returns (bool)
    {
        return uint256(_account) < REDEMPTION_ADDRESS_COUNT;
    }

    /**
     * @dev Determines if it is redeeming.
     */
    function isRedeem(address, address _recipient)
        external
        view
        override
        onlyToken
        returns (bool)
    {
        return _isRedemptionAddress(_recipient);
    }

    /**
     * @dev Determines if it is redeeming from.
     */
    function isRedeemFrom(
        address,
        address,
        address _recipient
    ) external view override onlyToken returns (bool) {
        return _isRedemptionAddress(_recipient);
    }

    /**
     * @dev Throws if any of `_from` or `_to` is blocklisted.
     */
    function canTransfer(address _from, address _to)
        external
        view
        override
        onlyToken
    {
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_spender`, `_from` or `_to` is blocklisted.
     */
    function canTransferFrom(
        address _spender,
        address _from,
        address _to
    ) external view override onlyToken {
        require(!_isBlocked(_spender), "blocklisted");
        require(!_isBlocked(_from), "blocklisted");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_to` is not KYC verified or blocklisted.
     */
    function canMint(address _to) external view override onlyToken {
        require(_isKyced(_to), "user has not KYC");
        require(!_isBlocked(_to), "blocklisted");
    }

    /**
     * @dev Throws if any of `_from` is not enabled to burn or `_amount` lower than minBurnBound.
     */
    function canBurn(address _from, uint256 _amount)
        external
        view
        override
        onlyToken
    {
        require(getAttributeValue(_from, CAN_BURN) != 0, "can not burn");
        require(_amount >= minBurnBound, "below min bound");
        require(_amount <= maxBurnBound, "above max bound");
    }

    /**
     * @dev Throws if any of `_account` is not blocked.
     */
    function canWipe(address _account) external view override onlyToken {
        require(_isBlocked(_account), "can not wipe");
    }

    /**
     * @dev Throws if called by any address other than the token.
     */
    modifier onlyToken() {
        require(msg.sender == token, "only Token");
        _;
    }
}