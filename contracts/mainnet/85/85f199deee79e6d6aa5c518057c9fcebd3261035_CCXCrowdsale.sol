pragma solidity ^0.4.17;



library SafeMath {

  /**
  * Multiplication
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
  	if (a == 0) {
      return 0;
  	}
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * Division
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); 
    uint256 c = a / b;
    return c;
  }

  /**
  * Soustraction
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * Addition
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // ERROR if not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * Amount of token burn
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract CCXToken is  BurnableToken{
    string public constant name = "CCX";
    string public constant symbol = "CCX";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    function CCXToken() public
    {
        totalSupply = 40000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
    
    
}

contract Ownable {
  address public owner;

 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract CCXCrowdsale is Ownable{

    using SafeMath for uint256;

    enum Periods {NotStarted, PreSale,EndPreSale,ThirdWeek,SecondWeek,FirstWeek,Finished}
    Periods public period;


    CCXToken public token;
    address public wallet;
    uint256 public constant ratePresale = 1500;
    uint256 public constant rateFirstWeek = 1100;
    uint256 public constant rateSecondWeek = 1200;
    uint256 public constant rateThirdWeek = 1300;
    uint256 public constant rate = 1000;
    uint256 public balance;
    uint256 public tokens;

    mapping(address => uint256) internal balances;

     function CCXCrowdsale(address _token,address _wallet) public{
        token = CCXToken(_token);
           wallet = _wallet;
        period = Periods.NotStarted;
    }

   
    
    

    function nextState() onlyOwner public{
       
        if(period == Periods.NotStarted){
            period = Periods.PreSale;
        }
        else if(period == Periods.PreSale){
            period = Periods.EndPreSale;
        }
        else if(period == Periods.EndPreSale){
            period = Periods.ThirdWeek;
        }
        else if(period == Periods.ThirdWeek){
            period = Periods.SecondWeek;
        }
        else if(period == Periods.SecondWeek){
            period = Periods.FirstWeek;
        }
    }

    function buyTokens() internal
    {
        
          uint256   amount = msg.value;
          bool success= false;
      if(uint(period) == 1){
      		    tokens = amount.mul(ratePresale); 	
       }else if(uint(period) == 3){
      		    tokens = amount.mul(rateThirdWeek);
       }
         else if(uint(period) == 4){    
      		    tokens = amount.mul(rateSecondWeek);
       }
         else if(uint(period) == 5){     
      		    tokens = amount.mul(rateFirstWeek);
       }
       else{
         tokens = amount.mul(rate);
    }
        success = token.transfer(msg.sender, tokens);
        balance = balance.add(tokens);
        require(success);
        wallet.transfer(msg.value);
  
       }


    function () public payable{
            require(msg.sender != address(0));
        require(msg.value > 0);
        buyTokens();
    }
  
   function burningTokens() public onlyOwner{
        if(period == Periods.Finished){
            token.burn(tokens);
        }
    }
}

   contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


}