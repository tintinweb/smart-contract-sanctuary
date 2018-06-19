pragma solidity ^0.4.20;
 
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


contract AGASCrowdsale is Ownable {
    using SafeMath for uint;

    event Print(string _message, address _msgSender);

    address public multisig = 0x0A9465529653815E61E5187517392d9C10d0f9dd; 
    address public addressOfERC20Tocken = 0xa7A1F840CF741B96F5A80D5856ae02F0f474251f;
    ERC20 public token;
    
    
    uint public startPreICO = 1521435600; //Mon, 19 Mar 2018 05:00:00 GMT 
    uint public startICO = 1523854800; //Mon, 16 Apr 2018 05:00:00 GMT
    uint public startProICO = 1526274000; //Mon, 14 May 2018 05:00:00 GMT
    
    uint public tokenDec = 1000000000000000000; //18
    
    uint public PreICOHardcap = 2000000*tokenDec;
    uint public ICOHardcap = 6000000*tokenDec;
    uint public ProICOHardcap = 8000000*tokenDec;
    uint public tokensSold = 0;
    
    uint public bonusAmount = 200000*tokenDec;
    uint public givenBonus = 0;
    
    uint public PreICOPrice = 1000000000000000; // 0.001 ETH 
    uint public ICOPrice = 2000000000000000; // 0.002 ETH
    uint public ProICOPrice = 4000000000000000; // 0.004 ETH
    
    
    
    function AGASCrowdsale(){
        owner = msg.sender;
        token = ERC20(addressOfERC20Tocken);
    }    
    
    
   
    function tokenBalance() constant returns (uint256) {
        return token.balanceOf(address(this));
    } 
    
   
    function setAddressOfERC20Tocken(address _addressOfERC20Tocken) onlyOwner {
        addressOfERC20Tocken =  _addressOfERC20Tocken;
        token = ERC20(addressOfERC20Tocken);
        
    }
    

    function transferToken(address _to, uint _value) onlyOwner returns (bool) {
        return token.transfer(_to,  _value);
    }
    
    function() payable {
        doPurchase();
    }



    function doPurchase() payable {
       
        require(now >= startPreICO);
        
       
        require(msg.value >= 100000000000000); 
    
        uint sum = msg.value;
        uint rest = 0;
        uint tokensAmount = 0;
        
        
      
        if(now >= startPreICO && now < startICO){
           
            require(PreICOHardcap > tokensSold);
            
           
            tokensAmount = sum.mul(tokenDec).div(PreICOPrice);
            
            
            if(tokensAmount.add(tokensSold) > PreICOHardcap) {
              
                tokensAmount = PreICOHardcap.sub(tokensSold);
               
                rest = sum.sub(tokensAmount.mul(PreICOPrice).div(tokenDec));
            }
                
          
        } else if(now >= startICO && now < startProICO){
            
            require(ICOHardcap > tokensSold);
            
            
            tokensAmount = sum.mul(tokenDec).div(ICOPrice);
            
             
            if(tokensAmount.add(tokensSold) > ICOHardcap) {
                
                tokensAmount = ICOHardcap.sub(tokensSold);
              
                rest = sum.sub(tokensAmount.mul(ICOPrice).div(tokenDec));
            }
        
        
        } else {
            
            require(ProICOHardcap > tokensSold);
            
            tokensAmount = sum.mul(tokenDec).div(ProICOPrice);
            
             
            if(tokensAmount.add(tokensSold) > ProICOHardcap) {
              
                tokensAmount = ProICOHardcap.sub(tokensSold);
              
                rest = sum.sub(tokensAmount.mul(ProICOPrice).div(tokenDec));
            }
            
        }         
        
      
        tokensSold = tokensSold.add(tokensAmount);
        


        if(givenBonus < bonusAmount && tokensAmount >= 500*tokenDec){
            
            uint bonus = 0;
            
            
            if(tokensAmount >= 500*tokenDec && tokensAmount <1000*tokenDec)
            { 
               
                bonus = 20*tokenDec;
            
            } else if ( tokensAmount >= 1000*tokenDec && tokensAmount <5000*tokenDec ) {
              
                bonus = 100*tokenDec;
            
            } else if ( tokensAmount >= 5000*tokenDec && tokensAmount <10000*tokenDec ) {
               
                bonus = 600*tokenDec;
            
            } else if ( tokensAmount >= 10000*tokenDec ) {
            
                bonus = 1500*tokenDec;
            }

            bonus = (bonus < (bonusAmount - givenBonus) ) ? bonus : (bonusAmount - givenBonus);
            
     
            givenBonus = givenBonus.add(bonus);
       
            tokensAmount = tokensAmount.add(bonus);
            
        } 

        require(tokenBalance() > tokensAmount);
        
        require(token.transfer(msg.sender, tokensAmount));
       
        if(rest==0){

            multisig.transfer(msg.value);
        }else{

            multisig.transfer(msg.value.sub(rest)); 

            msg.sender.transfer(rest);
        }
             
    }

}