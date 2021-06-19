/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

//SPDX-License-Identifier: MIT

/**
    Name: Healthiers Token
    Symbol: HEALTH
    Decimals: 8
    @ 2021 Healthiers
*/

pragma solidity ^0.8.4; 

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    function allowance(address owner, address spender) public virtual view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC223Interface {
    function transfer(address to, uint value, bytes memory data) public virtual;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

abstract contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes memory _data) public  virtual;
}

contract OwnableInterface {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "OwnableInterface: new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract HealthiersToken is OwnableInterface, ERC20Interface, ERC223Interface {
    using SafeMath for uint;
     
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    bool internal _minting = false;
    bool internal _burning = false;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public limitAccount;

    event MintingDisable();
    event MintingEnable();
    event BurningEnable();
    event BurningDisable();
    event FrozenFunds(address target, bool frozen);
    event LimitFunds(address target, uint256 periodTime);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _symbol = symbol_;
        _name = name_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10 ** uint256(decimals_);
        balances[msg.sender] = totalSupply_ * 10 ** uint256(decimals_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function setPeriodAccount(address target, uint256 periodTime) onlyOwner public {
        limitAccount[target] = periodTime;
        emit LimitFunds(target, periodTime);
    }
    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_to != msg.sender, "HealthiersToken: transfer to the own address");
        require(_value > 0, "HealthiersToken: transfer zero value");
        require(!frozenAccount[msg.sender], "HealthiersToken: frozenAccount");
        require(limitAccount[msg.sender] < uint256(block.timestamp), "HealthiersToken: do not reach period");
        require(!frozenAccount[_to], "HealthiersToken: frozenAccount");
        
        require(_to != address(0), "HealthiersToken: transfer to the zero address");
        require(_value <= balances[msg.sender], "HealthiersToken: transfer amount exceeds balance");
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value, bytes memory _data) public override {
        require(_to != msg.sender, "HealthiersToken: transfer to the own address");
        require(_value > 0, "HealthiersToken: transfer zero value");
        require(!frozenAccount[msg.sender], "HealthiersToken: frozenAccount");
        require(limitAccount[msg.sender] < uint256(block.timestamp), "HealthiersToken: do not reach period");
        require(!frozenAccount[_to], "HealthiersToken: frozenAccount");
        
        require(_to != address(0), "HealthiersToken: transfer to the zero address");
        require(_value <= balances[msg.sender], "HealthiersToken: transfer amount exceeds balance");
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_to != _from, "HealthiersToken: transfer to the own address");
        require(_value > 0, "HealthiersToken: transfer zero value");
        require(!frozenAccount[_from], "HealthiersToken: frozenAccount");
        require(limitAccount[_from] < uint256(block.timestamp), "HealthiersToken: do not reach period");
        require(!frozenAccount[_to], "HealthiersToken: frozenAccount");
        
        require(_to != address(0), "HealthiersToken: transfer to the zero address");
        require(_value <= balances[_from], "HealthiersToken: transfer amount exceeds balance");
        require(_value <= allowed[_from][msg.sender], "HealthiersToken: transfer amount exceeds balance");
        
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function minting() public view returns (bool) {
        return _minting;
    }

    function _mintingDisable() onlyOwner public {
        _minting = false;
        emit MintingDisable();
    }

    function _mintingEnable() onlyOwner public {
        _minting = true;
        emit MintingEnable();
    }

    function mint(address _to, uint256 _value) onlyOwner public {
        require(_to != address(0), "HealthiersToken: mint to the zero address");
        require(_minting, "HealthiersToken: minting is disabled");

        _totalSupply += _value;
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(address(0), _to, _value);
    }

    function burning() public view returns (bool) {
        return _burning;
    }

    function _burningDisable() onlyOwner public {
        _burning = false;
        emit BurningDisable();
    }

    function _burningEnable() onlyOwner public {
        _burning = true;
        emit BurningEnable();
    }

    function burn(uint256 _value) onlyOwner public {
        require(_burning, "HealthiersToken: burning is disabled");
        uint256 accountBalance = balances[msg.sender];
        require(accountBalance >= _value, "HealthiersToken: burn amount exceeds balance");
        require(_totalSupply >= _value, "HealthiersToken: burn amount exceeds totalSupply");
        _totalSupply -= _value;
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);

        emit Transfer(msg.sender, address(0), _value);
    }
    
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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