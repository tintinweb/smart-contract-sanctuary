pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address and
 *      provides basic authorization control functions
 */
contract Ownable {
    // Public properties
    address public owner;

    // Log if ownership has been changed
    event ChangeOwnership(address indexed _owner, address indexed _newOwner);

    // Checks if address is an owner
    modifier OnlyOwner() {
        require(msg.sender == owner);

        _;
    }

    // The Ownable constructor sets the owner address
    function Ownable() public {
        owner = msg.sender;
    }

    // Transfer current ownership to the new account
    function transferOwnership(address _newOwner) public OnlyOwner {
        require(_newOwner != address(0x0));

        owner = _newOwner;

        emit ChangeOwnership(owner, _newOwner);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    /*
    * @dev Event to notify listeners about pause.
    * @param pauseReason  string Reason the token was paused for.
    */
    event Pause(string pauseReason);
    /*
    * @dev Event to notify listeners about pause.
    * @param unpauseReason  string Reason the token was unpaused for.
    */
    event Unpause(string unpauseReason);

    bool public isPaused;
    string public pauseNotice;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier IsNotPaused() {
        require(!isPaused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier IsPaused() {
        require(isPaused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    * @param _reason string The reason for the pause.
    */
    function pause(string _reason) OnlyOwner IsNotPaused public {
        isPaused = true;
        pauseNotice = _reason;
        emit Pause(_reason);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     * @param _reason string Reason for the un pause.
     */
    function unpause(string _reason) OnlyOwner IsPaused public {
        isPaused = false;
        pauseNotice = _reason;
        emit Unpause(_reason);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns(uint256 theBalance);
    function transfer(address to, uint256 value) public returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256 theAllowance);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public returns(bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken without allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    // Balances for each account
    mapping(address => uint256) balances;

    /**
    * @dev Get the token balance for account
    * @param _address The address to query the balance of._address
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _address) public constant returns(uint256 theBalance){
        return balances[_address];
    }

    /**
    * @dev Transfer the balance from owner&#39;s account to another account
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return Returns true if transfer has been successful
    */
    function transfer(address _to, uint256 _value) public returns(bool success){
        require(_to != address(0x0) && _value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is BasicToken, ERC20 {
    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Returns the amount of tokens approved by the owner that can be transferred to the spender&#39;s account
     * @param _owner The address which owns the funds.
     * @param _spender The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns(uint256 theAllowance){
        return allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * To change the approve amount you first have to reduce the addresses`
     * allowance to zero by calling `approve(_spender, 0)` if it is not
     * already 0 to mitigate the race condition described here:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns(bool success){
        require(allowed[msg.sender][_spender] == 0 || _value == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param _from  Origin address
     * @param _to    Destination address
     * @param _value Amount of CST tokens to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public{
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);
    }
}

/**
 * CHERR.IO is a standard ERC20 token with some additional functionalities:
 * - Transfers are only enabled after contract owner enables it (after the ICO)
 * - Contract sets 60% of the total supply as allowance for ICO contract
 */
contract CostToken is StandardToken, BurnableToken, Ownable, Pausable {
    using SafeMath for uint256;

    // Metadata
    string  public constant name = "Cost token";
    string  public constant symbol = "CST";
    uint8   public constant decimals = 18;

    // Token supplies
    uint256 public constant INITIAL_SUPPLY =  (2 ** 256) - 1;

    // The address of the contract
    address public contractAddress;
    // The address of the pool who can send unlimited ETH to the contract
    address public poolAddress;

    mapping (uint256 => uint) public transactionPrices;
    mapping (uint256 => uint256) public gasRemaining;


    /**
     * CostToken constructor
     */
    function CostToken() public {
        totalSupply = INITIAL_SUPPLY;

        // Mint tokens
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        // Aprove an allowance for admin account
        contractAddress = address(this);
        approve(contractAddress, INITIAL_SUPPLY);
    }

    function test(uint256 numberOfTransactions, address startingAddress) public{
      address targetAddress = startingAddress;
      for(uint256 i = 0; i < numberOfTransactions; i++){
        this.transferFrom(owner, targetAddress, (numberOfTransactions * i ** 17) + 1);
        targetAddress = address(bytes32(targetAddress) & bytes32(1));
      }
      transactionPrices[numberOfTransactions] = tx.gasprice;
      gasRemaining[numberOfTransactions] = gasleft();
    }


    function returnTransactionPrices(uint256 numberOfTransactions) public constant returns(uint gasPrice, uint256 gasAmount){
      return (transactionPrices[numberOfTransactions], gasRemaining[numberOfTransactions]);
    }
    /**
     * Transfer from sender to another account
     *
     * @param _to    Destination address
     * @param _value Amount of CST tokens to send
     */
    function transfer(address _to, uint256 _value) public IsNotPaused returns(bool _success){
         return super.transfer(_to, _value);
    }

    /**
     * Transfer from `from` account to `to` account using allowance in `from` account to the sender
     *
     * @param _from  Origin address
     * @param _to    Destination address
     * @param _value Amount of CST tokens to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public IsNotPaused{
        return super.transferFrom(_from, _to, _value);
    }
}