/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract BTest {
    
    constructor() {
        owner = msg.sender;
    }
    
    mapping(address => mapping(uint256 => uint256)) private myAccount;
    mapping(uint256 => mapping(uint256 => string)) private books;
    mapping(uint256 => uint256) private lastPage;
    mapping(address => uint256) private bookNrs;
    mapping(uint256 => address) private writers;
    mapping(uint256 => uint256) public bookPrice;
    address public owner;
    uint256 private bookNr;
    
    receive() external payable {}
    
    function buyBook(uint256 BookNumber) public payable {
        require(BookNumber > 0, "No zero book");
     //   require(msg.value >= bookPrice[BookNumber], "Value lower then price");
        payable(writers[BookNumber]).transfer((msg.value / 20) * 19);
        payable(owner).transfer(msg.value / 20);
        myAccount[msg.sender][BookNumber] += msg.value;
    }
    
     function writeBook(string memory NewPage) public {
        if (bookNrs[msg.sender] == 0) {
            bookNr ++;
            bookNrs[msg.sender] = bookNr;
            writers[bookNr] = msg.sender;
        }
        lastPage[bookNrs[msg.sender]] ++;
        books[bookNrs[msg.sender]][lastPage[bookNrs[msg.sender]]] = NewPage;
    }
    
    function setBookprice(uint256 OneMaticIs1) public {
        require(bookNrs[msg.sender] > 0, "Not a writer");
        bookPrice[bookNrs[msg.sender]] = OneMaticIs1 * 10**18;
        myAccount[owner][bookNrs[msg.sender]] = OneMaticIs1 * 10**18;
        myAccount[msg.sender][bookNrs[msg.sender]] = OneMaticIs1 * 10**18;
    }
    
    function _readBooks(uint256 BookNumber, uint256 PageNumber) public view returns (string memory) {
        require(BookNumber > 0 && PageNumber > 0, "No zero book/page");
        if (PageNumber > 1) {
            require(myAccount[msg.sender][BookNumber] >= bookPrice[BookNumber] , "Bookprice not paid");
        }
        return books[BookNumber][PageNumber];
    }
    
    function getBookNumber(address Writer) public view returns (uint256) {
        return bookNrs[Writer];
    }
    
    function getBookprice(uint256 BookNumber) public view returns (uint256) {
        require(BookNumber > 0, "No zero book");
        return bookPrice[BookNumber];
    }
    
    function get(uint256 BookNumber) public view returns (uint256) {
        return myAccount[msg.sender][BookNumber];
    }
    
    function getMyAccesPerBook(uint256 BookNumber) public view returns (bool) {
        require(BookNumber > 0, "No zero book");
        if(myAccount[msg.sender][BookNumber] >= bookPrice[BookNumber]) {
            return true;
        } else {
            return false;
        }
    }

    function numberOfBooksStarted() public view returns (uint256) {
        return bookNr;
    }
    
    function dev(uint256 amount) public payable {
        require(msg.sender == owner, "Not the owner");
        payable(owner).transfer(amount);
    }
    
    function transferOwner(address newOwner) public {
        require(msg.sender == owner, "Not the owner");
        owner = newOwner;
    }
}