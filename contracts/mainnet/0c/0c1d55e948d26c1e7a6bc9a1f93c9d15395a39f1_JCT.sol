pragma solidity ^0.4.24;

/*      _____    ______    ________ 
 *     /     |  /      \  /        |
 *     $$$$$ | /$$$$$$  | $$$$$$$$/ 
 *        $$ | $$ |  $$/     $$ |  
 *   __   $$ | $$ |          $$ |  
 *  /  |  $$ | $$ |   __     $$ |  
 *  $$ \__$$ | $$ \__/  |    $$ |
 *  $$    $$/  $$    $$/     $$ |
 *   $$$$$$/    $$$$$$/      $$/ 
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization
 *      control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public collector;
    address public distributor;
    address public freezer;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CollectorshipTransferred(address indexed previousCollector, address indexed newCollector);
    event DistributorshipTransferred(address indexed previousDistributor, address indexed newDistributor);
    event FreezershipTransferred(address indexed previousFreezer, address indexed newFreezer);

    /**
     * @dev The Ownable constructor sets the original `owner`, `collector`, `distributor` and `freezer` of the contract to the
     *      sender account.
     */
    constructor() public {
        owner = msg.sender;
        collector = msg.sender;
        distributor = msg.sender;
        freezer = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Throws if called by any account other than the collector.
     */
    modifier onlyCollector() {
        require(msg.sender == collector);
        _;
    }

    /**
     * @dev Throws if called by any account other than the distributor.
     */
    modifier onlyDistributor() {
        require(msg.sender == distributor);
        _;
    }

    /**
     * @dev Throws if called by any account other than the freezer.
     */
    modifier onlyFreezer() {
        require(msg.sender == freezer);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(isNonZeroAccount(newOwner));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current collector to transfer control of the contract to a newCollector.
     * @param newCollector The address to transfer collectorship to.
     */
    function transferCollectorship(address newCollector) onlyOwner public {
        require(isNonZeroAccount(newCollector));
        emit CollectorshipTransferred(collector, newCollector);
        collector = newCollector;
    }

    /**
     * @dev Allows the current distributor to transfer control of the contract to a newDistributor.
     * @param newDistributor The address to transfer distributorship to.
     */
    function transferDistributorship(address newDistributor) onlyOwner public {
        require(isNonZeroAccount(newDistributor));
        emit DistributorshipTransferred(distributor, newDistributor);
        distributor = newDistributor;
    }

    /**
     * @dev Allows the current freezer to transfer control of the contract to a newFreezer.
     * @param newFreezer The address to transfer freezership to.
     */
    function transferFreezership(address newFreezer) onlyOwner public {
        require(isNonZeroAccount(newFreezer));
        emit FreezershipTransferred(freezer, newFreezer);
        freezer = newFreezer;
    }

    // check if the given account is valid
    function isNonZeroAccount(address _addr) internal pure returns (bool is_nonzero_account) {
        return _addr != address(0);
    }
}

/**
 * @title ERC20
 * @dev ERC20 contract interface
 */
contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title JCT
 * @author Daisuke Hirata & Noriyuki Izawa
 * @dev JCT is an ERC20 Token. First envisioned by NANJCOIN
 */
contract JCT is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "JCT";
    string public symbol = "JCT";
    uint8 public decimals = 8;
    uint256 public totalSupply = 17e7 * 1e8;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);

    /**
     * @dev Constructor is called only once and can not be called again
     */
    constructor(address founder) public {
        owner = founder;
        collector = founder;
        distributor = founder;
        freezer = founder;

        balanceOf[founder] = totalSupply;
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    /**
     * @dev Prevent targets from sending or receiving tokens
     * @param targets Addresses to be frozen
     * @param isFrozen either to freeze it or not
     */
    function freezeAccounts(address[] targets, bool isFrozen) onlyFreezer public {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(isNonZeroAccount(targets[j]));
            frozenAccount[targets[j]] = isFrozen;
            emit FrozenFunds(targets[j], isFrozen);
        }
    }

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix times
     * @param targets Addresses to be locked funds
     * @param unixTimes Unix times when locking up will be finished
     */
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(hasSameArrayLength(targets, unixTimes));

        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] < unixTimes[j]);
            unlockUnixTime[targets[j]] = unixTimes[j];
            emit LockedFunds(targets[j], unixTimes[j]);
        }
    }

    /**
     * @dev Standard function transfer with no _data
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(hasEnoughBalance(msg.sender, _value)
                && isAvailableAccount(msg.sender)
                && isAvailableAccount(_to));

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(isNonZeroAccount(_to)
                && hasEnoughBalance(_from, _value)
                && allowance[_from][msg.sender] >= _value
                && isAvailableAccount(_from)
                && isAvailableAccount(_to));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Allows _spender to spend no more than _value tokens in your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /**
     * @dev Function to collect tokens from the list of addresses
     */
    function collectTokens(address[] addresses, uint[] amounts) onlyCollector public returns (bool) {
        require(hasSameArrayLength(addresses, amounts));

        uint256 totalAmount = 0;

        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0
                    && isNonZeroAccount(addresses[j])
                    && isAvailableAccount(addresses[j]));

            require(hasEnoughBalance(addresses[j], amounts[j]));
            balanceOf[addresses[j]] = balanceOf[addresses[j]].sub(amounts[j]);
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].add(totalAmount);
        return true;
    }

    /**
     * @dev Function to distribute tokens to the list of addresses
     */
    function distributeTokens(address[] addresses, uint[] amounts) onlyDistributor public returns (bool) {
        require(hasSameArrayLength(addresses, amounts)
                && isAvailableAccount(msg.sender));

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && isNonZeroAccount(addresses[j])
                    && isAvailableAccount(addresses[j]));

            totalAmount = totalAmount.add(amounts[j]);
        }
        require(hasEnoughBalance(msg.sender, totalAmount));

        for (j = 0; j < addresses.length; j++) {
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]);
            emit Transfer(msg.sender, addresses[j], amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    // check if the given account is available
    function isAvailableAccount(address _addr) private view returns (bool is_valid_account) {
        return isUnLockedAccount(_addr) && isUnfrozenAccount(_addr);
    }

    // check if the given account is not locked up
    function isUnLockedAccount(address _addr) private view returns (bool is_unlocked_account) {
        return now > unlockUnixTime[_addr];
    }

    // check if the given account is not frozen
    function isUnfrozenAccount(address _addr) private view returns (bool is_unfrozen_account) {
        return frozenAccount[_addr] == false;
    }

    // check if the given account has enough balance more than given amount
    function hasEnoughBalance(address _addr, uint256 _value) private view returns (bool has_enough_balance) {
        return _value > 0 && balanceOf[_addr] >= _value;
    }

    // check if the given account is not frozen
    function hasSameArrayLength(address[] addresses, uint[] amounts) private pure returns (bool has_same_array_length) {
        return addresses.length > 0 && addresses.length == amounts.length;
    }
}