/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: NONE
pragma solidity >=0.7.0 <0.9.0;

contract Library {

    // Xây dựng thư viện trên blockchain
    uint private bookCount = 0;
    address public owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    string private managerName = 'Duy';
    mapping (uint => Book) public books;
     

    // Thông tin sách
    struct Book{
        string title;
        string author;
    }
    
    // Lấy thông tin manager của thư viện
    function getManager() public view returns(string memory){
        return managerName;
    }
    
    // Thay đổi thông tin manager của thư viện
    function setManager(string memory _newManager) public {
        // Chỉ owner mới có quyền assign manager mới
        require(msg.sender == owner, 'Guest cannot update manager name');
        managerName = _newManager;
    }
    
    // Lấy số lượng sách hiện có trong thư viện
    function getBookCount() public view returns(uint){
        return bookCount;
    }
    
    // Thêm 1 quyển sách vào thư viện
    function addNewBook(string memory _author, string memory _title) public {
        books[bookCount] = Book(_title, _author);
        bookCount++;
    }
}