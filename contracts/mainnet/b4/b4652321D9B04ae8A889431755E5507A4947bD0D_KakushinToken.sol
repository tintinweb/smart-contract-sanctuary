pragma solidity 0.4.21;

/// @title SafeMath
/// @dev Math operations with safety checks that throw on error
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

/// @title Kakushin Solidity Token
/// @author PriusLabs
contract KakushinToken {
   
   using SafeMath for uint256 ;
   
    string public name ;
    string public symbol ;
    uint8 public decimals = 18;
   
   
    uint256 public totalSupply = 2400000000;
    
    address public constant companyWallet = 0xd9240Ac690F7764fC53e151863b5f79105c50E3d ;
    
    address public constant founder1Wallet = 0xcE13BC6f7168B309584b70Ae996ec6168c296427 ;    
    
    address public constant founder2Wallet = 0xa520044662761ad83b8cfA8Cd63c156F64104B9E ;    
    
    address public constant founder3Wallet = 0xF9e2d35b4C23446929330EA327895D754E17784D ;    
    
    address public constant founder4Wallet = 0xcc3870Ec7Cc86Cd3f267f17c5d78467d49B9FA2b ;   
    
    address public constant owner1 = 0x9c27c3465a7dE3E653417234A60a51C51C9E978e;
	
	address public constant owner2 = 0x36F7f9cD70b52f4b2b8Ca861fAa4A44D8C1E4Be3;   //Address of Admin Wallet---- //
    
    uint startDate;
    
    uint endDate = 1530403199 ;
    
    

  
  
    mapping (address => uint256) public balances;

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Function that implements SafeMath for exponent operations
    /// @param a Value to be raised to the power of @param b
    /// @return uint256 result of the operation
    function safeExp(uint256 a, uint256 b) private pure returns(uint256){
        if(a == 0) { return 0; }
        uint256 c = a;
        uint i;
        if(b == 0) {
            c = 1;
        }
        else if(b < 0) {
            for(i = 0; i >= b; i--) {
                c = c.div(a);
            }
        }
        else {
            for(i = 1; i < b; i++) {
                c = c.mul(a);
            }
        }
        return c;
    }
    
   /// @dev constructor function for contract, initializes the totalSupply for the owners, sets name and symbol for smart contract token
    function KakushinToken() public {
        totalSupply = totalSupply.mul(safeExp(10, uint256(decimals)));  // Update total supply with the decimal amount
                      // Give the creator all initial tokens
        name = "KAKUSHIN";                                   // Set the name for display purposes
        symbol = "KKN";                               // Set the symbol for display purposes
        balances[owner1] = uint256(59).mul(totalSupply.div(100));
        balances[companyWallet] = uint256(28).mul(totalSupply.div(100));  
        balances[founder1Wallet] = uint256(62400000).mul(safeExp(10, uint256(decimals)));
        balances[founder2Wallet] = uint256(62400000).mul(safeExp(10, uint256(decimals)));
        balances[founder3Wallet] = uint256(124800000).mul(safeExp(10, uint256(decimals)));
        balances[founder4Wallet] = uint256(62400000).mul(safeExp(10, uint256(decimals)));
        startDate = now;
        
    }
    
    /// @notice send `value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to , uint value) public returns (bool success){
        
        require(_to != 0x0);
        
        require(balances[msg.sender] >= value);
        
        startDate = now ;
        
       
        if(msg.sender == owner1 || msg.sender == owner2){
            
            balances[_to] = balances[_to].add(value); 
            balances[msg.sender] = balances[msg.sender].sub(value);
            
        }else if(startDate > endDate){
                  
            balances[_to] = balances[_to].add(value) ; 
            balances[msg.sender] = balances[msg.sender].sub(value) ; 
                  
        }
              
        emit Transfer(msg.sender, _to, value);
              
        return true ;
        
    }
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    /// @notice Checks sale is greater than end date
    /// @return Boolean result of the checking
    function checkSale() public view returns(bool success) {
        
        
        if(startDate > endDate){
            return true ;
        } else {
            return false;
        }
        
    }

  
    
}