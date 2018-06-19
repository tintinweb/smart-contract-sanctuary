pragma solidity ^0.4.11;

interface IERC20 {
 

    function totalSupply() public constant returns (uint256 totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _owner, uint256 _value) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transferFrom(address _owner, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
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
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}


/**
 * @title Standard ERC20 token
 *
*/
contract KeplerCoin is IERC20 {
    
    
    using SafeMath for uint256;
    
    
    uint256 public constant  _totalSupply = 30000000000000000000000000 ;
    string public constant symbol = &quot;KPL&quot;;
    string public constant name = &quot;Kepler Coin&quot;;
    uint8 public constant decimals = 18;
    
    mapping(address =&gt; uint256) balances;
    mapping(address =&gt; mapping(address =&gt; uint256)) allowed;
    
    // rate of our token
    uint256 public RATE = 5000;
    
    // address of the person who created it
    address public owner;
    
    bool public isActive = true;
    

    
    //paybale function to create transaction
    
    function () payable {
        createTokens();
    }

    function KeplerCoin(){
    
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;


    } 
    
    function changeRate(uint256 _rate){
    
        require(msg.sender == owner);

        RATE = _rate;
    }
    
    
    function toggleActive(bool _isActive){
        
        require(msg.sender == owner);
        
        isActive = _isActive;

    }
    
    
   
 
    
    function createTokens() payable{
        require(msg.value &gt; 0
        &amp;&amp; isActive
        );
        
        uint256 tokens = msg.value*RATE;
        
        require(balances[owner] &gt;= tokens);

        balances[owner] = balances[owner].sub(tokens);

        balances[msg.sender] = balances[msg.sender].add(tokens);

        owner.transfer(msg.value);
    }
    
    function totalSupply() public constant returns (uint256 totalSupply){
        return _totalSupply;
    }
    
     function balanceOf(address _owner) public constant returns (uint256 balance){
         return balances[_owner];
     }
     
    function transfer(address _owner, uint256 _value) public returns (bool success){
        
        require(
            balances[msg.sender]&gt;= _value 
            &amp;&amp; _value &gt;0
            );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_owner] = balances[_owner].add(_value);
        Transfer(msg.sender , _owner  , _value);
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(
            allowed[_from][msg.sender] &gt;= _value
            &amp;&amp; balances[_from] &gt;= _value
            &amp;&amp; _value &gt;0
            );
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from , _to , _value);
        return true;
        
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender , _spender , _value);
        return true;
        
    }
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    

 

}