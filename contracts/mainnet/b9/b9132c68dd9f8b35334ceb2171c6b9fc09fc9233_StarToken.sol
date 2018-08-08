pragma solidity ^0.4.11;


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


 
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) returns (bool) {

   
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  

  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

contract StarToken is StandardToken,Ownable {

  string public constant name = "StarLight";
  string public constant symbol = "STAR";
  uint8 public constant decimals = 18;
  
  address public address1 = 0x08294159dE662f0Bd810FeaB94237cf3A7bB2A3D;
  address public address2 = 0xAed27d4ecCD7C0a0bd548383DEC89031b7bBcf3E;
  address public address3 = 0x41ba7eED9be2450961eBFD7C9Fb715cae077f1dC;
  address public address4 = 0xb9cdb4CDC8f9A931063cA30BcDE8b210D3BA80a3;
  address public address5 = 0x5aBF2CA9e7F5F1895c6FBEcF5668f164797eDc5D;
 uint256 public weiRaised;



  uint public  price;
    

 
  function StarToken() {
    
    price = 1136;
  }
  
  function () payable {
      
      buy();
  }
  
  function buy() payable {

    require(msg.value >= 1 ether);
    



      uint256 weiAmount = msg.value;


        uint256 toto = totalSupply.div(1 ether);

      if ( toto> 3000000) {

          price = 558;
        }

        if (toto > 9000000) {

          price = 277;
        }

        if (toto > 23400000) {

            price = 136;
        }

        if (toto > 104400000) {

            price = 0;
        }

      // calculate token amount to be created
      uint256 tokens = weiAmount.mul(price);

    // update state
      weiRaised = weiRaised.add(weiAmount);


      totalSupply = totalSupply.add(tokens);
      balances[msg.sender] = balances[msg.sender].add(tokens);


      address1.transfer(weiAmount.div(5));
      address2.transfer(weiAmount.div(5));
      address3.transfer(weiAmount.div(5));
      address4.transfer(weiAmount.div(5));
      address5.transfer(weiAmount.div(5));

  }


  function setPrice(uint256 newPrice){

        price = newPrice;

  }
  


  function withdraw() onlyOwner
    {
        owner.transfer(this.balance);
    }



}