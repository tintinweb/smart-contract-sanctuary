//SourceUnit: Staking.sol

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;
// import "hardhat/console.sol";
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

interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


contract Staking {
	using SafeMath for uint256;
	ITRC20 public Token;

	uint256 constant public INVEST_MIN_AMOUNT = 50E6;
	uint256 constant public WITHDRAW_MIN_AMOUNT = 50E6;
	uint256[] public REFERRAL_PERCENTS = [1000, 500, 200, 200, 100];
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
        bool allow ;
        uint timer;
	}

	struct User {
		Deposit[] deposits;
        
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
	}
    

	mapping (address => User) internal users;
    mapping (address => bool ) UnstakeAllownce; 
    mapping (address => mapping(bool => uint)) unstakeChecker;

	uint256 public startUNIX;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address _token ){
		Token = ITRC20(_token);
		startUNIX = block.timestamp;

        plans.push(Plan(180, 18));        //18%
        plans.push(Plan(365, 48));       //48%
        plans.push(Plan(730, 120));      //120%
	}
	
	function invest(address referrer, uint8 plan, uint256 _amount) public {
		require(_amount >= INVEST_MIN_AMOUNT);
		User storage user = users[msg.sender];
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
			}
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}
		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, _amount);
		user.deposits.push(Deposit(plan, percent, _amount, profit, block.timestamp, finish, false, 0));
        Token.transferFrom(msg.sender, address(this), _amount);
		totalStaked = totalStaked.add(_amount);
		emit NewDeposit(msg.sender, plan, percent, _amount, profit, block.timestamp, finish);
	}

    function allowUnstake(address _user, uint _index) public{
        
        User storage user = users[_user];        
            if(user.deposits[_index].plan == 0){
                user.deposits[0].timer = block.timestamp.add(2592000);
                user.deposits[_index].start = 0;
                user.deposits[_index].finish = 0;
            }else if(user.deposits[_index].plan == 1){
                user.deposits[1].timer = block.timestamp.add(3888000);
                user.deposits[_index].start = 0;
                user.deposits[_index].finish = 0;
            }else if(user.deposits[_index].plan == 2){
                user.deposits[2].timer = block.timestamp.add(5184000);
                user.deposits[_index].start = 0;
                user.deposits[_index].finish = 0;
            }
    }

    function unstake(address _user, uint _index) public{
        User storage user = users[_user];
        require( block.timestamp > user.deposits[_index].timer,'your cool down period is not completed.' );
        require(user.deposits[_index].timer != 0, 'please start cool down period');
        uint _amount = user.deposits[_index].amount;
        totalStaked = totalStaked.sub(_amount);
        Token.transfer(_user, _amount);
        user.deposits[_index].amount = 0;
        user.deposits[_index].profit = 0;
        user.deposits[_index].amount = 0; 
        user.deposits[_index].percent = 0;
        user.deposits[_index].start = 0;
        user.deposits[_index].finish = 0;
        user.deposits[_index].timer = 0 ;
    }

	function withdraw() public {
		User storage user = users[msg.sender];
        for(uint i= 0 ; i < user.deposits.length ; i ++){
            uint256 totalAmount = getUserDividends(msg.sender );
            uint256 contractBalance = Token.balanceOf(address(this));
            if (contractBalance < totalAmount) {
                totalAmount = contractBalance;
            }
            user.checkpoint = block.timestamp;
            Token.transfer( msg.sender ,totalAmount);
            emit Withdrawn(msg.sender, totalAmount);
        
        }
	}

	function getContractBalance() public view returns (uint256) {
		return Token.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > startUNIX) {
            return plans[plan].percent;
        } 
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
            for (uint256 i = 0; i < user.deposits.length; i++) {
                if (user.checkpoint < user.deposits[i].finish  ) {
                        uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                        uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                        uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                        if (from < to ) {
                            totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                        }                    
                }else{
                }
            }

		return totalAmount;
	}

    function withdrawReferralBonus(address _user) public{
        uint bonus = getUserReferralBonus(_user);
        Token.transfer(_user, bonus);
        users[_user].bonus = 0;
    }

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2], users[userAddress].levels[3], users[userAddress].levels[4]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;

	}
    function coolDownPeriod(address _user, uint _index) public view returns(uint){
        User storage user = users[_user];
        return(user.deposits[_index].timer);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}