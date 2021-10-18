/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/IdentityManager.sol

pragma solidity ^0.8.4;

contract IdentityManager is Ownable {
    
    event CreateIdentity(address indexed addr, string indexed username, string dataUserName, string name, string twitter);
    event UpdateIdentity(address indexed addr, string indexed username, string dataUserName, string name, string twitter);
    event DeleteIdentity(address indexed addr, string indexed username);
    
    struct User {
        string username;
        string name;
        string twitter;
    }
    
    mapping(address => User) private users;
    mapping(string => address) internal usernames;
    
    function createIdentity(address account, string calldata username, string calldata name, string calldata twitter) public onlyOwner {
        User storage user = users[account];
        require(bytes(user.username).length == 0, "Existing identity");
        require(usernames[username] == address(0), "Duplicate username");
        
        user.username = username;
        user.name = name;
        user.twitter = twitter;
        usernames[username] = account;
        
        emit CreateIdentity(account, username, username, name, twitter);
    }
    
    function updateIdentity(address account, string calldata username, string calldata name, string calldata twitter) public onlyOwner {
        User storage user = users[account];

        require(usernames[username] == address(0), "Duplicate username");
        
        usernames[user.username] = address(0);
        usernames[username] = account;
        user.username = username;
        user.name = name;
        user.twitter = twitter;
        
        emit UpdateIdentity(account, username, username, name, twitter);
    }
    
    function deleteIdentity(address account) public onlyOwner {
        User storage user = users[account];
        string memory uname = user.username;
        require(bytes(uname).length != 0, "Identity does not exist");
        
        delete users[account];
        delete usernames[uname];
        
        emit DeleteIdentity(account, uname);
    }
}