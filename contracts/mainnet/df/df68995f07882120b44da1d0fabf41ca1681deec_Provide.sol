pragma solidity ^0.4.13;


/**
 * Provide platform contract.
 */
contract Provide {
  using SafeMath for uint;

  /** Provide contract owner; has ability to update the platform robot address. */
  address public owner;

  /** Provide (PRVD) token. */
  ProvideToken public token;

  /** Provide platform robot; has ability to update the wallet contract addresses. */
  address public prvd;

  /** Provide platform wallet where fees owed to Provide are remitted. */
  address public prvdWallet;

  /** Provide platform wallet where payment amounts owed to providers are escrowed. */
  address public paymentEscrow;

  /**
   * @param _prvd Provide platform robot contract address
   * @param _prvdWallet Provide platform wallet where fees owed to Provide are remitted
   * @param _paymentEscrow Provide platform wallet where payment amounts owed to providers are escrowed
   */
  function Provide(
    address _token,
    address _prvd,
    address _prvdWallet,
    address _paymentEscrow
  ) {
    owner = msg.sender;
    token = ProvideToken(_token);
    prvd = _prvd;
    prvdWallet = _prvdWallet;
    paymentEscrow = _paymentEscrow;
  }

  /**
   * Deploy a work order contract.
   * @param _peer Address of party purchasing services
   * @param _identifier Provide platform work order identifier (UUIDv4)
   */
  function createWorkOrder(
    address _peer,
    uint128 _identifier
  ) onlyPrvd returns(address workOrder) {
    return new ProvideWorkOrder(token, prvd, prvdWallet, paymentEscrow, _peer, _identifier);
  }

  /**
   * Allow the contract owner to update Provide platform robot.
   */
  function setPrvd(address _prvd) onlyOwner {
    if (_prvd == 0x0) revert();
    prvd = _prvd;
  }

  /**
   * Allow the Provide platform robot to update the Provide wallet contract address.
   */
  function setPrvdWallet(address _prvdWallet) onlyPrvd {
    if (_prvdWallet == 0x0) revert();
    prvdWallet = _prvdWallet;
  }

  /**
   * Allow the Provide platform robot to update the payments escrow wallet contract address.
   */
  function setPaymentEscrow(address _paymentEscrow) onlyPrvd {
    if (_paymentEscrow == 0x0) revert();
    paymentEscrow = _paymentEscrow;
  }

  /**
   * Only allow the Provide contract owner to execute a contract function.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) revert();
    _;
  }

  /**
   * Only allow the Provide platform robot to execute a contract function.
   */
  modifier onlyPrvd() {
    if (msg.sender != prvd) revert();
    _;
  }
}

/**
 * Base contract for work orders on the Provide platform.
 */
contract ProvideWorkOrder {
  using SafeMath for uint;

  /** Status of the work order contract. **/
  enum Status { Pending, InProgress, Completed, Paid }

  /** Provide (PRVD) token. */
  ProvideToken public token;

  /** Provide platform robot. */
  address public prvd;

  /** Provide platform wallet where fees owed to Provide are remitted. */
  address public prvdWallet;

  /** Provide platform wallet where payment amounts owed to providers are escrowed. */
  address public paymentEscrow;

  /** Peer requesting and purchasing service. */
  address public peer;

  /** Peer providing service; compensated in PRVD tokens. */
  address public provider;

  /** Provide platform work order identifier (UUIDv4). */
  uint128 public identifier;

  /** Current status of the work order contract. **/
  Status public status;

  /** Total amount of Provide (PRVD) tokens payable to provider, expressed in wei. */
  uint256 public amount;

  /** Encoded transaction details. */
  string public details;

  /** Emitted when the work order has been started. */
  event WorkOrderStarted(uint128 _identifier);

  /** Emitted when the work order has been completed. */
  event WorkOrderCompleted(uint128 _identifier, uint256 _amount, string _details);

  /** Emitted when the transaction has been completed. */
  event TransactionCompleted(uint128 _identifier, uint256 _paymentAmount, uint256 feeAmount, string _details);

  /**
   * @param _prvd Provide platform robot contract address
   * @param _paymentEscrow Provide platform wallet where payment amounts owed to providers are escrowed
   * @param _peer Address of party purchasing services
   * @param _identifier Provide platform work order identifier (UUIDv4)
   */
  function ProvideWorkOrder(
    address _token,
    address _prvd,
    address _prvdWallet,
    address _paymentEscrow,
    address _peer,
    uint128 _identifier
  ) {
    if (_token == 0x0) revert();
    if (_prvd == 0x0) revert();
    if (_prvdWallet == 0x0) revert();
    if (_paymentEscrow == 0x0) revert();
    if (_peer == 0x0) revert();

    token = ProvideToken(_token);
    prvd = _prvd;
    prvdWallet = _prvdWallet;
    paymentEscrow = _paymentEscrow;
    peer = _peer;
    identifier = _identifier;

    status = Status.Pending;
  }

  /**
   * Set the address of the party providing service and start the work order.
   * @param _provider Address of the party providing service
   */
  function start(address _provider) public onlyPrvd onlyPending {
    if (provider != 0x0) revert();
    provider = _provider;
    status = Status.InProgress;
    WorkOrderStarted(identifier);
  }

  /**
   * Complete the work order.
   * @param _amount Total amount of Provide (PRVD) tokens payable to provider, expressed in wei
   * @param _details Encoded transaction details
   */
  function complete(uint256 _amount, string _details) public onlyProvider onlyInProgress {
    amount = _amount;
    details = _details;
    status = Status.Completed;
    WorkOrderCompleted(identifier, amount, details);
  }

  /**
   * Complete the transaction by remitting the exact amount of PRVD tokens due.
   * The service provider&#39;s payment is escrowed in the payment escrow wallet
   * and the platform fee is remitted to Provide.
   *
   * Partial payments will be rejected.
   */
  function completeTransaction() public onlyPurchaser onlyCompleted {
    uint allowance = token.allowance(msg.sender, this);
    if (allowance < amount) revert();

    token.transferFrom(this, paymentEscrow, amount);

    uint feeAmount = allowance.sub(amount);
    if (feeAmount > 0) token.transferFrom(this, prvdWallet, feeAmount);

    status = Status.Paid;
    TransactionCompleted(identifier, amount, feeAmount, details);
  }

  /**
   * Only allow the Provide platform robot to execute a contract function.
   */
  modifier onlyPrvd() {
    if (msg.sender != prvd) revert();
    _;
  }

  /**
   * Only allow the peer purchasing services to execute a contract function.
   */
  modifier onlyPurchaser() {
    if (msg.sender != peer) revert();
    _;
  }

  /**
   * Only allow the service provider to execute a contract function.
   */
  modifier onlyProvider() {
    if (msg.sender != provider) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is pending.
   */
  modifier onlyPending() {
    if (uint(status) != uint(Status.Pending)) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is started.
   */
  modifier onlyInProgress() {
    if (uint(status) != uint(Status.InProgress)) revert();
    _;
  }

  /**
   * Only allow execution of a contract function if the work order is complete.
   */
  modifier onlyCompleted() {
    if (uint(status) != uint(Status.Completed)) revert();
    _;
  }
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
    return a / b;
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

  function assertTrue(bool val) internal {
    assert(val);
  }

  function assertFalse(bool val) internal {
    assert(!val);
  }
}


/**
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Basic token.
 * Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping (address => uint) balances;

  /**
   * Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if (msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}


/**
 * Standard ERC20 token
 *
 * Implemantation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  /**
   * Transfer tokens from one address to another
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
   * Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * Controller interface.
 */
contract Controller {

  /**
   * Called to determine if the token allows proxy payments.
   *
   * @param _owner The address that sent ether to the token contract
   * @return True if the ether is accepted, false if it throws
   */
  function proxyPayment(address _owner) payable returns(bool);

  /**
   * Called to determine if the controller approves a token transfer.
   *
   * @param _from The origin of the transfer
   * @param _to The destination of the transfer
   * @param _amount The amount of the transfer
   * @return False if the controller does not authorize the transfer
   */
  function onTransfer(address _from, address _to, uint _amount) returns(bool);

  /**
   * Called to notify the controller of a transfer approval.
   *
   * @param _owner The address that calls `approve()`
   * @param _spender The spender in the `approve()` call
   * @param _amount The amount in the `approve()` call
   * @return False if the controller does not authorize the approval
   */
  function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}


/**
 * Controlled.
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
    if (msg.sender != controller) revert();
    _;
  }
}


/**
 * A trait that allows any token owner to decrease the token supply.
 *
 * We add a Burned event to differentiate from normal transfers.
 * However, we still try to support some legacy Ethereum ecosystem,
 * as ERC-20 has not standardized on the burn event yet.
 */
contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

  event Burned(address burner, uint burnedAmount);

  /**
   * Burn extra tokens from a balance.
   *
   * Keeps token balance tracking services happy by sending the burned
   * amount to BURN_ADDRESS, so that it will show up as a ERC-20 transaction
   * in etherscan, etc. as there is no standardized burn event yet.
   *
   * @param burnAmount The amount of tokens to burn
   */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);

    Burned(burner, burnAmount);
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}


/**
 * Mintable token.
 *
 * Simple ERC20 Token example, with mintable token creation
 */
contract MintableToken is StandardToken, Controlled {

  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;

  /**
   * Function to mint tokens
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
   * Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyController returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  modifier canMint() {
    if (mintingFinished) revert();
    _;
  }
}


/**
 * LimitedTransferToken
 *
 * LimitedTransferToken defines the generic interface and the implementation to limit token
 * transferability for different events. It is intended to be used as a base class for other token
 * contracts.
 * LimitedTransferToken has been designed to allow for different limiting factors,
 * this can be achieved by recursively calling super.transferableTokens() until the base class is
 * hit. For example:
 *     function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
 *       return min256(unlockedTokens, super.transferableTokens(holder, time));
 *     }
 * A working example is VestedToken.sol:
 */
contract LimitedTransferToken is ERC20 {

  /**
   * Checks whether it can transfer or otherwise throws
   */
  modifier canTransfer(address _sender, uint _value) {
    if (_value > transferableTokens(_sender, uint64(now))) revert();
    _;
  }

  /**
   * Checks modifier and allows transfer if tokens are not locked.
   *
   * @param _to The address that will recieve the tokens
   * @param _value The amount of tokens to be transferred
   */
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
    super.transfer(_to, _value);
  }

 /**
  * Checks modifier and allows transfer if tokens are not locked.
  *
  * @param _from The address that will send the tokens
  * @param _to The address that will receive the tokens
  * @param _value The amount of tokens to be transferred
  */
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
    super.transferFrom(_from, _to, _value);
  }

  /**
   * Default transferable tokens function returns all tokens for a holder (no limit).
   *
   * Overriding transferableTokens(address holder, uint64 time) is the way to provide the
   * specific logic for limiting token transferability for a holder over time.
   *
   * @param holder The address of the token holder
   */
  function transferableTokens(address holder, uint64 /* time */) constant public returns (uint256) {
    return balanceOf(holder);
  }
}


/**
 * Upgrade agent interface.
 *
 * Upgrade agent transfers tokens to a new contract. The upgrade agent itself
 * can be the token contract, or just an intermediary contract doing the heavy lifting.
 */
contract UpgradeAgent {

  uint public originalSupply;

  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;
}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens
 * to the next smart contract revision.
 *
 */
contract UpgradeableToken is StandardToken {

  /** Contract/actor who can set the upgrade path. */
  address public upgradeController;

  /** Designated upgrade agent responsible for completing the upgrade. */
  UpgradeAgent public upgradeAgent;

  /** Number of tokens upgraded to date. */
  uint256 public totalUpgraded;

  /**
   * Upgrade states:
   *
   * - NotAllowed: the child contract has not reached a condition where the upgrade can begin
   * - WaitingForAgent: token allows upgrade, but we don&#39;t have a new agent yet
   * - ReadyToUpgrade: the agent is set, but not a single token has been upgraded yet
   * - Upgrading: upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Emitted when a token holder upgrades some portion of token holdings.
   */
  event Upgrade(address indexed from, address indexed to, uint256 value);

  /**
   * New upgrade agent has been set.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade controller.
   */
  function UpgradeableToken(address _upgradeController) {
    upgradeController = _upgradeController;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {
      UpgradeState state = getUpgradeState();
      if (!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        revert(); // called in an invalid state
      }

      if (value == 0) revert(); // validate input value

      balances[msg.sender] = balances[msg.sender].sub(value);

      // Take tokens out from circulation
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that can handle.
   */
  function setUpgradeAgent(address agent) external {
      if (!canUpgrade()) {
        revert();
      }

      if (agent == 0x0) revert();
      if (msg.sender != upgradeController) revert(); // only upgrade controller can designate the next agent
      if (getUpgradeState() == UpgradeState.Upgrading) revert(); // upgrade has already started for an agent

      upgradeAgent = UpgradeAgent(agent);

      if (!upgradeAgent.isUpgradeAgent()) revert(); // bad interface
      if (upgradeAgent.originalSupply() != totalSupply) revert(); // ensure that token supplies match in source and target

      UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if (address(upgradeAgent) == 0x0) return UpgradeState.WaitingForAgent;
    else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade controller.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeController(address controller) public {
      if (controller == 0x0) revert();
      if (msg.sender != upgradeController) revert();
      upgradeController = controller;
  }

  /**
   * Child contract can override to condition enable upgrade path.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }
}


/**
 * Vested token.
 *
 * Tokens that can be vested for a group of addresses.
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
   * Grant tokens to a specified address.
   *
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
      revert();
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) revert();  // To prevent a user being spammed and have his balance
                                                                // locked (out of gas attack when calculating vesting).

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
   * Revoke the grant of tokens of a specified address.
   *
   * @param _holder The address which will have its tokens revoked
   * @param _grantId The id of the token grant
   */
  function revokeTokenGrant(address _holder, uint _grantId) public {
    TokenGrant storage grant = grants[_holder][_grantId];

    if (!grant.revokable) { // check if grant is revokable
      revert();
    }

    if (grant.granter != msg.sender) { // only granter to revoke the grant
      revert();
    }

    address receiver = grant.burnsOnRevoke ? 0x0 : msg.sender;
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
   * Calculate the total amount of transferable tokens of a holder at a given time.
   *
   * @param holder address The address of the holder
   * @param time uint64 The specific time
   * @return An uint representing a holder&#39;s total amount of transferable tokens
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
   * Check the amount of grants that an address has.
   *
   * @param _holder The holder of the grants
   * @return A uint representing the total amount of grants
   */
  function tokenGrantsCount(address _holder) constant returns (uint index) {
    return grants[_holder].length;
  }

  /**
   * Calculate amount of vested tokens at a specific time.
   *
   * @param tokens uint256 The amount of tokens granted
   * @param time uint64 The time to be checked
   * @param start uint64 A time representing the beginning of the grant
   * @param cliff uint64 The cliff period
   * @param vesting uint64 The vesting period
   * @return An uint representing the amount of vested tokens from a specific grant
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
  function calculateVestedTokens(uint256 tokens, uint256 time, uint256 start, uint256 cliff, uint256 vesting) constant returns (uint256) {
      // Shortcuts for before cliff and after vesting cases.
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;

      // Interpolate all vested tokens.
      // As before cliff the shortcut returns 0, we can use just calculate a value
      // in the vesting rect (as shown in above&#39;s figure)

      uint vestedTokens = tokens.mul(time.sub(start)).div(vesting.sub(start));
      return vestedTokens;
  }

  /**
   * Get all information about a specifc grant.
   *
   * @param _holder The address which will have its tokens revoked.
   * @param _grantId The id of the token grant.
   * @return Returns all the values that represent a TokenGrant(address, value, start, cliff,
   *         revokability, burnsOnRevoke, and vesting) plus the vested value at the current time.
   */
  function tokenGrant(address _holder, uint _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant storage grant = grants[_holder][_grantId];

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
   * Get the amount of vested tokens at a specific time.
   *
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
   * Calculate the amount of non vested tokens at a specific time.
   *
   * @param grant TokenGrant The grant to be checked.
   * @param time uint64 The time to be checked
   * @return An uint representing the amount of non vested tokens of a specifc grant on the
   * passed time frame.
   */
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return grant.value.sub(vestedTokens(grant, time));
  }

  /**
   * Calculate the date when the holder can trasfer all its tokens
   *
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

/**
 * Provide (PRVD) token contract.
 */
contract ProvideToken is BurnableToken, MintableToken, VestedToken, UpgradeableToken {

  string public constant name = &#39;Provide&#39;;
  string public constant symbol = &#39;PRVD&#39;;
  uint public constant decimals = 8;

  function ProvideToken()  UpgradeableToken(msg.sender) { }

  function() public payable {
    if (isContract(controller)) {
      if (!Controller(controller).proxyPayment.value(msg.value)(msg.sender)) revert();
    } else {
      revert();
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