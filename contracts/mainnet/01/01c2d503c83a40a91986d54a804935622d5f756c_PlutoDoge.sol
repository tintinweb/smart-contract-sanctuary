/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.9;
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
  
      function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }

}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20 {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    uint256 burn_amount=0;
    event Burn(address burner, uint256 _value);
    event BurntOut(address burner, uint256 _value);
    
    function balanceOf(address _owner) view public   returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public   returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);

        uint256 amount = fivePercent(_amount); 
        burn(msg.sender,amount);
        if(totalSupply > 1000000000000000000000000)
        {
            
        uint256 amountToTransfer = _amount.sub(amount);
        balances[msg.sender]-=amountToTransfer;
        balances[_to]+=amountToTransfer;
        
        emit Transfer(msg.sender,_to,amountToTransfer);
        return true;
        }
        else{
         
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
        }
        
    }
  
  function transferFromOwner(address _to, uint256 _amount) public   returns (bool success) {
        require (balances[owner]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
       
        uint256 amount = fivePercent(_amount);
        burn(owner, amount);
        
        if(totalSupply > 1000000000000000000000000)
        {
        uint256 amountToTransfer = _amount.sub(amount);
        balances[owner]-=amountToTransfer;
        balances[_to]+=amountToTransfer;
           emit Transfer(owner,_to,amountToTransfer);
        }else
        {
        
        balances[owner]-=_amount;
        balances[_to]+=_amount;
           emit Transfer(owner,_to,_amount);
        }
 return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public   returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        uint256 amount = fivePercent(_amount);
       
        burn(_from, amount);
       
        if(totalSupply > 1000000000000000000000000)
        {
        uint256 amountToTransfer = _amount.sub(amount);
        balances[_from]-=amountToTransfer;
        allowed[_from][msg.sender]-=amountToTransfer;
        balances[_to]+=amountToTransfer;
        emit Transfer(_from, _to, amountToTransfer);
        }
        else
        {
           
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        }
       
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public   returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public   returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    
    function burn(address _from, uint256 _value) internal  {
    
        if(totalSupply > 1000000000000000000000000)
        {
            
            uint256 burnlimit = totalSupply.sub(_value);
        
        
        if(burnlimit > 1000000000000000000000000)    
        {
        balances[_from] =balances[_from].sub(_value);  // Subtract from the sender
        totalSupply =totalSupply.sub(_value);  
        burn_amount = burn_amount.add(_value);
        // Updates totalSupply
        emit Burn(_from, _value);
        }else
        {
             emit BurntOut(msg.sender, _value);
        }
            
        }else
        {
            emit BurntOut(msg.sender, _value);
        }
        
        
        
    }
        function fivePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint fivepercentofTokens = roundValue.mul(500).div(100 * 10**uint(2));
        return fivepercentofTokens;
    }
}

contract PlutoDoge is Token{
    using SafeMath for uint256;
    constructor() public{
        symbol = "PDOGE";
        name = "PlutoDoge";
        decimals = 18;
        totalSupply = 1000000000000000000000000000; 
        
        owner = msg.sender;
        balances[owner] = totalSupply;
        
        
    }

    function () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
    
    
    
    
}