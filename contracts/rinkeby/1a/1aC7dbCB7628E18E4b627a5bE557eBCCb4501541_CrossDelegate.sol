/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.4.26;


/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    constructor() public {
        owner = msg.sender;
    }

    address public newOwner;

    function transferOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract Admin is Owned {
    mapping(address => bool) public mapAdmin;

    event AddAdmin(address admin);
    event RemoveAdmin(address admin);

    modifier onlyAdmin() {
        require(mapAdmin[msg.sender], "not admin");
        _;
    }

    function addAdmin(
        address admin
    )
        external
        onlyOwner
    {
        mapAdmin[admin] = true;

        emit AddAdmin(admin);
    }

    function removeAdmin(
        address admin
    )
        external
        onlyOwner
    {
        delete mapAdmin[admin];

        emit RemoveAdmin(admin);
    }
}

contract ERC20Protocol {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint supply);
    is replaced with:
    uint public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */

    /**************************************
     **
     ** VARIABLES
     **
     **************************************/

    string public name;
    string public symbol;
    uint8 public decimals;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    /// total amount of tokens
    uint public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath div 0"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub b > a");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath add overflow");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath mod 0");
        return a % b;
    }
}

contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4, "Payload size is incorrect");
        _;
    }

    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        //  To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "Not permitted");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
      return allowed[_owner][_spender];
    }
}

contract MappingToken is StandardToken, Admin {
    using SafeMath for uint;
    /****************************************************************************
     **
     ** MODIFIERS
     **
     ****************************************************************************/
    modifier onlyMeaningfulValue(uint value) {
        require(value > 0, "Value is null");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(mapAdmin[msg.sender] || msg.sender == owner, "not admin or owner");
        _;
    }

    /****************************************************************************
     **
     ** EVENTS
     **
     ****************************************************************************/

    ///@notice Initialize the TokenManager address
    ///@dev Initialize the TokenManager address
    ///@param tokenName The token name to be used
    ///@param tokenSymbol The token symbol to be used
    ///@param tokenDecimal The token decimals to be used
    constructor(string tokenName, string tokenSymbol, uint8 tokenDecimal)
        public
    {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimal;
    }

    /****************************************************************************
     **
     ** MANIPULATIONS
     **
     ****************************************************************************/

    /// @notice Create token
    /// @dev Create token
    /// @param account Address will receive token
    /// @param value Amount of token to be minted
    function mint(address account, uint value)
        external
        onlyAdminOrOwner
        onlyMeaningfulValue(value)
    {
        balances[account] = balances[account].add(value);
        totalSupply = totalSupply.add(value);

        emit Transfer(address(0), account, value);
    }

    /// @notice Burn token
    /// @dev Burn token
    /// @param account Address of whose token will be burnt
    /// @param value Amount of token to be burnt
    function burn(address account, uint value)
        external
        onlyAdminOrOwner
        onlyMeaningfulValue(value)
    {
        balances[account] = balances[account].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(account, address(0), value);
    }

    /// @notice update token name, symbol
    /// @dev update token name, symbol
    /// @param _name token new name
    /// @param _symbol token new symbol
    function update(string _name, string _symbol)
        external
        onlyAdminOrOwner
    {
        name = _name;
        symbol = _symbol;
    }
}

interface IMappingToken {
    function transferOwner(address _newOwner) external;
    function name() external view returns (string);
    function symbol() external view returns (string);
    function decimals() external view returns (uint8);
    function mint(address, uint) external;
    function burn(address, uint) external;
    function update(string, string) external;
    function addAdmin(address) external;
    function removeAdmin(address) external;
}

/**
 * Math operations with safety checks
 */
contract CrossDelegate is Admin {
    using SafeMath for uint;
    /************************************************************
     **
     ** EVENTS
     **
     ************************************************************/

     event AddToken(address indexed tokenAddress, string name, string symbol, uint8 decimals);
     event UpdateToken(address indexed tokenAddress, string name, string symbol);
     event MintToken(address indexed tokenAddress, address indexed to, uint indexed value);
     event BurnToken(address indexed tokenAddress, uint indexed value, bytes destAccount);

    /**
    *
    * MANIPULATIONS
    *
    */

    function mintToken(
        address tokenAddress,
        address to,
        uint    value
    )
        external
        onlyAdmin
    {
        IMappingToken(tokenAddress).mint(to, value);
        emit MintToken(tokenAddress, to, value);
    }

    function burnToken(
        address tokenAddress,
        uint    value,
        bytes   destAccount
    )
        external
    {
        IMappingToken(tokenAddress).burn(msg.sender, value);
        emit BurnToken(tokenAddress, value, destAccount);
    }

    function addToken(
        string name,
        string symbol,
        uint8 decimals
    )
        external
        onlyOwner
    {
        address tokenAddress = new MappingToken(name, symbol, decimals);
        emit AddToken(tokenAddress, name, symbol, decimals);
    }

    function updateToken(address tokenAddress, string name, string symbol)
        external
        onlyOwner
    {
        IMappingToken(tokenAddress).update(name, symbol);
        emit UpdateToken(tokenAddress, name, symbol);
    }

    function changeTokenOwner(address tokenAddress, address _newOwner) external onlyOwner {
        IMappingToken(tokenAddress).transferOwner(_newOwner);
    }

    function addTokenAdmin(address tokenAddress, address admin) external onlyOwner {
        IMappingToken(tokenAddress).addAdmin(admin);
    }

    function removeTokenAdmin(address tokenAddress, address admin) external onlyOwner {
        IMappingToken(tokenAddress).removeAdmin(admin);
    }

}