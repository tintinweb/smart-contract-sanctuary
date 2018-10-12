pragma solidity 0.4.24;

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

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {

  /**
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The address which you want to send tokens from
   * @param value uint256 The amount of token to be burned
   */
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }

  /**
   * @dev Overrides ERC20._burn in order for burn and burnFrom to emit
   * an additional Burn event.
   */
  function _burn(address who, uint256 value) internal {
    super._burn(who, value);
  }
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

// File: contracts/robonomics/XRT.sol

contract XRT is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    constructor() public ERC20Detailed("XRT", "Robonomics Beta", 9) {
        uint256 INITIAL_SUPPLY = 1000 * (10 ** 9);
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

// File: contracts/robonomics/RobotLiabilityAPI.sol

//import &#39;./LiabilityFactory.sol&#39;;


contract RobotLiabilityAPI {
    bytes   public model;
    bytes   public objective;
    bytes   public result;

    ERC20   public token;
    uint256 public cost;
    uint256 public lighthouseFee;
    uint256 public validatorFee;

    bytes32 public demandHash;
    bytes32 public offerHash;

    address public promisor;
    address public promisee;
    address public validator;

    bool    public isSuccess;
    bool    public isFinalized;

    LiabilityFactory public factory;

    event Finalized(bool indexed success, bytes result);
}

// File: contracts/robonomics/LightContract.sol

contract LightContract {
    /**
     * @dev Shared code smart contract 
     */
    address lib;

    constructor(address _library) public {
        lib = _library;
    }

    function() public {
        require(lib.delegatecall(msg.data));
    }
}

// File: contracts/robonomics/RobotLiability.sol

// Standard robot liability light contract
contract RobotLiability is RobotLiabilityAPI, LightContract {
    constructor(address _lib) public LightContract(_lib)
    { factory = LiabilityFactory(msg.sender); }
}

// File: contracts/robonomics/SingletonHash.sol

contract SingletonHash {
    event HashConsumed(bytes32 indexed hash);

    /**
     * @dev Used hash accounting
     */
    mapping(bytes32 => bool) public isHashConsumed;

    /**
     * @dev Parameter can be used only once
     * @param _hash Single usage hash
     */
    function singletonHash(bytes32 _hash) internal {
        require(!isHashConsumed[_hash]);
        isHashConsumed[_hash] = true;
        emit HashConsumed(_hash);
    }
}

// File: contracts/robonomics/DutchAuction.sol

/// @title Dutch auction contract - distribution of XRT tokens using an auction.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7102051417101f5f16141e03161431121e1f02141f0208025f1f1405">[email&#160;protected]</a>>
/// @author Airalab - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c2b0a7b1a7a3b0a1aa82a3abb0a3ecaeaba4a7">[email&#160;protected]</a>> 
contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public MAX_TOKENS_SOLD = 800 * 10**9; // 8M XRT = 10M - 1M (Foundation) - 1M (Early investors base)
    uint constant public WAITING_PERIOD = 0; // 1 days;

    /*
     *  Storage
     */
    XRT     public xrt;
    address public ambix;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        // Contract on stage
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        // Only owner is allowed to proceed
        require(msg.sender == owner);
        _;
    }

    modifier isWallet() {
        // Only wallet is allowed to proceed
        require(msg.sender == wallet);
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets owner.
    /// @param _wallet Multisig wallet.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction price factor.
    constructor(address _wallet, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != 0 && _ceiling > 0 && _priceFactor > 0);

        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts&#39; addresses.
    /// @param _xrt Robonomics token address.
    /// @param _ambix Distillation cube address.
    function setup(address _xrt, address _ambix)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        // Validate argument
        require(_xrt != 0 && _ambix != 0);

        xrt = XRT(_xrt);
        ambix = _ambix;

        // Validate token balance
        require(xrt.balanceOf(this) == MAX_TOKENS_SOLD);

        stage = Stages.AuctionSetUp;
    }

    /// @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;

        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        if (receiver == 0)
            receiver = msg.sender;

        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxWei = MAX_TOKENS_SOLD * calcTokenPrice() / 10**9 - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;

        // Only invest maximum possible amount.
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            receiver.transfer(msg.value - amount);
        }

        // Forward funding to ether wallet
        wallet.transfer(amount);

        bids[receiver] += amount;
        totalReceived += amount;
        emit BidSubmission(receiver, amount);

        // Finalize auction when maxWei reached
        if (amount == maxWei)
            finalizeAuction();
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**9 / finalPrice;
        bids[receiver] = 0;
        require(xrt.transfer(receiver, tokenCount));
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        view
        public
        returns (uint)
    {
        return totalReceived * 10**9 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        view
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        finalPrice = totalReceived == ceiling ? calcTokenPrice() : calcStopPrice();
        uint soldTokens = totalReceived * 10**9 / finalPrice;

        if (totalReceived == ceiling) {
            // Auction contract transfers all unsold tokens to Ambix contract
            require(xrt.transfer(ambix, MAX_TOKENS_SOLD - soldTokens));
        } else {
            // Auction contract burn all unsold tokens
            xrt.burn(MAX_TOKENS_SOLD - soldTokens);
        }

        endTime = now;
    }
}

// File: contracts/robonomics/LighthouseAPI.sol

//import &#39;./LiabilityFactory.sol&#39;;


contract LighthouseAPI {
    address[] public members;

    function membersLength() public view returns (uint256)
    { return members.length; }

    mapping(address => uint256) indexOf;

    mapping(address => uint256) public balances;

    uint256 public minimalFreeze;
    uint256 public timeoutBlocks;

    LiabilityFactory public factory;
    XRT              public xrt;

    uint256 public keepaliveBlock = 0;
    uint256 public marker = 0;
    uint256 public quota = 0;

    function quotaOf(address _member) public view returns (uint256)
    { return balances[_member] / minimalFreeze; }
}

// File: contracts/robonomics/Lighthouse.sol

contract Lighthouse is LighthouseAPI, LightContract {
    constructor(
        address _lib,
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks
    ) 
        public
        LightContract(_lib)
    {
        require(_minimalFreeze > 0 && _timeoutBlocks > 0);

        minimalFreeze = _minimalFreeze;
        timeoutBlocks = _timeoutBlocks;
        factory = LiabilityFactory(msg.sender);
        xrt = factory.xrt();
    }
}

// File: ens/contracts/AbstractENS.sol

contract AbstractENS {
    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

// File: ens/contracts/ENS.sol

/**
 * The ENS registry contract.
 */
contract ENS is AbstractENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

    // Permits modifications only by the owner of the specified node.
    modifier only_owner(bytes32 node) {
        if(records[node].owner != msg.sender) throw;
        _;
    }

    /**
     * Constructs a new ENS registrar.
     */
    function ENS() {
        records[0].owner = msg.sender;
    }

    /**
     * Returns the address that owns the specified node.
     */
    function owner(bytes32 node) constant returns (address) {
        return records[node].owner;
    }

    /**
     * Returns the address of the resolver for the specified node.
     */
    function resolver(bytes32 node) constant returns (address) {
        return records[node].resolver;
    }

    /**
     * Returns the TTL of a node, and any records associated with it.
     */
    function ttl(bytes32 node) constant returns (uint64) {
        return records[node].ttl;
    }

    /**
     * Transfers ownership of a node to a new address. May only be called by the current
     * owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

    /**
     * Transfers ownership of a subnode sha3(node, label) to a new address. May only be
     * called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = sha3(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

    /**
     * Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /**
     * Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

// File: ens/contracts/PublicResolver.sol

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver {
    AbstractENS ens;
    mapping(bytes32=>address) addresses;
    mapping(bytes32=>bytes32) hashes;

    modifier only_owner(bytes32 node) {
        if(ens.owner(node) != msg.sender) throw;
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    function PublicResolver(AbstractENS ensAddr) {
        ens = ensAddr;
    }

    /**
     * Fallback function.
     */
    function() {
        throw;
    }

    /**
     * Returns true if the specified node has the specified record type.
     * @param node The ENS node to query.
     * @param kind The record type name, as specified in EIP137.
     * @return True if this resolver has a record of the provided type on the
     *         provided node.
     */
    function has(bytes32 node, bytes32 kind) constant returns (bool) {
        return (kind == "addr" && addresses[node] != 0) || (kind == "hash" && hashes[node] != 0);
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) constant returns (bool) {
        return interfaceID == 0x3b3b57de || interfaceID == 0xd8389dc5;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) constant returns (address ret) {
        ret = addresses[node];
    }

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) only_owner(node) {
        addresses[node] = addr;
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) constant returns (bytes32 ret) {
        ret = hashes[node];
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) only_owner(node) {
        hashes[node] = hash;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// File: contracts/robonomics/LiabilityFactory.sol

contract LiabilityFactory is SingletonHash {
    constructor(
        address _robot_liability_lib,
        address _lighthouse_lib,
        DutchAuction _auction,
        XRT _xrt,
        ENS _ens
    ) public {
        robotLiabilityLib = _robot_liability_lib;
        lighthouseLib = _lighthouse_lib;
        auction = _auction;
        xrt = _xrt;
        ens = _ens;
    }

    using SafeERC20 for XRT;
    using SafeERC20 for ERC20;

    /**
     * @dev New liability created 
     */
    event NewLiability(address indexed liability);

    /**
     * @dev New lighthouse created
     */
    event NewLighthouse(address indexed lighthouse, string name);

    /**
     * @dev Robonomics dutch auction contract
     */
    DutchAuction public auction;

    /**
     * @dev Robonomics network protocol token
     */
    XRT public xrt;

    /**
     * @dev Ethereum name system
     */
    ENS public ens;

    /**
     * @dev Total GAS utilized by Robonomics network
     */
    uint256 public totalGasUtilizing = 0;

    /**
     * @dev GAS utilized by liability contracts
     */
    mapping(address => uint256) public gasUtilizing;

    /**
     * @dev The count of utilized gas for switch to next epoch 
     */
    uint256 public constant gasEpoch = 347 * 10**10;

    /**
     * @dev Weighted average gasprice
     */
    uint256 public constant gasPrice = 10 * 10**9;

    /**
     * @dev Lighthouse accounting
     */
    mapping(address => bool) public isLighthouse;

    /**
     * @dev Robot liability shared code smart contract
     */
    address public robotLiabilityLib;

    /**
     * @dev Lightouse shared code smart contract
     */
    address public lighthouseLib;

    /**
     * @dev XRT emission value for utilized gas
     */
    function wnFromGas(uint256 _gas) public view returns (uint256) {
        // Just return wn=gas when auction isn&#39;t finish
        if (auction.finalPrice() == 0)
            return _gas;

        // Current gas utilization epoch
        uint256 epoch = totalGasUtilizing / gasEpoch;

        // XRT emission with addition coefficient by gas utilzation epoch
        uint256 wn = _gas * 10**9 * gasPrice * 2**epoch / 3**epoch / auction.finalPrice();

        // Check to not permit emission decrease below wn=gas
        return wn < _gas ? _gas : wn;
    }

    /**
     * @dev Only lighthouse guard
     */
    modifier onlyLighthouse {
        require(isLighthouse[msg.sender]);
        _;
    }

    /**
     * @dev Create robot liability smart contract
     * @param _demand ABI-encoded demand message 
     * @param _offer ABI-encoded offer message 
     */
    function createLiability(
        bytes _demand,
        bytes _offer
    )
        external 
        onlyLighthouse
        returns (RobotLiability liability)
    {
        // Store in memory available gas
        uint256 gasinit = gasleft();

        // Create liability
        liability = new RobotLiability(robotLiabilityLib);
        emit NewLiability(liability);

        // Parse messages
        require(liability.call(abi.encodePacked(bytes4(0x0be8947a), _demand))); // liability.demand(...)
        singletonHash(liability.demandHash());

        require(liability.call(abi.encodePacked(bytes4(0x87bca1cf), _offer))); // liability.offer(...)
        singletonHash(liability.offerHash());

        // Transfer lighthouse fee to lighthouse worker directly
        if (liability.lighthouseFee() > 0)
            xrt.safeTransferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee());

        // Transfer liability security and hold on contract
        ERC20 token = liability.token();
        if (liability.cost() > 0)
            token.safeTransferFrom(liability.promisee(),
                                   liability,
                                   liability.cost());

        // Transfer validator fee and hold on contract
        if (address(liability.validator()) != 0 && liability.validatorFee() > 0)
            xrt.safeTransferFrom(liability.promisee(),
                                 liability,
                                 liability.validatorFee());

        // Accounting gas usage of transaction
        uint256 gas = gasinit - gasleft() + 110525; // Including observation error
        totalGasUtilizing       += gas;
        gasUtilizing[liability] += gas;
     }

    /**
     * @dev Create lighthouse smart contract
     * @param _minimalFreeze Minimal freeze value of XRT token
     * @param _timeoutBlocks Max time of lighthouse silence in blocks
     * @param _name Lighthouse subdomain,
     *              example: for &#39;my-name&#39; will created &#39;my-name.lighthouse.1.robonomics.eth&#39; domain
     */
    function createLighthouse(
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks,
        string  _name
    )
        external
        returns (address lighthouse)
    {
        bytes32 lighthouseNode
            // lighthouse.2.robonomics.eth
            = 0xa058d6058d5ec525aa555c572720908a8d6ea6e2781b460bdecb2abf8bf56d4c;

        // Name reservation check
        bytes32 subnode = keccak256(abi.encodePacked(lighthouseNode, keccak256(_name)));
        require(ens.resolver(subnode) == 0);

        // Create lighthouse
        lighthouse = new Lighthouse(lighthouseLib, _minimalFreeze, _timeoutBlocks);
        emit NewLighthouse(lighthouse, _name);
        isLighthouse[lighthouse] = true;

        // Register subnode
        ens.setSubnodeOwner(lighthouseNode, keccak256(_name), this);

        // Register lighthouse address
        PublicResolver resolver = PublicResolver(ens.resolver(lighthouseNode));
        ens.setResolver(subnode, resolver);
        resolver.setAddr(subnode, lighthouse);
    }

    /**
     * @dev Is called whan after liability finalization
     * @param _gas Liability finalization gas expenses
     */
    function liabilityFinalized(
        uint256 _gas
    )
        external
        returns (bool)
    {
        require(gasUtilizing[msg.sender] > 0);

        uint256 gas = _gas - gasleft();
        require(_gas > gas);

        totalGasUtilizing        += gas;
        gasUtilizing[msg.sender] += gas;
        require(xrt.mint(tx.origin, wnFromGas(gasUtilizing[msg.sender])));
        return true;
    }
}