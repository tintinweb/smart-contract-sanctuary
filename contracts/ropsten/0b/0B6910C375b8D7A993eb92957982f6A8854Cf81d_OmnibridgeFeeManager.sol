/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.7.0;

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


pragma solidity ^0.7.0;




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

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;

/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/upgradeable_contracts/modules/MediatorOwnableModule.sol

pragma solidity 0.7.5;

/**
 * @title MediatorOwnableModule
 * @dev Common functionality for non-upgradeable Omnibridge extension module.
 */
contract MediatorOwnableModule is OwnableModule {
    address public mediator;

    /**
     * @dev Initializes this contract.
     * @param _mediator address of the deployed Omnibridge extension for which this module is deployed.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _mediator, address _owner) OwnableModule(_owner) {
        require(Address.isContract(_mediator));
        mediator = _mediator;
    }

    /**
     * @dev Throws if sender is not the Omnibridge extension.
     */
    modifier onlyMediator {
        require(msg.sender == mediator);
        _;
    }
}

// File: contracts/upgradeable_contracts/modules/fee_manager/OmnibridgeFeeManager.sol

pragma solidity 0.7.5;

/**
 * @title OmnibridgeFeeManager
 * @dev Implements the logic to distribute fees from the Omnibridge mediator contract operations.
 * The fees are distributed in the form of ERC20/ERC677 tokens to the list of reward addresses.
 */
contract OmnibridgeFeeManager is MediatorOwnableModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // This is not a real fee value but a relative value used to calculate the fee percentage.
    // 1 ether = 100% of the value.
    uint256 internal constant MAX_FEE = 1 ether;
    uint256 internal constant MAX_REWARD_ACCOUNTS = 50;

    bytes32 public constant HOME_TO_FOREIGN_FEE = 0x741ede137d0537e88e0ea0ff25b1f22d837903dbbee8980b4a06e8523247ee26; // keccak256(abi.encodePacked("homeToForeignFee"))
    bytes32 public constant FOREIGN_TO_HOME_FEE = 0x03be2b2875cb41e0e77355e802a16769bb8dfcf825061cde185c73bf94f12625; // keccak256(abi.encodePacked("foreignToHomeFee"))

    // mapping feeType => token address => fee percentage
    mapping(bytes32 => mapping(address => uint256)) internal fees;
    address[] internal rewardAddresses;

    event FeeUpdated(bytes32 feeType, address indexed token, uint256 fee);

    /**
     * @dev Stores the initial parameters of the fee manager.
     * @param _mediator address of the mediator contract used together with this fee manager.
     * @param _owner address of the contract owner.
     * @param _rewardAddresses list of unique initial reward addresses, between whom fees will be distributed
     * @param _fees array with initial fees for both bridge directions.
     *   [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
     */
    constructor(
        address _mediator,
        address _owner,
        address[] memory _rewardAddresses,
        uint256[2] memory _fees
    ) MediatorOwnableModule(_mediator, _owner) {
        require(_rewardAddresses.length <= MAX_REWARD_ACCOUNTS);
        _setFee(HOME_TO_FOREIGN_FEE, address(0), _fees[0]);
        _setFee(FOREIGN_TO_HOME_FEE, address(0), _fees[1]);

        for (uint256 i = 0; i < _rewardAddresses.length; i++) {
            require(_isValidAddress(_rewardAddresses[i]));
            for (uint256 j = 0; j < i; j++) {
                require(_rewardAddresses[j] != _rewardAddresses[i]);
            }
        }
        rewardAddresses = _rewardAddresses;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Throws if given fee amount is invalid.
     */
    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Throws if given fee type is unknown.
     */
    modifier validFeeType(bytes32 _feeType) {
        require(_feeType == HOME_TO_FOREIGN_FEE || _feeType == FOREIGN_TO_HOME_FEE);
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Updates the value for the particular fee type.
     * Only the owner can call this method.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
     */
    function setFee(
        bytes32 _feeType,
        address _token,
        uint256 _fee
    ) external validFeeType(_feeType) onlyOwner {
        _setFee(_feeType, _token, _fee);
    }

    /**
     * @dev Retrieves the value for the particular fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @return fee value associated with the requested fee type.
     */
    function getFee(bytes32 _feeType, address _token) public view validFeeType(_feeType) returns (uint256) {
        // use token-specific fee if one is registered
        uint256 _tokenFee = fees[_feeType][_token];
        if (_tokenFee > 0) {
            return _tokenFee - 1;
        }
        // use default fee otherwise
        return fees[_feeType][address(0)] - 1;
    }

    /**
     * @dev Calculates the amount of fee to pay for the value of the particular fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _value bridged value, for which fee should be evaluated.
     * @return amount of fee to be subtracted from the transferred value.
     */
    function calculateFee(
        bytes32 _feeType,
        address _token,
        uint256 _value
    ) public view returns (uint256) {
        if (rewardAddresses.length == 0) {
            return 0;
        }
        uint256 _fee = getFee(_feeType, _token);
        return _value.mul(_fee).div(MAX_FEE);
    }

    /**
     * @dev Adds a new address to the list of accounts to receive rewards for the operations.
     * Only the owner can call this method.
     * @param _addr new reward address.
     */
    function addRewardAddress(address _addr) external onlyOwner {
        require(_isValidAddress(_addr));
        require(!isRewardAddress(_addr));
        require(rewardAddresses.length < MAX_REWARD_ACCOUNTS);
        rewardAddresses.push(_addr);
    }

    /**
     * @dev Removes an address from the list of accounts to receive rewards for the operations.
     * Only the owner can call this method.
     * finds the element, swaps it with the last element, and then deletes it;
     * @param _addr to be removed.
     * return boolean whether the element was found and deleted
     */
    function removeRewardAddress(address _addr) external onlyOwner {
        uint256 numOfAccounts = rewardAddresses.length;
        for (uint256 i = 0; i < numOfAccounts; i++) {
            if (rewardAddresses[i] == _addr) {
                rewardAddresses[i] = rewardAddresses[numOfAccounts - 1];
                delete rewardAddresses[numOfAccounts - 1];
                rewardAddresses.pop();
                return;
            }
        }
        // If account is not found and removed, the transactions is reverted
        revert();
    }

    /**
     * @dev Tells the number of registered reward receivers.
     * @return amount of addresses.
     */
    function rewardAddressCount() external view returns (uint256) {
        return rewardAddresses.length;
    }

    /**
     * @dev Tells the list of registered reward receivers.
     * @return list with all registered reward receivers.
     */
    function rewardAddressList() external view returns (address[] memory) {
        return rewardAddresses;
    }

    /**
     * @dev Tells if a given address is part of the reward address list.
     * @param _addr address to check if it is part of the list.
     * @return true if the given address is in the list
     */
    function isRewardAddress(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < rewardAddresses.length; i++) {
            if (rewardAddresses[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Distributes the fee proportionally between registered reward addresses.
     * @param _token address of the token contract for which fee should be distributed.
     */
    function distributeFee(address _token) external onlyMediator {
        uint256 numOfAccounts = rewardAddresses.length;
        uint256 fee = IERC20(_token).balanceOf(address(this));
        uint256 feePerAccount = fee.div(numOfAccounts);
        uint256 randomAccountIndex;
        uint256 diff = fee.sub(feePerAccount.mul(numOfAccounts));
        if (diff > 0) {
            randomAccountIndex = random(numOfAccounts);
        }

        for (uint256 i = 0; i < numOfAccounts; i++) {
            uint256 feeToDistribute = feePerAccount;
            if (diff > 0 && randomAccountIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }
            IERC20(_token).safeTransfer(rewardAddresses[i], feeToDistribute);
        }
    }

    /**
     * @dev Calculates a random number based on the block number.
     * @param _count the max value for the random number.
     * @return a number between 0 and _count.
     */
    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }

    /**
     * @dev Internal function for updating the fee value for the given fee type.
     * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
     * @param _token address of the token contract for which fee should apply, 0x00..00 describes the initial fee for newly created tokens.
     * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
     */
    function _setFee(
        bytes32 _feeType,
        address _token,
        uint256 _fee
    ) internal validFee(_fee) {
        fees[_feeType][_token] = 1 + _fee;
        emit FeeUpdated(_feeType, _token, _fee);
    }

    /**
     * @dev Checks if a given address can be a reward receiver.
     * @param _addr address of the proposed reward receiver.
     * @return true, if address is valid.
     */
    function _isValidAddress(address _addr) internal view returns (bool) {
        return _addr != address(0) && _addr != address(mediator);
    }
}