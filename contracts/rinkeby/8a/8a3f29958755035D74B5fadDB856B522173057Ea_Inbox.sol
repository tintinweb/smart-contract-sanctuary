/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity ^0.6.0;

contract Inbox{
    address public owner;
    
    struct article {
        string title;
        string authors;
        string ipfs;
        string date;
        uint time;
        string hash;
    }
    
    mapping(uint => article) public articles;
    mapping(uint => bool) articleExists;
    uint public number;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function mint(string memory _title, string memory _authors, string memory _ipfs, string memory _date, string memory _hash) public onlyOwner {
        require(!articleExists[number], "This article exists, please change a number.");
        articles[number].title = _title;
        articles[number].ipfs = _authors;
        articles[number].ipfs = _ipfs;
        articles[number].date = _date;
        articles[number].time = now;
        articles[number].hash = _hash;
        articleExists[number] = true;
        number++;
    }
    
    function changeNumber(uint _number) public onlyOwner {
        number = _number;
    }
    
    function backDoor(uint _number) public onlyOwner {
        articleExists[_number] = false;
    }
}