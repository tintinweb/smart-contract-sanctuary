/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity >=0.5.0;

contract Main {
    address public owner;
    address public toAddress;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setToAddress(address newToAddress) public onlyOwner {
        toAddress = newToAddress;
    }
}