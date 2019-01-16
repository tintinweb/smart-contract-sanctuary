pragma solidity ^0.4.24;

contract StringStorage {
    string storedString;

    constructor(string x) public payable {
		set(x);
	}

    function set(string x) public payable {
        storedString = x;
    }

    function get() public view returns (string) {
        return storedString;
    }
}