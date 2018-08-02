pragma solidity ^0.4.24;
/// @author Global Group - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3453585b5655585d4e5150745359555d581a575b59">[email&#160;protected]</a>>
library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}
contract Owned {
    address public owner;

    event LogNew(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        emit LogNew(owner, _newOwner);
        owner = _newOwner;
    }
}
contract MEGIngerface {
	function depositFunds(address _participant, uint256 _weiAmount) public payable returns(bool success);
	function withdrawFromBalance(address _participant, uint256 _weiAmount) public payable returns(bool success);
	function addBalance(address _participant, uint256 _weiAmount) public returns(bool success);
	function substractBalance(address _participant, uint256 _weiAmount) public returns(bool success);
	function transferETH(address _to, uint256 _value) public;
	function balanceOf(address who) public view returns (uint256);
	function getJackpot() public view returns (uint256 _jackpot);
	function getIsAuth(address _auth) public view returns(bool _isAuth);
}

contract MoneyManager is Owned, MEGIngerface {
	using SafeMath for uint256;
	
	/* Public variables */
	uint256 penndingBalances = 0;
	uint256 JACKPOT;
	
	modifier onlyAuth {
	    require(auth[msg.sender] == true);
	    _;
	}
	
	mapping (address => bool) internal auth;
	
	/* This creates an array with all balances */
	mapping (address => uint256) internal balances;

	constructor() public {

	}
	
    function() public payable {
        require(msg.sender == owner);
        JACKPOT = JACKPOT.add(msg.value);
        penndingBalances = penndingBalances.add(msg.value);
    }
    
    event DepostFunds(uint256 _participantBalance, uint256 _depositedAmount, uint256 _when);
    function depositFunds(address _participant, uint256 _weiAmount) public payable returns(bool success) {
        require(msg.value == _weiAmount);
        balances[_participant] = balances[_participant].add(_weiAmount);
        penndingBalances = penndingBalances.add(_weiAmount);
        emit DepostFunds(balances[_participant], _weiAmount, block.timestamp);
        return true;
    }
    
    event WithdrawFromBalance(address _participant, uint256 _when, uint256 amount);
    function withdrawFromBalance(address _participant, uint256 _weiAmount) public payable returns(bool success) {
        require(balances[_participant] > 0);
        require(balances[_participant] >= _weiAmount);
        balances[_participant] = balances[_participant].sub(_weiAmount);
	    penndingBalances = penndingBalances.sub(_weiAmount);
        _participant.transfer(_weiAmount);
        emit WithdrawFromBalance(_participant, block.timestamp, _weiAmount);
        return true;
    }
    
	event AddBalance(address _participant, uint256 _weiAmount, uint256 _when);
	function addBalance(address _participant, uint256 _weiAmount) public onlyAuth returns(bool success) {
		balances[_participant] = balances[_participant].add(_weiAmount);
        penndingBalances = penndingBalances.add(_weiAmount);
		JACKPOT = JACKPOT.sub(_weiAmount);
		emit AddBalance(_participant, _weiAmount, block.timestamp);
        return true;
	}
	
	event SubstractBalance(address _participant, uint256 _weiAmount, uint256 _when);
	function substractBalance(address _participant, uint256 _weiAmount) public onlyAuth returns(bool success) {
	    balances[_participant] = balances[_participant].sub(_weiAmount);
	    penndingBalances = penndingBalances.sub(_weiAmount);
		JACKPOT = JACKPOT.add(6 finney);
		penndingBalances = penndingBalances.add(6 finney);
		emit SubstractBalance(_participant,_weiAmount, block.timestamp);
        return true;
	}
	
	event Authorization(address indexed authorized, bool isAuthorized);
	function authorize(address _Auth, bool isAuth) public onlyOwner {
		auth[_Auth] = isAuth;
		emit Authorization(_Auth, isAuth);
	}
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	function transferETH(address _to, uint256 _value) public onlyOwner {
	    require(address(this).balance >= penndingBalances.add(_value));
	    _to.transfer(_value);
	}
	
	function balanceOf(address _participant) public view returns (uint256 balance) {
		return balances[_participant];
	}
	
	function getJackpot() public view returns (uint256 _jackpot) {
		return JACKPOT;
	}
	
	function getPenndingBalances() public view returns(uint256 _penndingBalances){
	    return penndingBalances;
	}
	
	function getIsAuth(address _auth) public view returns(bool _isAuth){
		return auth[_auth];
	}

}