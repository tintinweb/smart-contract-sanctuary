/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

contract BookLibraryV1 {
    
    // List of all books in the book library
    Book[] private books;
    
    // The owner of the book library - contract creator
    address private owner;
    
    // Map of borrower addresses and sub-maping of books they have borrowed. 
    // (We use sub-mapping as it is more cost efficant then looping thru array)
    mapping(address => mapping(uint => bool)) private borrowerBooks;
    
    // Map of books and array of their borrowers addresses.
    mapping(uint => address[]) private bookBorrowers;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * Adds a book in the book library. This function is permissted only by the owner (contract creator)
     **/
    function addBook(string memory _name, string memory _author, uint256 _copies) public onlyOwner {
        
        require(!_bookExists(_name), "Book with this name already exists");
        
        books.push(Book(books.length, _name, _author, _copies));
    }
    
    /**
     * Checks whether or not a book with specified name already exists in the library
     **/
    function _bookExists(string memory _name) private view returns (bool) {
        
        uint nameLength = bytes(_name).length;
        
        for(uint i = 0; i < books.length; i ++) {
            
            string memory bookName = books[i].name;
            
            // Skip hash comparision of the sizes differs
            if(bytes(bookName).length != nameLength) {
               continue;
            }
            
            // Compare by hash and return if found
            if( keccak256(bytes(_name)) == keccak256(bytes(bookName))) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Borrow the specified book from the book library 
     **/
    function borrowBook(uint _bookId) public {
        
        // Get reference to the book and the user borrowed books
        
        Book storage book = books[_bookId];
        
        mapping(uint => bool) storage borrowedBooks = borrowerBooks[msg.sender];
        
        // Validation busness rules: 
        // The user should not be able to borrow same book more then once and if no copies are left
        
        require(borrowedBooks[_bookId] != true, "You have already borrowed a copy from this book");
        
        require(book.copies > 0, "No copies left of this book");
        
        // Add this book to the borrowers list
        borrowedBooks[_bookId] = true;
        
        // Reduce the total number of copies for this book
        book.copies --;
        
        // Add the borrower to the book borrowers list. An append-only log.
        // (the task assessment requrement is to keep track of all borrowers for a book even if they have returned it, so we dont remove them from this list)
        bookBorrowers[_bookId].push(msg.sender);
    }
    
    /**
     * Return already borrowed book to the book library
     **/
    function returnBook(uint _bookId) public {
        
        // Get reference to the book and the user borrowed books
        
        Book storage book = books[_bookId];
        
        mapping(uint => bool) storage borrowedBooks = borrowerBooks[msg.sender];
        
        // Validation busness rules: 
        // The must have borrowed the book in order to return it
        
        require(borrowedBooks[_bookId] == true, "You have not borrowed the book you are trying to return");
        
        // Remove the book from the borrowers list
        delete borrowedBooks[_bookId];
        
        // Increase the total number of copies for this book
        book.copies ++;
        
    }
    
    /**
     * Get a list of all available books that can be borrowed
     **/
    function availableBooks() public view returns (Book[] memory) {
        
        // Find all books that have more then zero copies and return 
        
        // Note: solidity does not support dynamic arrays for return values so we have to set initial array size
        Book[] memory available = new Book[](books.length);
        uint availableCount = 0;
        
        for(uint i=0; i<books.length; i++) {
            
            if(books[i].copies > 0) {
                available[availableCount] = books[i];
                availableCount++;
            }
        }
        
        return available;
    }
    
    /**
     * Get list of all borrowers ever borrowed the specified book
     **/
    function borrowersPerBook(uint _bookId) public view returns (address[] memory) {
        
        return bookBorrowers[_bookId];
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    struct Book {
        uint id;
        string name;
        string author;
        uint256 copies;
    }
    
}