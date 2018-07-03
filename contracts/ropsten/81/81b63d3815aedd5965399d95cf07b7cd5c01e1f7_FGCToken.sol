pragma solidity ^0.4.0;


contract Token {

    string internal _symbol;
    string internal _name;

    uint8 internal _decimals;
    uint internal _totalSupply;

    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name()
        public
        view
        returns (string) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}


interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


library SafeMath {
  function sub(uint _base, uint _value)
    internal
    pure
    returns (uint) {
    assert(_value <= _base);
    return _base - _value;
  }

  function add(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
    _ret = _base + _value;
    assert(_ret >= _base);
  }

  function div(uint _base, uint _value)
    internal
    pure
    returns (uint) {
    assert(_value > 0 && (_base % _value) == 0);
    return _base / _value;
  }

  function mul(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
    _ret = _base * _value;
    assert(0 == _base || _ret / _base == _value);
  }
}


library Addresses {
  function isContract(address _base) internal constant returns (bool) {
      uint codeSize;
      assembly {
          codeSize := extcodesize(_base)
      }
      return codeSize > 0;
  }
}


contract FGCToken is Token(&quot;FGC&quot;, &quot;FGC Token&quot;, 0, 1000000000), ERC20, ERC223 {

    using SafeMath for uint;
    using Addresses for address;

    function FGCToken()
        public {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply()
        public
        view
        returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr)
        public
        view
        returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value)
        public
        returns (bool) {
        return transfer(_to, _value, &quot;&quot;);
    }

    function transfer(address _to, uint _value, bytes _data)
        public
        returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender]) {

            if (_to.isContract()) {
              ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
              _contract.tokenFallback(msg.sender, _value, _data);
            }

            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);

            Transfer(msg.sender, _to, _value);
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool) {
        return transferFrom(_from, _to, _value, &quot;&quot;);
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data)
        public
        returns (bool) {
        if (_allowances[_from][msg.sender] > 0 &&
            _value > 0 &&
            _allowances[_from][msg.sender] >= _value &&
            _balanceOf[_from] >= _value) {

              _allowances[_from][msg.sender] -= _value;

              if (_to.isContract()) {
                ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
                _contract.tokenFallback(msg.sender, _value, _data);
              }

            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);

            Transfer(_from, _to, _value);

            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value)
        public
        returns (bool) {
        if (_balanceOf[msg.sender] >= _value) {
          _allowances[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
        }
        return false;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint) {
        if (_allowances[_owner][_spender] < _balanceOf[_owner]) {
          return _allowances[_owner][_spender];
        }
        return _balanceOf[_owner];
    }
}