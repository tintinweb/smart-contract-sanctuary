pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a && c>=b);
    return c;
  }
}

// Interface for burning tokens
contract Burnable {
  // @dev Destroys tokens for an account
  // @param account Account whose tokens are destroyed
  // @param value Amount of tokens to destroy
  function _burnTokens(address account, uint value) internal;
  event Burned(address account, uint value);
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

  event Error(string _t);

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
    Inspired on 
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 * by https://www.gohichain.com/
 */

/*
    It can be listed more than one Agent. An agent is a kind of privileged user
    A non released resource must reserve special ops to Agents
    A released resource can be full operated by non Agents too.
    
*/
//Define interface for Manage + release a resource normal operation after an external trigger
contract Releasable is Ownable {

  address public releaseAgent;
  bool public released = false;
  mapping (address => bool) public Agents;

  event ReleaseAgent(address previous, address newAgent);

  //Set the contract that can call release and make the resource operative
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    releaseAgent = addr;
    emit ReleaseAgent(releaseAgent, addr);
  }

  // Owner can allow a particular address (e.g. a crowdsale contract) to be Agent to manage the resource
  function setAgent(address addr) onlyOwner inReleaseState(false) public returns(bool){
    Agents[addr] = true;
    emit Agent(addr,true);
    return true;
  }

  // Owner forbids a particular address (e.g. a crowdsale contract) to be Agent to manage the resource
  function resetAgent(address addr) onlyOwner inReleaseState(false) public returns(bool){
    Agents[addr] = false;
    emit Agent(addr,false);
    return true;
  }
    event Agent(address addr, bool status);

  function amIAgent() public view returns (bool) {
    return Agents[msg.sender];
  }

  function isAgent(address addr) public view /*onlyOwner */ returns(bool) {
    return Agents[addr];
  }

  //From now the resource is free
  function releaseOperation() public onlyReleaseAgent {
        released = true;
		emit Released();
  }
  event Released();

  // Limit resource operative until the release
  modifier canOperate(address sender) {
    require(released || Agents[sender]);
    _;
  }

  //The function can be called only before or after the tokens have been released
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  //The function can be called only by a whitelisted release agent.
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }
}



contract StandardToken is Burnable, Pausable {
    using SafeMath for uint;

    uint private total_supply;
    uint public decimals;

    // This creates an array with all balances
    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    //Constructor
    constructor(uint supply, uint token_decimals, address token_retriever) public {
        decimals                    = token_decimals;
        total_supply                = supply * uint(10) ** decimals ; // 10 ** 9,  1000 millions
        balances[token_retriever]   = total_supply;                   // Give to the creator all initial tokens
    }

    function totalSupply() public view returns (uint) {
        return total_supply;
    }

    //Public interface for balances
    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }

    //Public interface for allowances
    function allowance(address account, address spender) public view returns (uint remaining) {
        return allowed[account][spender];
    }

    //Internal transfer, only can be called by this contract
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                        //Burn is an specific op
        require(balances[_from] >= _value);        //Enough ?
        require(balances[_to] + _value >= balances[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];

        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public whenNotPaused returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub( _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _holder, address _spender, uint _value) internal {
        require(_value <= total_supply);
        require(_value >= 0);
        allowed[_holder][_spender] = _value;
        emit Approval(_holder, _spender,_value);
    }
    function approve(address _spender, uint _value) public returns (bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function safeApprove(address _spender, uint _currentValue, uint _value)  public returns (bool success) {
        require(allowed[msg.sender][_spender] == _currentValue);
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens
     */
    function _burnTokens(address from, uint _value) internal {
        require(balances[from] >= _value);                    // Check if the sender has enough
        balances[from] = balances[from].sub(_value);    // Subtract from the sender
        total_supply = total_supply.sub(_value);                    // Updates totalSupply
        emit  Burned(from, _value);
    }

    function burn(uint _value) public whenNotPaused returns (bool success) {
        _burnTokens(msg.sender,_value);
        return true;
    }
}



/**
 * Originally from https://github.com/TokenMarketNet/ico
 * Modified by https://www.coinfabrik.com/
 */


//Define interface for releasing the token transfer after a successful crowdsale.
contract ReleasableToken is Releasable, StandardToken {

  //We restrict transfer by overriding it
  function transfer(address to, uint value) public canOperate(msg.sender) returns (bool success) {
   return super.transfer(to, value);
  }

  //We restrict transferFrom by overriding it
  //"from" must be an agent before released
  function transferFrom(address from, address to, uint value) public canOperate(from) returns (bool success) {
    return super.transferFrom(from, to, value);
  }

  //We restrict burn by overriding it
  function burn(uint value) public canOperate(msg.sender) returns (bool success) {
    return super.burn(value);
  }
}




contract Token is ReleasableToken {

    string public name = "PROTOAL";
    string public symbol = "pAL";

    //    Constructor
    constructor(uint supply, uint token_decimals, address token_retriever) StandardToken(supply, token_decimals, token_retriever) public { }
    
}