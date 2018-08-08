pragma solidity ^0.4.11;


/**
 * Controller
 */
contract Controller {

  /// @notice Called when `_owner` sends ether to the token contract
  /// @param _owner The address that sent the ether to create tokens
  /// @return True if the ether is accepted, false if it throws
  function proxyPayment(address _owner) payable returns(bool);

  /// @notice Notifies the controller about a token transfer allowing the
  ///  controller to react if desired
  /// @param _from The origin of the transfer
  /// @param _to The destination of the transfer
  /// @param _amount The amount of the transfer
  /// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) returns(bool);

  /// @notice Notifies the controller about an approval allowing the
  ///  controller to react if desired
  /// @param _owner The address that calls `approve()`
  /// @param _spender The spender in the `approve()` call
  /// @param _amount The amount in the `approve()` call
  /// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}

/**
 * Math operations with safety checks
 */
library SafeMath {

  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
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
    if (msg.sender != owner) {
      throw;
    }
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title Contracts that should not own Tokens
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is Ownable {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ Uint the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint value_, bytes data_) external {
    throw;
  }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param tokenAddr address The address of the token contract
   */
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

// @dev Contract to hold ETH raised during a token sale.
// Prevents attack in which the Multisig sends raised ether to the
// sale contract to mint tokens to itself, and getting the
// funds back immediately.
contract AbstractSale {
  function saleFinalized() constant returns (bool);
}

contract Escrow is HasNoTokens {

  address public beneficiary;
  uint public finalBlock;
  AbstractSale public tokenSale;

  // @dev Constructor initializes public variables
  // @param _beneficiary The address of the multisig that will receive the funds
  // @param _finalBlock Block after which the beneficiary can request the funds
  function Escrow(address _beneficiary, uint _finalBlock, address _tokenSale) {
    beneficiary = _beneficiary;
    finalBlock = _finalBlock;
    tokenSale = AbstractSale(_tokenSale);
  }

  // @dev Receive all sent funds without any further logic
  function() public payable {}

  // @dev Withdraw function sends all the funds to the wallet if conditions are correct
  function withdraw() public {
    if (msg.sender != beneficiary) throw;
    if (block.number > finalBlock) return doWithdraw();
    if (tokenSale.saleFinalized()) return doWithdraw();
  }

  function doWithdraw() internal {
    if (!beneficiary.send(this.balance)) throw;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping (address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * Controlled
 */
contract Controlled {

  address public controller;

  function Controlled() {
    controller = msg.sender;
  }

  function changeController(address _controller) onlyController {
    controller = _controller;
  }

  modifier onlyController {
    if (msg.sender != controller) throw;
    _;
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 */
contract MintableToken is StandardToken, Controlled {

  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyController canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyController returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  modifier canMint() {
    if (mintingFinished) throw;
    _;
  }
}

/**
 * @title LimitedTransferToken
 * @dev LimitedTransferToken defines the generic interface and the implementation to limit token
 * transferability for different events. It is intended to be used as a base class for other token
 * contracts.
 * LimitedTransferToken has been designed to allow for different limiting factors,
 * this can be achieved by recursively calling super.transferableTokens() until the base class is
 * hit. For example:
 *     function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
 *       return min256(unlockedTokens, super.transferableTokens(holder, time));
 *     }
 * A working example is VestedToken.sol:
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/VestedToken.sol
 */
contract LimitedTransferToken is ERC20 {

  /**
   * @dev Checks whether it can transfer or otherwise throws.
   */
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) throw;
   _;
  }

  /**
   * @dev Checks modifier and allows transfer if tokens are not locked.
   * @param _to The address that will recieve the tokens.
   * @param _value The amount of tokens to be transferred.
   */
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
    super.transfer(_to, _value);
  }

  /**
  * @dev Checks modifier and allows transfer if tokens are not locked.
  * @param _from The address that will send the tokens.
  * @param _to The address that will recieve the tokens.
  * @param _value The amount of tokens to be transferred.
  */
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
    super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Default transferable tokens function returns all tokens for a holder (no limit).
   * @dev Overwriting transferableTokens(address holder, uint64 time) is the way to provide the
   * specific logic for limiting token transferability for a holder over time.
   */
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}

/**
 * @title Vested token
 * @dev Tokens that can be vested for a group of addresses.
 */
contract VestedToken is StandardToken, LimitedTransferToken {

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

  struct TokenGrant {
    address granter;     // 20 bytes
    uint256 value;       // 32 bytes
    uint64 cliff;
    uint64 vesting;
    uint64 start;        // 3 * 8 = 24 bytes
    bool revokable;
    bool burnsOnRevoke;  // 2 * 1 = 2 bits? or 2 bytes?
  } // total 78 bytes = 3 sstore per operation (32 per sstore)

  mapping (address => TokenGrant[]) public grants;

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

  /**
   * @dev Grant tokens to a specified address
   * @param _to address The address which the tokens will be granted to.
   * @param _value uint256 The amount of tokens to be granted.
   * @param _start uint64 Time of the beginning of the grant.
   * @param _cliff uint64 Time of the cliff period.
   * @param _vesting uint64 The vesting period.
   * @param _revokable bool If the grant is revokable.
   * @param _burnsOnRevoke bool When true, the tokens are burned if revoked.
   */
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) public {

    // Check for date inconsistencies that may cause unexpected behavior
    if (_cliff < _start || _vesting < _cliff) {
      throw;
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) throw;  // To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).

    uint count = grants[_to].push(
                TokenGrant(
                  _revokable ? msg.sender : 0,  // avoid storing an extra 20 bytes when it is non-revokable
                  _value,
                  _cliff,
                  _vesting,
                  _start,
                  _revokable,
                  _burnsOnRevoke
                )
              );
    transfer(_to, _value);
    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

  /**
   * @dev Revoke the grant of tokens of a specifed address.
   * @param _holder The address which will have its tokens revoked.
   * @param _grantId The id of the token grant.
   */
  function revokeTokenGrant(address _holder, uint _grantId) public {
    TokenGrant grant = grants[_holder][_grantId];

    if (!grant.revokable) { // Check if grant was revokable
      throw;
    }

    if (grant.granter != msg.sender) { // Only granter can revoke it
      throw;
    }

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;
    uint256 nonVested = nonVestedTokens(grant, uint64(now));

    // remove grant from array
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    balances[receiver] = balances[receiver].add(nonVested);
    balances[_holder] = balances[_holder].sub(nonVested);

    Transfer(_holder, receiver, nonVested);
  }

  /**
   * @dev Calculate the total amount of transferable tokens of a holder at a given time
   * @param holder address The address of the holder
   * @param time uint64 The specific time.
   * @return An uint representing a holder&#39;s total amount of transferable tokens.
   */
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);
    if (grantIndex == 0) return balanceOf(holder); // shortcut for holder without grants

    // Iterate through all the grants the holder has, and add all non-vested tokens
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
    }

    // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
    uint256 vestedTransferable = balanceOf(holder).sub(nonVested);

    // Return the minimum of how many vested can transfer and other value
    // in case there are other limiting transferability factors (default is balanceOf)
    return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

  /**
   * @dev Check the amount of grants that an address has.
   * @param _holder The holder of the grants.
   * @return A uint representing the total amount of grants.
   */
  function tokenGrantsCount(address _holder) constant returns (uint index) {
    return grants[_holder].length;
  }

  /**
   * @dev Calculate amount of vested tokens at a specifc time.
   * @param tokens uint256 The amount of tokens grantted.
   * @param time uint64 The time to be checked
   * @param start uint64 A time representing the begining of the grant
   * @param cliff uint64 The cliff period.
   * @param vesting uint64 The vesting period.
   * @return An uint representing the amount of vested tokensof a specif grant.
   *  transferableTokens
   *   |                         _/--------   vestedTokens rect
   *   |                       _/
   *   |                     _/
   *   |                   _/
   *   |                 _/
   *   |                /
   *   |              .|
   *   |            .  |
   *   |          .    |
   *   |        .      |
   *   |      .        |(grants[_holder] == address(0)) return 0;
   *   |    .          |
   *   +===+===========+---------+----------> time
   *      Start       Clift    Vesting
   */
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) constant returns (uint256)
    {
      // Shortcuts for before cliff and after vesting cases.
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;

      // Interpolate all vested tokens.
      // As before cliff the shortcut returns 0, we can use just calculate a value
      // in the vesting rect (as shown in above&#39;s figure)

      // vestedTokens = tokens * (time - start) / (vesting - start)
      uint256 vestedTokens = tokens.mul(time.sub(start)).div(vesting.sub(start));
      return vestedTokens;
  }

  /**
   * @dev Get all information about a specifc grant.
   * @param _holder The address which will have its tokens revoked.
   * @param _grantId The id of the token grant.
   * @return Returns all the values that represent a TokenGrant(address, value, start, cliff,
   * revokability, burnsOnRevoke, and vesting) plus the vested value at the current time.
   */
  function tokenGrant(address _holder, uint _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
  }

  /**
   * @dev Get the amount of vested tokens at a specific time.
   * @param grant TokenGrant The grant to be checked.
   * @param time The time to be checked
   * @return An uint representing the amount of vested tokens of a specific grant at a specific time.
   */
  function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

  /**
   * @dev Calculate the amount of non vested tokens at a specific time.
   * @param grant TokenGrant The grant to be checked.
   * @param time uint64 The time to be checked
   * @return An uint representing the amount of non vested tokens of a specifc grant on the
   * passed time frame.
   */
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return grant.value.sub(vestedTokens(grant, time));
  }

  /**
   * @dev Calculate the date when the holder can trasfer all its tokens
   * @param holder address The address of the holder
   * @return An uint representing the date of the last transferable tokens.
   */
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = SafeMath.max64(grants[holder][i].vesting, date);
    }
  }
}

/// @title Artcoin (ART) - democratizing culture.
contract Artcoin is MintableToken, VestedToken {

  string public constant name = &#39;Artcoin&#39;;
  string public constant symbol = &#39;ART&#39;;
  uint public constant decimals = 18;

  function() public payable {
    if (isContract(controller)) {
      if (!Controller(controller).proxyPayment.value(msg.value)(msg.sender)) throw;
    } else {
      throw;
    }
  }

  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == address(0)) return false;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }
}

/// @title Artcoin Placeholder - democratizing culture.
contract ArtcoinPlaceholder is Controller {

  Artcoin public token;
  address public tokenSale;

  function ArtcoinPlaceholder(address _token, address _tokenSale) {
    token = Artcoin(_token);
    tokenSale = _tokenSale;
  }

  function changeController(address consortium) public {
    if (msg.sender != tokenSale) throw;
    token.changeController(consortium);
    suicide(consortium);
  }

  function proxyPayment(address _owner) payable public returns (bool) {
    throw;
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return true;
  }
}

/// @title ART Sale - democratizing culture.
contract ArtSale is Controller {
  using SafeMath for uint;

  address public manager;
  address public operations;
  ArtcoinPlaceholder public consortiumPlaceholder;

  Artcoin public token;
  Escrow public escrow;

  uint public initialBlock;  // block number in which the sale starts, inclusive. sale will be opened at initial block.
  uint public finalBlock;  // block number in which the sale ends, exclusive, sale will be closed at ends block.
  uint public initialPrice;  // number of wei-Artcoin tokens for 1 wei, at the start of the sale (18 decimals)
  uint public finalPrice;  // number of wei-Artcoin tokens for 1 wei, at the end of the sale
  uint public priceStages;  // number of different price stages for interpolating between initialPrice and finalPrice

  uint public maximumSubscription;  // maximum subscriptions, in wei
  uint public totalSubscription = 0;  // total subscriptions, in wei

  mapping (address => bool) public activations;  // confirmations to activate the sale
  mapping (address => uint) public subscriptions;  // subscriptions

  uint constant public dust = 1 finney;  // minimum investment

  bool public saleStopped = false;
  bool public saleFinalized = false;

  event NewPresaleAllocation(address indexed holder, uint amount);
  event NewSubscription(address indexed holder, uint amount, uint etherAmount);

  function ArtSale(address _manager,
                   address _operations,
                   uint _initialBlock,
                   uint _finalBlock,
                   uint256 _initialPrice,
                   uint256 _finalPrice,
                   uint8 _priceStages,
                   uint _maximumSubscription)
                   nonZeroAddress(_operations) {
    if (_initialBlock < getBlockNumber()) throw;
    if (_initialBlock >= _finalBlock) throw;
    if (_initialPrice <= _finalPrice) throw;
    if (_priceStages < 2) throw;
    if (_priceStages > _initialPrice - _finalPrice) throw;

    manager = _manager;
    operations = _operations;
    maximumSubscription = _maximumSubscription;
    initialBlock = _initialBlock;
    finalBlock = _finalBlock;
    initialPrice = _initialPrice;
    finalPrice = _finalPrice;
    priceStages = _priceStages;
  }

  // @notice Set Artcoin token and escrow address.
  // @param _token: Address of an instance of the Artcoin token
  // @param _consortiumPlaceholder: Address of the consortium placeholder
  // @param _escrow: Address of the wallet receiving the funds of the sale
  function setArtcoin(address _token,
                      address _consortiumPlaceholder,
                      address _escrow)
                      nonZeroAddress(_token)
                      nonZeroAddress(_consortiumPlaceholder)
                      nonZeroAddress(_escrow)
                      public {
    if (activations[this]) throw;

    token = Artcoin(_token);
    consortiumPlaceholder = ArtcoinPlaceholder(_consortiumPlaceholder);
    escrow = Escrow(_escrow);

    if (token.controller() != address(this)) throw;  // sale is token controller
    if (token.totalSupply() > 0) throw;  // token is empty
    if (consortiumPlaceholder.tokenSale() != address(this)) throw;  // placeholder has reference to sale
    if (consortiumPlaceholder.token() != address(token)) throw; // placeholder has reference to ART
    if (escrow.finalBlock() != finalBlock) throw;  // final blocks must match
    if (escrow.beneficiary() != operations) throw;  // receiving wallet must match
    if (escrow.tokenSale() != address(this)) throw;  // watched token sale must be self

    doActivateSale(this);
  }

  // @notice Certain addresses need to call the activate function prior to the sale opening block.
  // This proves that they have checked the sale contract is legit, as well as proving
  // the capability for those addresses to interact with the contract.
  function activateSale() public {
    doActivateSale(msg.sender);
  }

  function doActivateSale(address _entity) nonZeroAddress(token) onlyBeforeSale private {
    activations[_entity] = true;
  }

  // @notice Whether the needed accounts have activated the sale.
  // @return Is sale activated
  function isActivated() constant public returns (bool) {
    return activations[this] && activations[operations];
  }

  // @notice Get the price for a Artcoin token at any given block number
  // @param _blockNumber the block for which the price is requested
  // @return Number of wei-Artcoin for 1 wei
  // If sale isn&#39;t ongoing for that block, returns 0.
  function getPrice(uint _blockNumber) constant public returns (uint) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;
    return priceForStage(stageForBlock(_blockNumber));
  }

  // @notice Get what the stage is for a given blockNumber
  // @param _blockNumber: Block number
  // @return The sale stage for that block. Stage is between 0 and (priceStages - 1)
  function stageForBlock(uint _blockNumber) constant internal returns (uint) {
    uint blockN = _blockNumber.sub(initialBlock);
    uint totalBlocks = finalBlock.sub(initialBlock);
    return priceStages.mul(blockN).div(totalBlocks);
  }

  // @notice Get what the price is for a given stage
  // @param _stage: Stage number
  // @return Price in wei for that stage.
  // If sale stage doesn&#39;t exist, returns 0.
  function priceForStage(uint _stage) constant internal returns (uint) {
    if (_stage >= priceStages) return 0;
    uint priceDifference = initialPrice.sub(finalPrice);
    uint stageDelta = priceDifference.div(uint(priceStages - 1));
    return initialPrice.sub(uint(_stage).mul(stageDelta));
  }

  // @notice Artcoin needs to make initial token allocations for presale partners
  // This allocation has to be made before the sale is activated. Activating the
  // sale means no more arbitrary allocations are possible and expresses conformity.
  // @param _recipient: The receiver of the tokens
  // @param _amount: Amount of tokens allocated for receiver.
  function allocatePresaleTokens(address _recipient,
                                 uint _amount,
                                 uint64 cliffDate,
                                 uint64 vestingDate,
                                 bool revokable,
                                 bool burnOnRevocation)
                                 onlyBeforeSaleActivation
                                 onlyBeforeSale
                                 nonZeroAddress(_recipient)
                                 only(operations) public {
    token.grantVestedTokens(_recipient, _amount, uint64(now), cliffDate, vestingDate, revokable, burnOnRevocation);
    NewPresaleAllocation(_recipient, _amount);
  }

  /// @dev The fallback function is called when ether is sent to the contract, it
  /// simply calls `doPayment()` with the address that sent the ether as the
  /// `_subscriber`. Payable is a required solidity modifier for functions to receive
  /// ether, without this modifier functions will throw if ether is sent to them
  function() public payable {
    return doPayment(msg.sender);
  }

  /// @dev `doPayment()` is an internal function that sends the ether that this
  /// contract receives to escrow and creates tokens in the address of the
  /// @param _subscriber The address that will hold the newly created tokens
  function doPayment(address _subscriber)
           onlyDuringSalePeriod
           onlySaleNotStopped
           onlySaleActivated
           nonZeroAddress(_subscriber)
           minimumValue(dust) internal {
    if (totalSubscription + msg.value > maximumSubscription) throw;  // throw if maximum subscription exceeded
    uint purchasedTokens = msg.value.mul(getPrice(getBlockNumber()));  // number of purchased tokens

    if (!escrow.send(msg.value)) throw;  // escrow funds
    if (!token.mint(_subscriber, purchasedTokens)) throw;  // deliver tokens

    subscriptions[_subscriber] = subscriptions[_subscriber].add(msg.value);
    totalSubscription = totalSubscription.add(msg.value);
    NewSubscription(_subscriber, purchasedTokens, msg.value);
  }

  // @notice Function to stop sale before the sale period ends
  // @dev Only operations is authorized to call this method
  function stopSale() onlySaleActivated onlySaleNotStopped only(operations) public {
    saleStopped = true;
  }

  // @notice Function to restart stopped sale
  // @dev Only operations is authorized to call this method
  function restartSale() onlyDuringSalePeriod onlySaleStopped only(operations) public {
    saleStopped = false;
  }

  // @notice Finalizes sale and distributes Artcoin to purchasers and releases payments
  // @dev Transfers the token controller power to the consortium.
  function finalizeSale() onlyAfterSale only(operations) public {
    doFinalizeSale();
  }

  function doFinalizeSale() internal {
    uint purchasedTokens = token.totalSupply();

    uint advisorTokens = purchasedTokens * 5 / 100;  // mint 5% of purchased for advisors
    if (!token.mint(operations, advisorTokens)) throw;

    uint managerTokens = purchasedTokens * 25 / 100;  // mint 25% of purchased for manager
    if (!token.mint(manager, managerTokens)) throw;

    token.changeController(consortiumPlaceholder);

    saleFinalized = true;
    saleStopped = true;
  }

  // @notice Deploy Artcoin Consortium contract
  // @param consortium: The address the consortium was deployed at.
  function deployConsortium(address consortium) onlyFinalizedSale nonZeroAddress(consortium) only(operations) public {
    consortiumPlaceholder.changeController(consortium);
  }

  function setOperations(address _operations) nonZeroAddress(_operations) only(operations) public {
    operations = _operations;
  }

  function getBlockNumber() constant internal returns (uint) {
    return block.number;
  }

  function saleFinalized() constant returns (bool) {
    return saleFinalized;
  }

  function proxyPayment(address _owner) payable public returns (bool) {
    doPayment(_owner);
    return true;
  }

  /// @notice Notifies the controller about a transfer
  /// @param _from The origin of the transfer
  /// @param _to The destination of the transfer
  /// @param _amount The amount of the transfer
  /// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    // Until the sale is finalized, only allows transfers originated by the sale contract.
    // When finalizeSale is called, this function will stop being called and will always be true.
    return _from == address(this);
  }

  /// @notice Notifies the controller about an approval
  /// @param _owner The address that calls `approve()`
  /// @param _spender The spender in the `approve()` call
  /// @param _amount The amount in the `approve()` call
  /// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return false;
  }

  modifier only(address x) {
    if (msg.sender != x) throw;
    _;
  }

  modifier onlyBeforeSale {
    if (getBlockNumber() >= initialBlock) throw;
    _;
  }

  modifier onlyDuringSalePeriod {
    if (getBlockNumber() < initialBlock) throw;
    if (getBlockNumber() >= finalBlock) throw;
    _;
  }

  modifier onlyAfterSale {
    if (getBlockNumber() < finalBlock) throw;
    _;
  }

  modifier onlySaleStopped {
    if (!saleStopped) throw;
    _;
  }

  modifier onlySaleNotStopped {
    if (saleStopped) throw;
    _;
  }

  modifier onlyBeforeSaleActivation {
    if (isActivated()) throw;
    _;
  }

  modifier onlySaleActivated {
    if (!isActivated()) throw;
    _;
  }

  modifier onlyFinalizedSale {
    if (getBlockNumber() < finalBlock) throw;
    if (!saleFinalized) throw;
    _;
  }

  modifier nonZeroAddress(address x) {
    if (x == 0) throw;
    _;
  }

  modifier minimumValue(uint256 x) {
    if (msg.value < x) throw;
    _;
  }
}