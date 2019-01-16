pragma solidity ^0.4.24;

// File: contracts/IERC20.sol

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

// File: contracts/SafeMath.sol

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

// File: contracts/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  using SafeMath for uint256;

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
    // safeApprove should only be called when setting an initial allowance, 
    // or when resetting it to zero. To increase and decrease it, use 
    // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

// File: contracts/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for IERC20;

  // ERC20 basic token contract being held
  IERC20 private _token;

  // beneficiary of tokens after they are released
  address private _beneficiary;

  // timestamp when token release is enabled
  uint256 private _releaseTime;

  constructor(
    IERC20 token,
    address beneficiary,
    uint256 releaseTime
  )
    public
  {
    // solium-disable-next-line security/no-block-members
    require(releaseTime > block.timestamp);
    _token = token;
    _beneficiary = beneficiary;
    _releaseTime = releaseTime;
  }

  /**
   * @return the token being held.
   */
  function token() public view returns(IERC20) {
    return _token;
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() public view returns(address) {
    return _beneficiary;
  }

  /**
   * @return the time when the tokens are released.
   */
  function releaseTime() public view returns(uint256) {
    return _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= _releaseTime);

    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0);

    _token.safeTransfer(_beneficiary, amount);
  }
}

// File: contracts/Ownable.sol

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

// File: contracts/Authorizable.sol

contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != msg.sender);
        authorized[_toAdd] = true;
    }
    function isAuthorized(address _addr) view public returns (bool) {
        return authorized[_addr] || _addr == owner();
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}

// File: contracts\YoungToken.sol

contract YoungToken is IERC20, Authorizable {

    // token name
    string public name = "Young";

    // token short name
    string public symbol = "YNG";

    // token decimals - Example : min transaction with 4 decimals is -> 0.0001 YNG
    uint8 public decimals = 4;

    // total supply for young token
    uint256 public cap;

    // percentage intendeed for development team
    uint8 public teamPercentage = 10;

    // percentage intendeed for advisors
    uint8 public advisorsPercentage = 5;

    // is entire total supply minted ?
    bool public mintingFinished = false;

    // is entire team supply minted?
    bool public teamTokenMinted = false;
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    *
    * Young Token constructor
    * params _advisorAddress -> Address to send &#39;advisorsPercentage&#39; tokens
    *         _cap             -> Total token supply (maybe 100 millions)
    *
    **/
    constructor (address _advisorsAddress, uint256 _cap) public {
        require(_cap > 0);
        cap = _cap*uint(10)**decimals;
        _totalSupply = 0;
        uint256 advisorsTokens = (cap * advisorsPercentage) / 100;
        mint(_advisorsAddress, advisorsTokens);
    }
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
    function increaseAllowance(address spender, uint256 addedValue)
      public
      returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
      public
      returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
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
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
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
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
    // can this address mint tokens?
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    // event for remaining token burn (after second ico phase)
    event Burn(address indexed burner, uint256 value);

    // event for token mint
    event Mint(address indexed to, uint256 amount);

    // event to close mint after total supply reached
    event MintFinished();

    // event for generation of token team lock
    event TeamTimeLockGenerated(address contractAddress, address destinationAddress, uint256 amount);

    /**
    *
    * Mint and lock &#39;teamPercentage&#39; tokens
    * params _to -> Address to send &#39;teamPercentage&#39; tokens
    *
    * info : &#39;teamTokenMinted&#39; should be false (Means that team tokens aren&#39;t already minted)
    *          This function also lock team tokens for 24 weeks ( 6 months )
    *
    **/
    function mintLockTeamTokens(address _to) public onlyOwner canMint returns (address) {
        // Mint and send team tokens to the time lock. Tokens are locked for 6 months
        require(!teamTokenMinted);
        uint256 teamTokens = (cap * teamPercentage) / 100;
        TokenTimelock teamLock = new TokenTimelock(this, _to, now + 24 weeks);
        address timeLockAddress = address(teamLock);
        mint(timeLockAddress, teamTokens);
        teamTokenMinted = true;
        emit TeamTimeLockGenerated(timeLockAddress, _to, teamTokens);
        return timeLockAddress;
    }

    /**
    *
    * Token burn funtion
    * params _value -> Amount of tokens to burn
    *
    * info : Require value <= balance of request sender
    *
    * devs : Maybe this function should be onlyOwner ?
    *
    **/
    function burn(uint256 _value) public {
        require(_value <= _balances[msg.sender]);
        address burner = msg.sender;
        _balances[burner] = _balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        cap = cap.sub(_value);
        emit Burn(burner, _value);
    }

    /**
    *
    * Token mint function
    * params _to     -> Address to send minted tokens
    *         _amount -> Amount of tokens to burn
    *
    * info : Cannot exceed totalSupply
    *
    **/
    function mint(address _to, uint256 _amount) onlyAuthorized canMint public returns (bool) {
        require(_totalSupply.add(_amount) <= cap);
        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    *
    * Finalize token minting ( after that minting will not possible )
    *
    **/
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}