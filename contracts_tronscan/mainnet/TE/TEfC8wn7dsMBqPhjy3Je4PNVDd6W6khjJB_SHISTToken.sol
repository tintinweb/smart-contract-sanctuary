//SourceUnit: SHISTToken.sol

pragma solidity ^0.5.0;

library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {

    uint256 public totalSupply;

    function balanceOf(address _owner) view public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    mapping(address => bool) public _isExcludedFromFee;
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    address public burnAddress;
    
    function removeAllFee() private {
        if(_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }
    

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);
        require(_balances[_to] + _value > _balances[_to]);
        
        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[_to])
            removeAllFee();
            
        
        _balances[msg.sender] = SafeMath.safeSub(_balances[msg.sender], _value);
        
        uint256 fee = _value.safeMul(_taxFee).safeDiv(100);
        
        _balances[_to] = _balances[_to].safeAdd(_value.safeSub(fee));
        
        if(fee > 0) {
            _balances[burnAddress] = _balances[burnAddress].safeAdd(fee);
            emit Transfer(msg.sender, burnAddress, fee);
        }
        
        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[_to])
            restoreAllFee();
            
        emit Transfer(msg.sender, _to, _value.safeSub(fee));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowed[_from][msg.sender]);
        require(_balances[_to] + _value > _balances[_to]);
        
        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[_to])
            removeAllFee();
            
        _balances[_from] = SafeMath.safeSub(_balances[_from], _value);
        _allowed[_from][msg.sender] = SafeMath.safeSub(_allowed[_from][msg.sender], _value);
        
        uint256 fee = _value.safeMul(_taxFee).safeDiv(100);
        _balances[_to] = _balances[_to].safeAdd(_value.safeSub(fee));
        
        if(fee > 0) {
            _balances[burnAddress] = _balances[burnAddress].safeAdd(fee);
            emit Transfer(_from, burnAddress, fee);
        }
         
        
        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[_to])
            restoreAllFee();
            
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (_allowed[msg.sender][_spender] == 0));
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
}

contract SHISTToken is StandardToken {
    

    string public name = "SHIST Sniper rifle";
    uint8 public decimals = 18;
    string public symbol = "SHIST";
    uint256 public totalSupply = 10000000000*10**uint256(decimals);
    
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _burnAddress) public {
        _balances[msg.sender] = totalSupply;
        _isExcludedFromFee[msg.sender] = true;
        
        owner = msg.sender;
        
        burnAddress = _burnAddress;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
  
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function () external payable {
        revert();
    }
  
}