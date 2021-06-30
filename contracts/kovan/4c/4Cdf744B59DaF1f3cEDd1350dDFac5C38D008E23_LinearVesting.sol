// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILinearVesting.sol";

contract LinearVesting is ReentrancyGuard, Ownable, ILinearVesting {
    /// @notice start of vesting period as a timestamp
    uint256 public start;

    /// @notice end of vesting period as a timestamp
    uint256 public end;

    /// @notice amount vested for a beneficiary. Note beneficiary address can not be reused
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per beneficiary
    mapping(address => uint256) public totalDrawn;

    /// @notice ERC20 token we are vesting
    IERC20 public token;

    /// @notice start of vesting period as a timestamp
    //uint256 public constant FEE_DECIMAL= 10000;

    /**
     * @notice Construct a new vesting contract
     */
    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime
    ) {
        token = IERC20(_token);
        start = _startTime;
        end = _endTime;

        predefinedBeneficiaries();
    }

    function predefinedBeneficiaries() internal returns (bool) {
        //To be updated before deployment
        vestedAmount[
            0x0b4d53152f882A219615F148e4C353390072D715
        ] = 1000000000000000000000000;
        return true;
    }

    /**
     * @notice Create new vesting schedules in a batch
     * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
     * @param _beneficiaries array of beneficiaries of the vested tokens
     * @param _amounts array of amount of tokens (in wei)
     * @dev array index of address should be the same as the array index of the amount
     */
    function createVestingSchedules(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) external override onlyOwner returns (bool) {
        require(
            _beneficiaries.length > 0,
            "VestingContract::createVestingSchedules: ERR_NO_BENEFICIARY"
        );
        require(
            _beneficiaries.length == _amounts.length,
            "VestingContract::createVestingSchedules: ERR_ARR_LENGTH"
        );

        bool result = true;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            uint256 amount = _amounts[i];
            _createVestingSchedule(beneficiary, amount);
        }

        return result;
    }

    /**
     * @notice Create a new vesting schedule
     * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
     * @param _beneficiary beneficiary of the vested tokens
     * @param _amount amount of tokens (in wei)
     */
    function createVestingSchedule(address _beneficiary, uint256 _amount)
        external
        override
        onlyOwner
        returns (bool)
    {
        return _createVestingSchedule(_beneficiary, _amount);
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     */
    function drawDown() external nonReentrant returns (bool) {
        return _drawDown(msg.sender);
    }

    // Accessors

    /**
     * @notice Vested token balance for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return _tokenBalance total balance proxied via the ERC20 token
     */
    function tokenBalance() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Vesting schedule and associated data for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return _amount
     * @return _totalDrawn
     * @return _remainingBalance
     */
    function vestingScheduleForBeneficiary(address _beneficiary)
        external
        view
        override
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _remainingBalance
        )
    {
        return (
            vestedAmount[_beneficiary],
            totalDrawn[_beneficiary],
            vestedAmount[_beneficiary] - (totalDrawn[_beneficiary])
        );
    }

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _beneficiary beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _beneficiary)
        external
        view
        override
        returns (uint256 _amount)
    {
        return _availableDrawDownAmount(_beneficiary);
    }

    /**
     * @notice Balance remaining in vesting schedule
     * @param _beneficiary beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
     */
    function remainingBalance(address _beneficiary)
        external
        view
        override
        returns (uint256)
    {
        return vestedAmount[_beneficiary] - (totalDrawn[_beneficiary]);
    }

    // Internal

    function _createVestingSchedule(address _beneficiary, uint256 _amount)
        internal
        returns (bool)
    {
        require(
            _beneficiary != address(0),
            "VestingContract::createVestingSchedule: INVALID_BENEFICIARY_ADDRESS"
        );
        require(
            _amount > 0,
            "VestingContract::createVestingSchedule: ERR_ZERO_AMOUNT"
        );

        // Ensure one per address
        require(
            vestedAmount[_beneficiary] == 0,
            "VestingContract::createVestingSchedule: ERR_BENEFICIARY_ALREADY_ADDED"
        );

        uint256 initialBalance = token.balanceOf(address(this));

        // Vest the tokens into the deposit account and delegate to the beneficiary
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "VestingContract::createVestingSchedule: ERR_TRANSFER_FROM"
        );

        uint256 finalBalance = token.balanceOf(address(this));
        vestedAmount[_beneficiary] = finalBalance - initialBalance;

        emit ScheduleCreated(_beneficiary);

        return true;
    }

    function _drawDown(address _beneficiary) internal returns (bool) {
        require(
            vestedAmount[_beneficiary] > 0,
            "VestingContract::_drawDown: ERR_NO_VEST_SCHEDULED"
        );

        uint256 amount = _availableDrawDownAmount(_beneficiary);

        require(
            amount > 0,
            "VestingContract::_drawDown: ERR_NO_AMOUNT_WITHDRAWABLE"
        );

        // Increase total drawn amount
        totalDrawn[_beneficiary] = totalDrawn[_beneficiary] + (amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_beneficiary] <= vestedAmount[_beneficiary],
            "VestingContract::_drawDown: ERR_AMOUNT_ALREADY_REDEEMED"
        );

        // Issue tokens to beneficiary
        require(
            token.transfer(_beneficiary, amount),
            "VestingContract::_drawDown: ERR_TOKEN_TRANSFER"
        );
        vestedAmount[_beneficiary] -= amount;

        emit DrawDown(_beneficiary, amount);

        return true;
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function _availableDrawDownAmount(address _beneficiary)
        internal
        view
        returns (uint256 _amount)
    {
        if (_getNow() <= end) {
            // the cliff period has not ended, no tokens to draw down
            return 0;
        } else {
            return vestedAmount[_beneficiary] - (totalDrawn[_beneficiary]);
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

interface ILinearVesting {
    /// @notice event emitted when a vesting schedule is created
    event ScheduleCreated(address indexed _beneficiary);

    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(address indexed _beneficiary, uint256 indexed _amount);

    function createVestingSchedules(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) external returns (bool);

    /**
     * @notice Create a new vesting schedule
     * @notice A transfer is used to bring tokens into the VestingDepositAccount so pre-approval is required
     * @param _beneficiary beneficiary of the vested tokens
     * @param _amount amount of tokens (in wei)
     */
    function createVestingSchedule(address _beneficiary, uint256 _amount)
        external
        returns (bool);

    /**
     * @notice Vested token balance for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return _tokenBalance total balance proxied via the ERC20 token
     */
    function tokenBalance() external view returns (uint256);

    /**
     * @notice Vesting schedule and associated data for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return _amount
     * @return _totalDrawn
     * @return _remainingBalance
     */
    function vestingScheduleForBeneficiary(address _beneficiary)
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _remainingBalance
        );

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _beneficiary beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _beneficiary)
        external
        view
        returns (uint256 _amount);

    /**
     * @notice Balance remaining in vesting schedule
     * @param _beneficiary beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
     */
    function remainingBalance(address _beneficiary)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
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