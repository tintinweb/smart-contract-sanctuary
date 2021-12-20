// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bookshelf {
  event AddBook(address recipient, uint bookId);
    event SetFinished(uint bookId, bool finished);

    struct Book {
      string name;
      uint year;
      string author;
      bool finished;
    }

    Book[] private bookList;
    mapping(uint256 => address) bookToOwner;

    function addBook(string memory name, uint16 year, string memory author, bool finished) external {
      bookList.push(Book(name, year, author, finished));
      uint bookId = bookList.length - 1;
      bookToOwner[bookId] = msg.sender;
      emit AddBook(msg.sender, bookId);
    }

    function _getBookList(bool finished) private view returns (Book[] memory) {
      Book[] memory temporary = new Book[](bookList.length);
      uint counter = 0;
      for (uint i = 0; i < bookList.length; i++) {
        if (bookToOwner[i] == msg.sender) {
          if (bookList[i].finished == finished) {
            temporary[counter] = bookList[i];
            counter++;
          }
        }
      }

      Book[] memory result = new Book[](counter);
      for (uint i = 0; i < counter; i++) {
        result[i] = temporary[i];
      }
      return result;
    }

    function getUnfinishedBooks() external view returns (Book[] memory) {
      return _getBookList(false);
    }

    function getFinishedBooks() external view returns (Book[] memory) {
      return _getBookList(true);
    }

    function setFinished(uint bookId, bool finished) external {
      if (bookToOwner[bookId] == msg.sender) {
        bookList[bookId].finished = finished;
        emit SetFinished(bookId, finished);
      }
    }
}