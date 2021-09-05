pragma solidity 0.8.6;
//SPDX-License-Identifier: No License

import "./SafeMath.sol";

contract Contributions {
    using SafeMath for uint256;

    uint256 public MAX_CONTRIBUTION = 10 ether;
    uint256 public holders = 0;
    address public owner;
    bool public isWithdrawingAllowed = false;

    mapping(address => uint256) public contributions;
    mapping(address => bool) public eligibleContributors;
    mapping(address => bool) public eligibleForWithdrawing;

    constructor() {
        owner = msg.sender;
        eligibleContributors[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier onlyEligibleContributor() {
        require(
            eligibleContributors[msg.sender],
            "Not eligible for contributions"
        );
        _;
    }

    function toggleWithdrawing() public onlyOwner {
        isWithdrawingAllowed = !isWithdrawingAllowed;
    }

    function withdraw() public onlyEligibleContributor {
        require(contributions[msg.sender] > 0, "No funds available");
        require(holders > 0, "No holders available");
        require(isWithdrawingAllowed, "Withdrawing not allowed yet");
        require(
            eligibleForWithdrawing[msg.sender],
            "Not eligible for withdrawing"
        );
        eligibleForWithdrawing[msg.sender] = false;
        contributions[msg.sender] = 0;
        uint256 totalSupply = address(this).balance;
        uint256 amountToTransfer = totalSupply.div(holders);
        holders = holders.sub(1);
        payable(msg.sender).transfer(amountToTransfer);
    }

    function contribute() public payable onlyEligibleContributor {
        require(msg.value > 0, "Must send funds");
        require(!isWithdrawingAllowed, "Contribution phase over");
        uint256 updatedContributions = contributions[msg.sender].add(msg.value);
        require(
            updatedContributions <= MAX_CONTRIBUTION,
            "Balance would go above maximum contribution"
        );
        if (!(contributions[msg.sender] > 0)) {
            holders = holders.add(1);
        }
        contributions[msg.sender] = updatedContributions;
        eligibleForWithdrawing[msg.sender] = true;
    }

    function setMaximumContribution(uint256 newMaximumContribution)
        public
        onlyOwner
    {
        MAX_CONTRIBUTION = newMaximumContribution;
    }

    function addEligibleContributor(address account) public onlyOwner {
        eligibleContributors[account] = true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}