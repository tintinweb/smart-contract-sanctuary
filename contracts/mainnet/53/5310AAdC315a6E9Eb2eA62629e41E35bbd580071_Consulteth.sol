pragma solidity ^0.4.0;

 /* 
 This Consulteum token contract is based on the ERC20 token contract. Additional 
 functionality has been integrated: 
 * the contract Lockable, which is used as a parent of the Token contract 
 * the function mintTokens(), which makes use of the currentSwapRate() and safeToAdd() helpers 
 * the function disableTokenSwapLock() 
 */ 
 
 
 contract Lockable {  
     uint public creationTime;
     bool public tokenSwapLock; 
     
     address public dev;
 
     // This modifier should prevent tokens transfers while the tokenswap 
     // is still ongoing 
     modifier isTokenSwapOn { 
         if (tokenSwapLock) throw; 
        _;
     }
     
  // This modifier should prevent ICO from being launched by an attacker
     
    modifier onlyDev{ 
       if (msg.sender != dev) throw; 
      _;
   }

     function Lockable() { 
       dev = msg.sender; 
     } 
 } 
 

 

 contract ERC20 { 
     function totalSupply() constant returns (uint); 
     function balanceOf(address who) constant returns (uint); 
     function allowance(address owner, address spender) constant returns (uint); 
 

     function transfer(address to, uint value) returns (bool ok); 
     function transferFrom(address from, address to, uint value) returns (bool ok); 
     function approve(address spender, uint value) returns (bool ok); 
 
     event Transfer(address indexed from, address indexed to, uint value); 
     event Approval(address indexed owner, address indexed spender, uint value); 
 } 
 
 
 contract Consulteth is ERC20, Lockable { 
 

   mapping( address => uint ) _balances; 
   mapping( address => mapping( address => uint ) ) _approvals; 
   
   uint public foundationAsset;
   uint public CTX_Cap;
   uint _supply; 
   
   address public wallet_Mini_Address;
   address public wallet_Address;
   
   uint public factorial_ICO;
   
   event TokenMint(address newTokenHolder, uint amountOfTokens); 
   event TokenSwapOver(); 
 
   modifier onlyFromMiniWallet { 
       if (msg.sender != wallet_Mini_Address) throw;
      _;
   }
   
   modifier onlyFromWallet { 
       if (msg.sender != wallet_Address) throw; 
      _;
   } 
 
  
 
   function Consulteth(uint preMine, uint cap_CTX) { 
     _balances[msg.sender] = preMine; 
     foundationAsset = preMine;
     CTX_Cap = cap_CTX;
     
     _supply += preMine;  
      
   } 
 
 
   function totalSupply() constant returns (uint supply) { 
     return _supply; 
   } 


 
   function balanceOf( address who ) constant returns (uint value) { 
     return _balances[who]; 
   } 
 
 
   function allowance(address owner, address spender) constant returns (uint _allowance) { 
     return _approvals[owner][spender]; 
   } 
 
 
   // A helper to notify if overflow occurs 
   function safeToAdd(uint a, uint b) internal returns (bool) { 
     return (a + b >= a && a + b >= b); 
   } 
 
 
   function transfer(address to, uint value) isTokenSwapOn returns (bool ok) { 
 
 
     if( _balances[msg.sender] < value ) { 
         throw; 
     } 
     if( !safeToAdd(_balances[to], value) ) { 
         throw; 
     } 
 
 
     _balances[msg.sender] -= value; 
     _balances[to] += value; 
     Transfer( msg.sender, to, value ); 
     return true; 
   } 
 
 
   function transferFrom(address from, address to, uint value) isTokenSwapOn returns (bool ok) { 
     // if you don&#39;t have enough balance, throw 
     if( _balances[from] < value ) { 
         throw; 
     } 
     // if you don&#39;t have approval, throw 
     if( _approvals[from][msg.sender] < value ) { 
         throw; 
     } 
     if( !safeToAdd(_balances[to], value) ) { 
         throw; 
     } 
     // transfer and return true 
     _approvals[from][msg.sender] -= value; 
     _balances[from] -= value; 
     _balances[to] += value; 
     Transfer( from, to, value ); 
     return true; 
   } 
 
   function approve(address spender, uint value) 
     isTokenSwapOn 
     returns (bool ok) { 
     _approvals[msg.sender][spender] = value; 
     Approval( msg.sender, spender, value ); 
     return true; 
   } 
 
 
   function kickStartMiniICO(address ico_Mini_Wallet) onlyDev  { 
    if (ico_Mini_Wallet == address(0x0)) throw; 
         // Allow setting only once 
    if (wallet_Mini_Address != address(0x0)) throw; 
         wallet_Mini_Address = ico_Mini_Wallet;
         
         creationTime = now; 
         tokenSwapLock = true;  
   }
 
   // The function preICOSwapRate() returns the current exchange rate 
   // between consulteum tokens and Ether during the pre-ICO token swap period 
   
   function preICOSwapRate() constant returns(uint) { 
       if (creationTime + 1 weeks > now) { 
           return 1000; 
       } 
       else if (creationTime + 3 weeks > now) { 
           return 850; 
       } 
        
       else { 
           return 0; 
       } 
   } 
   
 
   
   // The function mintMiniICOTokens is only usable by the chosen wallet 
   // contract to mint a number of tokens proportional to the 
   // amount of ether sent to the wallet contract. The function 
   // can only be called during the tokenswap period 
   
function mintMiniICOTokens(address newTokenHolder, uint etherAmount) onlyFromMiniWallet
    external { 
 
 
         uint tokensAmount = preICOSwapRate() * etherAmount; 
         
         if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw; 
         if(!safeToAdd(_supply,tokensAmount)) throw; 
 
 
         _balances[newTokenHolder] += tokensAmount; 
         _supply += tokensAmount; 
 
 
         TokenMint(newTokenHolder, tokensAmount); 
   }
   
// The function disableMiniSwapLock() is called by the wallet 
   // contract once the token swap has reached its end conditions 

   function disableMiniSwapLock() onlyFromMiniWallet
     external { 
         tokenSwapLock = false; 
         TokenSwapOver(); 
   }    
  


function kickStartICO(address ico_Wallet, uint mint_Factorial) onlyDev  { 
    if (ico_Wallet == address(0x0)) throw; 
         // Allow setting only once 
    if (wallet_Address != address(0x0)) throw; 
         
         wallet_Address = ico_Wallet;
         factorial_ICO = mint_Factorial;
         
         creationTime = now; 
         tokenSwapLock = true;  
   }
 
  
   function ICOSwapRate() constant returns(uint) { 
       if (creationTime + 1 weeks > now) { 
           return factorial_ICO; 
       } 
       else if (creationTime + 2 weeks > now) { 
           return (factorial_ICO - 30); 
       } 
       else if (creationTime + 4 weeks > now) { 
           return (factorial_ICO - 70); 
       } 
       else { 
           return 0; 
       } 
   } 
 

 
   // The function mintICOTokens is only usable by the chosen wallet 
   // contract to mint a number of tokens proportional to the 
   // amount of ether sent to the wallet contract. The function 
   // can only be called during the tokenswap period 
   function mintICOTokens(address newTokenHolder, uint etherAmount) onlyFromWallet
    external { 
 
 
         uint tokensAmount = ICOSwapRate() * etherAmount; 

         if((_supply + tokensAmount) > CTX_Cap) throw;
         
         if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw; 
         if(!safeToAdd(_supply,tokensAmount)) throw; 
 
 
         _balances[newTokenHolder] += tokensAmount; 
         _supply += tokensAmount; 
 
 
         TokenMint(newTokenHolder, tokensAmount); 
   } 
 
 
   // The function disableICOSwapLock() is called by the wallet 
   // contract once the token swap has reached its end conditions 
   function disableICOSwapLock() onlyFromWallet
     external { 
         tokenSwapLock = false; 
         TokenSwapOver(); 
   } 
 }