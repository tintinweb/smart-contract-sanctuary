pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ParentToken {

     /* library used for calculations */
    using SafeMath for uint256; 

    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address=>uint)) allowance;        



    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ParentToken(uint256 currentSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol){
            
       balances[msg.sender] =  currentSupply;    // Give the creator all initial tokens  
       totalSupply = currentSupply;              // Update total supply 
       name = tokenName;                         // Set the name for display purposes
       decimals = decimalUnits;                  // Decimals for the tokens
       symbol = tokenSymbol;					// Set the symbol for display purposes	
    }
    
    

   ///@notice Transfer tokens to the beneficiary account
   ///@param  to The beneficiary account
   ///@param  value The amount of tokens to be transfered  
       function transfer(address to, uint value) returns (bool success){
        require(
            balances[msg.sender] >= value 
            && value > 0 
            );
            balances[msg.sender] = balances[msg.sender].sub(value);    
            balances[to] = balances[to].add(value);
            return true;
    }
    
	///@notice Allow another contract to spend some tokens in your behalf
	///@param  spender The address authorized to spend 
	///@param  value The amount to be approved 
    function approve(address spender, uint256 value)
        returns (bool success) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    ///@notice Approve and then communicate the approved contract in a single tx
	///@param  spender The address authorized to spend 
	///@param  value The amount to be approved 
    function approveAndCall(address spender, uint256 value, bytes extraData)
        returns (bool success) {    
        tokenRecipient recSpender = tokenRecipient(spender);
        if (approve(spender, value)) {
            recSpender.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }



   ///@notice Transfer tokens between accounts
   ///@param  from The benefactor/sender account.
   ///@param  to The beneficiary account
   ///@param  value The amount to be transfered  
    function transferFrom(address from, address to, uint value) returns (bool success){
        
        require(
            allowance[from][msg.sender] >= value
            &&balances[from] >= value
            && value > 0
            );
            
            balances[from] = balances[from].sub(value);
            balances[to] =  balances[to].add(value);
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            return true;
        }
        
}


contract GlobalBTC is owned,ParentToken{

     /* library used for calculations */
    using SafeMath for uint256; 

     /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;  
    uint256 public currentSupply= 3000000000000000;
    string public constant symbol = "GBTC";
    string public constant tokenName = "GlobalBTC";
    uint8 public constant decimals = 8;

    

    mapping (address => bool) public frozenAccount;


  ///@notice Default function used for any payments made.
    function () payable {
        acceptPayment();    
    }
   

   ///@notice Accept payment and transfer to owner account. 
    function acceptPayment() payable {
        require(msg.value>0);
        
        owner.transfer(msg.value);
    }



    function GlobalBTC()ParentToken(currentSupply,tokenName,decimals,symbol){}


   ///@notice Provides balance of the account requested 
   ///@param  add Address of the account for which balance is being enquired
    function balanceOf(address add) constant returns (uint balance){
       return balances[add];
    }
    
    
    
   ///@notice Transfer tokens to the beneficiary account
   ///@param  to The beneficiary account
   ///@param  value The amount of tokens to be transfered 
        function transfer(address to, uint value) returns (bool success){
        require(
            balances[msg.sender] >= value 
            && value > 0 
            && (!frozenAccount[msg.sender]) 										// Allow transfer only if account is not frozen
            );
            balances[msg.sender] = balances[msg.sender].sub(value);                 
            balances[to] = balances[to].add(value);                               // Update the balance of beneficiary account
			Transfer(msg.sender,to,value);
            return true;
    }
    
    

   ///@notice Transfer tokens between accounts
   ///@param  from The benefactor/sender account.
   ///@param  to The beneficiary account
   ///@param  value The amount to be transfered  
        function transferFrom(address from, address to, uint value) returns (bool success){
        
            require(
            allowance[from][msg.sender] >= value
            &&balances[from] >= value                                                 //Check if the benefactor has sufficient balance
            && value > 0 
            && (!frozenAccount[msg.sender])                                           // Allow transfer only if account is not frozen
            );
            
            balances[from] = balances[from].sub(value);                               // Deduct from the benefactor account
            balances[to] =  balances[to].add(value);                                  // Update the balance of beneficiary account
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
            Transfer(from,to,value);
            return true;
        }
        
    

   ///@notice Increase the number of coins
   ///@param  target The address of the account where the coins would be added.
   ///@param  mintedAmount The amount of coins to be added
        function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balances[target] = balances[target].add(mintedAmount);      //Add the amount of coins to be increased to the balance
        currentSupply = currentSupply.add(mintedAmount);            //Add the amount of coins to be increased to the supply
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

   ///@notice Freeze the account at the target address
   ///@param  target The address of the account to be frozen
    function freezeAccount(address target, bool freeze) onlyOwner {
        require(freeze);                                             //Check if account has to be freezed
        frozenAccount[target] = freeze;                              //Freeze the account  
        FrozenFunds(target, freeze);
    }


   /// @notice Remove tokens from the system irreversibly
    /// @param value The amount of money to burn
    function burn(uint256 value) onlyOwner returns (bool success)  {
        require (balances[msg.sender] > value && value>0);            // Check if the sender has enough balance
        balances[msg.sender] = balances[msg.sender].sub(value);       // Deduct from the sender
        currentSupply = currentSupply.sub(value);                     // Update currentSupply
        Burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) onlyOwner returns (bool success) {
        require(balances[from] >= value);                                         // Check if the targeted balance is enough
        require(value <= allowance[from][msg.sender]);                            // Check allowance
        balances[from] = balances[from].sub(value);                               // Deduct from the targeted balance
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);     // Deduct from the sender&#39;s allowance
        currentSupply = currentSupply.sub(value);                                 // Update currentSupply
        Burn(from, value);
        return true;
    }



  /* This notifies clients about the amount transfered */
	event Transfer(address indexed _from, address indexed _to,uint256 _value);     

  /* This notifies clients about the amount approved */
	event Approval(address indexed _owner, address indexed _spender,uint256 _value);

  /* This notifies clients about the account freeze */
	event FrozenFunds(address target, bool frozen);
    
  /* This notifies clients about the amount burnt */
   event Burn(address indexed from, uint256 value);

}