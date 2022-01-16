/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

pragma solidity 0.5.10;

interface Random {
    function rand() external returns (uint8);
}

contract BNBDaddy {
	using SafeMath for uint256;

	uint256 constant public MIN_BET = 0.005 ether; 
	uint256 constant public MAX_BET = 1 ether; 
	uint256 constant public WINNER  = 1880;
	uint256 constant public OWNERS_FEE = 100;
	uint256 constant private PERCENTS_DIVIDER = 1000;
	uint256 constant private CEO_FEE = 9;
	uint256 constant private DEV_FEE = 1;

	uint256 public totalBet;
	uint256 public totalBetAmount;
	uint256 public totalWin;
	uint256 public totalWinAmount;
	uint256 public totalLost;
	uint256 public totalLostAmount;

    uint256 private randT;

    uint256 public lastActivity;

    Random private random;

	struct User {
        uint256 Bet;
        uint256 BetAmount;
        uint256 Win;
        uint256 WinAmount;
        uint256 Lost;
        uint256 LostAmount;
	}

	mapping (address => User) internal users;


	address payable private ceoWallet;
	address payable private devWallet;
    uint256 public ownerFee;

	event Bet(address indexed user, uint256 amount, uint256 rand, uint256 userAction, uint256 time);

    function() payable external {   
    }

	constructor(address payable ceoAddr, address payable devAddr,address randAddr) public {
		require(!isContract(ceoAddr) && !isContract(devAddr));
		ceoWallet = ceoAddr;
		devWallet = devAddr;
        random = Random(randAddr);

        lastActivity = block.timestamp;
	}

	function bet(uint8 userAction) public payable {
		require(!isContract(msg.sender),"contracts are not allowed");
        uint256 amount = msg.value;
		require(amount >= MIN_BET,"Min amount is 0.005 BNB");
		require(amount <= MAX_BET,"Max amount is 1 BNB");

        uint8 status = random.rand();
		User storage user = users[msg.sender];

        //win
        if(status == userAction){
            user.Win += 1;
            user.WinAmount += amount;
            totalWin += 1;
            totalWinAmount += amount;
            ownerFee = ownerFee.add(amount.mul(OWNERS_FEE).div(PERCENTS_DIVIDER));
            msg.sender.transfer(amount.mul(WINNER).div(PERCENTS_DIVIDER));
        }else{
            user.Lost += 1;
            user.LostAmount += amount;
            totalLost += 1;
            totalLostAmount += amount;
            ownerFee = ownerFee.add(amount.div(100000).div(PERCENTS_DIVIDER));
            msg.sender.transfer(amount.div(100000).div(PERCENTS_DIVIDER));
        }
        user.Bet += 1;
        user.BetAmount += amount;
		totalBet += 1;
        totalBetAmount += amount;

        lastActivity = block.timestamp;
		emit Bet(msg.sender, amount, status, userAction, block.timestamp);

        if(randT > 1000000){
            randT = 0;
        }
        uint256 randTime = block.timestamp % 4;
        for(uint8 i=0; i < randTime; i++){
            randT += 1;
        }


        if(ownerFee >= 1 ether){
            ceoWallet.transfer(ownerFee.mul(CEO_FEE).div(10));
            devWallet.transfer(ownerFee.mul(DEV_FEE).div(10));
        }
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getSiteInfo() public view returns(uint256 _totalBet, uint256 _totalBetAmount, uint256 _totalWin, uint256 _totalWinAmount, uint256 _totalLost, uint256 _totalLostAmount) {
		return(totalBet, totalBetAmount, totalWin, totalWinAmount, totalLost, totalLostAmount);
	}

	function getUserInfo(address userAddress) public view returns(uint256 _Bet, uint256 _BetAmount, uint256 _Win, uint256 _WinAmount, uint256 _Lost, uint256 _LostAmount) {
        User storage user = users[userAddress];
		return(user.Bet, user.BetAmount, user.Win, user.WinAmount, user.Lost, user.LostAmount);
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function end() public{
        require(msg.sender == ceoWallet,"only owner");
        require(lastActivity.add(30 days) < block.timestamp, "only 30 days after last activity");
        ceoWallet.transfer(getContractBalance());
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