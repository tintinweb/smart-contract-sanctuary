// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLib is Ownable {     //  REMINDER DO NOT USE ARRAYs, care with mapping sync, try to use memory instead of storrage whereven you can, watch transaction expence

    
    mapping(address=>mapping(bytes32=>bool)) public borowedBooks; // addresses of the owners of the books
    mapping(bytes32=>Book) public bytesToBooks;
    
    bytes32[] private availableBooksIds;
    
    struct Book {
        string name;
        uint count;
        address[] borowers;
    }
    
    // only administrator can add books
    function addBook(string calldata _name, uint _count) public onlyOwner {
        address[] memory borrowed;
        bytes32 bookByteId = keccak256(abi.encodePacked(_name));
        bytesToBooks[bookByteId]=Book(_name,_count,borrowed);     // BOOKS name to bytes and use it for ID
        availableBooksIds.push(bookByteId);
    }

    // user can borrow just 1 copy of a book
    function borrowBook(bytes32 _id) public  {
        require(bytesToBooks[_id].count>0 && borowedBooks[msg.sender][_id]==false);
        if(borowedBooks[msg.sender][_id]){
              bytesToBooks[_id].borowers.push(msg.sender);
        }
        bytesToBooks[_id].count--;
        borowedBooks[msg.sender][_id]=true;
    }
    
    // return borrowBook
    function returnBorrowedBook(bytes32 _id) public {
        borowedBooks[msg.sender][_id]=false;
        bytesToBooks[_id].count++;
    }
    
    // show all owners that Borrowed that Book
     function getBorowersBookAddreses(bytes32 _id) public view returns (address[] memory){
        return bytesToBooks[_id].borowers;
    }
    
    // return available books
    function getAvailableBookIds() public view returns (bytes32[] memory bookIDS) {
        bookIDS = availableBooksIds;
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