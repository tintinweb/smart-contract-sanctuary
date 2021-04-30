/**
 *Submitted for verification at Etherscan.io on 2021-04-30
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
    uint256 private rate;
    uint256 private price;
    uint private multiplier;
    uint256 public totalSold;
    
    /**
     * Participant Information
     */
    mapping (address => Participant) public userInfo;
    address[] private addressList;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, uint256 amount);
    
    /**
     * Event for Start Crowdsale
     * @param owner : who owner this contract
     * @param openingtime : time when the Crowdsale started
     */
    event setOpeningtime(address indexed owner, uint256 openingtime);
    
    /**
     * Event for Close Crowdsale
     * @param owner : who owner this contract
     * @param closingtime : time when the Crowdsale Ended
     */
    event setClosingtime(address indexed owner, uint256 closingtime);
    
     /**
     * Event for withdraw pair token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended
     */
    event WithdrawUSDT(address indexed owner, uint256 amount);
    
    /**
     * Event for withdraw distributed token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended
     */
    event WithdrawToken(address indexed owner, uint256 amount);
  
  /**
     * Event for withdraw distributed token from contract to owner
     * @param previousOwner : owner Crowdsale contract
     * @param newOwner : New Owner of Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 time);
    
    /**
     * Event for withdraw distributed token from contract to owner
     * @param previousFreezer : Freezer of Crowdsale contract
     * @param newFreezer : new Freezer of Crowdsale contract
     * @param time : time when transferFreezer function executed
     */
    event FreezerTransferred(address indexed previousFreezer, address indexed newFreezer, uint256 time);
    
     /**
     * Event for withdraw distributed token from contract to owner
     * @param FreezerAddress : Address who can freeze Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event FreezeCrowdsale(address indexed FreezerAddress, uint256 time);
    
    /**
     * Event for withdraw distributed token from contract to owner
     * @param FreezerAddress : Address who can freeze Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event UnfreezeCrowdsale(address indexed FreezerAddress, uint256 time);
    
    /**
     * Event for withdraw distributed token from contract to owner
     * @param owner : Address who can initialize Crowdsale contract
     * @param min_contribution : min contribution for transaction in Crowdsale
     * @param max_contribution : max contribution for transaction in Crowdsale
     * @param start_time : time when the Crowdsale starts
     * @param end_time : time when the Crowdsale ends
     * @param rate : time when changeOwner function executed
     */
    event Initializing(
        address indexed owner, 
        uint256 min_contribution, 
        uint256 max_contribution,
        uint256 start_time,
        uint256 end_time,
        uint256 rate,
        uint256 initial_price,
        uint initial_multiplier
    );

    /**
     * Constructor of Bitmind Crowdsale Contract
     * @param _token : token who will be distributed to user on Crowdsale
     * @param _pair : pair token who user send to Crowdsale contract
     */
     
    constructor(address _token, address _pair) public {
        owner = msg.sender;
        tokenAddress = IERC20(_token);
        pairAddress = IERC20(_pair); 
        freezerAddress = msg.sender;
        pause = false;
    }
    
    /**
     * 
     */
    function initialize(
        uint256 MinContribution,
        uint256 MaxContribution,
        uint256 StartTime,
        uint256 EndTime,
        uint256 initial_price,
        uint256 initial_rate,
        uint initial_multiplier
    ) public onlyOwner returns(bool){
        multiplier = initial_multiplier;
        price = initial_price;
        min_contribution = MinContribution;
        max_contribution = MaxContribution;
        start_time = StartTime;
        end_time = EndTime;
        rate = initial_rate;
        
        emit Initializing(msg.sender, MinContribution, MaxContribution, StartTime, EndTime, initial_rate, initial_price, initial_multiplier);
        return true;
    }
    
    function getPrice() public view returns(uint256){
        uint256 timeRanged = end_time.sub(start_time);
        uint256 multiplier_days = timeRanged.div(1 days).div(multiplier);
        uint256 phase = multiplier_days.mul(1 days);
        
        if(block.timestamp >= start_time && block.timestamp <= start_time.add(phase.mul(1))){
            return price;
        }else if(block.timestamp > start_time.add(phase.mul(1)) && block.timestamp <= start_time.add(phase.mul(2))){
            return price.add(rate);
        }else if(block.timestamp > start_time.add(phase.mul(2)) && block.timestamp <= timeRanged.mul(1 days)){
            return price.add(rate.mul(2));
        }
        
    }
    
    
    /**
     * Function for Purchase Token on Crowdsale
     * @param _amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function Purchase(uint256 _amount) external onlyWhileOpen returns(bool){
        
        require(pause == false, 'BitmindMsg: Crowdsale is freezing');
        require(price > 0, 'BitmindMsg: Initial Prize is not set');
        
        uint256 amount = _amount.mul(10e12).div(getPrice()).mul(10e18);
        
        if (min_contribution > 0 && max_contribution > 0 ){
            require(amount >= min_contribution && amount <= max_contribution, "BitmindMsg: Amount invalid");
        }
        pairAddress.transferFrom(msg.sender, address(this), _amount);
        
       
        
        require(remainingToken() > 0 && remainingToken() >= amount, "BitmindMsg: INSUFFICIENT BMD");
        
        
        if (userInfo[msg.sender].amount == 0) {
          addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
        
        totalSold = totalSold.add(amount);
        tokenAddress.transfer(msg.sender, amount);
        
        emit TokensPurchased(msg.sender, amount);
        return true;
    }
    
    
    /**
     * Function for withdraw pair token on Crowdsale
     * 
     * return event WithdrawUSDT
     */
     
    function withdrawUSDT() public onlyOwner returns(bool){
         require(collectedPair()>0, 'BitmindMsg: Pair Token INSUFFICIENT');
         
         pairAddress.transfer(msg.sender, collectedPair());
         emit WithdrawUSDT(msg.sender,collectedPair());
         return true;
    }
    
     /**
     * Function for withdraw pair token on Crowdsale
     * 
     * return event WithdrawUSDT
     */
     
    function withdrawToken() public onlyOwner returns(bool){
         require(remainingToken()>0, 'BitmindMsg: Distributed Token INSUFFICIENT');
         
         tokenAddress.transfer(owner, remainingToken());
         emit WithdrawToken(msg.sender, remainingToken());
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
     * Function to get remaining token of distributed token
     * 
     * return balanceOf token from Crowdsale Contract
     */
    function remainingToken() public view returns(uint256){
        return tokenAddress.balanceOf(address(this));
    }
    
    /**
     * Function to get collected token of pair token
     * 
     * return balanceOf token from Crowdsale Contract
     */
    function collectedPair() public view returns(uint256){
        return pairAddress.balanceOf(address(this));
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
        require(_time >= block.timestamp, "BitmindMsg: Opening Time must before current_time");
        
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
    
    function transferFreezer(address freezer) onlyFreezer public returns(bool){
        freezerAddress = freezer;
        
        emit FreezerTransferred(msg.sender, freezer, block.timestamp);
        return true;
    }
    
    function freeze() public onlyFreezer returns(bool) {
        pause = true;
        
        emit FreezeCrowdsale(freezerAddress, block.timestamp);
        return true;
    }
    
    function unfreeze() public onlyFreezer returns(bool) {
        pause = false;
        
        emit UnfreezeCrowdsale(freezerAddress, block.timestamp);
        return true;
    }
    

}