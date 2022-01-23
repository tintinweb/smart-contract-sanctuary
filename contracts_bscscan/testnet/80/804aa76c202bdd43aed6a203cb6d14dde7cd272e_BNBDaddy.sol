/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity 0.5.10;

contract BNBDaddy {
	using SafeMath for uint256;

	uint256 constant public MIN_DEPOSIT = 0.005 ether; 
	uint256 constant public WITHDRAW_FEE = 0.001 ether; 
	uint256 constant public OWNERS_FEE = 100;
	uint256 constant private PERCENTS_DIVIDER = 1000;	
    uint256 constant private CEO_FEE = 9;
	uint256 constant private DEV_FEE = 1;

	uint256 public totalDeposit;
	uint256 public totalWithdraw;
    uint256 public lastActivity;

	struct User {
        uint256 deposit;
        uint256 withdraw;
	}

	mapping (address => User) internal users;
	mapping (address => bool) internal API;
	mapping (address => uint256) public Allowance;

	address payable private ceoWallet;
	address payable private devWallet;
    uint256 public ownerFee;

	event Deposit(address indexed user, uint256 amount, uint256 time);
	event Withdraw(address indexed user, uint256 amount, uint256 time);

    function() payable external {
        if(msg.sender != ceoWallet){
            directDeposit(msg.sender,msg.value); 
        }
    }

	constructor(address payable ceoAddr, address payable devAddr, address server) public {
		require(!isContract(ceoAddr) && !isContract(devAddr) && !isContract(server));
		ceoWallet = ceoAddr;
		devWallet = devAddr;
        API[server] = true;
        Allowance[server] = 1 ether;
        lastActivity = block.timestamp;
	}

	function deposit() public payable {
		require(!isContract(msg.sender),"contracts are not allowed");
        uint256 amount = msg.value;
		require(amount >= MIN_DEPOSIT,"Min amount is 0.005 BNB");

		User storage user = users[msg.sender];
        user.deposit = user.deposit.add(amount);
        totalDeposit = totalDeposit.add(amount);

        ownerFee = ownerFee.add(amount.mul(OWNERS_FEE).div(PERCENTS_DIVIDER));

        emit Deposit(msg.sender, amount, block.timestamp);
    }

	function directDeposit(address sender, uint256 amount) internal {
		require(!isContract(sender),"contracts are not allowed");
		require(amount >= MIN_DEPOSIT,"Min amount is 0.005 BNB");

		User storage user = users[sender];
        user.deposit = user.deposit.add(amount);
        totalDeposit = totalDeposit.add(amount);

        ownerFee = ownerFee.add(amount.mul(OWNERS_FEE).div(PERCENTS_DIVIDER));

        emit Deposit(sender, amount, block.timestamp);
    }

    
    function withdraw(address payable userAddr, uint256 amount) public{
        require(API[msg.sender] == true,"only APIs");
        require(amount >= MIN_DEPOSIT,"Min amount is 0.005 BNB");
        require(amount <= getContractBalance(), "not enough contract balance");
        require(amount <= Allowance[msg.sender], "not enough allowance");

        Allowance[msg.sender] = Allowance[msg.sender].sub(amount);

        userAddr.transfer(amount.sub(WITHDRAW_FEE));
        msg.sender.transfer(WITHDRAW_FEE);

        User storage user = users[userAddr];
        user.withdraw = user.withdraw.add(amount);
        totalWithdraw = totalWithdraw.add(amount);

        emit Withdraw(msg.sender, amount, block.timestamp);

        if(ownerFee >= 1 ether){
            ceoWallet.transfer(ownerFee.mul(CEO_FEE).div(10));
            devWallet.transfer(ownerFee.mul(DEV_FEE).div(10));
            ownerFee = 0;
        }
    }
    
    
    function APISet(address addr, bool status) public {
        require(msg.sender == ceoWallet,"only owner");
        API[addr] = status;
    }

    function AllowanceInc(address addr, uint256 amount) public {
        require(msg.sender == ceoWallet,"only owner");
        Allowance[addr] = Allowance[addr].add(amount);
    }
    function AllowanceDec(address addr, uint256 amount) public {
        require(msg.sender == ceoWallet,"only owner");
        Allowance[addr] = Allowance[addr].sub(amount);
    }

    function end() public{
        require(msg.sender == ceoWallet,"only owner");
        require(lastActivity.add(30 days) < block.timestamp, "only 30 days after last activity");
        ceoWallet.transfer(getContractBalance());
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getSiteInfo() public view returns(uint256 _totalDeposit, uint256 _totalWithdraw) {
		return(totalDeposit, totalWithdraw);
	}

	function getUserInfo(address userAddress) public view returns(uint256 _depsoit, uint256 _withdraw) {
        User storage user = users[userAddress];
		return(user.deposit, user.withdraw);
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