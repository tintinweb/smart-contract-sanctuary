/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.4.11;

contract IERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SHITcoin is IERC20 {
    
    using SafeMath for uint256;
  
    string public symbol = 'SHIT';

    string public name = 'SHITcoin';
    
    uint8 public constant decimals = 18;
    
    uint256 public constant tokensPerEther = 1000;
    
    uint256 public _totalSupply = 99999999000000000000000000;
    
    
    uint256 public totalContribution = 0;
    
    uint256 public bonusSupply = 0;
    
    bool public purchasingAllowed = false;
    
    uint8 public currentSaleDay = 1; 
    uint8 public currentBonus = 100;
    
    string public startDate = '2017-09-16 18:00';
    
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function SHITcoin() {
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
    }
    
    function changeStartDate(string _startDate){
        require(
            msg.sender==owner
        );
        startDate = _startDate;
    }
    
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }
   
    function getStats() constant returns (uint256, uint256, uint256,  bool, uint256, uint256, string) {
        return (totalContribution, _totalSupply, bonusSupply, purchasingAllowed, currentSaleDay, currentBonus, startDate);
    }
    
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
    
     function rebrand(string _symbol, string _name) onlyOwner {
        symbol = _symbol;
        name   = _name;
     }

    
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    /* 
     * create payable token. Now you can purchase it
     *
     */
    function () payable {
        require(
            msg.value > 0
            && purchasingAllowed
        );
        /*  everything is in wei */
        uint256 baseTokens  = msg.value.mul(tokensPerEther);
        uint256 bonusTokens = msg.value.mul(currentBonus);
        /* send tokens to buyer. Buyer gets baseTokens + bonusTokens */
        balances[msg.sender] = balances[msg.sender].add(baseTokens).add(bonusTokens);
        /* send eth to owner */
        owner.transfer(msg.value);
        
        bonusSupply       = bonusSupply.add(bonusTokens);
        totalContribution = totalContribution.add(msg.value);
        _totalSupply      = _totalSupply.add(baseTokens).add(bonusTokens);

        Transfer(address(this), msg.sender, baseTokens.add(bonusTokens));
    }
    
    function enablePurchasing() onlyOwner {
        purchasingAllowed = true;
    }
    
    function disablePurchasing() onlyOwner {
        purchasingAllowed = false;
    }
    
    function setCurrentSaleDayAndBonus(uint8 _day) onlyOwner {
        require(
            (_day > 0 && _day < 11) 
        );

        currentBonus = 10; 
        currentSaleDay = _day;

        if(_day==1) {
            currentBonus = 100;
        } 
        if(_day==2) {
            currentBonus = 75;
        }
        if(_day>=3 && _day<5) {
            currentBonus = 50;
        }
        if(_day>=5 && _day<8) {
            currentBonus = 25;
        }

        
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(
            (balances[msg.sender] >= _value)
            && (_value > 0)
            && (_to != address(0))
            && (balances[_to].add(_value) >= balances[_to])
            && (msg.data.length >= (2 * 32) + 4)
        );

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(
            (allowed[_from][msg.sender] >= _value) // Check allowance
            && (balances[_from] >= _value) // Check if the sender has enough
            && (_value > 0) // Don't allow 0value transfer
            && (_to != address(0)) // Prevent transfer to 0x0 address
            && (balances[_to].add(_value) >= balances[_to]) // Check for overflows
            && (msg.data.length >= (2 * 32) + 4) //mitigates the ERC20 short address attack
            //most of these things are not necesary
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        
        require(
            (_value == 0) 
            || (allowed[msg.sender][_spender] == 0)
        );
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}