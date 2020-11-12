pragma solidity 0.5.16;

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
 * @title FreedomDividendCoin ERC20 token
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
contract FreedomDividendCoin is IERC20,ERC20Detailed {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    string private _name="Freedom Dividend Coin";

    string private _symbol="FDC";

    uint8 private _decimals=2;

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

    address private DividendDistributor = 0xa100E22A959D869137827D963cED87d4B545ce45;
    uint256 private globalDistributionTimestamp;
    uint256 private balanceOfDividendDistributorAtDistributionTimestamp;

    struct DividendAddresses {
        address individualAddress;
        uint256 lastDistributionTimestamp;
    }

    mapping(address => DividendAddresses) private FreedomDividendAddresses;

    constructor ()
    ERC20Detailed(_name, _symbol, _decimals)
    public
    {
        _mint(msg.sender, 2500000000);
        transfer(DividendDistributor, 10000000);
        globalDistributionTimestamp = now;
        balanceOfDividendDistributorAtDistributionTimestamp = balanceOf(DividendDistributor);
    }

    function transferCoin(address _from, address _to, uint256 _value) internal {
        uint256 transferRate = _value / 10;
        require(transferRate > 0, "Transfer Rate needs to be higher than the minimum");
        require(_value > transferRate, "Value sent needs to be higher than the Transfer Rate");
        uint256 sendValue = _value - transferRate;
        _transfer(_from, _to, sendValue);
        _transfer(_from, DividendDistributor, transferRate);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        transferCoin(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        transferCoin(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function collectFreedomDividendFromSender() public returns (bool) {
        collectFreedomDividend(msg.sender);
        return true;
    }

    function collectFreedomDividendWithAddress(address collectionAddress) public returns (bool) {
        collectFreedomDividend(collectionAddress);
        return true;
    }

    function collectFreedomDividend(address collectionAddress) internal {

        require(collectionAddress != address(0), "Need to use a valid Address");
        require(collectionAddress != DividendDistributor, "Dividend Distributor does not distribute a dividend to itself");

        if (FreedomDividendAddresses[collectionAddress].individualAddress != address(0)) {
            if ((now - globalDistributionTimestamp) >= 30 days) {
                require(balanceOf(DividendDistributor) > 0, "Balance of Dividend Distributor needs to be greater than 0");
                globalDistributionTimestamp = now;
                balanceOfDividendDistributorAtDistributionTimestamp = balanceOf(DividendDistributor);
            }
            
            if (FreedomDividendAddresses[collectionAddress].lastDistributionTimestamp > globalDistributionTimestamp) {
                require(1 == 0, "Freedom Dividend has already been collected in past 30 days or just signed up for Dividend and need to wait up to 30 days");
            } else if ((now - FreedomDividendAddresses[collectionAddress].lastDistributionTimestamp) >= 30 days) {
                require(balanceOf(collectionAddress) > 0, "Balance of Collection Address needs to be greater than 0");
                uint256 percentageOfTotalSupply = balanceOf(collectionAddress) * totalSupply() / 625000000;
                require(percentageOfTotalSupply > 0, "Percentage of Total Supply needs to be higher than the minimum");
                uint256 distributionAmount = balanceOfDividendDistributorAtDistributionTimestamp * percentageOfTotalSupply / 10000000000;
                require(distributionAmount > 0, "Distribution amount needs to be higher than 0");
                _transfer(DividendDistributor, collectionAddress, distributionAmount);
                FreedomDividendAddresses[collectionAddress].lastDistributionTimestamp = now;
            } else {
                require(1 == 0, "It has not been 30 days since last collection of the Freedom Dividend");
            }
        } else {
            DividendAddresses memory newDividendAddresses;
            newDividendAddresses.individualAddress = collectionAddress;
            newDividendAddresses.lastDistributionTimestamp = now;
            FreedomDividendAddresses[collectionAddress] = newDividendAddresses;
        }

    }

    function getDividendAddress() public view returns(address) {
        return FreedomDividendAddresses[msg.sender].individualAddress;
    }

    function getDividendAddressWithAddress(address Address) public view returns(address) {
        return FreedomDividendAddresses[Address].individualAddress;
    }

    function getLastDistributionTimestamp() public view returns(uint256) {
        return FreedomDividendAddresses[msg.sender].lastDistributionTimestamp;
    }

    function getLastDistributionTimestampWithAddress(address Address) public view returns(uint256) {
        return FreedomDividendAddresses[Address].lastDistributionTimestamp;
    }

    function getGlobalDistributionTimestamp() public view returns(uint256) {
        return globalDistributionTimestamp;
    }

    function getbalanceOfDividendDistributorAtDistributionTimestamp() public view returns(uint256) {
        return balanceOfDividendDistributorAtDistributionTimestamp;
    }

}