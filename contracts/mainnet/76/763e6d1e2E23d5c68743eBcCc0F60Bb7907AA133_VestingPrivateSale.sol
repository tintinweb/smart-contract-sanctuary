// File @openzeppelin/contracts/GSN/Context.sol@v3.1.0

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/Ownable.sol@v3.1.0

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v3.1.0

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



// File contracts/Vesting.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



// Vesting provides the main functionality for the vesting approach taken
// The goal is to enable releasing funds from the timelocks after the exchange listing has happened.
// To keep things simple the contract is Ownable, and the owner (a multisig wallet) is able to indicate that
// the exchange listing has happened. All release dates are defined in days relative to the listing date.

// All release schedules are set up during minting, HOWEVER, ERC20 balances will be transferred from the initial
// multisig wallets to the Vesting contracts after minting the ERC20.
// Caveat: The release schedules (timelocks) do need a sufficient balance and will otherwise fail. We decided not
// to write any guards for this situation since it's a 1-time only event and it is easy to remedy (send more RAMP).

// It will be the responsibility of the RAMP team to fund the Vesting contracts as soon as possible, and with
// the amounts necessary.
// It will also be the responsibility of the RAMP team to call the "setListingTime" function at the appropriate time.

abstract contract Vesting is Ownable {

    // Every timelock has this structure
    struct Timelock {
        address beneficiary;
        uint256 balance;
        uint256 releaseTimeOffset;
    }

    // The timelocks, publicly queryable
    Timelock[] public timelocks;

    // The time of exchange listing, as submitted by the Owner. Starts as 0.
    uint256 public listingTime = 0;

    // The token (RAMP DEFI)
    IERC20 token;

    // Event fired when tokens are released
    event TimelockRelease(address receiver, uint256 amount, uint256 timelock);

    // Vesting is initialized with the token contract
    constructor(address tokenContract) public {
        token = IERC20(tokenContract);
    }

    // Sets up a timelock. Intended to be used during instantiation of an implementing contract
    function setupTimelock(address beneficiary, uint256 amount, uint256 releaseTimeOffset)
    internal
    {
        // Create a variable
        Timelock memory timelock;

        // Set beneficiary
        timelock.beneficiary = beneficiary;

        // Set balance
        timelock.balance = amount;

        // Set the release time offset. This is a uint256 representing seconds after listingTime
        timelock.releaseTimeOffset = releaseTimeOffset;

        // Add the timelock to the array.
        timelocks.push(timelock);
    }

    // Lets Owner set the listingTime. Can be done only once.
    function setListingTime()
    public
    onlyOwner
    {
        // We can run this only once since listingTime will be a timestamp after.
        require(listingTime == 0, "Listingtime was already set");

        // Set the listingtime to the current timestamp.
        listingTime = block.timestamp;
    }

    // Initiates the process to release tokens in a given timelock.
    // Anyone can call this function, but funds will always be released to the beneficiary that was initially set.
    // If the transfer fails for any reason, the transaction will revert.
    // NOTE: It is the RAMP team responsibility to ensure the tokens are indeed owned by this contract.
    function release(uint256 timelockNumber)
    public
    {
        // Check if listingTime is set, otherwise it is not possible to release funds yet.
        require(listingTime > 0, "Listing time was not set yet");

        // Retrieve the requested timelock struct
        Timelock storage timelock = timelocks[timelockNumber];

        // Check if the timelock is ready for release.
        require(listingTime + timelock.releaseTimeOffset <= now, "Timelock can not be released yet.");

        // Get the amount to transfer
        uint256 amount = timelock.balance;

        // Set the timelock balance to 0
        timelock.balance = 0;

        // Transfer the token amount to the beneficiary. If this fails, the transaction will revert.
        require(token.transfer(timelock.beneficiary, amount), "Transfer of amount failed");

        // Emit an event for this.
        emit TimelockRelease(timelock.beneficiary, amount, timelockNumber);

    }

}


// File contracts/VestingPrivateSale.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



contract VestingPrivateSale is Vesting {

    constructor(address tokenContract, address beneficiary) Vesting(tokenContract) public {

        // 1 = Private1-5
        setupTimelock(beneficiary, 36000000e18, 0 days);

        // 2 = Private2-5
        setupTimelock(beneficiary, 36000000e18, 91 days);

        // 3 = Private3-5
        setupTimelock(beneficiary, 36000000e18, 182 days);

        // 4 = Private4-5
        setupTimelock(beneficiary, 36000000e18, 273 days);

        // 5 = Private5-5
        setupTimelock(beneficiary, 36000000e18, 365 days);

        // Make the beneficiary (Team multisig) owner of this contract
        transferOwnership(beneficiary);
    }

}