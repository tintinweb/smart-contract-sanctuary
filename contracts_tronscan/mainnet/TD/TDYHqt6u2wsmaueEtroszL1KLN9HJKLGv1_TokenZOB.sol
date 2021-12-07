//SourceUnit: ZOB_ONLINE.sol

pragma solidity = 0.7.6;
abstract contract Erc20Token{  
    uint256 public totalSupply;
    function balanceOf(address _owner) public view virtual returns (uint256 val);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}

contract TokenZOB is Erc20Token {
    using SafeMath for uint256;
    string public name = "ZOB";
    string public symbol = "ZOB";
    uint8 public decimals = 18;
    constructor(address issuerAddr) {
        totalSupply = 100000000000 * 10 ** uint256(decimals);
        balance[issuerAddr] = totalSupply;
        emit Transfer(address(0x0), issuerAddr, totalSupply);
    }
  
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balance[msg.sender] >= _value && balance[_to] + _value > balance[_to]);
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        if(_to == address(0x0)){
            totalSupply = totalSupply.sub(_value);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function batchTransfer(address[] calldata addrs, uint256[] calldata _values) public returns (bool success) {
        require(addrs.length == _values.length, "addrs,values length mismatch");
        for(uint i = 0; i < addrs.length; i++) {
            transfer(addrs[i], _values[i]);
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        require(balance[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balance[_from] = balance[_from].sub(_value);
        balance[_to] = balance[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 val) {  
        return balance[_owner];
    }
  
    function approve(address _spender, uint256 _value) public override returns (bool success) {   
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {  
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balance;  
    mapping (address => mapping (address => uint256)) allowed;  
}


library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint z) {
    if (x == 0) {
      return 0;
    }
    uint256 c = x * y;
    require(c / x == y, "ds-math-mul-overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint c) {
    require(b > 0,'ds-math-div-overflow');
    c = a / b;
  }
}