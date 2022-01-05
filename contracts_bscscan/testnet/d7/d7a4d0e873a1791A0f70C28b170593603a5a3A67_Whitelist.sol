pragma solidity 0.7.6;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public allotment;
    event WhitelistAdded(address indexed user, uint256 indexed _allotment);
    event AllotmentUpdated(address indexed user, uint256 indexed _allotment);
    event WhitelistRemoved(address indexed user);

   /**
     * Add contract addresses to the whitelist
     */

    function addToWhitelist(address _user, uint256 _allotment) public onlyOwner {
        require(!whitelisted[_user], "already whitelisted");
        whitelisted[_user] = true;
        allotment[_user] = _allotment;
        emit WhitelistAdded(_user,_allotment);
    }
    function addAddressesToWhitelist(address[] memory _userAddresses, uint256[] memory _allotment) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            addToWhitelist(_userAddresses[i], _allotment[i]);
        }
    }
    /**
     * Update the alootment of whitelist
     */
    function updateAllotmet(address _user, uint256 _allotment) public onlyOwner {
        require(whitelisted[_user], "User not whitelisted");
        allotment[_user] = _allotment;
        emit AllotmentUpdated(_user,_allotment);
    }
    function batchUpdateAllotmet(address[] memory _userAddresses, uint256[] memory _allotments) public onlyOwner {
        require(_userAddresses.length == _allotments.length, "Incomplete information");
        for(uint256 i = 0; i < _userAddresses.length; i++){
            updateAllotmet(_userAddresses[i], _allotments[i]);
        }
    }
    function checkWhitelist(address _user) public view returns(bool)  {
        return whitelisted[_user];
    }
     function checkAllotment(address _user) public view returns(uint256)  {
        return allotment[_user];
    }
    /**
     * Remove a contract addresses from the whitelist
     */

    function removeFromWhitelist(address _user) public onlyOwner {
        require(whitelisted[_user], "user not in whitelist");
        whitelisted[_user] = false;
        emit WhitelistRemoved(_user);
    }
    function batchRemoveFromWhitelist(address[] memory _userAddresses) public onlyOwner {
        for(uint256 i = 0; i < _userAddresses.length; i++){
            removeFromWhitelist(_userAddresses[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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