/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */


contract Owner {

    address private owner;

    struct tokenDetail {
        address contractAddress;
        string avatarUrl;
        string tokenName;
    }

    struct TokenChecker{
        tokenDetail detail;
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

    struct TokenReport{
        tokenDetail detail;
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
    }

    
    uint public numTokenCheckers;
    uint public numTokenReports;

    mapping (uint => TokenChecker) public TokenCheckers;
    mapping (uint => TokenReport) public TokenReports;

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

    function tokenData(
        tokenDetail memory detail, 
        uint ticker, uint price,
        uint confirmation, 
        uint status, 
        string memory network,
        string memory emailAddress, 
        string memory telegramGroup, 
        string memory textArea, 
        string memory projectOwner) public {
        
        TokenChecker storage tokenChecker = TokenCheckers[numTokenCheckers];

        tokenChecker.detail = detail;
        tokenChecker.ticker = ticker;
        tokenChecker.price = price;
        tokenChecker.confirmation = confirmation;
        tokenChecker.status = status;
        tokenChecker.network = network;
        tokenChecker.emailAddress = emailAddress;
        tokenChecker.telegramGroup = telegramGroup;
        tokenChecker.textArea = textArea;
        tokenChecker.projectOwner = projectOwner;
        
        numTokenCheckers ++;

    }

    function tokenReportData(
        tokenDetail memory detail,
        uint ticker, 
        uint price,
        uint confirmation, 
        uint status, 
        string memory network,
        address copyAddress, 
        string memory scam, 
        string memory textArea) public {
        
        TokenReport storage tokenReport = TokenReports[numTokenReports];
    
        tokenReport.detail = detail;
        tokenReport.ticker = ticker;
        tokenReport.price = price;
        tokenReport.confirmation = confirmation;
        tokenReport.status = status;
        tokenReport.network = network;
        tokenReport.copyAddress = copyAddress;
        tokenReport.scam = scam;
        tokenReport.textArea = textArea;

        numTokenReports ++;

    }

    function voteChecker(uint tokenIndex, uint8 voteValue) external{
        TokenChecker storage tokenChecker = TokenCheckers[tokenIndex];
        address voter = msg.sender;
        if(tokenChecker.votes[voter] == 0 )
        {
            tokenChecker.votes[voter] = voteValue;
            tokenChecker.voteCount++;
        }
    }   
    
    function getVoter(uint tokenIndex, address voter) public view returns(uint8) {
        TokenChecker storage tokenChecker = TokenCheckers[tokenIndex];
        return tokenChecker.votes[voter];
    }

}