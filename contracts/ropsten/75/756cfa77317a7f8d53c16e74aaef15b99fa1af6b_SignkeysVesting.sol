pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
  * @param owner The address to query the balance of.
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
    _transfer(msg.sender, to, value);
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
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

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

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

// File: contracts/SignkeysToken.sol

contract SignkeysToken is ERC20Pausable, ERC20Detailed, Ownable {

    uint8 public constant DECIMALS = 18;

    uint256 public constant INITIAL_SUPPLY = 2E10 * (10 ** uint256(DECIMALS));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20Detailed("SignkeysToken", "KEYS", DECIMALS) {
        _mint(owner(), INITIAL_SUPPLY);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool success) {
        require(_spender != address(this));
        require(super.approve(_spender, _value));
        require(_spender.call(_data));
        return true;
    }

    function() payable external {
        revert();
    }
}

contract SignkeysReferralSmartContract is Ownable {
    using SafeMath for uint256;

    /* Token contract */
    SignkeysToken token;

    /* Crowdsale contract */
    SignkeysCrowdsale signkeysCrowdsale;

    uint256[] public buyingAmountRanges = [199, 1000, 10000, 100000, 1000000, 10000000];
    uint256[] public referrerRewards = [5, 50, 500, 5000, 50000];
    uint256[] public refereeRewards = [5, 50, 500, 5000, 50000];

    event BonusSent(
        address indexed referrerAddress,
        uint256 referrerAmount,
        address indexed refereeAddress,
        uint256 refereeAmount
    );

    constructor(address _token) public {
        token = SignkeysToken(_token);
    }

    function setCrowdsaleContract(address _crowdsale) public {
        signkeysCrowdsale = SignkeysCrowdsale(_crowdsale);
    }

    function calcBonus(uint256 amount, bool isReferrer) private view returns (uint256) {
        uint256 multiplier = 10 ** uint256(token.decimals());
        if (amount < multiplier.mul(buyingAmountRanges[0])) {
            return 0;
        }
        for (uint i = 1; i < buyingAmountRanges.length; i++) {
            uint min = buyingAmountRanges[i - 1];
            uint max = buyingAmountRanges[i];
            if (amount > min.mul(multiplier) && amount <= max.mul(multiplier)) {
                return isReferrer ? multiplier.mul(referrerRewards[i - 1]) : multiplier.mul(refereeRewards[i - 1]);
            }
        }
    }

    function sendBonus(address referrer, address referee, uint256 _amount) external returns (uint256)  {
        require(msg.sender == address(signkeysCrowdsale), "Bonus may be sent only by crowdsale contract");

        uint256 referrerBonus;
        uint256 refereeBonus;

        uint256 referrerBonusAmount = calcBonus(_amount, true);
        uint256 refereeBonusAmount = calcBonus(_amount, false);

        if (token.balanceOf(this) > referrerBonusAmount) {
            token.transfer(referrer, referrerBonusAmount);
            referrerBonus = referrerBonusAmount;
        } else {
            referrerBonus = 0;
        }

        if (token.balanceOf(this) > refereeBonusAmount) {
            token.transfer(referee, refereeBonusAmount);
            refereeBonus = refereeBonusAmount;
        } else {
            refereeBonus = 0;
        }

        emit BonusSent(referrer, referrerBonus, referee, refereeBonus);
    }

    function getBuyingAmountRanges() public onlyOwner view returns (uint256[]) {
        return buyingAmountRanges;
    }

    function getReferrerRewards() public onlyOwner view returns (uint256[]) {
        return referrerRewards;
    }

    function getRefereeRewards() public onlyOwner view returns (uint256[]) {
        return refereeRewards;
    }

    function setBuyingAmountRanges(uint[] ranges) public onlyOwner {
        buyingAmountRanges = ranges;
    }

    function setReferrerRewards(uint[] rewards) public onlyOwner {
        require(rewards.length == buyingAmountRanges.length - 1);
        referrerRewards = rewards;
    }

    function setRefereeRewards(uint[] rewards) public onlyOwner {
        require(rewards.length == buyingAmountRanges.length - 1);
        refereeRewards = rewards;
    }
}

pragma solidity ^0.4.24;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9ceef9f1fff3dcae">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="82e3eee7fae7fbc2efebfae0fbf6e7f1acebed">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  constructor() internal {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}


contract SignkeysCrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /* Token contract */
    SignkeysToken signkeysToken;

    /* Vesting contract */
    SignkeysVesting signkeysVesting;

    /* Referral smart contract*/
    SignkeysReferralSmartContract referralSmartContract;

    /* signer address, can be set by owner only */
    address public signer;

    /* ETH funds will be transferred to this address */
    address public wallet;

    // Buyer bought the amount of tokens with tokenPrice
    event BuyTokens(
        address indexed buyer,
        address indexed tokenReceiver,
        uint256 tokenPrice,
        uint256 amount,
        uint256 indexed customerId
    );

    // Crowdsale start time has been changed
    event StartsAtChanged(uint newStartsAtUTC);

    // Crowdsale end time has been changed
    event EndsAtChanged(uint newEndsAtUTC);

    // Wallet changed
    event WalletChanged(address newWallet);

    // Signer changed
    event CrowdsaleSignerChanged(address newSigner);

    constructor(
        address _token,
        address _vesting,
        address _referralSmartContract,
        address _wallet,
        address _signer
    ) public {
        require(_token != 0x0, "Token contract for crowdsale must be set");
        require(_vesting != 0x0, "Vesting contract for crowdsale must be set");
        require(_referralSmartContract != 0x0, "Referral smart contract for crowdsale must be set");

        require(_wallet != 0x0, "Wallet for fund transferring must be set");
        require(_signer != 0x0, "Signer must be set");

        signkeysToken = SignkeysToken(_token);
        signkeysVesting = SignkeysVesting(_vesting);
        referralSmartContract = SignkeysReferralSmartContract(_referralSmartContract);

        signer = _signer;
        wallet = _wallet;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        signer = _signer;
        emit CrowdsaleSignerChanged(_signer);
    }

    function setWalletAddress(address _wallet) external onlyOwner {
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

    function setVestingContract(address _vesting) external onlyOwner {
        signkeysVesting = SignkeysVesting(_vesting);
    }

    function setReferralSmartContract(address _referralSmartContract) external onlyOwner {
        referralSmartContract = SignkeysReferralSmartContract(_referralSmartContract);
    }

    function getRemainingTokensToSell() external view returns (uint256) {
        return signkeysToken.balanceOf(this);
    }

    /**
     * @dev Make an investment.
     *
     * @param _tokenPrice price per one token including decimals
     * @param _minWei minimal amount of wei buyer should invest
     * @param _customerId customer id on server to track the transactions
     * @param _expiration expiration on token
     */
    function buyTokens(
        address tokenReceiver,
        address referral,
        uint256 _tokenPrice,
        uint256 _minWei,
        uint256 _customerId,
        uint256 _expiration,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) payable external nonReentrant {
        require(_expiration >= now, "Signature expired");
        require(_customerId != 0, "Customer id must be defined to track the transactions");
        require(_minWei > 0, "Minimal amount to purchase must be greater than 0");

        require(msg.value >= _minWei, "Purchased amount is less than min amount to invest");

        address receivedSigner = ecrecover(
            keccak256(
                abi.encodePacked(
                    _tokenPrice, _minWei, _customerId, _expiration
                )
            ), _v, _r, _s);

        require(receivedSigner == signer, "Something wrong with signature");

        uint256 tokensAmount = msg.value.mul(10 ** uint256(signkeysToken.decimals())).div(_tokenPrice);
        require(signkeysToken.balanceOf(this) >= tokensAmount, "Not enough tokens in sale contract");
        uint256 amountForVesting = tokensAmount.mul(signkeysVesting.percentageToLock()).div(100);

        signkeysToken.transfer(tokenReceiver, tokensAmount.sub(amountForVesting));
        signkeysToken.approve(address(signkeysVesting), amountForVesting);
        signkeysVesting.lock(tokenReceiver, amountForVesting);

        if (referral != 0x0) {
            // send bonuses according to referral smart contract
            referralSmartContract.sendBonus(referral, tokenReceiver, tokensAmount);
        }

        // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our wallet
        if (wallet == 0x0 || !wallet.send(msg.value)) {
            revert();
        }

        emit BuyTokens(msg.sender, tokenReceiver, _tokenPrice, tokensAmount, _customerId);
    }

    /**
     * Don&#39;t expect to just send in money and get tokens.
     */
    function() payable external {
        revert();
    }
}

pragma solidity ^0.4.24;

contract SignkeysVesting is Ownable {
    using SafeMath for uint256;

    uint256 public INITIAL_VESTING_CLIFF_SECONDS = 180 days;
    uint256 public INITIAL_PERCENTAGE_TO_LOCK = 50; // 50%

    // The token to which we add the vesting restrictions
    SignkeysToken public signkeysToken;

    // Crowdsale contract
    SignkeysCrowdsale public signkeysCrowdsale;

    // the start date of crowdsale
    uint public vestingStartDateTime;

    // the date after which user is able to sell all his tokens
    uint public vestingCliffDateTime;

    // the percentage of tokens to lock immediately after buying
    uint256 public percentageToLock;

    /* The amount of locked tokens for each user */
    mapping(address => uint256) private _balances;

    event TokensLocked(address indexed user, uint amount);
    event TokensReleased(address indexed user, uint amount);

    constructor() public{
        vestingStartDateTime = now;
        vestingCliffDateTime = SafeMath.add(now, INITIAL_VESTING_CLIFF_SECONDS);
        percentageToLock = INITIAL_PERCENTAGE_TO_LOCK;
    }

    function setToken(address token) external onlyOwner {
        signkeysToken = SignkeysToken(token);
    }

    function setCrowdsaleContract(address crowdsaleContract) external onlyOwner {
        signkeysCrowdsale = SignkeysCrowdsale(crowdsaleContract);
    }

    function balanceOf(address tokenHolder) external view returns (uint256) {
        return _balances[tokenHolder];
    }

    function lock(address _user, uint256 _amount) external returns (uint256)  {
        require(msg.sender == address(signkeysCrowdsale), "Tokens may be locked only by crowdsale contract");
        require(signkeysToken.balanceOf(_user) >= _amount, "User balance is less than the requested size");

        signkeysToken.transferFrom(msg.sender, this, _amount);

        _balances[_user] = _balances[_user].add(_amount);

        emit TokensLocked(_user, _amount);

        return _balances[_user];
    }

    /**
     * @notice Transfers vested tokens back to user.
     * @param _user user that asks to release his tokens
     */
    function release(address _user) private {
        require(vestingCliffDateTime <= now, "Cannot release vested tokens until vesting cliff date");
        uint256 unreleased = _balances[_user];

        if (unreleased > 0) {
            signkeysToken.transfer(_user, unreleased);
            _balances[_user] = _balances[_user].sub(unreleased);
        }

        emit TokensReleased(_user, unreleased);
    }

    function release() public {
        release(msg.sender);
    }

    function setVestingStartDateTime(uint _vestingStartDateTime) external onlyOwner {
        require(_vestingStartDateTime <= vestingCliffDateTime, "Start date should be less or equal than cliff date");
        vestingStartDateTime = _vestingStartDateTime;
    }

    function setVestingCliffDateTime(uint _vestingCliffDateTime) external onlyOwner {
        require(vestingStartDateTime <= _vestingCliffDateTime, "Cliff date should be greater or equal than start date");
        vestingCliffDateTime = _vestingCliffDateTime;
    }

    function setPercentageToLock(uint256 percentage) external onlyOwner {
        require(percentage >= 0 && percentage <= 100, "Percentage must be in range [0, 100]");
        percentageToLock = percentage;
    }


}