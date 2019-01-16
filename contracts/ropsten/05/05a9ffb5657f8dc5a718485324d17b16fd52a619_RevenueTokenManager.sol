pragma solidity ^0.4.13;

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

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

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

contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

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

contract Modifiable {
    //
    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

contract RevenueToken is ERC20Mintable {
    using SafeMath for uint256;

    bool public mintingDisabled;

    address[] public holders;

    mapping(address => bool) public holdersMap;

    mapping(address => uint256[]) public balances;

    mapping(address => uint256[]) public balanceBlocks;

    mapping(address => uint256[]) public balanceBlockNumbers;

    event DisableMinting();

    /**
     * @notice Disable further minting
     * @dev This operation can not be undone
     */
    function disableMinting()
    public
    onlyMinter
    {
        mintingDisabled = true;

        emit DisableMinting();
    }

    /**
     * @notice Mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value)
    public
    onlyMinter
    returns (bool)
    {
        require(!mintingDisabled);

        // Call super&#39;s mint, including event emission
        bool minted = super.mint(to, value);

        if (minted) {
            // Adjust balance blocks
            addBalanceBlocks(to);

            // Add to the token holders list
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return minted;
    }

    /**
     * @notice Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
        // Call super&#39;s transfer, including event emission
        bool transferred = super.transfer(to, value);

        if (transferred) {
            // Adjust balance blocks
            addBalanceBlocks(msg.sender);
            addBalanceBlocks(to);

            // Add to the token holders list
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev Beware that to change the approve amount you first have to reduce the addresses&#39;
     * allowance to zero by calling `approve(spender, 0)` if it is not already 0 to mitigate the race
     * condition described here:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
    public
    returns (bool)
    {
        // Prevent the update of non-zero allowance
        require(0 == value || 0 == allowance(msg.sender, spender));

        // Call super&#39;s approve, including event emission
        return super.approve(spender, value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
        // Call super&#39;s transferFrom, including event emission
        bool transferred = super.transferFrom(from, to, value);

        if (transferred) {
            // Adjust balance blocks
            addBalanceBlocks(from);
            addBalanceBlocks(to);

            // Add to the token holders list
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

    /**
     * @notice Calculate the amount of balance blocks, i.e. the area under the curve (AUC) of
     * balance as function of block number
     * @dev The AUC is used as weight for the share of revenue that a token holder may claim
     * @param account The account address for which calculation is done
     * @param startBlock The start block number considered
     * @param endBlock The end block number considered
     * @return The calculated AUC
     */
    function balanceBlocksIn(address account, uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock);
        require(account != address(0));

        if (balanceBlockNumbers[account].length == 0 || endBlock < balanceBlockNumbers[account][0])
            return 0;

        uint256 i = 0;
        while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < startBlock)
            i++;

        uint256 r;
        if (i >= balanceBlockNumbers[account].length)
            r = balances[account][balanceBlockNumbers[account].length - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : balanceBlockNumbers[account][i - 1];

            uint256 h = balanceBlockNumbers[account][i];
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : balanceBlocks[account][i].mul(h).div(balanceBlockNumbers[account][i].sub(l));
            i++;

            while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < endBlock) {
                r = r.add(balanceBlocks[account][i]);
                i++;
            }

            if (i >= balanceBlockNumbers[account].length)
                r = r.add(
                    balances[account][balanceBlockNumbers[account].length - 1].mul(
                        endBlock.sub(balanceBlockNumbers[account][balanceBlockNumbers[account].length - 1])
                    )
                );

            else if (balanceBlockNumbers[account][i - 1] < endBlock)
                r = r.add(
                    balanceBlocks[account][i].mul(
                        endBlock.sub(balanceBlockNumbers[account][i - 1])
                    ).div(
                        balanceBlockNumbers[account][i].sub(balanceBlockNumbers[account][i - 1])
                    )
                );
        }

        return r;
    }

    /**
     * @notice Get the count of balance updates for the given account
     * @return The count of balance updates
     */
    function balanceUpdatesCount(address account)
    public
    view
    returns (uint256)
    {
        return balanceBlocks[account].length;
    }

    /**
     * @notice Get the count of holders
     * @return The count of holders
     */
    function holdersCount()
    public
    view
    returns (uint256)
    {
        return holders.length;
    }

    /**
     * @notice Get the subset of holders (optionally with positive balance only) in the given 0 based index range
     * @param low The lower inclusive index
     * @param up The upper inclusive index
     * @param posOnly List only positive balance holders
     * @return The subset of positive balance registered holders in the given range
     */
    function holdersByIndices(uint256 low, uint256 up, bool posOnly)
    public
    view
    returns (address[])
    {
        require(low <= up);

        up = up > holders.length - 1 ? holders.length - 1 : up;

        uint256 length = 0;
        if (posOnly) {
            for (uint256 i = low; i <= up; i++)
                if (0 < balanceOf(holders[i]))
                    length++;
        } else
            length = up - low + 1;

        address[] memory _holders = new address[](length);

        uint256 j = 0;
        for (i = low; i <= up; i++)
            if (!posOnly || 0 < balanceOf(holders[i]))
                _holders[j++] = holders[i];

        return _holders;
    }

    function addBalanceBlocks(address account)
    private
    {
        uint256 length = balanceBlockNumbers[account].length;
        balances[account].push(balanceOf(account));
        if (0 < length)
            balanceBlocks[account].push(
                balances[account][length - 1].mul(
                    block.number.sub(balanceBlockNumbers[account][length - 1])
                )
            );
        else
            balanceBlocks[account].push(0);
        balanceBlockNumbers[account].push(block.number);
    }
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    //
    //Clamping functions.
    //
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

contract SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    bool public selfDestructionDisabled;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Get the address of the destructor role
    function destructor()
    public
    view
    returns (address);

    /// @notice Disable self-destruction of this contract
    /// @dev This operation can not be undone
    function disableSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Disable self-destruction
        selfDestructionDisabled = true;

        // Emit event
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    /// @notice Destroy this contract
    function triggerSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Require that self-destruction has not been disabled
        require(!selfDestructionDisabled);

        // Emit event
        emit TriggerSelfDestructionEvent(msg.sender);

        // Self-destruct and reward destructor
        selfdestruct(msg.sender);
    }
}

contract Ownable is Modifiable, SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    address public deployer;
    address public operator;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Return the address that is able to initiate self-destruction
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    /// @notice Set the deployer of this contract
    /// @param newDeployer The address of the new deployer
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            // Set new deployer
            address oldDeployer = deployer;
            deployer = newDeployer;

            // Emit event
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    /// @notice Set the operator of this contract
    /// @param newOperator The address of the new operator
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            // Set new operator
            address oldOperator = operator;
            operator = newOperator;

            // Emit event
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    /// @notice Gauge whether message sender is deployer or not
    /// @return true if msg.sender is deployer, else false
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    /// @notice Gauge whether message sender is operator or not
    /// @return true if msg.sender is operator, else false
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    /// @notice Gauge whether message sender is operator or deployer on the one hand, or none of these on these on
    /// on the other hand
    /// @return true if msg.sender is operator, else false
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

contract TokenMultiTimelock is Ownable {
    using SafeERC20 for IERC20;

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Release {
        uint256 earliestReleaseTime;
        uint256 amount;
        uint256 blockNumber;
        bool done;
    }

    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    IERC20 public token;
    address public beneficiary;

    Release[] public releases;
    uint256 public totalLockedAmount;
    uint256 public executedReleasesCount;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SetTokenEvent(IERC20 token);
    event SetBeneficiaryEvent(address beneficiary);
    event DefineReleaseEvent(uint256 earliestReleaseTime, uint256 amount, uint256 blockNumber);
    event SetReleaseBlockNumberEvent(uint256 index, uint256 blockNumber);
    event ReleaseEvent(uint256 index, uint256 blockNumber, uint256 earliestReleaseTime,
        uint256 actualReleaseTime, uint256 amount);

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address deployer)
    Ownable(deployer)
    public
    {
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Set the address of token
    /// @param _token The address of token
    function setToken(IERC20 _token)
    public
    onlyOperator
    notNullOrThisAddress(_token)
    {
        // Require that the token has not previously been set
        require(address(token) == address(0));

        // Update beneficiary
        token = _token;

        // Emit event
        emit SetTokenEvent(token);
    }

    /// @notice Set the address of beneficiary
    /// @param _beneficiary The new address of beneficiary
    function setBeneficiary(address _beneficiary)
    public
    onlyOperator
    notNullAddress(_beneficiary)
    {
        // Update beneficiary
        beneficiary = _beneficiary;

        // Emit event
        emit SetBeneficiaryEvent(beneficiary);
    }

    /// @notice Define a set of new releases
    /// @param earliestReleaseTimes The timestamp after which the corresponding amount may be released
    /// @param amounts The amounts to be released
    /// @param releaseBlockNumbers The set release block numbers for releases whose earliest release time
    /// is in the past
    function defineReleases(uint256[] earliestReleaseTimes, uint256[] amounts, uint256[] releaseBlockNumbers)
    onlyOperator
    public
    {
        require(earliestReleaseTimes.length == amounts.length);
        require(earliestReleaseTimes.length >= releaseBlockNumbers.length);

        // Require that token address has been set
        require(address(token) != address(0));

        for (uint256 i = 0; i < earliestReleaseTimes.length; i++) {
            // Update the total amount locked by this contract
            totalLockedAmount += amounts[i];

            // Require that total amount locked is smaller than or equal to the token balance of
            // this contract
            require(token.balanceOf(address(this)) >= totalLockedAmount);

            // Retrieve early block number where available
            uint256 blockNumber = i < releaseBlockNumbers.length ? releaseBlockNumbers[i] : 0;

            // Add release
            releases.push(Release(earliestReleaseTimes[i], amounts[i], blockNumber, false));

            // Emit event
            emit DefineReleaseEvent(earliestReleaseTimes[i], amounts[i], blockNumber);
        }
    }

    /// @notice Get the count of releases
    /// @return The number of defined releases
    function releasesCount()
    public
    view
    returns (uint256)
    {
        return releases.length;
    }

    /// @notice Set the block number of a release that is not done
    /// @param index The index of the release
    /// @param blockNumber The updated block number
    function setReleaseBlockNumber(uint256 index, uint256 blockNumber)
    public
    onlyBeneficiary
    {
        // Require that the release is not done
        require(!releases[index].done);

        // Update the release block number
        releases[index].blockNumber = blockNumber;

        // Emit event
        emit SetReleaseBlockNumberEvent(index, blockNumber);
    }

    /// @notice Transfers tokens held in the indicated release to beneficiary.
    /// @param index The index of the release
    function release(uint256 index)
    public
    onlyBeneficiary
    {
        // Get the release object
        Release storage _release = releases[index];

        // Require that this release has not already been executed
        require(!_release.done);

        // Require that the current timestamp is beyond the nominal release time
        require(block.timestamp >= _release.earliestReleaseTime);

        // Set release done
        _release.done = true;

        // Bump number of executed releases
        executedReleasesCount++;

        // Decrement the total locked amount
        totalLockedAmount -= _release.amount;

        // Execute transfer
        token.safeTransfer(beneficiary, _release.amount);

        // Get block number
        uint256 blockNumber = 0 < _release.blockNumber ? _release.blockNumber : block.number;

        // Emit event
        emit ReleaseEvent(index, blockNumber, _release.earliestReleaseTime, block.timestamp, _release.amount);
    }

    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }
}

contract RevenueTokenManager is TokenMultiTimelock {
    using SafeMathUintLib for uint256;

    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    uint256[] public releaseBlockNumbers;
    uint256[] public totalReleasedAmounts;
    uint256[] public totalReleasedAmountBlocks;

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address deployer)
    public
    TokenMultiTimelock(deployer)
    {
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Transfers tokens held in the indicated release to beneficiary
    /// and update amount blocks
    /// @param index The index of the release
    function release(uint256 index)
    public
    onlyBeneficiary
    {
        // Add amount blocks
        _addAmountBlocks(index);

        // Call release of multi timelock
        super.release(index);
    }

    /// @notice Calculate the released amount blocks, i.e. the area under the curve (AUC) of
    /// release amount as function of block number
    /// @param startBlock The start block number considered
    /// @param endBlock The end block number considered
    /// @return The calculated AUC
    function releasedAmountBlocksIn(uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock);

        if (releaseBlockNumbers.length == 0 || endBlock < releaseBlockNumbers[0])
            return 0;

        uint256 i = 0;
        while (i < releaseBlockNumbers.length && releaseBlockNumbers[i] < startBlock)
            i++;

        uint256 r;
        if (i >= releaseBlockNumbers.length)
            r = totalReleasedAmounts[releaseBlockNumbers.length - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : releaseBlockNumbers[i - 1];

            uint256 h = releaseBlockNumbers[i];
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : totalReleasedAmountBlocks[i].mul(h).div(releaseBlockNumbers[i].sub(l));
            i++;

            while (i < releaseBlockNumbers.length && releaseBlockNumbers[i] < endBlock) {
                r = r.add(totalReleasedAmountBlocks[i]);
                i++;
            }

            if (i >= releaseBlockNumbers.length)
                r = r.add(
                    totalReleasedAmounts[releaseBlockNumbers.length - 1].mul(
                        endBlock.sub(releaseBlockNumbers[releaseBlockNumbers.length - 1])
                    )
                );

            else if (releaseBlockNumbers[i - 1] < endBlock)
                r = r.add(
                    totalReleasedAmountBlocks[i].mul(
                        endBlock.sub(releaseBlockNumbers[i - 1])
                    ).div(
                        releaseBlockNumbers[i].sub(releaseBlockNumbers[i - 1])
                    )
                );
        }

        return r;
    }

    //
    // Private functions
    // -----------------------------------------------------------------------------------------------------------------
    function _addAmountBlocks(uint256 index)
    private
    {
        // Use block number defined in release if it is non-null
        uint256 blockNumber = 0 < releases[index].blockNumber ? releases[index].blockNumber : block.number;

        // Store the new total amount released by adding this release&#39; amount to
        // previous total amount
        totalReleasedAmounts.push(
            (0 == totalReleasedAmounts.length ? 0 : totalReleasedAmounts[totalReleasedAmounts.length - 1])
            + releases[index].amount
        );

        // Add to total released amount blocks
        if (0 < executedReleasesCount)
            totalReleasedAmountBlocks.push(
                totalReleasedAmounts[executedReleasesCount - 1].mul(
                    blockNumber.sub(releaseBlockNumbers[executedReleasesCount - 1])
                )
            );
        else
            totalReleasedAmountBlocks.push(0);

        // Store the block number of the release
        releaseBlockNumbers.push(blockNumber);
    }
}