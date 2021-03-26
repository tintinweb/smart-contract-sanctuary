/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.5;
/*Math operations with safety checks */
contract SafeMath { 
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;  
    }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {  
    return a/b;  
    }
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;  
    }
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;  
    }  
  function safePower(uint a, uint b) internal pure returns (uint256) {
      uint256 c = a**b;
      return c;  
    }
}

interface IToken {
  function transfer(address _to, uint256 _value) external;
}

contract ZebiToken is SafeMath{
    string public name;    
    string public symbol;    
    uint8   public decimals;    
    uint256 public totalSupply;  
    address payable public owner;
    uint256 public totalSupplyLimit;
    bool    public pauseMint;
    address public minter;
    address payable public ownerTemp;
    uint256 blocknumberLastAcceptOwner;
    uint256 blocknumberLastAcceptMinter;
    address public minterTemp;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public blacklist;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);  
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event SetPauseMint(bool pause);
    event SetOwner(address user);
    event SetTotalSupplyLimit(uint amount);
    event SetMinter(address minter);
    event SetBlacklist(address user,bool isBlacklist);
    event AcceptOwner(address user);
    event AcceptMinter(address user);
    
    constructor (/* Initializes contract with initial supply tokens to the creator of the contract */
        uint256 initialSupply,string memory tokenName,string memory tokenSymbol) public{
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = 18;                                      // Amount of decimals for display purposes
        owner = msg.sender;
        totalSupplyLimit = 21000000 * (10 ** uint256(decimals));           
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool success){/* Send coins */
        require (_to != address(0x0) && !blacklist[msg.sender]);    // Prevent transfer to 0x0 address. Use burn() instead
        require (_value >= 0) ;                                                                 
        require (balanceOf[msg.sender] >= _value) ;           // Check if the sender has enough
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ; // Check for overflows
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);               // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {/* Allow another contract to spend some tokens in your behalf */
        allowance[msg.sender][_spender] = _value;   
        emit Approval(msg.sender, _spender, _value);
        return true;    
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {/* A contract attempts to get the coins */
        require (_to != address(0x0) && !blacklist[_from]) ;                                // Prevent transfer to 0x0 address. Use burn() instead
        require (_value >= 0) ;                                                 
        require (balanceOf[_from] >= _value) ;                 // Check if the sender has enough
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ;  // Check for overflows
        require (_value <= allowance[_from][msg.sender]) ;     // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true; 
      }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value) ;            // Check if the sender has enough
        require (_value > 0) ; 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);            // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);          
        emit Transfer(msg.sender, address(0), _value);
        return true;
    } 
    
    function mintToken(uint256 _mintedAmount) public returns (bool success) {
        require(msg.sender == minter && !pauseMint && safeAdd(totalSupply,_mintedAmount) <= totalSupplyLimit);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender],_mintedAmount);
        totalSupply = safeAdd(totalSupply,_mintedAmount);
        emit Transfer(address(0x0), msg.sender, _mintedAmount);
        return true;
    }  

    function setPauseMint(bool _pause) public{   
        require (msg.sender == owner) ; 
        pauseMint = _pause;
        emit SetPauseMint(_pause);
    } 
    
    function setMinter(address _minter) public{   
        require (msg.sender == owner) ; 
        minterTemp = _minter;
        blocknumberLastAcceptMinter = block.number + 42000;
        emit SetMinter(_minter);
    } 
    
    function acceptMinter() public{   
        require (msg.sender == owner  && block.number < blocknumberLastAcceptMinter && block.number > blocknumberLastAcceptMinter - 36000) ; 
        minter = minterTemp;
        emit AcceptMinter(minterTemp);
    } 
    
    function setBlacklist(address _user,bool _isBlacklist) public{   
        require (msg.sender == owner) ; 
        blacklist[_user] = _isBlacklist;
        emit SetBlacklist(_user,_isBlacklist);
    } 

    function setOwner(address payable _add) public{
        require (msg.sender == owner && _add != address(0x0)) ;
        ownerTemp = _add ;   
        blocknumberLastAcceptOwner = block.number + 42000;
        emit SetOwner(_add);
    }
    
    function acceptOwner()public{
        require (msg.sender == ownerTemp && block.number < blocknumberLastAcceptOwner && block.number > blocknumberLastAcceptOwner - 36000) ;
        owner = ownerTemp ;
        emit AcceptOwner(owner);
    }

    function setTotalSupplyLimit(uint _amount) public{
        require (msg.sender == owner && _amount > 0) ;
        totalSupplyLimit = _amount ;  
        emit SetTotalSupplyLimit(_amount);  
    }
    
    function() external payable  {}/* can accept ether */
    
    // transfer balance to owner
    function withdrawToken(address token, uint amount) public{
      require(msg.sender == owner);
      if (token == address(0x0)) 
        owner.transfer(amount); 
      else 
        IToken(token).transfer(owner, amount);
    }
}