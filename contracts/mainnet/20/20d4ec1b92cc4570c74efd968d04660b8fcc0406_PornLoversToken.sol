pragma solidity ^0.4.18;

contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public{
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);

    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract Token {
    function totalSupply () view public returns (uint256 supply);
    function balanceOf (address _owner) view public returns (uint256 balance);
    function transfer (address _to, uint256 _value) public returns (bool success);
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
    function approve (address _spender, uint256 _value) public returns (bool success);
    function allowance (address _owner, address _spender) view public returns (uint256 remaining);

    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
}

contract AbstractToken is Token {
    using SafeMath for uint;

    function AbstractToken () public payable{
        
    }

    function balanceOf (address _owner) view public returns (uint256 balance) {
        return accounts[_owner];
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        uint256 fromBalance = accounts[msg.sender];
        if (fromBalance < _value) return false;
        if (_value > 0 && msg.sender != _to) {
            accounts[msg.sender] = fromBalance.sub(_value);
            accounts[_to] = accounts[_to].add(_value);
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 spenderAllowance = allowances[_from][msg.sender];
        if (spenderAllowance < _value) return false;
        uint256 fromBalance = accounts[_from];
        if (fromBalance < _value) return false;

        allowances[_from][msg.sender] = spenderAllowance.sub(_value);

        if (_value > 0 && _from != _to) {
            accounts[_from] = fromBalance.sub(_value);
            accounts[_to] = accounts[_to].add(_value);
            Transfer(_from, _to, _value);
        }
        return true;
    }

    function approve (address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance (address _owner, address _spender) view public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    mapping (address => uint256) accounts;

    mapping (address => mapping (address => uint256)) private allowances;
}

contract AbstractVirtualToken is AbstractToken {
    using SafeMath for uint;

    uint256 constant MAXIMUM_TOKENS_COUNT = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 constant BALANCE_MASK = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 constant MATERIALIZED_FLAG_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

    function AbstractVirtualToken () public{
        
    }

    function totalSupply () view public returns (uint256 supply) {
        return tokensCount;
    }

    function balanceOf (address _owner) constant public returns (uint256 balance) { 
        return (accounts[_owner] & BALANCE_MASK).add(getVirtualBalance(_owner));
    }

    function transfer (address _to, uint256 _value) public returns (bool success) {
        if (_value > balanceOf(msg.sender)) return false;
        else {
            materializeBalanceIfNeeded(msg.sender, _value);
            return AbstractToken.transfer(_to, _value);
        }
    }

    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success) {
        if (_value > allowance(_from, msg.sender)) return false;
        if (_value > balanceOf(_from)) return false;
        else {
            materializeBalanceIfNeeded(_from, _value);
            return AbstractToken.transferFrom(_from, _to, _value);
        }
    }

    function virtualBalanceOf (address _owner) internal view returns (uint256 _virtualBalance);

    function getVirtualBalance (address _owner) private view returns (uint256 _virtualBalance) {
        if (accounts [_owner] & MATERIALIZED_FLAG_MASK != 0) return 0;
        else {
            _virtualBalance = virtualBalanceOf(_owner);
            uint256 maxVirtualBalance = MAXIMUM_TOKENS_COUNT.sub(tokensCount);
            if (_virtualBalance > maxVirtualBalance)
                _virtualBalance = maxVirtualBalance;
        }
    }

    function materializeBalanceIfNeeded (address _owner, uint256 _value) private {
        uint256 storedBalance = accounts[_owner];
        if (storedBalance & MATERIALIZED_FLAG_MASK == 0) {
            if (_value > storedBalance) {
                uint256 virtualBalance = getVirtualBalance(_owner);
                require (_value.sub(storedBalance) <= virtualBalance);
                accounts[_owner] = MATERIALIZED_FLAG_MASK | storedBalance.add(virtualBalance);
                tokensCount = tokensCount.add(virtualBalance);
            }
        }
    }

    uint256 tokensCount;
}

contract PornLoversToken is HasNoTokens, AbstractVirtualToken {
    
    uint256 private constant VIRTUAL_THRESHOLD = 0.1 ether;
    uint256 private constant VIRTUAL_COUNT = 91;

    event LogBonusSet(address indexed _address, uint256 _amount);

    function virtualBalanceOf(address _owner) internal view returns (uint256) {
        return _owner.balance >= VIRTUAL_THRESHOLD ? VIRTUAL_COUNT : 0;
    }

    function name() public pure returns (string result) {
        return "91porn.com";
    }

    function symbol() public pure returns (string result) {
        return "91porn";
    }

    function decimals() public pure returns (uint8 result) {
        return 0;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        bool success = super.transfer(_to, _value); 
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);

        return success;
    }

    function massNotify(address[] _owners) public onlyOwner {
        for (uint256 i = 0; i < _owners.length; i++) {
            Transfer(address(0), _owners[i], VIRTUAL_COUNT);
        }
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}