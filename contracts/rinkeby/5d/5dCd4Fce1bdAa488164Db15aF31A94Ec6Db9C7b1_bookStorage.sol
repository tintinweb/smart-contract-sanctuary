/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity >=0.8.6 <0.8.7;

contract bookStorage {

    struct Book {
        string title;
        string text;
    }

    Book[] public books;
    
    mapping (string => string) public TitleToText;

    function _createBook(string memory _title, string memory _text) public {
        books.push(Book(_title, _text));
        TitleToText[_title] = _text;
    }

    function _readBook(string memory _title) public view returns (string memory) {
        return(TitleToText[_title]);
    }
    
    function _readAll() public view returns (Book[] memory) {
        return(books);
    }

}