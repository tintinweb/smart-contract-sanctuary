// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    mapping(uint256 => Book) books;
    uint256 totalBooksCount;
    mapping(uint256 => address[]) borrowersLedger;
    mapping(address => mapping(uint256 => bool)) booksBorrowedByAddress;
    //not used at the moment
    Book[] allAvailableBooks;

    constructor() {
        totalBooksCount = 0;
    }

    struct Book {
        string title;
        uint256 copies;
        bool available;
        bool valid;
    }

    modifier bookIsValid(uint256 _id) {
        require(books[_id].valid, "This book doesn't exist...");
        _;
    }

    event NewBookAdded(string title, uint256 copies);

    //add new book
    function addBook(string memory _title, uint256 _copies) external onlyOwner {
        //TODO check external vs public in terms of gas usage
        Book memory newBook = Book({
            title: _title,
            copies: _copies,
            available: true,
            valid: true
        });
        books[totalBooksCount] = newBook;
        totalBooksCount++;
        allAvailableBooks.push(newBook);
        emit NewBookAdded(_title, _copies);
    }

    //get tatal number books in the library
    function getTotalBooksCount() external view returns (uint256) {
        return totalBooksCount;
    }

    //add new copies
    function increaseCopies(uint256 _id, uint256 _numToIncrease)
        public
        onlyOwner
    {
        require(
            _numToIncrease > 0,
            "Please provide a number greater than zero!"
        );
        books[_id].copies += _numToIncrease;

        if (books[_id].copies > 0) {
            books[_id].available = true;
        }
    }

    //get book by id
    function getBookById(uint256 _id)
        external
        view
        bookIsValid(_id)
        returns (Book memory)
    {
        return books[_id];
    }

    //borrow a book by id
    function borrowBook(uint256 _id) public bookIsValid(_id) {
        Book storage book = books[_id];
        require(book.valid, "This book doesn't exist...");
        require(
            book.available && !booksBorrowedByAddress[msg.sender][_id],
            "Sorry, you won't be able to borrow this book now..."
        );

        book.copies--;
        borrowersLedger[_id].push(msg.sender);
        booksBorrowedByAddress[msg.sender][_id] = true;

        if (book.copies == 0) {
            book.available = false;
        }
    }

    //return borrowed book
    function returnBook(uint256 _id) public bookIsValid(_id) {
        Book storage book = books[_id];
        require(
            booksBorrowedByAddress[msg.sender][_id],
            "It seems that you didn't borrow this book...hence you cannot return it..."
        );

        book.copies++;
        booksBorrowedByAddress[msg.sender][_id] = false;

        if (book.copies > 0) {
            book.available = true;
        }
    }

    //get all books ever borrowed by address
    function getBorrowersLedger(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        return borrowersLedger[_id];
    }

    //get books currently borrowed by address
    function getBooksBorrowedByAddress(address _user, uint256 _id)
        external
        view
        returns (bool)
    {
        return booksBorrowedByAddress[_user][_id];
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