// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/// @title Contract for handling lucky draws
/// @author Alexis Tay
/// @notice Contract used for creating lucky draws, submitting entries, and picking winners.
/// @dev Uses a commit reveal scheme to pick winners. Entries are salted, hashed and committed to the blockchain. The winner is picked, and the salt is then revealed.
/// @dev inherits from Ownable and Pausable [Only the owner can pause the contract]
contract LuckyDrawController is Ownable, Pausable {
    
    /// @notice Emitted when state of the lucky draw controller is changed.
    /// @param paused Boolean that indicates whether the contract is paused or not.
    event LuckyDrawStateChange(bool paused);

    /// @notice Pauses the contract.
    /// @dev This function is only accessible by the owner.
    function pause() public onlyOwner {
        _pause();
        emit LuckyDrawStateChange(true);
    }

    /// @notice Unpauses the contract.
    /// @dev This function is only accessible by the owner.
    function unpause() public onlyOwner {
        _unpause();
        emit LuckyDrawStateChange(false);
    }

    struct LuckyDraw {
        address owner;
        string name;
        bytes32 entries;
        string entriesIPFScid;
        uint256 numEntries;
        string salt;
        uint256[] winners;
        LuckyDrawState luckyDrawState;
    }

    enum LuckyDrawState {
        Created,
        EntriesSet,
        WinnerSet,
        SaltSet
    }
    
    /// @notice Array of all the lucky draws
    LuckyDraw[] public luckyDraws;

    /// @notice Emitted when lucky draw is created
    /// @param luckyDrawId Index of the lucky draw
    /// @param luckyDraw Lucky draw that was created
    event LuckyDrawCreated(uint256 luckyDrawId, LuckyDraw luckyDraw);

    /// @notice Emitted when entries of lucky draw is set
    /// @param luckyDraw Lucky draw that had its entries set
    event LuckyDrawEntriesSet(LuckyDraw luckyDraw);
     
    /// @notice Emitted when new winner of lucky draw is picked
    /// @param luckyDraw Lucky draw that had its winner picked
    event LuckyDrawWinnerPicked(LuckyDraw luckyDraw);

    /// @notice Emitted when salt of lucky draw is set
    /// @param luckyDraw Lucky draw that had its salt set
    event LuckyDrawSaltSet(LuckyDraw luckyDraw);

    /// @notice Creates a new lucky draw
    /// @param _name Name of the lucky draw
    function createLuckyDraw(string memory _name) public whenNotPaused() {
        LuckyDraw memory luckyDraw;
        luckyDraw.owner = msg.sender;
        luckyDraw.name = _name;
        luckyDraws.push(luckyDraw);
        emit LuckyDrawCreated(luckyDraws.length-1, luckyDraw);
    }    
    
    /// @notice Ensures that only lucky draw owner can operate on the lucky draw
    /// @param _luckyDrawId Index of the lucky draw
    modifier onlyLuckyDrawOwner(uint256 _luckyDrawId) {
        require (msg.sender == luckyDraws[_luckyDrawId].owner, "Not owner");
        _;
    }
    
    /// @notice Sets the entries of the lucky draw
    /// @param _luckyDrawId Index of the lucky draw
    /// @param _entries Entries of the lucky draw (hash of the concatenated salted hashed entries)
    /// @param _entriesIPFScid  PFS cid of the concatenated salted hashed entries
    /// @param _numEntries Number of entries
    /// @dev The actual entries on IPFS. Only the hash of the concatenated salted hashed entries is stored on the blockchain.
    function setEntries(uint256 _luckyDrawId, bytes32 _entries, string memory _entriesIPFScid, uint256 _numEntries) 
            public whenNotPaused() onlyLuckyDrawOwner(_luckyDrawId) {
        require(luckyDraws[_luckyDrawId].luckyDrawState == LuckyDrawState.Created, "State not Created");
        luckyDraws[_luckyDrawId].entries = _entries;
        luckyDraws[_luckyDrawId].entriesIPFScid = _entriesIPFScid;
        luckyDraws[_luckyDrawId].numEntries = _numEntries;

        luckyDraws[_luckyDrawId].luckyDrawState = LuckyDrawState.EntriesSet;
        emit LuckyDrawEntriesSet(luckyDraws[_luckyDrawId]);
    }
    
    /// @notice Picks a winner of the lucky draw
    /// @param _luckyDrawId Index of the lucky draw
    function pickWinner(uint256 _luckyDrawId) 
            public whenNotPaused() onlyLuckyDrawOwner(_luckyDrawId) {
        require(luckyDraws[_luckyDrawId].luckyDrawState != LuckyDrawState.Created, "State cannot be Created"); // need entries
        require(luckyDraws[_luckyDrawId].luckyDrawState != LuckyDrawState.SaltSet, "State cannot be SaltSet"); // cannot pick winner if salt is set

        uint256 winner =  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _luckyDrawId, luckyDraws[_luckyDrawId].winners.length))) % luckyDraws[_luckyDrawId].numEntries;
        luckyDraws[_luckyDrawId].winners.push(winner);

        luckyDraws[_luckyDrawId].luckyDrawState = LuckyDrawState.WinnerSet;
        emit LuckyDrawWinnerPicked(luckyDraws[_luckyDrawId]);
    }

    /// @notice Sets the salt of the lucky draw
    /// @param  _luckyDrawId Index of the lucky draw
    /// @param  _salt Salt of the lucky draw
    function setSalt(uint256 _luckyDrawId, string memory _salt) 
            public whenNotPaused() onlyLuckyDrawOwner(_luckyDrawId) {
        require(luckyDraws[_luckyDrawId].luckyDrawState == LuckyDrawState.WinnerSet, "State not WinnerSet");
        luckyDraws[_luckyDrawId].salt = _salt;
        luckyDraws[_luckyDrawId].luckyDrawState = LuckyDrawState.SaltSet;
        emit LuckyDrawSaltSet(luckyDraws[_luckyDrawId]);
    }

    /// @notice Returns the number of lucky draws
    /// @return Number of lucky draws
    function getNumluckyDraws() public view returns (uint256) {
        return luckyDraws.length;
    }

    /// @notice Returns the lucky draw ids that belong to the given address
    /// @return array of lucky draw ids
    /// @dev Loops thru the array once to get the number of lucky draws that belong to the given address, and then populate the array with the lucky draw ids.
    function getLuckyDrawIds() public view returns (uint256[] memory  ) {
        uint256 length;
        length = 0;
        for (uint256 i = 0; i < luckyDraws.length; i++) {
            if (luckyDraws[i].owner == msg.sender) {
                length++;
            }
        }
        uint[] memory luckyDrawIds = new uint256[](length);
        length = 0;
        for (uint256 i = 0; i < luckyDraws.length; i++) {
            if (luckyDraws[i].owner == msg.sender) {
                luckyDrawIds[length] = i;
                length++;
            }
        }
        return luckyDrawIds;
    }   

    /// @notice Returns the lucky draw with the given id
    /// @param _luckyDrawId Index of the lucky draw
    /// @return luckyDraw Lucky draw with the given id
    function getLuckyDraw(uint256 _luckyDrawId) public view returns (LuckyDraw memory luckyDraw) {
        luckyDraw = luckyDraws[_luckyDrawId];
    }
    
    /// @notice Returns the entries of the lucky draw with the given id
    /// @param _luckyDrawId Index of the lucky draw
    /// @return entries Hash of the concatenated salted hashed entries
    function getEntries(uint256 _luckyDrawId) public view returns (bytes32 entries) {
        entries = luckyDraws[_luckyDrawId].entries;
    }
    
    /// @notice Returns the winners of the lucky draw with the given id
    /// @param _luckyDrawId Index of the lucky draw
    /// @return winners Winners of the lucky draw
    function getWinners(uint256 _luckyDrawId) public view returns (uint256[] memory winners) {
        winners = luckyDraws[_luckyDrawId].winners;
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