/**
 *Submitted for verification at BscScan.com on 2021-12-22
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
        mapping(address => uint8) votesAdd;
        mapping(address => uint8) votesMinus;
    }

    struct TokenCertified{
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
        mapping(address => uint8) votesAdd;
        mapping(address => uint8) votesMinus;
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
        mapping(address => uint8) votesAdd;
        mapping(address => uint8) votesMinus;
    }

    struct Doxxed{
        string projectName;
        string tokenName;
        uint ticker;
        string network;
        address contractAddress;
        string RPNum;
        string emailAddress;
        string avatarUrl;
    }

    struct Advert{
        string pageExchange;
        string adExchange;
        string advertUrl;
        uint256 startDate;
        uint256 endDate;
    }

    // struct advertPrice{
    //     uint homeBannerPrice;
    //     uint tokenBannerPrice;
    //     uint smallAdvertPrice;
    // }
    
    uint public numTokenCheckers;
    uint public numTokenCertifieds;
    uint public numTokenReports;
    uint public numDoxxeds;
    uint public numAdverts;

    mapping (uint => TokenChecker) public TokenCheckers;
    mapping (uint => TokenCertified) public TokenCertifieds;
    mapping (uint => TokenReport) public TokenReports;
    mapping (uint => Doxxed) public Doxxeds;
    mapping (uint => Advert) public Adverts;

    mapping (string => uint) public advertPrice;


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
        advertPrice["homeBannerPrice"] = 15 * 10 ** 17;
        advertPrice["tokenBannerPrice"] = 1 * 10 ** 18;
        advertPrice["smallAdvertPrice"] = 5 * 10 ** 17;
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

    function setPrice(
        uint _homeBannerPrice,
        uint _tokenBannerPrice,
        uint _smallAdvertPrice) public {
        
        advertPrice["homeBannerPrice"] = _homeBannerPrice;
        advertPrice["tokenBannerPrice"] = _tokenBannerPrice;
        advertPrice["smallAdvertPrice"] = _smallAdvertPrice;
       
    }

    function tokenData(
        tokenDetail memory _detail, 
        uint _ticker, 
        uint _price,
        uint _confirmation, 
        uint _status, 
        string memory _network,
        string memory _emailAddress, 
        string memory _telegramGroup, 
        string memory _textArea, 
        string memory _projectOwner) public {
        
        TokenChecker storage tokenChecker = TokenCheckers[numTokenCheckers];

        tokenChecker.detail = _detail;
        tokenChecker.ticker = _ticker;
        tokenChecker.price = _price;
        tokenChecker.confirmation = _confirmation;
        tokenChecker.status = _status;
        tokenChecker.network = _network;
        tokenChecker.emailAddress = _emailAddress;
        tokenChecker.telegramGroup = _telegramGroup;
        tokenChecker.textArea = _textArea;
        tokenChecker.projectOwner = _projectOwner;
        
        numTokenCheckers ++;

    }

    function tokenCertifiedData(
        tokenDetail memory _detail, 
        uint _ticker, 
        uint _price,
        uint _confirmation, 
        uint _status, 
        string memory _network,
        string memory _emailAddress, 
        string memory _telegramGroup, 
        string memory _textArea, 
        string memory _projectOwner) public {
        
        TokenCertified storage certified = TokenCertifieds[numTokenCertifieds];

        certified.detail = _detail;
        certified.ticker = _ticker;
        certified.price = _price;
        certified.confirmation = _confirmation;
        certified.status = _status;
        certified.network = _network;
        certified.emailAddress = _emailAddress;
        certified.telegramGroup = _telegramGroup;
        certified.textArea = _textArea;
        certified.projectOwner = _projectOwner;
        
        numTokenCertifieds ++;

    }

    function tokenReportData(
        tokenDetail memory _detail,
        uint _ticker, 
        uint _price,
        uint _confirmation, 
        uint _status, 
        string memory _network,
        address _copyAddress, 
        string memory _scam, 
        string memory _textArea) public {
        
        TokenReport storage tokenReport = TokenReports[numTokenReports];
    
        tokenReport.detail = _detail;
        tokenReport.ticker = _ticker;
        tokenReport.price = _price;
        tokenReport.confirmation = _confirmation;
        tokenReport.status = _status;
        tokenReport.network = _network;
        tokenReport.copyAddress = _copyAddress;
        tokenReport.scam = _scam;
        tokenReport.textArea = _textArea;

        numTokenReports ++;

    }

    function tokenDoxxed(
        string memory _projectName,
        string memory _tokenName,
        uint _ticker,
        string memory _network,
        address _contractAddress,
        string memory _RPNum,
        string memory _emailAddress,
        string memory _avatarUrl) public {
        
        Doxxed storage doxxed = Doxxeds[numDoxxeds];
    
        doxxed.projectName = _projectName;
        doxxed.tokenName = _tokenName;
        doxxed.ticker = _ticker;
        doxxed.network = _network;
        doxxed.contractAddress = _contractAddress;
        doxxed.RPNum = _RPNum;
        doxxed.emailAddress = _emailAddress;
        doxxed.avatarUrl = _avatarUrl;

        numDoxxeds ++;

    }

    function advertData(
        string memory _pageExchange,
        string memory _adExchange,
        string memory _advertUrl,
        uint256 _startDate,
        uint256 _endDate
        ) public {
        
        Advert storage advert = Adverts[numAdverts];
    
        advert.pageExchange = _pageExchange;
        advert.adExchange = _adExchange;
        advert.advertUrl = _advertUrl;
        advert.startDate = _startDate;
        advert.endDate = _endDate;

        numAdverts ++;

    }

    function voteCheckerAdd(uint tokenIndex, uint8 voteValue) external{ //token checker
        TokenChecker storage tokenChecker = TokenCheckers[tokenIndex];
        address voter = msg.sender;
        if(tokenChecker.votesAdd[voter] == 0 )
        {
            tokenChecker.votesAdd[voter] = voteValue;
            tokenChecker.voteCount++;
        }
    }   
    
    // function getVoter(uint tokenIndex, address voter) public view returns(uint8) {
    //     TokenChecker storage tokenChecker = TokenCheckers[tokenIndex];
    //     return tokenChecker.votes[voter];
    // }

    function voteCheckerMinus(uint tokenIndex, uint8 voteValue) external{  //tokenchecker
        TokenChecker storage tokenChecker = TokenCheckers[tokenIndex];
        address voter = msg.sender;
        if(tokenChecker.votesMinus[voter] == 0 )
        {
            tokenChecker.votesMinus[voter] = voteValue;
            tokenChecker.voteCount--;
        }
    }

    function voteCertifiedAdd(uint tokenIndex, uint8 voteValue) external{ //certified
        TokenCertified storage certified = TokenCertifieds[tokenIndex];
        address voter = msg.sender;
        if(certified.votesAdd[voter] == 0 )
        {
            certified.votesAdd[voter] = voteValue;
            certified.voteCount++;
        }
    }   

    function voteCertifiedMinus(uint tokenIndex, uint8 voteValue) external{  //certified
        TokenCertified storage certified = TokenCertifieds[tokenIndex];
        address voter = msg.sender;
        if(certified.votesMinus[voter] == 0 )
        {
            certified.votesMinus[voter] = voteValue;
            certified.voteCount--;
        }
    } 

    function voteScamAdd(uint tokenIndex, uint8 voteValue) external{ //scam
        TokenReport storage tokenReport = TokenReports[tokenIndex];
        address voter = msg.sender;
        if(tokenReport.votesAdd[voter] == 0 )
        {
            tokenReport.votesAdd[voter] = voteValue;
            tokenReport.voteCount++;
        }
    }   

    function voteScamMinus(uint tokenIndex, uint8 voteValue) external{  //scam
        TokenReport storage tokenReport = TokenReports[tokenIndex];
        address voter = msg.sender;
        if(tokenReport.votesMinus[voter] == 0 )
        {
            tokenReport.votesMinus[voter] = voteValue;
            tokenReport.voteCount--;
        }
    } 


}