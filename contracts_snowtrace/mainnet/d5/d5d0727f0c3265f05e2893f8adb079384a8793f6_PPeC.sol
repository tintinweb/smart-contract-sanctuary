/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// ---------------------- Built with 💘 for everyone --------------------------
/// @author Gradi Kayamba  - Self-taught Full-Stack Software Developer [FSSD for life].
/// @title  Paid Per Click - The winning crypto of the internet.
/// @Symbol PPeC           - Spelled [P:E:K]
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title Interface : Ethereum Token Standard #20.
// ----------------------------------------------------------------------------
interface ERC20Interface {
    
    /**
     * @dev Triggers on any successful call to transfer() and transferFrom().
     * @param from   : The address sending tokens.
     * @param to     : The address receiving tokens.
     * @param amount : The quantity of tokens to be sent.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    /**
     * @dev Triggers on any successful call to approve() and allowance().
     * @param owner   : The address allowing token to be spent.
     * @param spender : The address allowed to spend tokens.
     * @param amount  : The quantity allowed to be spent.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    /**
     * @notice Transfers `amount` tokens to `to`.
     * @param to     : The address receiving tokens.
     * @param amount : The quantity of tokens to send.
     */
    function transfer(address to, uint256 amount) external returns (bool success);
    
    /**
     * @notice Transfers `amount` tokens from `from` to `to`.
     * @param from   : The address sending tokens.
     * @param to     : The address receiving tokens.
     * @param amount : The quantity of tokens to be sent.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    
    /**
     * @notice Sets `amount` to be spent by `spender` on owner's behalf.
     * @param spender : The address allowed to spend tokens.
     * @param amount  : The quantity allowed to be spent.
     */
    function approve(address spender, uint256 amount) external returns (bool success);
    
    /**
     * @notice Returns the amount which `spender` is still allowed to withdraw from `owner`.
     * @param owner   : The address allowing token to be spent.
     * @param spender : The address allowed to spend tokens.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    
    /**
     * @notice Returns the amount of tokens owned by account `owner`.
     * @param owner : The address from which the balance will be retrieved.
     * @return 000
     */
    function balanceOf(address owner) external view returns (uint256);
    
    /**
     * @notice Returns the amount of tokens in existence.
     * @return 000
     */
    function totalSupply() external view returns (uint256);
}

// ----------------------------------------------------------------------------
/// @title Context : Information about sender, and value of the transaction.
// ----------------------------------------------------------------------------
abstract contract Context {
    /// @dev Returns information about the sender of the transaction.
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /// @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

// ----------------------------------------------------------------------------
/// @title Ownable : Information about the founder of the contract and none-zero address modifier.
// ----------------------------------------------------------------------------
abstract contract Ownable is Context {
    // Define public constant variables.
    address payable public founder;       // Smart Contract Creator/Founder.
    mapping(address => uint256) balances; // Holds each address balance.

    // Set values on construction.
    constructor() {
        founder = payable(_msgSender());
    }
    
    /**
     * @dev Triggers on any successful call to transferOwnership().
     * @param oldOwner : The address tranfering ownership.
     * @param newOwner : The address gaining ownership.
     */
    event TransferOwnership(address oldOwner, address newOwner);
    
    /// @dev Makes a function callable only by the founder.
    modifier onlyFounder() {
        require(_msgSender() == founder, "Your are not the Founder.");
        _;
    }
    
    /// @dev Makes a function callable only when the address' owner is not a zero-address.
    modifier noneZero(address owner){
        require(owner != address(0), "Zero address not allowed.");
        _;
    }

    /**
     * @notice Transfers ownership of the contract to `newOwner`.
     * @notice Callable only by the founder.
     * @notice Callable only by a none-zero address.
     */
    function transferOwnership(address payable newOwner) 
    onlyFounder 
    noneZero(newOwner) 
    public 
    returns (bool success) 
    {
        // Check founder's balance.
        uint256 founderBalance = balances[founder];
        // Check new owner's balance.
        uint256 newOwnerBalance = balances[newOwner];
        
        // Set founder balance to 0.
        balances[founder] = 0;
        
        // Add founder's old balance to the new owner's balance.
        balances[newOwner] = newOwnerBalance + founderBalance;
        
        // Transfer ownership from `founder` to the `newOwner`.
        founder = newOwner;
        
        // Emit event
        emit TransferOwnership(founder, newOwner);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Whitelisted : The ability to block evil users' transactions and burn their tokens.
// ----------------------------------------------------------------------------
abstract contract Whitelisted is Ownable {
    // Define public constant variables.
    mapping (address => bool) public isWhitelisted; // Holds whitelisted status for each address.
    
    /**
     * @dev Triggers on any successful call to burnWhiteTokens().
     * @param evilOwner   : The address to burn tokens from.
     * @param dirtyTokens : The quantity of tokens to burn.
     */
    event BurnWhiteTokens(address evilOwner, uint256 dirtyTokens);
    
    /**
     * @dev Triggers on any successful call to addToWhitelist().
     * @param evilOwner : The address to add to whitelist.
     */
    event AddToWhitelist(address evilOwner);
    
    /**
     * @dev Triggers on any successful call to removedFromWhitelist().
     * @param owner : The address to remove from whitelist.
     */
    event RemovedFromWhitelist(address owner);
    
    /// @dev Makes a function callable only when `owner` is not whitelisted.
    modifier whenNotWhitelisted(address owner) {
        require(isWhitelisted[owner] == false, "Whitelisted status detected; please check whitelisted status.");
        _;
    }
    
    /// @dev Makes a function callable only when `owner` is whitelisted.
    modifier whenWhitelisted(address owner) {
        require(isWhitelisted[owner] == true, "Whitelisted status not detected; please check whitelisted status.");
        _;
    }
    
    /**
     * @notice Adds `evilOwner` to whitelist.
     * @notice Callable only by the founder.
     * @notice Callable only when `evilOwner` is not whitelisted.
     * @param evilOwner : The address being added to the whitelist.
     * @return success
     */
    function addToWhitelist(address evilOwner) 
    onlyFounder 
    whenNotWhitelisted(evilOwner)
    public 
    returns (bool success) 
    {
        // Set whitelisted status.
        isWhitelisted[evilOwner] = true;
        
        // Emit event
        emit AddToWhitelist(evilOwner);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Removes `owner` from whitelist.
     * @notice Callable only by the founder.
     * @notice Callable only when `owner` is whitelisted.
     * @param owner : The address to remove from whitelist.
     * @return success
     */
    function removedFromWhitelist(address owner) 
    onlyFounder 
    whenWhitelisted(owner) 
    public 
    returns (bool success) 
    {
        // Unset whitelisted status.
        isWhitelisted[owner] = false;
        
        // Emit event
        emit RemovedFromWhitelist(owner);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Burns tokens of `evilOwner`. 
     * @notice Callable only by the founder.
     * @notice Callable only when `evilOwner` is whitelisted.
     * @param evilOwner : The address to burn funds from.
     * @return success
     */
    function burnWhiteTokens(address evilOwner) 
    onlyFounder
    whenWhitelisted(evilOwner)
    public
    returns (bool success) {
        // Check evil owner's balance - NOTE - Always check the balance, first.
        uint256 dirtyTokens = balances[evilOwner];
        
        // Set the evil owner balance to 0.
        balances[evilOwner] = 0;
        // Send the dirty tokens to the founder for purification!
        balances[founder] += dirtyTokens;
        
        // Emit event
        emit BurnWhiteTokens(evilOwner, dirtyTokens);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Pausable: The ability to pause or unpause trasactions of all tokens.
// ----------------------------------------------------------------------------
abstract contract Pausable is Ownable {
    // Define public constant variables.
    bool public paused = false; // Holds transfer status.
    
    /// @dev Triggers on any successful call to pause().    
    event Pause();
    
    /// @dev Triggers on any successful call to unpause(). 
    event Unpause();

    /// @dev Makes a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(paused == false, "All transactions have been paused.");
        _;
    }

    /// @dev Makes a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    /**
     * @notice Pauses transactions.
     * @notice Callable only by the founder.
     * @notice Callable only when the contract is not paused.
     * @return success
     */
    function pause() public onlyFounder whenNotPaused returns (bool success) {
        // Set pause
        paused = true;
        
        // See {event Pause}
        emit Pause();
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @dev Unpauses transactions.
     * @notice Callable only by the founder.
     * @notice Callable only when the contract is paused.
     * @return success
     */
    function unpause() public  onlyFounder whenPaused returns (bool success) {
        // Unset pause
        paused = false;
        
        // See {event Unpause}
        emit Unpause();
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title PPeC [peK] : Paid Per Click ERC20 Token.
// ----------------------------------------------------------------------------
contract PPeC is  ERC20Interface, Context, Ownable, Whitelisted, Pausable {
    // Define public constant variables.
    string public name;    // Token name
    string public symbol;  // Token symbol
    uint8 public decimals; // Number of decimals.
    uint256 public override totalSupply;    
    address payable public treasury;  // Holds all Advertisement Fees.
    mapping(address => mapping(address => uint256)) allowed; // Holds each address allowance balance.
    
    // Set immutable values.
    constructor(address treasury_) {
        name              = "Paid Per Click";
        decimals          = 18;
        symbol            = "PPeC";
        totalSupply       = 10000000000000E18; //10 Trillion PPeC.
        balances[founder] = totalSupply;
        treasury = payable(treasury_);
    }
    
    /**
     * @dev Triggers on any successful call to mint().
     * @param owner  : The address tokens will be minted to.
     * @param amount : The quantity of tokes to be minted.
     */
    event Mint(address indexed owner, uint256 amount);
    
    /**
     * @dev Triggers on any successful call to burn().
     * @param owner  : The address tokens will be burned from.
     * @param amount : The quantity of tokes to be burned.
     */
    event Burn(address indexed owner, uint256 amount);

    /**
     * @dev Triggers an error when funds available is less than funds required.
     * @param available : The funds available for the transaction.
     * @param required  : The funds required for the transaction.
     */
    error NotEnoughFunds(uint256 available, uint256 required);
    
    /**
     * @notice Changes token name to `newName`.
     * @notice Callable only by the founder.
     */
    function changeTokenName(string memory newName) 
    onlyFounder
    public 
    returns (bool success) 
    {
        // Change token name from `name` to the `newName`.
        name = newName;
        
        // Returns true on success.
        return true;
    }
    
    /**
     * @notice Changes token symbol to `newSymbol`.
     * @notice Callable only by the founder.
     */
    function changeTokenSymbol(string memory newSymbol) 
    onlyFounder
    public 
    returns (bool success) 
    {
        // Change token symbol from `symbol` to the `newSymbol`.
        symbol = newSymbol;
        
        // Returns true on success.
        return true;
    }
    
    // See {_transfer} and {ERC20Interface - transfer}
    function transfer(address to, uint256 amount) public virtual override returns (bool success) {
        // Inherit from {_transfer}.
        _transfer(_msgSender(), to, amount);
        
        // Returns true on success.
        return true;
    }
    
    // See {_transfer}, {_approve} and {ERC20Interface - transferFrom}
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    ) public virtual override returns (bool success) {
        // Inherits from _transfer.
        _transfer(_from, _to, _amount);
        
        // Check sender's allowance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_from][_msgSender()];
        
        // Inherits from _approve.
        _approve(_from, _msgSender(), currentAllowance - _amount, currentAllowance); 

        // Returns true on success.
        return true;
    }

    // See also {_approve} and {ERC20Interface - approve}
    function approve(address spender, uint256 amount) public virtual override returns (bool success) {
        // Inherits from _approve.
        _approve(_msgSender(), spender, amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * Increases total allowance to `amount`.
     * See also {_approve} and {ERC20Interface - approve}
     */
    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool success) {
        // Check spender's allowance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), spender, currentAllowance + amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    /**
     * Decreases total allowance by `amount`.
     * See also {_approve} and {ERC20Interface - approve}
     */
    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool success) {
        // Check sender's allowance balance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), spender, currentAllowance - amount, currentAllowance);

        // Returns true on success.
        return true;
    }  
    
    /**
     * @notice See {ERC20Interface - transfer}. 
     * @notice MUST trigger Transfer event.
     */
    function _transfer( address from, address to, uint256 amount)
    noneZero(from)
    noneZero(to)
    whenNotWhitelisted(from)
    whenNotWhitelisted(to)
    whenNotPaused
    internal 
    virtual 
    {
        // Check sender's balance.
        // NOTE - Always check balances before transaction.
        uint256 senderBalance = balances[from];
        
        /// @dev Requires the sender `senderBalance` balance be at least the `amount`.
        if (amount > senderBalance)
            revert NotEnoughFunds({
                available: senderBalance,
                required: amount
            });
        
        // Increase recipient balance.
        balances[to] += amount;
        // Decrease sender balance.
        balances[from] -= amount;
        
        // See {event ERC20Interface-Transfer}
        emit Transfer(from, to, amount);
    }
    
    /**
     * @notice See {ERC20Interface - approve}
     * @notice MUST trigger a Approval event.
     */
    function _approve( address owner, address spender, uint256 amount, uint256 initialBalance)
    noneZero(spender)
    noneZero(owner)
    internal
    virtual
    {
        /// @dev Requires the owner `initialBalance` balance be at least the `amount`.
        require(initialBalance >= amount, "Not enough balance.");
        
        /// @dev Requires the `amount` be greater than 0 (zero).
        require(amount > 0, "The value is less than zero!");
        
        // Set spender allowance to the `amount`.
        allowed[owner][spender] = amount;
        
        // See {event ERC20Interface-Approval}
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @notice Increases an address' balance and add to the total supply.
     * @notice Callable only by the founder.
     * @param owner  : The address to mint or add tokens to.
     * @param amount : The quantity of tokens to mint or create.
     * @notice MUST trigger Mint event.
     * @return success
     */
    function mint(address owner, uint256 amount) 
    onlyFounder
    public 
    virtual 
    returns (bool success) 
    {
        // Increase total supply.
        totalSupply += amount;
        // Increase owner's balance.
        balances[owner] += amount;
        
        // See {event Mint}
        emit Mint(owner, amount);
        
        // Returns true on success.
        return true;
    }
    
    /**  
     * @notice Decreases an address' balance, and decrease total supply.
     * @notice Callable only by the founder.
     * @param owner  : The address to burn or substract tokens from.
     * @param amount : The quantity of tokens to burn or destroy.
     * @notice MUST trigger Burn event.
     */
    function burn(address owner, uint256 amount) 
    onlyFounder
    public
    virtual
    returns (bool success)
    {
        // Check owner's balance.
        // NOTE - Always check balance before transaction, first.
        uint256 accountBalance = balances[owner];
        
        /// @dev Requires the owner's balance `accountBalance` be at least `_amount`.
        require(accountBalance >= amount, "Burn amount exceeds balance");
        
        // Decrease owner balance.
        balances[owner] -= amount;
        // Decrease `totalSupply` by `_amount`.
        totalSupply -= amount;

        // See {event Burn}
        emit Burn(owner, amount);
        
        // Returns true on success.
        return true;
    }
    
    // Kills contract
    function selfDestruct() public onlyFounder returns (bool success) {
        
        // Decrease founder total supply to 0.
        balances[founder] = 0;
        // Decrease `totalSupply` to 0.
        totalSupply = 0;
        
        // Returns true on success.
        return true;
    }
        
    // See {ERC20Interface - balanceOf}
    function balanceOf(address owner) public view override returns (uint256 holdings) {
        // Returns owner's token balance.
        return balances[owner];
    }

    // See {ERC20Interface - allowance}
    function allowance(address owner, address spender) public view virtual override returns (uint256 remaining) {
        // Returns spender's allowance balance.
        return allowed[owner][spender];
    }
}