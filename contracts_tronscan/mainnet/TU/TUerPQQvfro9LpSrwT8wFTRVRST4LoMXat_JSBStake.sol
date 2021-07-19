//SourceUnit: JSBStake.sol

pragma solidity ^0.5.0;
import "./Manageable.sol";
import "./TRC20.sol";

contract JSBStake is Manageable {
	address payable public owner;
	address payable public tokenAddress;
	
	struct User {
		bool exists;
		uint256 totalStake;
		uint256 totalWithdraw;
		uint256 totalHarvest;
		uint256 totalUnStake;
	}
	
	struct Withdraw {
		uint256 amount;
		uint256 blockNumberStake;
	    uint256 blockNumberWithdraw;
		uint256 timeWithdraw;
	}

	struct Income {
	    address staker;
		uint256 stakeAmount;
		uint256 blockNumber;
		uint256 lastTimeWithdraw;
		uint256 totalHarvest;
		uint256 totalWithdraw;
		uint256 lastBlockUnStake;
		bool isStake;
	}

	uint256 public count = 1;
	mapping(address => User) public users;
	mapping(uint256 => Withdraw) public withdraws;
	mapping(uint256 => Income) public incomes;
	mapping(uint256 => address) public listUsers;
	uint public stakedSupply = 0;
	uint public totalHarvest = 0;
	uint256 public maxTotalHarvest = 1000000*1e6;
    TRC20 JSB;
    uint256 profit1Week = 138;
    uint256 profit1Month = 231;
    uint256 profit4Month = 370;
    uint256 profit6Month = 555;
    uint256 profit9Month = 694;
    uint256 profit12Month = 833;
    uint256 profit24Month = 925;
    uint256 blockPerDay = 720;
    uint256 dayOfWeek = 7;

    
	constructor(address payable _owner, address payable _tokenAddress) public {
		owner = _owner;
		JSB = TRC20(_tokenAddress);
		tokenAddress = _tokenAddress;
		User memory user = User({
			exists: true,
			totalStake: 0,
			totalHarvest: 0,
			totalWithdraw: 0,
			totalUnStake: 0
		});
    
		users[_owner] = user;
		listUsers[count] = owner;
	}

	function stake(uint256 _amount) public returns (bool) {
		require(_amount > 0, "Greater than min stake value");
		require(totalHarvest <= maxTotalHarvest, "Total Harvest was maximum");
		require(
            JSB.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
		address staker  = msg.sender;
		_safeTransferFrom(msg.sender, address(this), _amount);
		User memory user = User({
				exists: true,
				totalStake: _amount,
    			totalHarvest: 0,
    			totalWithdraw: 0,
				totalUnStake: 0
		});
		
	    _setIncome(staker, now, _amount);
		
		if(users[staker].exists) {
		    users[staker].totalStake += _amount;
		}
		
		if(!users[staker].exists) {
		    users[staker] = user;
		}
		
		listUsers[count] = staker;
		emit Stake(block.number, staker, _amount, now);
		
		return true;
	}
	
	function unStake(uint256 _timeStake) public returns (bool) {
	    require(incomes[_timeStake].isStake, "Stake was canceled");
	    require(users[msg.sender].exists, "User is not exists");
	    incomes[_timeStake].isStake = false;
	    incomes[_timeStake].lastBlockUnStake = block.number;
	    incomes[_timeStake].lastTimeWithdraw = now;
	    uint256 profit = calculateProfit(_timeStake);
	    users[msg.sender].totalHarvest = profit;
	    profit = profit - incomes[_timeStake].totalWithdraw;
	    totalHarvest += profit;
	    incomes[_timeStake].totalWithdraw += profit;
	    incomes[_timeStake].totalHarvest += profit;
	    users[msg.sender].totalWithdraw += profit;
		users[msg.sender].totalHarvest += profit;
	    JSB.transfer(incomes[_timeStake].staker, incomes[_timeStake].stakeAmount);
		users[msg.sender].totalUnStake += incomes[_timeStake].stakeAmount;
		require(totalHarvest <= maxTotalHarvest, "Total Harvest was maximum");
	    if(profit > 0) {
		   	JSB.transfer(incomes[_timeStake].staker, profit);
	    }
		emit UnStake(block.number, msg.sender, profit + incomes[_timeStake].stakeAmount, now);
		return true;
	}
	
	function withdraw(uint256 _timeStake) public returns (bool) {
	    require(incomes[_timeStake].isStake, "Stake was canceled");
	    require(users[msg.sender].exists, "User is not exists");
	    uint256 profit = calculateProfit(_timeStake);
	    users[msg.sender].totalHarvest = profit;
	    profit = profit - incomes[_timeStake].totalWithdraw;
	    totalHarvest += profit;
		users[msg.sender].totalWithdraw += profit;
		users[msg.sender].totalHarvest += profit;
	    incomes[_timeStake].lastBlockUnStake = block.number;
	    incomes[_timeStake].lastTimeWithdraw = now;
	    incomes[_timeStake].totalWithdraw += profit;
	    incomes[_timeStake].totalHarvest += profit;
		require(totalHarvest <= maxTotalHarvest, "Total Harvest was maximum");
	    if(profit > 0) {
	        JSB.transfer(incomes[_timeStake].staker, profit);
	        emit Withdraws(block.number, msg.sender, profit, now);
	        return true;
	    }
	    return false;
	}
	
	
	function calculateProfit(uint256 _timeStake) public returns (uint256) {
	    uint256 fromBlock = incomes[_timeStake].blockNumber;
	    uint256 toBlock = block.number;
	    uint256 profit = 0;
	    uint256 subBlock = toBlock - fromBlock;
	    subBlock = subBlock / 120;
	    
	    if(subBlock <= (blockPerDay*dayOfWeek)) {
	        profit = (subBlock * profit1Week);
	    }
	    if(subBlock > (blockPerDay*dayOfWeek) && subBlock <= (blockPerDay*30)) {
	        profit = (blockPerDay * dayOfWeek * profit1Week);
	        profit = profit + ((subBlock - (blockPerDay * dayOfWeek)) * profit1Month);
	    }
	    if(subBlock > (blockPerDay*30) && subBlock <= (blockPerDay*120)) {
	        profit = (blockPerDay*30 * profit1Month);
	        profit = profit + ((subBlock - (blockPerDay * 30)) * profit4Month);
	    }
	    if(subBlock > (blockPerDay*120) && subBlock <= (blockPerDay*180)) {
	        profit = (blockPerDay*120 * profit4Month);
	        profit = profit + ((subBlock - (blockPerDay * 120)) * profit6Month);
	    }
	    if(subBlock > (blockPerDay*180) && subBlock <= (blockPerDay*270)) {
	        profit = (blockPerDay*180 * profit6Month);
	        profit = profit + ((subBlock - (blockPerDay * 180)) * profit9Month);
	    }
	    if(subBlock > (blockPerDay*270) && subBlock <= (blockPerDay*360)) {
	        profit = (blockPerDay*270 * profit9Month);
	        profit = profit + ((subBlock - (blockPerDay * 270)) * profit12Month);
	    }
	    if( subBlock > (blockPerDay*360)) {
	        profit = (blockPerDay*360 * profit12Month);
	        profit = profit + ((subBlock - (blockPerDay * 360)) * profit24Month);
	    }
	    emit CalculateProfit(fromBlock, toBlock, profit, _timeStake, subBlock);
	    return profit/1e2;
	}
	
	function _safeTransferFrom(address _sender, address _recipient, uint _amount) private {
        bool sent = JSB.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }
	
	function _setIncome(address _staker, uint256 _timeStake, uint256 _value) private {
	    incomes[_timeStake].stakeAmount = _value;
	    incomes[_timeStake].blockNumber = block.number;
		incomes[_timeStake].lastTimeWithdraw = 0;
		incomes[_timeStake].totalHarvest = 0;
		incomes[_timeStake].totalWithdraw = 0;
		incomes[_timeStake].isStake = true;
		incomes[_timeStake].lastBlockUnStake = 0;
		incomes[_timeStake].staker = _staker;
		stakedSupply += _value;
	}

	function withdrawJSB(address _recipient, uint256 _amount) public onlyAdmins returns (bool)  {
		require(_amount <= JSB.balanceOf(address(this)), "The amount must be lower than balance");
		JSB.transfer(_recipient, _amount);
		emit WithdrawJSB(_recipient, _amount);
		return true;
	}

    event Stake(
        uint256 blockNumber,
    	address newMember,
    	uint256 value,
    	uint256 timeStake
    );
    
    event UnStake(
        uint256 blockNumber,
    	address staker,
    	uint256 value,
    	uint256 timeStake
    );
    
    event Withdraws(
        uint256 blockNumber,
    	address staker,
    	uint256 value,
    	uint256 timeStake
    );
    
     event WithdrawJSB(
    	address recipient,
    	uint256 value
    );
    
    event CalculateProfit(
        uint256 fromBlock,
    	uint256 toBlock,
    	uint256 value,
    	uint256 timeStake,
    	uint256 subBlock
    );
}

//SourceUnit: Manageable.sol

pragma solidity ^0.5.0;

contract Manageable {
    mapping(address => bool) public admins;
    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function modifyAdmins(address[] memory newAdmins, address[] memory removedAdmins) public onlyAdmins {
        for(uint256 index; index < newAdmins.length; index++) {
            admins[newAdmins[index]] = true;
        }
        for(uint256 index; index < removedAdmins.length; index++) {
            admins[removedAdmins[index]] = false;
        }
    }
}

//SourceUnit: TRC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface TRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
}