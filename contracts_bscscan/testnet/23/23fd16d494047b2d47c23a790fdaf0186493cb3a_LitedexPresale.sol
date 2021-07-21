/**
 *Submitted for verification at BscScan.com on 2021-07-21
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
    function allowance(address owner, address spender) external view returns (uint256);

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
    /**
     * Configurator Crowdsale Contract
     */
    address payable internal owner;
    address internal pauser;
    
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Litedex: Only Owner'); 
        _;
    }
    modifier onlyPauser{
        require(msg.sender == pauser, 'Litedex: Only Pauser Address');
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
     * Event for Transfer Pauser Admin
     * @param previousPauser : Pauser of Crowdsale contract
     * @param newPauser : new Pauser of Crowdsale contract
     * @param time : time when transferPauser function executed
     */
    event pauserTransferred(address indexed previousPauser, address indexed newPauser, uint256 time);
    
    
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
     * Function to change Pauser Address
     * Only Pauser who could access this function
     * 
     * return event pauserTransferred
     */
    
    function transferPauser(address pauserAddress) onlyPauser public returns(bool){
        pauser = pauserAddress;
        
        emit pauserTransferred(msg.sender, pauserAddress, block.timestamp);
        return true;
    }
    constructor() internal{
        owner = msg.sender;
        pauser = msg.sender;
    }
}

contract TimeCrowdsale is Ownable {
    uint internal _start;
    uint internal _end;
    bool internal pausable;
    
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
    event closingtime(address indexed owner, uint256 closingtime);
    
     /**
     * Event for Freeze the Crowdsale
     * @param pauser : Address who can pause Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event Pause(address indexed pauser, uint256 time);
    
    /**
     * Event for Unfreeze the Crowdsale
     * @param pauser : Address who can pause Crowdsale contract
     * @param time : time when changeOwner function executed
     */
    event Unpause(address indexed pauser, uint256 time);
    
    modifier isNotStarted {
        require(getBlockTimestamp() <= _start, 'Litedex: Pre-crowdsale is already started');
        _;
    }
    modifier onlyWhileNotOpen {
        require(getBlockTimestamp() < _start && getBlockTimestamp() > _end, 'Litedex: Pre-crowdsale is already started');
        require(isPaused() == true, 'Litedex: Pre-crowdsale is unpaused');
        _;
    }
    
    modifier onlyWhileOpen {
        require(getBlockTimestamp() >= _start && getBlockTimestamp() <= _end, 'Litedex: Pre-crowdsale is not started');
        require(isPaused() == false, 'Litedex: Pre-crowdsale is paused');
        _;
    }
    
    function getStartTime() public view returns(uint256){
        return _start;
    }
    
    function getEndTime() public view returns(uint256){
        return _end;
    }
    
    function getBlockTimestamp() internal view returns(uint256){
        return block.timestamp;
    }
    
    function setTimeCrowdsale(uint256 start, uint256 end) external onlyOwner returns(uint256 startTime, uint256 endTime){
        _start = start;
        _end = end;
        return (start,end);
    }
    
    function updateStartTime(uint256 time) external onlyOwner isNotStarted returns(uint256 startTime){
        require(time < _end, 'Litedex: time is higher than end time');
        _start = time;
        return _start;
    }
    
    function updateEndTime(uint256 time) external onlyOwner returns(uint256 endTime){
        require(time > _start, 'Litedex: time is lower than start time');
        _end = time;
        return _end;
    }
    
     /**
     * Function to get status of Crowdsale which user get during transaction per 1 pair on Crowdsale 
     */
    function isPaused() public view returns(bool){
        return pausable;
    }
    
    function pause() external onlyWhileOpen onlyPauser returns(bool) {
        pausable = true;
        emit Pause(pauser, getBlockTimestamp());
        return true;
    }
    
    /**
     * Function to unfreeze or pause crowdsale
     * Only Pauser who could access this function
     * 
     * return true
     */
    
    function unpause() external onlyPauser returns(bool) {
        require(isPaused() == true, 'Litedex: Pre-crowdsale is unpaused');
        pausable = false;
        
        emit Unpause(pauser, getBlockTimestamp());
        return true;
    }
}
contract LitedexPresale is TimeCrowdsale{
    using SafeMath for uint256;

    struct Participant {
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

    /**
     * Token Address for Crowdsale Contract
     */
    IBEP20 private token;
    IBEP20 private pair;
    
    /**
     * Time Configuration
     */
    bool private cappable;
    
    /** 
     * Crowdsale Information
     */
    uint256 private min_contribution;
    uint256 private max_contribution;
    uint256 private cap;
    uint256 private price;
    uint256 private token_available;
    uint256 private total_received;
    uint256 private token_sold;
    
    /**
     * Participant Information
     */
    mapping (address => Participant) public userInfo;
    mapping (uint256 => Crowdsale) public crowdsaleInfo;
    
    
    address[] private addressList;
    
    uint256[] private crowdsaleList;

    /**
     * Event for token purchase logging
     * @param purchaser : who paid for the tokens and get the tokens
     * @param amount : total amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, uint256 amount);
    
     /**
     * Event for withdraw usdt token from contract to owner
     * @param owner : who owner this contract
     * @param amount : time when the Crowdsale Ended
     */
    event WithdrawUSDT(address indexed owner, uint256 amount);
    
    
    /**
     * Event for Initializing Crowdsale Contract
     * @param min_contribution : min contribution for transaction in Crowdsale
     * @param max_contribution : max contribution for transaction in Crowdsale
     * @param initial_price : initial price of Crowdsale
     */
    event Initializing(
        uint256 min_contribution, 
        uint256 max_contribution,
        uint256 initial_price
    );

    /**
     * Constructor of Litedex Crowdsale Contract
     */
     
    constructor(address tokenAddress, address pairAddress) public {
        token = IBEP20(tokenAddress);
        pair = IBEP20(pairAddress);
        pausable = false;
    }
    
    /**
     * Function for Initialize default configuration of Crowdsale
     */
    function initialize(
        uint256 MinContribution,
        uint256 MaxContribution,
        uint256 initialCap,
        uint256 initialPrice
    ) public onlyOwner onlyWhileNotOpen returns(bool) {
        
        require(initialPrice > 0 , "Litedex: initial price must higher than 0");
        price = initialPrice;
        
        require(MinContribution > 0, "Litedex: min_contribution must higher than 0");
        min_contribution = MinContribution;
        
        require(MaxContribution > 0, "Litedex: max_contribution must higher than 0");
        max_contribution = MaxContribution;
        
        if(initialCap == 0){
            cappable = false;
        }else{
            cappable = true;
            cap = initialCap;
            token_available = initialCap;
        }
        
        token_sold = 0;
        total_received = 0;
        _start = 0;
        _end = 0;
        
        uint _id = crowdsaleList.length;
        
        crowdsaleInfo[_id].phase = _id;
        
        emit Initializing(MinContribution, MaxContribution, initialPrice);
        return true;
    }
    
    /**
     * Function for Purchase Token on Crowdsale
     * @param amount : amount which user purchase
     * 
     * return deliveryTokens
     */
    
    function purchase(uint256 amount) external onlyWhileOpen returns(bool){
        
        require(price > 0, 'Litedex: Price is not initialized');
        
        if (min_contribution > 0 && max_contribution > 0 ){
            require(amount > 0 , 'Litedex: Amount cannot 0');
            require(amount >= min_contribution, "Litedex: Amount is lower than min contribution");
            require(amount < max_contribution, "Litedex: Amount is higher than max contribution");
        }
        
        uint256 tokenReached = getEstimateToken(amount);
        require(tokenReached > 0, "Litedex: Calculating Error!");
        
        if(cappable == false) {
            pair.transferFrom(msg.sender, address(this), amount);
        }else{
            uint256 _pairdecimals = pair.decimals();
            pair.transferFrom(msg.sender, address(this), tokenReached.mul(price).div(10 ** _pairdecimals));
        }
        
        uint256 _id = crowdsaleList.length;
        
        total_received = total_received.add(amount);
        crowdsaleInfo[_id].totalReceived.add(amount);

        if (userInfo[msg.sender].amount == 0) {
          addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(amount);
        
        token_sold = token_sold.add(tokenReached);
        crowdsaleInfo[_id].totalSold.add(tokenReached);
        
        if(cappable == true){
            token_available = token_available.sub(tokenReached);
        }
        token.mint(msg.sender, tokenReached);
        
        emit TokensPurchased(msg.sender, tokenReached);
        return true;
    }
    
    /**
     * Function for Estimate token which user get on Crowdsale
     * @param _amount : amount which user purchase
     * 
     * return token_amount type uint256
     */
    function getEstimateToken(uint256 _amount) public view returns(uint256) {
        require(_amount > 0, 'Litedex: Amount cannot 0');
        require(price > 0, 'Litedex: Price is not initialized');
        uint256 estimateToken;
        uint256 tokendecimal = token.decimals();
        uint256 pairdecimal = pair.decimals();
        _amount = (pairdecimal != tokendecimal) ? _amount.mul(10 ** (tokendecimal.sub(pairdecimal))) : _amount;
        
        if(cappable == false){
            estimateToken = _amount.div(price).mul(10 ** tokendecimal);
        }else{
            require(token_sold < cap, 'Litedex: total cap has reached');
            estimateToken = _amount.div(price).mul(10 ** tokendecimal);
            if(estimateToken >= cap.sub(token_sold).mul(10 ** tokendecimal)){
                estimateToken = cap.sub(token_sold).mul(10 ** tokendecimal);
            }
        }
        return estimateToken;
    }
    /**
     * Function for setting current cappable
     * 
     * return true
     */
     function setCappable(bool activeCap) onlyOwner external returns(bool){
         cappable = activeCap;
         return true;
     }
     
     /**
     * Function for setting current min contribution
     * 
     * return true
     */
     function setMinContribution(uint256 newMinContribution) onlyOwner external returns(bool){
         min_contribution = newMinContribution;
         return true;
     }
     
     /**
     * Function for setting current min contribution
     * 
     * return true
     */
     function setMaxContribution(uint256 newMaxContribution) onlyOwner external returns(bool){
         max_contribution = newMaxContribution;
         return true;
     }
     /**
     * Function for setting current price
     * 
     * return true
     */
     function setPrice(uint256 newPrice) onlyOwner external returns(bool){
         price = newPrice;
         return true;
     }
    
    /**
     * Function for getting current price
     * 
     * return price (uint256)
     */
    
    function getPrice() public view returns(uint256){
        return price;
    }
    
    /**
     * Function for getting current total received
     * 
     * return total_received (uint256)
     */
    
    function getTotalReceived() public view returns(uint256){
        return total_received;
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
     * Function for getting current token available
     * 
     * return token_available (uint256)
     */
    
    function getTokenAvailable() public view returns(uint256){
        if(isCappable() == true){
            return token_available;
        }else{
            return 0;
        }
    }
    
    /**
     * Function for getting current total cap
     * 
     * return cap (uint256)
     */
    
    function getTotalCap() public view returns(uint256){
        if(isCappable() == true){
            return cap;
        }else{
            return 0;
        }
    }
    
    /**
     * Function for getting current cappable status
     * 
     * return cappable (bool)
     */
    
    function isCappable() public view returns(bool){
        return cappable;
    }
    
    /**
     * Function for withdraw usdt token on Crowdsale
     * 
     * return event WithdrawUSDT
     */
     
    function withdraw() external onlyOwner returns(bool){
         require(total_received > 0, 'Litedex: Pair Token INSUFFICIENT');
         
         uint256 balance = pair.balanceOf(address(this));
         pair.transfer(msg.sender, balance);
         emit WithdrawUSDT(msg.sender,balance);
         return true;
    }
    
    /**
     * Function to get total participant of Crowdsale
     * 
     * return total participant
     */
    
    function getTotalParticipant() public view returns(uint){
        return addressList.length;
    }
    
   
}