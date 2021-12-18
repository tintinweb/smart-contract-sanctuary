/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */


contract Owner {

    address private owner;

    struct TokenChecker{
        address contractAddress;
        string avatarUrl;
        string tokenName;
        uint percentage;
        uint price;
        uint confirmation;
        uint voteCount;
        uint status;
        string network;
        string emailAddress;
        string telegramGroup;
        string textArea;
        uint ticker;
        string projectOwner;
        mapping(address => uint8) votes;
    }


    struct Member {
        TokenChecker tokenChecker;
    }

    struct TokenReport{
        address contractAddress;
        string avatarUrl;
        string tokenName;
        uint percentage;
        uint price;
        uint confirmation;
        uint voteCount;
        uint status;
        string network;
        address copyAddress;
        string scam;
        string textArea;
        uint ticker;
        mapping(address => uint8) votes;
    }

    struct MemberReport {
        TokenReport tokenReport;
    }

    mapping(uint => Member) members;
    mapping(uint => MemberReport) memberReports;

    uint public numTokenCheckers;
    uint public numTokenReports;


    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
 * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function tokenData(address contractAddress, string memory avatarUrl,
        string memory tokenName, uint ticker, uint price,
        uint status, string memory network,
        string memory emailAddress, string memory telegramGroup,
        string memory textArea, string memory projectOwner) public {

        members[numTokenCheckers].tokenChecker.contractAddress = contractAddress;
        members[numTokenCheckers].tokenChecker.avatarUrl = avatarUrl;
        members[numTokenCheckers].tokenChecker.tokenName = tokenName;
        members[numTokenCheckers].tokenChecker.ticker = ticker;
        members[numTokenCheckers].tokenChecker.price = price;
        members[numTokenCheckers].tokenChecker.status = status;
        members[numTokenCheckers].tokenChecker.network = network;
        members[numTokenCheckers].tokenChecker.emailAddress = emailAddress;
        members[numTokenCheckers].tokenChecker.telegramGroup = telegramGroup;
        members[numTokenCheckers].tokenChecker.textArea = textArea;
        members[numTokenCheckers].tokenChecker.projectOwner = projectOwner;

        numTokenCheckers ++;

    }

    function tokenReportData(address contractAddress, string memory avatarUrl,
        string memory tokenName, uint ticker, uint price,
        uint confirmation, uint status, string memory network,
        address copyAddress, string memory scam, string memory textArea) public {

        memberReports[numTokenReports].tokenReport.contractAddress = contractAddress;
        memberReports[numTokenReports].tokenReport.avatarUrl = avatarUrl;
        memberReports[numTokenReports].tokenReport.tokenName = tokenName;
        memberReports[numTokenReports].tokenReport.ticker = ticker;
        memberReports[numTokenReports].tokenReport.price = price;
        memberReports[numTokenReports].tokenReport.confirmation = confirmation;
        memberReports[numTokenReports].tokenReport.status = status;
        memberReports[numTokenReports].tokenReport.network = network;
        memberReports[numTokenReports].tokenReport.copyAddress = copyAddress;
        memberReports[numTokenReports].tokenReport.scam = scam;
        memberReports[numTokenReports].tokenReport.textArea = textArea;

        numTokenReports ++;

    }

    function voteChecker(uint tokenIndex, uint8 voteValue) external{
        address voter = msg.sender;
        if(members[tokenIndex].tokenChecker.votes[address(voter)] == 0 )
        {
            members[tokenIndex].tokenChecker.votes[voter] = voteValue;
            members[tokenIndex].tokenChecker.voteCount++;
        }
    }


    function getVoter(uint tokenIndex, address voter) public view returns(uint8) {
        return members[tokenIndex].tokenChecker.votes[voter];
    }

}