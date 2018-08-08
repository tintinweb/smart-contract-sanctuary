pragma solidity ^0.4.11;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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


   contract StudioToken  {
       
       using SafeMath for uint256;
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
   
    address public owner;
    bool public pauseForDividend = false;
    
    
    

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping ( uint => address ) public accountIndex;
    uint accountCount;
    
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function StudioToken(
       ) {
            
       uint256 initialSupply = 50000000;
        uint8 decimalUnits = 0;   
        appendTokenHolders ( msg.sender );    
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = "Studio";                                   // Set the name for display purposes
        symbol = "STDO";                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        
        owner = msg.sender;
    }
    
    function getBalance ( address tokenHolder ) returns (uint256) {
        return balanceOf[ tokenHolder ];
    }
    
    
    function getAccountCount ( ) returns (uint256) {
        return accountCount;
    }
    
    
    function getAddress ( uint256 slot ) returns ( address ) {
        return accountIndex[ slot ];
    }
    
    function getTotalSupply ( ) returns (uint256) {
        return totalSupply;
    }
    
    
   
    
   
    function appendTokenHolders ( address tokenHolder ) private {
        
        if ( balanceOf[ tokenHolder ] == 0 ){ 
            accountIndex[ accountCount ] = tokenHolder;
            accountCount++;
        }
        
    }
    

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (  pauseForDividend == true ) throw;// Check for overflows
        appendTokenHolders ( _to);
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        if (  pauseForDividend == true ) throw;// Check for overflows
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                // Check if the sender has enough
        if (_value > allowance[_from][msg.sender]) throw;    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
    
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    
    
    function pauseForDividend() onlyOwner{
        
        if ( pauseForDividend == true ) pauseForDividend = false; else pauseForDividend = true;
        
    }
    
    
    
    
    
    
    function transferOwnership ( address newOwner) onlyOwner {
        
        owner = newOwner;
        
        
    }
    
    
    
    
}


contract Dividend {
    StudioToken studio; // StudioICO contract instance
    address studio_contract;
   
  
    uint public accountCount;
    event Log(uint);
    address owner;


    uint256 public ether_profit;
    uint256 public profit_per_token;
    uint256 holder_token_balance;
    uint256 holder_profit;
    
    
    
     mapping (address => uint256) public balanceOf;
    
    
    event Message(uint256 holder_profit);
    event Transfer(address indexed_from, address indexed_to, uint value);

    // modifier for owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    // constructor which takes address of smart contract
    function Dividend(address Studiocontract) {
        owner = msg.sender;
        studio = StudioToken(Studiocontract);
    }
    // unnamed function which takes ether
    function() payable {
       
        studio.pauseForDividend();

        accountCount = studio.getAccountCount();
        
          Log(accountCount);

            ether_profit = msg.value;

            profit_per_token = ether_profit / studio.getTotalSupply();

            Message(profit_per_token);
        
        
        if (msg.sender == owner) {
            
            for ( uint i=0; i < accountCount ; i++ ) {
               
               address tokenHolder = studio.getAddress(i);
               balanceOf[ tokenHolder ] +=  studio.getBalance( tokenHolder ) * profit_per_token;
        
            }
            
          

          
            
        }
        
        
         studio.pauseForDividend();
    }
    
    
    
    function withdrawDividends (){
        
        
        msg.sender.transfer(balanceOf[ msg.sender ]);
        balanceOf[ msg.sender ] = 0;
        
        
    }
    
  
    


}