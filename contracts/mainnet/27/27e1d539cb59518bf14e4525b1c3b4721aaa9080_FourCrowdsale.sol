pragma solidity ^0.4.17;

// File: contracts/helpers/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @dev The Constructor sets the original owner of the contract to the
  * sender account.
  */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
  * @dev Throws if called by any other account other than owner.
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

// File: contracts/helpers/SafeMath.sol

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

// File: contracts/token/ERC20Interface.sol

contract ERC20Interface {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);

}

// File: contracts/token/BaseToken.sol

contract BaseToken is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  /**
  * @dev Obtain total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);

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
    require(_spender != address(0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    return true;
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

    Transfer(_from, _to, _value);

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
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

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
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
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

// File: contracts/token/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is BaseToken, Ownable {

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
    require(_to != address(0));

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

// File: contracts/token/CappedToken.sol

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: contracts/helpers/Pausable.sol

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

// File: contracts/token/PausableToken.sol

/**
 * @title Pausable token
 * @dev BaseToken modified with pausable transfers.
 **/
contract PausableToken is BaseToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts/token/SignedTransferToken.sol

/**
* @title SignedTransferToken
* @dev The SignedTransferToken enables collection of fees for token transfers
* in native token currency. User will provide a signature that allows the third
* party to settle the transaction in his name and collect fee for provided
* serivce.
*/
contract SignedTransferToken is BaseToken {

  event TransferPreSigned(
    address indexed from,
    address indexed to,
    address indexed settler,
    uint256 value,
    uint256 fee
  );

  event TransferPreSignedMany(
    address indexed from,
    address indexed settler,
    uint256 value,
    uint256 fee
  );


  // Mapping of already executed settlements for a given address
  mapping(address => mapping(bytes32 => bool)) executedSettlements;

  /**
  * @dev Will settle a pre-signed transfer
  */
  function transferPreSigned(address _from,
                             address _to,
                             uint256 _value,
                             uint256 _fee,
                             uint256 _nonce,
                             uint8 _v,
                             bytes32 _r,
                             bytes32 _s) public returns (bool) {
    uint256 total = _value.add(_fee);
    bytes32 calcHash = calculateHash(_from, _to, _value, _fee, _nonce);

    require(_to != address(0));
    require(isValidSignature(_from, calcHash, _v, _r, _s));
    require(balances[_from] >= total);
    require(!executedSettlements[_from][calcHash]);

    executedSettlements[_from][calcHash] = true;

    // Move tokens
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);

    // Move fee
    balances[_from] = balances[_from].sub(_fee);
    balances[msg.sender] = balances[msg.sender].add(_fee);
    Transfer(_from, msg.sender, _fee);

    TransferPreSigned(_from, _to, msg.sender, _value, _fee);

    return true;
  }

  /**
  * @dev Settle multiple transactions in a single call. Please note that
  * should a single one fail the full state will be reverted. Your client
  * implementation should always first check for balances, correct signatures
  * and any other conditions that might result in failed transaction.
  */
  function transferPreSignedBulk(address[] _from,
                                 address[] _to,
                                 uint256[] _values,
                                 uint256[] _fees,
                                 uint256[] _nonces,
                                 uint8[] _v,
                                 bytes32[] _r,
                                 bytes32[] _s) public returns (bool) {
    // Make sure all the arrays are of the same length
    require(_from.length == _to.length &&
            _to.length ==_values.length &&
            _values.length == _fees.length &&
            _fees.length == _nonces.length &&
            _nonces.length == _v.length &&
            _v.length == _r.length &&
            _r.length == _s.length);

    for(uint i; i < _from.length; i++) {
      transferPreSigned(_from[i],
                        _to[i],
                        _values[i],
                        _fees[i],
                        _nonces[i],
                        _v[i],
                        _r[i],
                        _s[i]);
    }

    return true;
  }


  function transferPreSignedMany(address _from,
                                 address[] _tos,
                                 uint256[] _values,
                                 uint256 _fee,
                                 uint256 _nonce,
                                 uint8 _v,
                                 bytes32 _r,
                                 bytes32 _s) public returns (bool) {
   require(_tos.length == _values.length);
   uint256 total = getTotal(_tos, _values, _fee);

   bytes32 calcHash = calculateManyHash(_from, _tos, _values, _fee, _nonce);

   require(isValidSignature(_from, calcHash, _v, _r, _s));
   require(balances[_from] >= total);
   require(!executedSettlements[_from][calcHash]);

   executedSettlements[_from][calcHash] = true;

   // transfer to each recipient and take fee at the end
   for(uint i; i < _tos.length; i++) {
     // Move tokens
     balances[_from] = balances[_from].sub(_values[i]);
     balances[_tos[i]] = balances[_tos[i]].add(_values[i]);
     Transfer(_from, _tos[i], _values[i]);
   }

   // Move fee
   balances[_from] = balances[_from].sub(_fee);
   balances[msg.sender] = balances[msg.sender].add(_fee);
   Transfer(_from, msg.sender, _fee);

   TransferPreSignedMany(_from, msg.sender, total, _fee);

   return true;
  }

  function getTotal(address[] _tos, uint256[] _values, uint256 _fee) private view returns (uint256)  {
    uint256 total = _fee;

    for(uint i; i < _tos.length; i++) {
      total = total.add(_values[i]); // sum of all the values + fee
      require(_tos[i] != address(0)); // check that the recipient is a valid address
    }

    return total;
  }

  /**
  * @dev Calculates transfer hash for transferPreSignedMany
  */
  function calculateManyHash(address _from, address[] _tos, uint256[] _values, uint256 _fee, uint256 _nonce) public view returns (bytes32) {
    return keccak256(uint256(1), address(this), _from, _tos, _values, _fee, _nonce);
  }

  /**
  * @dev Calculates transfer hash.
  */
  function calculateHash(address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce) public view returns (bytes32) {
    return keccak256(uint256(0), address(this), _from, _to, _value, _fee, _nonce);
  }

  /**
  * @dev Validates the signature
  */
  function isValidSignature(address _signer, bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (bool) {
    return _signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", _hash),
            _v,
            _r,
            _s
        );
  }

  /**
  * @dev Allows you to check whether a certain transaction has been already
  * settled or not.
  */
  function isTransactionAlreadySettled(address _from, bytes32 _calcHash) public view returns (bool) {
    return executedSettlements[_from][_calcHash];
  }

}

// File: contracts/token/PausableSignedTransferToken.sol

contract PausableSignedTransferToken is SignedTransferToken, PausableToken {

  function transferPreSigned(address _from,
                             address _to,
                             uint256 _value,
                             uint256 _fee,
                             uint256 _nonce,
                             uint8 _v,
                             bytes32 _r,
                             bytes32 _s) public whenNotPaused returns (bool) {
    return super.transferPreSigned(_from, _to, _value, _fee, _nonce, _v, _r, _s);
  }

  function transferPreSignedBulk(address[] _from,
                                 address[] _to,
                                 uint256[] _values,
                                 uint256[] _fees,
                                 uint256[] _nonces,
                                 uint8[] _v,
                                 bytes32[] _r,
                                 bytes32[] _s) public whenNotPaused returns (bool) {
    return super.transferPreSignedBulk(_from, _to, _values, _fees, _nonces, _v, _r, _s);
  }

  function transferPreSignedMany(address _from,
                                 address[] _tos,
                                 uint256[] _values,
                                 uint256 _fee,
                                 uint256 _nonce,
                                 uint8 _v,
                                 bytes32 _r,
                                 bytes32 _s) public whenNotPaused returns (bool) {
    return super.transferPreSignedMany(_from, _tos, _values, _fee, _nonce, _v, _r, _s);
  }
}

// File: contracts/FourToken.sol

contract FourToken is CappedToken, PausableSignedTransferToken  {
  string public name = &#39;The 4th Pillar Token&#39;;
  string public symbol = &#39;FOUR&#39;;
  uint256 public decimals = 18;

  // Max supply of 400 million
  uint256 public maxSupply = 400000000 * 10**decimals;

  function FourToken()
    CappedToken(maxSupply) public {
      paused = true;
  }

  // @dev Recover any mistakenly sent ERC20 tokens to the Token address
  function recoverERC20Tokens(address _erc20, uint256 _amount) public onlyOwner {
    ERC20Interface(_erc20).transfer(msg.sender, _amount);
  }

}

// File: contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale {
  using SafeMath for uint256;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param tokens amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);

  // The token being sold
  MintableToken public token;

  // start and end timestamps in UNIX.
  uint256 public startTime;
  uint256 public endTime;

  // how many tokens does a buyer get per wei
  uint256 public rate;

  // wallet where funds are forwarded
  address public wallet;

  // amount of raised money in wei
  uint256 public weiRaised;
  // amount of sold tokens
  uint256 public tokensSold;


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = MintableToken(_token);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokens);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

}

// File: contracts/crowdsale/FinalizableCrowdsale.sol

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  event Finalized();

  bool public isFinalized = false;

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

// File: contracts/crowdsale/TokenCappedCrowdsale.sol

contract TokenCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public tokenCap;

  function TokenCappedCrowdsale(uint256 _tokenCap) public {
    require(_tokenCap > 0);
    tokenCap = _tokenCap;
  }

  function isCapReached() public view returns (bool) {
    return tokensSold >= tokenCap;
  }

  function hasEnded() public view returns (bool) {
    return isCapReached() || super.hasEnded();
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal view returns (bool) {
    bool withinCap = tokensSold.add(getTokenAmount(msg.value)) <= tokenCap;
    return withinCap && super.validPurchase();
  }
}

// File: contracts/crowdsale/WhitelistCrowdsale.sol

contract WhitelistCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  event WhitelistUpdated(uint256 timestamp, string operation, uint256 totalAddresses);

  // Mapping of whitelisted addresses
  mapping(address => bool) whitelisted;

  // Total count of whitelisted participants
  uint256 public whitelistedCount;

  function isWhitelisted(address _addr) public view returns (bool) {
    return whitelisted[_addr];
  }

  function addAddress(address _addr) external onlyOwner {
    whitelisted[_addr] = true;
    whitelistedCount++;
    WhitelistUpdated(block.timestamp, "Added", whitelistedCount);
  }

  function addAddresses(address[] _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      whitelisted[_addrs[i]] = true;
      whitelistedCount++;
    }

    WhitelistUpdated(block.timestamp, "Added", whitelistedCount);
  }

  function removeAddress(address _addr) external onlyOwner {
    whitelisted[_addr] = false;
    whitelistedCount--;
    WhitelistUpdated(block.timestamp, "Removed", whitelistedCount);
  }

  function removeAddresses(address[] _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      whitelisted[_addrs[i]] = false;
      whitelistedCount--;
    }

    WhitelistUpdated(block.timestamp, "Removed", whitelistedCount);
  }

  function validPurchase() internal view returns (bool) {
    return isWhitelisted(msg.sender) && super.validPurchase();
  }

}

// File: contracts/FourCrowdsale.sol

contract FourCrowdsale is TokenCappedCrowdsale, WhitelistCrowdsale, FinalizableCrowdsale {
  event RateChanged(uint256 newRate, string name);

  uint256 private constant E18 = 10**18;

  // Max tokens sold = 152 million
  uint256 private TOKEN_SALE_CAP = 152000000 * E18;

  uint256 public constant TEAM_TOKENS = 50000000 * E18;
  address public constant TEAM_ADDRESS = 0x3EC2fC20c04656F4B0AA7372258A36FAfB1EF427;

  // Vault tokens have been pre-minted
//  uint256 public constant VAULT_TOKENS = 152000000 * E18;
//  address public constant VAULT_ADDRESS = 0x545baa8e4Fff675711CB92Af33e5850aDD913b76;

  uint256 public constant ADVISORS_AND_CONTRIBUTORS_TOKENS = 39000000 * E18;
  address public constant ADVISORS_AND_CONTRIBUTORS_ADDRESS = 0x90adab6891514DC24411B9Adf2e11C0eD7739999;

  // Bounty tokens have been pre-minted
//  uint256 public constant BOUNTY_TOKENS = 7000000 * E18;
//  address public constant BOUNTY_ADDRESS = 0x18f260a71c282bc4d5fe4ee1187658a06e9d1a59;

  // Unsold tokens will be transfered to the VAULT
  address public constant UNSOLD_ADDRESS = 0x4eC155995211C8639375Ae3106187bff3FF5DB46;

  // Bonus amount. The first 24h there will be a bonus of 10%
  uint256 public bonus;

  function FourCrowdsale(uint256 _startTime,
                         uint256 _endTime,
                         uint256 _rate,
                         uint256 _bonus,
                         address _wallet,
                         address _token)
        TokenCappedCrowdsale(TOKEN_SALE_CAP)
        Crowdsale(_startTime, _endTime, _rate, _wallet, _token) public {
    bonus = _bonus;
  }

  function setCrowdsaleWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function changeStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner {
    require(_newStartTime >= now);
    require(_newEndTime >= _newStartTime);

    startTime = _newStartTime;
    endTime = _newEndTime;
  }

  function changeEndTime(uint256 _newEndTime) public onlyOwner {
    require(_newEndTime > startTime);
    endTime = _newEndTime;
  }

  function setRate(uint256 _rate) public onlyOwner  {
    require(now < startTime); // cant change once the sale has started
    rate = _rate;
    RateChanged(_rate, &#39;rate&#39;);
  }

  function setBonus(uint256 _bonus) public onlyOwner  {
    require(now < startTime); // cant change once the sale has started
    bonus = _bonus;
    RateChanged(_bonus, &#39;bonus&#39;);
  }

  function processPresaleOrEarlyContributors(address[] _beneficiaries, uint256[] _tokenAmounts) public onlyOwner {
    // Cant process anymore after the crowdsale has finished
    require(now <= endTime);

    for (uint i = 0; i < _beneficiaries.length; i++) {
      // update state
      tokensSold = tokensSold.add(_tokenAmounts[i]);
      token.mint(_beneficiaries[i], _tokenAmounts[i]);

      TokenPurchase(msg.sender, _beneficiaries[i], 0, _tokenAmounts[i]);
    }
  }


  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 actualRate = rate;

    // For the first 24 hours of the crowdsale there is a bonus
    if (now <= startTime + 1 days) {
      actualRate = actualRate.add(bonus);
    }

    return weiAmount.mul(actualRate);
  }

  function finalization() internal {
    // transfer tokens to team
    token.mint(TEAM_ADDRESS, TEAM_TOKENS);

    // transfer tokens to the 4th pillar vault
    // already minted before crowdsale
    // token.mint(VAULT_ADDRESS, VAULT_TOKENS);

    // transfer advisors and contributors tokens
    token.mint(ADVISORS_AND_CONTRIBUTORS_ADDRESS, ADVISORS_AND_CONTRIBUTORS_TOKENS);

    // transfer bounty tokens
    // already minted before crowdsale
    //token.mint(BOUNTY_ADDRESS, BOUNTY_TOKENS);

    // transfer all unsold tokens to the unsold address for the airdrop
    uint256 unsold_tokens = TOKEN_SALE_CAP - tokensSold;
    token.mint(UNSOLD_ADDRESS, unsold_tokens);

    // finish minting
    token.finishMinting();
    // release ownership back to owner
    token.transferOwnership(owner);
    // finalize
    super.finalization();
  }

  // @dev Recover any mistakenly sent ERC20 tokens to the Crowdsale address
  function recoverERC20Tokens(address _erc20, uint256 _amount) public onlyOwner {
    ERC20Interface(_erc20).transfer(msg.sender, _amount);
  }

  function releaseTokenOwnership() public onlyOwner {
    token.transferOwnership(owner);
  }
}