//await deployer.deploy(signkeysVesting);
        // const vesting = await signkeysVesting.deployed();
        //
        // await deployer.deploy(signkeysToken, vesting.address);
        // const token = await signkeysToken.deployed();
        //
        // const signer = owner;
        // await deployer.deploy(signkeysStaking, token.address, signer);
        // const staking = await signkeysStaking.deployed();
        // await token.setStakingContract(staking.address);
        //
        //
        // const start = toSolidityTime(moment.now().valueOf());
        // const end = toSolidityTime(moment.now().valueOf() + 3600 * 1000);
        //
        // await deployer.deploy(SignkeysCrowdsale, token.address, wallet, start, end, signer);
        // const sale = await SignkeysCrowdsale.deployed();
        // await token.setSaleContract(sale.address);


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

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1664737b75795624">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9afbf6ffe2ffe3daf7f3e2f8e3eeffe9b4f3f5">[email&#160;protected]</a>>
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

// File: contracts/SignkeysCrowdsale.sol

contract SignkeysCrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ERC20Detailed signkeysToken;

    /* signer address, can be set by owner only */
    address public signer;

    /* the UNIX timestamp start date of the crowdsale in UTC */
    uint public startsAtUTC;

    /* the UNIX timestamp end date of the crowdsale in UTC */
    uint public endsAtUTC;

    /* ETH funds will be transferred to this address */
    address public wallet;

    /* Owner on this contract */
    address private contractOwner;

    // Buyer bought the amount of tokens with tokenPrice
    event BuyTokens(address buyer, uint256 tokenPrice, uint256 amount, uint256 customerId);

    // Crowdsale start time has been changed
    event StartsAtChanged(uint newStartsAtUTC);

    // Crowdsale end time has been changed
    event EndsAtChanged(uint newEndsAtUTC);

    // Wallet changed
    event WalletChanged(address newWallet);

    // Signer changed
    event CrowdsaleSignerChanged(address newSigner);

    constructor(address _token, address _wallet, uint _start, uint _end, address _signer) public {
        require(_wallet != 0x0, "Wallet for fund transferring must be set");
        require(_token != 0x0, "Token contract for crowdsale must be set");
        require(_start != 0, "Start date of crowdsale must be set");
        require(_end != 0, "End date of crowdsale must be set");
        require(startsAtUTC <= endsAtUTC, "Start date must be less than end date");
        require(_signer != 0x0, "Signer must be set");

        signkeysToken = ERC20Detailed(_token);
        signer = _signer;
        wallet = _wallet;
        startsAtUTC = _start;
        endsAtUTC = _end;

        contractOwner = msg.sender;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        signer = _signer;
        emit CrowdsaleSignerChanged(_signer);
    }

    function setWalletAddress(address _wallet) external onlyOwner {
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

    function getRemainingTokensToSell() external view returns (uint256) {
        return signkeysToken.balanceOf(this);
    }

    /**
     * Allow crowdsale owner to change start date of the crowdsale.
     */
    function setStartsAtUTC(uint time) external onlyOwner {
        require(time <= endsAtUTC, "Start date must be less than end time");
        startsAtUTC = time;
        emit StartsAtChanged(startsAtUTC);
    }

    /**
     * Allow crowdsale owner to close early or extend the crowdsale.
     *
     * This may put the crowdsale to an invalid state,
     * but we trust owners know what they are doing.
     */
    function setEndsAtUTC(uint time) external onlyOwner {
        require(now <= time, "End date must be greater than current time");
        require(startsAtUTC <= time, "End date must be greater than start time");
        endsAtUTC = time;
        emit EndsAtChanged(endsAtUTC);
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
        uint256 _tokenPrice,
        uint256 _minWei,
        uint256 _customerId,
        uint256 _expiration,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) payable external nonReentrant {
        require(_expiration >= now, "Signature expired");
        require(now >= startsAtUTC, "Cannot buy before crowdsale starts");
        require(now <= endsAtUTC, "Cannot buy after crowdsale ends");
        require(_customerId != 0, "Customer id must be defined to track the transactions");

        uint256 weiAmount = msg.value;
        require(weiAmount >= _minWei, "Purchased amount is less than min amount to invest");

        address receivedSigner = ecrecover(
            keccak256(
                abi.encodePacked(
                    _tokenPrice, _minWei, _customerId, _expiration
                )
            ), _v, _r, _s);

        require(receivedSigner == signer, "Something wrong with signature");

        uint256 multiplier = 10 ** uint256(signkeysToken.decimals());
        uint256 tokensAmount = weiAmount.mul(multiplier).div(_tokenPrice);
        require(signkeysToken.balanceOf(this) >= tokensAmount, "Not enough tokens in sale contract");

        signkeysToken.transfer(msg.sender, tokensAmount);

        // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our wallet
        if (!wallet.send(weiAmount)) {
            revert();
        }

        emit BuyTokens(msg.sender, _tokenPrice, tokensAmount, _customerId);
    }

    /**
     * Don&#39;t expect to just send in money and get tokens.
     */
    function() payable external {
        revert();
    }
}


pragma solidity ^0.4.24;

/**
 * Deserialize bytes payloads.
 *
 * Values are in big-endian byte order.
 *
 */
library BytesDeserializer {

    /**
     * Extract 256-bit worth of data from the bytes stream.
     */
    function slice32(bytes b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * Extract Ethereum address worth of data from the bytes stream.
     */
    function sliceAddress(bytes b, uint offset) internal pure returns (address) {
        bytes32 out;

        for (uint i = 0; i < 20; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
        }
        return address(uint(out));
    }

    /**
     * Extract 128-bit worth of data from the bytes stream.
     */
    function slice16(bytes b, uint offset) internal pure returns (bytes16) {
        bytes16 out;

        for (uint i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * Extract 32-bit worth of data from the bytes stream.
     */
    function slice4(bytes b, uint offset) internal pure returns (bytes4) {
        bytes4 out;

        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * Extract 16-bit worth of data from the bytes stream.
     */
    function slice2(bytes b, uint offset) internal pure returns (bytes2) {
        bytes2 out;

        for (uint i = 0; i < 2; i++) {
            out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * Extract 8-bit worth of data from the bytes stream.
     */
    function slice(bytes b, uint offset) internal pure returns (bytes1) {
        return bytes1(b[offset] & 0xFF);
    }
}

pragma solidity ^0.4.24;

contract SignkeysStaking is Ownable {

    using BytesDeserializer for bytes;

    using SafeMath for uint256;

    /* The amount of staked tokens for each user*/
    mapping(address => uint256) private _stakes;

    /* The date until the stake is locked */
    mapping(address => uint256) private _stakeLockDateTimes;

    /* The token to which we provide the staking functionality */
    SignkeysToken private token;

    /* signer address, can be set by owner only */
    address public signer;

    /* The duration of lock starting from the moment of stake */
    uint256 public lockDuration;

    event Staked(address indexed user, uint256 amount, uint256 _tokenPrice, uint256 _valueWeis, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event Locked(address indexed user, uint endDateTime);
    event LockDurationChanged(uint newLockDurationSeconds);
    event StakingSignerChanged(address indexed newSigner);

    constructor(address _token, address _signer) public {
        lockDuration = 30 days;
        token = SignkeysToken(_token);
        signer = _signer;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        signer = _signer;
        emit StakingSignerChanged(_signer);
    }

    /**
    * @dev Gets the stake of the specified address.
    * @param staker The address to query the stake of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function stakeOf(address staker) public view returns (uint256) {
        return _stakes[staker];
    }

    /**
    * @dev Gets the lock date of the specified address.
    * @param staker The address to query the lock date of.
    * @return An uint256 representing the lock date of the passed address.
    */
    function lockDateTimeOf(address staker) public view returns (uint256) {
        return _stakeLockDateTimes[staker];
    }

    /**
    * Stake the given amount of tokens. This method calls only via "approve and call" mechanism from token.
    * See receiveApproval method and approveAndCall method in token
    * @param _user The address from which we stake tokens
    * @param _amount The amount of tokens we stake from
    */
    function stake(address _user, uint256 _amount) internal returns (uint256)  {
        require(token.balanceOf(_user) >= _amount, "User balance is less than the requested stake size");

        token.transferFrom(_user, this, _amount);

        _stakes[_user] = _stakes[_user].add(_amount);
        _stakeLockDateTimes[_user] = now.add(lockDuration);

        emit Locked(_user, _stakeLockDateTimes[_user]);

        return token.balanceOf(_user);
    }

    /*
    * Unstake the given amount of tokens from msg.sender
    * @param _amount The amount of tokens we unstake
    */
    function unstake(uint _amount) external {
        require(_stakeLockDateTimes[msg.sender] <= now, "Stake is locked");
        require(stakeOf(msg.sender) >= _amount, "User stake size is less than the requested amount");

        token.transfer(msg.sender, _amount);

        _stakes[msg.sender] = _stakes[msg.sender].sub(_amount);

        emit Unstaked(msg.sender, _amount, token.balanceOf(msg.sender));
    }

    /*
    * receiveApproval method provide the way to call required stake method after transfer approval in token
    * @params sender the user we need to stake tokens from
    * @params value the amount to stake in USD
    * @params tokenContract the address of token contract. Need for validation
    * @params callData additional data. Should contains:
    * token price in wei(same as in crowdsale), value in weis, expiration of signature and (v, r, s) signature
    */
    function receiveApproval(address sender, uint256 tokensAmount, address tokenContract, bytes callData) external {
        require(tokenContract == address(token), "Should be Signkeys token");

        uint256 _tokenPrice;
        uint256 _valueWei;
        uint256 _expiration;
        uint8 _v;
        bytes32 _r;
        bytes32 _s;

        (_tokenPrice, _valueWei, _expiration, _v, _r, _s) = getStakingInfoPayload(callData);

        require(_expiration >= now, "Signature expired");

        uint256 multiplier = 10 ** uint256(token.decimals());
        require(tokensAmount == _valueWei.mul(multiplier).div(_tokenPrice),
            "Value doesn&#39;t correspond weis amount and token price");

        address receivedSigner = ecrecover(keccak256(abi.encodePacked(_tokenPrice, _valueWei, _expiration)), _v, _r, _s);
        require(receivedSigner == signer, "Something wrong with signature");

        uint256 newBalance = stake(sender, tokensAmount);

        emit Staked(sender, tokensAmount, _tokenPrice, _valueWei, newBalance);
    }

    function getStakingInfoPayload(bytes callData) internal pure
    returns (uint256 _tokenPrice, uint256 _valueWei, uint256 _expiration, uint8 _v, bytes32 _r, bytes32 _s) {
        uint256 tokenPrice = uint256(callData.slice32(0));
        uint256 valueWei = uint256(callData.slice32(32));
        uint256 expiration = uint256(callData.slice32(64));
        uint8 v = uint8(callData.slice(96));
        bytes32 r = bytes32(callData.slice32(97));
        bytes32 s = bytes32(callData.slice32(129));
        return (tokenPrice, valueWei, expiration, v, r, s);
    }

    /*
    * Set new lock duration for staked tokens
    */
    function setLockDuration(uint _periodInSeconds) external onlyOwner {
        lockDuration = _periodInSeconds;
        emit LockDurationChanged(lockDuration);
    }
}

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


contract SignkeysToken is ERC20, ERC20Detailed, Ownable {

    uint8 public constant DECIMALS = 18;

    uint256 public constant INITIAL_SUPPLY = 2E10 * (10 ** uint256(DECIMALS));

    uint256 public constant AVAILABLE_FOR_EMPLOYEES = 1E9 * (10 ** uint256(DECIMALS));

    /* Vesting contract */
    SignkeysVesting public vestingContract;

    /* Staking contract */
    SignkeysStaking public stakingContract;

    /* Crowdsale contract */
    SignkeysCrowdsale public saleContract;

    /* Owner on this contract */
    address private tokenOwner;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(address _vesting) public ERC20Detailed("SignkeysToken", "KEYS", DECIMALS) {
        tokenOwner = msg.sender;
        _mint(tokenOwner, INITIAL_SUPPLY);
        vestingContract = SignkeysVesting(_vesting);
    }

    function setStakingContract(address _staking) external onlyOwner {
        stakingContract = SignkeysStaking(_staking);
    }

    function setVestingContract(address _vesting) external onlyOwner {
        vestingContract = SignkeysVesting(_vesting);
    }

    function setSaleContract(address _sale) external onlyOwner {
        saleContract = SignkeysCrowdsale(_sale);
    }

    function _transfer(address from, address to, uint256 value) internal {
        // TODO refactor these conditions
        if (msg.sender != tokenOwner // pass vesting condition if owner need to transfer own or approved tokens
        && from != tokenOwner
        && from != address(saleContract) // sale contract may transfer tokens bypassing vesting schedule resctrictions
        && from != address(stakingContract) // staking contract may unstake tokens
        && to != address(stakingContract)) {// user can stake vested tokens
            require(address(vestingContract) != 0x0, "Token should have vesting contract for transfer operations");
            vestingContract.canTransfer(from, to, value);
        }
        super._transfer(from, to, value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);
        if (!_spender.call(
            bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender, _value, this, _extraData)
        ) {
            revert();
        }
        return true;
    }

    function() payable external {
        revert();
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) external onlyOwner {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to burn tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) external onlyOwner {
        _burnFrom(from, value);
    }

    /**
     * @dev Mints a specific amount of tokens to the target address and increment total supply
     * @param to address The address which you want to mint tokens to
     * @param value uint256 The amount of token to be burned
     */
    function mint(address to, uint256 value) external onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

pragma solidity ^0.4.24;

contract SignkeysVesting is Ownable {

    uint256 public INITIAL_VESTING_CLIFF_SECONDS = 180 days;

    uint public vestingStartDateTime;
    uint public vestingCliffDateTime;

    constructor() public{
        vestingStartDateTime = now;
        vestingCliffDateTime = SafeMath.add(now, INITIAL_VESTING_CLIFF_SECONDS);
    }

    function setVestingStartDateTime(uint _vestingStartDateTime) external onlyOwner {
        require(_vestingStartDateTime <= vestingCliffDateTime, "Start date should be less or equal than cliff date");
        vestingStartDateTime = _vestingStartDateTime;
    }

    function setVestingCliffDateTime(uint _vestingCliffDateTime) external onlyOwner {
        require(vestingStartDateTime <= _vestingCliffDateTime, "Cliff date should be greater or equal than start date");
        vestingCliffDateTime = _vestingCliffDateTime;
    }

    function canTransfer(address from, address to, uint256 value) public view {
        require(vestingCliffDateTime <= now, "Contract can&#39;t transfer tokens until cliff date");
    }
}