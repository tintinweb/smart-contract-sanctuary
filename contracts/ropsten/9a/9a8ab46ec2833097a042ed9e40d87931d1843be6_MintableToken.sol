/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

pragma solidity ^0.4.23;



library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
  
    return a / b;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply ;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) ;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn (address indexed from, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value) ;
  event Approval( address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;


  mapping(address => uint256) balances;
  
  function transfer(address _to, uint256 _value) {
    require (balances [msg.sender] >= _value) ;
    require (balances[_to] + _value >= balances[_to]);
    

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    
  }


     function burn (uint256 _value){
         require ( balances[msg.sender] >= _value);
         balances [msg.sender] =balances [msg.sender].sub(_value);
         totalSupply = totalSupply.sub(_value);
         Burn(msg.sender , _value);
         
     }
      
     function balanceOf(address _owner) constant returns (uint256 balance){
         return balances[_owner] ;
     }
  

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  
  function transferFrom(address _from ,address _to, uint256 _value){
      var _allowance =allowed [_from][msg.sender];
      balances[_to] =    balances[_to].add(_value);
      balances[_from] =  balances[_from].sub(_value);
      allowed [_from][msg.sender] =_allowance .sub(_value);
  
  }

  function approve(address _spender, uint256 _value) {
    require (!((_value != 0)&& (allowed[msg.sender][_spender ] != 0)));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    
  }


  function allowance( address _owner, address _spender) constant returns (uint256 remaining)
   
  {
    return allowed[_owner][_spender];
  }


 
}

contract Ownable {
    address public owner;
    
    function Ownable (){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)){
            owner = newOwner ;
        }
    }
    
}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  string public name ="JSK Token Ftan";
   string public symbole ="JSK";
   uint256 public decimals =18 ;

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }
    
    function MintableToken (){
        mint(msg.sender,1000000000000000000000000);
        
    }


   
  function mint( address _to, uint256 _amount) onlyOwner canMint returns (bool)
  
  {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0, _to, _amount);
    return true;
  }


  function finishMinting() onlyOwner  returns (bool) {
    mintingFinished = true;
    MintFinished();
    
    return true;
  }
}

contract swapToken is MintableToken {
    MintableToken basicToken ;
    
    mapping(address => bool) migrated;
    function swapToken (MintableToken _basicToken ){
        basicToken =_basicToken ;
        totalSupply = 1000000000000000000000000;
        
    }
    
    function migration (address _owner) internal {
        if(!migrated[_owner]){
            balances[_owner]= balances[_owner].add(basicToken.balanceOf(_owner));
            migrated[_owner]=true;
        }
    }
    
    function  transfer(address _to, uint256 _value) {
        migration(msg.sender);
        require (balances[msg.sender] >= _value);
        require (balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to]=balances[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        
    }

    function burn (uint256 _value){
        migration(msg.sender);
        require (balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        
        Burn(msg.sender,_value);
        
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        migration(_owner);
        return balances[_owner];
        
    }
    
    function transferFrom(address _from, address _to,uint256 _value){
        var _allowance=allowed[_from][msg.sender];
        migration(msg.sender);
        balances[_to]=balances[_to].add(_value);
        balances[_from]=balances[_from].sub(_value);
        allowed[_from][msg.sender]=_allowance.sub(_value);
        Transfer(_from,_to,_value);
    }
    
    function approve(address _spender,uint256 _value){
         migration(msg.sender);
         require (!((_value!=0)&& (allowed[msg.sender][_spender]!=0)));
        allowed[msg.sender][_spender]= _value;
        Approval(msg.sender,_spender,_value);
    }
    











}

contract Crowdsale is Ownable{
    using SafeMath for uint256;
    
    MintableToken public token ;
    uint256 public deadline;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public tokensSold;
    
    event TokenPurchase(address indexed purchaser,address  indexed beneficiary,uint256 value,uint256 amount);
    
    function Crowdsale(MintableToken tokenContract,uint256 durationInWeek,uint256 _rate,address _wallet){
        require(_rate >0);
        require(_wallet !=0x0);
        token = tokenContract;
        deadline = now + durationInWeek * 1 weeks;
        rate = _rate;
        wallet = _wallet;
    }
    function setNewTokenOwner(address newOwner) onlyOwner{
        token.transferOwnership(newOwner);
    }
    
    function createTokenContract() internal returns (MintableToken){
        return new MintableToken();
    }
    
    function ()  payable {
        buyTokens(msg.sender);
        
    }
    function buyTokens(address beneficiary) payable{
        require (beneficiary !=0x0);
        require(validPurchase());
        require(weiRaised <1000000000000000000000000);
        uint256 weiAmount = msg.value;
        uint256 updatedweiRaised = weiRaised .add(weiAmount);
        uint256 tokens = weiAmount .mul(rate);
        require (tokens <= token.balanceOf(this));
        weiRaised  = updatedweiRaised ;
        token.transfer(beneficiary , tokens);
        tokensSold = tokensSold.add(tokens);
        TokenPurchase (msg.sender,beneficiary,weiAmount,tokens);
        
        
        forwardFunds();
        
        
        
    }
    function forwardFunds() internal {
        wallet.transfer(msg.value);
        
        
    }
    
    function validPurchase()internal constant returns (bool){
        uint256 current =block.number;
        bool  withinPeriod =now <= deadline ;
        bool  nonZeroPurchase = msg.value !=0 ;
        return withinPeriod && nonZeroPurchase;
    }
      function hasEnded() public constant returns(bool){
          
          return(now > deadline);
      }
      function tokenResend()onlyOwner{
          token.transfer(token, token.balanceOf(this));
          
      }
}