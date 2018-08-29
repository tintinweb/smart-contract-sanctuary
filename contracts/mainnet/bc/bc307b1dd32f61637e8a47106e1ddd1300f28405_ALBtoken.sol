pragma solidity ^0.4.8;


contract SafeMath {
  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract ALBtoken is SafeMath{
    // Token information
    uint256 public vigencia;
    string public name;
    string public symbol;
    uint8 public decimals;
	uint256 public totalSupply;
	address public owner;
	
	
      //Token Variables	
    uint256[] public TokenMineSupply;
    uint256 public _MineId;
    uint256 totalSupplyFloat;
    uint256 oldValue;
    uint256 subValue;
    uint256 oldTotalSupply;
    uint256 TokensToModify;
    bool firstTime;
	
	  
     struct Minas {
     uint256 id;
	 string name;
	 uint tokensupply;
	 bool active;
	  }


    //Mapping
	/* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
	mapping(uint256=>Minas) public participatingMines;
    
	//Events
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /* This notifies clients about the amount burn*/
    event Burn(address indexed from, uint256 value);
	/* This notifies clients about the token add*/
    event AddToken(address indexed from, uint256 value);    
    /*This notifies clients about new mine created or updated*/
    event MineCreated (uint256 MineId, string MineName, uint MineSupply);
    event MineUpdated (uint256 MineId, string MineName, uint MineSupply, bool Estate);
	
	

   /* Initializes contract with initial supply tokens to the creator of the contract */
    function ALBtoken(){
        totalSupply = 0;      // Update total supply
        name = "Albarit";     // Set the name for display purposes
        symbol = "ALB";       // Set the symbol for display purposes
        decimals = 3;         // Amount of decimals for display purposes
        balanceOf[msg.sender] = totalSupply;  // Give the creator all initial tokens
		owner = msg.sender;  //Set contrac&#39;s owner
		vigencia =2178165600;
		firstTime = false;
    }

	//Administrator 
	 modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
        
       if(block.timestamp >= vigencia)
       {
           throw;
       }
       
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
       }
    
    

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
		if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
		
		if(block.timestamp >= vigencia)
       {
           throw;
       }
		
		if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
       if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
       
       if(block.timestamp >= vigencia)
       {
           throw;
       }
       
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
	
	/* A contract attempts to get the coins */
    function transferFromRoot(address _from, address _to, uint256 _value) onlyOwner returns (bool success) {
       if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
       
       if(block.timestamp >= vigencia)
       {
           throw;
       }
       
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function addToken(uint256 _value) onlyOwner returns (bool success) {
       if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
       
       if(block.timestamp >= vigencia)
       {
           throw;
       }
        //totalSupply = SafeMath.safeAdd(totalSupply,_value);                                // Updates totalSupply
        emit AddToken(msg.sender, _value);
        balanceOf[owner]=SafeMath.safeAdd(balanceOf[owner], _value); 
        return true;
    }
    
	function burn(uint256 _value) onlyOwner returns (bool success) {
       if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
       
        if(block.timestamp >= vigencia)
       {
           throw;
       }
        
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        //totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

	
	// transfer balance to owner
	function withdrawEther(uint256 amount) onlyOwner{
		if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
		if(block.timestamp >= vigencia)
       {
           throw;
       }
		
		if(msg.sender != owner)throw;
		owner.transfer(amount);
	}
	
	// can accept ether
	function() payable {
    }

  function RegisterMine(string _name, uint _tokensupply) onlyOwner
   {
     if (firstTime == false)
     {
         firstTime = true;
     }
     else
     {
      if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
     } 
     
      if(block.timestamp >= vigencia)
       {
           throw;
       }
      
       
       /*Register new mine&#39;s data*/
	   participatingMines[_MineId] = Minas ({
	       id: _MineId,
		   name: _name,
		   tokensupply: _tokensupply,
		   active: true
	   });
	   
	   /*add to array new item with new mine&#39;s token supply */
	   TokenMineSupply.push(_tokensupply);
	   
	   /*add to array new item with new mine&#39;s token supply */
	   
	   /*Uptade Albarit&#39;s total supply*/
	    /*uint256*/ totalSupplyFloat = 0;
        for (uint8 i = 0; i < TokenMineSupply.length; i++)
        {
            totalSupplyFloat = safeAdd(TokenMineSupply[i], totalSupplyFloat);
        } 
        
        totalSupply = totalSupplyFloat;
        addToken(_tokensupply);
        emit MineCreated (_MineId, _name, _tokensupply);
         _MineId = safeAdd(_MineId, 1);

   }
   
   
   function ModifyMine(uint256 _Id, bool _state, string _name, uint _tokensupply) onlyOwner 
   {
       if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
       
       if(block.timestamp >= vigencia)
       {
           throw;
       }
       
       
       /*uint256*/ oldValue = 0;
       /*uint256*/ subValue = 0;
       /*uint256*/ oldTotalSupply = totalSupply;
       /*uint256*/ TokensToModify = 0;
      /*update mine&#39;s data*/ 
	   participatingMines[_Id].active = _state;
	   participatingMines[_Id].name = _name;
   	   participatingMines[_Id].tokensupply = _tokensupply;
   	   
   	   oldValue = TokenMineSupply[_Id];
   	   
   	    if (_tokensupply > oldValue) {
          TokenMineSupply[_Id] = _tokensupply;
      } else {
          subValue = safeSub(oldValue, _tokensupply);
          TokenMineSupply[_Id]=safeSub(TokenMineSupply[_Id], subValue);
      }
   	   
   	   /*Uint256*/ totalSupplyFloat = 0;
   	   
        for (uint8 i = 0; i < TokenMineSupply.length; i++)
        {
            totalSupplyFloat = safeAdd(TokenMineSupply[i], totalSupplyFloat);
        } 
        
        emit MineUpdated(_Id, _name, _tokensupply,  _state);
          totalSupply = totalSupplyFloat;
          
          
        /*_tokensupply > oldValue*/
      if (totalSupply > oldTotalSupply) {
          TokensToModify = safeSub(totalSupply, oldTotalSupply);
          addToken(TokensToModify);
        } 
           /*_tokensupply > oldValue*/
      if (totalSupply < oldTotalSupply) {
          TokensToModify = safeSub(oldTotalSupply, totalSupply);
          burn(TokensToModify);
        } 
        
   }
   
function getTokenByMineID() external view returns (uint256[]) {
  return TokenMineSupply;
}

function ModifyVigencia(uint256 _vigencia) onlyOwner
{
    if(totalSupply == 0)
        {
            selfdestruct(owner);
        }
    vigencia = _vigencia;
}

}