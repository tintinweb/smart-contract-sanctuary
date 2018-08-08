pragma solidity ^0.4.16;

/**
 * The Owned contract ensures that only the creator (deployer) of a 
 * contract can perform certain tasks.
 */
contract Owned {
    address public owner = msg.sender;
    event OwnerChanged(address indexed old, address indexed current);
    modifier only_owner { require(msg.sender == owner); _; }
    function setOwner(address _newOwner) only_owner public { emit OwnerChanged(owner, _newOwner); owner = _newOwner; }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract DepositTiken is Owned {
    
    using SafeMath for uint;
    
    uint public _money = 0;
//  uint public _moneySystem = 0;
    uint public _tokens = 0;
    uint public _sellprice = 10**18;
    uint public contractBalance;
    
    // сохранить баланс на счетах пользователя
    
    mapping (address => uint) balances;
    
    event SomeEvent(address indexed from, address indexed to, uint value, bytes32 status);
    constructor () public {
        uint s = 10**18;
        _sellprice = s.mul(95).div(100);
    }
    function balanceOf(address addr) public constant returns(uint){
        return balances[addr];
    }
    function balance() public constant returns(uint){
        return balances[msg.sender];
    }
    // OK
    function buy() external payable {
        uint _value = msg.value.mul(10**18).div(_sellprice.mul(100).div(95));
        
        _money += msg.value.mul(97).div(100);
        //_moneySystem += msg.value.mul(3).div(100);
        
        owner.transfer(msg.value.mul(3).div(100));
        
        _tokens += _value;
        balances[msg.sender] += _value;
        
        _sellprice = _money.mul(10**18).mul(99).div(_tokens).div(100);
        
        address _this = this;
        contractBalance = _this.balance;
        
        emit SomeEvent(msg.sender, this, _value, "buy");
    }
    
    function sell (uint256 countTokens) public {
        require(balances[msg.sender] - countTokens >= 0);
        
        uint _value = countTokens.mul(_sellprice).div(10**18);
        
        _money -= _value;
        
        _tokens -= countTokens;
        balances[msg.sender] -= countTokens;
        
        if(_tokens > 0) {
            _sellprice = _money.mul(10**18).mul(99).div(_tokens).div(100);
        }
        
        address _this = this;
        contractBalance = _this.balance;
        
        msg.sender.transfer(_value);
        
        emit SomeEvent(msg.sender, this, _value, "sell");
    }
    function getPrice() public constant returns (uint bid, uint ask) {
        bid = _sellprice.mul(100).div(95);
        ask = _sellprice;
    }
}