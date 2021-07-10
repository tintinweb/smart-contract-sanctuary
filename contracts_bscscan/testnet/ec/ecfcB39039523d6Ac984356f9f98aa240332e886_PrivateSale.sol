/* SPDX-License-Identifier: Unlicensed */
/*
 __      __                           ________                    __        __    __                         
|  \    /  \                         |        \                  |  \      |  \  |  \                        
 \$$\  /  $$______   __    __   ______\$$$$$$$$______    _______ | $$____  | $$\ | $$  ______   __   __   __ 
  \$$\/  $$/      \ |  \  |  \ /      \ | $$  /      \  /       \| $$    \ | $$$\| $$ /      \ |  \ |  \ |  \
   \$$  $$|  $$$$$$\| $$  | $$|  $$$$$$\| $$ |  $$$$$$\|  $$$$$$$| $$$$$$$\| $$$$\ $$|  $$$$$$\| $$ | $$ | $$
    \$$$$ | $$  | $$| $$  | $$| $$   \$$| $$ | $$    $$| $$      | $$  | $$| $$\$$ $$| $$  | $$| $$ | $$ | $$
    | $$  | $$__/ $$| $$__/ $$| $$      | $$ | $$$$$$$$| $$_____ | $$  | $$| $$ \$$$$| $$__/ $$| $$_/ $$_/ $$
    | $$   \$$    $$ \$$    $$| $$      | $$  \$$     \ \$$     \| $$  | $$| $$  \$$$ \$$    $$ \$$   $$   $$
     \$$    \$$$$$$   \$$$$$$  \$$       \$$   \$$$$$$$  \$$$$$$$ \$$   \$$ \$$   \$$  \$$$$$$   \$$$$$\$$$$ 

Private Sale Contract
*/
pragma solidity ^0.8.6;


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
        address investor;
        address tokenPurchased;
        address tokenContributed;
        uint purchased;
        uint claimed;
        uint vestCount;
        uint vestTimeSet;
        uint vestPercentageSet;
        uint nextClaim;
        bool isInvestor;
    }
    Sale[] public sales;
    mapping(address => bool) public investors;
    mapping(address => mapping(address => Sale)) public investorPurchased;
    uint public startTime;
    uint public endTime;
    uint public price;
    address public tokenForSale;
    address public tokenForContribution;
    uint public availableTokens;
    uint public contributionAmount;
    uint public minPurchase;
    uint public maxPurchase;
    uint public softCap;
    uint public hardCap;
    uint public vestTime;
    uint public vestPercentage;
    bool public released = true;
    bool public allInvestorsAllowed = false;
    string public name = "Major Sale!";
    event Origin(address indexed from, address indexed to, uint256 value);
    event VestingClaimed(address indexed tokenForSale, address indexed from, uint256 value);
    event TokenBought(address indexed tokenForSale, address indexed from, uint256 value);
    event AllTokensReleased(address indexed tokenAddress);
    event ContractWithdrawal(string msg);
    
    constructor() {
       emit Origin(address(0), _msgSender(), 0);
    }
    
    modifier icoActive() {
        require(
            endTime > 0 && block.timestamp < endTime && availableTokens > 0 && (contributionAmount <= softCap || contributionAmount < hardCap), 
            "ICO is not active!");
        _;
    }
    
    modifier icoNotActive() {
        require((endTime != 0 && endTime <= block.timestamp) || released, 'ICO is already active!');
        _;
    }
    
    modifier icoEnded() {
        require(endTime > 0 && (block.timestamp >= endTime || availableTokens == 0), 'ICO has ended!');
        _;
    }
    
    modifier tokensNotReleased() {
        require(released == false, 'Tokens have not been released!');
        _;
    }
    
    modifier tokensReleased() {
        require(released == true, 'Tokens have been released!');
        _;
    }
    
    modifier onlyInvestors() {
        require(investors[_msgSender()] == true || allInvestorsAllowed, 'Only investors!');
        _;
    }    
    
    modifier eligibleClaim(address _tokenAddressSale) {
        require(investorPurchased[_tokenAddressSale][_msgSender()].isInvestor, 'You are not eligible to claim!');
        _;
    }
    
    function addWhitelist(address[] calldata _investors) external onlyAdmin {
    for(uint index = 0; index <= _investors.length; index++) {
        investors[_investors[index]] = true;
    }
    }    
    
    function removeWhitelist(address[] calldata _investors) external onlyAdmin {
    for(uint index = 0; index <= _investors.length; index++) {
        investors[_investors[index]] = false;
    }
    }

    function allowAllInvestors(bool isAllAllowed) external onlyAdmin() {
        allInvestorsAllowed = isAllAllowed;    
    }    
    
    function updateSaleName(string calldata _saleName) external onlyAdmin() {
        name = _saleName;   
    }    
    
    function updateEndTime(uint _endTimeInEpoch) external onlyAdmin() {
        endTime = _endTimeInEpoch;   
    }
    
    function start(
        uint _endDateInEpoch,
        uint _price,
        uint _availableTokens,
        uint _minPurchase,
        uint _maxPurchase,
        uint _softCap,
        uint _hardCap,
        uint _vestTimeInEpoch,
        uint _vestPercentage,
        address _tokenAddressSale,
        address _tokenAddressContribution) external onlyAdmin() icoNotActive() {
        require(_tokenAddressContribution != _tokenAddressSale && _tokenAddressContribution != address(0), 'Enter a valid Token address for contribution!');
        require(_endDateInEpoch > 0 && _endDateInEpoch > block.timestamp, 'Enter a valid end date!');
        require(_availableTokens <= IERC20(_tokenAddressSale).balanceOf(address(this)), 'Contract missing coins for sale!' );
        require(_availableTokens > 0 && _price > 0, 'Cannot sell zero tokens or have zero price!');
        require(_minPurchase > 0 && _minPurchase < _maxPurchase, 'Minimum purchase amount must be greater than zero & less than max purchase!');
        require(_maxPurchase > 0, 'Max purchase must be greater than zero!');
        require(_vestPercentage <= 100 && _vestPercentage > 0);
        startTime = block.timestamp;
        endTime = _endDateInEpoch; 
        price = _price;
        tokenForSale = _tokenAddressSale;
        tokenForContribution = _tokenAddressContribution;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        vestTime = _vestTimeInEpoch;
        vestPercentage = _vestPercentage;
        released = false;
    }

    // add noRentry - add handler for decimal points
    function buyCurrentSale(uint _purchaseAmount) external onlyInvestors() icoActive() {
        address sender = _msgSender();
        require(_purchaseAmount >= minPurchase && _purchaseAmount <= maxPurchase, 'Send an amount between minPurchase and maxPurchase limit!');
        require(IERC20(tokenForContribution).allowance(sender,address(this)) > _purchaseAmount, "Increase allowance, approve more tokens!");
        require(_purchaseAmount % price == 0, 'Contribute an even amount!');
        uint _amountPurchased = _purchaseAmount / price;
        require(_amountPurchased <= availableTokens, 'Not enough tokens left for sale');
        if(investorPurchased[tokenForSale][sender].isInvestor){
            investorPurchased[tokenForSale][sender].purchased += _amountPurchased; 
        }else{
            uint firstVest = endTime + vestTime;
            investorPurchased[tokenForSale][sender] = Sale(sender,tokenForSale,tokenForContribution,_amountPurchased,0,0,vestTime,vestPercentage,firstVest,true);
            sales.push(investorPurchased[tokenForSale][sender]);
        }
        contributionAmount += _purchaseAmount;
        IERC20(tokenForContribution).transferFrom(sender,address(this),_purchaseAmount);
        emit TokenBought(tokenForSale,sender,_purchaseAmount);
    }
    
    function claimVesting(address _tokenAddressSale) external eligibleClaim(_tokenAddressSale) {
        address sender = _msgSender();
        require(investorPurchased[_tokenAddressSale][sender].nextClaim < block.timestamp, "Must wait for next vesting period!");
        uint investorPurchasedAmount = investorPurchased[_tokenAddressSale][sender].purchased;
        uint investorClaimed = investorPurchased[_tokenAddressSale][sender].claimed;
        uint investorAvailableClaim = investorPurchasedAmount  - investorClaimed;
        require(investorAvailableClaim > 0, "No more tokens left to claim!");
        uint investorVestTime = investorPurchased[_tokenAddressSale][sender].vestTimeSet;
        uint investorVestPercentage = investorPurchased[_tokenAddressSale][sender].vestPercentageSet;
        uint claimCount;
        uint claimTotal;
        bool claimChecker = true;
        while(claimChecker){
            investorPurchased[_tokenAddressSale][sender].nextClaim += investorVestTime;
            ++claimCount;
            if(investorPurchased[_tokenAddressSale][sender].nextClaim > block.timestamp){
                claimChecker = false;
            }
        }
        
        uint previousClaimAmount = investorAvailableClaim;
        
        for(uint index = 0; index <= claimCount; index++){
            uint investorCurrentClaim =  (previousClaimAmount * investorVestPercentage) / 100;
            if(investorCurrentClaim > 0){
            previousClaimAmount -= investorCurrentClaim;
            claimTotal += investorCurrentClaim;
            }
        }
        require(claimTotal <= investorAvailableClaim, "Issue with claiming tokens!");
        investorPurchased[_tokenAddressSale][sender].claimed += claimTotal;
        IERC20(_tokenAddressSale).transfer(sender,claimTotal);
        emit VestingClaimed(_tokenAddressSale,sender,claimTotal);
        
    }
    
    function releaseAllBuyerTokens(address _tokenAddressSale) external onlyAdmin() icoEnded() tokensNotReleased() {
        for(uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            if(sale.tokenPurchased == _tokenAddressSale){
                uint _transferAmount = sale.purchased - sale.claimed;
                sale.claimed += _transferAmount;
                    if(_transferAmount > 0){
                        IERC20(tokenForSale).transfer(sale.investor, _transferAmount);
                    }
            }
        }
        released = true;
        emit AllTokensReleased(_tokenAddressSale);
    }    
    
    function releaseSingleBuyerTokens(address _tokenAddressSale, address _investor) external onlyAdmin() icoEnded() tokensNotReleased() {
        uint investorPurchasedAmount = investorPurchased[_tokenAddressSale][_investor].purchased;
        uint investorClaimed = investorPurchased[_tokenAddressSale][_investor].claimed;
        uint investorAvailableClaim = investorPurchasedAmount  - investorClaimed;
        require(investorAvailableClaim > 0, "Investor has no coins available for release!");
        IERC20(_tokenAddressSale).transfer(_investor, investorAvailableClaim);
        emit VestingClaimed(_tokenAddressSale,_investor,investorAvailableClaim);
    }
    
    function withdrawSaleFunds(address _receiver) external onlyAdmin() icoEnded() tokensReleased() {
        uint _totalContributionAmount = IERC20(tokenForContribution).balanceOf(address(this));
        IERC20(tokenForContribution).transfer(_receiver,_totalContributionAmount);
        emit ContractWithdrawal("Contract funds withdrawn!");
    }
}