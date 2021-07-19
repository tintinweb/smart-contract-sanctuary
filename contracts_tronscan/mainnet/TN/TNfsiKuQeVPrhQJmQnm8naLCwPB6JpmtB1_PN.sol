//SourceUnit: new_pn.sol

pragma solidity 0.6.0;

library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0 ) {
          return 0;
      }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a && c >= b, "SafeMath: addition overflow");
    return c;
  }
}



interface TRC20Interface {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TRC20 is TRC20Interface {
    using SafeMath for uint256;
    uint256 public _totalSupply;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
 
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address _owner) override public view returns (uint256) {
        return _balances[_owner];
    }
 
    function allowance(address _owner,address spender) override public view returns (uint256) {
        return _allowed[_owner][spender];
    }
 
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0x0),"address cannot be empty.");  
        require(_balances[_to] + _value > _balances[_to],"_value too large"); 

        uint256 previousBalance = SafeMath.safeAdd(_balances[_from], _balances[_to]); //校验
        _balances[_from] = SafeMath.safeSub(_balances[_from], _value);
        _balances[_to] = SafeMath.safeAdd(_balances[_to], _value);
        emit Transfer(_from, _to, _value);

        assert (SafeMath.safeAdd(_balances[_from], _balances[_to]) == previousBalance);
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
        _allowed[_from][msg.sender] = SafeMath.safeSub(_allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _delegatee, uint256 _value) override public returns (bool) {
        require(_delegatee != address(0x0),"address cannot be empty.");
        _allowed[msg.sender][_delegatee] = _value;
        emit Approval(msg.sender, _delegatee, _value);
        return true;
  }
  
}



contract PN is TRC20 {
    address public owner; 
    uint256 public _circSupply = 0; //已发行量
    uint8 public constant decimals = 18;
    string public constant name = "PN"; 
    string public constant symbol = "pn";
    uint256 private _preIssure = formatDecimals(2000000); ////预释放200w
     
    event Issure(uint256 _value);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    constructor(uint256 _initialSupply, address _boss) public {
        owner = msg.sender;
        _totalSupply = formatDecimals(_initialSupply);
        _balances[_boss] = _preIssure; //预释放200万
        _circSupply = _preIssure; //已发行量
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    //释放千分之五
    function issure() public onlyOwner {
        require(SafeMath.safeSub(_totalSupply, _circSupply) > 0, "less pn");
        uint256 _value = SafeMath.safeDiv(SafeMath.safeSub(_totalSupply, _circSupply), 200);
        require(_balances[owner] + _value > _balances[owner],"large value"); 
        _balances[owner] = SafeMath.safeAdd(_balances[owner], _value);
        _circSupply = SafeMath.safeAdd(_circSupply, _value);
        emit Issure(_value);
    }
    
    //格式化(_value * 10 ** uint256(decimals))
    function formatDecimals(uint256 _value) internal pure returns (uint256){
        return _value * 10 ** uint256(decimals);
    }
    
}