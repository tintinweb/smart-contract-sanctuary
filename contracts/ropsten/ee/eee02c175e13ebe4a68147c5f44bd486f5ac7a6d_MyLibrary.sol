pragma solidity ^0.4.24;

contract MyLibrary  {
    
    /* Define variable greeting of the type string */
    string public nameOfLibrary;
    address public owner;
    uint8 currentBookNumber = 0; 
    struct Book {
        uint8 bookNumber;
        string nameOfBook;
        string author;
        address borrower;
        bool issued;
    }
    Book [] public AllBooks;
    mapping (address => uint256) public balanceOf;

    /* This runs when the contract is executed */
    constructor(string _msg) public {
        nameOfLibrary = _msg;
        owner = msg.sender;
    }
    
    function addBook(string _nameOfBook, string _author) public returns (bool _success) {
        require( msg.sender == owner, "Only owner can add books"); // allow only the owner of the library to add books
        Book memory _book;
        _book.bookNumber = currentBookNumber;
        _book.nameOfBook = _nameOfBook; 
        _book.author = _author;
        AllBooks.push(_book);
        currentBookNumber++; 
        return true;
    }

    function joinClub () public payable returns (bool success) {
        require (msg.value > 2,"please pay 2 ether to join");
        balanceOf[msg.sender] +=msg.value;
        return true;
    }
    
    function issueBook (uint8 _bookNumber) public returns (bool success){
        require(AllBooks[_bookNumber].borrower == 0x0, "book already issued" );
        if (balanceOf[msg.sender] <= 0) {
            return false;
        }
        AllBooks[_bookNumber].borrower = msg.sender;
        return true;
    }


    function finito () public payable {
        selfdestruct(owner);
        
    }

    event ListAllBooks( string _name, string _author); 
    
    function printListOfBooks() public {
        uint8  i ;
        for (i = 0 ; i < AllBooks.length; i++ )  { 
            emit ListAllBooks (AllBooks[i].nameOfBook, AllBooks[i].author);
        }
    } 
}