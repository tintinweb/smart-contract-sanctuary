/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/* SPDX-License-Identifier: Unlicensed */
/*
Private Sale Contract
*/
pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    mapping(address => bool) private _admin;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        _admin[_owner] = true;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function isAdminCheck(address addressToCheck) external view returns (bool) {
        return _admin[addressToCheck];
    } 

    function setAdmin(address addressToSet) external returns (string memory, address, bool) {
        _admin[addressToSet] = true;
        return("Admin status", addressToSet, _admin[addressToSet]);
    }

    function removeAdmin(address addressToRemove) external returns (string memory, address, bool) {
        _admin[addressToRemove] = false;
        return("Admin status", addressToRemove, _admin[addressToRemove]);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "You are not the Owner!");
        _;
    }

    modifier onlyAdmin() {
        require(_admin[_msgSender()], "You are not an Admin!");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address _transferAddress) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _transferAddress);
        _owner = _transferAddress;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract PrivateSale is Context, Ownable {
    struct Sale {
        uint256 saleID;
        address investor;
        uint256 tokenSaleDecimalCount;
        address tokenPurchased;
        address tokenContributed;
        uint256 purchased;
        bool claimed;
        uint256 nextClaim;
        uint256 saleStartTime;
        uint256 saleEndTime;
        bool isInvestor;
    }

    Sale[] public sales;
    mapping(address => bool) public investors;
    mapping(address => mapping(address => Sale)) public investorPurchased;
    uint256 public nextSaleID;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public price;
    uint256 public tokenForSaleDecimalCount;
    address public tokenForSale;
    address public tokenForContribution;
    uint256 public availableTokens;
    uint256 public contributionAmount;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public softCap;
    uint256 public hardCap;
    bool public released = true;
    bool public claimeEnabled = false;
    bool public allInvestorsAllowed = false;
    string public name = "DSCAPE Sale!";
    event Origin(address indexed from, address indexed to, uint256 value);
    event VestingClaimed(address indexed tokenForSale, address indexed from, uint256 value);
    event TokenBought(address indexed tokenForSale, address indexed from, uint256 value);
    event AllTokensReleased(address indexed tokenAddress);
    event ContractWithdrawal(string msg);
    
    constructor() {
       emit Origin(address(0), _msgSender(), 0);
    }
    
    modifier saleActive() {
        require(
            (endTime > 0 && block.timestamp < endTime && availableTokens > 0 && contributionAmount < hardCap) || (endTime > 0 && availableTokens > 0 && contributionAmount < softCap), 
            "Sale is not active!");
        _;
    }
    
    modifier saleNotActive() {
        require((endTime != 0 && endTime <= block.timestamp) || released, 'Sale is already active!');
        _;
    }
    
    modifier saleEnded() {
        require(endTime > 0 && (block.timestamp >= endTime || availableTokens == 0), 'Sale has not ended!');
        tokenForSaleDecimalCount = 0;
        _;
    }
    
    modifier tokensNotReleased() {
        require(released == false, 'Tokens already released!');
        _;
    }
    
    modifier tokensReleased() {
        require(released == true, 'Tokens have not been released!');
        _;
    }
    
    modifier onlyInvestors() {
        require(investors[_msgSender()] == true || allInvestorsAllowed, 'Only investors!');
        _;
    }    
    
    modifier eligibleClaim(address _tokenAddressSale) {
        address sender = _msgSender();
        require(investorPurchased[_tokenAddressSale][sender].isInvestor, 'You are not eligible to claim!');
        bool investorClaimed = investorPurchased[_tokenAddressSale][sender].claimed;
        require(!investorClaimed, 'Tokens already claimed!');
        _;
    }
    
    function addWhitelist(address _investor) external onlyAdmin() {
        investors[_investor] = true;
    }    
    
    function removeWhitelist(address _investor) external onlyAdmin() {
        investors[_investor] = false;
    }      
    
    function addWhitelistGroup(address[] memory _investors) external onlyAdmin() {
    require(_investors.length > 1, "Enter more than 1 investor!");
    for(uint index = 0; index < _investors.length; index++) {
        address currentInvestor = _investors[index];
        investors[currentInvestor] = true;
    }
    }    
    
    function removeWhitelistGroup(address[] memory _investors) external onlyAdmin() {
    require(_investors.length > 1, "Enter more than 1 investor!");
    for(uint index = 0; index < _investors.length; index++) {
        address currentInvestor = _investors[index];
        investors[currentInvestor] = false;
    }
    }

    function allowAllInvestors(bool isAllAllowed) external onlyAdmin() {
        allInvestorsAllowed = isAllAllowed;    
    }    
 
// admin functions     
    function updateSaleName(string calldata _saleName) external onlyAdmin() {
        name = _saleName;   
    }        
 
    function updateSalePrice(uint256 _salePrice) external onlyAdmin() {
        price = _salePrice;   
    }    
    
    function updateEndTime(uint256 _endTimeInEpoch) external onlyAdmin() {
        endTime = _endTimeInEpoch;   
    }        
     
    function updateSoftCap(uint256 _softCap) external onlyAdmin() {
        softCap = _softCap;   
    }        
    
    function updateHardCap(uint256 _hardCap) external onlyAdmin() {
        hardCap = _hardCap;   
    }         
    
    function updateTokenSaleDecimals(uint8 _tokenForSaleDecimalCount) external onlyAdmin() saleNotActive() {
        tokenForSaleDecimalCount = _tokenForSaleDecimalCount;   
    }     

// admin functions
// dev functions   
 
    function updateAvailableTokens(uint256 _availableTokens) external onlyAdmin() {
        availableTokens = _availableTokens;   
    }        
    
    function updateMinPurchase(uint256 _minPurchase) external onlyAdmin() {
        minPurchase = _minPurchase;   
    }        
    
    function updateMaxPurchase(uint256 _maxPurchase) external onlyAdmin() {
        maxPurchase = _maxPurchase;   
    }             
    
    function updateTokensReleased(bool _isReleased) external onlyAdmin() {
        released = _isReleased;   
    }    
    
    function updateInvestorNextClaim(address _tokenAddressSale, address _investor, uint256 _nextClaimInEpoch) external onlyAdmin() {
        investorPurchased[_tokenAddressSale][_investor].nextClaim = _nextClaimInEpoch;   
    }

// dev functions     

    function start(
        uint256 _endDateInEpoch,
        uint256 _salePrice,
        uint256 _availableTokens,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _tokenForSaleDecimalCount,
        address _tokenAddressSale,
        address _tokenAddressContribution) external onlyAdmin() saleNotActive() {
        require(_tokenForSaleDecimalCount > 0, "Token for sale decimal count must be set first!");
        require(_tokenAddressContribution != _tokenAddressSale, 'Enter a valid Token address for contribution!');
        require(_endDateInEpoch > 0 && _endDateInEpoch > block.timestamp, 'Enter a valid end date!');
        //possible bug, convert available token input to full decimal count when comparing with contract balance
        require(_availableTokens == IERC20(_tokenAddressSale).balanceOf(address(this)), 'Contract missing coins for sale!' );
        require(_availableTokens > 0 && _salePrice > 0, 'Cannot sell zero tokens or have zero price!');
        require(_minPurchase > 0 && _minPurchase < _maxPurchase, 'Minimum purchase amount must be greater than zero & less than max purchase!');
        require(_maxPurchase > 0, 'Max purchase must be greater than zero!');
        startTime = block.timestamp;
        endTime = _endDateInEpoch; 
        price = _salePrice;
        tokenForSale = _tokenAddressSale;
        tokenForSaleDecimalCount = _tokenForSaleDecimalCount;
        tokenForContribution = _tokenAddressContribution;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        released = false;
        contributionAmount = 0;
    }

    /**
    * Allow deposits
    */
    receive() external payable {}

    function buyCurrentSale(uint256 _purchaseAmount) external payable onlyInvestors() saleActive() {
        address payable sender = payable(_msgSender());
        address payable reciever = payable(address(this));
        if(tokenForContribution == address(0)){
        _purchaseAmount = msg.value;
        }
        require(_purchaseAmount >= minPurchase && _purchaseAmount <= maxPurchase, 'Send an amount between minPurchase and maxPurchase limit!');
        uint256 _amountPurchased = _purchaseAmount / price;
        uint256 _amountPurchasedWithDecimals = _amountPurchased * (10 ** tokenForSaleDecimalCount);
        require(_amountPurchasedWithDecimals <= availableTokens, 'Not enough tokens left for sale');
        if(investorPurchased[tokenForSale][sender].isInvestor){
            uint256 investorSaleID = investorPurchased[tokenForSale][sender].saleID;
            investorPurchased[tokenForSale][sender].purchased += _amountPurchasedWithDecimals;
            Sale storage sale = sales[investorSaleID];
            sale.purchased += _amountPurchasedWithDecimals;
        }else{
            uint256 firstVest = endTime;
            investorPurchased[tokenForSale][sender] = Sale(nextSaleID,sender,tokenForSaleDecimalCount,tokenForSale,tokenForContribution,_amountPurchasedWithDecimals,false,firstVest,startTime,endTime,true);
            sales.push(investorPurchased[tokenForSale][sender]);
            nextSaleID++;
        }
        contributionAmount += _purchaseAmount;
        availableTokens -= _amountPurchasedWithDecimals;
        
        if(tokenForContribution == address(0)){
            reciever.transfer(_purchaseAmount);
        }else{
            IERC20(tokenForContribution).transferFrom(sender,address(this),_purchaseAmount);
        }
        emit TokenBought(tokenForSale,sender,_purchaseAmount);
    }
    

    function claim(address _tokenAddressSale) external eligibleClaim(_tokenAddressSale) {
        require(_tokenAddressSale != address(this), 'Enter address of token sold!');
        address sender = _msgSender();

        if(!claimeEnabled){
        require(investorPurchased[_tokenAddressSale][sender].nextClaim < block.timestamp, "Must wait for sale to end!");
        }

        uint256 investorAvailableClaim = investorPurchased[_tokenAddressSale][sender].purchased;

        require(investorAvailableClaim > 0, "No more tokens left to claim!");
        
        require(sendVestClaim(investorAvailableClaim,sender,_tokenAddressSale));
    }
    
    function sendVestClaim(uint256 investorAvailableClaim, address sender,address _tokenAddressSale) internal returns(bool){
        uint256 investorSaleID = investorPurchased[_tokenAddressSale][sender].saleID;
        investorPurchased[_tokenAddressSale][sender].claimed = true;
        Sale storage sale = sales[investorSaleID];
        sale.claimed = true;
        IERC20(_tokenAddressSale).transfer(sender,investorAvailableClaim);
        emit VestingClaimed(_tokenAddressSale,sender,investorAvailableClaim);
        return true;
    }
    
    function releaseAllBuyerTokens(address _tokenAddressSale) external onlyAdmin() saleEnded() tokensNotReleased() {
        require(_tokenAddressSale != address(this));
        for(uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            if(sale.tokenPurchased == _tokenAddressSale){
                uint256 _transferAmount = sale.purchased;
                bool investorClaimed = investorPurchased[_tokenAddressSale][sale.investor].claimed;
                    if(_transferAmount > 0 && !investorClaimed){
                        investorPurchased[_tokenAddressSale][sale.investor].claimed = true;
                        sendVestClaim(_transferAmount,sale.investor,_tokenAddressSale);
                    }
            }
        }
        released = true;
        emit AllTokensReleased(_tokenAddressSale);
    }    
    
    function releaseSingleBuyerTokens(address _tokenAddressSale, address _investor) external onlyAdmin(){
        require(_tokenAddressSale != address(this), 'Enter Token addresss of token sold!');
        bool investorClaimed = investorPurchased[_tokenAddressSale][_investor].claimed;
        require(!investorClaimed, 'Investor already claimed!');
        uint256 investorPurchasedAmount = investorPurchased[_tokenAddressSale][_investor].purchased;
        investorPurchased[_tokenAddressSale][_investor].claimed = true;
        sendVestClaim(investorPurchasedAmount,_investor,_tokenAddressSale);
    }
    
    function withdrawSaleFunds(address _tokenAddressContribution, address _receiver) external onlyAdmin() {
        require(_tokenAddressContribution != address(this));
        uint256 _totalContributionAmount;
        if(_tokenAddressContribution == address(0)){
        address payable _payableReceiver = payable(_receiver);
        _totalContributionAmount = address(this).balance;
        _payableReceiver.transfer(_totalContributionAmount);        
        }
        else{
        _totalContributionAmount = IERC20(_tokenAddressContribution).balanceOf(address(this));
        IERC20(_tokenAddressContribution).transfer(_receiver,_totalContributionAmount);
        }
        contributionAmount = 0;
        emit ContractWithdrawal("Contract funds withdrawn!");
    }
    
    function withdrawUnsoldTokens(address _tokenAddressSale, address _receiver) external onlyAdmin() tokensReleased(){
        require(_tokenAddressSale != address(this));
        uint256 _totalUnsoldAmount = IERC20(_tokenAddressSale).balanceOf(address(this));
        IERC20(_tokenAddressSale).transfer(_receiver,_totalUnsoldAmount);
        released = false;
        emit ContractWithdrawal("Contract funds withdrawn!");
    }
}