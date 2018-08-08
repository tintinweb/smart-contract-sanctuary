pragma solidity ^0.4.8;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// GROWCHAIN
// YOU get a GROWCHAIN, and YOU get a GROWCHAIN, and YOU get a GROWCHAIN!
contract GROWCHAIN is ERC20Interface {
    string public constant symbol = "GROW";
    string public constant name = "GROW CHAIN";
    uint8 public constant decimals = 2;

    uint256 _totalSupply = 0;
    uint256 _airdropAmount = 188 * 10 ** uint256(decimals);
    uint256 _cutoff = 1000000 * 10 ** uint256(decimals);
    uint256 _outAmount = 0;

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;

    // GROWCHAIN accepts request to tip-touch another GROWCHAIN
    mapping(address => mapping (address => uint256)) allowed;

    function GROWCHAIN() {
        initialized[msg.sender] = true;
        balances[msg.sender] = 5000000000 * 10 ** uint256(decimals) - _cutoff;
        _totalSupply = balances[msg.sender];
    }

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }

    // What&#39;s my girth?
    function balance() constant returns (uint256) {
        return getBalance(msg.sender);
    }

    // What is the length of a particular GROWCHAIN?
    function balanceOf(address _address) constant returns (uint256) {
        return getBalance(_address);
    }

    // Tenderly remove hand from GROWCHAIN and place on another GROWCHAIN
    function transfer(address _to, uint256 _amount) returns (bool success) {
        initialize(msg.sender);

        if (balances[msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(msg.sender, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // Perform the inevitable actions which cause release of that which each GROWCHAIN
    // is built to deliver. In EtherGROWCHAINLand there are only GROWCHAINes, so this 
    // allows the transmission of one GROWCHAIN&#39;s payload (or partial payload but that
    // is not as much fun) INTO another GROWCHAIN. This causes the GROWCHAINae to change 
    // form such that all may see the glory they each represent. Erections.
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        initialize(_from);

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(_from, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // Allow splooger to cause a payload release from your GROWCHAIN, multiple times, up to 
    // the point at which no further release is possible..
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // internal privats
    function initialize(address _address) internal returns (bool success) {
        if (_outAmount < _cutoff && !initialized[_address]) {
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            _outAmount += _airdropAmount;
            _totalSupply += _airdropAmount;
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (_outAmount < _cutoff && !initialized[_address]) {
            return balances[_address] + _airdropAmount;
        }
        else {
            return balances[_address];
        }
    }
    
    function getOutAmount()constant returns(uint256 amount){
        return _outAmount;
    }
    
}