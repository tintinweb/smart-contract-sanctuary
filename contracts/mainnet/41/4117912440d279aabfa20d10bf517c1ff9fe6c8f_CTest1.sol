pragma solidity ^0.4.16;


contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}




contract ERC20 {
  uint public totalSupply = 1000000;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
      
      if (_value < 0) {
          revert();
      }
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      
      if (_value < 0) {
          revert();
      }
      
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}







contract CTest1 is StandardToken {
  
    // Set the contract controller address
    // Set the 3 Founder addresses
    address public owner = msg.sender;
    address public Founder1 = 0xB5D39A8Ea30005f9114Bf936025De2D6f353813E;
    address public Founder2 = 0x00A591199F53907480E1f5A00958b93B43200Fe4;
    address public Founder3 = 0x0d19C131400e73c71bBB2bC1666dBa8Fe22d242D;

  
    function name() constant returns (string) { return "CTest1 Token"; }
    function symbol() constant returns (string) { return "CTest1"; }
    function decimals() constant returns (uint) { return 18; }
    
    
    
    function () payable {
        
        
        //If all the tokens are gone, stop!
        if (totalSupply < 1)
        {
            throw;
        }
        
        
        uint256 rate = 0;
        address receiver = msg.sender;
        
        
        //Set the price to 0.0003 ETH/CTest1
        //$0.10 per
        if (totalSupply > 975000)
        {
            rate = 3340;
        }
        
        //Set the price to 0.0015 ETH/CTest1
        //$0.50 per
        if (totalSupply < 975001)
        {
            rate = 668;
        }
        
        //Set the price to 0.0030 ETH/CTest1
        //$1.00 per
        if (totalSupply < 875001)
        {
            rate = 334;
        }
        
        //Set the price to 0.0075 ETH/CTest1
        //$2.50 per
        if (totalSupply < 475001)
        {
            rate = 134;
        }
        
        
       

        
        uint256 tokens = safeMul(msg.value, rate);
        tokens = tokens/1 ether;
        
        
        //Make sure they send enough to buy atleast 1 token.
        if (tokens < 1)
        {
            throw;
        }
        
        
        //Make sure someone isn&#39;t buying more than the remaining supply
        uint256 check = safeSub(totalSupply, tokens);
        if (check < 0)
        {
            throw;
        }
        
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 975000 && check < 975000)
        {
            throw;
        }
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 875000 && check < 875000)
        {
            throw;
        }
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 475000 && check < 475000)
        {
            throw;
        }
        
        
        //Prevent any ETH address from buying more than 50 CTest1 during the pre-sale
        if ((balances[receiver] + tokens) > 50 && totalSupply > 975000)
        {
            throw;
        }
        
        
        balances[receiver] = safeAdd(balances[receiver], tokens);
        
        totalSupply = safeSub(totalSupply, tokens);
        
        Transfer(0, receiver, tokens);



	    Founder1.transfer((msg.value/3));					//Send the ETH
	    Founder2.transfer((msg.value/3));					//Send the ETH
	    Founder3.transfer((msg.value/3));					//Send the ETH
        
    }
    
    
    
    //Burn all remaining tokens.
    //Only contract creator can do this.
    function Burn () {
        
        if (msg.sender == owner && totalSupply > 0)
        {
            totalSupply = 0;
        } else {throw;}

    }
  
  
  
}