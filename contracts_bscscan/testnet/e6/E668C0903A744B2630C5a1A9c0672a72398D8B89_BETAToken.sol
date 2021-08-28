/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

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



interface ERC20Interface {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value, uint _fee);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ERC20 is ERC20Interface {
    using SafeMath for uint256;
    
    address public feeowner;
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
 
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        uint256 fee = (amount * 2) / 100;
        uint256 sub_value = SafeMath.safeAdd(amount,fee);

        require( _balances[msg.sender] >= sub_value);
        if ( _balances[recipient] + amount <  _balances[recipient]) revert("overflows");

        
        _balances[sender] = SafeMath.safeSub(_balances[sender], sub_value);
        _balances[recipient] = SafeMath.safeAdd(_balances[recipient], sub_value);
        _balances[feeowner] = SafeMath.safeAdd(_balances[feeowner], fee);
        emit Transfer(sender, recipient, amount, fee);
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



contract BETAToken is ERC20 {
    address public owner; 
    uint256 public _circSupply = 0; 
    uint8 public constant decimals = 18;
    string public constant name = "BETA"; 
    string public constant symbol = "BETA";
     
    event Issure(uint256 _value);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    constructor(uint256 _initialSupply) public {
        owner = msg.sender;
        _totalSupply = formatDecimals(_initialSupply);
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function changeFeeOwner(address newFeeOwner) public onlyOwner {
        feeowner = newFeeOwner;
    }

    function issure(uint256 _value) public onlyOwner {
        require(SafeMath.safeSub(_totalSupply, _circSupply) > 0, "less MIST");
        
        require(SafeMath.safeAdd(_circSupply, _value) <= _totalSupply,"large value"); 

        require(_balances[owner] + _value > _balances[owner],"large value"); 
        
        _balances[owner] = SafeMath.safeAdd(_balances[owner], _value);
        _circSupply = SafeMath.safeAdd(_circSupply, _value);
        
        emit Issure(_value);
    }
    
    function formatDecimals(uint256 _value) internal pure returns (uint256){
        return _value * 10 ** uint256(decimals);
    }
    
}