pragma solidity ^0.4.24;

library SafeMath {

	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
		if (_a == 0) {
			return 0;
		}

		uint256 c = _a * _b;
		require(c / _a == _b);

		return c;
	}

	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b > 0);
		uint256 c = _a / _b;

		return c;
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		require(_b <= _a);
		uint256 c = _a - _b;

		return c;
	}

	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		require(c >= _a);

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

contract InvestorsStorage {
	address private owner;

	mapping (address => Investor) private investors;

	struct Investor {
		uint deposit;
		uint checkpoint;
		address referrer;
	}

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function updateInfo(address _address, uint _value) external onlyOwner {
		investors[_address].deposit += _value;
		investors[_address].checkpoint = block.timestamp;
	}

	function updateCheckpoint(address _address) external onlyOwner {
		investors[_address].checkpoint = block.timestamp;
	}

	function addReferrer(address _referral, address _referrer) external onlyOwner {
		investors[_referral].referrer = _referrer;
	}

	function getInterest(address _address) external view returns(uint) {
		if (investors[_address].deposit > 0) {
			return(500 + ((block.timestamp - investors[_address].checkpoint) / 1 days));
		}
	}

	function d(address _address) external view returns(uint) {
		return investors[_address].deposit;
	}

	function c(address _address) external view returns(uint) {
		return investors[_address].checkpoint;
	}

	function r(address _address) external view returns(address) {
		return investors[_address].referrer;
	}
}

contract NewSmartPyramid {
	using SafeMath for uint;

	address adv_adr;
	address adm_adr;
	uint waveStartUp;
	uint nextPayDay;

	mapping (uint => Leader) top;

	event LogInvestment(address indexed _addr, uint _value);
	event LogIncome(address indexed _addr, uint _value, string indexed _type);
	event LogReferralInvestment(address indexed _referrer, address indexed _referral, uint _value);
	event LogGift(address _firstAddr, uint _firstDep, address _secondAddr, uint _secondDep, address _thirdAddr, uint _thirdDep);
	event LogNewWave(uint _waveStartUp);

	InvestorsStorage private x;

	modifier notOnPause() {
		require(waveStartUp <= block.timestamp);
		_;
	}

	struct Leader {
		address addr;
		uint deposit;
	}

	function bytesToAddress(bytes _source) internal pure returns(address parsedReferrer) {
		assembly {
			parsedReferrer := mload(add(_source,0x14))
		}
		return parsedReferrer;
	}

	function addReferrer(uint _value) internal {
		address _referrer = bytesToAddress(bytes(msg.data));
		if (_referrer != msg.sender) {
			x.addReferrer(msg.sender, _referrer);
			x.r(msg.sender).transfer(_value / 20);
			emit LogReferralInvestment(_referrer, msg.sender, _value);
			emit LogIncome(_referrer, _value / 20, "referral");
		}
	}

	constructor(address adv,address adm) public {
		adv_adr = adv;
		adm_adr = adm;
		x = new InvestorsStorage();
		nextPayDay = block.timestamp.sub((block.timestamp - 1538388000).mod(7 days)).add(7 days);
	}

	function getInfo(address _address) external view returns(uint deposit, uint amountToWithdraw) {
		deposit = x.d(_address);
		if (block.timestamp >= x.c(_address) + 10 minutes) {
			amountToWithdraw = (x.d(_address).mul(x.getInterest(_address)).div(10000)).mul(block.timestamp.sub(x.c(_address))).div(1 days);
		} else {
			amountToWithdraw = 0;
		}
	}

	function getTop() external view returns(address, uint, address, uint, address, uint) {
		return(top[1].addr, top[1].deposit, top[2].addr, top[2].deposit, top[3].addr, top[3].deposit);
	}

	function() external payable {
		if (msg.value == 0) {
			withdraw();
		} else {
			invest();
		}
	}

	function invest() notOnPause public payable {

		adm_adr.transfer(msg.value.mul(13).div(100));
		adv_adr.transfer(msg.value.mul(2).div(100));

		if (x.d(msg.sender) > 0) {
			withdraw();
		}

		x.updateInfo(msg.sender, msg.value);

		if (msg.value > top[3].deposit) {
			toTheTop();
		}

		if (x.r(msg.sender) != 0x0) {
			x.r(msg.sender).transfer(msg.value / 20);
			emit LogReferralInvestment(x.r(msg.sender), msg.sender, msg.value);
			emit LogIncome(x.r(msg.sender), msg.value / 20, "referral");
		} else if (msg.data.length == 20) {
			addReferrer(msg.value);
		}

		emit LogInvestment(msg.sender, msg.value);
	}

	function withdraw() notOnPause public {

		if (block.timestamp >= x.c(msg.sender) + 10 minutes) {
			uint _payout = (x.d(msg.sender).mul(x.getInterest(msg.sender)).div(10000)).mul(block.timestamp.sub(x.c(msg.sender))).div(1 days);
			x.updateCheckpoint(msg.sender);
		}

		if (_payout > 0) {

			if (_payout > address(this).balance) {
				nextWave();
				return;
			}

			msg.sender.transfer(_payout);
			emit LogIncome(msg.sender, _payout, "withdrawn");
		}
	}

	function toTheTop() internal {
		if (msg.value <= top[2].deposit) {
			top[3] = Leader(msg.sender, msg.value);
		} else {
			if (msg.value <= top[1].deposit) {
				top[3] = top[2];
				top[2] = Leader(msg.sender, msg.value);
			} else {
				top[3] = top[2];
				top[2] = top[1];
				top[1] = Leader(msg.sender, msg.value);
			}
		}
	}

	function payDay() external {
		if(msg.sender != adm_adr)
			require(block.timestamp >= nextPayDay);
		nextPayDay = block.timestamp.sub((block.timestamp - 1538388000).mod(7 days)).add(7 days);

		emit LogGift(top[1].addr, top[1].deposit, top[2].addr, top[2].deposit, top[3].addr, top[3].deposit);

		for (uint i = 0; i <= 2; i++) {
			if (top[i+1].addr != 0x0) {
				uint money_to = 0.5 ether;
				if(i==0)
					money_to = 3 ether;
				else if(i==1)
					money_to = 1.5 ether;

				top[i+1].addr.transfer(money_to);
				top[i+1] = Leader(0x0, 0);
			}
		}
	}

	function nextWave() private {
		for (uint i = 0; i <= 2; i++) {
			top[i+1] = Leader(0x0, 0);
		}
		x = new InvestorsStorage();
		waveStartUp = block.timestamp + 7 days;
		emit LogNewWave(waveStartUp);
	}
}