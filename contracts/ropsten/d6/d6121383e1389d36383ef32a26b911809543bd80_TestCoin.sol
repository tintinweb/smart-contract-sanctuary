/**
 *Submitted for verification at Etherscan.io on 2021-05-21
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
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

/**
* @title Test Contract For ERC20 Tokens
* @dev Test tokens as per ERC20 Standards
*/
contract TestCoin is IERC20, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint public totalEthRewards = 0;
    uint stakeNum = 0;
    uint amtByDay = 27397260274000000000;
    address public stakeCreator;
    bool public isPaused = false;
    address[] public customers;
    uint public stakePeriod = 20 minutes;

    struct Stake {
        uint start;
        uint end;
        uint CoinLockedTotal;
        uint CoinxReward;
        uint ethReward;
    }

    struct StakeStruct {
        uint CoinLocked;
        uint time;
    }

    struct Rewards {
        uint coinx;
        uint eth;
    }

    event logLockedTokens(address holder, uint amountLocked, uint timeLocked, uint stakeNum);
    event logUnlockedTokens(address holder, uint amountUnlocked, uint timeUnlocked, uint stakeNum);
    event logWithdraw(address holder, uint coinx, uint eth, uint time);
    event logCloseStake(address stakeOwner, uint stakeNum, uint timeClosed);

    modifier paused {
        require(isPaused == false, "This contract was paused by the owner!");
        _;
    }

    modifier exist (uint index) {
        require(index <= stakeNum, 'This stake does not exist.');
        _;
    }

    mapping (address => bool) public regCustomer;
    mapping (address => StakeStruct[]) public _stakes;
    mapping (uint => Stake) public stakes;
    mapping (address => Rewards) public rewards;
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowed;

    IERC20 public UNITEST;

    constructor(address payable _owner, address test_token) public {
        owner = _owner;
        stakeCreator = owner;
        symbol = "TESTC";
        name = "TestCoin";
        decimals = 18;
        _totalSupply = 100000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
        stakes[0] = Stake(now, 0, 0, 0, 0);
        UNITEST = IERC20(test_token);
    }
    function getStakesCount(address holder) public view returns(uint) {
        return _stakes[holder].length;
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
     * @dev Set new Stake Period.
     * @param newStakePeriod indicates new stake period, it was 7 days by default.
     */
    function setStakePeriod(uint256 newStakePeriod) external onlyOwner {
        stakePeriod = newStakePeriod;
    }

    /**
     * @dev Stake  tokens for earning rewards, Tokens will be deducted from message sender account
     * @param amount Amount of tokens to be staked in the pool
     */
    function lock(uint amount) external paused {
        require(amount > 0, 'Payment must be greater than 0.');
        require(UNITEST.balanceOf(msg.sender) >= amount, 'Holder does not have enough tokens.');
        require(UNITEST.allowance(msg.sender, address(this)) >= amount, 'Call Approve function firstly.');

        UNITEST.transferFrom(msg.sender, address(this), amount);

        Stake memory stake = stakes[stakeNum];
        StakeStruct memory newStake;
        newStake.CoinLocked = amount;
        newStake.time = block.timestamp;
        _stakes[msg.sender].push(newStake);

        stake.CoinLockedTotal = stake.CoinLockedTotal.add(amount);
        stakes[stakeNum] = stake;

        if(!regCustomer[msg.sender]) {
            customers.push(msg.sender);
            regCustomer[msg.sender] = true;
        }

        emit logLockedTokens(msg.sender, amount, newStake.time, stakeNum);
    }

    /**
     * @dev stakeOf Calculate  the total amount staked by account
     * @param account address which tries to unlock all Test token staked before
     */
    function stakeOf(address account) public view returns (uint256) {
        if (_stakes[account].length <= 0) return 0;
        
        uint256 stake = 0;

        for (uint i = 0; i < _stakes[account].length; i++) {
            stake = stake.add(uint256(_stakes[account][i].CoinLocked));
        }
        
        return stake;
    }

    /**
     * @dev Withdraw My Staked Tokens from staker pool
     */
    function unlock() external paused {
        uint256 unlockAmount = stakeOf(msg.sender);

        require(unlockAmount > 0, 'You do not have locked tokens.');
        require(UNITEST.balanceOf(address(this))  >= unlockAmount, 'Insufficient account balance!');

        Stake memory stake = stakes[stakeNum];
        stake.CoinLockedTotal = stake.CoinLockedTotal.sub(unlockAmount);
        stakes[stakeNum] = stake;

        UNITEST.transfer(msg.sender, unlockAmount);
        delete _stakes[msg.sender];
        regCustomer[msg.sender] = false;
        
        emit logUnlockedTokens(msg.sender, unlockAmount, block.timestamp, stakeNum);
    }

    /**
     * @dev Stake Creator finalizes the stake, the stake receives the accumulated ETH as reward and calculates everyone's percentages.
     */
    function closeStake() external {
        require(msg.sender == stakeCreator, 'You cannot call this function');

        Stake memory stake = stakes[stakeNum];
        require(now >= stake.start.add(stakePeriod), 'You cannot call this function until stakePeriod is over');

        stake.end = now;
        stake.ethReward = stake.ethReward.add(totalEthRewards);

        uint amtCoinx = stake.end.sub(stake.start).mul(amtByDay).div(1 days);
        
        if(amtCoinx > balances[owner]) {
            amtCoinx = balances[owner];
        }
        
        stake.CoinxReward = amtCoinx;
        stakes[stakeNum] = stake;
        
        emit logCloseStake(msg.sender, stakeNum, block.timestamp);

        uint256 sumAmountAge = _getSumAmountAge(stake.end);

        for (uint i = 0; i < customers.length; i++) {
            uint256 _amountAge = _getAmountAge(customers[i], stake.end);
            
            if(_amountAge > 0) {
                Rewards memory rwds = rewards[customers[i]];
                rwds.coinx = rwds.coinx.add(_amountAge.mul(amtCoinx).div(sumAmountAge));
                rwds.eth = rwds.eth.add(_amountAge.mul(stake.ethReward).div(sumAmountAge));
                rewards[customers[i]] = rwds;
            }
        }
        
        stakeNum++;
        stakes[stakeNum] = Stake(now, 0, stake.CoinLockedTotal, 0, 0);
        totalEthRewards = 0;
    }

    function _getAmountAge(address _address, uint256 _now) internal view returns (uint256) {
        if (_stakes[_address].length <= 0) return 0;
        
        uint256 _amountAge = 0;
        Stake memory stake = stakes[stakeNum];

        for (uint i = 0; i < _stakes[_address].length; i++) {
            uint256 nAmountSeconds = 0;
            
            if(_stakes[_address][i].time < stake.start) {
                nAmountSeconds = _now.sub(stake.start);
            } else {
                nAmountSeconds = _now.sub(_stakes[_address][i].time);
            }
            
            _amountAge = _amountAge.add(_stakes[_address][i].CoinLocked.mul(nAmountSeconds).div(1 days));
        }

        return _amountAge;
    }

    function _getSumAmountAge(uint256 _now) internal view returns (uint256) {
        uint256 _sumAmountAge = 0;

        for (uint i = 0; i < customers.length; i++) {
            uint256 _amountAge = 0;
            _amountAge = _getAmountAge(customers[i], _now);
            
            if(_amountAge > 0) {
                _sumAmountAge = _sumAmountAge.add(_amountAge);
            }
        }

        return _sumAmountAge;
    }

    /**
     * @dev Withdraw Reward Test Tokens and ETH
     */
    function withdraw() external paused {
        Rewards memory rwds = rewards[msg.sender];

        require((rwds.coinx > 0 || rwds.eth > 0), 'You have no any rewards to withdraw');
        require(balances[owner] >= rwds.coinx, 'Insufficient account balance!');
        require(address(this).balance >= rwds.eth,'Invalid account state, not enough funds.');

        if(rwds.coinx > 0) {
            balances[owner] = balances[owner].sub(rwds.coinx);
            balances[msg.sender] = balances[msg.sender].add(rwds.coinx);
            
            emit Transfer(owner, msg.sender, rwds.coinx);
        }

        if(rwds.eth > 0) { 
            msg.sender.transfer(rwds.eth);
        }
        
        emit logWithdraw(msg.sender, rwds.coinx, rwds.eth, block.timestamp);

        rwds.coinx = 0;
        rwds.eth = 0;
        rewards[msg.sender] = rwds;
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
    function () external payable {
        totalEthRewards = totalEthRewards.add(msg.value);
    }

    function close() external onlyOwner {
        selfdestruct(owner);
    }
    
}