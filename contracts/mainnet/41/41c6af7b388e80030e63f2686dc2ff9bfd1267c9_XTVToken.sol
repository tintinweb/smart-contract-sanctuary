pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}/*
 * Name: Full Fill TV - XTV Network Utils Contract
 * Author: Allen Sarkisyan
 * Copyright: 2017 Full Fill TV, Inc.
 * Version: 1.0.0
*/


library XTVNetworkUtils {
  function verifyXTVSignatureAddress(bytes32 hash, bytes memory sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return (address(0));
    }

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    }

    bytes32 prefixedHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );

    // solium-disable-next-line arg-overflow
    return ecrecover(prefixedHash, v, r, s);
  }
}/*
 * Name: Full Fill TV Contract
 * Author: Allen Sarkisyan
 * Copyright: 2017 Full Fill TV, Inc.
 * Version: 1.0.0
*/




contract XTVNetworkGuard {
  mapping(address => bool) xtvNetworkEndorser;

  modifier validateSignature(
    string memory message,
    bytes32 verificationHash,
    bytes memory xtvSignature
  ) {
    bytes32 xtvVerificationHash = keccak256(abi.encodePacked(verificationHash, message));

    require(verifyXTVSignature(xtvVerificationHash, xtvSignature));
    _;
  }

  function setXTVNetworkEndorser(address _addr, bool isEndorser) public;

  function verifyXTVSignature(bytes32 hash, bytes memory sig) public view returns (bool) {
    address signerAddress = XTVNetworkUtils.verifyXTVSignatureAddress(hash, sig);

    return xtvNetworkEndorser[signerAddress];
  }
}
/*
 * Name: Full Fill TV - XTV Token Contract
 * Author: Allen Sarkisyan
 * Copyright: 2017 Full Fill TV, Inc.
 * Version: 1.0.0
*/




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
/*
 * Name: Full Fill TV Contract
 * Author: Allen Sarkisyan
 * Copyright: 2017 Full Fill TV, Inc.
 * Version: 1.0.0
*/




/*
 * Name: Full Fill TV Contract
 * Author: Allen Sarkisyan
 * Copyright: 2017 Full Fill TV, Inc.
 * Version: 1.0.0
*/


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  bool public paused = false;
  bool public mintingFinished = false;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address _owner, address spender) public view returns (uint256);
  function increaseApproval(address spender, uint addedValue) public returns (bool);
  function decreaseApproval(address spender, uint subtractedValue) public returns (bool);

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

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

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Buy(address indexed _recipient, uint _amount);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Pause();
  event Unpause();
}

contract ERC20Token is ERC20, Ownable {
  using SafeMath for uint256;

  /** ERC20 Interface Methods */
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) { return totalSupply_; }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
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
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
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
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
 
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



contract XTVToken is XTVNetworkGuard, ERC20Token {
  using SafeMath for uint256;

  string public constant name = "XTV";
  string public constant symbol = "XTV";
  uint public constant decimals = 18;

  address public fullfillTeamAddress;
  address public fullfillFounder;
  address public fullfillAdvisors;
  address public XTVNetworkContractAddress;

  bool public airdropActive;
  uint public startTime;
  uint public endTime;
  uint public XTVAirDropped;
  uint public XTVBurned;
  mapping(address => bool) public claimed;
  
  uint256 private constant TOKEN_MULTIPLIER = 1000000;
  uint256 private constant DECIMALS = 10 ** decimals;
  uint256 public constant INITIAL_SUPPLY = 500 * TOKEN_MULTIPLIER * DECIMALS;
  uint256 public constant EXPECTED_TOTAL_SUPPLY = 1000 * TOKEN_MULTIPLIER * DECIMALS;

  // 33%
  uint256 public constant ALLOC_TEAM = 330 * TOKEN_MULTIPLIER * DECIMALS;
  // 7%
  uint256 public constant ALLOC_ADVISORS = 70 * TOKEN_MULTIPLIER * DECIMALS;
  // 10%
  uint256 public constant ALLOC_FOUNDER = 100 * TOKEN_MULTIPLIER * DECIMALS;
  // 50%
  uint256 public constant ALLOC_AIRDROP = 500 * TOKEN_MULTIPLIER * DECIMALS;

  uint256 public constant AIRDROP_CLAIM_AMMOUNT = 500 * DECIMALS;

  modifier isAirdropActive() {
    require(airdropActive);
    _;
  }

  modifier canClaimTokens() {
    uint256 remainingSupply = balances[address(0)];

    require(!claimed[msg.sender] && remainingSupply > AIRDROP_CLAIM_AMMOUNT);
    _;
  }

  constructor(
    address _fullfillTeam,
    address _fullfillFounder,
    address _fullfillAdvisors
  ) public {
    owner = msg.sender;
    fullfillTeamAddress = _fullfillTeam;
    fullfillFounder = _fullfillFounder;
    fullfillAdvisors = _fullfillAdvisors;

    airdropActive = true;
    startTime = block.timestamp;
    endTime = startTime + 365 days;

    balances[_fullfillTeam] = ALLOC_TEAM;
    balances[_fullfillFounder] = ALLOC_FOUNDER;
    balances[_fullfillAdvisors] = ALLOC_ADVISORS;

    balances[address(0)] = ALLOC_AIRDROP;

    totalSupply_ = EXPECTED_TOTAL_SUPPLY;

    emit Transfer(address(this), address(0), ALLOC_AIRDROP);
  }

  function setXTVNetworkEndorser(address _addr, bool isEndorser) public onlyOwner {
    xtvNetworkEndorser[_addr] = isEndorser;
  }

  // @dev 500 XTV Tokens per claimant
  function claim(
    string memory token,
    bytes32 verificationHash,
    bytes memory xtvSignature
  ) 
    public
    isAirdropActive
    canClaimTokens
    validateSignature(token, verificationHash, xtvSignature)
    returns (uint256)
  {
    claimed[msg.sender] = true;

    balances[address(0)] = balances[address(0)].sub(AIRDROP_CLAIM_AMMOUNT);
    balances[msg.sender] = balances[msg.sender].add(AIRDROP_CLAIM_AMMOUNT);

    XTVAirDropped = XTVAirDropped.add(AIRDROP_CLAIM_AMMOUNT);

    emit Transfer(address(0), msg.sender, AIRDROP_CLAIM_AMMOUNT);

    return balances[msg.sender];
  }

  // @dev Burns tokens at address 0x00
  function burnTokens() public onlyOwner {
    require(block.timestamp > endTime);

    uint256 remaining = balances[address(0)];

    airdropActive = false;

    XTVBurned = remaining;
  }

  function setXTVNetworkContractAddress(address addr) public onlyOwner {
    XTVNetworkContractAddress = addr;
  }

  function setXTVTokenAirdropStatus(bool _status) public onlyOwner {
    airdropActive = _status;
  }
}