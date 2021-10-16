// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GasChat is Ownable {
  event NewMessage(address indexed from, uint timestamp, string message, uint _style);
  event NewAlias(address indexed from, string _alias, string _url);

  uint[3] public prices = [0.000005 ether, 0.00005 ether, 0.0001 ether];

  struct Message {
    address waver;
    string message;
    uint timestamp;
    uint _style;
  }

  Message[] messages;

  struct User {
    address id;
    string _alias;
    string _url;
    bool exists;
  }
  mapping (address => User) public user;
  address[] public userAddresses;

  constructor() payable {}

  function setMessage(string memory _message, uint _style) public payable {
    uint msgLength = bytes(_message).length;
    require((msg.value >= msgLength * prices[_style] && msgLength < 281) || owner() == msg.sender);
    messages.push(Message(msg.sender, _message, block.timestamp, _style));
    emit NewMessage(msg.sender, block.timestamp, _message, _style);
  }

  function getAllMessages() view public returns (Message[] memory) {
    return messages;
  }

  function setAlias(string memory _alias, string memory _url) public payable {
    uint aliasLength = bytes(_alias).length;
    uint urlLength = bytes(_url).length;
    require(msg.value > 0.0299 ether && aliasLength < 21 && urlLength < 81 || owner() == msg.sender);    
    if(!user[msg.sender].exists) {
      userAddresses.push(msg.sender);
    }
    user[msg.sender] = User({id: msg.sender, _alias: _alias, _url: _url, exists: true });
    emit NewAlias(msg.sender, _alias, _url);
  }

  function getAllAliases() public view returns (User[] memory){
    User[] memory ret = new User[](userAddresses.length);
    for (uint i = 0; i < userAddresses.length; i++) {
      ret[i] = User({
        id: user[userAddresses[i]].id,
        _alias: user[userAddresses[i]]._alias,
        _url: user[userAddresses[i]]._url,
        exists: true
      });
    }
    return ret;
  }

  function withdrawFunds() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
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