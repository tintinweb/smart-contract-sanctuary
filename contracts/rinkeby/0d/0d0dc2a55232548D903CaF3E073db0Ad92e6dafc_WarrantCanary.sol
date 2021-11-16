// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Warrant Canary with enclosed funds
/// @author haurog
/// @notice  A warrant canary contract implementation which allows enclosed funds (ETH only) to be withdrawn by a third party upon expiration

contract WarrantCanary is Ownable, Pausable {

    uint public IDcount;
    struct warrantCanary {
        uint ID;
        uint expirationTime;
        uint lastUpdatedInBlock;  // tracks in which block expiration or trusted third party has been changed.
        string purpose;
        address payable warrantCanaryOwner;
        address payable trustedThirdParty;
        uint enclosedFunds;
    }

    mapping(uint => warrantCanary) public  warrantCanaries;  // All warrant canaries accessed by IDs.
    mapping(address => uint[]) public IDsOwned;  // Store all warrant canaries that an address owns.
    mapping(address => uint[]) public IDsTrusted;  // Store all warrant canaries that have this address as a trusted third party.

    event LogCreated(uint warrantCanaryID, string purpose,address trustedThirdParty);
    event LogExpirationUpdated(uint warrantCanaryID, uint oldExpirationBlock, uint newExpirationBlock);
    event LogFundsAdded(uint warrantCanaryID, uint amount);
    event LogChangedTrustedThirdParty(uint warrantCanaryID, address oldTrustedThirdParty, address newTrustedThirdParty);
    event LogFundsWithdrawn(uint warrantCanaryID, uint amount);
    event LogDeleted(uint warrantCanaryID);

    modifier onlyCanaryOwner(uint warrantCanaryID) {
        require(msg.sender == warrantCanaries[warrantCanaryID].warrantCanaryOwner,
                "You are not the owner of this warrant canary.");
        _;
    }

    modifier onlyCanaryOwnerOrTrustedThirdParty(uint warrantCanaryID) {
        require(msg.sender == warrantCanaries[warrantCanaryID].warrantCanaryOwner ||
                msg.sender == warrantCanaries[warrantCanaryID].trustedThirdParty,
                "You are neither the owner or trusted third party of this warrant canary.");
        if (msg.sender == warrantCanaries[warrantCanaryID].trustedThirdParty) {
            require(block.timestamp >= warrantCanaries[warrantCanaryID].expirationTime,
                "Warrant canary has not expired yet.");
        }
        _;
    }

    modifier FundsOnlyWithThirdParty(address trustedThirdParty_) {
        // only allow funding if a trusted third party is chosen
        if (trustedThirdParty_ == address(0)) {
            require(msg.value == 0, "Funds can only be sent to warrant canaries with a trusted third party set.");
        }
        _;
    }

    /// @notice Creates a new Warrant Canary with trusted thirdParty (can be set to 0x0).
    /// @param expirationTime_: The time (unix epoch in seconds) when the warrant canary expires.
    /// @param purpose_: A string describing the purpose of the warrant canary.
    /// @param trustedThirdParty_: An address of a trusted third party. Can be 0x0 if a plain warrant canary should be used.
    function createWarrantCanary(
        uint expirationTime_,
        string memory purpose_,
        address payable trustedThirdParty_
    )
        public
        payable
        FundsOnlyWithThirdParty(trustedThirdParty_)
        whenNotPaused()
    {
        warrantCanaries[IDcount] = warrantCanary(
        {
            ID : IDcount,
            expirationTime: expirationTime_,
            lastUpdatedInBlock: block.number,
            purpose: purpose_,
            warrantCanaryOwner: payable(msg.sender),
            trustedThirdParty: trustedThirdParty_,
            enclosedFunds: msg.value
        });

        IDsOwned[msg.sender].push(IDcount);

        if (trustedThirdParty_!= address(0)) {
            IDsTrusted[trustedThirdParty_].push(IDcount);
        }

        emit LogCreated(IDcount, purpose_, trustedThirdParty_);

        IDcount++;

    }

    /// @notice Update the expiration time for an owned warrant canary contract.
    /// @param warrantCanaryID_: ID (uint) of the warrant canary whose expiration time should be changed.
    /// @param newExpirationTime_: The time (unix epoch in seconds) when the warrant canary expires.
    function updateExpiration(uint warrantCanaryID_, uint newExpirationTime_)
        public
        onlyCanaryOwner(warrantCanaryID_)
    {
        uint oldExpirationTime = warrantCanaries[warrantCanaryID_].expirationTime;
        warrantCanaries[warrantCanaryID_].expirationTime= newExpirationTime_;
        updateLastUpdatedInBlock(warrantCanaryID_);
        emit LogExpirationUpdated(warrantCanaryID_, oldExpirationTime, newExpirationTime_);
    }

    /// @notice Add funds to a warrant canary (ETH only).
    /// @param warrantCanaryID_: ID (uint) of the warrant canary to which the funds are added.
    function addFunds(uint warrantCanaryID_)
    public
    payable
    FundsOnlyWithThirdParty(warrantCanaries[warrantCanaryID_].trustedThirdParty)
    whenNotPaused()
    {
        warrantCanaries[warrantCanaryID_].enclosedFunds += msg.value;
        emit LogFundsAdded(warrantCanaryID_, msg.value);
    }

    /// @notice Change the address of the trusted third party. The 0x0 address is ownly allowed if no funds are enclosed.
    /// @param warrantCanaryID_: ID (uint) of the warrant canary whose trusted third party should be changed.
    function changeTrustedThirdParty(
        uint warrantCanaryID_,
        address payable newTrustedThirdParty_
    )
        public
        onlyCanaryOwner(warrantCanaryID_)

    {
        if (newTrustedThirdParty_ == address(0)) {
            require(warrantCanaries[warrantCanaryID_].enclosedFunds == 0,
            "Trusted third party can only be set to 0x0 if there are no funds enclosed.");
        }
        address oldTrustedThirdParty = warrantCanaries[warrantCanaryID_].trustedThirdParty;
        warrantCanaries[warrantCanaryID_].trustedThirdParty = newTrustedThirdParty_;
        updateLastUpdatedInBlock(warrantCanaryID_);
        emit LogChangedTrustedThirdParty(warrantCanaryID_, oldTrustedThirdParty, newTrustedThirdParty_);
    }

    /// @notice Withdraw a part of the funds from the warrant canary
    /// @param warrantCanaryID_: ID (uint) of the warrant canary whose funds should be withdrawn
    function withdrawSomeFunds(uint warrantCanaryID_, uint fundsToWithdraw_)
        public
        onlyCanaryOwnerOrTrustedThirdParty(warrantCanaryID_)
    {
        require(warrantCanaries[warrantCanaryID_].enclosedFunds >= fundsToWithdraw_);
        warrantCanaries[warrantCanaryID_].enclosedFunds -= fundsToWithdraw_;
        (bool sent, ) = msg.sender.call{value: fundsToWithdraw_}("");
        require(sent, "Failed to send funds.");
        emit LogFundsWithdrawn(warrantCanaryID_, fundsToWithdraw_);
    }

    /// @notice Withdraw all funds from the warrant canary.
    /// @param warrantCanaryID_: ID (uint) of the warrant canary whose full funds should be withdrawn.
    function withdrawAllFunds(uint warrantCanaryID_)
        public
        onlyCanaryOwnerOrTrustedThirdParty(warrantCanaryID_)
    {
        withdrawSomeFunds(warrantCanaryID_, warrantCanaries[warrantCanaryID_].enclosedFunds);
    }

    /// @notice Delete a given warrant canary. Deletion is only possible if no funds are enclosed.
    /// @param warrantCanaryID_: ID (uint) of the warrant canary which should be deleted.
    /// @dev The function also deletes the warrant canary ID from all IDsTrusted and IDsOwned.
    function deleteWarrantCanary(uint warrantCanaryID_)
        public
        onlyCanaryOwnerOrTrustedThirdParty(warrantCanaryID_) {
        // deletes the warrant canary from the mapping (only possible if enclosedFunds = 0)
        require(warrantCanaries[warrantCanaryID_].enclosedFunds == 0,
        "The warrant Canary still has funds and can not be deleted.");

        address wcOwner = warrantCanaries[warrantCanaryID_].warrantCanaryOwner;
        address wcTrusted = warrantCanaries[warrantCanaryID_].trustedThirdParty;

        IDsOwned[wcOwner] = removeByValue(IDsOwned[wcOwner], warrantCanaryID_);


        if (wcTrusted != address(0)) {
            IDsTrusted[wcTrusted] = removeByValue(IDsTrusted[wcTrusted], warrantCanaryID_);
        }

        delete warrantCanaries[warrantCanaryID_];

        emit LogDeleted(warrantCanaryID_);
    }

    /// @notice A helper function to remove an entry from an array by value.
    /// @param array_: Array from which an entry should be removed.
    /// @param valueToDelete_: Value of the entry to be deleted.
    /// @dev Keeps the order of the non removed elements (more expensive and not really necessary in this project).
    function removeByValue(uint[] storage array_, uint valueToDelete_)
        private
        returns(uint[] storage)
    {
        uint index = 0;
        // find index of the value (is unique)
        for(; index <= array_.length && array_[index] != valueToDelete_ ; index++){}

        // shift all elements after index one element upwards
        for (; index < array_.length - 1; index++){
            array_[index] = array_[index + 1];
        }
        // delete last element
        array_.pop();

        return array_;
    }

    /// @notice A getter function get an array of all owned warrant Canary IDs back.
    /// @param wcOwner: Address of which all the owned IDs are returned.
    /// @return an array (can be empty) with all owned warrant canaries.
    function getIDsOwned(address wcOwner)
        public
        view
        returns(uint[] memory)
    {
        return IDsOwned[wcOwner];
    }

    /// @notice A getter function get an array of all warrant Canary IDs back where the address is a trusted third party.
    /// @param wcTrusted: Address of which all the trusted third party warrant canaries are returned.
    /// @return an array (can be empty) with all the IDs for which the address is a trusted third party.
    function getIDsTrusted(address wcTrusted)
        public
        view
        returns(uint[] memory)
    {
        return IDsTrusted[wcTrusted];
    }

    /// @notice Updates the variable "lastUpdatedInBlock" in the warrant canary.
    /// @param warrantCanaryID_: ID (uint) of the warrant canary which should be deleted.
    function updateLastUpdatedInBlock(uint warrantCanaryID_) internal {
        warrantCanaries[warrantCanaryID_].lastUpdatedInBlock = block.number;
    }

    /// @notice Pauses the contract. Contract owner only, therefore very minimal function.
    function pauseContract() public onlyOwner() {
        _pause();
    }

    /// @notice Unpauses the contract. Contract owner only, therefore very minimal function.
    function unpauseContract() public onlyOwner() {
        _unpause();
    }

    /// @notice Retrieves Ether which is not assciated with any warrant Canary. Contract owner only, therefore very minimal function.
    function retrieveExcessFunds() public onlyOwner() {
        uint allEnclosedFunds;
        for(uint i = 0; i < IDcount; i++)
        {
            allEnclosedFunds += warrantCanaries[i].enclosedFunds;
        }
        uint withdrawAmount = address(this).balance - allEnclosedFunds;
        (bool sent, ) = msg.sender.call{value: withdrawAmount}("");
        require(sent, "Failed to send Ether.");
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}