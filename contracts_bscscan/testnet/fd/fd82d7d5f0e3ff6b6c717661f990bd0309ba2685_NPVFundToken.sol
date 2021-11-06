/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic is Pausable {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  address public NPVAddress;
  uint256 noEther = 0;

  string public name = "NPV Fund Token";
  uint8 public decimals = 18;
  string public symbol = "NPV";

  address public enterWallet = 0xf0EF10870308013903bd6Dc8f86E7a7EAF1a86Ab;
  address public investWallet = 0x1cBEF3676Ef0f4D7efB786D2Bda33e5E22b6A313;
  address public exitWallet = 0xf0EF10870308013903bd6Dc8f86E7a7EAF1a86Ab;
  uint256 public priceEthPerToken = 33333;
  
  uint256 public depositCommission = 95;
  uint256 public investCommission = 70;
  uint256 public withdrawCommission = 97;
  
  event MoreData(uint256 ethAmount, uint256 price);

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (_to == NPVAddress) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      totalSupply = totalSupply.sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(msg.sender, NPVAddress, _value);
      MoreData(weiAmount, priceEthPerToken);
      return true;

    } else {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      MoreData(0, priceEthPerToken);
      return true;
    }
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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (_to == NPVAddress) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(_from, NPVAddress, _value);
      MoreData(weiAmount, priceEthPerToken);
      return true;

    } else {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        MoreData(0, priceEthPerToken);
        return true;
    }
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

contract NPVFundToken is StandardToken {
    
  function () payable whenNotPaused {
    
    uint256 amount = msg.value;
    address investor = msg.sender;
    
    uint256 tokens = amount.mul(depositCommission).mul(priceEthPerToken).div(10000);
    
    totalSupply = totalSupply.add(tokens);
    balances[investor] = balances[investor].add(tokens);

    investWallet.transfer(amount.div(100).mul(investCommission));
    enterWallet.transfer(amount.div(100).mul(uint256(100).sub(depositCommission)));
    
    Transfer(NPVAddress, investor, tokens);
    MoreData(amount, priceEthPerToken);
    
  }

  function setNPVAddress(address _address) onlyOwner {
    NPVAddress = _address;
  }

  function addEther() payable onlyOwner {}

  function deleteInvestorTokens(address investor, uint256 tokens) onlyOwner {
    require(tokens <= balances[investor]);

    balances[investor] = balances[investor].sub(tokens);
    totalSupply = totalSupply.sub(tokens);
    Transfer(investor, NPVAddress, tokens);
    MoreData(0, priceEthPerToken);
  }

  function setNewPrice(uint256 _ethPerToken) onlyOwner {
    priceEthPerToken = _ethPerToken;
  }

  function getWei(uint256 weiAmount) onlyOwner {
    owner.transfer(weiAmount);
  }

  function airdrop(address[] _array1, uint256[] _array2) onlyOwner {
    address[] memory arrayAddress = _array1;
    uint256[] memory arrayAmount = _array2;
    uint256 arrayLength = arrayAddress.length.sub(1);
    uint256 i = 0;
     
    while (i <= arrayLength) {
        totalSupply = totalSupply.add(arrayAmount[i]);
        balances[arrayAddress[i]] = balances[arrayAddress[i]].add(arrayAmount[i]);
        Transfer(NPVAddress, arrayAddress[i], arrayAmount[i]);
        MoreData(0, priceEthPerToken);
        i = i.add(1);
    }  
  }
  
  function setNewDepositCommission(uint256 _newDepositCommission) onlyOwner {
    depositCommission = _newDepositCommission;
  }
  
  function setNewInvestCommission(uint256 _newInvestCommission) onlyOwner {
    investCommission = _newInvestCommission;
  }
  
  function setNewWithdrawCommission(uint256 _newWithdrawCommission) onlyOwner {
    withdrawCommission = _newWithdrawCommission;
  }
  
  function newEnterWallet(address _enterWallet) onlyOwner {
    enterWallet = _enterWallet;
  }
  
  function newInvestWallet(address _investWallet) onlyOwner {
    investWallet = _investWallet;
  }
  
  function newExitWallet(address _exitWallet) onlyOwner {
    exitWallet = _exitWallet;
  }
  
}