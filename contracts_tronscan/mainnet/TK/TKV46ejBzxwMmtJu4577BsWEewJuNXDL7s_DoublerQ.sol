//SourceUnit: DoublerQ.sol

/*
 * 
 *   DoublerQ | Be fast and double your money!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://DoublerQ.com                                       |
 *   │   Telegram channel: https://t.me/Doubler_Q                            |
 *   │   Twitter page: https://twitter.com/Doubler_Q                         |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: Doubler Queue company LTD (#13045273 )
 *   - Company status: https://find-and-update.company-information.service.gov.uk/company/13045273
 *
 * ────────────────────────────────────────────────────────────────────────
 *
 *   [DoublerQ Introduction]
 *
 *   DoublerQ System is simply a single-line matrix and you can easily double your money with a little
 *   precision, speed of action and strategy. In a completely simple and transparent process, at a specific
 *   time that has already been announced, a new spot line based on Smart Contact will be launched on the Tron
 *   network. Your money is doubled by the people who come in after you, and their money is doubled by the next
 *   people. Example: You enter the 100 TRX Spotline as the first person. 2 people will enter after you, each
 *   of whom will pay you 100 TRX and you will be removed from the list. And so this queue continues.
 *
 */

pragma solidity >=0.5.8;

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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function transfer(address payable addr, uint256 value) public onlyOwner {
        require(addr != address(0), "Ownable: new owner is the zero address");
		addr.transfer(value); 
    }
}

interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DoublerQ is Ownable {
	using SafeMath for uint256;

	uint256 public totalUsers;
	uint256 public totalPurchases;
	uint256 public spotCount;
	address payable public projectAddress;

	struct Spot {
        uint coinType;
		uint256 tokenId;
		address tokenAddress;
		uint256 amount;
		uint256 decimal;
		string symbol;
        uint256 projectFee;
        uint256 referralFee;
		uint256 start;
        uint256 timeStep;
	}

	struct User {
		address payable referrer;
        bool active;
		uint256 commission;
		uint256 referrals;
        mapping (uint256 => uint256) checkpoint;
	}

	Spot[] public spots;
	mapping (address => User) public users;
	mapping (uint256 => address payable[]) public spotLine;

    event Registration(address indexed addr, address indexed referrer);
	event NewSpot(uint coinType, uint256 tokenId, address tokenAddress, uint256 amount, uint256 decimal, string symbol, uint256 projectFee, uint256 referralFee, uint256 start, uint256 timeStep);
	event Purchase(uint256 spot, address indexed from, address indexed to, uint256 last);

	constructor(address payable projectAddr) public {
		projectAddress = projectAddr;
		users[msg.sender].active = true;
	}

    function addSpot(uint coinType, uint256 tokenId, address tokenAddress, uint256 amount, uint256 decimal, string memory symbol, uint256 projectFee, uint256 referralFee, uint256 start, uint256 timeStep) public onlyOwner {
        require(coinType < 3, "Type must be less than 3!");
        require(amount > 0, "Value must be greater than 0!");
        require(projectFee > 0, "Value must be greater than 0!");
        require(referralFee > 0, "Value must be greater than 0!");
        require(start > block.timestamp, "Start time must be greater than now!");
        require(coinType != 1 || tokenId > 1000000, "TokenId must be greater than 1000000!");
        require(coinType != 2 || tokenAddress != address(0), "TokenAddress must not be the zero address!");
		
        spots.push(Spot(coinType, tokenId, tokenAddress, amount, decimal, symbol, projectFee, referralFee, start, timeStep));
		spotCount = spotCount.add(1);
		emit NewSpot(coinType, tokenId, tokenAddress, amount, decimal, symbol, projectFee, referralFee, start, timeStep);
    }

    function setProjectAddress(address payable addr) public onlyOwner {
        require(addr != address(0), "Address must not be the zero address!");
        projectAddress = addr;
    }

    function register(address payable referrer) public {
        require(users[msg.sender].active == false, "Your account registered already!");
        require(users[referrer].active == true || referrer == address(0), "Inviter account does not registered!");
        users[msg.sender].referrer = referrer;
        users[msg.sender].active = true;
        users[referrer].referrals = users[referrer].referrals.add(1);
		totalUsers = totalUsers.add(1);
        emit Registration(msg.sender, referrer);
    }

	function purchase(uint256 sNumber) public payable {
        require(users[msg.sender].active == true, "Your account does not registered!");
        require(sNumber < spots.length, "Invalid spot number!");
		User storage user = users[msg.sender];
        Spot storage spot = spots[sNumber];
        require(spot.start <= block.timestamp, "Start time not reached!");
        require(user.checkpoint[sNumber].add(spot.timeStep) <= block.timestamp, "Your spot step time has remained!");
		uint256 value;
		if (spot.coinType == 0) {
			value = msg.value;
		}
		else if(spot.coinType == 1) {
			value = msg.tokenvalue;
		}
		else {
			value = spot.amount.add(spot.projectFee.add(spot.referralFee));
		}
		require(value == spot.amount.add(spot.projectFee.add(spot.referralFee)), "Your paid spot amount not correct");
        spotLine[sNumber].push(msg.sender);
		uint256 last = spotLine[sNumber].length;
		address payable addr = spotLine[sNumber][(last - 1) / 2];
		if (spot.coinType == 0){
			users[user.referrer].commission = users[user.referrer].commission.add(spot.referralFee);
			projectAddress.transfer(spot.projectFee);
			user.referrer.transfer(spot.referralFee);
			addr.transfer(spot.amount);
		}
		else if(spot.coinType == 1){
			projectAddress.transferToken(spot.projectFee, spot.tokenId);
			user.referrer.transferToken(spot.referralFee, spot.tokenId);
			addr.transferToken(spot.amount, spot.tokenId);
		}
		else{
			ITRC20 tokenAddr = ITRC20(spot.tokenAddress);
        	tokenAddr.transferFrom(msg.sender, projectAddress, spot.projectFee);
        	tokenAddr.transferFrom(msg.sender, user.referrer, spot.referralFee);
        	tokenAddr.transferFrom(msg.sender, addr, spot.amount);
		}
		user.checkpoint[sNumber] = block.timestamp;
		totalPurchases = totalPurchases.add(1);
		emit Purchase(sNumber, msg.sender, addr, last);
	}

	function getStat() public view returns(uint256, uint256, uint256) {
		return (totalUsers, totalPurchases, spotCount);
	}

	function getSpotList(uint256 fromNumber, uint256 toNumber) public view 
					returns(uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
		uint256 length = toNumber - fromNumber;
		uint256[] memory amount = new uint256[](length);
		uint256[] memory projectFee = new uint256[](length);
		uint256[] memory referralFee = new uint256[](length);
		uint256[] memory start = new uint256[](length);
		uint256[] memory last = new uint256[](length);
		uint256 index;
		for(uint256 i = fromNumber; i < toNumber; i++){
			index = i - fromNumber;
			amount[index] = spots[i].amount;
			projectFee[index] = spots[i].projectFee;
			referralFee[index] = spots[i].referralFee;
			start[index] = spots[i].start;
			last[index] = spotLine[i].length;
		}
		return (amount, projectFee, referralFee, start, last);
	}

	function getSpotList2(uint256 fromNumber, uint256 toNumber) public view 
					returns(uint[] memory, uint256[] memory, address[] memory, uint256[] memory, uint256[] memory) {
		uint256 length = toNumber - fromNumber;
		uint[] memory coinType = new uint[](length);
		uint256[] memory tokenId = new uint256[](length);
		address[] memory tokenAddress = new address[](length);
		uint256[] memory decimal = new uint256[](length);
		uint256[] memory timeStep = new uint256[](length);
		uint256 index;
		for(uint256 i = fromNumber; i < toNumber; i++){
			index = i - fromNumber;
			coinType[index] = spots[i].coinType;
			tokenId[index] = spots[i].tokenId;
			tokenAddress[index] = spots[i].tokenAddress;
			decimal[index] = spots[i].decimal;
			timeStep[index] = spots[i].timeStep;
		}
		return (coinType, tokenId, tokenAddress, decimal, timeStep);
	}

	function getSpotLine(uint256 sNumber, address addr) public view returns(address[] memory, uint256) {
		address[] memory addrs = new address[](spotLine[sNumber].length);
		for(uint256 i = 0; i < spotLine[sNumber].length; i++){
			addrs[i] = spotLine[sNumber][i];
		}
		return (addrs, users[addr].checkpoint[sNumber]);
	}
}