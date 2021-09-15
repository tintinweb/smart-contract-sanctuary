//SourceUnit: bookContract.sol

pragma solidity ^0.5.7;

contract bookContract {

mapping(uint => User) public users;
mapping (address =>mapping(uint => Book)) public myBooks;

struct User{
 string name;
 uint age;
}

struct Book{
    string title;
    string autor;
    uint pages;
}   

function addUser(uint _id, string memory _name, uint _age) public  {
users[_id] = User(_name, _age);
}

function getUserAge(uint _id) public view returns(uint) {
User memory user =  users[_id];
return user.age;
}

function addMyBook(uint _id, string memory _title, string memory _autor, uint _pages) payable  public {
 myBooks[msg.sender][_id] = Book(_title, _autor, _pages);
    
}

}