/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity >=0.4.22 <0.6.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transferAndLock(
        address receiver,
        uint256 amount,
        uint256 releaseDate
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    uint256 private _totalSupply = 0;

    /**
     * @dev Total number of tokens in existence
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
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
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
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards
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
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
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
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

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
 * @title Pausable
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     * Requirements:
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     * Requirements:
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
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

contract CarbonToken is ERC20, Pausable, ERC20Detailed {
    address carbonianWallet = 0x5B92e4dD06E3E39025DC25baCe3eD62C8989f52E; // Carbonian (Master Wallet)
    address projectOwnerWallet = 0x11c6CaB01BBc9802B658Fcf1cA15fD0F1bB337E9; // Combating Climate Change Projects
    address co2CorpWallet = 0x86e4ecb15ed4fe220770a9Ab9195c450eD0B06B3; // CO2-1-0 (CARBON) CORP
    address privateSaleWallet = 0x7973659D9Ca8f0FA8A8aC6beF941149885bC55A0; // Private Sale (VCs & HNWIs)
    address presaleIDOWallet = 0xc8965C1274F445EA0ABe9A1CbCD0BBE3800Af129; // Pre Sale /IDO (Air Drop, Bounty, Community, Etc.)
    address workingTeamWallet = 0xc8965C1274F445EA0ABe9A1CbCD0BBE3800Af129; // Working Team
    address boardOfAdvisoryWallet = 0xE041F0B8fb73B9902D8df14b1BD494162b4Ac876; // Board of Advisory
    address offsetterWallet = 0x22Bb14665BCf3A9A23071871d434D27e04af6B8e; // Offsetter

    uint256 private totalCoins;
    struct LockItem {
        uint256 releaseDate;
        uint256 amount;
    }

    mapping(address => LockItem[]) private lockList;
    mapping(uint256 => uint256) private quarterMap;
    address[] private lockedAddressList; // list of addresses that have some fund currently or previously locked

    constructor() public ERC20Detailed("Carbon-10", "CO2", 9) {
        totalCoins = 1000000000 * 10**uint256(decimals());
        _mint(owner(), totalCoins); // total supply fixed at 1 billion tokens
        ERC20.transfer(presaleIDOWallet, 50000000 * 10**uint256(decimals())); // transfer 50 million tokens
        transferAndLock(
            privateSaleWallet,
            25000000 * 10**uint256(decimals()),
            1666396800
        ); // transfer 25 million tokens and lock up until Sat Oct 22 2022 00:00:00 GMT
    }

    /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success.
     * @param receiver The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address receiver, uint256 amount)
        public
        whenNotPaused
        returns (bool success)
    {
        require(receiver != address(0));
        require(amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(receiver, amount);
    }

    /**
     * @dev transfer of token on behalf of the owner to another address.
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success.
     * @param from The address to transfer from.
     * @param receiver The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transferFrom(
        address from,
        address receiver,
        uint256 amount
    ) public whenNotPaused returns (bool success) {
        require(from != address(0));
        require(receiver != address(0));
        require(amount <= allowance(from, msg.sender));
        require(amount <= getAvailableBalance(from));
        return ERC20.transferFrom(from, receiver, amount);
    }

    /**
     * @dev transfer to a given address a given amount and lock this fund until a given time
     * used for sending fund to team members, partners, or for owner to lock service fund over time
     * @return the bool true if success.
     * @param receiver The address to transfer to.
     * @param amount The amount to transfer.
     * @param releaseDate The date to release token.
     */

    function transferAndLock(
        address receiver,
        uint256 amount,
        uint256 releaseDate
    ) public whenNotPaused returns (bool success) {
        ERC20._transfer(msg.sender, receiver, amount);
        if (lockList[receiver].length == 0) lockedAddressList.push(receiver);
        LockItem memory item = LockItem({
            amount: amount,
            releaseDate: releaseDate
        });
        lockList[receiver].push(item);

        return true;
    }

    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
    function getLockedAmount(address lockedAddress)
        public
        view
        returns (uint256 _amount)
    {
        uint256 lockedAmount = 0;
        for (uint256 j = 0; j < lockList[lockedAddress].length; j++) {
            if (now < lockList[lockedAddress][j].releaseDate) {
                uint256 temp = lockList[lockedAddress][j].amount;
                lockedAmount += temp;
            }
        }
        return lockedAmount;
    }

    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
    function getAvailableBalance(address lockedAddress)
        public
        view
        returns (uint256 _amount)
    {
        uint256 bal = balanceOf(lockedAddress);
        uint256 locked = getLockedAmount(lockedAddress);
        return bal.sub(locked);
    }

    function() external payable {
        revert();
    }

    // the following functions are useful for frontend dApps

    /**
     * @return the list of all addresses that have at least a fund locked currently or in the past
     */
    function getLockedAddresses() public view returns (address[] memory) {
        return lockedAddressList;
    }

    /**
     * @return the number of addresses that have at least a fund locked currently or in the past
     */
    function getNumberOfLockedAddresses() public view returns (uint256 _count) {
        return lockedAddressList.length;
    }

    /**
     * @return the number of addresses that have at least a fund locked currently
     */
    function getNumberOfLockedAddressesCurrently()
        public
        view
        returns (uint256 _count)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i]) > 0) count++;
        }
        return count;
    }

    /**
     * @return the list of all addresses that have at least a fund locked currently
     */
    function getLockedAddressesCurrently()
        public
        view
        returns (address[] memory)
    {
        address[] memory list = new address[](
            getNumberOfLockedAddressesCurrently()
        );
        uint256 j = 0;
        for (uint256 i = 0; i < lockedAddressList.length; i++) {
            if (getLockedAmount(lockedAddressList[i]) > 0) {
                list[j] = lockedAddressList[i];
                j++;
            }
        }

        return list;
    }

    /**
     * @return the total amount of locked funds at the current time
     */
    function getLockedAmountTotal() public view returns (uint256 _amount) {
        uint256 sum = 0;
        for (uint256 i = 0; i < lockedAddressList.length; i++) {
            uint256 lockedAmount = getLockedAmount(lockedAddressList[i]);
            sum = sum.add(lockedAmount);
        }
        return sum;
    }

    /**
     * @return the total amount of circulating coins that are not locked at the current time
     *
     */
    function getCirculatingSupplyTotal() public view returns (uint256 _amount) {
        return totalSupply().sub(getLockedAmountTotal());
    }

    /**
     * @dev transfer of token to Carbonian Address.
     * always require the sender has enough balance
     * @return the bool true if success.
     * @param amount The amount to be transferred.
     */
    function Offsetter(uint256 amount)
        public
        whenNotPaused
        returns (bool success)
    {
        require(amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(carbonianWallet, amount);
    }

    /**
     * @dev transfer of token to another address
     * with project ID
     * always require the sender has enough balance
     * @return the bool true if success.
     * @param receiver The address to transfer to.
     * @param amount The amount to be transferred.
     * @param projectId ID of project.
     */
    function transferWithProjectId(
        address receiver,
        uint256 amount,
        uint256 projectId
    ) public whenNotPaused returns (bool success) {
        require(receiver != address(0));
        require(projectId > 0);
        require(amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(receiver, amount);
    }

    /**
     * @dev transfer to a given address a given amount and lock this fund until a given time
     * used for sending fund to team members, partners, or for owner to lock service fund over time
     * with project ID
     * @return the bool true if success.
     * @param receiver The address to transfer to.
     * @param amount The amount to transfer.
     * @param releaseDate The date to release token.
     * @param projectId ID of project.
     */
    function transferAndLockWithProjectId(
        address receiver,
        uint256 amount,
        uint256 releaseDate,
        uint256 projectId
    ) public whenNotPaused returns (bool success) {
        require(projectId > 0);
        ERC20._transfer(msg.sender, receiver, amount);
        if (lockList[receiver].length == 0) lockedAddressList.push(receiver);
        LockItem memory item = LockItem({
            amount: amount,
            releaseDate: releaseDate
        });
        lockList[receiver].push(item);
        return true;
    }
}