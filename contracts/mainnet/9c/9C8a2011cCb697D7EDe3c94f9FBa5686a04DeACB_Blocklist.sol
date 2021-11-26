/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity 0.5.16;

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

/**
 * @title Blocklist
 * @dev This contract manages a list of addresses and has a simple CRUD
 */
contract Blocklist is Ownable {
  /**
   * @dev The index of each user in the list
   */
  mapping(address => uint256) private _userIndex;

  /**
   * @dev The list itself
   */
  address[] private _userList;

  /**
   * @notice Event emitted when a user is added to the blocklist
   */
  event addedToBlocklist(address indexed account, address by);

  /**
   * @notice Event emitted when a user is removed from the blocklist
   */
  event removedFromBlocklist(address indexed account, address by);

  /**
   * @notice Modifier to facilitate checking the blocklist
   */
  modifier onlyInBlocklist(address account) {
    require(isBlocklisted(account), "Not in blocklist");
    _;
  }

  /**
   * @notice Modifier to facilitate checking the blocklist
   */
  modifier onlyNotInBlocklist(address account) {
    require(!isBlocklisted(account), "Already in blocklist");
    _;
  }

  /**
   * @dev Adds an address to the blocklist
   * @param account The address to add
   * @return true if the operation succeeded
   * @dev Fails if the address was already blocklisted
   */
  function _addToBlocklist(address account) private onlyNotInBlocklist(account) returns(bool) {
    _userIndex[account] = _userList.length;
    _userList.push(account);

    emit addedToBlocklist(account, msg.sender);

    return true;
  }

  /**
   * @notice Adds many addresses to the blocklist at once
   * @param accounts[] The list of addresses to add
   * @dev Fails if at least one of the addresses was already blocklisted
   */
  function batchAddToBlocklist(address[] calldata accounts) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      require(_addToBlocklist(accounts[i]));
    }
  }

  /**
   * @notice Adds an address to the blocklist
   * @param account The address to add
   * @return true if the operation succeeded
   * @dev Fails if the address was already blocklisted
   */
  function addToBlocklist(address account) external onlyOwner returns(bool) {
    return _addToBlocklist(account);
  }

  /**
   * @dev Removes an address from the blocklist
   * @param account The address to remove
   * @return true if the operation succeeds
   * @dev Fails if the address was not blocklisted
   */
  function _removeFromBlocklist(address account) private onlyInBlocklist(account) returns(bool) {
    uint rowToDelete = _userIndex[account];
    address keyToMove = _userList[_userList.length-1];
    _userList[rowToDelete] = keyToMove;
    _userIndex[keyToMove] = rowToDelete; 
    _userList.length--;

    emit removedFromBlocklist(account, msg.sender);
    
    return true;
  }

  /**
   * @notice Removes many addresses from the blocklist at once
   * @param accounts[] The list of addresses to remove
   * @dev Fails if at least one of the addresses was not blocklisted
   */
  function batchRemoveFromBlocklist(address[] calldata accounts) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      require(_removeFromBlocklist(accounts[i]));
    }
  }

  /**
   * @notice Removes an address from the blocklist
   * @param account The address to remove
   * @dev Fails if the address was not blocklisted
   * @return true if the operation succeeded
   */
  function removeFromBlocklist(address account) external onlyOwner returns(bool) {
    return _removeFromBlocklist(account);
  }

  /**
   * @notice Consults whether an address is blocklisted
   * @param account The address to check
   * @return bool True if the address is blocklisted
   */
  function isBlocklisted(address account) public view returns(bool) {
    if(_userList.length == 0) return false;

    // We don't want to throw when querying for an out-of-bounds index.
    // It can happen when the list has been shrunk after a deletion.
    if(_userIndex[account] >= _userList.length) return false;

    return _userList[_userIndex[account]] == account;
  }

  /**
   * @notice Fetches the list of all blocklisted addresses
   * @return array The list of currently blocklisted addresses
   */
  function getFullList() public view returns(address[] memory) {
    return _userList;
  }
}