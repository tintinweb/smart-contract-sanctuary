pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);  
        owner = newOwner;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract EyeToken is ERC20, Ownable {
    using SafeMath for uint256;

    struct Frozen {
        bool frozen;
        uint until;
    }

    string public name = "EYE Token";
    string public symbol = "EYE";
    uint8 public decimals = 18;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => Frozen) public frozenAccounts;
    uint256 internal totalSupplyTokens;
    bool internal isICO;
    address public wallet;

    function EyeToken() public Ownable() {
        wallet = msg.sender;
        isICO = true;
        totalSupplyTokens = 10000000000 * 10 ** uint256(decimals);
        balances[wallet] = totalSupplyTokens;
    }

    /**
     * @dev Finalize ICO
     */
    function finalizeICO() public onlyOwner {
        isICO = false;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupplyTokens;
    }

    /**
     * @dev Freeze account, make transfers from this account unavailable
     * @param _account Given account
     */
    function freeze(address _account) public onlyOwner {
        freeze(_account, 0);
    }

    /**
     * @dev  Temporary freeze account, make transfers from this account unavailable for a time
     * @param _account Given account
     * @param _until Time until
     */
    function freeze(address _account, uint _until) public onlyOwner {
        if (_until == 0 || (_until != 0 && _until > now)) {
            frozenAccounts[_account] = Frozen(true, _until);
        }
    }

    /**
     * @dev Unfreeze account, make transfers from this account available
     * @param _account Given account
     */
    function unfreeze(address _account) public onlyOwner {
        if (frozenAccounts[_account].frozen) {
            delete frozenAccounts[_account];
        }
    }

    /**
     * @dev allow transfer tokens or not
     * @param _from The address to transfer from.
     */
    modifier allowTransfer(address _from) {
        require(!isICO, "ICO phase");
        if (frozenAccounts[_from].frozen) {
            require(frozenAccounts[_from].until != 0 && frozenAccounts[_from].until < now, "Frozen account");
            delete frozenAccounts[_from];
        }
        _;
    }

    /**
    * @dev transfer tokens for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result = _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value); 
        return result;
    }

    /**
    * @dev transfer tokens for a specified address in ICO mode
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferICO(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(isICO, "Not ICO phase");
        require(_to != address(0), "Zero address &#39;To&#39;");
        require(_value <= balances[wallet], "Not enought balance");
        balances[wallet] = balances[wallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(wallet, _to, _value);  
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

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public allowTransfer(_from) returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Not enought allowance");
        bool result = _transfer(_from, _to, _value);
        if (result) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);  
        }
        return result;
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

    /**
     * @dev transfer token for a specified address
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _transfer(address _from, address _to, uint256 _value) internal allowTransfer(_from) returns (bool) {
        require(_to != address(0), "Zero address &#39;To&#39;");
        require(_from != address(0), "Zero address &#39;From&#39;");
        require(_value <= balances[_from], "Not enought balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }
}