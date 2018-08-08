pragma solidity ^0.4.24;

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

// ioucoin
// YOU get a ioucoin, and YOU get a ioucoin, and YOU get a ioucoin!
contract IOUcoin is ERC20Interface {
    string public constant symbol = "IOU";
    string public constant name = "LOVE COIN";
    uint8 public constant decimals = 8;

    uint256 _totalSupply = 5201314000000000;
    uint256 _airdropAmount = 52013140000;
    uint256 _cutoff = _airdropAmount * 520131400;

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;

    // ioucoin accepts request to tip-touch another ioucoin
    mapping(address => mapping (address => uint256)) allowed;

    function ioucoin() {
        initialized[msg.sender] = true;
        balances[msg.sender] = _airdropAmount * 52013140;
        _totalSupply = balances[msg.sender];
    }

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }

    // What&#39;s my girth?
    function balance() constant returns (uint256) {
        return getBalance(msg.sender);
    }

    // What is the length of a particular ioucoin?
    function balanceOf(address _address) constant returns (uint256) {
        return getBalance(_address);
    }

    // Tenderly remove hand from ioucoin and place on another ioucoin
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

    // Perform the inevitable actions which cause release of that which each ioucoin
    // is built to deliver. In EtherPenisLand there are only ioucoin, so this 
    // allows the transmission of one ioucoin payload (or partial payload but that
    // is not as much fun) INTO another ioucoin. This causes the ioucoin to change 
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

    // Allow splooger to cause a payload release from your ioucoin, multiple times, up to 
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
        if (_totalSupply < _cutoff && !initialized[_address]) {
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            _totalSupply += _airdropAmount;
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (_totalSupply < _cutoff && !initialized[_address]) {
            return balances[_address] + _airdropAmount;
        }
        else {
            return balances[_address];
        }
    }
}