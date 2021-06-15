/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract BurnRole {
    using Roles for Roles.Role;

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    Roles.Role private _burners;

    constructor () internal {
        _addBurner(msg.sender);
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender));
        _;
    }

    function isBurner(address account) public view returns (bool) {
        return _burners.has(account);
    }

    function addBurner(address account) public onlyBurner {
        _addBurner(account);
    }

    function renounceBurner() public {
        _removeBurner(msg.sender);
    }

    function _addBurner(address account) internal {
        _burners.add(account);
        emit BurnerAdded(account);
    }

    function _removeBurner(address account) internal {
        _burners.remove(account);
        emit BurnerRemoved(account);
    }
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
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
        _approve(msg.sender, spender, value);
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
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20, BurnRole{
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyBurner returns (bool){
        _burn(msg.sender, value);
        return true;
    }
}


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

    function addMinter(address account) external onlyMinter {
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



/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic.
 */
contract ERC20Mintable is ERC20, MinterRole{
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) external onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}


/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }

    /**
     * @return the cap for the token minting.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap);
        super._mint(account, value);
    }
}


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
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

contract RPGBurn is Ownable {
    using Address for address;
    using SafeMath for uint256;

    ERC20Burnable private _token;

    constructor(ERC20Burnable token) public {
        _token = token;
    }

    function burn(uint256 value) onlyOwner public {
        _token.burn(value);
    }
}


contract RPG is
    ERC20,
    ERC20Detailed,
    ERC20Burnable,
    ERC20Capped,
    Ownable
{
    using Address for address;
    uint256 public constant INITIAL_SUPPLY = 21000000 * (10**18);
    mapping(address => uint8) public limit;
    RPGBurn public burnContract;

    constructor(string memory name, string memory symbol)
        public
        Ownable()
        ERC20Capped(INITIAL_SUPPLY)
        ERC20Burnable()
        ERC20Detailed(name, symbol, 18)
        ERC20()
    {
        // mint all tokens
        _mint(msg.sender, INITIAL_SUPPLY);

        // create burner contract
        burnContract = new RPGBurn(this);
        addBurner(address(burnContract));
    }

    /**
     * Set target address transfer limit
     * @param addr target address
     * @param mode limit mode (0: no limit, 1: can not transfer token, 2: can not receive token)
     */
    function setTransferLimit(address addr, uint8 mode) public onlyOwner {
        require(mode == 0 || mode == 1 || mode == 2);

        if (mode == 0) {
            delete limit[addr];
        } else {
            limit[addr] = mode;
        }
    }

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(limit[msg.sender] != 1, 'from address is limited.');
        require(limit[to] != 2, 'to address is limited.');
        
        _transfer(msg.sender, to, value);

        return true;
    }

    function burnFromContract(uint256 value) onlyBurner public {
        burnContract.burn(value);
    }
}

contract RPGVesting is Ownable {
    using Address for address;
    using SafeMath for uint256;

    RPG private _token;
    RPGVestingA private _investors = RPGVestingA(0);
    RPGVestingB private _incubator_adviser;
    RPGVestingC private _development;
    RPGVestingD private _community;
    RPGVestingE private _fund;

    uint256 public INITIAL_SUPPLY;
    
    event event_debug(uint256 amount);

    constructor() public {
        
    }

    function init(
        RPG token,RPGVestingA investors_addr,RPGVestingB incubator_adviser_addr,RPGVestingC development_addr,RPGVestingD community_addr,RPGVestingE fund_addr,
        address[] memory investors,          //10%-----A
        uint256[] memory investors_number,
        address[] memory incubator_advisers, //7%-----B
        uint256[] memory incubator_advisers_number,
        address developments,               //14%----C
        address community,                  //49%----D  mutisigncontract address
        address[3] memory fund              //20%----E
    ) public onlyOwner {
        require(address(_investors) == address(0));     //run once
        
        //para check
        require(address(token) != address(0));
        require(address(investors_addr) != address(0));
        require(address(incubator_adviser_addr) != address(0));
        require(address(development_addr) != address(0));
        require(address(community_addr) != address(0));
        require(address(fund_addr) != address(0));
        require(investors.length == investors_number.length);
        require(incubator_advisers.length == incubator_advisers_number.length);
        require(developments != address(0));
        require(community != address(0));
        require(fund[0] != address(0));
        require(fund[1] != address(0));
        require(fund[2] != address(0));
        //run check
        
        _token = token;
        _investors = investors_addr;
        _incubator_adviser = incubator_adviser_addr;
        _development = development_addr;
        _community = community_addr;
        _fund = fund_addr;
        INITIAL_SUPPLY = _token.INITIAL_SUPPLY();
        require(_token.balanceOf(address(this)) == INITIAL_SUPPLY);
        
        // create all vesting contracts
        // _investors          = new RPGVestingA(_token,INITIAL_SUPPLY.mul(9).div(100));
        // _incubator_adviser  = new RPGVestingB(_token,INITIAL_SUPPLY.mul(7).div(100));
        // _development        = new RPGVestingB(_token,INITIAL_SUPPLY.mul(14).div(100));
        // _community          = new RPGVestingC(_token,community,INITIAL_SUPPLY.mul(49).div(100));
        // _fund               = new RPGVestingD(_token,fund,INITIAL_SUPPLY.mul(21).div(100));

        //init
        require(_investors.init(_token,INITIAL_SUPPLY.mul(10).div(100),investors,investors_number));
        require(_incubator_adviser.init(_token,INITIAL_SUPPLY.mul(7).div(100),incubator_advisers,incubator_advisers_number));
        require(_development.init(_token,developments,INITIAL_SUPPLY.mul(14).div(100)));
        require(_community.init(_token,community,INITIAL_SUPPLY.mul(49).div(100)));
        require(_fund.init(_token,fund,INITIAL_SUPPLY.mul(20).div(100)));

        //transfer tokens to vesting contracts
        _token.transfer(address(_investors)         , _investors.total());
        _token.transfer(address(_incubator_adviser) , _incubator_adviser.total());
        _token.transfer(address(_development)       , _development.total());
        _token.transfer(address(_community)         , _community.total());
        _token.transfer(address(_fund)              , _fund.total());
        
    }

    function StartIDO(uint256 start) public onlyOwner {
        require(start >= block.timestamp);

        _investors.setStart(start);
        _fund.setStart(start);
    }
    
    function StartMainnet(uint256 start) public onlyOwner {
        require(start >= block.timestamp);
        require(start >= _investors.start());

        _incubator_adviser.setStart(start);
        _development.setStart(start);
        _community.setStart(start);
    }
    
    function StartInvestorsClaim() public onlyOwner {
        require(_investors.start() > 0 && _investors.start() < block.timestamp);
        
        _investors.setcanclaim();
    }
    
    function investors() public view returns (address) {
        return address(_investors);
    }
    
    function incubator_adviser() public view returns (address) {
        return address(_incubator_adviser);
    }
    
    function development() public view returns (address) {
        return address(_development);
    }
    
    function community() public view returns (address) {
        return address(_community);
    }
    
    function fund() public view returns (address) {
        return address(_fund);
    }
    
    ////calc vesting number/////////////////////////////
    function unlocked_investors_vesting(address user) public view returns(uint256) {
        return _investors.calcvesting(user);
    }
    
    function unlocked_incubator_adviser_vesting(address user) public view returns(uint256) {
        return _incubator_adviser.calcvesting(user);
    }
    
    function unlocked_development_vesting() public view returns(uint256) {
        return _development.calcvesting();
    }
    
    function unlocked_community_vesting() public view returns(uint256) {
        return _community.calcvesting();
    }
    
    // function calc_fund_vesting() public view returns(uint256) {
    //     return _fund.calcvesting();
    // }
    
    ///////claimed amounts//////////////////////////////
    function claimed_investors(address user) public view returns(uint256){
        return _investors.claimed(user);
    }
    
    function claimed_incubator_adviser(address user) public view returns(uint256){
        return _incubator_adviser.claimed(user);
    }
    
    function claimed_development() public view returns(uint256){
        return _development.claimed();
    }
    
    function claimed_community() public view returns(uint256){
        return _community.claimed();
    }
    
    //////change address/////////////////////////////////
    function investors_changeaddress(address oldaddr,address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _investors.changeaddress(oldaddr,newaddr);
    }
    
    function incubator_adviser_changeaddress(address oldaddr,address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _incubator_adviser.changeaddress(oldaddr,newaddr);
    }
    
    function community_changeaddress(address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _community.changeaddress(newaddr);
    }
    
}

contract RPGVestingA {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;
    IERC20 private _token;
    uint256 private _total;
    uint256 private _start = 0;
    bool    private _canclaim = false;
    address[] private _beneficiarys;
    uint256 constant _duration = 86400;
    uint256 constant _releasealldays = 400;
    mapping(address => uint256) private _beneficiary_total;
    mapping(address => uint256) private _released;
    
    //event 
    event event_claimed(address user,uint256 amount);
    event event_change_address(address oldaddr,address newaddr);
    
    constructor(address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token, uint256 total,address[] memory beneficiarys,uint256[] memory amounts) public returns(bool) {
        require(_vestingaddr == msg.sender);
        require(_beneficiarys.length == 0);     //run once
        
        require(address(token) != address(0));
        require(total > 0);
        require(beneficiarys.length == amounts.length);
        
        _token = token;
        _total = total;
        
        uint256 all = 0;
        for(uint256 i = 0 ; i < amounts.length; i++)
        {
            all = all.add(amounts[i]);
        }
        require(all == _total);
        
        _beneficiarys = beneficiarys;
        for(uint256 i = 0 ; i < _beneficiarys.length; i++)
        {
            _beneficiary_total[_beneficiarys[i]] = amounts[i];
            _released[_beneficiarys[i]] = 0;
        }
        return true;
    }
    
    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
    * @return the start time of the token vesting.
    */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address[] memory) {
        return _beneficiarys;
    }

    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }
    
    /**
     * @return canclaim.
     */
    function canclaim() public view returns (bool) {
        return _canclaim;
    }
    
    function setcanclaim() public {
        require(_vestingaddr == msg.sender);
        require(_canclaim == false);
        
        _canclaim = true;
    }

    /**
     * @return total number can release to now.
     */
    function calcvesting(address user) public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        require(_beneficiary_total[user] > 0);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        if(daynum <= _releasealldays)
        {
            return _beneficiary_total[user].mul(daynum).div(_releasealldays);
        }
        else
        {
            return _beneficiary_total[user];
        }
    }
    
    /**
     * claim all the tokens to now
     * @return claim number this time .
     */
    function claim() external returns(uint256) {
        require(_start > 0);
        require(_beneficiary_total[msg.sender] > 0);
        require(_canclaim == true);
        
        uint256 amount = calcvesting(msg.sender).sub(_released[msg.sender]);
        if(amount > 0)
        {
            _released[msg.sender] = _released[msg.sender].add(amount);
            _token.safeTransfer(msg.sender,amount);
            emit event_claimed(msg.sender,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed(address user) public view returns(uint256) {
        require(_start > 0);
        
        return _released[user];
    }
    
    function changeaddress(address oldaddr,address newaddr) public {
        require(_beneficiarys.length > 0);
        require(_beneficiary_total[newaddr] == 0);
        
        if(msg.sender == _vestingaddr)
        {
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == oldaddr)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[oldaddr];
                    _beneficiary_total[oldaddr] = 0;
                    _released[newaddr] = _released[oldaddr];
                    _released[oldaddr] = 0;
                    
                    emit event_change_address(oldaddr,newaddr);
                    return;
                }
            }
        }
        else
        {
            require(msg.sender == oldaddr);
            
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == msg.sender)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[msg.sender];
                    _beneficiary_total[msg.sender] = 0;
                    _released[newaddr] = _released[msg.sender];
                    _released[msg.sender] = 0;
                    
                    emit event_change_address(msg.sender,newaddr);
                    return;
                }
            }
        }
    } 
}


contract RPGVestingB {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;
    IERC20 private _token;
    address[] private _beneficiarys;
    uint256 private _total;
    uint256 private _start = 0;
    uint256 constant _duration = 86400;
    uint256 constant _releaseperiod = 180;
    mapping(address => uint256) private _beneficiary_total;
    mapping(address => uint256) private _released;
    
    //event 
    event event_claimed(address user,uint256 amount);
    event event_change_address(address oldaddr,address newaddr);
    
    constructor(address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token,uint256 total,address[] memory beneficiarys,uint256[] memory amounts) public returns(bool) {
        require(_vestingaddr == msg.sender);
        require(_beneficiarys.length == 0); //run once
        
        require(address(token) != address(0));
        require(total > 0);
        require(beneficiarys.length == amounts.length);
        
        _token = token;
        _total = total;
    
        uint256 all = 0;
        for(uint256 i = 0 ; i < amounts.length; i++)
        {
            all = all.add(amounts[i]);
        }
        require(all == _total);
        
        _beneficiarys = beneficiarys;
        for(uint256 i = 0 ; i < _beneficiarys.length; i++)
        {
            _beneficiary_total[_beneficiarys[i]] = amounts[i];
            _released[_beneficiarys[i]] = 0;
        }
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address[] memory) {
        return _beneficiarys;
    }
    
    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }
    
    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    
    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }
    
    /**
     * @return number to now.
     */
    function calcvesting(address user) public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        require(_beneficiary_total[user] > 0);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        uint256 counts180 = daynum.div(_releaseperiod);
        uint256 dayleft = daynum.mod(_releaseperiod);
        uint256 amount180 = 0;
        uint256 thistotal = _beneficiary_total[user].mul(8).div(100);
        for(uint256 i = 0; i< counts180; i++)
        {
            amount180 = amount180.add(thistotal);
            thistotal = thistotal.mul(92).div(100);     //thistotal.mul(100).div(8).mul(92).div(100).mul(8).div(100);     //next is thistotal/(0.08)*0.92*0.08
        }
        
        return amount180.add(thistotal.mul(dayleft).div(_releaseperiod));
    }

    /**
     * claim all the tokens to now
     * @return claim number this time .
     */
    function claim() external returns(uint256) {
        require(_start > 0);
        require(_beneficiary_total[msg.sender] > 0);
        
        uint256 amount = calcvesting(msg.sender).sub(_released[msg.sender]);
        if(amount > 0)
        {
            _released[msg.sender] = _released[msg.sender].add(amount);
            _token.safeTransfer(msg.sender,amount);
            emit event_claimed(msg.sender,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed(address user) public view returns(uint256) {
        require(_start > 0);
        
        return _released[user];
    }

    function changeaddress(address oldaddr,address newaddr) public {
        require(_beneficiarys.length > 0);
        require(_beneficiary_total[newaddr] == 0);
        
        if(msg.sender == _vestingaddr) 
        {
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == oldaddr)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[oldaddr];
                    _beneficiary_total[oldaddr] = 0;
                    _released[newaddr] = _released[oldaddr];
                    _released[oldaddr] = 0;
                    
                    emit event_change_address(oldaddr,newaddr);
                    return;
                }
            }
        }
        else
        {
            require(msg.sender == oldaddr);
            
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == msg.sender)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[msg.sender];
                    _beneficiary_total[msg.sender] = 0;
                    _released[newaddr] = _released[msg.sender];
                    _released[msg.sender] = 0;
                    
                    emit event_change_address(msg.sender,newaddr);
                    return;
                }
            }
        }
    }
}

contract RPGVestingC {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). 
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;

    event event_claimed(address user,uint256 amount);
    
    IERC20 private _token;
    uint256 private _total;
    uint256 constant _duration = 86400;
    uint256 constant _releaseperiod = 180;
    uint256 private _released = 0;

    // beneficiary of tokens after they are released
    address private _beneficiary = address(0);
    uint256 private _start = 0;

    constructor (address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token,address beneficiary, uint256 total) public returns(bool){
        require(_vestingaddr == msg.sender);
        require(_beneficiary == address(0));    //run once
        
        require(address(token) != address(0));
        require(beneficiary != address(0));
        require(total > 0);
        
        _token = token;
        _beneficiary = beneficiary;
        _total = total;
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    
    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }

    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
     * @return number to now.
     */
    function calcvesting() public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        uint256 counts180 = daynum.div(_releaseperiod);
        uint256 dayleft = daynum.mod(_releaseperiod);
        uint256 amount180 = 0;
        uint256 thistotal = _total.mul(8).div(100);
        for(uint256 i = 0; i< counts180; i++)
        {
            amount180 = amount180.add(thistotal);
            thistotal = thistotal.mul(92).div(100);         //thistotal.mul(100).div(8).mul(92).div(100).mul(8).div(100);     //next is thistotal/(0.08)*0.92*0.08
        }
        
        return amount180.add(thistotal.mul(dayleft).div(_releaseperiod));
    }

    /**
     * @return number of this claim
     */
    function claim() external returns(uint256) {
        require(_start > 0);
        
        uint256 amount = calcvesting().sub(_released);
        if(amount > 0)
        {
            _released = _released.add(amount);
            _token.safeTransfer(_beneficiary,amount);
            emit event_claimed(msg.sender,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed() public view returns(uint256) {
        require(_start > 0);
        
        return _released;
    }
}

contract RPGVestingD {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). 
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;

    event event_claimed(address user,uint256 amount);

    IERC20 private _token;
    uint256 private _total;
    uint256 constant _duration = 86400;
    uint256 constant _releaseperiod = 180;
    uint256 private _released = 0;

    // beneficiary of tokens after they are released
    address private _beneficiary = address(0);
    uint256 private _start = 0;

    constructor (address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;

    }
    
    function init(IERC20 token,address beneficiary, uint256 total) public returns(bool){
        require(_vestingaddr == msg.sender);
        require(_beneficiary == address(0));    //run once
        
        require(address(token) != address(0));
        require(beneficiary != address(0));
        require(total > 0);
        
        _token = token;
        _beneficiary = beneficiary;
        _total = total;
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    
    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }

    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
     * @return number to now.
     */
    function calcvesting() public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        uint256 counts180 = daynum.div(_releaseperiod);
        uint256 dayleft = daynum.mod(_releaseperiod);
        uint256 amount180 = 0;
        uint256 thistotal = _total.mul(8).div(100);
        for(uint256 i = 0; i< counts180; i++)
        {
            amount180 = amount180.add(thistotal);
            thistotal = thistotal.mul(92).div(100);                //thistotal.mul(100).div(8).mul(92).div(100).mul(8).div(100);     //next is thistotal/(0.08)*0.92*0.08
        }
        
        return amount180.add(thistotal.mul(dayleft).div(_releaseperiod));
    }

    /**
     * @return number of this claim
     */
    function claim() external returns(uint256) {
        require(_start > 0);
        
        uint256 amount = calcvesting().sub(_released);
        if(amount > 0)
        {
            _released = _released.add(amount);
            _token.safeTransfer(_beneficiary,amount);
            emit event_claimed(_beneficiary,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed() public view returns(uint256) {
        require(_start > 0);
        
        return _released;
    }
    
    //it must approve , before call this function
    function changeaddress(address newaddr) public {
        require(_beneficiary != address(0));
        require(msg.sender == _vestingaddr);
        
        _token.safeTransferFrom(_beneficiary,newaddr,_token.balanceOf(_beneficiary));
        _beneficiary = newaddr;
    } 
}

contract RPGVestingE {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). 
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;

    event event_claimed(address user,uint256 amount);

    IERC20 private _token;
    uint256 private _total;

    // beneficiary of tokens after they are released
    address[3] private _beneficiarys;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    //uint256 private _phase;
    uint256 private _start = 0;
    //uint256 private _duration;

    //bool private _revocable;

    constructor (address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token,address[3] memory beneficiarys, uint256 total) public returns(bool){
        require(_vestingaddr == msg.sender);
        
        require(address(token) != address(0));
        require(beneficiarys[0] != address(0));
        require(beneficiarys[1] != address(0));
        require(beneficiarys[2] != address(0));
        require(total > 0);
        
        _token = token;
        _beneficiarys = beneficiarys;
        _total = total;
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address[3] memory) {
        return _beneficiarys;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    
    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }

    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
     * @notice Transfers tokens to beneficiary.
     */
    function claim() external returns(uint256){
        require(_start > 0);

        _token.safeTransfer(_beneficiarys[0], _total.mul(8).div(20));
        emit event_claimed(_beneficiarys[0],_total.mul(8).div(20));
        
        _token.safeTransfer(_beneficiarys[1], _total.mul(7).div(20));
        emit event_claimed(_beneficiarys[1],_total.mul(7).div(20));
        
        _token.safeTransfer(_beneficiarys[2], _total.mul(5).div(20));
        emit event_claimed(_beneficiarys[2],_total.mul(5).div(20));
        return _total;

        //emit TokensReleased(address(token), unreleased);
    }
    
    /**
     * @return all number has claimed
     */
    function claimed() public view returns(uint256) {
        require(_start > 0);
        
        uint256 amount0 = _token.balanceOf(_beneficiarys[0]);
        uint256 amount1 = _token.balanceOf(_beneficiarys[1]);
        uint256 amount2 = _token.balanceOf(_beneficiarys[2]);
        return amount0.add(amount1).add(amount2);
    }

}