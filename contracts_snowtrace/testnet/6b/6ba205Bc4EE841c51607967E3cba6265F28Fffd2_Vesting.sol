// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Token Vesting Contract
/// @author defikintaro
/// @notice This contract treats all of the addresses equally
/// @dev All function calls are currently implemented without side effects
contract Vesting is Ownable {
  using SafeMath for uint256;
  using Address for address;

  /// @dev Emits when `initialize` method has been called
  /// @param caller The address of the caller
  /// @param distributionStart Distribution start date
  /// @param installmentPeriod Per installment period
  event Initialized(address caller, uint256 distributionStart, uint256 installmentPeriod);

  /// @dev Emits when `withdraw` method has been called
  /// @param recipient Recipient address
  /// @param value Transferred value
  event Withdrawn(address recipient, uint256 value);

  /// @dev Emits when `addParticipants` method has been called
  /// @param participants Participants addresses
  /// @param stakes Participants stakes
  /// @param caller The address of the caller
  event ParticipantsAdded(address[] participants, uint256[] stakes, address caller);

  /// @dev Emits when `addGroup` method has been called
  /// @param cliff Group cliff period
  /// @param tgePerMillion Unlocked tokens per million
  /// @param numberOfInstallments Number of installments of being distributed
  /// @param caller The address of the caller
  event GroupAdded(
    uint256 cliff,
    uint256 tgePerMillion,
    uint256 numberOfInstallments,
    address caller
  );

  /// @dev The instance of ERC20 token
  IERC20 token;

  /// @dev Total amount of tokens
  /// @dev Amount of remaining tokens to distribute for the beneficiary
  /// @dev Beneficiary cliff period
  /// @dev Total number of installments for the beneficiary
  /// @dev Number of installments that were made
  /// @dev The value of single installment
  /// @dev The value to transfer to the beneficiary at TGE
  /// @dev Boolean variable that contains whether the value at TGE was paid or not
  struct Beneficiary {
    uint256 stake;
    uint256 tokensLeft;
    uint256 cliff;
    uint256 numberOfInstallments;
    uint256 numberOfInstallmentsMade;
    uint256 installmentValue;
    uint256 tgeValue;
    bool wasValueAtTgePaid;
  }

  /// @dev Is group active
  /// @dev Cliff period
  /// @dev TGE unlock amount per million
  /// @dev Number of installments will be made
  struct Group {
    bool active;
    uint256 cliff;
    uint256 tgePerMillion;
    uint256 numberOfInstallments;
  }

  /// @dev Beneficiary records
  mapping(address => Beneficiary) public beneficiaries;
  /// @dev Group records
  mapping(uint8 => Group) public groups;

  /// @dev Track the number of beneficiaries
  uint256 public numberOfBeneficiaries;
  /// @dev Track the total sum
  uint256 public sumOfStakes;
  /// @dev Total deposited tokens
  uint256 public totalDepositedTokens;
  /// @dev Installment period
  uint256 public period;

  /// @dev The timestamp of the distribution start
  uint256 public distributionStartTimestamp;
  /// @dev Boolean variable that indicates whether the contract was initialized
  bool public isInitialized = false;

  /// @dev Checks that the contract is initialized
  modifier initialized() {
    require(isInitialized, "Not initialized");
    _;
  }

  constructor() {}

  /// @dev Initializes the distribution
  /// @param _token Distributed token address
  /// @param _distributionStart Distribution start date
  /// @param _installmentPeriod Per installment period
  function initialize(
    address _token,
    uint256 _distributionStart,
    uint256 _installmentPeriod
  ) external onlyOwner {
    require(!isInitialized, "Already initialized");
    require(_distributionStart > block.timestamp, "Cannot start early");
    require(_installmentPeriod > 0, "Installment period must be greater than 0");
    require(_token.isContract(), "The token address must be a deployed contract");

    isInitialized = true;
    token = IERC20(_token);
    distributionStartTimestamp = _distributionStart;
    period = _installmentPeriod;

    emit Initialized(msg.sender, _distributionStart, _installmentPeriod);
  }

  /// @dev Deposit the tokens from the owner wallet then increase `totalDepositedTokens`
  /// @param _amount Amount of the tokens
  function deposit(uint256 _amount) external onlyOwner initialized {
    totalDepositedTokens += _amount;
    token.transferFrom(msg.sender, address(this), _amount);
  }

  /// @dev Withdraw the TGE amount
  /// @notice Reverts if there are not enough tokens
  function withdrawTge() external initialized {
    if (!beneficiaries[msg.sender].wasValueAtTgePaid) {
      beneficiaries[msg.sender].wasValueAtTgePaid = true;
      token.transfer(msg.sender, beneficiaries[msg.sender].tgeValue);
    }
  }

  /// @dev Withdraws the available installment amount
  /// @notice Does not allow withdrawal before the cliff date
  function withdraw() external initialized {
    address sender = msg.sender;
    require(beneficiaries[sender].stake > 0, "Not a participant");
    require(
      block.timestamp >= distributionStartTimestamp.add(beneficiaries[sender].cliff),
      "Cliff duration has not passed"
    );
    require(
      beneficiaries[sender].numberOfInstallments > beneficiaries[sender].numberOfInstallmentsMade,
      "Installments have been paid"
    );

    uint256 elapsedPeriods = block
      .timestamp
      .sub(distributionStartTimestamp.add(beneficiaries[sender].cliff))
      .div(period);

    if (elapsedPeriods > beneficiaries[sender].numberOfInstallments) {
      elapsedPeriods = beneficiaries[sender].numberOfInstallments;
    }

    uint256 availableInstallments = elapsedPeriods.sub(
      beneficiaries[sender].numberOfInstallmentsMade
    );
    uint256 amount = availableInstallments.mul(beneficiaries[sender].installmentValue);

    beneficiaries[sender].numberOfInstallmentsMade += availableInstallments;
    token.transfer(sender, amount);
    emit Withdrawn(sender, amount);
  }

  /// @dev Adds new participants
  /// @param _participants The addresses of new participants
  /// @param _stakes The amounts of the tokens that belong to each participant
  /// @param _group Group id of the participants
  /// @notice Ceils the installment value distributed per period by 1x10^-6
  function addParticipants(
    address[] calldata _participants,
    uint256[] calldata _stakes,
    uint8 _group
  ) external onlyOwner {
    require(!isInitialized, "Cannot add participants after initialization");
    require(groups[_group].active, "Group is not active");
    require(_participants.length == _stakes.length, "Different array sizes");
    for (uint256 i = 0; i < _participants.length; i++) {
      require(_participants[i] != address(0), "Invalid address");
      require(_stakes[i] > 0, "Stake must be more than 0");
      require(beneficiaries[_participants[i]].stake == 0, "Participant has already been added");

      uint256 _tgeValue = _stakes[i].mul(groups[_group].tgePerMillion).div(1e6);

      uint256 _installmentValue = _stakes[i].sub(_tgeValue).div(
        groups[_group].numberOfInstallments
      );
      // Ceil the installment amount
      _installmentValue = _installmentValue.div(1e12).add(1);
      _installmentValue *= 1e12;

      // Track the sum
      sumOfStakes += _installmentValue.mul(groups[_group].numberOfInstallments).add(_tgeValue);

      beneficiaries[_participants[i]] = Beneficiary({
        stake: _stakes[i],
        tokensLeft: 0,
        cliff: groups[_group].cliff,
        numberOfInstallments: groups[_group].numberOfInstallments,
        numberOfInstallmentsMade: 0,
        installmentValue: _installmentValue,
        tgeValue: _tgeValue,
        wasValueAtTgePaid: false
      });
      numberOfBeneficiaries++;
    }

    emit ParticipantsAdded(_participants, _stakes, msg.sender);
  }

  /// @dev Add or change a group parameters
  /// @param _groupId Id of the group
  /// @param _cliff Cliff duration period
  /// @param _tgePerMillion Unlocked token amount at TGE per million
  /// @param _numberOfInstallments Number of installments of being distributed
  function setGroup(
    uint8 _groupId,
    uint256 _cliff,
    uint256 _tgePerMillion,
    uint256 _numberOfInstallments
  ) external onlyOwner {
    require(!isInitialized, "Cannot change a group after initialization");
    groups[_groupId] = Group({
      active: true,
      cliff: _cliff,
      tgePerMillion: _tgePerMillion,
      numberOfInstallments: _numberOfInstallments
    });
    emit GroupAdded(_cliff, _tgePerMillion, _numberOfInstallments, msg.sender);
  }

  /// @dev Withdraw the remaining amount to the owner after stakes are initialized
  function withdrawRemaining() external onlyOwner initialized {
    uint256 remaining = totalDepositedTokens.sub(sumOfStakes);
    totalDepositedTokens = sumOfStakes;
    token.transfer(owner(), remaining);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}