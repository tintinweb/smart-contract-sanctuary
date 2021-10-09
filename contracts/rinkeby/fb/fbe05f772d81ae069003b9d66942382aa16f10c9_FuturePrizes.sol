/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract FuturePrizes {
    struct Project {
        string name;
        address treasurer;
        address bidder;
        uint reserve;
        uint bid;
        bool funded;
    }

    mapping (uint => Project) public projects;
    uint public numProjects;
    mapping (address => uint) public refunds;
    bool public auctionLive;
    uint public prizeAmount;

    constructor() {}

    function setAuctionLive(bool _auctionLive) external {
        auctionLive = _auctionLive;
    }

    function createProject(string calldata _name, address _treasurer, uint _reserve) external {
        Project storage project = projects[numProjects++];
        project.name = _name;
        project.treasurer = _treasurer;
        project.reserve = _reserve;
    }

    function bid(uint _projectId) external payable {
        require(auctionLive);
        Project storage project = projects[_projectId];
        require(project.treasurer != address(0));
        require(msg.value >= project.reserve);
        require(msg.value > project.bid);
        prizeAmount += msg.value - (project.bid > project.reserve ? project.bid : project.reserve);
        refunds[project.bidder] += project.bid;
        project.bidder = msg.sender;
        project.bid = msg.value;
    }

    function refund(address payable _refundee) external {
        uint refundAmount = refunds[_refundee];
        delete refunds[_refundee];
        _refundee.call{value: refundAmount}("");
    }

    function fundProject(uint _projectId) external {
        Project storage project = projects[_projectId];
        uint reserve = project.reserve;
        require(!project.funded);
        require(project.bid >= reserve);
        project.funded = true;
        payable(project.treasurer).call{value: reserve}("");
    }

    function awardPrize(uint _projectId, uint _awardAmount) external {
        require(prizeAmount >= _awardAmount);
        prizeAmount -= _awardAmount;
        Project storage project = projects[_projectId];
        payable(project.bidder).call{value: _awardAmount}("");
    }
}