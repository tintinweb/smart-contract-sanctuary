pragma solidity ^0.4.25;
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract CapperRole {
  using Roles for Roles.Role;

  event CapperAdded(address indexed account);
  event CapperRemoved(address indexed account);

  Roles.Role private cappers;

  constructor() public {
    cappers.add(msg.sender);
  }

  modifier onlyCapper() {
    require(isCapper(msg.sender));
    _;
  }

  function isCapper(address account) public view returns (bool) {
    return cappers.has(account);
  }

  function addCapper(address account) public onlyCapper {
    cappers.add(account);
    emit CapperAdded(account);
  }

  function renounceCapper() public {
    cappers.remove(msg.sender);
  }

  function _removeCapper(address account) internal {
    cappers.remove(account);
    emit CapperRemoved(account);
  }
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}

contract ERC20Mintable is ERC20, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // Address where funds are collected
  address private _wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 private _rate;

  // Amount of wei raised
  uint256 private _weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param rate Number of token units a buyer gets per wei
   * @dev The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   * @param wallet Address where collected funds will be forwarded to
   * @param token Address of the token being sold
   */
  constructor(uint256 rate, address wallet, IERC20 token) public {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @return the token being sold.
   */
  function token() public view returns(IERC20) {
    return _token;
  }

  /**
   * @return the address where funds are collected.
   */
  function wallet() public view returns(address) {
    return _wallet;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function rate() public view returns(uint256) {
    return _rate;
  }

  /**
   * @return the mount of wei raised.
   */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param beneficiary Address performing the token purchase
   */
  function buyTokens(address beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
   *   super._preValidatePurchase(beneficiary, weiAmount);
   *   require(weiRaised().add(weiAmount) <= cap);
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param beneficiary Address receiving the tokens
   * @param weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _openingTime;
  uint256 private _closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen());
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param openingTime Crowdsale opening time
   * @param closingTime Crowdsale closing time
   */
  constructor(uint256 openingTime, uint256 closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(openingTime >= block.timestamp);
    require(closingTime >= openingTime);

    _openingTime = openingTime;
    _closingTime = closingTime;
  }

  /**
   * @return the crowdsale opening time.
   */
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

  /**
   * @return the crowdsale closing time.
   */
  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

  /**
   * @return true if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > _closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param beneficiary Token purchaser
   * @param tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    // Potentially dangerous assumption about the type of the token.
    require(
      ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param cap Max amount of wei to be contributed
   */
  constructor(uint256 cap) public {
    require(cap > 0);
    _cap = cap;
  }

  /**
   * @return the cap of the crowdsale.
   */
  function cap() public view returns(uint256) {
    return _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised() >= _cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    super._preValidatePurchase(beneficiary, weiAmount);
    require(weiRaised().add(weiAmount) <= _cap);
  }

}

contract BoltCrowdsaleTwo is Crowdsale, CappedCrowdsale, TimedCrowdsale, CapperRole {
  using SafeMath for uint256;

  // Individual contribution amounts and caps
  mapping(address => uint256) private _contributions;
  mapping(address => uint256) private _caps;

  // Bonus tokens locked in this contract
  mapping(address => uint256) private _lockedTokens;
  uint256 private _bonusAvailableUntil;
  uint256 private _bonusUnlockTime;

  constructor(
      uint256 rate,               // rate, in BOLTbits to wei
      address wallet,             // wallet to send Ether to
      ERC20 token,                // the token
      uint256 cap,                // total cap, in wei
      uint256 openingTime,        // opening time in unix epoch seconds
      uint256 closingTime,        // closing time in unix epoch seconds
      uint256 bonusUnlockTime,    // unlocking time for bonus tokens in unix epoch seconds
      uint256 bonusAvailableUntil // cutoff time for bonus tokens to be issued when minting
  )
      CapperRole()
      TimedCrowdsale(openingTime, closingTime)
      CappedCrowdsale(cap)
      Crowdsale(rate, wallet, token)
      public
  {
    require(
      bonusUnlockTime > closingTime,
      "Cannot unlock bonus tokens before crowdsale ends"
    );

    require(
      bonusAvailableUntil >= openingTime && bonusAvailableUntil <= closingTime,
      "Cannot unlock bonus tokens before crowdsale ends"
    );

    _bonusUnlockTime = bonusUnlockTime;
    _bonusAvailableUntil = bonusAvailableUntil;
  }

  /**
   * @dev Checks whether bonus is currently available.
   * @return Returns whether bonus tokens are available
   */
  function _isBonusAvailable()
    private
    view
    returns (bool)
  {
    // solium-disable-next-line security/no-block-members
    return block.timestamp <= _bonusAvailableUntil;
  }

  /**
   * @dev Overrides the way in which ether to tokens conversion calculation to give bonus tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount)
    internal
    view
    returns (uint256)
  {
    uint256 baseTokenAmount = weiAmount.mul(rate());
    uint256 bonusAmount = _isBonusAvailable() ?
      baseTokenAmount.div(5) : // 20% bonus
      0;

    return baseTokenAmount + bonusAmount;
  }

  /**
    * @dev Overrides delivery by minting tokens upon purchase.
    * @param beneficiary Token purchaser
    * @param tokenAmount Number of tokens to be minted
    */
  function _deliverTokens(address beneficiary, uint256 tokenAmount)
    internal
  {
    uint256 baseAmount = _isBonusAvailable() ?
      tokenAmount.div(6).mul(5) : // 20% total, may be slightly inaccurate, but doesn&#39;t matter
      0;
    uint256 lockedBonusAmount = tokenAmount.sub(baseAmount);

    require(
      ERC20Mintable(address(token())).mint(beneficiary, baseAmount),
      "Could not mint tokens to beneficiary."
    );

    if (lockedBonusAmount > 0) {
      require(
        ERC20Mintable(address(token())).mint(this, lockedBonusAmount),
        "Could not mint tokens to self for lockup."
      );
      _lockedTokens[beneficiary] = _lockedTokens[beneficiary].add(lockedBonusAmount);
    }
  }

  /**
   * @dev Gets the amount of locked bonus tokens for the beneficiary.
   * @param beneficiary Address whose locked bonus token balance is to be checked
   * @return Current locked bonus token balance for individual beneficiary
   */
  function getLockedTokens(address beneficiary)
    public
    view
    returns (uint256)
  {
    return _lockedTokens[beneficiary];
  }

  /**
    * @dev Deliver bonus tokens that were previously locked during purchase to multiple beneficiaries.
    * @param beneficiaries Token purchaser
    */
  function deliverBonusTokens(address[] beneficiaries)
    external
  {
    require(
      // solium-disable-next-line security/no-block-members
      _bonusUnlockTime <= block.timestamp,
      "Tokens are not yet unlocked."
    );

    for (uint8 i = 0; i < beneficiaries.length && i < 255; i ++) {
      _deliverBonusTokens(beneficiaries[i]);
    }
  }

  /**
    * @dev Deliver bonus tokens that were previously locked during purchase to a single beneficiary .
    * @param beneficiary Token purchaser
    */
  function _deliverBonusTokens(address beneficiary)
    private
  {
    require(
      _lockedTokens[beneficiary] > 0,
      "No tokens to unlock."
    );

    _lockedTokens[beneficiary] = 0;

    require(
      ERC20(address(token())).transfer(beneficiary, _lockedTokens[beneficiary]),
      "Could not transfer tokens."
    );
  }

  /**
   * @dev Sets multiple beneficiary&#39;s maximum contribution.
   * @param beneficiaries Address to be capped
   * @param caps Wei limit for each addresses contribution
   */
  function setCaps(address[] beneficiaries, uint256[] caps)
    external
    onlyCapper
  {
    for (uint8 i = 0; i < beneficiaries.length && i < 255; i ++) {
      _caps[beneficiaries[i]] = caps[i];
    }
  }

  /**
   * @dev Sets a specific beneficiary&#39;s maximum contribution.
   * @param beneficiary Address to be capped
   * @param cap Wei limit for individual contribution
   */
  function setCap(address beneficiary, uint256 cap)
    external
    onlyCapper
  {
    _caps[beneficiary] = cap;
  }

  /**
   * @dev Returns the cap of a specific beneficiary.
   * @param beneficiary Address whose cap is to be checked
   * @return Current cap for individual beneficiary
   */
  function getCap(address beneficiary)
    public
    view
    returns (uint256)
  {
    return _caps[beneficiary];
  }

  /**
   * @dev Returns the amount contributed so far by a specific beneficiary.
   * @param beneficiary Address of contributor
   * @return Beneficiary contribution so far
   */
  function getContribution(address beneficiary)
    public
    view
    returns (uint256)
  {
    return _contributions[beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the beneficiary&#39;s funding cap.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    super._preValidatePurchase(beneficiary, weiAmount);
    require(
      _contributions[beneficiary].add(weiAmount) <= _caps[beneficiary],
      "Contribution cap exceeded."
    );
  }

  /**
   * @dev Extend parent behavior to update beneficiary contributions
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    super._updatePurchasingState(beneficiary, weiAmount);
    _contributions[beneficiary] = _contributions[beneficiary].add(
      weiAmount);
  }
}