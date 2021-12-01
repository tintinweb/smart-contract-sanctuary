/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity >=0.8.6 <0.8.7;

contract bookStorage {

    struct Book {
        string title;
        string img;
        string text;
        string date;
    }

    Book[] public books;
    

    function _createBook(string memory _title, string memory _img, string memory _text, string memory _date) public {
        books.push(Book(_title, _img, _text, _date));
    }
    
    function _deleteBook() public {
        delete books[books.length -1];
    }

    function _readAll() public view returns (Book[] memory) {
        return(books);
    }
    
   
    
    

}