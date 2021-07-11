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
        uint saleID;
        address investor;
        uint8 tokenSaleDecimalCount;
        address tokenPurchased;
        address tokenContributed;
        uint purchased;
        uint claimed;
        uint vestCount;
        uint vestTimeSet;
        uint vestPercentageSet;
        uint nextClaim;
        uint saleStartTime;
        uint saleEndTime;
        bool isInvestor;
    }
    Sale[] public sales;
    mapping(address => bool) public investors;
    mapping(address => mapping(address => Sale)) public investorPurchased;
    uint public nextSaleID;
    uint public startTime;
    uint public endTime;
    uint public price;
    uint8 public tokenForSaleDecimalCount;
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
    
    function updateSaleName(string calldata _saleName) external onlyAdmin() {
        name = _saleName;   
    }        
    
    function updateSalePrice(uint _salePrice) external onlyAdmin() {
        price = _salePrice;   
    }    
    
    function updateEndTime(uint _endTimeInEpoch) external onlyAdmin() {
        endTime = _endTimeInEpoch;   
    }        
    
    function updateAvailableTokens(uint _availableTokens) external onlyAdmin() {
        availableTokens = _availableTokens;   
    }        
    
    function updateMinPurchase(uint _minPurchase) external onlyAdmin() {
        minPurchase = _minPurchase;   
    }        
    
    function updateMaxPurchase(uint _maxPurchase) external onlyAdmin() {
        maxPurchase = _maxPurchase;   
    }        
    
    function updateSoftCap(uint _softCap) external onlyAdmin() {
        softCap = _softCap;   
    }        
    
    function updateHardCap(uint _hardCap) external onlyAdmin() {
        hardCap = _hardCap;   
    }        
    
    function updateVestTime(uint _vestTimeInEpoch) external onlyAdmin() {
        vestTime = _vestTimeInEpoch;   
    }        
    
    function updateVestPercentage(uint _vestPercentageWholeNumber) external onlyAdmin() {
        vestPercentage = _vestPercentageWholeNumber;   
    }        
    
    function updateTokenSaleDecimals(uint8 _tokenForSaleDecimalCount) external onlyAdmin() {
        tokenForSaleDecimalCount = _tokenForSaleDecimalCount;   
    }    
    
    function updateInvestorNextClaim(address _tokenAddressSale, address _investor, uint _nextClaimInEpoch) external onlyAdmin() {
        investorPurchased[_tokenAddressSale][_investor].nextClaim = _nextClaimInEpoch;   
    }
    
    function start(
        uint _endDateInEpoch,
        uint _salePrice,
        uint _availableTokens,
        uint _minPurchase,
        uint _maxPurchase,
        uint _softCap,
        uint _hardCap,
        uint _vestTimeInEpoch,
        uint _vestPercentageWholeNumber,
        address _tokenAddressSale,
        address _tokenAddressContribution) external onlyAdmin() icoNotActive() {
        require(tokenForSaleDecimalCount > 0, "Token for sale decimal count must be set first!");
        require(_tokenAddressContribution != _tokenAddressSale && _tokenAddressContribution != address(0), 'Enter a valid Token address for contribution!');
        require(_endDateInEpoch > 0 && _endDateInEpoch > block.timestamp, 'Enter a valid end date!');
        require(_availableTokens <= IERC20(_tokenAddressSale).balanceOf(address(this)), 'Contract missing coins for sale!' );
        require(_availableTokens > 0 && _salePrice > 0, 'Cannot sell zero tokens or have zero price!');
        require(_minPurchase > 0 && _minPurchase < _maxPurchase, 'Minimum purchase amount must be greater than zero & less than max purchase!');
        require(_maxPurchase > 0, 'Max purchase must be greater than zero!');
        require(_vestPercentageWholeNumber <= 100 && _vestPercentageWholeNumber > 0);
        startTime = block.timestamp;
        endTime = _endDateInEpoch; 
        price = _salePrice;
        tokenForSale = _tokenAddressSale;
        tokenForContribution = _tokenAddressContribution;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        vestTime = _vestTimeInEpoch;
        vestPercentage = _vestPercentageWholeNumber;
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
            investorPurchased[tokenForSale][sender] = Sale(nextSaleID,sender,tokenForSaleDecimalCount,tokenForSale,tokenForContribution,_amountPurchased,0,0,vestTime,vestPercentage,firstVest,startTime,endTime,true);
            sales.push(investorPurchased[tokenForSale][sender]);
            nextSaleID++;
        }
        contributionAmount += _purchaseAmount;
        availableTokens -= _amountPurchased;
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
        
        for(uint index = 1; index <= claimCount; index++){
            uint investorCurrentClaim =  (previousClaimAmount * investorVestPercentage) / 100;
            if(investorCurrentClaim > 0){
            previousClaimAmount -= investorCurrentClaim;
            claimTotal += investorCurrentClaim;
            }
        }
        sendVestClaim(investorAvailableClaim, claimTotal, sender,_tokenAddressSale);
    }
    
    function sendVestClaim(uint investorAvailableClaim, uint claimTotal, address sender,address _tokenAddressSale) internal{
        require(claimTotal <= investorAvailableClaim, "Issue with claiming tokens!");
        uint investorSaleID = investorPurchased[_tokenAddressSale][sender].saleID;
        investorPurchased[_tokenAddressSale][sender].claimed += claimTotal;
        Sale storage sale = sales[investorSaleID];
        sale.claimed += claimTotal;
        uint8 claimTokenDecimalCount = investorPurchased[_tokenAddressSale][sender].tokenSaleDecimalCount;
        uint claimTotalWithDecimals = claimTotal * (10 ** uint(claimTokenDecimalCount));
        IERC20(_tokenAddressSale).transfer(sender,claimTotalWithDecimals);
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
        sendVestClaim(investorAvailableClaim,investorAvailableClaim,_investor,_tokenAddressSale);
    }
    
    function withdrawSaleFunds(address _tokenAddressContribution, address _receiver) external onlyAdmin() icoEnded() {
        uint _totalContributionAmount = IERC20(_tokenAddressContribution).balanceOf(address(this));
        IERC20(_tokenAddressContribution).transfer(_receiver,_totalContributionAmount);
        emit ContractWithdrawal("Contract funds withdrawn!");
    }
    
    function withdrawUnsoldTokens(address _tokenAddressSale, address _receiver) external onlyAdmin() icoEnded() tokensReleased(){
            uint _totalUnsoldAmount = IERC20(_tokenAddressSale).balanceOf(address(this));
            IERC20(_tokenAddressSale).transfer(_receiver,_totalUnsoldAmount);
            emit ContractWithdrawal("Contract funds withdrawn!");
    }
}