/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract LoanFactory {
    address[] public deployedLoanRequests;

    function createLoanRequest(string memory title, uint target, uint interest, string memory description, string[] memory images, uint months) public {
        address newLoanRequest = address(new LoanRequest(title, target, interest, description, images, months, msg.sender));
        deployedLoanRequests.push(newLoanRequest);
    }
}

contract LoanRequest {

    //the owner of the loan
    address public manager;

    uint public contributors;
    mapping(address => uint) public contributorOwed;
    mapping(uint => address) public contributorId;

    //the goal which has to be reached to get the funds withdrawn from the contract
    uint public target;

    //amount of eth(in wei) already collected
    uint public collected;
    //amount of eth(in wei) already repayed
    uint public repayed;

    //amount owed
    uint public debt;

    // % of APY offered by the borrower
    uint public interest;

    string public title;
    string public description;

    //the number of months the borrower has commited to repay in
    uint public months;
    string[] public images;

    //to prevent people to contribute more than the target amount

    bool public fundsWithdrawn;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(string memory _title, uint _target, uint _interest, string memory _description, string[] memory _images, uint _months, address creator ) {
        target=_target;
        title=_title;
        interest=_interest;
        description=_description;
        months=_months;
        images=_images;
        manager=creator;
        debt = _target;
    }

    function contribute() public payable{
        require(msg.value <= target - collected);
        require(contributorOwed[msg.sender] == 0);
        contributorOwed[msg.sender] = msg.value;
        collected = collected + msg.value;
        contributors++;
        contributorId[contributors] = msg.sender;
    }

    function withdraw() public payable restricted {
        require(collected == target);
        payable(manager).transfer(target);
        fundsWithdrawn = true;
    }


    function getDetails() public view returns(address, string memory, string memory, string[] memory, uint, uint, uint, uint, uint, uint, uint, bool){
        return(
            manager,
            title,
            description,
            images,
            months,
            contributors,
            target,
            collected,
            repayed,
            debt,
            interest,
            fundsWithdrawn
        );
    }

    function repay(address wallet) public payable restricted {
        require(msg.value == contributorOwed[wallet]);
        payable(wallet).transfer(msg.value);
        repayed = repayed + msg.value;
    }
}