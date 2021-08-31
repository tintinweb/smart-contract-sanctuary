//SourceUnit: PallaStakeTest.sol

pragma solidity 0.5.10;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface ITRC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
}

contract PallaStake is Ownable{
	using SafeMath for uint256;

    ITRC20 public pallaToken;
    ITRC20 public LPT;

    // uint256 constant public PALLA_STAKE_MIN    = 100 * 10**8;
    // uint256 constant public LP_STAKE_MIN       = 100 * 10**6;
    uint256 constant public PALLA_STAKE_MIN    = 1 ;
    uint256 constant public LP_STAKE_MIN       = 1 ;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	// uint256 constant public TIME_STEP = 1 days;
	uint256 constant public TIME_STEP = 600;
	uint256 constant public ONE_MONTH = 30 * TIME_STEP;
	uint256 constant public ONE_YEAR  = 365 * TIME_STEP;

    uint256 public APR = 2500;

    uint256[2] public totalStaked;
    uint256[2] public totalClaimed;
    uint256 public totalLocked;

    struct Pool{
        ITRC20 token;
        uint256 min;
        uint256 decimalsDiff;
    }

    Pool[] internal pools;

    struct User {
		uint256[2] Checkpoint;
		uint256[2] Staked;
		uint256[2] Claimed;
		uint256 Locked;
	}

    mapping (address => User) internal users;

    event onStake(address indexed user, uint256 pool, uint256 amount);
    event onUnstake(address indexed user, uint256 pool, uint256 amount);
    event onClaimed(address indexed user, uint256 pool, uint256 amount);

    constructor(address payable _palla, address payable _lp) public {
        pallaToken = ITRC20(_palla);
        LPT = ITRC20(_lp);

        pools.push(Pool(pallaToken,PALLA_STAKE_MIN,1));
        pools.push(Pool(LPT,LP_STAKE_MIN,100));
    }

    function getTokenBalance(uint256 pool, address _user) public view returns (uint256){
        require(pool < pools.length, "pool id is not valid");
        return pools[pool].token.balanceOf(_user);
    }

    function stake(uint256 pool,uint256 amount) public {
        require(pool < pools.length, "pool id is not valid");
        require(amount >= pools[pool].min, "Min amount is 100 token");
        require(stakeAllowance(pool, amount),   "No enough Token in the contract");

        pools[pool].token.transferFrom(msg.sender,address(this),amount);
        
        User storage user = users[msg.sender];

        //lock
        uint256 lockAmount = amount.mul(APR).mul(ONE_MONTH).div(PERCENTS_DIVIDER).div(ONE_YEAR);
        totalLocked = totalLocked.add(lockAmount);
        user.Locked = user.Locked.add(lockAmount);

        if(user.Staked[pool] > 0){
            uint256 rewards = getDividends(pool,msg.sender);
            user.Claimed[pool] = user.Claimed[pool].add(rewards);
            totalClaimed[pool] = totalClaimed[pool].add(rewards);
            if(rewards>0){
                pallaToken.transfer(msg.sender, rewards);
                //unlock
                if(user.Locked>0){
                    if(user.Locked > rewards){
                        user.Locked = user.Locked.sub(rewards);
                    }
                    else{
                        user.Locked = 0;
                    }
                    if(totalLocked>0){
                        if(totalLocked > rewards){
                            totalLocked = totalLocked.sub(rewards);
                        }
                        else{
                            totalLocked = 0;
                        }
                    }
                }
            }
        }

        user.Checkpoint[pool] = block.timestamp;
        user.Staked[pool] = user.Staked[pool].add(amount);

        totalStaked[pool] = totalStaked[pool].add(amount);

        emit onStake(msg.sender,pool , amount);
    }

	function claim(uint256 pool) public {
        require(pool < pools.length, "pool id is not valid");
	    User storage user = users[msg.sender];

	    uint256 rewards = getDividends(pool, msg.sender);
	    require(rewards > 0, "nothing to claim");
        user.Claimed[pool] = user.Claimed[pool].add(rewards);
        totalClaimed[pool] = totalClaimed[pool].add(rewards);

        //unlock
        if(user.Locked>0){
            if(user.Locked > rewards){
                user.Locked = user.Locked.sub(rewards);
            }
            else{
                user.Locked = 0;
            }
            if(totalLocked>0){
                if(totalLocked > rewards){
                    totalLocked = totalLocked.sub(rewards);
                }
                else{
                    totalLocked = 0;
                }
            }
        }
	    
	    user.Checkpoint[pool] = block.timestamp;
	    pallaToken.transfer(msg.sender, rewards);
	    
	    emit onClaimed(msg.sender, pool, rewards);
	}
	
	function unstake(uint256 pool) public {
        require(pool < pools.length, "pool id is not valid");
        User storage user = users[msg.sender];
        require(block.timestamp >= user.Checkpoint[pool].add(3 * TIME_STEP), "unstake is not allowed until 3 days after last activity");
	   
	   uint256 rewards = getDividends(pool,msg.sender);
	   if(rewards > 0){
	        pallaToken.transfer(msg.sender, rewards);
            user.Claimed[pool] = user.Claimed[pool].add(rewards);
            totalClaimed[pool] = totalClaimed[pool].add(rewards);

            //unlock
            if(user.Locked>0){
                if(user.Locked > rewards){
                    user.Locked = user.Locked.sub(rewards);
                }
                else{
                    user.Locked = 0;
                }
                if(totalLocked>0){
                    if(totalLocked > rewards){
                        totalLocked = totalLocked.sub(rewards);
                    }
                    else{
                        totalLocked = 0;
                    }
                }
            }
	   }

       pools[pool].token.transfer(msg.sender, user.Staked[pool]);	   
       user.Staked[pool] = 0;
	   totalStaked[pool] = totalStaked[pool].sub(user.Staked[pool]);
	   
	   emit onUnstake(msg.sender, pool, user.Staked[pool]);
	}

    function getDividends(uint256 pool, address userAddress) public view returns(uint256){
        require(pool < pools.length, "pool id is not valid");
	    User storage user = users[userAddress];
        uint256 duration = block.timestamp.sub(user.Checkpoint[pool]);
        uint256 amount = user.Staked[pool].mul(pools[pool].decimalsDiff);
        uint256 dividends = amount.mul(APR.div(2)).mul(duration).div(PERCENTS_DIVIDER).div(ONE_YEAR);
        dividends = dividends.add(amount.mul(APR.div(2)).mul(duration.mul(duration)).div(PERCENTS_DIVIDER).div(ONE_YEAR.mul(ONE_YEAR)));
	    return dividends;
	}

    function stakeAllowance(uint256 pool, uint256 amount) public view returns(bool){
        require(pool < pools.length, "pool id is not valid");
        uint256 rewardNeeds = amount.mul(pools[pool].decimalsDiff).mul(APR).mul(ONE_MONTH).div(PERCENTS_DIVIDER).div(ONE_YEAR);
        if( (pallaToken.balanceOf(address(this))).sub(totalLocked.add(totalStaked[0])) >= rewardNeeds )
        {
            return true;
        }
        else{
            return false;
        }
    }

    function getUserInfo(uint256 pool, address _addr) public view returns(uint256,uint256,uint256,uint256){
        require(pool < pools.length, "pool id is not valid");
        User storage user = users[_addr];
        return (
        user.Checkpoint[pool],
		user.Staked[pool],
		user.Claimed[pool],
		user.Locked
        );
    }

    function getPoolInfo(uint256 pool) public view returns(uint256,uint256,uint256){
        require(pool < pools.length, "pool id is not valid");
        return (
        totalStaked[pool],
        totalClaimed[pool],
        totalLocked
        );
    }

    function withdraw() public onlyOwner {
        uint256 withdrawableAmount = pallaToken.balanceOf(address(this)).sub(totalStaked[0].add(totalLocked));
        pallaToken.transfer(owner(),withdrawableAmount);
    }

    function setAPR(uint256 amount) public onlyOwner {
        require(amount >= 2500, "min 2500");
        APR = amount;
    }
    

}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}