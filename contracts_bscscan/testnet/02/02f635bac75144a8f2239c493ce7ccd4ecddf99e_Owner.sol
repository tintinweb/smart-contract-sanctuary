/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        uint pageExchange;
        uint adExchange;
        string advertUrl;
        string linkUrl;
        uint256 startDate;
        uint256 endDate;
        bool deleteStatus;
    }

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

    uint[3] public advertPrice;
    uint public additionalPrice = 30; // 30%
    uint public discountForTally = 5; // 5%
    uint public burnRate = 2; // 2%;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public tallyPair;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    IBEP20 public tallyToken;
    
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
        advertPrice[0] = 15 * (10 ** 17);
        advertPrice[1] = 1 * (10 ** 18);
        advertPrice[2] = 5 * (10 ** 17);
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
        
        advertPrice[0] = _homeBannerPrice * 10 ** 10;
        advertPrice[1] = _tokenBannerPrice * 10 ** 10;
        advertPrice[2] = _smallAdvertPrice * 10 ** 10;
       
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
        uint _pageExchange,
        uint _adExchange,
        string memory _advertUrl,
        string memory _linkUrl,
        uint256 _startDate,
        uint256 _endDate,
        uint8 mode
        ) payable public {
        uint basePrice;

        if(_pageExchange == 0 && _adExchange == 0){
            basePrice =  advertPrice[0];
        } else if (_pageExchange != 0 && _adExchange == 0){
            basePrice = advertPrice[1];
        } else {
            basePrice = advertPrice[2];
        }
        
        uint period = (_endDate - _startDate) / (24*60*60*1000);
        if(period > 3)
        {
            period = period-3;
            basePrice = (100+additionalPrice*period)*basePrice/100;
        }
        if(address(tallyToken) != address(0))
        {
            uint256 tallyPriceForBnb = tallyToken.balanceOf(msg.sender)*100/getTallyRate();
            if(tallyPriceForBnb > 1200)
            {
                basePrice = basePrice*9/10;
            }
        }
        if(mode == 1)// pay with tallyToken
        {
            require(address(tallyToken)!=address(0),"Tally is not set."); 
            require(tallyToken.balanceOf(msg.sender) > basePrice,"Insufficient Funds."); 
            uint256 fiveOfbasePrice = 5 * basePrice / 100;
            basePrice = (100 - discountForTally) * basePrice / 100;
            basePrice = getTallyRate()*basePrice/(10**18);
            tallyToken.transferFrom(msg.sender, address(this), basePrice);
            tallyToken.transfer(deadAddress, basePrice*burnRate/100);//burnRate
            uint256 tallyPriceForBnb = tallyToken.balanceOf(msg.sender)*100/getTallyRate();
            if(tallyPriceForBnb > 1200)
            {                
                tallyToken.transfer(msg.sender, getTallyRate()*fiveOfbasePrice/(10**18));
            }
        }
        else
        {
            require(msg.value>=basePrice,"Invalid bnb value");
        }
        Advert storage advert = Adverts[numAdverts];
    
        advert.pageExchange = _pageExchange;
        advert.adExchange = _adExchange;
        advert.advertUrl = _advertUrl;
        advert.linkUrl = _linkUrl;
        advert.startDate = _startDate;
        advert.endDate = _endDate;
        advert.deleteStatus = true;

        numAdverts ++;

    }

    function updateDeleteStatus(uint tokenIndex, bool _deleteStatus) external{ //updatedeletestatus
        Advert storage advert = Adverts[tokenIndex];
        advert.deleteStatus = _deleteStatus;
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

    function updateTallytoken(IBEP20 _tally) external isOwner{
        tallyToken = _tally;
    }

    function updateAdditionalPrice(uint _additionalPrice) external isOwner{
        additionalPrice = _additionalPrice;
    }

    function updateDiscountForTally(uint _discountForTally) external isOwner{
        discountForTally = _discountForTally;
    } 

    function updateBurnRate(uint _burnRate) external isOwner{
        burnRate = _burnRate;
    }

    function updateTallyPair(address _tallyPair) external isOwner{
        tallyPair = _tallyPair;
    }

    function withdrawBnb() external isOwner{
        payable(owner).transfer(payable(address(this)).balance);
    }

    function withdrawTally() external isOwner{
        tallyToken.transfer(owner, tallyToken.balanceOf(address(this)));
    }

    function getTallyRate() internal view returns(uint256){
        uint256 tallyBlance = tallyToken.balanceOf(tallyPair);
        uint256 bnbBlance = payable(tallyPair).balance;
        return tallyBlance*(10**18)/bnbBlance;
    }
}