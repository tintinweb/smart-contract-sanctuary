/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

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


 interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external  view returns (uint256);
    function transfer(address to, uint256 value) external  returns (bool ok);
    function transferFrom(address from, address to, uint256 value) external returns (bool ok);
    function approve(address spender, uint256 value)external returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BitmindCrowdsale {
    using SafeMath for uint256;

    struct Participant {
        uint256 amount;   // How many tokens the user has provided.
    }
    struct CrowdsaleHistory {
        uint256 id;
        uint256 start_time;
        uint256 end_time;
        uint256 initial_price;
        uint256 final_price;
        uint256 final_cap;
        uint256 total_received;
        uint256 token_available;
        uint256 token_sold;
    }
      
    modifier onlyOwner {
        require(msg.sender == owner, 'BitmindMsg: Only Owner'); 
        _;
    }
    modifier onlyWhileOpen{
        //Validation Crowdsale
        require(start_time > 0 && end_time > 0 , 'BitmindMsg: Crowdsale is not started yet');
        require(block.timestamp > start_time && block.timestamp < end_time, 'BitmindMsg: Crowdsale is not started yet');
        _;
    }
     
    modifier onlyFreezer{
        require(msg.sender == freezerAddress, 'BitmindMsg: Only Freezer Address');
        _;
    }

    /**
     * Configurator Crowdsale Contract
     */
    address payable private owner;
    address private freezerAddress;

    /**
     * Token Address for Crowdsale Contract
     */
    IERC20 private tokenAddress;
    IERC20 private pairAddress;
    
    /**
     * Time Configuration
     */
    uint256 private start_time;
    uint256 private end_time;
    bool private pause;
    
    /** 
     * Crowdsale Information
     */
    uint256 private min_contribution;
    uint256 private max_contribution;
    uint256 public cap;
    uint256 private rate;
    uint256 private price;
    uint256 public token_available;
    uint256 public total_received;
    uint256 public token_sold;
    
    /**
     * Participant Information
     */
    mapping (address => Participant) public userInfo;
    address[] private addressList;
    
    mapping (uint256 => CrowdsaleHistory) public crowdsaleInfo;
    uint256[] private crowdsaleid;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, uint256 amount);
    
    /**
     * Event shown after change Opening Time 
     * @param owner : who owner this contract
     * @param openingtime : time when the Crowdsale started
     */
    event setOpeningtime(address indexed owner, uint256 openingtime);
    
    /**
     * Event shown after change Closing Time
     * @param owner : who owner this contract
     * @param closingtime : time when the Crowdsale Ended
     */
    event setClosingtime(address indexed owner, uint256 closingtime);
    
     /**
     * Event for withdraw usdt token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended
     */
    event WithdrawUSDT(address indexed owner, uint256 amount);
    
    /**
     * Event for withdraw bmd token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended
     */
    event WithdrawBMD(address indexed owner, uint256 amount);
  
  /**
     * Event for Transfer Ownership
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    
    /**
     * Event for Transfer Freezer Admin
     * @param previousFreezer : Freezer of Crowdsale contract
     * @param newFreezer : new Freezer of Crowdsale contract
     * @param time : time when transferFreezer function executed
     */
    event FreezerTransferred(address indexed previousFreezer, address indexed newFreezer, uint256 time);
    
     /**
     * Event for Freeze the Crowdsale
     * @param FreezerAddress : Address who can freeze Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event FreezeCrowdsale(address indexed FreezerAddress, uint256 time);
    
    /**
     * Event for Unfreeze the Crowdsale
     * @param FreezerAddress : Address who can freeze Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event UnfreezeCrowdsale(address indexed FreezerAddress, uint256 time);
    
    /**
     * Event for Initializing Crowdsale Contract
     * @param Token : Main Token which will be distributed in Crowdsale
     * @param Pair : Pair Token which will be used for transaction in Crowdsale
     * @param owner : Address who can initialize Crowdsale contract
     * @param min_contribution : min contribution for transaction in Crowdsale
     * @param max_contribution : max contribution for transaction in Crowdsale
     * @param start_time : time when the Crowdsale starts
     * @param end_time : time when the Crowdsale ends
     * @param rate : increasing price every period
     * @param initial_price : initial price of Crowdsale
     */
    event Initializing(
        address indexed Token,
        address indexed Pair,
        address indexed owner, 
        uint256 min_contribution, 
        uint256 max_contribution,
        uint256 start_time,
        uint256 end_time,
        uint256 rate,
        uint256 initial_price
    );

    /**
     * Constructor of Bitmind Crowdsale Contract
     */
     
    constructor() public {
        owner = msg.sender;
        freezerAddress = msg.sender;
        pause = false;
    }
    
    /**
     * Function for Initialize default configuration of Crowdsale
     */
    function initialize(
        address Token,
        address Pair,
        uint256 MinContribution,
        uint256 MaxContribution,
        uint256 initial_cap,
        uint256 StartTime,
        uint256 EndTime,
        uint256 initial_price,
        uint256 initial_rate
    ) public onlyOwner returns(bool){
        tokenAddress = IERC20(Token);
        pairAddress = IERC20(Pair);
        
        require(initial_price > 0 , "BitmindMsg: initial price must higher than 0");
        price = initial_price;
        
        require(StartTime > 0, "BitmindMsg: start_time must higher than 0");
        start_time = StartTime;
        
        require(EndTime > 0, "BitmindMsg: end_time must higher than 0");
        end_time = EndTime;
        
        require(MinContribution > 0, "BitmindMsg: min_contribution must higher than 0");
        min_contribution = MinContribution;
        
        require(MaxContribution > 0, "BitmindMsg: max_contribution must higher than 0");
        max_contribution = MaxContribution;
        
        require(initial_rate > 0, "BitmindMsg: initial_rate must higher than 0");
        rate = initial_rate;
        
        
        cap = initial_cap;
        token_available = initial_cap;
        token_sold = 0;
        total_received = 0;
        
        uint256 id = crowdsaleid.length.add(1);
        crowdsaleid.push(id);
        crowdsaleInfo[id].id = id;
        crowdsaleInfo[id].start_time = StartTime;
        crowdsaleInfo[id].end_time = EndTime;
        crowdsaleInfo[id].initial_price = initial_price;
        crowdsaleInfo[id].final_price = initial_price;
        crowdsaleInfo[id].final_cap = initial_cap;
        crowdsaleInfo[id].token_available = token_available;
        
        emit Initializing(Token, Pair, msg.sender, MinContribution, MaxContribution, StartTime, EndTime, initial_rate, initial_price);
        return true;
    }
    
    /**
     * Function for Purchase Token on Crowdsale
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function Purchase(uint256 amount) external onlyWhileOpen returns(bool){
        
        require(pause == false, 'BitmindMsg: Crowdsale is freezing');
        
        require(price > 0, 'BitmindMsg: Initial Prize is not set yet');
        
        if (min_contribution > 0 && max_contribution > 0 ){
            require(amount >= min_contribution && amount <= max_contribution, "BitmindMsg: Amount invalid");
        }
        
        uint256 tokenReached = getEstimateToken(amount);
        require(tokenReached > 0, "BitmindMsg: Calculating Error!");
        require(token_available > 0 && token_available >= tokenReached, "BitmindMsg: INSUFFICIENT BMD");
        
        pairAddress.transferFrom(msg.sender, address(this), amount.div(1e12));
        total_received = total_received.add(amount);
        
        crowdsaleInfo[crowdsaleid.length].total_received = total_received;
        crowdsaleInfo[crowdsaleid.length].final_price = getPrice();
        
        if (userInfo[msg.sender].amount == 0) {
          addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(amount);
        
        token_available = token_available.sub(tokenReached);
        token_sold = token_sold.add(tokenReached);
        
        crowdsaleInfo[crowdsaleid.length].token_available = token_available;
        crowdsaleInfo[crowdsaleid.length].token_sold = token_sold;
    
        tokenAddress.transfer(msg.sender, tokenReached);
        
        emit TokensPurchased(msg.sender, tokenReached);
        return true;
    }
    
    /**
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * 
     * return token_amount type uint256
     */
    function getEstimateToken(uint256 _amount) private view returns(uint256) {
        
        uint256 token_amount;
        uint256 a;
        uint256 b;
        uint256 phase_1 = cap.mul(50).div(100);
        uint256 phase_2 = cap.mul(80).div(100);
        uint256 phase_3 = cap.mul(100).div(100);
        
        uint256 get = _amount.div(getPrice().div(1e18));
        if(token_available > cap.sub(phase_1)){
            if(token_available.sub(get) < cap.sub(phase_1)){
                a = token_available.sub(cap.sub(phase_1));
                b = _amount.sub(a.mul(getPrice().div(1e18))).div(price.add(rate.mul(1)).div(1e18));
                token_amount = a.add(b);
            }else{
                token_amount = get;
            }
        }else if(token_available > cap.sub(phase_2)){
            if(token_available.sub(get) < cap.sub(phase_2)){
                a = token_available.sub(cap.sub(phase_2));
                b = _amount.sub(a.mul(getPrice().div(1e18))).div(price.add(rate.mul(2)).div(1e18));
                token_amount = a.add(b);
            }else{
                token_amount = get;
            }
        }else if(token_available > cap.sub(phase_3)){
            if(token_available.sub(get) < cap.sub(phase_3)){
                token_amount = token_available.sub(phase_3);
            }else{
                token_amount = get;
            }
        }
        return token_amount;
    }
    
    /**
     * Function for getting current price
     * 
     * return price (uint256)
     */
    
    function getPrice() public view returns(uint256){
        require(price > 0 && token_available > 0 && cap > 0, "BitmindMsg: Initializing contract first");
        
        if(token_available > cap.sub(cap.mul(50).div(100))){
            return price;
        }else if(token_available > cap.sub(cap.mul(80).div(100))){
            return price.add(rate.mul(1));
        }else if(token_available > cap.sub(cap.mul(100).div(100))){
            return price.add(rate.mul(2));
        }else{
            return price.add(rate.mul(2));
        }
    }
    
    
    /**
     * Function for withdraw usdt token on Crowdsale
     * 
     * return event WithdrawUSDT
     */
     
    function withdrawUSDT() public onlyOwner returns(bool){
         require(total_received>0, 'BitmindMsg: Pair Token INSUFFICIENT');
         
         uint256 balance = pairAddress.balanceOf(address(this));
         pairAddress.transfer(msg.sender, balance);
         emit WithdrawUSDT(msg.sender,balance);
         return true;
    }
    
     /**
     * Function for withdraw bmd token on Crowdsale
     * 
     * return event WithdrawUSDT
     */
     
    function withdrawBMD() public onlyOwner returns(bool){
         require(token_available > 0, 'BitmindMsg: Distributed Token INSUFFICIENT');
         
         uint256 balance = tokenAddress.balanceOf(address(this));
         tokenAddress.transfer(owner, balance);
         emit WithdrawBMD(msg.sender, balance);
         return true;
    }
    
    /**
     * Function to get opening time of Crowdsale
     */
    
    function openingTime() public view returns(uint256){
        return start_time;
    }
    
    /**
     * Function to get closing time of Crowdsale
     */
    
    function closingTime() public view returns(uint256){
        return end_time;
    }
    
    /**
     * Function to get minimum contribution of Crowdsale
     */
    function MIN_CONTRIBUTION() public view returns(uint256){
         return min_contribution;
    }
    /**
     * Function to get maximum contribution of Crowdsale
     */
    function MAX_CONTRIBUTION() public view returns(uint256){
        return max_contribution;
    }
      
    /**
     * Function to get rate which user get during transaction per 1 pair on Crowdsale 
     */
    function Rate() public view returns(uint256){
        return rate;
    }
    /**
     * Function to get status of Crowdsale which user get during transaction per 1 pair on Crowdsale 
     */
    function Pause() public view returns(bool){
        return pause;
    }
    
    /**
     * Function to get total participant of Crowdsale
     * 
     * return total participant
     */
    
    function totalParticipant() public view returns(uint){
        return addressList.length;
    }
    
    /**
     * Function to set opening time of Crowdsale
     * @param _time : time for opening time
     * 
     * return event OpeningTime
     */
     
    function changeOpeningTime(uint256 _time) public onlyOwner returns(bool) {
        require(_time >= block.timestamp, "BitmindMsg: Opening Time must before current time");
        
        start_time = _time;
        emit setOpeningtime(owner, _time);
        return true;
    }
    
    /**
     * Function to set closing time of Crowdsale
     * @param _time : time for opening time
     * 
     * return event ClosingTime
     */
    function changeClosingTime(uint256 _time) public onlyOwner returns(bool) {
        require(_time >= start_time, "BitmindMsg: Closing Time already set");
        
        end_time = _time;
        emit setClosingtime(owner, _time);
        return true;
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
    
    /**
     * Function to change Freezer Address
     * Only Freezer who could access this function
     * 
     * return event FreezerTransferred
     */
    
    function transferFreezer(address freezer) onlyFreezer public returns(bool){
        freezerAddress = freezer;
        
        emit FreezerTransferred(msg.sender, freezer, block.timestamp);
        return true;
    }
    
    /**
     * Function to freeze or pause crowdsale
     * Only Freezer who could access this function
     * 
     * return true
     */
    
    function freeze() public onlyFreezer returns(bool) {
        pause = true;
        
        emit FreezeCrowdsale(freezerAddress, block.timestamp);
        return true;
    }
    
    /**
     * Function to unfreeze or pause crowdsale
     * Only Freezer who could access this function
     * 
     * return true
     */
    
    function unfreeze() public onlyFreezer returns(bool) {
        pause = false;
        
        emit UnfreezeCrowdsale(freezerAddress, block.timestamp);
        return true;
    }
}