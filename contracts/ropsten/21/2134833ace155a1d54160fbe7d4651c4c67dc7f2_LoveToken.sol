pragma solidity ^0.4.25;

/**
 * @title Tenzorum Love Token - https://tenzorum.org
 *
 * @dev ERC20 token with a minting function executed by meta transaction - &#39;shareLove&#39;
 *      and a proxy function for easy subdomain registrations - &#39;newSubdomain&#39;.
 *
 * @author Radek Ostrowski - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dba9babfbeb09ba8afbaa9afb4b5b8b3bab2b5f5b8b4b6">[email&#160;protected]</a>
 */


//https://github.com/Tenzorum/IPAS-ens-subdomain-factory/blob/master/contracts/EnsSubdomainFactory.sol

contract EnsSubdomainFactory {
    function newSubdomain(string _subdomain, string _domain, string _topdomain, address _owner, address _target) public;
}

//https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
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
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
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
        require(value <= _balances[from]);
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
     * @param amount The amount that will be created.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != 0);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != 0);
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            amount);
        _burn(account, amount);
    }
}


contract LoveToken is ERC20 {

    string public constant name = "❤️&#127744; Love Token";
    string public constant symbol = "LUV";
    uint8 public constant decimals = 18;

    mapping (address => uint) public nonces;

    EnsSubdomainFactory public factory;
    address public owner;

    event SharedLove(address indexed who, address indexed with, uint256 amount);

    //can only be invoked via execute function (as a meta-tx)
    modifier onlyMetaTx() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(EnsSubdomainFactory _factory) public {
        factory = _factory;
        owner = msg.sender;
    }

    function shareLove(address _who, address _with, uint256 _amount) public onlyMetaTx {
        _mint(_who, _amount);
        _mint(_with, _amount);
        emit SharedLove(_who, _with, _amount);
    }

    //proxy to EnsSubdomainFactory allowing to create tenz-id as a meta-tx
    function newSubdomain(string _subdomain, string _domain, string _topdomain, address _owner, address _target) public onlyMetaTx {
        factory.newSubdomain(_subdomain, _domain, _topdomain, _owner, _target);
    }

    function updateSubdomainFactory(EnsSubdomainFactory _newFactory) public onlyOwner {
        require(address(factory) != address(_newFactory), "factories must be different");
        factory = _newFactory;
    }

    function transferContractOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "cannot transfer to address(0)");
        owner = _newOwner;
    }

    function execute(
        uint8 _v, bytes32 _r, bytes32 _s,
        address _from, address _to,
        uint _value, bytes _data,
        address _rewardType, uint _rewardAmount) public {

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _data,
            _rewardType, _rewardAmount, nonces[_from]++));

        require(ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s) == _from);

        // Below is not used. Love should be free!
        // ---------------------------------------
        // if(_rewardAmount > 0) {
        //     if(_rewardType == address(0)){
        //         //pay fee with ether
        //         require(msg.sender.call.value(_rewardAmount)());
        //     } else {
        //         //pay fee with tokens
        //         require((ERC20(_rewardType)).transfer(msg.sender, _rewardAmount));
        //     }
        // }

        require(_to.call.value(_value)(_data));
    }
}