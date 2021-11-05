/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

pragma solidity >=0.7.0 <0.9.0;

contract BookContract {
    
    string public name = "for test";
    mapping(uint256 => string) public names;
    mapping(address => mapping(uint256 => book)) public getBooks;

    struct book {
        string title;
        string author;
    }
    
    function addBook (uint256 _id, string memory _title, string memory _author) public {
        getBooks[msg.sender][_id] = book(_title, _author);
    }
    
    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
    
}