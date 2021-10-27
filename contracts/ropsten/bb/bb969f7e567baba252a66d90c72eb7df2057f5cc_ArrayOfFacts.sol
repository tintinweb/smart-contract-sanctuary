/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity >= 0.4.22 < 0.7.0;

contract ArrayOfFacts {
    string[] private facts;
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only contract owner can do this!');
        _;
    }

    function add(string memory fact) public onlyOwner {
        facts.push(fact);
    }

    function count() public view returns (uint256 factCount) {
        return facts.length;
    }

    function getFact(uint256 index) public view returns (string memory fact) {
        return facts[index];
    }
}