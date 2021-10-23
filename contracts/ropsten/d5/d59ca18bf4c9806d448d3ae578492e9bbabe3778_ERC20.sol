/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-23
*/

/**
 * Invictus Capital - CRYPTO10 Hedged
 * https://invictuscapital.com
 * MIT License - https://github.com/invictuscapital/smartcontracts/
 * Uses code from the OpenZeppelin project
 */


// File: contracts/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.6;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.6;


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

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.6;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
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
    function allowance(address owner, address spender) public view returns (uint256) {
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
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
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
        require(account != address(0));

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
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: contracts/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.6;


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
}

// File: contracts/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.6;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: contracts/openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.6;

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
     * @dev remove an account's access to this role
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts/openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.6;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: contracts/openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.6;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.6;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
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

// File: contracts/openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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

// File: contracts/openzeppelin-solidity/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.6;


/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol

pragma solidity ^0.5.6;



/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/InvictusWhitelist.sol

pragma solidity ^0.5.6;



/**
 * Manages whitelisted addresses.
 *
 */
contract InvictusWhitelist is Ownable, WhitelistedRole {
    constructor ()
        WhitelistedRole() public {
    }

    /// @dev override to support legacy name
    function verifyParticipant(address participant) public onlyWhitelistAdmin {
        if (!isWhitelisted(participant)) {
            addWhitelisted(participant);
        }
    }

    /// Allow the owner to remove a whitelistAdmin
    function removeWhitelistAdmin(address account) public onlyOwner {
        require(account != msg.sender, "Use renounceWhitelistAdmin");
        _removeWhitelistAdmin(account);
    }
}

// File: contracts/C10Token.sol

pragma solidity ^0.5.6;











/**
 * Contract for CRYPTO10 Hedged (C10) fund.
 *
 */
contract Pecalla is ERC20, ERC20Detailed, ERC20Burnable, Ownable, Pausable, MinterRole {

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    // Maps participant addresses to the eth balance pending token issuance
    mapping(address => uint256) public pendingBuys;
    // The participant accounts waiting for token issuance
    address[] public participantAddresses;

    // Maps participant addresses to the withdrawal request
    mapping (address => uint256) public pendingWithdrawals;
    address payable[] public withdrawals;

    uint256 private minimumWei = 50 finney;
    uint256 private fees = 5;  // 0.5% , or 5/1000
    uint256 private minTokenRedemption = 1 ether;
    uint256 private maxAllocationsPerTx = 50;
    uint256 private maxWithdrawalsPerTx = 50;
    Price public price;

    address public whitelistContract;

    struct Price {
        uint256 numerator;
        uint256 denominator;
    }

    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 value);
    event RemoveLiquidity(uint256 value);
    event DepositReceived(address indexed participant, uint256 value);
    event TokensIssued(address indexed participant, uint256 amountTokens, uint256 etherAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
    event TokensClaimed(address indexed token, uint256 balance);

    constructor (uint256 priceNumeratorInput, address whitelistContractInput)
        ERC20Detailed("Crypto10 Hedged", "C10", 18)
        ERC20Burnable()
        Pausable() public {
            price = Price(priceNumeratorInput, 1000);
            require(priceNumeratorInput > 0, "Invalid price numerator");
            require(whitelistContractInput != address(0), "Invalid whitelist address");
            whitelistContract = whitelistContractInput;
    }

    /**
     * @dev fallback function that buys tokens if the sender is whitelisted.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Explicitly buy via contract.
     */
    function buy() external payable {
        buyTokens(msg.sender);
    }

    /**
     * Sets the maximum number of allocations in a single transaction.
     * @dev Allows us to configure batch sizes and avoid running out of gas.
     */
    function setMaxAllocationsPerTx(uint256 newMaxAllocationsPerTx) external onlyOwner {
        require(newMaxAllocationsPerTx > 0, "Must be greater than 0");
        maxAllocationsPerTx = newMaxAllocationsPerTx;
    }

    /**
     * Sets the maximum number of withdrawals in a single transaction.
     * @dev Allows us to configure batch sizes and avoid running out of gas.
     */
    function setMaxWithdrawalsPerTx(uint256 newMaxWithdrawalsPerTx) external onlyOwner {
        require(newMaxWithdrawalsPerTx > 0, "Must be greater than 0");
        maxWithdrawalsPerTx = newMaxWithdrawalsPerTx;
    }

    /// Sets the minimum wei when buying tokens.
    function setMinimumBuyValue(uint256 newMinimumWei) external onlyOwner {
        require(newMinimumWei > 0, "Minimum must be greater than 0");
        minimumWei = newMinimumWei;
    }

    /// Sets the minimum number of tokens to redeem.
    function setMinimumTokenRedemption(uint256 newMinTokenRedemption) external onlyOwner {
        require(newMinTokenRedemption > 0, "Minimum must be greater than 0");
        minTokenRedemption = newMinTokenRedemption;
    }

    /// Updates the price numerator.
    function updatePrice(uint256 newNumerator) external onlyMinter {
        require(newNumerator > 0, "Must be positive value");

        price.numerator = newNumerator;

        allocateTokens();
        processWithdrawals();
        emit PriceUpdate(price.numerator, price.denominator);
    }

    /// Updates the price denominator.
    function updatePriceDenominator(uint256 newDenominator) external onlyMinter {
        require(newDenominator > 0, "Must be positive value");

        price.denominator = newDenominator;
    }

    /**
     * Whitelisted token holders can request token redemption, and withdraw ETH.
     * @param amountTokensToWithdraw The number of tokens to withdraw.
     * @dev withdrawn tokens are burnt.
     */
    function requestWithdrawal(uint256 amountTokensToWithdraw) external whenNotPaused 
        onlyWhitelisted {

        address payable participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw, 
            "Cannot withdraw more than balance held");
        require(amountTokensToWithdraw >= minTokenRedemption, "Too few tokens");

        burn(amountTokensToWithdraw);

        uint256 pendingAmount = pendingWithdrawals[participant];
        if (pendingAmount == 0) {
            withdrawals.push(participant);
        }
        pendingWithdrawals[participant] = pendingAmount.add(amountTokensToWithdraw);
        emit WithdrawRequest(participant, amountTokensToWithdraw);
    }

    /// Allows owner to claim any ERC20 tokens.
    function claimTokens(ERC20 token) external payable onlyOwner {
        require(address(token) != address(0), "Invalid address");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), token.balanceOf(address(this)));
        emit TokensClaimed(address(token), balance);
    }
    
    /**
     * @dev Allows the owner to burn a specific amount of tokens on a participant's behalf.
     * @param value The amount of tokens to be burned.
     */
    function burnForParticipant(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }

    /**
     * @dev Function to mint tokens when not paused.
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter whenNotPaused returns (bool) {
        _mint(to, value);

        return true;
    }

    /// Adds liquidity to the contract, allowing anyone to deposit ETH
    function addLiquidity() public payable {
        require(msg.value > 0, "Must be positive value");
        emit AddLiquidity(msg.value);
    }

    /// Removes liquidity, allowing managing wallets to transfer eth to the fund wallet.
    function removeLiquidity(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        msg.sender.transfer(amount);
        emit RemoveLiquidity(amount);
    }

    /// Allow the owner to remove a minter
    function removeMinter(address account) public onlyOwner {
        require(account != msg.sender, "Use renounceMinter");
        _removeMinter(account);
    }

    /// Allow the owner to remove a pauser
    function removePauser(address account) public onlyOwner {
        require(account != msg.sender, "Use renouncePauser");
        _removePauser(account);
    }

    /// returns the number of withdrawals pending.
    function numberWithdrawalsPending() public view returns (uint256) {
        return withdrawals.length;
    }

    /// returns the number of pending buys, waiting for token issuance.
    function numberBuysPending() public view returns (uint256) {
        return participantAddresses.length;
    }

    /**
     * First phase of the 2-part buy, the participant deposits eth and waits
     * for a price to be set so the tokens can be minted.
     * @param participant whitelisted buyer.
     */
    function buyTokens(address participant) internal whenNotPaused onlyWhitelisted {
        assert(participant != address(0));

        // Ensure minimum investment is met
        require(msg.value >= minimumWei, "Minimum wei not met");

        uint256 pendingAmount = pendingBuys[participant];
        if (pendingAmount == 0) {
            participantAddresses.push(participant);
        }

        // Increase the pending balance and wait for the price update
        pendingBuys[participant] = pendingAmount.add(msg.value);

        emit DepositReceived(participant, msg.value);
    }

    /// Internal function to allocate token.
    function allocateTokens() internal {
        uint256 numberOfAllocations = participantAddresses.length <= maxAllocationsPerTx ? 
            participantAddresses.length : maxAllocationsPerTx;
        
        address payable ownerAddress = address(uint160(owner()));
        for (uint256 i = numberOfAllocations; i > 0; i--) {
            address participant = participantAddresses[i - 1];
            uint256 deposit = pendingBuys[participant];
            uint256 feeAmount = deposit.mul(fees) / 1000;
            uint256 balance = deposit.sub(feeAmount);

            uint256 newTokens = balance.mul(price.numerator) / price.denominator;
            pendingBuys[participant] = 0;
            participantAddresses.pop();

            ownerAddress.transfer(feeAmount);

            mint(participant, newTokens);   
            emit TokensIssued(participant, newTokens, balance);
        }
    }

    /// Internal function to process withdrawals.
    function processWithdrawals() internal {
        uint256 numberOfWithdrawals = withdrawals.length <= maxWithdrawalsPerTx ? 
            withdrawals.length : maxWithdrawalsPerTx;

        address payable ownerAddress = address(uint160(owner()));
        for (uint256 i = numberOfWithdrawals; i > 0; i--) {
            address payable participant = withdrawals[i - 1];
            uint256 tokens = pendingWithdrawals[participant];

            assert(tokens > 0); // participant must have requested a withdrawal

            uint256 withdrawValue = tokens.mul(price.denominator) / price.numerator;

            pendingWithdrawals[participant] = 0;
            withdrawals.pop();

            if (address(this).balance >= withdrawValue) {
                uint256 feeAmount = withdrawValue.mul(fees) / 1000;
                uint256 balance = withdrawValue.sub(feeAmount);

                participant.transfer(balance);

                ownerAddress.transfer(feeAmount);

                emit Withdraw(participant, tokens, balance);
            }
            else {
                mint(participant, tokens);
                emit Withdraw(participant, tokens, 0); // indicate a failed withdrawal
            }
        }
    }

    modifier onlyWhitelisted() {
        require(InvictusWhitelist(whitelistContract).isWhitelisted(msg.sender), "Must be whitelisted");
        _;
    }
}