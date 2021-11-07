/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: none
pragma solidity ^0.6.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "SafeMath: subtraction overflow");
    }

    function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "SafeMath: division by zero");
    }

    function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "SafeMath: modulo by zero");
    }

    function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.5.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns(uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating wether the operation succeeded.
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
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating wether the operation succeeded.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


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
    function mint(address to, uint256 amount) external;
}

contract Ownable {
    /***
     * Configurator Crowdsale Contract
     */
    address payable internal owner;
    address payable internal admin;

    struct whitelistData {
        address account;
        bool isApproved;
        bool isWhales;
        bool isRetail;
        uint256 totalPurchased;
    }

    mapping (address => whitelistData) internal whitelist;

    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyWhitelist {
        require(isWhitelist(msg.sender) == true , 'Litedex: You are not whitelist address');
        _;
    }
    modifier onlyWhitelistLock{
        require(isWhitelistLock(msg.sender) == true, 'Litedex: You are not whitelist lock address');
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner, 'Litedex: Only Owner or Admin');
        _;
    }
    
    /**
     * Event for Transfer Ownership
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    

    function setAdmin(address payable account) external onlyOwner returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        admin = account;
    }
    /**
     * Function to change Crowdsale contract Owner
     * Only Owner who could access this function
     * 
     * return event OwnershipTransferred
     */
    
    function transferOwnership(address payable _owner) onlyOwner public returns(bool) {
        owner = _owner;
        
        emit OwnershipTransferred(msg.sender, _owner, block.timestamp);
        return true;
    }
    function isWhitelist(address account) public view returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        if(whitelist[account].isApproved && whitelist[account].isRetail){
            return whitelist[account].isApproved;
        }
        return false;
    }
    function isWhitelistLock(address account) public view returns(bool){
        require(account != address(0), 'Litedex: account is zero address');
        if(whitelist[account].isApproved && whitelist[account].isWhales){
            return whitelist[account].isApproved;
        }
        return false;
    }
    function addWhitelist(address account) external onlyAdmin returns(bool){
        require(isWhitelist(account) != true, 'Litedex: account is already in whitelist');
        whitelist[account].account = account;
        whitelist[account].isApproved = true;
        whitelist[account].isRetail = true;
        return true;
    }
    function addWhitelistLock(address account) external onlyAdmin returns(bool){
        require(isWhitelistLock(account) != true, 'Litedex: account is already in whitelist');
        whitelist[account].account = account;
        whitelist[account].isApproved = true;
        whitelist[account].isWhales = true;
        return true;
    }
    function dropWhitelist(address account) external onlyAdmin returns(bool){
        require(isWhitelist(account) != false, 'Litedex: account is not whitelist');
        whitelist[account].isApproved = false;
        whitelist[account].isRetail = false;
        return true;
    }
    function dropWhitelistLock(address account) external onlyAdmin returns(bool){
        require(isWhitelistLock(account) != false, 'Litedex: account is not whitelist');
        whitelist[account].isApproved = false;
        whitelist[account].isWhales = false;
        return true;
    }

    constructor() internal{
        owner = msg.sender;
        admin = msg.sender;
    }
}

contract TimeCrowdsale is Ownable {
    uint internal _start;
    uint internal _end;
    
    /**
     * Event shown after change Opening Time 
     * @param owner : who owner this contract
     * @param openingtime : time when the Crowdsale started
     */
    event openingTime(address indexed owner, uint256 openingtime);
    
    /**
     * Event shown after change Closing Time
     * @param owner : who owner this contract
     * @param closingtime : time when the Crowdsale Ended
     */
    event closingTime(address indexed owner, uint256 closingtime);
    
    modifier onlyWhileNotOpen {
        if(getStartedTime() > 0 && getEndedTime() > 0){
            require(getBlockTimestamp() < getStartedTime() && getBlockTimestamp() > getEndedTime(), 'Litedex: private sale is already started');
        }
        _;
    }
    
    modifier onlyWhileOpen {
        require(getStartedTime() > 0 && getEndedTime() > 0, 'Litedex: time is not initialized');
        require(getBlockTimestamp() >= getStartedTime() && getBlockTimestamp() <= getEndedTime(), 'Litedex: private sale is not started');
        _;
    }
    
    /**
     * function to get started time
     */
    
    function getStartedTime() public view returns(uint256){
        return _start;
    }
    
    /**
     * function to get ended time
     */
    
    function getEndedTime() public view returns(uint256){
        return _end;
    }
    
    /**
     * function to get current time
     */
    
    function getBlockTimestamp() internal view returns(uint256){
        return block.timestamp;
    }
    
    /**
     * function to set time for private sale
     */
    
    function setPresaleTime(uint256 start_time, uint256 end_time) external onlyOwner onlyWhileNotOpen returns(uint256 startTime, uint256 endTime){
        require(end_time > getStartedTime() && start_time > 0 && end_time > 0, 'Litedex: time is invalid');
        _start = start_time;
        _end = end_time;
        
        emit openingTime(owner, start_time);
        emit closingTime(owner, end_time);
        return (_start, _end);
    }
    
    function setStartTime(uint256 time) external onlyOwner returns(uint256){
        require(time > 0, 'Litedex: time is invalid');
        require(time < getEndedTime(), 'Litedex: time is higher than end time');
        _start = time;
        
        emit openingTime(owner, time);
        return _start;
    }
    
    function setEndTime(uint256 time) external onlyOwner returns(uint256){
        require(time > 0, 'Litedex: time is invalid');
        require(time > getStartedTime() , 'Litedex: time is lower than start time');
        _end = time;
        
        emit closingTime(owner, time);
        return _end;
    }
}
contract LitedexPresale is TimeCrowdsale{
    using SafeMath for uint256;

    struct participant {
        uint256 amount;   // How many tokens the user has provided.
    }
    struct Crowdsale {
        uint256 phase;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 totalCap;
        uint256 totalSold;
        uint256 totalReceived;
    }
    struct CrowdsaleLock {
        uint256 phase;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 totalCap;
        uint256 totalSold;
        uint256 totalReceived;
    }
    struct Token {
        address tokenAddress;
    }

    /***
     * Token Address for Crowdsale Contract
     */
    IBEP20 private token;
    IBEP20 private wrappedbnb;
    IFactory private factory;
    address payable private fundraiser;
    address payable private fundraiserLock;
    
    /***
     * Crowdsale Information for retail
     */
    uint256 private min_contribution;
    uint256 private max_contribution;
    uint256 private total_cap;
    uint256 private price;
    uint256 private token_available;
    uint256 private total_received;
    uint256 private token_sold;
    uint256 private stakedBNB;
    uint256 private stakedUSD;

    /***
     * Crowdsale Information for whales
     */
    uint256 private minContributionLock;
    uint256 private totalCapLock;
    uint256 private priceLock;
    uint256 private tokenAvailableLock;
    uint256 private totalReceivedLock;
    uint256 private tokenSoldLock;
    uint256 private stakedBNBLock;
    uint256 private stakedUSDLock;
    
    
    /**
     * Participant Information
     */
    mapping (address => participant) public userInfo;
    mapping (uint256 => Crowdsale) public crowdsaleInfo;
    mapping (uint256 => CrowdsaleLock) public crowdsaleLockInfo;
    mapping (uint256 => Token) private tokenApproved;

    address[] private tokenList;
    address[] private purchaserList;
    uint256[] private crowdsaleList;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event purchased(address indexed purchaser, uint256 amount);

    /**
     * Event for token purchase of locking investor
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event purchasedLock(address indexed purchaser, uint amount);
    
    /**
     * Event for Initializing Crowdsale Contract
     * @param min_contribution : min contribution for retails in Crowdsale
     * @param minContributionForLock : min contribution for locking investor
     * @param cap : goals for the private sale for retails
     * @param capForLock: goals for the locking private sale
     * @param price : initial price of Crowdsale for retails
     * @param priceForLock : initial price for locking investor
     */
    event initialized(
        uint256 min_contribution, 
        uint256 minContributionForLock,
        uint256 cap,
        uint256 capForLock,
        uint256 price,
        uint256 priceForLock
    );

    /**
     * Constructor of Litedex Crowdsale Contract
     */
    
    constructor(address _wbnb, address _factory, address _tokenAddress, address _pairAddress, address payable _fundraiser) public {
        token = IBEP20(_tokenAddress);
        wrappedbnb = IBEP20(_wbnb);
        factory = IFactory(_factory);
        tokenApproved[0].tokenAddress = _pairAddress;
        fundraiser = _fundraiser;
        fundraiserLock = _fundraiser;
        tokenList.push(_pairAddress);
    }
    
    receive() external payable {
        assert(msg.sender == address(wrappedbnb)); // only accept BNB via fallback from the WBNB contract
    }
    
    /**
     * Function for Initialize default configuration of Crowdsale
     */
    function initialize(
        uint256 minContribution,
        uint256 maxContribution,
        uint256 minContributionFLock,
        uint256 initialCap,
        uint256 initialCapFLock,
        uint256 initialPrice,
        uint256 initialPriceFLock
    ) external onlyOwner onlyWhileNotOpen returns(bool) {
        
        require(minContribution > 0 && minContributionFLock > 0, "Litedex: min_contribution must higher than 0");
        min_contribution = minContribution;
        max_contribution = maxContribution;
        minContributionLock = minContributionFLock;
        
        require(initialPrice > 0 && initialPriceFLock > 0, "Litedex: initial price must higher than 0");
        price = initialPrice;
        priceLock = initialPriceFLock;

        require(initialCap > 0 && initialCapFLock > 0, "Litedex: total cap must higher than 0");
        total_cap = initialCap;
        token_available = initialCap;

        totalCapLock = initialCapFLock;
        tokenAvailableLock = initialCapFLock;
        
        resetCrowdsaleData();
        
        uint256 _currentPhase = getCurrentPhase() + 1;
        crowdsaleInfo[_currentPhase].phase = _currentPhase;
        crowdsaleInfo[_currentPhase].totalCap = initialCap;
        crowdsaleInfo[_currentPhase].price = initialPrice;

        crowdsaleLockInfo[_currentPhase].phase = _currentPhase;
        crowdsaleLockInfo[_currentPhase].totalCap = initialCapFLock;
        crowdsaleLockInfo[_currentPhase].price = initialPriceFLock;


        crowdsaleList.push(_currentPhase);
        
        emit initialized(minContribution,minContributionFLock,initialCap, initialCapFLock, initialPrice, initialPriceFLock);
        return true;
    }
    
    /**
     * Function to reset crowdsale data
     */
    function resetCrowdsaleData() private onlyOwner {
        stakedBNB = 0;
        stakedUSD = 0;
        token_sold = 0;
        total_received = 0;

        stakedBNBLock = 0;
        stakedUSDLock = 0;
        tokenSoldLock = 0;
        totalReceivedLock = 0;
        _start = 0;
        _end = 0;
    }
    
    /**
     * function to get current phase of crowdsale
     */

    function getCurrentPhase() public view returns(uint256){
        return crowdsaleList.length;
    }
    
    /**
     * function to add new stable coin pair
     */

    function addNewPair(address tokenAddress) external onlyOwner returns(bool) {
        require(tokenAddress != address(0), 'Litedex: token is zero address');
        uint256 currentId = tokenList.length;
        tokenApproved[currentId].tokenAddress = tokenAddress;
        tokenList.push(tokenAddress);
        return true;
    }
    /**
     * Function to set fundraiser
     */
    
    function setFundraiser(address payable _newFundraiser) external onlyOwner returns(bool){
        require(_newFundraiser != address(0));
        fundraiser = _newFundraiser;
        return true;
    }

    /**
     * Function to set fundraiser
     */
    
    function setFundraiserLock(address payable _newFundraiser) external onlyOwner returns(bool){
        require(_newFundraiser != address(0));
        fundraiserLock = _newFundraiser;
        return true;
    }
    
    /**
     * function to purchase in private sale using BNB
     */

    function purchaseInBNB() payable external onlyWhileOpen onlyWhitelist returns(bool) {
        
        require(msg.value > 0 , 'Litedex: amount is zero'); //validation bnb is higher than 0
        require(whitelist[msg.sender].totalPurchased < getMaxContribution() , 'Litedex: your account has reached limit of presale');
        
        uint256 amount = msg.value.mul(getBnbPrice()).div(1e18); //calculate amount bnb per rate 32 e18
        
        uint256 tokenReached = getEstimateToken(amount); //trying to get the fixed amount token that available
        
        uint256 amountInBnb = tokenReached.mul(getCurrentPrice()).div(getBnbPrice());
        uint256 received = amountInBnb.mul(getBnbPrice()).div(1e18);
        
        stakedBNB = stakedBNB.add(amountInBnb);
        safeTransferBNB(fundraiser, amountInBnb);
        
        // IWBNB(address(wrappedbnb)).deposit{value: amountInBnb}(); 
        
        if(msg.value > amountInBnb) safeTransferBNB(msg.sender, msg.value.sub(amountInBnb));
        token.transfer(msg.sender, tokenReached);

        updateDataCrowdsale(received, tokenReached);
        
        whitelist[msg.sender].totalPurchased = whitelist[msg.sender].totalPurchased.add(tokenReached);
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }

    /**
     * function to purchase in private sale using BNB (Locking Investor)
     */

    function purchaseInBNBLock() payable external onlyWhileOpen onlyWhitelist returns(bool) {
        
        require(msg.value > 0 , 'Litedex: amount is zero'); //validation bnb is higher than 0
        uint256 amount = msg.value.mul(getBnbPrice()).div(1e18); //calculate amount bnb per rate 32 e18
        
        uint256 tokenReached = getEstimateTokenLock(amount); //trying to get the fixed amount token that available
        
        uint256 amountInBnb = tokenReached.mul(getCurrentPriceLock()).div(getBnbPrice());
        uint256 received = amountInBnb.mul(getBnbPrice()).div(1e18);
        
        stakedBNBLock = stakedBNBLock.add(amountInBnb);
        safeTransferBNB(fundraiserLock, amountInBnb);
        
        // IWBNB(address(wrappedbnb)).deposit{value: amountInBnb}(); 
        
        if(msg.value > amountInBnb) safeTransferBNB(msg.sender, msg.value.sub(amountInBnb));
        token.transfer(msg.sender, tokenReached);

        updateDataCrowdsaleLock(received, tokenReached);
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }
    
    /**
     * Function for Purchase Token on Crowdsale
     * @param pid : pair id which user spent to purchase
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function purchase(uint256 pid,uint256 amount) external onlyWhileOpen onlyWhitelist returns(bool){
        require(tokenApproved[pid].tokenAddress != address(0), "Litedex: pid is not available");
        require(whitelist[msg.sender].totalPurchased < getMaxContribution() , 'Litedex: your account has reached limit of presale');
        
        uint256 tokenReached;
        uint256 amounts;
        uint256 received;
        
        IBEP20 _pair = IBEP20(tokenApproved[pid].tokenAddress);
        uint256 _tokendecimals = _pair.decimals();
        
        if(tokenApproved[pid].tokenAddress == address(wrappedbnb)){
            tokenReached = getEstimateToken(amount.mul(getBnbPrice())).div(10 ** _tokendecimals);
            if(whitelist[msg.sender].totalPurchased.add(tokenReached) > getMaxContribution()){
                tokenReached = getMaxContribution().sub(whitelist[msg.sender].totalPurchased);
            }
            
            amounts = tokenReached.mul(getCurrentPrice()).div(getBnbPrice());
            stakedBNB = stakedBNB.add(amounts);
            received = amounts.mul(getBnbPrice()).div(10 ** _tokendecimals);
        }else{
            tokenReached = getEstimateToken(amount);
            if(whitelist[msg.sender].totalPurchased.add(tokenReached) > getMaxContribution()){
                tokenReached = getMaxContribution().sub(whitelist[msg.sender].totalPurchased);
            }
            amounts = tokenReached.mul(getCurrentPrice()).div(10 ** _tokendecimals);
            stakedUSD = stakedUSD.add(amounts);
            received = amounts;
        }
        
        _pair.transferFrom(msg.sender, address(this), amounts);
        
        if(tokenApproved[pid].tokenAddress == address(wrappedbnb)){
            IWBNB(address(wrappedbnb)).withdraw(amounts);
            safeTransferBNB(fundraiser, amounts);
        }else{
            _pair.transfer(fundraiser, amounts);
        }

        updateDataCrowdsale(received, tokenReached);
        
        token.transfer(msg.sender, tokenReached);
        whitelist[msg.sender].totalPurchased = whitelist[msg.sender].totalPurchased.add(tokenReached);
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }

    /**
     * Function for Purchase Token on Crowdsale (Locking Investor)
     * @param pid : pair id which user spent to purchase
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function purchaseLock(uint256 pid,uint256 amount) external onlyWhileOpen onlyWhitelist returns(bool){
        require(tokenApproved[pid].tokenAddress != address(0), "Litedex: pid is not available");
        
        uint256 tokenReached;
        uint256 amounts;
        uint256 received;
        
        IBEP20 _pair = IBEP20(tokenApproved[pid].tokenAddress);
        uint256 _tokendecimals = _pair.decimals();
        
        if(tokenApproved[pid].tokenAddress == address(wrappedbnb)){
            tokenReached = getEstimateTokenLock(amount.mul(getBnbPrice())).div(10 ** _tokendecimals);
            amounts = tokenReached.mul(getCurrentPriceLock()).div(getBnbPrice());
            stakedBNBLock = stakedBNBLock.add(amounts);
            received = amounts.mul(getBnbPrice()).div(10 ** _tokendecimals);
        }else{
            tokenReached = getEstimateTokenLock(amount);
            amounts = tokenReached.mul(getCurrentPriceLock()).div(10 ** _tokendecimals);
            stakedUSDLock = stakedUSDLock.add(amounts);
            received = amounts;
        }
        
        _pair.transferFrom(msg.sender, address(this), amounts);
        
        if(tokenApproved[pid].tokenAddress == address(wrappedbnb)){
            IWBNB(address(wrappedbnb)).withdraw(amounts);
            safeTransferBNB(fundraiserLock, amounts);
        }else{
            _pair.transfer(fundraiserLock, amounts);
        }

        updateDataCrowdsaleLock(received, tokenReached);
        
        token.transfer(msg.sender, tokenReached);
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }
    
    /**
     * Function to update data crowdsale
     */
    function updateDataCrowdsale(uint256 receives, uint256 reached) private {
        uint256 _id = getCurrentPhase();
        total_received = stakedBNB.mul(getBnbPrice()).div(1e18).add(stakedUSD);
        crowdsaleInfo[_id].totalReceived = total_received;

        if (userInfo[msg.sender].amount == 0) {
            purchaserList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(receives);
        
        token_sold = getTokenSold().add(reached);
        crowdsaleInfo[_id].totalSold = token_sold;
        
        crowdsaleInfo[_id].startTime = _start;
        crowdsaleInfo[_id].endTime = _end;
        
        token_available = getTokenAvailable().sub(reached);
    }
    /**
     * Function to update data crowdsale
     */
    function updateDataCrowdsaleLock(uint256 receives, uint256 reached) private {
        uint256 _id = getCurrentPhase();
        totalReceivedLock = stakedBNBLock.mul(getBnbPrice()).div(1e18).add(stakedUSDLock);
        crowdsaleLockInfo[_id].totalReceived = totalReceivedLock;

        if (userInfo[msg.sender].amount == 0) {
            purchaserList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(receives);
        
        tokenSoldLock = getTokenSoldLock().add(reached);
        crowdsaleLockInfo[_id].totalSold = tokenSoldLock;
        
        crowdsaleLockInfo[_id].startTime = _start;
        crowdsaleLockInfo[_id].endTime = _end;
        
        tokenAvailableLock = getTokenAvailableLock().sub(reached);
    }
    
    /**
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * return token_amount type uint256
     */
    function getEstimateToken(uint256 _amount) private view returns(uint256) {
        require(_amount >= getMinContribution() && _amount <= getMaxContribution(), "Litedex: amount is lower than min contribution");
        require(getCurrentPrice() > 0, 'Litedex: Price is not initialized');
        require(getTokenSold()< getTotalCap(), 'Litedex: total cap has reached');

        uint256 tokendecimal = token.decimals();
        uint256 estimateToken;
        
        estimateToken = _amount.mul(10 ** tokendecimal).div(getCurrentPrice());
        if(estimateToken >= getTotalCap().sub(getTokenSold())){
            estimateToken = getTotalCap().sub(getTokenSold());
        }
        
        require(estimateToken > 0, "Litedex: calculating error!");
        return estimateToken;
    }

    /**
     * Function for Estimate token which user get on Crowdsale (Locking Investor)
     * @param _amount : amount which user purchase
     * return token_amount type uint256
     */
    function getEstimateTokenLock(uint256 _amount) private view returns(uint256) {
        require(_amount >= getMinContributionLock(), "Litedex: amount is lower than min contribution");
        require(getCurrentPriceLock() > 0, 'Litedex: Price is not initialized');
        require(getTokenSoldLock()< getTotalCapLock(), 'Litedex: total cap has reached');

        uint256 tokendecimal = token.decimals();
        uint256 estimateToken;
        
        estimateToken = _amount.mul(10 ** tokendecimal).div(getCurrentPriceLock());
        if(estimateToken >= getTotalCapLock().sub(getTokenSoldLock())){
            estimateToken = getTotalCapLock().sub(getTokenSoldLock());
        }
        
        require(estimateToken > 0, "Litedex: calculating error!");
        return estimateToken;
    }
    
    /**
     * function to increase total cap
     */
    function increaseTotalCap(uint256 cap) onlyOwner external returns(uint256){
        total_cap = total_cap.add(cap);
        token_available = token_available.add(cap); 
        
        uint256 _id = getCurrentPhase();
        crowdsaleInfo[_id].totalCap = total_cap;
        return total_cap;
    }
    
    /**
     * function to decrease total cap
     */
    function decreaseTotalCap(uint256 cap) onlyOwner external returns(uint256){
        total_cap = total_cap.sub(cap);
        token_available = (token_available > cap) ? token_available.sub(cap) : 0;
        
        uint256 _id = getCurrentPhase();
        crowdsaleInfo[_id].totalCap = total_cap;
        return total_cap;
    }

    /**
     * function to increase total cap
     */
    function increaseTotalCapLock(uint256 cap) onlyOwner external returns(uint256){
        totalCapLock = totalCapLock.add(cap);
        tokenAvailableLock = tokenAvailableLock.add(cap); 
        
        uint256 _id = getCurrentPhase();
        crowdsaleLockInfo[_id].totalCap = totalCapLock;
        return totalCapLock;
    }
    
    /**
     * function to decrease total cap
     */
    function decreaseTotalCapLock(uint256 cap) onlyOwner external returns(uint256){
        totalCapLock = totalCapLock.sub(cap);
        tokenAvailableLock = (tokenAvailableLock > cap) ? tokenAvailableLock.sub(cap) : 0;
        
        uint256 _id = getCurrentPhase();
        crowdsaleLockInfo[_id].totalCap = totalCapLock;
        return totalCapLock;
    }
    
    /**
     * Function for setting current min contribution
     * 
     * return true
     */
    function setMinContribution(uint256 minContribution) onlyOwner external returns(uint256){
        min_contribution = minContribution;
        return min_contribution;
    }
    /**
     * Function for setting current price
     * 
     * return true
     */
    function setPrice(uint256 newPrice) onlyOwner external returns(uint256){
        price = newPrice;
        
        uint256 _id = getCurrentPhase();
        crowdsaleInfo[_id].price = price;
        return price; 
    }

    /**
     * Function for setting current min contribution
     * 
     * return true
     */
    function setMinContributionLock(uint256 minContribution) onlyOwner external returns(uint256){
        minContributionLock = minContribution;
        return minContributionLock;
    }
    /**
     * Function setting current price for locking investor
     * 
     * return true
     */
    function setPriceLock(uint256 newPrice) onlyOwner external returns(uint256){
        priceLock = newPrice;
        
        uint256 _id = getCurrentPhase();
        crowdsaleLockInfo[_id].price = priceLock;
        return priceLock; 
    }
    
    /**
     * Function for getting current price in usd
     * 
     * return price (uint256)
     */
    
    function getCurrentPrice() public view returns(uint256){
        return price;
    }

    /**
     * Function to get current price in usd for locking investor
     * 
     * return priceLock (uint256)
     */
    
    function getCurrentPriceLock() public view returns(uint256){
        return priceLock;
    }
    
    /**
     * Function for get total BNB received in contract
     */
 
     function getTotalBNBReceived() external view returns(uint256){
        return stakedBNB;
    }
    
    /**
     * Function for get total stable coin (BUSD,USDT,etc) received in contract
     */

    function getTotalUSDReceived() external view returns(uint256){
        return stakedUSD;
    }
    
    /**
     * Function for getting current bnb price in pool
     * 
     * return price (uint256)
     */

    function getBnbPrice() public view returns(uint256){
        uint256 bnbPrice;
        
        address lp = factory.getPair(address(wrappedbnb), address(tokenApproved[0].tokenAddress));
        IPair Lp = IPair(lp);
        
        (uint256 _reserve0, uint256 _reserve1,) = Lp.getReserves(); // gas savings
        if(Lp.token0() == address(wrappedbnb)){
            bnbPrice = ((_reserve1).mul(1e18).div(_reserve0));
        }else{
            bnbPrice = ((_reserve0).mul(1e18).div(_reserve1));
        }
        return bnbPrice;
    }
    
    /**
     * Function for getting current total received
     * 
     * return total_received (uint256)
     */
    
    function getTotalReceived() public view returns(uint256){
        return stakedBNB.mul(getBnbPrice()).div(1e18).add(stakedUSD);
    }

    /**
     * Function for getting current total received for locking investor
     * 
     * return total_received (uint256)
     */
    
    function getTotalReceivedLock() public view returns(uint256){
        return stakedBNBLock.mul(getBnbPrice()).div(1e18).add(stakedUSDLock);
    }
    
    /**
     * Function for getting current min contribution
     * 
     * return min_contribution (uint256)
     */
    
    function getMinContribution() public view returns(uint256){
        return min_contribution;
    }

    /**
     * Function for getting current max contribution
     * 
     * return max_contribution (uint256)
     */
    
    function getMaxContribution() public view returns(uint256){
        return max_contribution;
    }


    /**
     * Function for getting current min contribution
     * 
     * return min_contribution (uint256)
     */
    
    function getMinContributionLock() public view returns(uint256){
        return minContributionLock;
    }
    
    /**
     * Function for getting current token available
     * 
     * return token_available (uint256)
     */
    
    function getTokenAvailable() public view returns(uint256){
        return token_available;
    }

    /**
     * Function for getting current token available
     * 
     * return token_available (uint256)
     */
    
    function getTokenAvailableLock() public view returns(uint256){
        return tokenAvailableLock;
    }
    
    /**
     * Function for getting current total cap
     * 
     * return cap (uint256)
     */
    
    function getTotalCap() public view returns(uint256){
        return total_cap;
        
    }

    /**
     * Function for getting current total cap
     * 
     * return cap (uint256)
     */
    
    function getTotalCapLock() public view returns(uint256){
        return totalCapLock;
        
    }
    
    /**
     * Function for getting current token told
     * 
     */
    
    function getTokenSold() public view returns(uint256){
        return token_sold;
    }

    /**
     * Function for getting current token told
     * 
     */
    
    function getTokenSoldLock() public view returns(uint256){
        return tokenSoldLock;
    }
    
    /**
     * Function to withdraw ldx token after private sale
     */
    
    function withdrawLDX() external onlyOwner {
        if(token.balanceOf(address(this)) > getTokenAvailable()){
            token.transfer(owner, token.balanceOf(address(this)).sub(getTokenAvailable()).sub(getTokenAvailableLock()));
        }else{
            require(getBlockTimestamp() > getEndedTime(), 'Litedex: private sale is already started');
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }
    /**
     * Function to set new factory
     */
    
    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), 'Litedex: factory is not zero address');
        factory = IFactory(_factory);
    }
    
    /**
     * Function to recover stuck tokens in contract
     */
    
    function recoverStuckToken(address to, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0) && to != address(0));
        IBEP20 _token = IBEP20(tokenAddress);
        _token.transfer(to, _token.balanceOf(address(this)));
    }
    
    /**
     * Function to recover stuck BNB in contract
     */

    function recoverStuckBNB() external onlyOwner {
        return safeTransferBNB(owner, address(this).balance);
    }
    
    /**
     * Function to get total participant of Crowdsale
     * 
     * return total participant
     */
    
    function getTotalParticipant() public view returns(uint){
        return purchaserList.length;
    }
    
    /**
     * Functions safeTransfer BNB
     * 
     */
    
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Litedex: BNB_TRANSFER_FAILED');
    }
}