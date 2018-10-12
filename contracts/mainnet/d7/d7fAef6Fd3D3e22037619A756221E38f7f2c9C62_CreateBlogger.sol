pragma solidity ^0.4.20;

contract CreateBlogger {
    address [] public deployedBlogs;

    function createBlogger() public returns(address) {
        address newBlogger = new Blogger(msg.sender);
        deployedBlogs.push(newBlogger);
        return newBlogger;
    }

    function getDeployedBlogs() public view returns(address[]) {
        return deployedBlogs;
    }
}


contract Blogger {

    address public author;
    uint public donationCount;
    uint public withdrawalDate;


    struct Donate {
        address funder;
        uint value;
    }
    mapping(address => bool) public didGive;
    mapping(address => Donate) public donationRecords;


    modifier restricted() {
        require (msg.sender == author);
        _;
    }

    constructor (address sender) public {
        author = sender;
        donationCount = 0;
        withdrawalDate = now + 30 days;
    }

    function donate() public payable {
        donationCount ++;
        didGive[msg.sender] = true;

        Donate memory newDonation = Donate({
            funder: msg.sender,
            value: msg.value
        });
        donationRecords[msg.sender] = newDonation;

    }

    function requestRefund() public {
        require(didGive[msg.sender]);
        Donate storage record = donationRecords[msg.sender];

        require(record.funder == msg.sender);
        record.funder.transfer(record.value);

        didGive[msg.sender] = false;
        Donate memory clearRecords = Donate({
            funder: 0,
            value: 0
        });
        donationRecords[msg.sender] = clearRecords;
    }

    function withdraw() public restricted {
        require(withdrawalDate < now);

        author.transfer(address(this).balance);
        withdrawalDate = now + 30 days;

    }

    function getContractValue() public view returns(uint) {
        return address(this).balance;
    }

    function getSummary() public view returns (address, uint, uint, uint) {
        return (
            author,
            donationCount,
            withdrawalDate,
            address(this).balance
            );
    }
}