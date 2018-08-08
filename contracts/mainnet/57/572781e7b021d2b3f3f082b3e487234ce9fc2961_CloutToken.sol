pragma solidity ^0.4.16;


//Clout Token version 0.2


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
  uint public totalSupply;
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
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      
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







contract CloutToken is StandardToken {
  
    
    uint256 public rate = 0;
    uint256 public check = 0;
    
    address public owner = msg.sender;
    address public Founder1 = 0xB5D39A8Ea30005f9114Bf936025De2D6f353813E;  //sta
    address public Founder2 = 0x00A591199F53907480E1f5A00958b93B43200Fe4;  //ste
    address public Founder3 = 0x0d19C131400e73c71bBB2bC1666dBa8Fe22d242D;  //cd
    
	uint256 public tokenAmount;
  
    string public constant name = "Clout Token";
    string public constant symbol = "CLOUT";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETH.
	


  function mint(address receiver, uint amount) public {
      
      tokenAmount = ((msg.value/rate));
    
    if (tokenAmount != amount || amount == 0 || receiver != msg.sender)
    {
        revert();
    }
    

    totalSupply = totalSupply + amount;
    balances[receiver] += (amount*1 ether);

    // This will make the mint transaction appear in EtherScan.io
    // We can remove this after there is a standardized minting event
    Transfer(0, receiver, (amount*1 ether));
  }

  
  
	//This function is called when Ether is sent to the contract address
	//Even if 0 ether is sent.
    function () payable {


            //If all the tokens are gone, stop!
            if (totalSupply > 999999)
            {
                revert();
            }
            

            
            //Set the price to 0.00034 ETH/CLOUT
            //$0.10 per
            if (totalSupply < 25000)
            {
                rate = 0.00034*1 ether;
            }
            
            //Set the price to 0.0017 ETH/CLOUT
            //$0.50 per
            if (totalSupply >= 25000)
            {
                rate = 0.0017*1 ether;
            }
            
            //Set the price to 0.0034 ETH/CLOUT
            //$1.00 per
            if (totalSupply >= 125000)
            {
                rate = 0.0034*1 ether;
            }
            
            //Set the price to 0.0068 ETH/CLOUT
            //$2.00 per
            if (totalSupply >= 525000)
            {
                rate = 0.0068*1 ether;
            }
            
            
           
            
            tokenAmount = 0;
            tokenAmount = ((msg.value/rate));
            
            
            //Make sure they send enough to buy atleast 1 token.
            if (tokenAmount < 0)
            {
                revert();
            }
            
            
            //Make sure someone isn&#39;t buying more than the remaining supply
            check = 0;
            
            check = safeAdd(totalSupply, tokenAmount);
            
            if (check > 1000000)
            {
                revert();
            }
            
            
            //Make sure someone isn&#39;t buying more than the current tier
            if (totalSupply < 25000 && check > 25000)
            {
                revert();
            }
            
            //Make sure someone isn&#39;t buying more than the current tier
            if (totalSupply < 125000 && check > 125000)
            {
                revert();
            }
            
            //Make sure someone isn&#39;t buying more than the current tier
            if (totalSupply < 525000 && check > 525000)
            {
                revert();
            }
            
            
            //Prevent any ETH address from buying more than 50 CLOUT during the pre-sale
            uint256 senderBalance = (balances[msg.sender]/1 ether);
            if ((senderBalance + tokenAmount) > 200 && totalSupply < 25000)
            {
                revert();
            }
            
    
        	mint(msg.sender, tokenAmount);
        	tokenAmount = 0;							//set the &#39;amount&#39; var back to zero
        	check = 0;
        	rate = 0;
        		
        		
        	Founder1.transfer((msg.value/100)*49);					//Send the ETH 49%
        	Founder2.transfer((msg.value/100)*2);					//Send the ETH  2%
        	Founder3.transfer((msg.value/100)*49);					//Send the ETH 49%
    
    }


    //Burn all remaining tokens.
    //Only contract creator can do this.
    function Burn () {
        
        if (msg.sender == owner)
        {
            totalSupply = 1000000;
        } else {throw;}

    }
  
  
  
}