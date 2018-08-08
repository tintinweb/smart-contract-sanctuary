pragma solidity ^0.4.13;
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
 * @title Math
 * @dev Assorted math operations
 */
contract Math {
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
    require(newOwner != address(0));
    owner = newOwner;
  }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
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
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is SafeMath, ERC20Basic {
  mapping(address => uint256) balances;
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) returns (bool){
    balances[msg.sender] = sub(balances[msg.sender],_value);
    balances[_to] = add(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
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
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    balances[_to] = add(balances[_to],_value);
    balances[_from] = sub(balances[_from],_value);
    allowed[_from][msg.sender] = sub(_allowance,_value);
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = add(totalSupply,_amount);
    balances[_to] = add(balances[_to],_amount);
    Mint(_to, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
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
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }
  /**
   * @dev Checks modifier and allows transfer if tokens are not locked.
   * @param _to The address that will recieve the tokens.
   * @param _value The amount of tokens to be transferred.
   */
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
    return super.transfer(_to, _value);
  }
  /**
  * @dev Checks modifier and allows transfer if tokens are not locked.
  * @param _from The address that will send the tokens.
  * @param _to The address that will recieve the tokens.
  * @param _value The amount of tokens to be transferred.
  */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
    return super.transferFrom(_from, _to, _value);
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
contract VestedToken is Math, StandardToken, LimitedTransferToken {
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
    require(_cliff >= _start && _vesting >= _cliff);
    require(tokenGrantsCount(_to) < MAX_GRANTS_PER_ADDRESS);   // To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).
    uint256 count = grants[_to].push(
                TokenGrant(
                  _revokable ? msg.sender : 0, // avoid storing an extra 20 bytes when it is non-revokable
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
  function revokeTokenGrant(address _holder, uint256 _grantId) public {
    TokenGrant storage grant = grants[_holder][_grantId];
    require(grant.revokable);
    require(grant.granter == msg.sender); // Only granter can revoke it
    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;
    uint256 nonVested = nonVestedTokens(grant, uint64(now));
    // remove grant from array
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][sub(grants[_holder].length,1)];
    grants[_holder].length -= 1;
    balances[receiver] = add(balances[receiver],nonVested);
    balances[_holder] = sub(balances[_holder],nonVested);
    Transfer(_holder, receiver, nonVested);
  }
  /**
   * @dev Calculate the total amount of transferable tokens of a holder at a given time
   * @param holder address The address of the holder
   * @param time uint64 The specific time.
   * @return An uint256 representing a holder&#39;s total amount of transferable tokens.
   */
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);
    if (grantIndex == 0) return super.transferableTokens(holder, time); // shortcut for holder without grants
    // Iterate through all the grants the holder has, and add all non-vested tokens
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = add(nonVested, nonVestedTokens(grants[holder][i], time));
    }
    // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
    uint256 vestedTransferable = sub(balanceOf(holder), nonVested);
    // Return the minimum of how many vested can transfer and other value
    // in case there are other limiting transferability factors (default is balanceOf)
    return min256(vestedTransferable, super.transferableTokens(holder, time));
  }
  /**
   * @dev Check the amount of grants that an address has.
   * @param _holder The holder of the grants.
   * @return A uint256 representing the total amount of grants.
   */
  function tokenGrantsCount(address _holder) constant returns (uint256 index) {
    return grants[_holder].length;
  }
  /**
   * @dev Calculate amount of vested tokens at a specifc time.
   * @param tokens uint256 The amount of tokens grantted.
   * @param time uint64 The time to be checked
   * @param start uint64 A time representing the begining of the grant
   * @param cliff uint64 The cliff period.
   * @param vesting uint64 The vesting period.
   * @return An uint256 representing the amount of vested tokensof a specif grant.
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
   *   |      .        |
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
      uint256 vestedTokens = div(
                                    mul(
                                      tokens,
                                      sub(time, start)
                                      ),
                                    sub(vesting, start)
                                    );
      return vestedTokens;
  }
  /**
   * @dev Get all information about a specifc grant.
   * @param _holder The address which will have its tokens revoked.
   * @param _grantId The id of the token grant.
   * @return Returns all the values that represent a TokenGrant(address, value, start, cliff,
   * revokability, burnsOnRevoke, and vesting) plus the vested value at the current time.
   */
  function tokenGrant(address _holder, uint256 _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
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
   * @dev Get the amount of vested tokens at a specific time.
   * @param grant TokenGrant The grant to be checked.
   * @param time The time to be checked
   * @return An uint256 representing the amount of vested tokens of a specific grant at a specific time.
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
   * @return An uint256 representing the amount of non vested tokens of a specifc grant on the
   * passed time frame.
   */
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return sub(grant.value,vestedTokens(grant, time));
  }
  /**
   * @dev Calculate the date when the holder can trasfer all its tokens
   * @param holder address The address of the holder
   * @return An uint256 representing the date of the last transferable tokens.
   */
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = max64(grants[holder][i].vesting, date);
    }
  }
}
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is SafeMath, StandardToken {
    event Burn(address indexed burner, uint indexed value);
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint _value)
        public
    {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = sub(balances[burner], _value);
        totalSupply = sub(totalSupply, _value);
        Burn(burner, _value);
    }
}
/**
 * @title PLC
 * @dev PLC is ERC20 token contract, inheriting MintableToken, PausableToken,
 * VestedToken, BurnableToken contract from open zeppelin.
 */
contract PLC is MintableToken, PausableToken, VestedToken, BurnableToken {
  string public name = "PlusCoin";
  string public symbol = "PLC";
  uint256 public decimals = 18;
}
/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable, SafeMath{
  enum State { Active, Refunding, Closed }
  mapping (address => uint256) public deposited;
  mapping (address => uint256) public refunded;
  State public state;
  address public devMultisig;
  address[] public reserveWallet;
  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  /**
   * @dev This constructor sets the addresses of multi-signature wallet and
   * 5 reserve wallets.
   * and forwarding it if crowdsale is successful.
   * @param _devMultiSig address The address of multi-signature wallet.
   * @param _reserveWallet address[5] The addresses of reserve wallet.
   */
  function RefundVault(address _devMultiSig, address[] _reserveWallet) {
    state = State.Active;
    devMultisig = _devMultiSig;
    reserveWallet = _reserveWallet;
  }
  /**
   * @dev This function is called when user buy tokens. Only RefundVault
   * contract stores the Ether user sent which forwarded from crowdsale
   * contract.
   * @param investor address The address who buy the token from crowdsale.
   */
  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = add(deposited[investor], msg.value);
  }
  event Transferred(address _to, uint _value);
  /**
   * @dev This function is called when crowdsale is successfully finalized.
   */
  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    uint256 balance = this.balance;
    uint256 devAmount = div(balance, 10);
    devMultisig.transfer(devAmount);
    Transferred(devMultisig, devAmount);
    uint256 reserveAmount = div(mul(balance, 9), 10);
    uint256 reserveAmountForEach = div(reserveAmount, reserveWallet.length);
    for(uint8 i = 0; i < reserveWallet.length; i++){
      reserveWallet[i].transfer(reserveAmountForEach);
      Transferred(reserveWallet[i], reserveAmountForEach);
    }
    Closed();
  }
  /**
   * @dev This function is called when crowdsale is unsuccessfully finalized
   * and refund is required.
   */
  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }
  /**
   * @dev This function allows for user to refund Ether.
   */
  function refund(address investor) returns (bool) {
    require(state == State.Refunding);
    if (refunded[investor] > 0) {
      return false;
    }
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    refunded[investor] = depositedValue;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
    return true;
  }
}
/**
 * @title KYC
 * @dev KYC contract handles the white list for PLCCrowdsale contract
 * Only accounts registered in KYC contract can buy PLC token.
 * Admins can register account, and the reason why
 */
contract KYC is Ownable, SafeMath, Pausable {
  // check the address is registered for token sale
  mapping (address => bool) public registeredAddress;
  // check the address is admin of kyc contract
  mapping (address => bool) public admin;
  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event NewAdmin(address indexed _addr);
  /**
   * @dev check whether the address is registered for token sale or not.
   * @param _addr address
   */
  modifier onlyRegistered(address _addr) {
    require(isRegistered(_addr));
    _;
  }
  /**
   * @dev check whether the msg.sender is admin or not
   */
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }
  function KYC() {
    admin[msg.sender] = true;
  }
  /**
   * @dev set new admin as admin of KYC contract
   * @param _addr address The address to set as admin of KYC contract
   */
  function setAdmin(address _addr)
    public
    onlyOwner
  {
    require(_addr != address(0) && admin[_addr] == false);
    admin[_addr] = true;
    NewAdmin(_addr);
  }
  /**
   * @dev check the address is register for token sale
   * @param _addr address The address to check whether register or not
   */
  function isRegistered(address _addr)
    public
    constant
    returns (bool)
  {
    return registeredAddress[_addr];
  }
  /**
   * @dev register the address for token sale
   * @param _addr address The address to register for token sale
   */
  function register(address _addr)
    public
    onlyAdmin
    whenNotPaused
  {
    require(_addr != address(0) && registeredAddress[_addr] == false);
    registeredAddress[_addr] = true;
    Registered(_addr);
  }
  /**
   * @dev register the addresses for token sale
   * @param _addrs address[] The addresses to register for token sale
   */
  function registerByList(address[] _addrs)
    public
    onlyAdmin
    whenNotPaused
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0) && registeredAddress[_addrs[i]] == false);
      registeredAddress[_addrs[i]] = true;
      Registered(_addrs[i]);
    }
  }
  /**
   * @dev unregister the registered address
   * @param _addr address The address to unregister for token sale
   */
  function unregister(address _addr)
    public
    onlyAdmin
    onlyRegistered(_addr)
  {
    registeredAddress[_addr] = false;
    Unregistered(_addr);
  }
  /**
   * @dev unregister the registered addresses
   * @param _addrs address[] The addresses to unregister for token sale
   */
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(isRegistered(_addrs[i]));
      registeredAddress[_addrs[i]] = false;
      Unregistered(_addrs[i]);
    }
  }
}
/**
 * @title PLCCrowdsale
 * @dev PLCCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract PLCCrowdsale is Ownable, SafeMath, Pausable {
  // token registery contract
  KYC public kyc;
  // The token being sold
  PLC public token;
  // start and end timestamps where investments are allowed (both inclusive)
  uint64 public startTime; // 1506384000; //2017.9.26 12:00 am (UTC)
  uint64 public endTime; // 1507593600; //2017.10.10 12:00 am (UTC)
  uint64[5] public deadlines; // [1506643200, 1506902400, 1507161600, 1507420800, 1507593600]; // [2017.9.26, 2017.10.02, 2017.10.05, 2017.10.08, 2017.10.10]
  mapping (address => uint256) public presaleRate;
  uint8[5] public rates = [240, 230, 220, 210, 200];
  // amount of raised money in wei
  uint256 public weiRaised;
  // amount of ether buyer can buy
  uint256 constant public maxGuaranteedLimit = 5000 ether;
  // amount of ether presale buyer can buy
  mapping (address => uint256) public presaleGuaranteedLimit;
  mapping (address => bool) public isDeferred;
  // amount of ether funded for each buyer
  // bool: true if deferred otherwise false
  mapping (bool => mapping (address => uint256)) public buyerFunded;
  // amount of tokens minted for deferredBuyers
  uint256 public deferredTotalTokens;
  // buyable interval in block number 20
  uint256 constant public maxCallFrequency = 20;
  // block number when buyer buy
  mapping (address => uint256) public lastCallBlock;
  bool public isFinalized = false;
  // minimum amount of funds to be raised in weis
  uint256 public maxEtherCap; // 100000 ether;
  uint256 public minEtherCap; // 30000 ether;
  // investor address list
  address[] buyerList;
  mapping (address => bool) inBuyerList;
  // number of refunded investors
  uint256 refundCompleted;
  // new owner of token contract when crowdsale is Finalized
  address newTokenOwner = 0x568E2B5e9643D38e6D8146FeE8d80a1350b2F1B9;
  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;
  // dev team multisig wallet
  address devMultisig;
  // reserve
  address[] reserveWallet;
  /**
   * @dev Checks whether buyer is sending transaction too frequently
   */
  modifier canBuyInBlock () {
    require(add(lastCallBlock[msg.sender], maxCallFrequency) < block.number);
    lastCallBlock[msg.sender] = block.number;
    _;
  }
  /**
   * @dev Checks whether ico is started
   */
  modifier onlyAfterStart() {
    require(now >= startTime && now <= endTime);
    _;
  }
  /**
   * @dev Checks whether ico is not started
   */
  modifier onlyBeforeStart() {
    require(now < startTime);
    _;
  }
  /**
   * @dev Checks whether the account is registered
   */
  modifier onlyRegistered(address _addr) {
    require(kyc.isRegistered(_addr));
    _;
  }
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event PresaleTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event DeferredPresaleTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  /**
   * event for finalize logging
   */
  event Finalized();
  /**
   * event for register presale logging
   * @param presaleInvestor who register for presale
   * @param presaleAmount weis presaleInvestor can buy as presale
   * @param _presaleRate rate at which presaleInvestor can buy tokens
   * @param _isDeferred whether the investor is deferred investor
   */
  event RegisterPresale(address indexed presaleInvestor, uint256 presaleAmount, uint256 _presaleRate, bool _isDeferred);
  /**
   * event for unregister presale logging
   * @param presaleInvestor who register for presale
   */
  event UnregisterPresale(address indexed presaleInvestor);
  /**
   * @dev PLCCrowdsale constructor sets variables
   * @param _kyc address The address which KYC contract is deployed at
   * @param _token address The address which PLC contract is deployed at
   * @param _refundVault address The address which RefundVault is deployed at
   * @param _devMultisig address The address which MultiSigWallet for devTeam is deployed at
   * @param _reserveWallet address[5] The address list of reserveWallet addresses
   * @param _timelines uint64[5] list of timelines from startTime to endTime with timelines for rate changes
   * @param _maxEtherCap uint256 The value which maximum weis to be funded
   * @param _minEtherCap uint256 The value which minimum weis to be funded
   */
  function PLCCrowdsale(
    address _kyc,
    address _token,
    address _refundVault,
    address _devMultisig,
    address[] _reserveWallet,
    uint64[6] _timelines, // [startTime, ... , endTime]
    uint256 _maxEtherCap,
    uint256 _minEtherCap)
  {
    //timelines check
    for(uint8 i = 0; i < _timelines.length-1; i++){
      require(_timelines[i] < _timelines[i+1]);
    }
    require(_timelines[0] >= now);
    //address check
    require(_kyc != 0x00 && _token != 0x00 && _refundVault != 0x00 && _devMultisig != 0x00);
    for(i = 0; i < _reserveWallet.length; i++){
      require(_reserveWallet[i] != 0x00);
    }
    //cap check
    require(_minEtherCap < _maxEtherCap);
    kyc   = KYC(_kyc);
    token = PLC(_token);
    vault = RefundVault(_refundVault);
    devMultisig   = _devMultisig;
    reserveWallet = _reserveWallet;
    startTime    = _timelines[0];
    endTime      = _timelines[5];
    deadlines[0] = _timelines[1];
    deadlines[1] = _timelines[2];
    deadlines[2] = _timelines[3];
    deadlines[3] = _timelines[4];
    deadlines[4] = _timelines[5];
    maxEtherCap  = _maxEtherCap;
    minEtherCap  = _minEtherCap;
  }
  /**
   * @dev PLCCrowdsale fallback function for buying Tokens
   */
  function () payable {
    if(isDeferred[msg.sender])
      buyDeferredPresaleTokens(msg.sender);
    else if(now < startTime)
      buyPresaleTokens(msg.sender);
    else
      buyTokens();
  }
  /**
   * @dev push all token buyers in list
   * @param _addr address Account to push into buyerList
   */
  function pushBuyerList(address _addr) internal {
    if (!inBuyerList[_addr]) {
      inBuyerList[_addr] = true;
      buyerList.push(_addr);
    }
  }
  /**
   * @dev register presale account checking modifier
   * @param presaleInvestor address The account to register as presale account
   * @param presaleAmount uint256 The value which investor is allowed to buy
   * @param _presaleRate uint256 The rate at which investor buy tokens
   * @param _isDeferred bool whether presaleInvestor is deferred buyer
   */
  function registerPresale(address presaleInvestor, uint256 presaleAmount, uint256 _presaleRate, bool _isDeferred)
    onlyBeforeStart
    onlyOwner
  {
    require(presaleInvestor != 0x00);
    require(presaleAmount > 0);
    require(_presaleRate > 0);
    require(presaleGuaranteedLimit[presaleInvestor] == 0);
    presaleGuaranteedLimit[presaleInvestor] = presaleAmount;
    presaleRate[presaleInvestor] = _presaleRate;
    isDeferred[presaleInvestor] = _isDeferred;
    if(_isDeferred) {
      weiRaised = add(weiRaised, presaleAmount);
      uint256 deferredInvestorToken = mul(presaleAmount, _presaleRate);
      uint256 deferredDevToken = div(mul(deferredInvestorToken, 20), 70);
      uint256 deferredReserveToken = div(mul(deferredInvestorToken, 10), 70);
      uint256 totalAmount = add(deferredInvestorToken, add(deferredDevToken, deferredReserveToken));
      token.mint(address(this), totalAmount);
      deferredTotalTokens = add(deferredTotalTokens, totalAmount);
    }
    RegisterPresale(presaleInvestor, presaleAmount, _presaleRate, _isDeferred);
  }
  /**
   * @dev register presale account checking modifier
   * @param presaleInvestor address The account to register as presale account
   */
  function unregisterPresale(address presaleInvestor)
    onlyBeforeStart
    onlyOwner
  {
    require(presaleInvestor != 0x00);
    require(presaleGuaranteedLimit[presaleInvestor] > 0);
    uint256 _amount = presaleGuaranteedLimit[presaleInvestor];
    uint256 _rate = presaleRate[presaleInvestor];
    bool _isDeferred = isDeferred[presaleInvestor];
    require(buyerFunded[_isDeferred][presaleInvestor] == 0);
    presaleGuaranteedLimit[presaleInvestor] = 0;
    presaleRate[presaleInvestor] = 0;
    isDeferred[presaleInvestor] = false;
    if(_isDeferred) {
      weiRaised = sub(weiRaised, _amount);
      uint256 deferredInvestorToken = mul(_amount, _rate);
      uint256 deferredDevToken = div(mul(deferredInvestorToken, 20), 70);
      uint256 deferredReserveToken = div(mul(deferredInvestorToken, 10), 70);
      uint256 totalAmount = add(deferredInvestorToken, add(deferredDevToken, deferredReserveToken));
      deferredTotalTokens = sub(deferredTotalTokens, totalAmount);
      token.burn(totalAmount);
    }
    UnregisterPresale(presaleInvestor);
  }
  /**
   * @dev buy token (deferred presale investor)
   * @param beneficiary address The account to receive tokens
   */
  function buyDeferredPresaleTokens(address beneficiary)
    payable
    whenNotPaused
  {
    require(beneficiary != 0x00);
    require(isDeferred[beneficiary]);
    uint guaranteedLimit = presaleGuaranteedLimit[beneficiary];
    require(guaranteedLimit > 0);
    uint256 weiAmount = msg.value;
    require(weiAmount != 0);
    uint256 totalAmount = add(buyerFunded[true][beneficiary], weiAmount);
    uint256 toFund;
    if (totalAmount > guaranteedLimit) {
      toFund = sub(guaranteedLimit, buyerFunded[true][beneficiary]);
    } else {
      toFund = weiAmount;
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, presaleRate[beneficiary]);
    uint256 toReturn = sub(weiAmount, toFund);
    buy(beneficiary, tokens, toFund, toReturn, true);
    // token distribution : 70% for sale, 20% for dev, 10% for reserve
    uint256 devAmount = div(mul(tokens, 20), 70);
    uint256 reserveAmount = div(mul(tokens, 10), 70);
    distributeToken(devAmount, reserveAmount, true);
    // ether distribution : 10% for dev, 90% for reserve
    uint256 devEtherAmount = div(toFund, 10);
    uint256 reserveEtherAmount = div(mul(toFund, 9), 10);
    distributeEther(devEtherAmount, reserveEtherAmount);
    DeferredPresaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
  /**
   * @dev buy token (normal presale investor)
   * @param beneficiary address The account to receive tokens
   */
  function buyPresaleTokens(address beneficiary)
    payable
    whenNotPaused
    onlyBeforeStart
  {
    // check validity
    require(beneficiary != 0x00);
    require(validPurchase());
    require(!isDeferred[beneficiary]);
    uint guaranteedLimit = presaleGuaranteedLimit[beneficiary];
    require(guaranteedLimit > 0);
    // calculate eth amount
    uint256 weiAmount = msg.value;
    uint256 totalAmount = add(buyerFunded[false][beneficiary], weiAmount);
    uint256 toFund;
    if (totalAmount > guaranteedLimit) {
      toFund = sub(guaranteedLimit, buyerFunded[false][beneficiary]);
    } else {
      toFund = weiAmount;
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, presaleRate[beneficiary]);
    uint256 toReturn = sub(weiAmount, toFund);
    buy(beneficiary, tokens, toFund, toReturn, false);
    forwardFunds(toFund);
    PresaleTokenPurchase(msg.sender, beneficiary, toFund, tokens);
  }
  /**
   * @dev buy token (normal investors)
   */
  function buyTokens()
    payable
    whenNotPaused
    canBuyInBlock
    onlyAfterStart
    onlyRegistered(msg.sender)
  {
    // check validity
    require(validPurchase());
    require(buyerFunded[false][msg.sender] < maxGuaranteedLimit);
    // calculate eth amount
    uint256 weiAmount = msg.value;
    uint256 totalAmount = add(buyerFunded[false][msg.sender], weiAmount);
    uint256 toFund;
    if (totalAmount > maxGuaranteedLimit) {
      toFund = sub(maxGuaranteedLimit, buyerFunded[false][msg.sender]);
    } else {
      toFund = weiAmount;
    }
    if(add(weiRaised,toFund) > maxEtherCap) {
      toFund = sub(maxEtherCap, weiRaised);
    }
    require(toFund > 0);
    require(weiAmount >= toFund);
    uint256 tokens = mul(toFund, getRate());
    uint256 toReturn = sub(weiAmount, toFund);
    buy(msg.sender, tokens, toFund, toReturn, false);
    forwardFunds(toFund);
    TokenPurchase(msg.sender, msg.sender, toFund, tokens);
  }
  /**
   * @dev get buy rate for now
   * @return rate uint256 rate for now
   */
  function getRate() constant returns (uint256 rate) {
    for(uint8 i = 0; i < deadlines.length; i++)
      if(now < deadlines[i])
        return rates[i];
      return rates[rates.length-1];//should never be returned, but to be sure to not divide by 0
  }
  /**
   * @dev get the number of buyers
   * @return uint256 the number of buyers
   */
  function getBuyerNumber() constant returns (uint256) {
    return buyerList.length;
  }
  /**
   * @dev send ether to the fund collection wallet
   * @param toFund uint256 The value of weis to send to vault
   */
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }
  /**
   * @dev checks whether purchase value is not zero and maxEtherCap is not reached
   * @return true if the transaction can buy tokens
   */
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase && !maxReached();
  }
  function buy(
    address _beneficiary,
    uint256 _tokens,
    uint256 _toFund,
    uint256 _toReturn,
    bool _isDeferred)
    internal
  {
    if (!_isDeferred) {
      pushBuyerList(msg.sender);
      weiRaised = add(weiRaised, _toFund);
    }
    buyerFunded[_isDeferred][_beneficiary] = add(buyerFunded[_isDeferred][_beneficiary], _toFund);
    if (!_isDeferred) {
      token.mint(address(this), _tokens);
    }
    // 1 week lock
    token.grantVestedTokens(
      _beneficiary,
      _tokens,
      uint64(endTime),
      uint64(endTime + 1 weeks),
      uint64(endTime + 1 weeks),
      false,
      false);
    // return ether if needed
    if (_toReturn > 0) {
      msg.sender.transfer(_toReturn);
    }
  }
  /**
   * @dev distribute token to multisig wallet and reserve walletes.
   * This function is called in two context where crowdsale is closing and
   * deferred token is bought.
   * @param devAmount uint256 token amount for dev multisig wallet
   * @param reserveAmount uint256 token amount for reserve walletes
   * @param _isDeferred bool check whether function is called when deferred token is sold
   */
  function distributeToken(uint256 devAmount, uint256 reserveAmount, bool _isDeferred) internal {
    uint256 eachReserveAmount = div(reserveAmount, reserveWallet.length);
    token.grantVestedTokens(
      devMultisig,
      devAmount,
      uint64(endTime),
      uint64(endTime),
      uint64(endTime + 1 years),
      false,
      false);
    if (_isDeferred) {
      for(uint8 i = 0; i < reserveWallet.length; i++) {
        token.transfer(reserveWallet[i], eachReserveAmount);
      }
    } else {
      for(uint8 j = 0; j < reserveWallet.length; j++) {
        token.mint(reserveWallet[j], eachReserveAmount);
      }
    }
  }
  /**
   * @dev distribute ether to multisig wallet and reserve walletes
   * @param devAmount uint256 ether amount for dev multisig wallet
   * @param reserveAmount uint256 ether amount for reserve walletes
   */
  function distributeEther(uint256 devAmount, uint256 reserveAmount) internal {
    uint256 eachReserveAmount = div(reserveAmount, reserveWallet.length);
    devMultisig.transfer(devAmount);
    for(uint8 i = 0; i < reserveWallet.length; i++){
      reserveWallet[i].transfer(eachReserveAmount);
    }
  }
  /**
   * @dev checks whether crowdsale is ended
   * @return true if crowdsale event has ended
   */
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  /**
   * @dev should be called after crowdsale ends, to do
   */
  function finalize() {
    require(!isFinalized);
    require(hasEnded() || maxReached());
    finalization();
    Finalized();
    isFinalized = true;
  }
  /**
   * @dev end token minting on finalization, mint tokens for dev team and reserve wallets
   */
  function finalization() internal {
    if (minReached()) {
      vault.close();
      uint256 totalToken = token.totalSupply();
      uint256 tokenSold = sub(totalToken, deferredTotalTokens);
      // token distribution : 70% for sale, 20% for dev, 10% for reserve
      uint256 devAmount = div(mul(tokenSold, 20), 70);
      uint256 reserveAmount = div(mul(tokenSold, 10), 70);
      token.mint(address(this), devAmount);
      distributeToken(devAmount, reserveAmount, false);
    } else {
      vault.enableRefunds();
    }
    token.finishMinting();
    token.transferOwnership(newTokenOwner);
  }
  /**
   * @dev should be called when ethereum is forked during crowdsale for refunding ethers on not supported fork
   */
  function finalizeWhenForked() onlyOwner whenPaused {
    require(!isFinalized);
    isFinalized = true;
    vault.enableRefunds();
    token.finishMinting();
  }
  /**
   * @dev refund a lot of investors at a time checking onlyOwner
   * @param numToRefund uint256 The number of investors to refund
   */
  function refundAll(uint256 numToRefund) onlyOwner {
    require(isFinalized);
    require(!minReached());
    require(numToRefund > 0);
    uint256 limit = refundCompleted + numToRefund;
    if (limit > buyerList.length) {
      limit = buyerList.length;
    }
    for(uint256 i = refundCompleted; i < limit; i++) {
      vault.refund(buyerList[i]);
    }
    refundCompleted = limit;
  }
  /**
   * @dev if crowdsale is unsuccessful, investors can claim refunds here
   * @param investor address The account to be refunded
   */
  function claimRefund(address investor) returns (bool) {
    require(isFinalized);
    require(!minReached());
    return vault.refund(investor);
  }
  /**
   * @dev Checks whether maxEtherCap is reached
   * @return true if max ether cap is reaced
   */
  function maxReached() public constant returns (bool) {
    return weiRaised == maxEtherCap;
  }
  /**
   * @dev Checks whether minEtherCap is reached
   * @return true if min ether cap is reaced
   */
  function minReached() public constant returns (bool) {
    return weiRaised >= minEtherCap;
  }
  /**
   * @dev should burn unpaid tokens of deferred presale investors
   */
  function burnUnpaidTokens()
    onlyOwner
  {
    require(isFinalized);
    uint256 unpaidTokens = token.balanceOf(address(this));
    token.burn(unpaidTokens);
  }
}