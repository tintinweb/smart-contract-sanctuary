/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.5.11;

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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(to != address(this));
        require(value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
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
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(to != address(this));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address spender, uint256 addedValue) public returns (bool){
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
}


/**
 * @title ERC677 interface
 *
 * @dev Simple ERC677, adding transferAndCall functionality
 * @dev https://github.com/ethereum/EIPs/issues/677
 */
contract ERC677 is ERC20 {
  function transferAndCall(address to, uint256 value, bytes memory data) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


/**
 * @title ERC677Receiver interface
 *
 * @dev Interface for token receivers (contracts) for transferAndCall
 * @dev https://github.com/ethereum/EIPs/issues/677
 */
contract ERC677Receiver {
  function onTokenTransfer(address sender, uint value, bytes calldata data) external;
}


/**
 * @title ERC677Token
 *
 * @dev Implementation of ERC677 Token
 * @dev https://github.com/ethereum/EIPs/issues/677
 */
contract ERC677Token is ERC677, StandardToken {
    
  /**
   * @dev Transfers token to address with additional data if the recipient is a contract
   * @param to The address to transfer token to
   * @param value The amount of tokens to be transferred
   * @param data The data to be passed to the receiving contract
   */
  function transferAndCall(address to, uint256 value, bytes memory data) public returns (bool success) {
    super.transfer(to, value);
    emit Transfer(msg.sender, to, value, data);
    if (isContract(to)) {
      contractFallback(to, value, data);
    }
    return true;
  }


  /**
   * @dev Call receiving contract callback, when to address in transferAndCall is contract
   * @param to The address of receiving contract
   * @param value The amount of tokens to be transferred
   * @param data The data to be passed to the receiving contract onTokenTransfer
   */
  function contractFallback(address to, uint value, bytes memory data) private {
    ERC677Receiver receiver = ERC677Receiver(to);
    receiver.onTokenTransfer(msg.sender, value, data);
  }
  

  /**
   * @dev Checks of address is contract
   * @param addr Address to check
   */
  function isContract(address addr) private view returns (bool hasCode) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length > 0;
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
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is ERC677Token, Pausable {

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }
    
    function transferAndCall(address to, uint256 value, bytes memory data) public whenNotPaused returns (bool) {
        return super.transferAndCall(to, value, data);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseApproval(address spender, uint256 addedValue) public whenNotPaused returns (bool){
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public whenNotPaused returns (bool){
        return super.decreaseApproval(spender, subtractedValue);
    }
}


/**
 * @title TaxaToken token
 *
 * @dev PausableToken modified with coin specific setting.
 **/

contract TaxaToken is PausableToken {
    string public constant name = "Taxa Token";
    string public constant symbol = "TXT";
    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 10 ** 10 * 10 ** uint256(decimals);

    constructor() public {
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
    }
}