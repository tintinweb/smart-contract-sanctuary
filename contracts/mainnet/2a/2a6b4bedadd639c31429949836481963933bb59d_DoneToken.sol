pragma solidity ^0.4.13;

/* 
`* is owned
*/
contract owned {

    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function ownerTransferOwnership(address newOwner)
        onlyOwner
    {
        owner = newOwner;
    }

}

/* 
* safe math
*/
contract DSSafeAddSub {

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
    
    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) revert();
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) revert();
        return a - b;
    } 

}


/**
 *
 * @title  DoneToken
 * 
 * The official token powering Donation Efficiency.
 * DoneToken is a ERC.20 standard token with some custom functionality
 *
 */ 


contract DoneToken is owned, DSSafeAddSub {

    /* check address */
    modifier onlyBy(address _account) {
        if (msg.sender != _account) revert();
        _;
    }    

    /* vars */
    string public standard = &#39;Token 1.0&#39;;
    string public name = "DONE";
    string public symbol = "DET";
    uint8 public decimals = 16;
    uint public totalSupply = 150000000000000000000000; 

    address public priviledgedAddress;  
    bool public tokensFrozen;
    uint public crowdfundDeadline = now + 1 hours;       
    uint public nextFreeze = now + 2 hours;
    uint public nextThaw = now + 3 hours;
   

    /* map balances */
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;  

    /* events */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogTokensFrozen(bool indexed Frozen);    

    /*
    *  @notice sends all tokens to msg.sender on init    
    */  
    function DoneToken(){
        /* send creator all initial tokens 25,000,000 */
        balanceOf[msg.sender] = 150000000000000000000000;
        /* tokens are not frozen */  
        tokensFrozen = false;                                      

    }  

    /*
    *  @notice public function    
    *  @param _to address to send tokens to   
    *  @param _value number of tokens to transfer 
    *  @returns boolean success         
    */     
    function transfer(address _to, uint _value) public
        returns (bool success)    
    {
        if(tokensFrozen && msg.sender != priviledgedAddress) return false;  /* transfer only by priviledgedAddress during crowdfund or reward phases */
        if (balanceOf[msg.sender] < _value) return false;                   /* check if the sender has enough */
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;         /* check for overflows */              
        balanceOf[msg.sender] -=  _value;                                   /* subtract from the sender */
        balanceOf[_to] += _value;                                           /* add the same to the recipient */
        Transfer(msg.sender, _to, _value);                                  /* notify anyone listening that this transfer took place */
        return true;
    }      

    /*
    *  @notice public function    
    *  @param _from address to send tokens from 
    *  @param _to address to send tokens to   
    *  @param _value number of tokens to transfer     
    *  @returns boolean success      
    *  another contract attempts to spend tokens on your behalf
    */       
    function transferFrom(address _from, address _to, uint _value) public
        returns (bool success) 
    {                
        if(tokensFrozen && msg.sender != priviledgedAddress) return false;  /* transfer only by priviledgedAddress during crowdfund or reward phases */
        if (balanceOf[_from] < _value) return false;                        /* check if the sender has enough */
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;         /* check for overflows */                
        if (_value > allowance[_from][msg.sender]) return false;            /* check allowance */
        balanceOf[_from] -= _value;                                         /* subtract from the sender */
        balanceOf[_to] += _value;                                           /* add the same to the recipient */
        allowance[_from][msg.sender] -= _value;                             /* reduce allowance */
        Transfer(_from, _to, _value);                                       /* notify anyone listening that this transfer took place */
        return true;
    }        
 
    /*
    *  @notice public function    
    *  @param _spender address being granted approval to spend on behalf of msg.sender
    *  @param _value number of tokens granted approval for _spender to spend on behalf of msg.sender    
    *  @returns boolean success      
    *  approves another contract to spend some tokens on your behalf
    */      
    function approve(address _spender, uint _value) public
        returns (bool success)
    {
        /* set allowance for _spender on behalf of msg.sender */
        allowance[msg.sender][_spender] = _value;

        /* log event about transaction */
        Approval(msg.sender, _spender, _value);        
        return true;
    } 
  
    /*
    *  @notice address restricted function 
    *  crowdfund contract calls this to burn its unsold coins 
    */     
    function priviledgedAddressBurnUnsoldCoins() public
        /* only crowdfund contract can call this */
        onlyBy(priviledgedAddress)
    {
        /* totalSupply should equal total tokens in circulation */
        totalSupply = safeSub(totalSupply, balanceOf[priviledgedAddress]); 
        /* burns unsold tokens from crowdfund address */
        balanceOf[priviledgedAddress] = 0;
    }

    /*
    *  @notice public function 
    *  locks/unlocks tokens on a recurring cycle
    */         
    function updateTokenStatus() public
    {
        
        /* locks tokens during initial crowdfund period */
        if(now < crowdfundDeadline){                       
            tokensFrozen = true;         
            LogTokensFrozen(tokensFrozen);  
        }  

        /* locks tokens */
        if(now >= nextFreeze){          
            tokensFrozen = true;
            LogTokensFrozen(tokensFrozen);  
        }

        /* unlocks tokens */
        if(now >= nextThaw){         
            tokensFrozen = false;
            nextFreeze = now + 2 hours;
            nextThaw = now + 3 hours;              
            LogTokensFrozen(tokensFrozen);  
        }        
      
    }                              

    /*
    *  @notice owner restricted function
    *  @param _newPriviledgedAddress the address
    *  only this address can burn unsold tokens
    *  transfer tokens only by priviledgedAddress during crowdfund or reward phases
    */      
    function ownerSetPriviledgedAddress(address _newPriviledgedAddress) public 
        onlyOwner
    {
        priviledgedAddress = _newPriviledgedAddress;
    }   
                    
    
}