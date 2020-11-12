/**
 *Submitted for verification at Etherscan.io on 2020-11-02
*/

pragma solidity ^0.5.0;

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }
    
    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}

 /**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 /**
 * @title Layerx Contract For ERC20 Tokens
 * @dev LAYERX tokens as per ERC20 Standards
 */
contract Layerx is IERC20, Owned {
    using SafeMath for uint256;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    uint public ethToNextStake = 0;
    uint stakeNum = 0;
    uint constant CAP = 1000000000000000000;
    uint constant CAP_R = 100000000;
    uint constant DAYMILLI = 86400;
    uint amtByDay = 27397260274000000000;
    address public stakeCreator;
    address[] private activeHolders;
    
    bool isPaused = false;

    struct Stake {
        uint start;
        uint end;
        uint layerLockedTotal;
        uint layerxReward;
        uint ethReward;
    }

    struct StakeHolder {
        uint layerLocked;
        uint id;
    }
    
    struct Rewards {
        uint layersx;
        uint eth;
        bool isReceived;
    }
    
    event logLockedTokens(address holder, uint amountLocked, uint stakeId);
    event logUnlockedTokens(address holder, uint amountUnlocked);
    event logNewStakePayment(uint id, uint amount);
    event logWithdraw(address holder, uint layerx, uint eth, uint stakeId);
    
    modifier paused {
        require(isPaused == false, "This contract was paused by the owner!");
        _;
    }
    
    modifier exist (uint index) {
        require(index <= stakeNum, 'This stake does not exist.');
        _;        
    }
    
    mapping (address => StakeHolder) public stakeHolders;
    mapping (address => mapping (uint => Rewards)) public rewards;
    mapping (uint => Stake) public stakes;
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowed;
    
    IERC20 UNILAYER = IERC20(0x0fF6ffcFDa92c53F615a4A75D982f399C989366b); 
    
    constructor(address _owner) public {
        owner = _owner;
        stakeCreator = owner;
        symbol = "LAYERX";
        name = "UNILAYERX";
        decimals = 18;
        _totalSupply = 40000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
        
        stakes[0] = Stake(now, 0, 0, 0, 0);    
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param tokenOwner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }   
    
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyOwner {
        require(value > 0, "Invalid Amount.");
        require(_totalSupply >= value, "Invalid account state.");
        require(balances[owner] >= value, "Invalid account balances state.");
        _totalSupply = _totalSupply.sub(value);
        balances[owner] = balances[owner].sub(value);
        emit Transfer(owner, address(0), value);
    }    
    
    /**
     * @dev Set new Stake Creator address.
     * @param _stakeCreator The address of the new Stake Creator.
     */    
    function setNewStakeCreator(address _stakeCreator) external onlyOwner {
        require(_stakeCreator != address(0), 'Do not use 0 address');
        stakeCreator = _stakeCreator;
    }
    
    /**
     * @dev Set new pause status.
     * @param newIsPaused The pause status: 0 - not paused, 1 - paused.
     */ 
    function setIsPaused(bool newIsPaused) external onlyOwner {
        isPaused = newIsPaused;
    }     

    /**
     * @dev Remove holder from the list of active holders.
     * @param holder that must be removed.
     */ 
    function removeHolder(StakeHolder memory holder) internal {
        uint openId = holder.id;
        address openWallet = activeHolders[openId];
        if(activeHolders.length > 1) {
            uint lastId = activeHolders.length-1;
            address lastWallet = activeHolders[lastId];
            StakeHolder memory lastHolder = stakeHolders[lastWallet];
            
            lastHolder.id = openId;
            stakeHolders[lastWallet] = lastHolder;
            activeHolders[openId] = lastWallet;
        }
        activeHolders.pop();
        holder.id = 0;
        stakeHolders[openWallet] = holder;        
    }    
    
    /**
    * @dev Stake LAYER tokens for earning rewards, Tokens will be deducted from message sender account
    * @param payment Amount of LAYER to be staked in the pool
    */    
    function lock(uint payment) external paused {
        require(payment > 0, 'Payment must be greater than 0.');
        require(UNILAYER.balanceOf(msg.sender) >= payment, 'Holder does not have enough tokens.');
        UNILAYER.transferFrom(msg.sender, address(this), payment);
        
        StakeHolder memory holder = stakeHolders[msg.sender];
        
        if(holder.layerLocked == 0) {
            uint holderId = activeHolders.length;
            activeHolders.push(msg.sender);
            holder.id = holderId;
        }        
        
        holder.layerLocked = holder.layerLocked.add(payment);
        
        Stake memory stake = stakes[stakeNum];
        stake.layerLockedTotal = stake.layerLockedTotal.add(payment);
        
        stakeHolders[msg.sender] = holder;
        stakes[stakeNum] = stake;
        
        emit logLockedTokens(msg.sender, payment, stakeNum);
    }    
    
    /**
    * @dev Withdraw My Staked Tokens from staker pool
    */    
    function unlock() external paused {
        StakeHolder memory holder = stakeHolders[msg.sender]; 
        uint amt = holder.layerLocked;
        require(amt > 0, 'You do not have locked tokens.');
        require(UNILAYER.balanceOf(address(this))  >= amt, 'Insufficient account balance!');
        Stake memory stake = stakes[stakeNum];
        require(stake.end == 0, 'Invalid date for unlock, please use withdraw.');
        stake.layerLockedTotal = stake.layerLockedTotal.sub(amt);
        stakes[stakeNum] = stake;
        holder.layerLocked = 0;
        stakeHolders[msg.sender] = holder;
        removeHolder(holder);        
        UNILAYER.transfer(msg.sender, amt);
        emit logUnlockedTokens(msg.sender, amt);
    }
    
    /**
    * @dev Stake Creator finalizes the stake, the stake receives the accumulated ETH as reward and calculates everyone's percentages.
    */      
    function addStakePayment() external {
        require(msg.sender == stakeCreator, 'You cannot call this function');
        Stake memory stake = stakes[stakeNum]; 
        stake.end = now;
        stake.ethReward = stake.ethReward.add(ethToNextStake);
        ethToNextStake = 0;
  
        uint days_passed = stake.end.sub(stake.start).mul(CAP_R).div(DAYMILLI);
        uint amtLayerx = days_passed.mul(amtByDay).div(CAP_R);
        
        if(amtLayerx > balances[owner]) { amtLayerx = balances[owner]; }
        
        stake.layerxReward = stake.layerxReward.add(amtLayerx);
        
        for(uint i = 0; i < activeHolders.length; i++) {
            StakeHolder memory holder = stakeHolders[activeHolders[i]];
            uint rate = holder.layerLocked.mul(CAP).div(stake.layerLockedTotal);
            rewards[activeHolders[i]][stakeNum].layersx = amtLayerx.mul(rate).div(CAP);
            rewards[activeHolders[i]][stakeNum].eth = stake.ethReward.mul(rate).div(CAP);
        }
        
        stakes[stakeNum] = stake;
        emit logNewStakePayment(stakeNum, ethToNextStake);  
        stakeNum++;
        stakes[stakeNum] = Stake(now, 0, stake.layerLockedTotal, 0, 0);
    }
    
    /**
    * @dev Withdraw Reward Layerx Tokens and ETH
    * @param index Stake index
    */    
    function withdraw(uint index) external paused exist(index) {
        Rewards memory rwds = rewards[msg.sender][index];
        Stake memory stake = stakes[index];
        
        require(stake.end <= now, 'Invalid date for withdrawal.');
        require(rwds.isReceived == false, 'You already withdrawal your rewards.');
        require(balances[owner] >= rwds.layersx, 'Insufficient account balance!');
        require(address(this).balance >= rwds.eth,'Invalid account state, not enough funds.');
   
        if(rwds.layersx > 0) {
            balances[owner] = balances[owner].sub(rwds.layersx);
            balances[msg.sender] = balances[msg.sender].add(rwds.layersx);  
            emit Transfer(owner, msg.sender, rwds.layersx);
        }
        
        if(rwds.eth > 0) {
            msg.sender.transfer(rwds.eth);    
        }
        
        rwds.isReceived = true;
        
        rewards[msg.sender][index] = rwds;
        emit logWithdraw(msg.sender, rwds.layersx, rwds.eth, index);
    }
    
    /**
    * @dev Function to get the number of stakes
    * @return number of stakes
    */    
    function getStakesNum() external view returns (uint) {
        return stakeNum+1;
    }
    

    /**
    * @dev Receive ETH and add value to the accumulated eth for stake
    */      
    function() external payable {
        ethToNextStake = ethToNextStake.add(msg.value); 
    }
}