pragma solidity ^0.5.1;

library Structures {
    struct Book {
        string name;
        string description;
        int32 year;
    }
}

contract EBibliography {
    mapping (string => string) basic_data;
    address owner;

    Structures.Book[] public books;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
    	require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    // ====== ADD NEW ======
    function setBasicData (string memory key, string memory value) public onlyOwner() {
        basic_data[key] = value;
    }

    // ======= GET DATA =======
    function getBasicData (string memory key) public view returns (string memory) {
        return basic_data[key];
    }

    function addBook (string memory name, string memory description, int32 year) public onlyOwner() {
        books.push(Structures.Book(name, description, year));
    }
}