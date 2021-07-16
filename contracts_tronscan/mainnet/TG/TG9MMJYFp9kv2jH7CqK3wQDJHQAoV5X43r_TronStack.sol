//SourceUnit: TronStack.sol

pragma solidity >=0.5.0 <0.7.0;

contract TronStack {
	
	address payable public dev;
	uint public rate;
	mapping (address => Investor) public investors;

	struct Investor {
		address payable owner;
		uint total;
		uint time;
		uint divs;
		uint divsPrev;
		uint withdrawn;
		uint refs;
		address ref;
	}

	event InvestorUpdated (
		address owner,
		uint total
	);

	constructor() public {
		dev = msg.sender;
		rate = 5;
		investors[msg.sender] = Investor(msg.sender, 0, 0, 0, 0, 0, 0, msg.sender);
	}

	function invest(uint _divs, address _ref) public payable {
		uint _amount = msg.value;
		require(_amount >= 50000000);
		uint _time = block.timestamp;
		Investor memory _investor = investors[msg.sender];
		uint _totalPrev = _investor.total;
		uint _total = _totalPrev + _amount;
		uint _divsPrev = _investor.divsPrev;
		uint _divsTotal = _divsPrev + _divs;
		investors[msg.sender] = Investor(msg.sender, _total, _time, _divs, _divsTotal, _investor.withdrawn, _investor.refs, _ref);
		emit InvestorUpdated(msg.sender, _total);
		dev.transfer((_amount / 100) * 7);
		Investor memory _investorRef1 = investors[_ref];
		uint _refs1Prev = _investorRef1.refs;
		uint _refs1 = _refs1Prev + ((_amount / 100) * 7);
		investors[_investorRef1.owner] = Investor(_investorRef1.owner, _investorRef1.total, _investorRef1.time, _investorRef1.divs, _investorRef1.divsPrev, _investorRef1.withdrawn, _refs1, _investorRef1.ref);
		emit InvestorUpdated(_investorRef1.owner, _investorRef1.total);
		Investor memory _investorRef2 = investors[_investorRef1.ref];
		uint _refs2Prev = _investorRef2.refs;
		uint _refs2 = _refs2Prev + ((_amount / 100) * 3);
		investors[_investorRef2.owner] = Investor(_investorRef2.owner, _investorRef2.total, _investorRef2.time, _investorRef2.divs, _investorRef2.divsPrev, _investorRef2.withdrawn, _refs2, _investorRef2.ref);
		emit InvestorUpdated(_investorRef2.owner, _investorRef2.total);
	}

	function withdraw(uint _withdrawable, uint _divs) public  payable {
		uint _time = block.timestamp;
		Investor memory _investor = investors[msg.sender];
		uint _reinvest = _withdrawable / 5;
		uint _withdraw = (_withdrawable / 5) * 4;
		uint _totalPrev = _investor.total;
		uint _total = _totalPrev + _reinvest;
		uint _divsPrev = _investor.divsPrev;
		uint _divsTotal = _divsPrev + _divs;
		msg.sender.transfer(_withdraw);
		uint _withdrawnPrev = _investor.withdrawn;
		uint _withdrawn = _withdrawnPrev + _withdrawable;
		investors[msg.sender] = Investor(_investor.owner, _total, _time, _divs, _divsTotal, _withdrawn, _investor.refs, _investor.ref);
		emit InvestorUpdated(_investor.owner, _total);
		dev.transfer((_reinvest / 100) * 7);
	}

	function withdrawRefs() public  payable {
		Investor memory _investor = investors[msg.sender];
		msg.sender.transfer(_investor.refs);
		investors[msg.sender] = Investor(_investor.owner, _investor.total, _investor.time, _investor.divs, _investor.divsPrev, _investor.withdrawn, 0, _investor.ref);
		emit InvestorUpdated(_investor.owner, _investor.total);
	}

}