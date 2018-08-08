pragma solidity ^0.4.17;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
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
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
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
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an address access to this role
     */
    function add(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = true;
    }

    /**
     * @dev remove an address&#39; access to this role
     */
    function remove(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage role, address addr)
    view
    internal
    {
        require(has(role, addr));
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage role, address addr)
    view
    internal
    returns (bool)
    {
        return role.bearer[addr];
    }
}

contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

    /**
     * @dev reverts if addr does not have role
     * @param addr address
     * @param roleName the name of the role
     * // reverts
     */
    function checkRole(address addr, string roleName)
    view
    public
    {
        roles[roleName].check(addr);
    }

    /**
     * @dev determine if addr has role
     * @param addr address
     * @param roleName the name of the role
     * @return bool
     */
    function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
    {
        return roles[roleName].has(addr);
    }

    /**
     * @dev add a role to an address
     * @param addr address
     * @param roleName the name of the role
     */
    function addRole(address addr, string roleName)
    internal
    {
        roles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    /**
     * @dev remove a role from an address
     * @param addr address
     * @param roleName the name of the role
     */
    function removeRole(address addr, string roleName)
    internal
    {
        roles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param roleName the name of the role
     * // reverts
     */
    modifier onlyRole(string roleName)
    {
        checkRole(msg.sender, roleName);
        _;
    }

    /**
     * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
     * @param roleNames the names of the roles to scope access to
     * // reverts
     *
     * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
     *  see: https://github.com/ethereum/solidity/issues/2467
     */
    // modifier onlyRoles(string[] roleNames) {
    //     bool hasAnyRole = false;
    //     for (uint8 i = 0; i < roleNames.length; i++) {
    //         if (hasRole(msg.sender, roleNames[i])) {
    //             hasAnyRole = true;
    //             break;
    //         }
    //     }

    //     require(hasAnyRole);

    //     _;
    // }
}

contract RBACWithAdmin is RBAC {
    /**
     * A constant role name for indicating admins.
     */
    string public constant ROLE_ADMIN = "admin";

    /**
     * @dev modifier to scope access to admins
     * // reverts
     */
    modifier onlyAdmin()
    {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

    /**
     * @dev constructor. Sets msg.sender as admin by default
     */
    function RBACWithAdmin()
    public
    {
        addRole(msg.sender, ROLE_ADMIN);
    }

    /**
     * @dev add a role to an address
     * @param addr address
     * @param roleName the name of the role
     */
    function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
    {
        addRole(addr, roleName);
    }

    /**
     * @dev remove a role from an address
     * @param addr address
     * @param roleName the name of the role
     */
    function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
    {
        removeRole(addr, roleName);
    }
}

contract NbtToken is StandardToken, Ownable, RBACWithAdmin {

    /*** EVENTS ***/

    event ExchangeableTokensInc(address indexed from, uint256 amount);
    event ExchangeableTokensDec(address indexed to, uint256 amount);

    event CirculatingTokensInc(address indexed from, uint256 amount);
    event CirculatingTokensDec(address indexed to, uint256 amount);

    event SaleableTokensInc(address indexed from, uint256 amount);
    event SaleableTokensDec(address indexed to, uint256 amount);

    event StockTokensInc(address indexed from, uint256 amount);
    event StockTokensDec(address indexed to, uint256 amount);

    event BbAddressUpdated(address indexed ethereum_address, string bb_address);

    /*** CONSTANTS ***/

    string public name = &#39;NiceBytes&#39;;
    string public symbol = &#39;NBT&#39;;

    uint256 public decimals = 8;

    uint256 public INITIAL_SUPPLY = 10000000000 * 10**decimals; // One time total supply
    uint256 public AIRDROP_START_AT = 1525780800; // May 8, 12:00 UTC
    uint256 public AIRDROPS_COUNT = 82;
    uint256 public AIRDROPS_PERIOD = 86400;
    uint256 public CIRCULATING_BASE = 2000000000 * 10**decimals;
    uint256 public MAX_AIRDROP_VOLUME = 2; // %
    uint256 public INITIAL_EXCHANGEABLE_TOKENS_VOLUME = 1200000000 * 10**decimals;
    uint256 public MAX_AIRDROP_TOKENS = 8000000000 * 10**decimals; // 8 billions
    uint256 public MAX_SALE_VOLUME = 800000000 * 10**decimals;
    uint256 public EXCHANGE_COMMISSION = 200 * 10**decimals; // NBT
    uint256 public MIN_TOKENS_TO_EXCHANGE = 1000 * 10**decimals; // should be bigger than EXCHANGE_COMMISSION
    uint256 public EXCHANGE_RATE = 1000;
    string constant ROLE_EXCHANGER = "exchanger";


    /*** STORAGE ***/

    uint256 public exchangeableTokens;
    uint256 public exchangeableTokensFromSale;
    uint256 public exchangeableTokensFromStock;
    uint256 public circulatingTokens;
    uint256 public circulatingTokensFromSale;
    uint256 public saleableTokens;
    uint256 public stockTokens;
    address public crowdsale;
    address public exchange_commission_wallet;

    mapping(address => uint256) exchangeBalances;
    mapping(address => string) bbAddresses;

    /*** MODIFIERS ***/

    modifier onlyAdminOrExchanger()
    {
        require(
            hasRole(msg.sender, ROLE_ADMIN) ||
            hasRole(msg.sender, ROLE_EXCHANGER)
        );
        _;
    }

    modifier onlyCrowdsale()
    {
        require(
            address(msg.sender) == address(crowdsale)
        );
        _;
    }

    /*** CONSTRUCTOR ***/

    function NbtToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[this] = INITIAL_SUPPLY;
        stockTokens = INITIAL_SUPPLY;
        emit StockTokensInc(address(0), INITIAL_SUPPLY);
        addRole(msg.sender, ROLE_EXCHANGER);
    }

    /*** PUBLIC AND EXTERNAL FUNCTIONS ***/

    /*** getters  ***/

    function getBbAddress(address _addr) public view returns (string _bbAddress) {
        return bbAddresses[_addr];
    }

    function howMuchTokensAvailableForExchangeFromStock() public view returns (uint256) {
        uint256 _volume = INITIAL_EXCHANGEABLE_TOKENS_VOLUME;
        uint256 _airdrops = 0;

        if (now > AIRDROP_START_AT) {
            _airdrops = (now.sub(AIRDROP_START_AT)).div(AIRDROPS_PERIOD);
            _airdrops = _airdrops.add(1);
        }

        if (_airdrops > AIRDROPS_COUNT) {
            _airdrops = AIRDROPS_COUNT;
        }

        uint256 _from_airdrops = 0;
        uint256 _base = CIRCULATING_BASE;
        for (uint256 i = 1; i <= _airdrops; i++) {
            _from_airdrops = _from_airdrops.add(_base.mul(MAX_AIRDROP_VOLUME).div(100));
            _base = _base.add(_base.mul(MAX_AIRDROP_VOLUME).div(100));
        }
        if (_from_airdrops > MAX_AIRDROP_TOKENS) {
            _from_airdrops = MAX_AIRDROP_TOKENS;
        }

        _volume = _volume.add(_from_airdrops);

        return _volume;
    }

    /*** setters  ***/

    function setBbAddress(string _bbAddress) public returns (bool) {
        bbAddresses[msg.sender] = _bbAddress;
        emit BbAddressUpdated(msg.sender, _bbAddress);
        return true;
    }

    function setCrowdsaleAddress(address _addr) onlyAdmin public returns (bool) {
        require(_addr != address(0) && _addr != address(this));
        crowdsale = _addr;
        return true;
    }

    function setExchangeCommissionAddress(address _addr) onlyAdmin public returns (bool) {
        require(_addr != address(0) && _addr != address(this));
        exchange_commission_wallet = _addr;
        return true;
    }

    /*** sale methods  ***/

    // For balancing of the sale limit between two networks
    function moveTokensFromSaleToExchange(uint256 _amount) onlyAdminOrExchanger public returns (bool) {
        require(_amount <= balances[crowdsale]);
        balances[crowdsale] = balances[crowdsale].sub(_amount);
        saleableTokens = saleableTokens.sub(_amount);
        exchangeableTokensFromSale = exchangeableTokensFromSale.add(_amount);
        balances[address(this)] = balances[address(this)].add(_amount);
        exchangeableTokens = exchangeableTokens.add(_amount);
        emit SaleableTokensDec(address(this), _amount);
        emit ExchangeableTokensInc(address(crowdsale), _amount);
        return true;
    }

    function moveTokensFromSaleToCirculating(address _to, uint256 _amount) onlyCrowdsale public returns (bool) {
        saleableTokens = saleableTokens.sub(_amount);
        circulatingTokensFromSale = circulatingTokensFromSale.add(_amount) ;
        circulatingTokens = circulatingTokens.add(_amount) ;
        emit SaleableTokensDec(_to, _amount);
        emit CirculatingTokensInc(address(crowdsale), _amount);
        return true;
    }

    /*** stock methods  ***/

    function moveTokensFromStockToExchange(uint256 _amount) onlyAdminOrExchanger public returns (bool) {
        require(_amount <= stockTokens);
        require(exchangeableTokensFromStock + _amount <= howMuchTokensAvailableForExchangeFromStock());
        stockTokens = stockTokens.sub(_amount);
        exchangeableTokens = exchangeableTokens.add(_amount);
        exchangeableTokensFromStock = exchangeableTokensFromStock.add(_amount);
        emit StockTokensDec(address(this), _amount);
        emit ExchangeableTokensInc(address(this), _amount);
        return true;
    }

    function moveTokensFromStockToSale(uint256 _amount) onlyAdminOrExchanger public returns (bool) {
        require(crowdsale != address(0) && crowdsale != address(this));
        require(_amount <= stockTokens);
        require(_amount + exchangeableTokensFromSale + saleableTokens + circulatingTokensFromSale <= MAX_SALE_VOLUME);

        stockTokens = stockTokens.sub(_amount);
        saleableTokens = saleableTokens.add(_amount);
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[crowdsale] = balances[crowdsale].add(_amount);

        emit Transfer(address(this), crowdsale, _amount);
        emit StockTokensDec(address(crowdsale), _amount);
        emit SaleableTokensInc(address(this), _amount);
        return true;
    }

    /*** exchange methods  ***/

    function getTokensFromExchange(address _to, uint256 _amount) onlyAdminOrExchanger public returns (bool) {
        require(_amount <= exchangeableTokens);
        require(_amount <= balances[address(this)]);

        exchangeableTokens = exchangeableTokens.sub(_amount);
        circulatingTokens = circulatingTokens.add(_amount);

        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(this), _to, _amount);
        emit ExchangeableTokensDec(_to, _amount);
        emit CirculatingTokensInc(address(this), _amount);
        return true;
    }

    function sendTokensToExchange(uint256 _amount) public returns (bool) {
        require(_amount <= balances[msg.sender]);
        require(_amount >= MIN_TOKENS_TO_EXCHANGE);
        require(!stringsEqual(bbAddresses[msg.sender], &#39;&#39;));
        require(exchange_commission_wallet != address(0) && exchange_commission_wallet != address(this));

        balances[msg.sender] = balances[msg.sender].sub(_amount); // ! before sub(_commission)

        uint256 _commission = EXCHANGE_COMMISSION + _amount % EXCHANGE_RATE;
        _amount = _amount.sub(_commission);

        circulatingTokens = circulatingTokens.sub(_amount);
        exchangeableTokens = exchangeableTokens.add(_amount);
        exchangeBalances[msg.sender] = exchangeBalances[msg.sender].add(_amount);

        balances[address(this)] = balances[address(this)].add(_amount);
        balances[exchange_commission_wallet] = balances[exchange_commission_wallet].add(_commission);

        emit Transfer(msg.sender, address(exchange_commission_wallet), _commission);
        emit Transfer(msg.sender, address(this), _amount);
        emit CirculatingTokensDec(address(this), _amount);
        emit ExchangeableTokensInc(msg.sender, _amount);
        return true;
    }

    function exchangeBalanceOf(address _addr) public view returns (uint256 _tokens) {
        return exchangeBalances[_addr];
    }

    function decExchangeBalanceOf(address _addr, uint256 _amount) onlyAdminOrExchanger public returns (bool) {
        require (exchangeBalances[_addr] > 0);
        require (exchangeBalances[_addr] >= _amount);
        exchangeBalances[_addr] = exchangeBalances[_addr].sub(_amount);
        return true;
    }

    /*** INTERNAL FUNCTIONS ***/

    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        for (uint256 i = 0; i < a.length; i ++)
            if (a[i] != b[i])
                return false;
        return true;
    }
}