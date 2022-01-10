// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookStore is Ownable{

    // Constants
    string constant private WRONG_ID = "Wrong ID";
    string constant private NO_COPIES = "No copies available";
    string constant private NOT_RENTED = "Book not rented";

    // Variables
    uint[] bookIds;
    mapping (uint => Book) private books; // Library
    mapping (address => mapping(uint => bool)) private existingUser; // Address -> bookId => bool
    mapping (address => mapping(uint => uint)) private rentedBooks; // ID => COPIES

    // Events
    event bookAdded(string indexed _bookName, string indexed _author, uint _copies);
    event bookUpdated(string indexed _bookName, string indexed _author, uint _copies);
    event bookRented(address indexed _rentedBy, string indexed _author, string indexed _bookName);
    event bookReturned(address indexed _returnedBy, string indexed _author, string indexed _bookName);

    // Structs
    struct Book {
        uint id;
        uint copies;
        string bookName;
        string author;
        address[] borrowers;
    }

    // Functions
    function addBook(string memory _bookName, string memory _author, uint _copies) external onlyOwner {
        uint bookId = uint(keccak256(abi.encodePacked(_bookName, _author))) % 10 ** 10;

        if (bookExists(bookId)) {
            books[bookId].copies += _copies;
            emit bookUpdated(_bookName, _author, _copies);
        } else {
            address[] memory addresses;
            books[bookId] = Book(bookId, _copies, _bookName, _author, addresses);
            bookIds.push(bookId);
            emit bookAdded(_bookName, _author, _copies);
        }
    }

    function rentBook(uint _bookId) external {
        address userAddress = msg.sender;
        require(bookExists(_bookId), WRONG_ID);
        require(books[_bookId].copies > 0, NO_COPIES);

        rentedBooks[userAddress][_bookId]++;
        books[_bookId].copies--;

        if (!existingUser[userAddress][_bookId]) { // If the user rents the particular book for a first time.
            books[_bookId].borrowers.push(userAddress);
            existingUser[userAddress][_bookId] = true;
        }

        emit bookRented(userAddress, books[_bookId].author, books[_bookId].bookName);
    }

    function returnBook(uint _bookId) external {
        address userAddress = msg.sender;
        require(bookExists(_bookId), WRONG_ID);
        require(rentedBooks[userAddress][_bookId] > 0, NOT_RENTED);

        rentedBooks[userAddress][_bookId]--;
        books[_bookId].copies++;
        emit bookReturned(userAddress, books[_bookId].author, books[_bookId].bookName);    
    }

    function bookExists(uint _id) internal view returns (bool) {
        return bytes(books[_id].bookName).length > 0;
    }

    // Gas-free functions:

    function showBooks() external view returns (Book[] memory) {
        uint availableBooks = bookIds.length;
        Book[] memory results = new Book[](availableBooks);
        for (uint i=0; i<availableBooks; i++) {
            results[i] = books[bookIds[i]];
        }
        return results;
    }

    function showBorrowers(uint _bookId) external view returns (address[] memory) {
        return books[_bookId].borrowers;
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