// Copyright New Alchemy Limited, 2017. All rights reserved.

pragma solidity >=0.4.10;

// from Zeppelin
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract Owned {
	address public owner;
	address newOwner;

	function Owned() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function changeOwner(address _newOwner) onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() {
		if (msg.sender == newOwner) {
			owner = newOwner;
		}
	}
}

contract Pausable is Owned {
	bool public paused;

	function pause() onlyOwner {
		paused = true;
	}

	function unpause() onlyOwner {
		paused = false;
	}

	modifier notPaused() {
		require(!paused);
		_;
	}
}

contract Finalizable is Owned {
	bool public finalized;

	function finalize() onlyOwner {
		finalized = true;
	}

	modifier notFinalized() {
		require(!finalized);
		_;
	}
}

contract IToken {
	function transfer(address _to, uint _value) returns (bool);
	function balanceOf(address owner) returns(uint);
}

// In case someone accidentally sends token to one of these contracts,
// add a way to get them back out.
contract TokenReceivable is Owned {
	function claimTokens(address _token, address _to) onlyOwner returns (bool) {
		IToken token = IToken(_token);
		return token.transfer(_to, token.balanceOf(this));
	}
}

contract EventDefinitions {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions, Pausable {
	string constant public name = "Token Report";
	uint8 constant public decimals = 8;
	string constant public symbol = "DATA";
	Controller public controller;
	string public motd;
	event Motd(string message);

	// functions below this line are onlyOwner

	// set "message of the day"
	function setMotd(string _m) onlyOwner {
		motd = _m;
		Motd(_m);
	}

	function setController(address _c) onlyOwner notFinalized {
		controller = Controller(_c);
	}

	// functions below this line are public

	function balanceOf(address a) constant returns (uint) {
		return controller.balanceOf(a);
	}

	function totalSupply() constant returns (uint) {
		return controller.totalSupply();
	}

	function allowance(address _owner, address _spender) constant returns (uint) {
		return controller.allowance(_owner, _spender);
	}

	function transfer(address _to, uint _value) onlyPayloadSize(2) notPaused returns (bool success) {
		if (controller.transfer(msg.sender, _to, _value)) {
			Transfer(msg.sender, _to, _value);
			return true;
		}
		return false;
	}

	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3) notPaused returns (bool success) {
		if (controller.transferFrom(msg.sender, _from, _to, _value)) {
			Transfer(_from, _to, _value);
			return true;
		}
		return false;
	}

	function approve(address _spender, uint _value) onlyPayloadSize(2) notPaused returns (bool success) {
		// promote safe user behavior
		if (controller.approve(msg.sender, _spender, _value)) {
			Approval(msg.sender, _spender, _value);
			return true;
		}
		return false;
	}

	function increaseApproval (address _spender, uint _addedValue) onlyPayloadSize(2) notPaused returns (bool success) {
		if (controller.increaseApproval(msg.sender, _spender, _addedValue)) {
			uint newval = controller.allowance(msg.sender, _spender);
			Approval(msg.sender, _spender, newval);
			return true;
		}
		return false;
	}

	function decreaseApproval (address _spender, uint _subtractedValue) onlyPayloadSize(2) notPaused returns (bool success) {
		if (controller.decreaseApproval(msg.sender, _spender, _subtractedValue)) {
			uint newval = controller.allowance(msg.sender, _spender);
			Approval(msg.sender, _spender, newval);
			return true;
		}
		return false;
	}

	modifier onlyPayloadSize(uint numwords) {
		assert(msg.data.length >= numwords * 32 + 4);
		_;
	}

	function burn(uint _amount) notPaused {
		controller.burn(msg.sender, _amount);
		Transfer(msg.sender, 0x0, _amount);
	}

	// functions below this line are onlyController

	modifier onlyController() {
		assert(msg.sender == address(controller));
		_;
	}

	// In the future, when the controller supports multiple token
	// heads, allow the controller to reconstitute the transfer and
	// approval history.

	function controllerTransfer(address _from, address _to, uint _value) onlyController {
		Transfer(_from, _to, _value);
	}

	function controllerApprove(address _owner, address _spender, uint _value) onlyController {
		Approval(_owner, _spender, _value);
	}
}

contract Controller is Owned, Finalizable {
	Ledger public ledger;
	Token public token;

	function Controller() {
	}

	// functions below this line are onlyOwner

	function setToken(address _token) onlyOwner {
		token = Token(_token);
	}

	function setLedger(address _ledger) onlyOwner {
		ledger = Ledger(_ledger);
	}

	modifier onlyToken() {
		require(msg.sender == address(token));
		_;
	}

	modifier onlyLedger() {
		require(msg.sender == address(ledger));
		_;
	}

	// public functions

	function totalSupply() constant returns (uint) {
		return ledger.totalSupply();
	}

	function balanceOf(address _a) constant returns (uint) {
		return ledger.balanceOf(_a);
	}

	function allowance(address _owner, address _spender) constant returns (uint) {
		return ledger.allowance(_owner, _spender);
	}

	// functions below this line are onlyLedger

	// let the ledger send transfer events (the most obvious case
	// is when we mint directly to the ledger and need the Transfer()
	// events to appear in the token)
	function ledgerTransfer(address from, address to, uint val) onlyLedger {
		token.controllerTransfer(from, to, val);
	}

	// functions below this line are onlyToken

	function transfer(address _from, address _to, uint _value) onlyToken returns (bool success) {
		return ledger.transfer(_from, _to, _value);
	}

	function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken returns (bool success) {
		return ledger.transferFrom(_spender, _from, _to, _value);
	}

	function approve(address _owner, address _spender, uint _value) onlyToken returns (bool success) {
		return ledger.approve(_owner, _spender, _value);
	}

	function increaseApproval (address _owner, address _spender, uint _addedValue) onlyToken returns (bool success) {
		return ledger.increaseApproval(_owner, _spender, _addedValue);
	}

	function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyToken returns (bool success) {
		return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
	}

	function burn(address _owner, uint _amount) onlyToken {
		ledger.burn(_owner, _amount);
	}
}

contract Ledger is Owned, SafeMath, Finalizable {
	Controller public controller;
	mapping(address => uint) public balanceOf;
	mapping (address => mapping (address => uint)) public allowance;
	uint public totalSupply;
	uint public mintingNonce;
	bool public mintingStopped;

	// functions below this line are onlyOwner

	function Ledger() {
	}

	function setController(address _controller) onlyOwner notFinalized {
		controller = Controller(_controller);
	}

	function stopMinting() onlyOwner {
		mintingStopped = true;
	}

	function multiMint(uint nonce, uint256[] bits) onlyOwner {
		require(!mintingStopped);
		if (nonce != mintingNonce) return;
		mintingNonce += 1;
		uint256 lomask = (1 << 96) - 1;
		uint created = 0;
		for (uint i=0; i<bits.length; i++) {
			address a = address(bits[i]>>96);
			uint value = bits[i]&lomask;
			balanceOf[a] = balanceOf[a] + value;
			controller.ledgerTransfer(0, a, value);
			created += value;
		}
		totalSupply += created;
	}

	// functions below this line are onlyController

	modifier onlyController() {
		require(msg.sender == address(controller));
		_;
	}

	function transfer(address _from, address _to, uint _value) onlyController returns (bool success) {
		if (balanceOf[_from] < _value) return false;

		balanceOf[_from] = safeSub(balanceOf[_from], _value);
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		return true;
	}

	function transferFrom(address _spender, address _from, address _to, uint _value) onlyController returns (bool success) {
		if (balanceOf[_from] < _value) return false;

		var allowed = allowance[_from][_spender];
		if (allowed < _value) return false;

		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
		balanceOf[_from] = safeSub(balanceOf[_from], _value);
		allowance[_from][_spender] = safeSub(allowed, _value);
		return true;
	}

	function approve(address _owner, address _spender, uint _value) onlyController returns (bool success) {
		// require user to set to zero before resetting to nonzero
		if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
			return false;
		}

		allowance[_owner][_spender] = _value;
		return true;
	}

	function increaseApproval (address _owner, address _spender, uint _addedValue) onlyController returns (bool success) {
		uint oldValue = allowance[_owner][_spender];
		allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
		return true;
	}

	function decreaseApproval (address _owner, address _spender, uint _subtractedValue) onlyController returns (bool success) {
		uint oldValue = allowance[_owner][_spender];
		if (_subtractedValue > oldValue) {
			allowance[_owner][_spender] = 0;
		} else {
			allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
		}
		return true;
	}

	function burn(address _owner, uint _amount) onlyController {
		balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
		totalSupply = safeSub(totalSupply, _amount);
	}
}