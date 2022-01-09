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
    uint32 public bookIds;
    address[] private users;
    mapping (uint32 => Book) private books; // Library
    mapping (string => inStock) private book;
    mapping (address => bool) private existingUser;
    mapping (address => mapping(uint32 => uint32)) private rentedBooks; // ID => COPIES

    // Events
    event bookAdded(string indexed _bookName, uint32 _copies);
    event bookUpdated(string indexed _bookName, uint32 _copies);
    event bookRented(address indexed _rentedBy, string indexed _bookName);
    event bookReturned(address indexed _returnedBy, string indexed _bookName);

    // Structs
    struct inStock {
        bool exists;
        uint32 id;
    }

    struct Book {
        uint32 id;
        uint32 copies;
        string bookName;
    }

    // Functions
    function addBook(string memory _bookName, uint32 _copies) external onlyOwner {
        if (book[_bookName].exists) {
            uint32 id = book[_bookName].id;
            books[id].copies += _copies;
            emit bookUpdated(_bookName, _copies);
        } else {
            uint32 newId = bookIds + 1;
            books[newId] = Book(newId, _copies, _bookName);
            book[_bookName].exists = true;
            book[_bookName].id = newId;
            bookIds++;
            emit bookAdded(_bookName, _copies);
        }
    }

    function rentBook(uint32 _bookId) external {
        address userAddress = msg.sender;
        require(_bookId > 0 && _bookId <= bookIds, WRONG_ID);
        require(books[_bookId].copies > 0, NO_COPIES);

        rentedBooks[userAddress][_bookId]++;
        books[_bookId].copies--;
        if (!existingUser[userAddress]) { // If user rents for a first time.
            users.push(userAddress);
            existingUser[userAddress] = true;
        }
        emit bookRented(userAddress, books[_bookId].bookName);
    }

    function returnBook(uint32 _bookId) external {
        address userAddress = msg.sender;
        require(_bookId > 0 && _bookId <= bookIds, WRONG_ID);
        require(rentedBooks[userAddress][_bookId] > 0, NOT_RENTED);

        rentedBooks[userAddress][_bookId]--;
        books[_bookId].copies++;
        emit bookReturned(userAddress, books[_bookId].bookName);    
    }

    // Gas-free functions:

    function showBooks() external view returns (Book[] memory) {
        Book[] memory results = new Book[](bookIds);
        for (uint32 i=0; i<bookIds; i++) {
            results[i] = books[i+1];
        }
        return results;
    }

    function showUsers() external view returns (address[] memory) {
        return users;
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