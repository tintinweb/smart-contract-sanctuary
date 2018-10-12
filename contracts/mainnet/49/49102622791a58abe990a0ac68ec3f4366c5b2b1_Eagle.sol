pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath 
{
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c  / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a  / b;
    }
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Owner
{
    address internal owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner returns(bool)
    {
        owner = newOwner;
        return true;
    }
}

contract EagleEvent {
	event onEventDeposit (
		address indexed who,
		uint256 indexed value
	);
	
	event onEventWithdraw (
		address indexed who,
		address indexed to,
		uint256 indexed value
	);
	
	event onEventWithdrawLost (
		address indexed from,
		address indexed to,
		uint256 indexed value
	);
	
	event onEventReport (
		address indexed from,
		address indexed to
	);
	
	event onEventVerify (
		address indexed from
	);
	
	event onEventReset (
		address indexed from
	);
	
	event onEventUnlock (
		address indexed from
	);
}

contract Eagle is Owner, EagleEvent
{
	//State
	enum State {
		Normal, Report, Verify, Lock
	}
	using SafeMath for uint256;
	uint256 public constant withdraw_fee = 600000000000000;  // 0.0006eth for every withdraw
	uint256 public constant withdraw_fee_lost = 10000000000000000; // 0.01eth for withdraw after lost
	uint256 public constant report_lock = 100000000000000000; // 0.1eth for report, cost for some malicious attacks.
	//core data
	mapping(address => uint256) public balances;
	mapping(address => State) public states;
	mapping(address => uint) public verifytimes;
	mapping(address => address) public tos;
	mapping(address => bytes) public signs;
	
	constructor() public
	{
		owner = msg.sender;
	}
	
	function getbalance(address _owner) public view returns(uint256)
	{
		return balances[_owner];
	}
	
	function getstate(address _owner) public view returns(State)
	{
		return states[_owner];
	}
	
	function getverifytime(address _owner) public view returns(uint)
	{
		return verifytimes[_owner];
	}
	
	//deposit
	function () public payable
	{
		require(states[msg.sender] == State.Normal);
		balances[msg.sender] = balances[msg.sender].add(msg.value);
		emit onEventDeposit(msg.sender, msg.value.div(100000000000000));
	}
	
	//withdraw
	function withdraw(address _to, uint256 _value) public
	{
		require(states[msg.sender] != State.Lock);
		require(balances[msg.sender] >= _value.add(withdraw_fee));
		balances[msg.sender] = balances[msg.sender].sub(_value.add(withdraw_fee));
		_to.transfer(_value);
		owner.transfer(withdraw_fee);
		emit onEventWithdraw(msg.sender, _to, _value.div(100000000000000));
	}
	
	//withdraw for loss
	function withdrawloss(address _from, address _to) public
	{
		require(_to == msg.sender);
		require(tos[_from] == _to);
		require(states[_from] == State.Verify);
		require(states[_to] == State.Normal);
		//check verify time
		require(now >= verifytimes[_from] + 5 days);
		require(balances[_from] >= withdraw_fee_lost);
		
		emit onEventWithdrawLost(_from, _to, balances[_from].div(100000000000000));
		
		owner.transfer(withdraw_fee_lost);
		balances[_to] = balances[_to].add(balances[_from]).sub(withdraw_fee_lost);
		balances[_from] = 0;
		states[_from] = State.Normal;
		verifytimes[_from] = 0;
		tos[_from] = 0;
	}
	
	//report 
	function report(address _from, address _to, bytes _sign) public
	{
		require(_to == msg.sender);
		require(states[_from] == State.Normal);
		require(balances[_to] >= report_lock);
		require(states[_to] == State.Normal);
		signs[_from] = _sign;
		tos[_from] = _to;
		states[_from] = State.Report;
		states[_to] = State.Lock;
		
		emit onEventReport(_from, _to);
	}
	
	//verify
	function verify(address _from, bytes _id) public
	{
		require(states[_from] == State.Report);
		bytes memory signedstr = signs[_from];
		bytes32 hash = keccak256(_id);
		hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		bytes32 r;
		bytes32 s;
		uint8 v;
		address addr;
		if (signedstr.length != 65) {
			addr = 0;
		} else {
			assembly {
				r := mload(add(signedstr, 32))
				s := mload(add(signedstr, 64))
				v := and(mload(add(signedstr, 65)), 255)
			}
			if(v < 27) {
				v += 27;
			}
			if(v != 27 && v != 28) {
				addr = 0;
			} else {
				addr = ecrecover(hash, v, r, s);
			}
		}
		require(addr == _from);
		verifytimes[_from] = now;
		states[_from] = State.Verify;
		states[tos[_from]] = State.Normal;
		
		emit onEventVerify(_from);
	}
	
	// reset the user&#39;s state for some malicious attacks
	function resetState(address _from) public onlyOwner
	{
		require(states[_from] == State.Report || states[_from] == State.Lock);
		if(states[_from] == State.Report) {
			states[_from] = State.Normal;
			verifytimes[_from] = 0;
			tos[_from] = 0;
			emit onEventReset(_from);
		} else if(states[_from] == State.Lock) {
			states[_from] = State.Normal;
			balances[_from] = balances[_from].sub(report_lock);
			owner.transfer(report_lock);
			emit onEventUnlock(_from);
		}
	}
}