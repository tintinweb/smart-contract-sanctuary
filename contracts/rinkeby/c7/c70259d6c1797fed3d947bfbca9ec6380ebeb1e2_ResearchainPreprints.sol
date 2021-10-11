/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.6.0;

contract ResearchainPreprints{
    address private owner;
    
    struct article {
        string title;
        string authors;
        string ipfs;
        string date;
        uint time;
        string hash;
    }
    
    mapping(uint => article) public articles;
    mapping(uint => bool) private articleExists;
    uint public number;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function mint(string memory _title, string memory _authors, string memory _ipfs, string memory _date, string memory _hash) public onlyOwner {
        require(!articleExists[number], "This number has already represented an article, feel free to contact Researchain to change a number.");
        articles[number].title = _title;
        articles[number].authors = _authors;
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
}