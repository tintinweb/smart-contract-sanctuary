pragma solidity ^0.6.0;

/**
 * @title ERC20Basic
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
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
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "transferring to a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title ERC20 Pausable token
 */
contract PausableToken is ERC20Basic, Pausable {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256  internal totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public override virtual returns (bool) {
        require(_to != address(0), "trasferring to zero address");
        require(_value <= balances[msg.sender], "transfer amount exceeds available balance");
        require(!paused, "token transfer while paused");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Transfer tokens from one address to another based on allowance
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
        require(_from != address(0), "from must not be zero address"); 
        require(_to != address(0), "to must not be zero address"); 
        require(!paused, "token transfer while paused");
        require(_value <= allowed[_from][msg.sender], "tranfer amount exceeds allowance");
        require(_value <= balances[_from], "transfer amount exceeds available balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Because approve/tranferFrom method is susceptible of multiple withdrawal attack,
    * please be careful when using approve additional amount of tokens.
    * Before approving additional allowances to a certain address, 
    * it is desired to check the changes of allowance of the address due to previous transferFrom activities.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(_spender != address(0), "approving to a zero address");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public 
        returns (bool)
    {
        require(_spender != address(0), "approving to zero address");
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool)
    {
        require(_spender != address(0), "spender must not be a zero address");
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
* @title Mintable token
*/
contract MintableToken is PausableToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool private mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished, "minting is finished");
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool)
    {
        require(_to != address(0), "minting to zero address");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


contract FreezableMintableToken is MintableToken {

    mapping (address => bool) private frozenAccounts;

    // total frozen balance per address
    mapping (address => uint256) private frozenBalance;

    event FrozenAccount(address target, bool frozen);
    event TokensFrozen(address indexed account, uint amount);
    event TokensUnfrozen(address indexed account, uint amount);

    /**
     * @dev Freeze the specified address.
     * @param target The address to freeze.
     * @param freeze A boolean that indicates if this address is frozen or not.
     */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccounts[target] = freeze;
        emit FrozenAccount(target, freeze);
    }

    /**
     * @dev Gets the balance of frozen tokens at the specified address.
     */
    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalance[_owner];
    }

    /**
     * @dev Gets the balance of the specified address which are not frozen and thus transferrable.
     * @param _owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function usableBalanceOf(address _owner) public view returns (uint256 balance) {
        return (balances[_owner].sub(frozenBalance[_owner]));
    }

    /**
     * @dev Send the specified amount of token to the specified address and freeze it.
     * @param _to Address to which token will be frozen.
     * @param _amount Amount of token to freeze.
     */
    function freezeTo(address _to, uint _amount) public onlyOwner {
        require(_to != address(0), "freezing a zero address");
        require(_amount <= balances[msg.sender], "amount exceeds balance");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        frozenBalance[_to] = frozenBalance[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);
        emit TokensFrozen(_to, _amount);
    }

    /**
     * @dev Unfreeze freezing tokens at the specified address.
     * @param _from Address from which frozen tokens are to be released.
     * @param _amount Amount of frozen tokens to release.
     */
    function unfreezeFrom(address _from, uint _amount) public onlyOwner {
        require(_from != address(0), "unfreezing from zero address");
        require(_amount <= frozenBalance[_from], "amount exceeds frozen balance");

        frozenBalance[_from] = frozenBalance[_from].sub(_amount);
        emit TokensUnfrozen(_from, _amount);
    }


    /**
     * @dev Mint the specified amount of token to the specified address and freeze it.
     * @param _to Address to which token will be frozen.
     * @param _amount Amount of token to mint and freeze.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintAndFreeze(address _to, uint _amount) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        frozenBalance[_to] = frozenBalance[_to].add(_amount);

        emit Mint(_to, _amount);
        emit TokensFrozen(_to, _amount);  
        emit Transfer(address(0), _to, _amount);
        return true;
    }  
    
    function transfer(address _to, uint256 _value) public override virtual returns (bool) {
        require(!frozenAccounts[msg.sender], "account is frozen");
        require(_value <= (balances[msg.sender].sub(frozenBalance[msg.sender])), 
            "amount exceeds usable balance");
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
        require(!frozenAccounts[msg.sender], "account is frozen");
        require(_value <= (balances[_from].sub(frozenBalance[_from])), 
            "amount to transfer exceeds usable balance");
        super.transferFrom(_from, _to, _value);
    }

}

/**
 * @title BurnableFreezableMintableToken Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableFreezableMintableToken is FreezableMintableToken {
    mapping (address => bool) private blocklistedAccounts;

    event Burn(address indexed owner, uint256 value);

    event AccountBlocked(address user);
    event AccountUnblocked(address user);
    event BlockedFundsDestroyed(address blockedListedUser, uint destroyedAmount);

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(!blocklistedAccounts[msg.sender], "account is blocklisted");
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(!blocklistedAccounts[_from], "account is blocklisted");
        super.transferFrom(_from, _to, _value);
    }
    
    function isBlocklisted(address _maker) public view returns (bool) {
        return blocklistedAccounts[_maker];
    } 
    
    function blockAccount(address _evilUser) public onlyOwner returns (bool) {
        require(_evilUser != address(0), "address to block must not be zero address");
        blocklistedAccounts[_evilUser] = true;
        emit AccountBlocked(_evilUser);
        return true;
    }

    function unblockAccount(address _clearedUser) public onlyOwner returns (bool) {
        blocklistedAccounts[_clearedUser] = false;
        emit AccountUnblocked(_clearedUser);
        return true;
    }

    function destroyBlockedFunds(address _blockListedUser) public onlyOwner returns (bool) {
        require(blocklistedAccounts[_blockListedUser], "account must be blocklisted");
        uint dirtyFunds = balanceOf(_blockListedUser);
        _burn(_blockListedUser, dirtyFunds);
        emit BlockedFundsDestroyed(_blockListedUser, dirtyFunds);
        return true;
    }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
    function burn(address _owner, uint256 _value) public onlyOwner {
        _burn(_owner, _value);
    }
  
    function _burn(address _who, uint256 _value) internal {
        require(_who != address(0));
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract MainToken is BurnableFreezableMintableToken {

    uint8 constant private DECIMALS = 18;
    uint constant private INITIAL_SUPPLY = 98000000000 * (10 ** uint(DECIMALS));
    string constant private NAME = "AllmediCoin";
    string constant private SYMBOL = "AMDC";

    constructor() public {
        address mintAddress = msg.sender;
        mint(mintAddress, INITIAL_SUPPLY);
    }
  
    function name() public view returns (string memory _name) {
        return NAME;
    }

    function symbol() public view returns (string memory _symbol) {
        return SYMBOL;
    }

    function decimals() public view returns (uint8 _decimals) {
        return DECIMALS;
    }
    
}