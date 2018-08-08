pragma solidity ^0.4.11;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
//   event Transfer(address indexed _from, address indexed _to, uint _value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  
  // KYBER-NOTE! code changed to comply with ERC20 standard
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  //event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
  
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    // KYBER-NOTE! code changed to comply with ERC20 standard
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    //balances[_from] = balances[_from].sub(_value); // this was removed
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract TCGC is StandardToken {
    string public constant name = "TRILLION CLOUD GOLD";
    string public constant symbol = "TCGC";
    uint public constant decimals = 18;
    uint public freezeTime = now + 1 years;
    address public owner;
    mapping(address=>bool) public freezeList;
    
    uint public freezeSupply;
    uint public distributeSupply;
    uint public distributed;
    
    uint public exchangeSupply;
    uint public exchanged;
    
    uint public price ;
    uint public mintTimes;
    
    event DoMint(uint256 n,uint256 number);
    event Burn(address from, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function TCGC(address _owner){
        owner = _owner;
        price =700; 
        totalSupply=17*(10**7)*10**decimals; 
        freezeSupply = totalSupply/2;
        distributeSupply = totalSupply*2/5;
        exchangeSupply = totalSupply/10;
        balances[owner] = totalSupply; 
        Transfer(address(0x0), owner, totalSupply);
    }
    
    modifier validUser(address addr){
        require(!freezeList[addr]);
        _;
    }
    
    function addFreeze(address addr) onlyOwner returns(bool){
        require(!freezeList[addr]);
        freezeList[addr] =true;
        return true;
    }
    
    function unFreeze(address addr) onlyOwner returns(bool){
        require(freezeList[addr]);
        delete freezeList[addr];
        return true;
    }
    
    //setPrice
    function setPrice(uint _price) onlyOwner{
        require( _price > 0);
        price= _price;
    }
    
    function transfer(address _to, uint _value) validUser(msg.sender) returns (bool){
        if(msg.sender == owner && now < freezeTime){
            require(balances[owner] >_value && balances[owner] - _value >= freezeSupply);
            require (distributed + _value <= distributeSupply);
            distributed = distributed.add(_value);
            super.transfer(_to,_value);
        }else{
            super.transfer(_to,_value);
        }
    }
    
    //add num tokens which means that totalSupply will be added by num*decimals
    function mint(uint256 num) onlyOwner{
        balances[owner] = balances[owner].add(num);
        totalSupply = totalSupply.add(num);
        //add distributeSupply
        distributeSupply = distributeSupply.add(num);
        Transfer( address(0x0),msg.sender, num);
        DoMint(mintTimes++,num);
    }
    
    //burn tokens at will
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, address(0x0), _value);
        Burn(msg.sender, _value);
        return true;
    }

    //send eth to get tokens
    function() payable {
        uint tokens = price.mul(msg.value);
        require(tokens  <= balances[owner] && exchanged+tokens <= exchangeSupply);
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        exchanged =  exchanged.add(tokens);
        owner.transfer(msg.value);
        Transfer(owner, msg.sender, tokens);
    }
}