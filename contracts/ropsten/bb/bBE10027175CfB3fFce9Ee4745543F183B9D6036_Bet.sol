/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

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
        totalSupply=1000000;
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
     function getCoins(address a)public{
         totalSupply = safeSub(totalSupply, 100);
         balances[a]=safeAdd(balances[a], 100);
     }
     
     function getBalance(address a)public view override returns(uint){
         return balances[a];
     }
      function PlaceBet(address _owner,address _player,address _judge,uint tokens,string memory _opisanie)public payable{
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
      function acceptBet(address _judge)public payable{
          if(bets[_judge].accepted==false){
                  bets[_judge].accepted=true;
                  balances[bets[_judge].player]=safeSub(balances[bets[_judge].player],bets[_judge].value);
                  totalSupply=safeAdd(totalSupply, bets[_judge].value);
                  emit BetAccepted(bets[_judge].owner, bets[_judge].player, _judge, bets[_judge].value);}
      }
       function approveBet(address _judge)public  {
           if(bets[_judge].accepted==true){
               uint256 commission = ((bets[_judge].value*2)*10)/100;
               uint256 winamount=(bets[_judge].value*2)-commission;
               totalSupply = safeSub(totalSupply, bets[_judge].value*2);
               balances[_judge]=safeAdd(balances[_judge],commission);
           balances[bets[_judge].owner]=safeAdd(balances[bets[_judge].owner],winamount);
               delete bets[_judge];
               
           }
      }

        function disapproveBet(address _judge)public  {
             if(bets[_judge].accepted==true){
                uint commission = ((bets[_judge].value*2)*10)/100;
               uint winamount=(bets[_judge].value*2)-commission;
                  totalSupply = safeSub(totalSupply, bets[_judge].value*2);
                  balances[_judge]=safeAdd(balances[_judge],commission);
           balances[bets[_judge].player]=safeAdd(balances[bets[_judge].player],winamount);
                 delete bets[_judge];
             }
      }
      
    fallback () external payable {
        
        uint tokens;
      
           tokens = msg.value / 100000000;
           totalSupply = safeSub(totalSupply, tokens);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        
        
    }
      
}