pragma solidity ^0.4.23;

/**
 * Import SafeMath source from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
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
 * ERC 20 token
 * https://github.com/ethereum/EIPs/issues/20
 */
interface Token {

    /**
     * @return total amount of tokens
     * function totalSupply() public constant returns (uint256 supply);
     * do not declare totalSupply() here, see https://github.com/OpenZeppelin/zeppelin-solidity/issues/434
     */

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) external constant returns (uint256 balance);

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @notice `msg.sender` approves `_addr` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of wei to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


/** @title Coinweb (XCOe) contract **/

contract Coinweb is Token {

    using SafeMath for uint256;

    string public constant name = "Coinweb";
    string public constant symbol = "XCOe";
    uint256 public constant decimals = 8;
    uint256 public constant totalSupply = 2400000000 * 10**decimals;
    address public founder = 0x51Db57ABe0Fc0393C0a81c0656C7291aB7Dc0fDe; // Founder&#39;s address
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    /**
     * If transfers are locked, only the contract founder can send funds.
     * Contract starts its lifecycle in a locked transfer state.
     */
    bool public transfersAreLocked = true;

    /**
     * Construct Coinweb contract.
     * Set the founder balance as the total supply and emit Transfer event.
     */
    constructor() public {
        balances[founder] = totalSupply;
        emit Transfer(address(0), founder, totalSupply);
    }

    /**
     * Modifier to check whether transfers are unlocked or the
     * founder is sending the funds
     */
    modifier canTransfer() {
        require(msg.sender == founder || !transfersAreLocked);
        _;
    }

    /**
     * Modifier to allow only the founder to perform some contract call.
     */
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * Set transfer locking state. Effectively locks/unlocks token sending.
     * @param _transfersAreLocked Boolean whether transfers are locked or not
     * @return Whether the transaction was successful or not
     */
    function setTransferLock(bool _transfersAreLocked) public onlyFounder returns (bool) {
        transfersAreLocked = _transfersAreLocked;
        return true;
    }

    /**
     * Contract calls revert on public method as it&#39;s not supposed to deal with
     * Ether and should not have payable methods.
     */
    function() public {
        revert();
    }
}