/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.5.7;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient,
     * reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
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


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Ownable
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract
     * to the sender account.
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
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Rescue compatible ERC20 Token
     *
     * @param tokenAddr ERC20 The address of the ERC20 token contract
     * @param receiver The address of the receiver
     * @param amount uint256
     */
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));
        
        require(balance >= amount);
        assert(_token.transfer(receiver, amount));
    }

    /**
     * @dev Withdraw Ether
     */
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));
        
        uint256 balance = address(this).balance;
        
        require(balance >= amount);
        to.transfer(amount);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor () internal {
        _paused = false;
    }

    /**
     * @return Returns true if the contract is paused, false otherwise.
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
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title Foken Main Contract
 */
contract Foken is Ownable, Pausable, IERC20 {
    using SafeMath for uint256;

    string private _name = "Foken";
    string private _symbol = "Foken";
    uint8 private _decimals = 6;                // 6 decimals
    uint256 private _cap = 35000000000000000;   // 35 billion cap, that is 35000000000.000000
    uint256 private _totalSupply;
    
    mapping (address => bool) private _minter;
    event Mint(address indexed to, uint256 value);
    event MinterChanged(address account, bool state);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    bool private _allowWhitelistRegistration;
    mapping(address => address) private _referrer;
    mapping(address => uint256) private _refCount;

    event FokenSaleWhitelistRegistered(address indexed addr, address indexed refAddr);
    event FokenSaleWhitelistTransferred(address indexed previousAddr, address indexed _newAddr);
    event FokenSaleWhitelistRegistrationEnabled();
    event FokenSaleWhitelistRegistrationDisabled();

    uint256 private _whitelistRegistrationValue = 888000000;   // 888 Foken, 888.000000
    uint256[15] private _whitelistRefRewards = [                // 100% Reward
        301000000,  // 301 Foken for Level.1
        200000000,  // 200 Foken for Level.2
        100000000,  // 100 Foken for Level.3
        100000000,  // 100 Foken for Level.4
        100000000,  // 100 Foken for Level.5
        50000000,   //  50 Foken for Level.6
        40000000,   //  40 Foken for Level.7
        30000000,   //  30 Foken for Level.8
        20000000,   //  20 Foken for Level.9
        10000000,   //  10 Foken for Level.10
        10000000,   //  10 Foken for Level.11
        10000000,   //  10 Foken for Level.12
        10000000,   //  10 Foken for Level.13
        10000000,   //  10 Foken for Level.14
        10000000    //  10 Foken for Level.15
    ];

    event Donate(address indexed account, uint256 amount);


    /**
     * @dev Constructor
     */
    constructor() public {
        _minter[msg.sender] = true;
        _allowWhitelistRegistration = true;

        emit FokenSaleWhitelistRegistrationEnabled();

        _referrer[msg.sender] = msg.sender;
        emit FokenSaleWhitelistRegistered(msg.sender, msg.sender);
    }


    /**
     * @dev donate
     */
    function () external payable {
        emit Donate(msg.sender, msg.value);
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

    /**
     * @return the cap for the token minting.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }
    
    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        if (_allowWhitelistRegistration && value == _whitelistRegistrationValue
            && inWhitelist(to) && !inWhitelist(msg.sender) && isNotContract(msg.sender)) {
            // Register whitelist for Foken-Sale
            _regWhitelist(msg.sender, to);
            return true;
        } else {
            // Normal Transfer
            _transfer(msg.sender, to, value);
            return true;
        }
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    /**
     * @dev Transfer tokens from one address to another.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(_allowed[from][msg.sender] >= value);
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
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
     * @dev Approve an address to spend another addresses&#39; tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    /**
     * @dev Throws if called by account not a minter.
     */
    modifier onlyMinter() {
        require(_minter[msg.sender]);
        _;
    }

    /**
     * @dev Returns true if the given account is minter.
     */
    function isMinter(address account) public view returns (bool) {
        return _minter[account];
    }

    /**
     * @dev Set a minter state
     */
    function setMinterState(address account, bool state) external onlyOwner {
        _minter[account] = state;
        emit MinterChanged(account, state);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to an account.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(_totalSupply.add(value) <= _cap);
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Mint(account, value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Throws if called by account not in whitelist.
     */
    modifier onlyInWhitelist() {
        require(_referrer[msg.sender] != address(0));
        _;
    }

    /**
     * @dev Returns true if the whitelist registration is allowed.
     */
    function allowWhitelistRegistration() public view returns (bool) {
        return _allowWhitelistRegistration;
    }

    /**
     * @dev Returns true if the given account is in whitelist.
     */
    function inWhitelist(address account) public view returns (bool) {
        return _referrer[account] != address(0);
    }

    /**
     * @dev Returns the referrer of a given account address
     */
    function referrer(address account) public view returns (address) {
        return _referrer[account];
    }

    /**
     * @dev Returns the referrals count of a given account address
     */
    function refCount(address account) public view returns (uint256) {
        return _refCount[account];
    }

    /**
     * @dev Disable Foken-Sale whitelist registration. Unrecoverable!
     */
    function disableFokenSaleWhitelistRegistration() external onlyOwner {
        _allowWhitelistRegistration = false;
        emit FokenSaleWhitelistRegistrationDisabled();
    }

    /**
     * @dev Register whitelist for Foken-Sale
     */
    function _regWhitelist(address account, address refAccount) internal {
        _refCount[refAccount] = _refCount[refAccount].add(1);
        _referrer[account] = refAccount;

        emit FokenSaleWhitelistRegistered(account, refAccount);

        // Whitelist Registration Referral Reward
        _transfer(msg.sender, address(this), _whitelistRegistrationValue);
        address cursor = account;
        uint256 remain = _whitelistRegistrationValue;
        for(uint i = 0; i < _whitelistRefRewards.length; i++) {
            address receiver = _referrer[cursor];

            if (cursor != receiver) {
                if (_refCount[receiver] > i) {
                    _transfer(address(this), receiver, _whitelistRefRewards[i]);
                    remain = remain.sub(_whitelistRefRewards[i]);
                }
            } else {
                _transfer(address(this), refAccount, remain);
                break;
            }

            cursor = _referrer[cursor];
        }
    }

    /**
     * @dev Transfer the whitelisted address to another.
     */
    function transferWhitelist(address account) external onlyInWhitelist {
        require(isNotContract(account));

        _refCount[account] = _refCount[msg.sender];
        _refCount[msg.sender] = 0;
        _referrer[account] = _referrer[msg.sender];
        _referrer[msg.sender] = address(0);
        emit FokenSaleWhitelistTransferred(msg.sender, account);
    }

    /**
     * @dev Returns true if the given address is not a contract
     */
    function isNotContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size == 0;
    }

    /**
     * @dev Calculator
     * Returns the reward amount if someone now registers the whitelist directly with the given whitelistedAccount.
     */
    function calculateTheRewardOfDirectWhitelistRegistration(address whitelistedAccount) external view returns (uint256 reward) {
        if (!inWhitelist(whitelistedAccount)) {
            return 0;
        }

        address cursor = whitelistedAccount;
        uint256 remain = _whitelistRegistrationValue;
        for(uint i = 1; i < _whitelistRefRewards.length; i++) {
            address receiver = _referrer[cursor];

            if (cursor != receiver) {
                if (_refCount[receiver] > i) {
                    remain = remain.sub(_whitelistRefRewards[i]);
                }
            } else {
                reward = reward.add(remain);
                break;
            }

            cursor = _referrer[cursor];
        }

        return reward;
    }
}