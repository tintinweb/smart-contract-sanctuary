// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  This contract is one of 3 vesting contracts for the JustCarbon Foundation

  Here, we cover the case of >= 1 beneficiaries in receipt of a single set of funds.
  Each beneficiary has funds made available on a periodic basis, and can withdraw any time.

  @author jordaniza ([email protected])
 */

contract MultipleVesting is Ownable, ReentrancyGuard {
    struct Beneficiary {
        /**
        Covers all details about the address' vesting schedule
    */
        // token value transferred to the account at start date
        uint256 initialTransfer;
        // total value already withdrawn by the account
        uint256 withdrawn;
        // The total number of tokens that can be transferred to the beneficiary
        uint256 total;
        // used for checking whitelisted accounts in method guards
        bool exists;
    }
    /* ==== Constants and immutables ==== */

    // the JCG token
    IERC20 private immutable token;

    // the number of seconds in a vesting period
    uint256 public immutable periodLength;

    // when the vesting period starts for all beneficiaries
    uint256 public immutable startTimestamp;

    // when the vesting period ends for all beneficiaries
    uint256 public immutable endTimestamp;

    /* ==== Mutable variables ==== */

    // amount currently withdrawn from the contract
    uint256 public contractWithdrawn = 0;

    // amount of tokens currently available across all beneficiaries
    uint256 public contractBalance = 0;

    // As more beneficiaries are added, the amount outstanding needs to be incremented
    uint256 public contractOwedTotal = 0;

    // a list of all the beneficiaries
    address[] public beneficiaries;

    // full details of each beneficiary
    mapping(address => Beneficiary) public beneficiaryDetails;

    // Lifecycle flag to prevent adding beneficiaries after tokens have been deposited
    bool public tokensDeposited = false;

    // Lifecycle method to prevent withdraw calls after the emergency withdraw called
    bool public closed = false;

    /* ===== Events ===== */
    event AddBeneficiary(address beneficiary);
    event DepositTokens(uint256 qty);
    event WithdrawSuccess(address benficiary, uint256 qty);
    event WithdrawFail(address benficiary);
    event EmergencyWithdraw();

    /* ===== Constructor ===== */
    constructor(
        address _tokenAddress,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _periodLength
    ) {
        require(_periodLength > 0, "Period length invalid");
        require(
            (_startTimestamp >= block.timestamp) &&
                (_endTimestamp >= block.timestamp),
            "Cannot pass a timestamp in the past"
        );
        require(_startTimestamp < _endTimestamp, "Start is after end");
        periodLength = _periodLength;
        token = IERC20(_tokenAddress);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    /* ===== Modifiers ==== */
    modifier beforeDeposit() {
        require(!tokensDeposited, "Cannot call after deposit");
        _;
    }

    modifier afterDeposit() {
        require(tokensDeposited, "Cannot call before deposited");
        _;
    }

    modifier notClosed() {
        require(!closed, "Contract closed");
        _;
    }

    /* ===== Getters ===== */
    function getBeneficiaries() public view returns (address[] memory) {
        return beneficiaries;
    }

    function calculateAvailable(address _beneficiaryAddress)
        public
        view
        returns (uint256)
    {
        /**
      Public getter to access the balance of an address using an address
      @param _address the address to check - will revert if not a valid address
      @return the total amount vested for the provided address, minus withdrawals
     */
        Beneficiary storage beneficiary = beneficiaryDetails[
            _beneficiaryAddress
        ];
        return _calculateAvailable(beneficiary);
    }

    function _calculateAvailable(Beneficiary memory beneficiary)
        private
        view
        notClosed
        returns (uint256)
    {
        /**
      Private method that accepts the beneficiary struct to avoid multiple SLOAD operations
      @param beneficiary the address to check - will revert if not a valid address
      @return the total amount vested for the provided address, minus withdrawals
    */
        require(beneficiary.exists, "Beneficiary does not exist");
        if (block.timestamp >= endTimestamp) {
            return beneficiary.total - beneficiary.withdrawn;
        }
        uint256 initialTransfer = beneficiary.initialTransfer;
        if (block.timestamp < startTimestamp) {
            return initialTransfer - beneficiary.withdrawn;
        }

        uint256 elapsedSeconds = block.timestamp - startTimestamp;
        uint256 elapsedWholePeriods = elapsedSeconds / periodLength;
        // convert only whole periods to seconds for vesting (no partial vesting)
        uint256 vestingSeconds = elapsedWholePeriods * periodLength;
        uint256 quantityToBeVested = beneficiary.total - initialTransfer;
        uint256 vestingDuration = (endTimestamp - startTimestamp);
        uint256 totalVestedOverTime = (quantityToBeVested * vestingSeconds) /
            vestingDuration;
        uint256 totalVested = initialTransfer + totalVestedOverTime;
        return totalVested - beneficiary.withdrawn;
    }

    /* ===== State changing functions ===== */

    function addBeneficiary(
        address _beneficiary,
        uint256 _initialTransfer,
        uint256 _total
    ) public onlyOwner beforeDeposit returns (bool) {
        /**
      Adds a new beneficiary to the whitelisted accounts.
      This whitelists the account to be able to access the withdraw function
      Also adds to the running total of how much is requried to be deposited
     */
        require(
            _initialTransfer <= _total,
            "Initial transfer quantity exceeds the total value"
        );
        require(
            !beneficiaryDetails[_beneficiary].exists,
            "Beneficiary already exists"
        );
        // Add the amount owed to each beneficiary to the total for the contract
        contractOwedTotal += _total;

        beneficiaryDetails[_beneficiary] = Beneficiary({
            initialTransfer: _initialTransfer,
            withdrawn: 0,
            total: _total,
            exists: true
        });

        beneficiaries.push(_beneficiary);
        emit AddBeneficiary(_beneficiary);
        return true;
    }

    function addBeneficiaries(
        address[] memory _beneficiaryList,
        uint256[] memory _initialTransferList,
        uint256[] memory _totalList
    ) public virtual onlyOwner beforeDeposit returns (bool) {
        /**
      Adds multiple beneficiaries in a single loop
      OOG risks mean we can't rely on this function, but it's useful as 
      an option to reduce gas costs
     */
        require(
            _beneficiaryList.length == _initialTransferList.length &&
                _initialTransferList.length == _totalList.length,
            "Arrays not the same length"
        );

        for (uint256 i; i < _beneficiaryList.length; i++) {
            addBeneficiary(
                _beneficiaryList[i],
                _initialTransferList[i],
                _totalList[i]
            );
        }
        return true;
    }

    function deposit(uint256 amount)
        public
        onlyOwner
        beforeDeposit
        returns (bool)
    {
        /**
      Deposit tokens into the contract, that can then be withdrawn by the beneficiaries
     */
        require(amount > 0, "Invalid amount");
        require(
            amount == contractOwedTotal,
            "Amount deposited is not equal to the amount outstanding"
        );

        contractBalance += amount;
        tokensDeposited = true;

        require(token.transferFrom(msg.sender, address(this), amount));
        emit DepositTokens(amount);
        return true;
    }

    function withdraw() public nonReentrant afterDeposit returns (bool) {
        /**
      Transfer all tokens currently vested (for a given account) to the whitelisted account.  
     */
        address sender = msg.sender;
        Beneficiary storage beneficiary = beneficiaryDetails[sender];
        require(beneficiary.exists, "Only beneficiaries");

        uint256 amount = _calculateAvailable(beneficiary);

        require(amount > 0, "Nothing to withdraw");
        // prevent locked tokens due to rounding errors
        if (amount > contractBalance) {
            amount = contractBalance;
        }

        beneficiary.withdrawn += amount;
        contractWithdrawn += amount;
        contractBalance -= amount;

        require(token.transfer(sender, amount));
        emit WithdrawSuccess(sender, amount);
        return true;
    }

    function emergencyWithdraw()
        public
        nonReentrant
        notClosed
        onlyOwner
        returns (bool)
    {
        /**
      Withdraw the full token balance of the contract to a fallback account
      Used in the case of a discovered vulnerability.
      @return success
     */
        require(contractBalance > 0, "No funds to withdraw");
        contractWithdrawn += contractBalance;
        contractBalance = 0;
        closed = true;

        require(token.transfer(msg.sender, token.balanceOf(address(this))));
        emit EmergencyWithdraw();

        return true;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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