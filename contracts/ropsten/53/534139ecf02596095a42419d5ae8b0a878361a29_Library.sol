pragma solidity ^0.4.23;

contract Library {
    
    address public owner;
    
    mapping(address => bool) public librarians;
    mapping(uint256 => book) public books;
    mapping(uint256 => bool) public bookExists;
    uint256 public idBook;

    struct book {
        string isbn;
        address owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyLibrarian() {
        require(librarians[msg.sender]);
        _;
    }

    event AddLibrarian(address indexed _address);
    event RemoveLibrarian(address indexed _address);
    event AddBook(string _isbn, address indexed _owner, address indexed _createdBy);
    event RemoveBook(string _isbn, address indexed _owner, address indexed _removedBy);
    event changeBook(string _isbn, address indexed _oldOwner, address indexed _newOwner, address indexed _changedBy);

    constructor() public {
        owner = msg.sender;
        librarians[owner] = true;
    }

    function addLibrarian(address _address) public onlyOwner() {
        librarians[_address] = true;
        emit AddLibrarian(_address);
    }

    function removeLibrarian(address _address) public onlyOwner() {
        require(librarians[_address]);
        librarians[_address] = false;
        emit RemoveLibrarian(_address);
    }

    function addBook(string _isbn, address _owner) public onlyLibrarian() {
        books[idBook] = book(_isbn, _owner);
        bookExists[idBook] = true;
        idBook += 1;
        emit AddBook(_isbn, _owner, msg.sender);
    }

    function removeBook(uint256 _idBook) public onlyLibrarian() {
        require(bookExists[_idBook]);
        bookExists[_idBook] = false;
        emit AddBook(books[_idBook].isbn, books[_idBook].owner, msg.sender);
    }

    function changeOwnerBook(uint256 _idBook, address _owner) public {
        require(bookExists[_idBook]);
        require(msg.sender == books[_idBook].owner || librarians[msg.sender]);
        emit changeBook(books[_idBook].isbn, books[_idBook].owner, _owner, msg.sender);
        books[_idBook].owner = _owner;
    }
}