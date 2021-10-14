/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity 0.8.0;

contract Wallet {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() payable {
        require(msg.value == 0.01 ether);
        owner = msg.sender;
    }

    function withdraw(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    function setOwner() public {
        owner = msg.sender;
    }
}