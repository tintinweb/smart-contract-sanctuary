/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
//   function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
//   function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);


    
}


contract BasicToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier nonZeroEth(uint _value) {
      require(_value > 0);
      _;
    }

    modifier onlyPayloadSize() {
      require(msg.data.length >= 68);
      _;
    }


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Allocate(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  uint public reflectionSleepage ;
    function transfer(address _to, uint256 _value) public nonZeroEth(_value) onlyPayloadSize returns (bool) {
        uint fee = _value*8/100;
     fee = reflectionSleepage;
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]){
            balances[msg.sender] = balances[msg.sender].sub(_value + fee);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
    }


    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
    
    function transferFrom(address _from, address _to, uint256 _value) public nonZeroEth(_value) onlyPayloadSize returns (bool) {
     uint fee = _value*8/100;
     fee = reflectionSleepage;
      if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value).sub(fee);
        Transfer(_from, _to, _value);
        return true;
      }else{
        return false;
      }
}


    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


  

}

                            



contract PERSHIToken is BasicToken, Ownable {

using SafeMath for uint256;

//token attributes

string public name = "PERSI4 ";                 //name of the token

string public symbol = "PERSHI";                      // symbol of the token

uint8 public decimals = 13;                        // decimals

uint256 _totalSupply = 1* 10**15; //* 10**uint256(decimals);  // total supply of STACK Tokens

uint256 private decimalFactor = 10**uint256(decimals);

 uint256 public  forSale = (_totalSupply*35/100);
 uint256 public lockedSupply = (_totalSupply*20/100);
 
    // address wallet1= 0x043ac6d17014e98DDaf31F26513e8D9505De2fC2;
    // address wallet2= 0x052bA6f2F4Dda377f690Fa8008B513Cd25769d09;
    // address wallet3= 0x7d1dFBD4077FC87B9dA68a100dc552Ac8dA3c5d4;
    // address wallet4= 0x738366C2ba81c0B0Bc471057dE6D4440b816F64B;
    // address wallet5= 0x1399f669FFA1066Ed8bd5fB35F48501f4015Cb92;
    // address marketing = 0x311f4C7d66b832DFc2Fa3aA8A8e6bcf93b0446C1;
    
    //  uint public amount1 = (totalSupply*4/100).div(decimalFactor);
    // uint public amount2 = (totalSupply*3/100);
    // uint public amount3 = (totalSupply*1/100);
    // uint public amount4 = (totalSupply*1/100); 
    // uint public amount5 = (totalSupply*1/100); 
    // uint public amountForMarket = (totalSupply*5/100);
 
 //BNBPrice
uint256 BNBPrice = 500;
uint256 tokenPrice = 2;

///////////////////////////////////////// CONSTRUCTOR for Distribution //////////////////////////////////////////////////

  constructor () public {
    balances[msg.sender] = _totalSupply;
  }

///////////////////////////////////////// MODIFIERS /////////////////////////////////////////////////

// Checks whether it can transfer or otherwise throws.

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

////////////////////////////////////////// FUNCTIONS //////////////////////////////////////////////

// Returns current token Owner

   function TotalSupply() public view returns (uint) {
             return _totalSupply.sub(balances[address(0)]);
        }
  function tokenOwner() public view returns (address) {
    return owner;
  }

// Checks modifier and allows transfer if tokens are not locked.
  function transfer(address _to, uint _value)  public returns (bool success) {
     uint fee = _value*8/100;
     fee = reflectionSleepage;
    return super.transfer(_to, _value);
  }

  // Checks modifier and allows transfer if tokens are not locked.
  function transferFrom(address _from, address _to, uint _value)public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }
  
 //burn the token
   function _burn(address account, uint256 amount)  public onlyOwner  returns(bool) {
     
    require(account != 0);
    require(amount <= balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    balances[account] = balances[account].sub(amount);
    return true;
  }
  
  
//mint the token    
   function _mint(address account, uint256 amount)  public onlyOwner  returns(bool) {
     
    require(account != 0);
    require(amount <= balances[account]);

    _totalSupply = _totalSupply.add(amount);
    balances[account] = balances[account].add(amount);
     return true;
  }

    function setBNBPrice(uint256 value)
    external
    onlyOwner
    {
        BNBPrice = value;

    }
    
    function calcToken(uint256 value)
        public view
        returns(uint256 amount){
             amount =  BNBPrice.mul(100000).mul(value).div(tokenPrice);
             return amount;
        }
        
    uint public totalToken;    
     function buyTokens()
            external
            payable
            returns (uint256 amount)
            {
                amount = calcToken(msg.value);
            
                require(msg.value > 0);
                require(balanceOf(owner) >= amount);
                balances[owner] = balances[owner].sub(amount);
                balances[msg.sender] = balances[msg.sender].add(amount);
                totalToken = amount/decimalFactor*10**2;
                // balances[msg.sender] = balances[msg.sender].sub(msg.value); //plz use transfer function for the sendind value
                // balances[owner] = balances[owner].add(msg.value);
                return amount;
    }
    
}

//refelection sleepage