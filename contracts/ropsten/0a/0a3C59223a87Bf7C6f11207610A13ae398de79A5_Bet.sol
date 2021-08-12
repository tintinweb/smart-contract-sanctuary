/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


 
 
 contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
interface ERC20Interface {
    
    function gettotalSupply() external returns (uint256 totalSupply);
 
   
    function getBalance(address _owner) external returns (uint256 balance);
 
    
    function transfer(address _to, uint256 _value)external returns (bool success);
 
   
    function transferFrom(address _from, address _to, uint256 _value)external returns (bool success);
 
    
    function approve(address _spender, uint256 _value)external returns (bool success);
 
   
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
 
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
   
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
 
 
 

 
contract Bet is SafeMath,ERC20Interface {
    string private symbol;
    string private  name;
    uint8 private decimals;
    uint private totalSupply;
   
    




struct _Bet{
string opisanie;
    address owner;
    address player;
    bool accepted;
    uint value;
}


     mapping(address => uint) balances;
     mapping(address => _Bet)  bets;
     mapping(address => mapping (address => uint256)) allowed;
     

     event BetPlaced(address _owner, address player,address _judge, uint tokens);
      event BetAccepted(address _owner, address player,address _judge, uint tokens);

     constructor() public {
         symbol = "example";
        name = "example Token";
        decimals = 18;
        totalSupply=1000000000;
    }
   
    function gettotalSupply() public view override returns (uint){
        return totalSupply;
         
    }
    function transfer(address _to, uint256 _value)public override returns (bool success){
        if(balances[msg.sender] >= _value ){
        balances[msg.sender]=safeSub(balances[msg.sender],_value);
        balances[_to]=safeAdd(balances[_to],_value);
        emit Transfer(msg.sender, _to, _value);
            return true;
        }else {return false;}
           
        
    }
     function transferFrom(address _from, address _to, uint256 _value)public override returns (bool success){
         if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value){
             balances[_from]=safeSub(balances[_from],_value);
            allowed[_from][msg.sender] =safeSub(allowed[_from][msg.sender],_value);
            balances[_to]=safeAdd(balances[_to],_value);
            emit Transfer(_from, _to, _value);
            return true;
            
         }else {return false;}
     }
     function approve(address _spender, uint256 _value)public override returns (bool success){
         allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
        
         return true;
     }
     function allowance(address _owner, address _spender)public view override returns (uint256 remaining){
         return allowed[_owner][_spender];
     }
     function getCoins()public payable{
         uint tokens;
      
           tokens = msg.value / 100000000000;
           totalSupply = safeSub(totalSupply, tokens);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
     }
     
     function getBalance(address a)public view override returns(uint){
         return balances[a];
     }
      function PlaceBet(address _owner,address _player,address _judge,uint tokens,string memory _opisanie)public {
           bets[_judge].owner=_owner;
           bets[_judge].player=_player;
           bets[_judge].value=tokens;
           bets[_judge].opisanie=_opisanie;
           bets[_judge].accepted=false;

          balances[_owner]=safeSub(balances[_owner],tokens);
          totalSupply=safeAdd(totalSupply, tokens);
          emit BetPlaced(_owner, _player, _judge, tokens);
          
      }
      function getBet(address _judge)public view returns(string memory){
          return bets[_judge].opisanie;
      }
      function acceptBet()public payable{
          if(bets[msg.sender].accepted==false){
                  bets[msg.sender].accepted=true;
                  balances[bets[msg.sender].player]=safeSub(balances[bets[msg.sender].player],bets[msg.sender].value);
                  totalSupply=safeAdd(totalSupply, bets[msg.sender].value);
                  
                   uint tokens = msg.value / 100000000000;
                   totalSupply = safeSub(totalSupply, tokens);
                   balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            
                  emit BetAccepted(bets[msg.sender].owner, bets[msg.sender].player, msg.sender, bets[msg.sender].value);}
      }
       function approveBet()public payable  {
           if(bets[msg.sender].accepted==true){
               uint256 commission = ((bets[msg.sender].value*2)*10)/100;
               uint256 winamount=(bets[msg.sender].value*2)-commission;
               totalSupply = safeSub(totalSupply, bets[msg.sender].value*2);
               balances[msg.sender]=safeAdd(balances[msg.sender],commission);
           balances[bets[msg.sender].owner]=safeAdd(balances[bets[msg.sender].owner],winamount);
               delete bets[msg.sender];
               
                uint tokens = msg.value / 100000000000;
                   totalSupply = safeSub(totalSupply, tokens);
                   balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
               
           }
      }

        function disapproveBet()public  payable{
             if(bets[msg.sender].accepted==true){
                uint commission = ((bets[msg.sender].value*2)*10)/100;
               uint winamount=(bets[msg.sender].value*2)-commission;
                  totalSupply = safeSub(totalSupply, bets[msg.sender].value*2);
                  balances[msg.sender]=safeAdd(balances[msg.sender],commission);
           balances[bets[msg.sender].player]=safeAdd(balances[bets[msg.sender].player],winamount);
                 delete bets[msg.sender];
                 
                  uint tokens = msg.value / 100000000000;
                   totalSupply = safeSub(totalSupply, tokens);
                   balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
             }
      }
      
    fallback () external payable {
        
        uint tokens;
      
           tokens = msg.value / 100000000000;
           totalSupply = safeSub(totalSupply, tokens);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        
        
    }
      
}