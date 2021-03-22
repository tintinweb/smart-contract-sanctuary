/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

//spider_time	2018/07/02 11:40:28
//token_Transactions	23944 txns
//token_price	

pragma solidity ^0.4.18;


/**
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



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
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
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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





contract WTMLToken is StandardToken, Ownable {
  uint256 constant zilla = 1 ether;

  string public name = 'WTML Token';
  string public symbol = 'WTML';
  uint public decimals = 18;
  uint256 public initialSupply = 10000 * zilla;
  bool public tradeable;

  function WTMLToken() public {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    tradeable = false;
  }

  /**
   * @dev modifier to determine if the token is tradeable
   */
  modifier isTradeable() {
    require( tradeable == true );
    _;
  }

  /**
   * @dev allow the token to be freely tradeable
   */
  function allowTrading() public onlyOwner {
    require( tradeable == false );
    tradeable = true;
  }

  /**
   * @dev allow the token to be freely tradeable
   * @param _to the address to transfer ZLA to
   * @param _value the amount of ZLA to transfer
   */
  function crowdsaleTransfer(address _to, uint256 _value) public onlyOwner returns (bool) {
    require( tradeable == false );
    return super.transfer(_to, _value);
  } 

  function transfer(address _to, uint256 _value) public isTradeable returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isTradeable returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public isTradeable returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public isTradeable returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}





/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract WTMLCrowdsale is Ownable {
  using SafeMath for uint256;

  // public events
  event StartCrowdsale();
  event FinalizeCrowdsale();
  event TokenSold(address recipient, uint eth_amount, uint zla_amount);
 
  // crowdsale constants
  uint256 constant presale_eth_to_zilla   = 1200;
  uint256 constant crowdsale_eth_to_zilla =  750;

  // our ZillaToken contract
  WTMLToken public token;

  // crowdsale token limit
  uint256 public zilla_remaining;

  // our WTML multisig vault address
  address public vault;

  // crowdsale state
  enum CrowdsaleState { Waiting, Running, Ended }
  CrowdsaleState public state = CrowdsaleState.Waiting;
  uint256 public start;
  uint256 public unlimited;
  uint256 public end;

  // participants state
  struct Participant {
    bool    whitelist;
    uint256 remaining;
  }
  mapping (address => Participant) private participants;

  /**
   * @dev constructs ZillaCrowdsale
   */
  function WTMLCrowdsale() public {
    token = new WTMLToken();
    zilla_remaining = token.totalSupply();
  }

  /**
   * @dev modifier to determine if the crowdsale has been initialized
   */
  modifier isStarted() {
    require( (state == CrowdsaleState.Running) );
    _;
  }

  /**
   * @dev modifier to determine if the crowdsale is active
   */
  modifier isRunning() {
    require( (state == CrowdsaleState.Running) && (now >= start) && (now < end) );
    _;
  }

  /**
   * @dev start the WTML Crowdsale
   * @param _start is the epoch time the crowdsale starts
   * @param _end is the epoch time the crowdsale ends
   * @param _vault is the multisig wallet the ethereum is transfered to
   */
  function startCrowdsale(uint256 _start, uint256 _unlimited, uint256 _end, address _vault) public onlyOwner {
    require(state == CrowdsaleState.Waiting);
    require(_start >= now);
    require(_unlimited > _start);
    require(_unlimited < _end);
    require(_end > _start);
    require(_vault != 0x0);

    start     = _start;
    unlimited = _unlimited;
    end       = _end;
    vault     = _vault;
    state     = CrowdsaleState.Running;
    StartCrowdsale();
  }

  /**
   * @dev Finalize the WTML Crowdsale, unsold tokens are moved to the vault account
   */
  function finalizeCrowdsale() public onlyOwner {
    require(state == CrowdsaleState.Running);
    require(end < now);
    // transfer remaining tokens to vault
    _transferTokens( vault, 0, zilla_remaining );
    // end the crowdsale
    state = CrowdsaleState.Ended;
    // allow the token to be traded
    token.allowTrading();
    FinalizeCrowdsale();
  }

  /**
   * @dev Allow owner to increase the end date of the crowdsale as long as the crowdsale is still running
   * @param _end the new end date for the crowdsale
   */
  function setEndDate(uint256 _end) public onlyOwner {
    require(state == CrowdsaleState.Running);
    require(_end > now);
    require(_end > start);
    require(_end > end);

    end = _end;
  }

  /**
   * @dev Allow owner to change the multisig wallet
   * @param _vault the new address of the multisig wallet
   */
  function setVault(address _vault) public onlyOwner {
    require(_vault != 0x0);

    vault = _vault;    
  }

  /**
   * @dev Allow owner to add to the whitelist
   * @param _addresses array of addresses to add to the whitelist
   */
  function whitelistAdd(address[] _addresses) public onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      Participant storage p = participants[ _addresses[i] ];
      p.whitelist = true;
      p.remaining = 15 ether;
    }
  }

  /**
   * @dev Allow owner to remove from the whitelist
   * @param _addresses array of addresses to remove from the whitelist
   */
  function whitelistRemove(address[] _addresses) public onlyOwner {
    for (uint i=0; i<_addresses.length; i++) {
      delete participants[ _addresses[i] ];
    }
  }

  /**
   * @dev Fallback function which buys tokens when sent ether
   */
  function() external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev Apply our fixed buy rate and verify we are not sold out.
   * @param eth the amount of ether being used to purchase tokens.
   */
  function _allocateTokens(uint256 eth) private view returns(uint256 tokens) {
    tokens = crowdsale_eth_to_zilla.mul(eth);
    require( zilla_remaining >= tokens );
  }

  /**
   * @dev Apply our fixed presale rate and verify we are not sold out.
   * @param eth the amount of ether used to purchase presale tokens.
   */
  function _allocatePresaleTokens(uint256 eth) private view returns(uint256 tokens) {
    tokens = presale_eth_to_zilla.mul(eth);
    require( zilla_remaining >= tokens );
  }

  /**
   * @dev Transfer tokens to the recipient and update our token availability.
   * @param recipient the recipient to receive tokens.
   * @param eth the amount of Ethereum spent.
   * @param wtml the amount of WTML Tokens received.
   */
  function _transferTokens(address recipient, uint256 eth, uint256 wtml) private {
    require( token.crowdsaleTransfer( recipient, wtml ) );
    zilla_remaining = zilla_remaining.sub( wtml );
    TokenSold(recipient, eth, wtml);
  }

  /**
   * @dev Allows the owner to grant presale participants their tokens.
   * @param recipient the recipient to receive tokens. 
   * @param eth the amount of ether from the presale.
   */
  function _grantPresaleTokens(address recipient, uint256 eth) private {
    uint256 tokens = _allocatePresaleTokens(eth);
    _transferTokens( recipient, eth, tokens );
  }

  /**
   * @dev Allows anyone to create tokens by depositing ether.
   * @param recipient the recipient to receive tokens. 
   */
  function buyTokens(address recipient) public isRunning payable {
    Participant storage p = participants[ recipient ];    
    require( p.whitelist );
    // check for the first session buy limits
    if( unlimited > now ) {
      require( p.remaining >= msg.value );
      p.remaining.sub( msg.value );
    }
    uint256 tokens = _allocateTokens(msg.value);
    require( vault.send(msg.value) );
    _transferTokens( recipient, msg.value, tokens );
  }

  /**
   * @dev Allows owner to transfer tokens to any address.
   * @param recipient is the address to receive tokens. 
   * @param wtml is the amount of WTML to transfer
   */
  function grantTokens(address recipient, uint256 wtml) public isStarted onlyOwner {
    require( zilla_remaining >= wtml );
    _transferTokens( recipient, 0, wtml );
  }

  /**
   * @dev Allows the owner to grant presale participants their tokens.
   * @param recipients array of recipients to receive tokens. 
   * @param eths array of ether from the presale.
   */
  function grantPresaleTokens(address[] recipients, uint256[] eths) public isStarted onlyOwner {
    require( recipients.length == eths.length );
    for (uint i=0; i<recipients.length; i++) {
      _grantPresaleTokens( recipients[i], eths[i] );
    }
  }

}