/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

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
        return msg.data;
    }
}

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

contract GakuenLootVerse is Ownable {

    struct Content {
        uint256 chainId;
        address _address;
        string uri;
        string description;
    }

    mapping(string => Content) contents;
    string[] names;

    event ContentChanged(string indexed name, uint256 chainId, address _address, string uri, string description);

    function getContent(string memory name) public view returns (Content memory) {
        return contents[name];
    }

    function getNames() public view returns (string[] memory) {
        return names;
    }

    function setContent(string memory name, uint256 chainId, address _address, string memory uri, string memory description) public onlyOwner {
        require(_address != address(0) || bytes(uri).length > 0, "content must need address or uri");

        Content storage content = contents[name];
        if(content._address == address(0) && bytes(content.uri).length == 0) {
            names.push(name);
        }
        content.chainId = chainId;
        content._address = _address;
        content.uri = uri;
        content.description = description;

        emit ContentChanged(name, chainId, _address, uri, description);
    }

    function removeContent(string memory name) public onlyOwner {
        Content memory content = contents[name];
        require(content._address != address(0) || bytes(content.uri).length > 0, "content not exist");

        delete contents[name];
        string memory lastName = names[names.length - 1];
        uint index;
        for (index = 0; index < names.length; index++) {
            if (keccak256(bytes(names[index])) == keccak256(bytes(name))) {
                break;
            }
        }
        names[index] = lastName;
        names.pop();

        emit ContentChanged(name, 0, address(0), "", "");
    }
}