/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-12
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

    struct whitelistData {
        address account;
        bool isApproved;
    }

    mapping (address => whitelistData) internal whitelist;

    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyWhitelist {
        require(isWhitelist(msg.sender) == true, 'Litedex: You are not whitelist address');
        _;
    }
    
    /**
     * Event for Transfer Ownership
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    
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
        require(account != address(0));
        if(whitelist[account].isApproved == true){
            return whitelist[account].isApproved;
        }
        return false;
    }
    function addWhitelist(address account) external onlyOwner returns(bool){
        require(isWhitelist(account) != true, 'Litedex: account is already in whitelist');
        whitelist[account].account = account;
        whitelist[account].isApproved = true;
        return true;
    }
    function dropWhitelist(address account) external onlyOwner returns(bool){
        require(isWhitelist(account) != false, 'Litedex: account is zero address');
        whitelist[account].isApproved = false;
        return true;
    }

    constructor() internal{
        owner = msg.sender;
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
    
    function setPrivatesaleTime(uint256 start_time, uint256 end_time) external onlyOwner onlyWhileNotOpen returns(uint256 startTime, uint256 endTime){
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
contract LitedexPrivatesale is TimeCrowdsale{
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
    
    /***
     * Crowdsale Information
     */
    uint256 private min_contribution;
    uint256 private total_cap;
    uint256 private price;
    uint256 private token_available;
    uint256 private total_received;
    uint256 private token_sold;
    uint256 private stakedBNB;
    uint256 private stakedUSD;
    
    
    /**
     * Participant Information
     */
    mapping (address => participant) public userInfo;
    mapping (uint256 => Crowdsale) public crowdsaleInfo;
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
     * Event for withdraw usdt token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended

     */
    event withdraw(address indexed owner, uint256 amount);
    
    /**
     * Event for Initializing Crowdsale Contract
     * @param min_contribution : min contribution for transaction in Crowdsale
     * @param cap : goals for the private sale
     * @param price : initial price of Crowdsale
     */
    event initialized(
        uint256 min_contribution, 
        uint256 cap,
        uint256 price
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
        uint256 initialCap,
        uint256 initialPrice
    ) public onlyOwner onlyWhileNotOpen returns(bool) {
        
        require(minContribution > 0, "Litedex: min_contribution must higher than 0");
        min_contribution = minContribution;
        
        require(initialPrice > 0 , "Litedex: initial price must higher than 0");
        price = initialPrice;

        require(initialCap > 0, "Litedex: total cap must higher than 0");
        total_cap = initialCap;
        token_available = initialCap;
        
        resetCrowdsaleData();
        
        uint256 _currentPhase = getCurrentPhase() + 1;
        crowdsaleInfo[_currentPhase].phase = _currentPhase;
        crowdsaleInfo[_currentPhase].totalCap = initialCap;
        crowdsaleInfo[_currentPhase].price = initialPrice;
        crowdsaleList.push(_currentPhase);
        
        emit initialized(minContribution,initialCap, initialPrice);
        return true;
    }

    function resetCrowdsaleData() private onlyOwner {
        stakedBNB = 0;
        stakedUSD = 0;
        token_sold = 0;
        total_received = 0;
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
    
    function setFundraiser(address payable _newFundraiser) external onlyOwner returns(bool){
        require(_newFundraiser != address(0));
        fundraiser = _newFundraiser;
        return true;
    }
    
    /**
     * function to purchase in private sale using BNB
     */

    function purchaseInBNB() payable external onlyWhileOpen onlyWhitelist returns(bool) {
        
        require(msg.value > 0 , 'Litedex: amount is zero'); //validation bnb is higher than 0
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
        
        uint256 tokenReached;
        uint256 amounts;
        uint256 received;
        
        IBEP20 _pair = IBEP20(tokenApproved[pid].tokenAddress);
        uint256 _tokendecimals = _pair.decimals();
        
        if(tokenApproved[pid].tokenAddress == address(wrappedbnb)){
            tokenReached = getEstimateToken(amount.mul(getBnbPrice())).div(10 ** _tokendecimals);
            amounts = tokenReached.mul(getCurrentPrice()).div(getBnbPrice());
            stakedBNB = stakedBNB.add(amounts);
            received = amounts.mul(getBnbPrice()).div(10 ** _tokendecimals);
        }else{
            tokenReached = getEstimateToken(amount);
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
        
        emit purchased(msg.sender, tokenReached);
        return true;
    }
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
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * return token_amount type uint256
     */
    function getEstimateToken(uint256 _amount) private view returns(uint256) {

        require(_amount > 0, 'Litedex: Amount cannot 0');
        require(_amount >= getMinContribution(), "Litedex: amount is lower than min contribution");
        require(getCurrentPrice() > 0, 'Litedex: Price is not initialized');
        require(getTokenSold()< getTotalCap(), 'Litedex: total cap has reached');

        uint256 tokendecimal = token.decimals();
        uint256 estimateToken;
        
        estimateToken = _amount.mul(10 ** tokendecimal).div(getCurrentPrice());
        if(estimateToken >= getTotalCap().sub(getTokenSold()).mul(10 ** tokendecimal)){
            estimateToken = getTotalCap().sub(getTokenSold()).mul(10 ** tokendecimal);
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
     * function to decrease total cap*/
    function decreaseTotalCap(uint256 cap) onlyOwner external returns(uint256){
        total_cap = total_cap.sub(cap);
        token_available = (token_available > cap) ? token_available.sub(cap) : 0;
        
        uint256 _id = getCurrentPhase();
        crowdsaleInfo[_id].totalCap = total_cap;
        return total_cap;
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
     * Function for getting current price
     * 
     * return price (uint256)
     */
    
    function getCurrentPrice() public view returns(uint256){
        return price;
    }
    
    /**
     * Function for getting current price in bnb
     * return price (uint256)
     */
 
     function getTotalBNBReceived() external view returns(uint256){
        return stakedBNB;
    }

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
     * Function for getting current min contribution
     * 
     * return min_contribution (uint256)
     */
    
    function getMinContribution() public view returns(uint256){
        return min_contribution;
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
     * Function for getting current total cap
     * 
     * return cap (uint256)
     */
    
    function getTotalCap() public view returns(uint256){
        return total_cap;
        
    }
    
    /**
     * Function for getting current token told
     * 
     */
    
    function getTokenSold() public view returns(uint256){
        return token_sold;
    }
    
    /**
     * Function for withdraw token or bnb
     */
     
    function withdrawToken(uint256 pid) external onlyOwner returns(bool){
        require(getTotalReceived() > 0, 'Litedex: total received is 0');
        
        //checking token balance 
        IBEP20 pair = IBEP20(tokenApproved[pid].tokenAddress);
        
        if(address(pair) == address(wrappedbnb)){
            withdrawBNB(); 
        }else{
            uint256 _balance = pair.balanceOf(address(this));
            
            //validate and distribute token to owner
            require(_balance > 0, 'Litedex: balance exceed withdrawl');
            pair.transfer(fundraiser, _balance);
            
            emit withdraw(fundraiser, _balance);
        }
        return true;
    }
    
    function withdrawBNB() public onlyOwner{
        //validate total received
        require(getTotalReceived() > 0, 'Litedex: total received is 0');
        
        //validate the balance have to higher than 0
        require(stakedBNB > 0, 'Litedex: balance exceed withdrawl');
        uint256 _balance = wrappedbnb.balanceOf(address(this));
        
        IWBNB(address(wrappedbnb)).withdraw(_balance);
        safeTransferBNB(fundraiser, _balance);
        
        // wrappedbnb.transfer(fundraiser, stakedBNB);
        stakedBNB = 0;
        
        emit withdraw(msg.sender, stakedBNB.mul(getBnbPrice()).div(1e18));
    }
    
    function withdrawLDX(uint256 amount) external onlyOwner {
        require(amount > 0 , 'Litedex: amount have to higher than 0');
        token.transfer(owner, amount);
    }
    
    function recoverStuckToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0));
        IBEP20 _token = IBEP20(tokenAddress);
        _token.transfer(owner, _token.balanceOf(address(this)));
    }

    function recoverStuckBNB() external onlyOwner {
        return safeTransferBNB(fundraiser, address(this).balance);
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
     * Functions safeTransfer
     * 
     */
    
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Litedex: BNB_TRANSFER_FAILED');
    }
}