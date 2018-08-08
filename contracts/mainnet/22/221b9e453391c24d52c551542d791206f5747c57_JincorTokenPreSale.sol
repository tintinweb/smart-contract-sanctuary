pragma solidity ^0.4.15;


  /**
   * @title SafeMath
   * @dev Math operations with safety checks that throw on error
   */
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


  /**
   * @title Ownable
   * @dev The Ownable contract has an owner address, and provides basic authorization control
   * functions, this simplifies the implementation of "user permissions".
   */
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
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

  }


  /*
   * Haltable
   *
   * Abstract contract that allows children to implement an
   * emergency stop mechanism. Differs from Pausable by requiring a state.
   *
   *
   * Originally envisioned in FirstBlood ICO contract.
   */
  contract Haltable is Ownable {
    bool public halted = false;

    modifier inNormalState {
      require(!halted);
      _;
    }

    modifier inEmergencyState {
      require(halted);
      _;
    }

    // called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner inNormalState {
      halted = true;
    }

    // called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner inEmergencyState {
      halted = false;
    }
  }

  /**
   * @title ERC20Basic
   * @dev Simpler version of ERC20 interface
   * @dev see https://github.com/ethereum/EIPs/issues/179
   */
  contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }


  /**
   * @title ERC20 interface
   * @dev see https://github.com/ethereum/EIPs/issues/20
   */
  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

  /**
   * @title Basic token
   * @dev Basic version of StandardToken, with no allowances.
   */
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

  /**
   * @title Standard ERC20 token
   *
   * @dev Implementation of the basic standard token.
   * @dev https://github.com/ethereum/EIPs/issues/20
   * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
   */
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

      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
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

  /**
   * @title Burnable
   *
   * @dev Standard ERC20 token
   */
  contract Burnable is StandardToken {
    using SafeMath for uint;

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) returns (bool success) {
      require(balances[msg.sender] >= _value);                // Check if the sender has enough
      balances[msg.sender] = balances[msg.sender].sub(_value);// Subtract from the sender
      totalSupply = totalSupply.sub(_value);                                  // Updates totalSupply
      Burn(msg.sender, _value);
      return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
      require(balances[_from] >= _value);               // Check if the sender has enough
      require(_value <= allowed[_from][msg.sender]);    // Check allowance
      balances[_from] = balances[_from].sub(_value);    // Subtract from the sender
      totalSupply = totalSupply.sub(_value);            // Updates totalSupply
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Burn(_from, _value);
      return true;
    }

    function transfer(address _to, uint _value) returns (bool success) {
      require(_to != 0x0); //use burn

      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      require(_to != 0x0); //use burn

      return super.transferFrom(_from, _to, _value);
    }
  }


  /**
   * @title JincorToken
   *
   * @dev Burnable Ownable ERC20 token
   */
  contract JincorToken is Burnable, Ownable {

    string public name = "Jincor Token";
    string public symbol = "JCR";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 35000000 * 1 ether;

    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
    mapping (address => bool) public transferAgents;

    /**
     * Limit token transfer until the crowdsale is over.
     *
     */
    modifier canTransfer(address _sender) {
      require(transferAgents[_sender] || released);
      _;
    }

    /** The function can be called only before or after the tokens have been releasesd */
    modifier inReleaseState(bool releaseState) {
      require(releaseState == released);
      _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
      require(msg.sender == releaseAgent);
      _;
    }


    /**
     * @dev Contructor that gives msg.sender all of existing tokens.
     */
    function JincorToken() {
      totalSupply = INITIAL_SUPPLY;
      balances[msg.sender] = INITIAL_SUPPLY;
    }


    /**
     * Set the contract that can call release and make the token transferable.
     *
     * Design choice. Allow reset the release agent to fix fat finger mistakes.
     */
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

      // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
      releaseAgent = addr;
    }

    function release() onlyReleaseAgent inReleaseState(false) public {
      released = true;
    }

    /**
     * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
     */
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
      transferAgents[addr] = state;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
      // Call Burnable.transfer()
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
      // Call Burnable.transferForm()
      return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) onlyOwner returns (bool success) {
      return super.burn(_value);
    }

    function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
      return super.burnFrom(_from, _value);
    }
  }



  contract JincorTokenPreSale is Ownable, Haltable {
    using SafeMath for uint;

    string public name = "Jincor Token PreSale";

    JincorToken public token;

    address public beneficiary;

    uint public hardCap;

    uint public softCap;

    uint public price;

    uint public purchaseLimit;

    uint public collected = 0;

    uint public tokensSold = 0;

    uint public investorCount = 0;

    uint public weiRefunded = 0;

    uint public startBlock;

    uint public endBlock;

    bool public softCapReached = false;

    bool public crowdsaleFinished = false;

    mapping (address => bool) refunded;

    event GoalReached(uint amountRaised);

    event SoftCapReached(uint softCap);

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    event Refunded(address indexed holder, uint256 amount);

    modifier preSaleActive() {
      require(block.number >= startBlock && block.number < endBlock);
      _;
    }

    modifier preSaleEnded() {
      require(block.number >= endBlock);
      _;
    }

    function JincorTokenPreSale(
    uint _hardCapUSD,
    uint _softCapUSD,
    address _token,
    address _beneficiary,
    uint _totalTokens,
    uint _priceETH,
    uint _purchaseLimitUSD,

    uint _startBlock,
    uint _endBlock
    ) {
      hardCap = _hardCapUSD.mul(1 ether).div(_priceETH);
      softCap = _softCapUSD.mul(1 ether).div(_priceETH);
      price = _totalTokens.mul(1 ether).div(hardCap);

      purchaseLimit = _purchaseLimitUSD.mul(1 ether).div(_priceETH).mul(price);
      token = JincorToken(_token);
      beneficiary = _beneficiary;

      startBlock = _startBlock;
      endBlock = _endBlock;
    }

    function() payable {
      require(msg.value >= 0.1 * 1 ether);
      doPurchase(msg.sender);
    }

    function refund() external preSaleEnded inNormalState {
      require(softCapReached == false);
      require(refunded[msg.sender] == false);

      uint balance = token.balanceOf(msg.sender);
      require(balance > 0);

      uint refund = balance.div(price);
      if (refund > this.balance) {
        refund = this.balance;
      }

      assert(msg.sender.send(refund));
      refunded[msg.sender] = true;
      weiRefunded = weiRefunded.add(refund);
      Refunded(msg.sender, refund);
    }

    function withdraw() onlyOwner {
      require(softCapReached);
      assert(beneficiary.send(collected));
      token.transfer(beneficiary, token.balanceOf(this));
      crowdsaleFinished = true;
    }

    function doPurchase(address _owner) private preSaleActive inNormalState {

      require(!crowdsaleFinished);
      require(collected.add(msg.value) <= hardCap);

      if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
        softCapReached = true;
        SoftCapReached(softCap);
      }
      uint tokens = msg.value * price;
      require(token.balanceOf(msg.sender).add(tokens) <= purchaseLimit);

      if (token.balanceOf(msg.sender) == 0) investorCount++;

      collected = collected.add(msg.value);

      token.transfer(msg.sender, tokens);

      tokensSold = tokensSold.add(tokens);

      NewContribution(_owner, tokens, msg.value);

      if (collected == hardCap) {
        GoalReached(hardCap);
      }
    }
  }