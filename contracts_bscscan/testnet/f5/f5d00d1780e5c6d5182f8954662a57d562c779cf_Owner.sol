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

    struct tokenDetail {
        address contractAddress;
        string avatarUrl;
        string tokenName;
    }

    struct tokenChecker{
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

    // mapping(uint => mapping(address => uint8)) rvotes;

    // struct tokenReport{
    //     address contractAddress;
    //     string avatarUrl;
    //     string tokenName;
    //     uint percentage;
    //     uint price;
    //     uint confirmation;
    //     uint voteCount;
    //     uint status;
    //     string network;
    //     address copyAddress;
    //     string scam;
    //     string textArea;
    //     uint ticker;
    // }

    
    uint public numTokenCheckers;
    uint public numTokenReports;

    mapping (uint => tokenChecker) public tokenCheckers;
    // mapping (uint => tokenReport) public tokenReports;

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

    function tokenData(tokenDetail memory detail, uint ticker, uint price,
            uint confirmation, uint status, string memory network,
            string memory emailAddress, string memory telegramGroup, 
            string memory textArea, string memory projectOwner) public {
        
        tokenChecker storage tokenchecker = tokenCheckers[numTokenCheckers];

        tokenchecker.detail = detail;
        tokenchecker.ticker = ticker;
        tokenchecker.price = price;
        tokenchecker.confirmation = confirmation;
        tokenchecker.status = status;
        tokenchecker.network = network;
        tokenchecker.emailAddress = emailAddress;
        tokenchecker.telegramGroup = telegramGroup;
        tokenchecker.textArea = textArea;
        tokenchecker.projectOwner = projectOwner;
        
        numTokenCheckers ++;

    }

    // function tokenReportData(address contractAddress, string memory avatarUrl, 
    //         string memory tokenName, uint ticker, uint price,
    //         uint confirmation, uint status, string memory network,
    //         address copyAddress, string memory scam, string memory textArea) public {
        
    //     tokenReport storage tokenreport = tokenReports[numTokenReports];
    
    //     tokenreport.contractAddress = contractAddress;
    //     tokenreport.avatarUrl = avatarUrl;
    //     tokenreport.tokenName = tokenName;
    //     tokenreport.ticker = ticker;
    //     tokenreport.price = price;
    //     tokenreport.confirmation = confirmation;
    //     tokenreport.status = status;
    //     tokenreport.network = network;
    //     tokenreport.copyAddress = copyAddress;
    //     tokenreport.scam = scam;
    //     tokenreport.textArea = textArea;

    //     numTokenReports ++;

    // }

    function voteChecker(uint tokenIndex, uint8 voteValue) external{
        tokenChecker storage tokenchecker = tokenCheckers[tokenIndex];
        address voter = msg.sender;
        if(tokenchecker.votes[voter] == 0 )
        {
            tokenchecker.votes[voter] = voteValue;
            tokenchecker.voteCount++;
        }
    }   
    
    function getVoter(uint tokenIndex, address voter) public view returns(uint8) {
        tokenChecker storage tokenchecker = tokenCheckers[tokenIndex];
        return tokenchecker.votes[voter];
    }

}