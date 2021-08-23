/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// ----------------------------------------------------------------------------
/// @author Gradi Kayamba
/// @title Bozindo Currency - BOZY
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title Interface : Token Standard #20. https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
interface ERC20Interface {
    
    /// @dev Triggers on any successful call to transfer() and transferFrom().
    /// @param _from : The address sending the tokens.
    /// @param _to : The address receiving the tokens.
    /// @param _amount : The quantity of tokens to be sent.
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    
    /// @dev Triggers on any successful call to approve() and allowance().
    /// @param _owner : The address allowing token to be spent.
    /// @param _spender : The address allowed to spend tokens.
    /// @param _amount : The quantity allowed to be spent.
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    
    /// @notice Transfers `_amount` tokens to `_to`.
    /// @param _to : The address receiving tokens.
    /// @param _amount : The quantity of tokens to send.
    function transfer(address _to, uint256 _amount) external returns (bool success);
    
    /// @notice Transfers `_amount` tokens from `_from` to `_to`.
    /// @param _from : The address sending tokens.
    /// @param _to : The address receiving tokens.
    /// @param _amount : The quantity of tokens to be sent.
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    
    /// @notice Sets `_amount` to be spent by `_spender` on your behalf.
    /// @param _spender : The address allowed to spend tokens.
    /// @param _amount : The quantity allowed to be spent.
    function approve(address _spender, uint256 _amount) external returns (bool success);
    
    /// @notice Returns the amount which `_spender` is still allowed to withdraw from `_owner`.
    /// @param _owner : The address allowing token to be spent.
    /// @param _spender : The address allowed to spend tokens.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
    /// @notice Returns the amount of tokens owned by account `_owner`.
    /// @param _owner : The address from which the balance will be retrieved.
    /// @return holdings 000
    function balanceOf(address _owner) external view returns (uint256 holdings);
    
    /// @notice Returns the amount of tokens in existence.
    /// @return remaining 000
    function totalSupply() external view returns (uint256);
}

// ----------------------------------------------------------------------------
/// @title Context : Information about sender, value, and data of the transaction.
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
    
    /// @dev Returns information about the data of the transaction.
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ----------------------------------------------------------------------------
/// @title Ownable : Information about the founder of the contract and none-zero address modifier.
// ----------------------------------------------------------------------------
abstract contract Ownable is Context {
    // Define public constant variables.
    address payable public founder;
    mapping(address => uint256) balances;

    // Set values on construction.
    constructor() {
        founder = payable(_msgSender());
    }
    
    /// @dev Triggers on any successful call to transferOwnership().
    /// @param _oldOwner : The address tranfering the ownership.
    /// @param _newOwner : The address gaining ownership.
    event TransferOwnership(address _oldOwner, address _newOwner);
    
    /// @dev Makes a function callable only by the founder.
    modifier onlyFounder() {
        require(_msgSender() == founder, "Your are not the Founder.");
        _;
    }
    
    /// @dev Makes a function callable only when the _owner is not a zero-address.
    modifier noneZero(address _owner){
        require(_owner != address(0), "Zero address not allowed.");
        _;
    }

    /// @notice Transfers ownership of the contract to `_newOwner`.
    /// @notice Callable by the founder only.
    /// @notice Callable only by a none-zero address.
    function transferOwnership(address payable _newOwner) 
    onlyFounder 
    noneZero(_newOwner) 
    public 
    returns (bool success) 
    {
        // Check founder's balance.
        uint256 founderBalance = balances[founder];
        // Check new owner's balance.
        uint256 newOwnerBalance = balances[_newOwner];
        
        // Set founder balance to 0.
        balances[founder] = 0;
        
        // Add founder's old balance to the new owner's balance.
        balances[_newOwner] = newOwnerBalance + founderBalance;
        
        // Transfer ownership from `founder` to the `_newOwner`.
        founder = _newOwner;
        
        // Emit event
        emit TransferOwnership(founder, _newOwner);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Whitelisted : The ability to block evil users' transactions and to burn their tokens.
// ----------------------------------------------------------------------------
abstract contract Whitelisted is Ownable {
    // Define public constant variables.
    mapping (address => bool) public isWhitelisted;
    
    /// @dev Triggers on any successful call to burnWhiteTokens().
    /// @param _evilOwner : The address to burn tokens from.
    /// @param _dirtyTokens : The quantity of tokens burned.
    event BurnWhiteTokens(address _evilOwner, uint256 _dirtyTokens);
    
    /// @dev Triggers on any successful call to addToWhitelist().
    /// @param _evilOwner : The address to add to whitelist.
    event AddToWhitelist(address _evilOwner);
    
    /// @dev Triggers on any successful call to removedFromWhitelist().
    /// @param _owner : The address to remove from whitelist.
    event RemovedFromWhitelist(address _owner);
    
    /// @dev Makes a function callable only when `_owner` is not whitelisted.
    modifier whenNotWhitelisted(address _owner) {
        require(isWhitelisted[_owner] == false, "Whitelisted status detected; please check whitelisted status.");
        _;
    }
    
    /// @dev Makes a function callable only when `_owner` is whitelisted.
    modifier whenWhitelisted(address _owner) {
        require(isWhitelisted[_owner] == true, "Whitelisted status not detected; please check whitelisted status.");
        _;
    }
    
    /// @notice Adds `_evilOwner` to whitelist.
    /// @notice Callable only by the founder.
    /// @notice Callable only when `_evilOwner` is not whitelisted.
    /// @param _evilOwner : The address to whitelist.
    /// @return success
    function addToWhitelist(address _evilOwner) 
    onlyFounder 
    whenNotWhitelisted(_evilOwner)
    public 
    returns (bool success) 
    {
        // Set whitelisted status
        isWhitelisted[_evilOwner] = true;
        
        // Emit event
        emit AddToWhitelist(_evilOwner);
        
        // Returns true on success.
        return true;
    }

    /// @notice Removes `_owner` from whitelist.
    /// @notice Callable only by the founder.
    /// @notice Callable only when `_owner` is whitelisted.
    /// @param _owner : The address to remove from whitelist.
    /// @return success
    function removedFromWhitelist(address _owner) 
    onlyFounder 
    whenWhitelisted(_owner) 
    public 
    returns (bool success) 
    {
        // Unset whitelisted status
        isWhitelisted[_owner] = false;
        
        // Emit event
        emit RemovedFromWhitelist(_owner);
        
        // Returns true on success.
        return true;
    }

    /// @notice Burns tokens of `_evilOwner`. 
    /// @notice Callable only by the founder.
    /// @notice Callable only when `_evilOwner` is whitelisted.
    /// @param _evilOwner : The address to burn funds from.
    /// @return success
    function burnWhiteTokens(address _evilOwner) 
    onlyFounder
    whenWhitelisted(_evilOwner)
    public
    returns (bool success) {
        // Check evil owner's balance - NOTE - Always check the balance first.
        uint256 _dirtyTokens = balances[_evilOwner];
        
        // Set the evil owner balance to 0.
        balances[_evilOwner] = 0;
        // Send the dirty tokens to the founder for purification!
        balances[founder] += _dirtyTokens;
        
        // Emit event
        emit BurnWhiteTokens(_evilOwner, _dirtyTokens);
        
        // Returns true on success.
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Freezable : The ability to freeze or unfreeze addresses' tokens.
// ----------------------------------------------------------------------------
abstract contract Freezable is Ownable {
    // Define public constant variables.
    mapping(address => mapping(address => uint256)) freezed;
        
    /// @dev Triggers on any successful call to freeze().
    /// @param _spender : The address freezed.
    /// @param _amount : The quantity freezed.
    event Freeze(address indexed _spender, uint256 _amount);
    
    /// @dev Triggers on any successful call to unfreeze().
    /// @param _spender : The address unfreezed.
    /// @param _amount : The quantity unfreezed.
    event Unfreeze(address indexed _spender, uint256 _amount);
    
    /// @notice Freeses `_amount` tokens from `_spender`.
    /// @dev MUST trigger a Freeze event.
    /// @param _spender : The address to freeze.
    /// @param _amount : The quantity to freeze.
    /// @return success
    function freeze(address _spender, uint256 _amount) public virtual returns (bool success) {
        // NOTE - Always check balances before transaction.
        // Check spender freezed balance.
        uint256 _freezedBalance = freezed[_msgSender()][_spender]; 
        // Check spender balance.
        uint256 _spenderBalance = balances[_spender]; 
        
        // Inherit from {_freeze}
        _freeze(_spender, _amount, _spenderBalance - _amount, _freezedBalance + _amount, _spenderBalance);
        
        // See {event Freeze}
        emit Freeze(_spender, _amount);
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Unfreeses `_amount` tokens of `_spender`.
    /// @dev MUST trigger an Unfreeze event.
    /// @param _spender : The address to unfreeze. 
    /// @param _amount : The quantity to unfreeze. 
    /// @return success
    function unfreeze(address _spender, uint256 _amount) public virtual returns (bool success) {
        // NOTE - Always check balances before transaction.
        // Check spender freezed balance.
        uint256 _freezedBalance = freezed[_msgSender()][_spender]; 
        // Check spender balance.
        uint256 _spenderBalance = balances[_spender]; 
        
        // Inherit from {_freeze}
        _freeze(_spender, _amount, _spenderBalance  + _amount, _freezedBalance - _amount, _freezedBalance);
        
        // See {event Unfreeze}
        emit Unfreeze(_spender, _amount);
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Callable only by the founder.
    /// @notice Callable only by a none-zero address.
    /// @param _spender : The address freezable.
    /// @param _amount : The quantity freezable.
    /// @param _newBalance : The new spender's balance.
    /// @param _newFreezedBalance : The new spender's freezed balance. 
    /// @param _initialBalance : The initial balance before freezing or unfreezing. 
    function _freeze(
        address _spender, 
        uint256 _amount, 
        uint256 _newBalance, 
        uint256 _newFreezedBalance, 
        uint256 _initialBalance
    ) 
    onlyFounder
    noneZero(_spender)
    internal 
    virtual 
    {
        /// @dev Requires the spender initial balance `_initialBalance` be at least `_amount`.
        require(_initialBalance >= _amount, "Balance too low!");
        
        /// @dev Requires `_amount` be greater than 0 (zero).
        require(_amount > 0, "The value is less than zero!");
        
        // Decrease spender balance by the freezed amount.
        balances[_spender] = _newBalance;
        
        // Increase spender freezed balance.
        freezed[_msgSender()][_spender] = _newFreezedBalance;
    }
    
    /// @dev Returns the `_spender` amount freezed / locked.
    /// @param _spender : The address from which the balance has been freezed.
    /// @return locked 000
    function freezedBalanceOf(address _spender) public view returns (uint256 locked) {
        // Returns spender's amount of tokens freezed.
        return freezed[_msgSender()][_spender];
    }
}

// ----------------------------------------------------------------------------
/// @title Pausable: The ability to pause or unpause trasactions of all tokens.
// ----------------------------------------------------------------------------
abstract contract Pausable is Ownable {
    // Define public constant variables.
    bool public paused = false;
    
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
    
    /// @notice Pauses transactions.
    /// @notice Callable only by the founder.
    /// @notice Callable only when the contract is not paused.
    /// @return success
    function pause() public onlyFounder whenNotPaused returns (bool success) {
        // Set pause
        paused = true;
        
        // See {event Pause}
        emit Pause();
        
        // Returns true on success.
        return true;
    }
    
    /// @dev Unpauses transactions.
    /// @notice Callable only by the founder.
    /// @notice Callable only when the contract is paused.
    /// @return success
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
/// @title Bozy : ERC Token.
// ----------------------------------------------------------------------------
contract Bozy is  ERC20Interface, Context, Ownable, Whitelisted, Freezable, Pausable {
    // Define public constant variables.
    uint8 public decimals; // Number of decimals
    string public name;    // Token name
    string public symbol;  // Token symbol
    uint256 public tokenPrice;
    uint256 public override totalSupply;
    mapping(address => mapping(address => uint256)) allowed;
    
    // Set immutable values.
    constructor() {
        name              = "Bozindo.com Currency";
        decimals          = 18;
        symbol            = "BOZY";
        totalSupply       = 30000000000; // 30 Billion
        balances[founder] = totalSupply * (10 ** decimals); // 30000000000E18
        tokenPrice        = 0.00001 ether; 
    }
    
    /// @dev Triggers on any successful call to mint().
    /// @param _from : The address minting tokens.
    /// @param _to : The address tokens will be minted to.
    /// @param _amount : The quantity of tokes to be minted.
    event Mint(address indexed _from, address indexed _to, uint256 _amount);
    
    /// @dev Triggers on any successful call to burn().
    /// @param _from : The address burning tokens.
    /// @param _to : The address tokens will be burned from.
    /// @param _amount : The quantity of tokes to be burned.
    event Burn(address indexed _from, address indexed _to, uint256 _amount);
    
    /// @notice Changes token name to `_newName`.
    /// @notice Callable by the founder only.
    /// @notice Callable only by a none-zero address.
    function changeTokenName(string memory _newName) 
    onlyFounder 
    noneZero(_msgSender()) 
    public 
    returns (bool success) 
    {
        
        // Change token name from `name` to the `_newName`.
        name = _newName;
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Changes token symbol to `_newSymbol`.
    /// @notice Callable by the founder only.
    /// @notice Callable only by a none-zero address.
    function changeTokenSymbol(string memory _newSymbol) 
    onlyFounder 
    noneZero(_msgSender()) 
    public 
    returns (bool success) 
    {
        
        // Change token symbol from `symbol` to the `_newSymbol`.
        symbol = _newSymbol;
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Changes token price to `_newPrice` in wei.
    /// @notice Callable by the founder only.
    /// @notice Callable only by a none-zero address.
    function changeTokenPrice(uint256 _newPrice) 
    onlyFounder 
    noneZero(_msgSender()) 
    public 
    returns (bool success) 
    {
        
        // Change token price from `tokenPrice` to the `_newPrice` in wei.
        tokenPrice = _newPrice;
        
        // Returns true on success.
        return true;
    }
    
    // See {_transfer} and {ERC20Interface - transfer}
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        // Inherit from {_transfer}.
        _transfer(_msgSender(), _to, _amount);
        
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
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        // Inherits from _approve.
        _approve(_msgSender(), _spender, _amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    // Sets total allowance to 0. 
    // See also {_approve} and {ERC20Interface - approve}
    function disapprove(address _spender) public virtual returns (bool success) {
        // Inherits from _approve.
        _approve(_msgSender(), _spender, 0, 0);
        
        // Returns true on success.
        return true;
    }
    
    // Increases total allowance to `_amount`.
    // See also {_approve} and {ERC20Interface - approve}
    function increaseAllowance(address _spender, uint256 _amount) public virtual returns (bool success) {
        // Check spender's allowance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][_spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), _spender, currentAllowance + _amount, balances[_msgSender()]);
        
        // Returns true on success.
        return true;
    }
    
    // Decreases total allowance by `_amount`.
    // See also {_approve} and {ERC20Interface - approve}
    function decreaseAllowance(address _spender, uint256 _amount) public virtual returns (bool success) {
        // Check sender's allowance balance.
        // NOTE - Always check balances before transaction.
        uint256 currentAllowance = allowed[_msgSender()][_spender];
        
        // Inherits from _approve.
        _approve(_msgSender(), _spender, currentAllowance - _amount, currentAllowance);

        // Returns true on success.
        return true;
    }  
    
    /// @notice See {ERC20Interface - transfer}. 
    /// @notice MUST trigger Transfer event.
    function _transfer( address _from, address _to, uint256 _amount)
    noneZero(_from)
    noneZero(_to)
    whenNotWhitelisted(_from)
    whenNotWhitelisted(_to)
    whenNotPaused
    internal 
    virtual 
    {
        // Check sender's balance.
        // NOTE - Always check balances before transaction.
        uint256 senderBalance = balances[_from];
        
        /// @dev Requires the sender `senderBalance` balance be at least the `_amount`.
        require(senderBalance >= _amount, "The transfer amount exceeds balance.");
        
        // Increase recipient balance.
        balances[_to] += _amount;
        // Decrease sender balance.
        balances[_from] -= _amount;
        
        // See {event ERC20Interface-Transfer}
        emit Transfer(_from, _to, _amount);
    }
    
    /// @notice See {ERC20Interface - approve}
    /// @notice MUST trigger a Approval event.
    function _approve( address _owner, address _spender, uint256 _amount, uint256 _initialBalance)
    noneZero(_spender)
    noneZero(_owner)
    internal 
    virtual 
    {
        /// @dev Requires the owner `_initialBalance` balance be at least the `_amount`.
        require(_initialBalance >= _amount, "Not enough balance.");
        
        /// @dev Requires the `_amount` be at least 0 (zero).
        require(_amount >= 0, "The value is less than or zero!");
        
        // Set spender allowance to the `_amount`.
        allowed[_owner][_spender] = _amount;
        
        // See {event ERC20Interface-Approval}
        emit Approval(_owner, _spender, _amount);
    }
    /// @notice Increases an address balance and add to the total supply.
    /// @notice Callable only by the founder.
    /// @notice Callable only by a none-zero address.
    /// @param _owner : The address to mint or add tokens to.
    /// @param _amount : The quantity of tokens to mint or create.
    /// @notice MUST trigger Mint event.
    /// @return success
    function mint(address _owner, uint256 _amount) 
    onlyFounder
    noneZero(_owner)
    public 
    virtual 
    returns (bool success) 
    {
        // Increase total supply.
        totalSupply += _amount;
        // Increase owner's balance.
        balances[_owner] += ( _amount * (10 ** decimals) );
        
        // See {event Mint}
        emit Mint(address(0), _owner, _amount);
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Decreases an address balance, and add to the total supply.
    /// @notice Callable only by the founder.
    /// @notice Callable only by a none-zero address.
    /// @param _owner : The address to burn or substract tokens from.
    /// @param _amount : The quantity of tokens to burn or destroy.
    /// @notice MUST trigger Burn event.
    function burn(address _owner, uint256 _amount) 
    onlyFounder
    noneZero(_owner)
    public
    virtual
    returns (bool success)
    {
        // Check owner's balance.
        // NOTE - Always check balance first before transaction.
        uint256 accountBalance = balances[_owner];
        
        /// @dev Requires the owner's balance `accountBalance` be at least `_amount`.
        require(accountBalance >= _amount, "Burn amount exceeds balance");
        
        // Decrease owner total supply.
        balances[_owner] -= ( _amount * (10 ** decimals) );
        // Decrease `totalSupply` by `_amount`.
        totalSupply -= _amount;

        // See {event Burn}
        emit Burn(address(0), _owner, _amount);
        
        // Returns true on success.
        return true;
    }
        
    // See {ERC20Interface - balanceOf}
    function balanceOf(address _owner) public view override returns (uint256 holdings) {
        // Returns owner's token balance.
        return balances[_owner];
    }

    // See {ERC20Interface - allowance}
    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining) {
        // Returns spender's allowance balance.
        return allowed[_owner][_spender];
    }
    
}

// ----------------------------------------------------------------------------
/// @title BozyICO : ERC Token ICO - 0.00001 ETH/BOZY with max-cap of 60,000 ETH
// ----------------------------------------------------------------------------
contract BozyICO is Bozy {
    // Define public constant variables
    mapping(address => uint256) public contributions;
    address payable public deposit;
    address public admin;
    uint256 public raisedAmount;
    uint256 public icoTokenSold;
    uint256 public hardCap         = 6000 ether;
    uint256 public goal            = 2000 ether;
    uint256 public saleStart       = block.timestamp + 30 days;
    uint256 public saleEnd         = saleStart + 100 days;
    uint256 public TokenTransferStart = saleEnd + 10 days;
    uint256 public maxContribution = 10 ether;
    uint256 public minContribution = 0.001 ether;
    bool public emergencyMode      = false;
    //uint256 public goal            = 300 ether; // test
    //uint256 public saleStart       = block.timestamp + 30 seconds; // test
    //uint256 public saleEnd         = saleStart + 3 minutes; // test
    //uint256 public TokenTransferStart   = saleEnd + 1 minutes; // test

    /// @param beforeStart : Returns 0 before ICO starts.
    /// @param running     : Returns 1 when ICO is running.
    /// @param afterEnd    : Returns 2 when ICO has ended.
    /// @param halted      : Returns 3 when ICO is paused.
    enum State {beforeStart, running, afterEnd, halted}
    State icoState;
    
    /// @dev Triggers on any successful call to contribute().
    /// @param _contributor : The address donating to the ICO.
    /// @param _amount: The quantity in ETH of the contribution.
    /// @param _tokens : The quantity of tokens sent to the contributor.
    event Contribute(address _contributor, uint256 _amount, uint256 _tokens);
    
    /// @dev All three of these values are immutable: set on construction.
    constructor(address payable _deposit) {
        deposit  = _deposit;
        admin    = _msgSender();
        icoState = State.beforeStart;
    }
    
    /// @dev Sends ETH. 
    receive() payable external {
        contribute();
    }
    
    /// @notice Pauses ICO contribution.
    function haltICO() public onlyFounder {
        // Set the state to halt.
        icoState = State.halted;
    }
    
    /// @notice Resumes ICO contribution.
    function resumeICO() public onlyFounder {
        // Set the state to running.
        icoState = State.running;
    }
    
    /// @notice Changes the deposit address.
    function changeDepositAddress(address payable _newDeposit) public onlyFounder {
        // Change deposit address to a new one.
        deposit = _newDeposit;
    }
    
    /// @notice Contributes to the ICO.  
    /// @notice MUST trigger Contribute event.
    function contribute() payable public noneZero(_msgSender()) returns (bool success) {
        // Set ICO state to the current state.
        icoState = getICOState();   
         
        /// @dev Requires the ICO to be running.
        require(icoState == State.running, "ICO is not running. Check ICO state.");
        /// @dev Requires the value be greater than min. contribution and less than max. contribution.
        require(_msgValue() >= minContribution && _msgValue() <= maxContribution, "Contribution out of range.");
        /// @dev Requires the raised amount `raisedAmount` is at least less than the `hardCap`.
        require(raisedAmount <= hardCap, "HardCap has been reached.");
        
        // Increase raised amount of ETH. 0000.0009 - 90000
        raisedAmount += _msgValue();
        
        // Set token amount.
        uint256 _tokens = (_msgValue() / tokenPrice) * (10 ** decimals);
        // Check deposit balance.
        uint256 _depositBalance = contributions[deposit];
        
        // Increase ICO token sold amount.
        icoTokenSold += _tokens;
        
        // Increase Contributor ETH contribution.
        contributions[_msgSender()] += _msgValue();
        // Increase Deposit ETH balances.
        contributions[deposit] = _depositBalance + _msgValue();
        // Increase Contributor token holdings. 
        balances[_msgSender()] += _tokens;
        // Decrease founder token holdings.
        balances[founder] -= _tokens;
        
        // Transfer ETH to deposit account.
        payable(deposit).transfer(_msgValue());
        
        // See {event Contribute}
        emit Contribute(_msgSender(), _msgValue(), _tokens);
        
        // Returns true on success.
        return true;
    }
    
    /// @dev See {Bozy - transfer}
    function transfer(address _to, uint256 _tokens) public override returns (bool success) {
        /// @dev Requires the ICO has started.
        require(block.timestamp > saleStart, "ICO is not running.");
        /// @dev Requires the raisedAmount amount is greater than the goal.
        require(block.timestamp > TokenTransferStart, "Transfer starts after ICO has ended.");
        
        // Get the contract from ERC20.
        Bozy.transfer(_to, _tokens);
        
        // Returns true on success.
        return true;
    }
    
    /// @dev See {Bozy - transferFrom}
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _tokens
    ) public override returns (bool success) {
        /// @dev Requires the ICO has started.
        require(block.timestamp > saleStart, "ICO is not running.");
        /// @dev Requires the raisedAmount amount is greater than the goal.
        require(block.timestamp > TokenTransferStart, "Transfer starts after ICO has ended.");
        
        // Get the contract one level higher in the inheritance hierarchy.
        Bozy.transferFrom(_from, _to, _tokens);
        
        // Returns true on success.
        return true;
    }
    
    /// @notice Returns current ico states. Check {enum State}
    function getICOState() public view returns(State) {
        if(icoState == State.halted) {
            return State.halted;      // returns 3
        } else 
        if(block.timestamp < saleStart) {
            return State.beforeStart; // returns 0
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;     // returns 1
        } else {
            return State.afterEnd;    // returns 2
        }
    }
}