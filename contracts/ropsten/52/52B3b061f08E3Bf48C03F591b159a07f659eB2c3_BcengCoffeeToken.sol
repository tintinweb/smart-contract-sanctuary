pragma solidity ^0.4.11;

contract BcengCoffeeToken{
    
    using SafeMath for uint256;
    //_totalSupply = 100000 * 10^18
    uint256 public _totalSupply = 100000000000000000000000;
    //numarul maxim de token-uri ce vor circula
    string public constant symbol = "BCT";
    string public constant name = "Bceng Coffee Token";
    uint8 public constant decimals = 18;
    
    address public owner;
    
    //mapping este un tip de data care face o asociere intre doua tipuri de date
    //mapping-ul <<balances>> este o structura prin care accesam balanta fiecarei adrese
    mapping (address => uint256) balances;
    //mapping-ul <<allowed>> este folosit pentru stabilirea <<alocatiilor>>
    //a anumita adresa a1 poate imputernici o alta adresa a2 sa cheltuiasca suma x din contul adresei a1
    mapping (address => mapping(address => uint256)) allowed;
    //se apeleaza la construirea contractului si doar atunci 
    function BcengCoffeeToken(){
        //initializam owner-ul token-ului
        owner = msg.sender;
        //dam toate token-urile detinatorului
        balances[owner] = _totalSupply;
    }
    
    
    function totalSupply() constant returns (uint256 totalSupply){
        return _totalSupply;
    }
    //returneaza balanta unei anumite adrese
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    //transfera _value token-uri de la msg.sender la _to si returneaza true daca transferul a avut succes
    function transfer(address _to, uint256 _value) returns (bool success){
        require(
            balances[msg.sender] >= _value
            && _value > 0
            );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    //transfera de la adresa _from la adresa _to si returneaza true daca tranzactia a avut succes
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    //senderul ii aproba lui _spender sa cheltuiasca _value din contul sau
    function approve(address _spender, uint256 _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    //returneaza <<alocatia>> lui _spender data de _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}