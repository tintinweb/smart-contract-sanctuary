pragma solidity ^0.4.23;

/**xxp
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
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

/**
 * @title ERC20Basic
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20Basic {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  // store tokens
  mapping(address => uint256) balances;
  // uint256 public totalSupply;

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
    *batch transfer token for a list of specified addresses
    * @param _toList The list of addresses to transfer to.
    * @param _tokensList The list of amount to be transferred.
    */
  function batchTransfer(address[] _toList, uint256[] _tokensList) public  returns (bool) {
      require(_toList.length <= 100);
      require(_toList.length == _tokensList.length);
      
      uint256 sum = 0;
      for (uint32 index = 0; index < _tokensList.length; index++) {
          sum = sum.add(_tokensList[index]);
      }

      // if the sender doenst have enough balance then stop
      require (balances[msg.sender] >= sum);
        
      for (uint32 i = 0; i < _toList.length; i++) {
          transfer(_toList[i],_tokensList[i]);
      }
      return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is StandardToken,Ownable {
  using SafeMath for uint256;

  event AddToVestMap(address vestcount);
  event DelFromVestMap(address vestcount);

  event Released(address vestcount,uint256 amount);
  event Revoked(address vestcount);

  struct tokenToVest{
      bool  exist;
      uint256  start;
      uint256  cliff;
      uint256  duration;
      uint256  torelease;
      uint256  released;
  }

  //key is the account to vest
  mapping (address=>tokenToVest) vestToMap;


  /**
   * @dev Add one account to the vest Map
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts 
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _torelease  delc count to release
   */
  function addToVestMap(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _torelease
  ) public onlyOwner{
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    require(_start > block.timestamp);
    require(!vestToMap[_beneficiary].exist);

    vestToMap[_beneficiary] = tokenToVest(true,_start,_start.add(_cliff),_duration,
        _torelease,uint256(0));

    emit AddToVestMap(_beneficiary);
  }


  /**
   * @dev del One account to the vest Map
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   */
  function delFromVestMap(
    address _beneficiary
  ) public onlyOwner{
    require(_beneficiary != address(0));
    require(vestToMap[_beneficiary].exist);

    delete vestToMap[_beneficiary];

    emit DelFromVestMap(_beneficiary);
  }



  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release(address _beneficiary) public {

    tokenToVest storage value = vestToMap[_beneficiary];
    require(value.exist);
    uint256 unreleased = releasableAmount(_beneficiary);
    require(unreleased > 0);
    require(unreleased + value.released <= value.torelease);


    vestToMap[_beneficiary].released = vestToMap[_beneficiary].released.add(unreleased);

    transfer(_beneficiary, unreleased);

    emit Released(_beneficiary,unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   */
  function releasableAmount(address _beneficiary) public view returns (uint256) {
    return vestedAmount(_beneficiary).sub(vestToMap[_beneficiary].released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount(address _beneficiary) public view returns (uint256) {

    tokenToVest storage value = vestToMap[_beneficiary];
    //uint256 currentBalance = balanceOf(_beneficiary);
    uint256 totalBalance = value.torelease;

    if (block.timestamp < value.cliff) {
      return 0;
    } else if (block.timestamp >= value.start.add(value.duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(value.start)).div(value.duration);
    }
  }
}

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is TokenVesting, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  
  function batchTransfer(address[] _toList, uint256[] _tokensList) public whenNotPaused returns (bool) {
      return super.batchTransfer(_toList, _tokensList);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function release(address _beneficiary) public whenNotPaused{
    super.release(_beneficiary);
  }
}

/*
 * @title DELCToken
 */
contract DELCToken is BurnableToken, MintableToken, PausableToken {
  // Public variables of the token
  string public name;
  string public symbol;
  // decimals is the strongly suggested default, avoid changing it
  uint8 public decimals;

  constructor() public {
    name = "DELC Relation Person Token";
    symbol = "DELC";
    decimals = 18;
    totalSupply = 10000000000 * 10 ** uint256(decimals);

    // Allocate initial balance to the owner
    balances[msg.sender] = totalSupply;
    
    emit Transfer(address(0), msg.sender, totalSupply);
    
  }

  // transfer balance to owner
  //function withdrawEther() onlyOwner public {
  //    owner.transfer(this.balance);
  //}

  // can accept ether
  //function() payable public {
  //}
}