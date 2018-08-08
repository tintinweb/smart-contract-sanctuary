pragma solidity ^0.4.21 ;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract OG is Ownable , StandardToken {
////////////////////////////////
  string public constant name = "OnlyGame Token";
  string public constant symbol = "OG";
  uint8 public constant decimals = 18;
  uint256 public constant totalsum =  1000000000 * 10 ** uint256(decimals);
  ////////////////////////////////
  address public crowdSaleAddress;
  bool public locked;
////////////////////////////////
  uint256 public __price = (1 ether / 20000  )   ;
////////////////////////////////
  function OG() public {
      crowdSaleAddress = msg.sender;
       unlock(); 
      totalSupply = totalsum;  // Update total supply with the decimal amount * 10 ** uint256(decimals)
      balances[msg.sender] = totalSupply; 
  }
////////////////////////////////
  // allow burning of tokens only by authorized users 
  modifier onlyAuthorized() {
      if (msg.sender != owner && msg.sender != crowdSaleAddress) 
          revert();
      _;
  }
////////////////////////////////
  function priceof() public view returns(uint256) {
    return __price;
  }
////////////////////////////////
  function updateCrowdsaleAddress(address _crowdSaleAddress) public onlyOwner() {
    require(_crowdSaleAddress != address(0));
    crowdSaleAddress = _crowdSaleAddress; 
  }
////////////////////////////////
  function updatePrice(uint256 price_) public onlyOwner() {
    require( price_ > 0);
    __price = price_; 
  }
////////////////////////////////
  function unlock() public onlyAuthorized {
      locked = false;
  }
  function lock() public onlyAuthorized {
      locked = true;
  }
////////////////////////////////
  function toEthers(uint256 tokens) public view returns(uint256) {
    return tokens.mul(__price) / ( 10 ** uint256(decimals));
  }
  function fromEthers(uint256 ethers) public view returns(uint256) {
    return ethers.div(__price) * 10 ** uint256(decimals);
  }
////////////////////////////////
  function returnTokens(address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        balances[crowdSaleAddress] = balances[crowdSaleAddress].add(_value);
        emit  Transfer(_member, crowdSaleAddress, _value);
        return true;
  }
////////////////////////////////
  function buyOwn(address recipient, uint256 ethers) public payable onlyOwner returns(bool) {
    return mint(recipient, fromEthers(ethers));
  }
  function mint(address to, uint256 amount) public onlyOwner returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply = totalSupply.add(amount);
    balances[to] = balances[to].add(amount );
    emit Transfer(address(0), to, amount);
    return true;
  }
  function burn(address from, uint256 amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount );
    totalSupply = totalSupply.sub(amount );
    emit Transfer(from, address(0), amount );
    return true;
  }
  function sell(address recipient, uint256 tokens) public payable onlyOwner returns(bool) {
    burn(recipient, tokens);
    recipient.transfer(toEthers(tokens));
  }
////////////////////////////////
  function mintbuy(address to, uint256 amount) public  returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply = totalSupply.add(amount );
    balances[to] = balances[to].add(amount );
    emit Transfer(address(0), to, amount );
    return true;
  }
   function buy(address recipient) public payable returns(bool) {
    return mintbuy(recipient, fromEthers(msg.value));
  }

////////////////////////////////
  function() public payable {
    buy(msg.sender);
  }

 
}