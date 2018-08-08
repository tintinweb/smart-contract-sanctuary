pragma solidity >=0.4.4;

//from Zeppelin
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    address newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Finalizable is Owned {
    bool public finalized;

    function finalize() onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        if (finalized) throw;
        _;
    }
}

contract IToken {
    function transfer(address _to, uint _value) returns (bool);
    function balanceOf(address owner) returns(uint);
}

contract TokenReceivable is Owned {
    event logTokenTransfer(address token, address to, uint amount);

    function claimTokens(address _token, address _to) onlyOwner returns (bool) {
        IToken token = IToken(_token);
        uint balance = token.balanceOf(this);
        if (token.transfer(_to, balance)) {
            logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions {

    string public name = "FunFair";
    uint8 public decimals = 8;
    string public symbol = "FUN";

    Controller controller;
    address owner;

    function setController(address _c) onlyOwner notFinalized {
        controller = Controller(_c);
    }

    function balanceOf(address a) constant returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() constant returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function transfer(address _to, uint _value)
    onlyPayloadSize(2)
    returns (bool success) {
       success = controller.transfer(msg.sender, _to, _value);
        if (success) {
            Transfer(msg.sender, _to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value)
    onlyPayloadSize(3)
    returns (bool success) {
       success = controller.transferFrom(msg.sender, _from, _to, _value);
        if (success) {
            Transfer(_from, _to, _value);
        }
    }

    function approve(address _spender, uint _value)
    onlyPayloadSize(2)
    returns (bool success) {
        //promote safe user behavior
        if (controller.allowance(msg.sender, _spender) > 0) throw;

        success = controller.approve(msg.sender, _spender, _value);
        if (success) {
            Approval(msg.sender, _spender, _value);
        }
    }

    function increaseApproval (address _spender, uint _addedValue)
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.increaseApproval(msg.sender, _spender, _addedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
        }
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
        }
    }

    modifier onlyPayloadSize(uint numwords) {
    assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function burn(uint _amount) {
        controller.burn(msg.sender, _amount);
        Transfer(msg.sender, 0x0, _amount);
    }
}

contract Controller is Owned, Finalizable {
    Ledger public ledger;
    address public token;

    function setToken(address _token) onlyOwner {
        token = _token;
    }

    function setLedger(address _ledger) onlyOwner {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        if (msg.sender != token) throw;
        _;
    }

    function totalSupply() constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) onlyToken constant returns (uint) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender)
    onlyToken constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyToken
    returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyToken
    returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }


    function burn(address _owner, uint _amount) onlyToken {
        ledger.burn(_owner, _amount);
    }
}

contract Ledger is Owned, SafeMath, Finalizable {
    address public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;

    function setController(address _controller) onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        if (msg.sender != controller) throw;
        _;
    }

    function transfer(address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value)
    onlyController
    returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    event LogMint(address indexed owner, uint amount);
    event LogMintingStopped();

    function mint(address _a, uint _amount) onlyOwner mintingActive {
        balanceOf[_a] += _amount;
        totalSupply += _amount;
        LogMint(_a, _amount);
    }

    function multiMint(uint[] bits) onlyOwner mintingActive {
        for (uint i=0; i<bits.length; i++) {
	    address a = address(bits[i]>>96);
	    uint amount = bits[i]&((1<<96) - 1);
	    mint(a, amount);
        }
    }

    bool public mintingStopped;

    function stopMinting() onlyOwner {
        mintingStopped = true;
        LogMintingStopped();
    }

    modifier mintingActive() {
        if (mintingStopped) throw;
        _;
    }

    function burn(address _owner, uint _amount) onlyController {
        balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}