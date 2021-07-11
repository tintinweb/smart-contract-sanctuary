pragma solidity ^0.4.13;

contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	/**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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
		Transfer(_from, _to, _value);
		return true;
	}

	/**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
	function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
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
	function Ownable() {
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
	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	bool public mintingFinished = false;


	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	/**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
	function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
		totalSupply = totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		Mint(_to, _amount);
		Transfer(0x0, _to, _amount);
		return true;
	}

	/**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
	function finishMinting() onlyOwner public returns (bool) {
		mintingFinished = true;
		MintFinished();
		return true;
	}
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

	event Burn(address indexed burner, uint256 value);

	/**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
	function burn(uint256 _value) public {
		require(_value > 0);
		require(_value <= balances[msg.sender]);
		// no need to require value <= totalSupply, since that would imply the
		// sender's balance is greater than the totalSupply, which *should* be an assertion failure

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
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
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		Pause();
	}

	/**
     * @dev called by the owner to unpause, returns to normal state
     */
	function unpause() onlyOwner whenPaused public {
		paused = false;
		Unpause();
	}
}

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract WithdrawVault is Ownable {
	using SafeMath for uint256;

	mapping (address => uint256) public deposited;
	address public wallet;


	function WithdrawVault(address _wallet) {
		require(_wallet != 0x0);
		wallet = _wallet;
	}

	function deposit(address investor) onlyOwner payable {
		deposited[investor] = deposited[investor].add(msg.value);
	}

	function close() onlyOwner {
		wallet.transfer(this.balance);
	}

}

contract Migrations {
	address public owner;
	uint public last_completed_migration;

	modifier restricted() {
		if (msg.sender == owner) _;
	}

	function Migrations() {
		owner = msg.sender;
	}

	function setCompleted(uint completed) restricted {
		last_completed_migration = completed;
	}

	function upgrade(address new_address) restricted {
		Migrations upgraded = Migrations(new_address);
		upgraded.setCompleted(last_completed_migration);
	}
}

contract TokenRecipient {

	function tokenFallback(address sender, uint256 _value, bytes _extraData) returns (bool) {}

}

contract FunctionX is MintableToken, BurnableToken, PausableToken {

	string public constant name = "Function X";
	string public constant symbol = "FX";
	uint8 public constant decimals = 18;

	function FunctionX() {
		mint(msg.sender, 1e26 );
		mint(0x901FCeaF2DC4A7b5c6d699a79DBf8468a29DD873, 1e25);
		mint(0xEd9dd2a4F4455C0B42b053343F74Af2F926537ae, 1e25);
		mint(0x14Aab2435DDa3A7b77538731750B49CA7733A65d, 1e25);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		bool result = super.transferFrom(_from, _to, _value);
		return result;
	}

	mapping (address => bool) stopReceive;

	function setStopReceive(bool stop) {
		stopReceive[msg.sender] = stop;
	}

	function getStopReceive() constant public returns (bool) {
		return stopReceive[msg.sender];
	}

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		require(!stopReceive[_to]);
		bool result = super.transfer(_to, _value);
		return result;
	}

	function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
		bool result = super.mint(_to, _amount);
		return result;
	}

	function burn(uint256 _value) public {
		super.burn(_value);
	}

	function pause() onlyOwner whenNotPaused public {
		super.pause();
	}

	function unpause() onlyOwner whenPaused public {
		super.unpause();
	}

	function transferAndCall(address _recipient, uint256 _amount, bytes _data) {
		require(_recipient != address(0));
		require(_amount <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_recipient] = balances[_recipient].add(_amount);

		require(TokenRecipient(_recipient).tokenFallback(msg.sender, _amount, _data));
		Transfer(msg.sender, _recipient, _amount);
	}

	function transferERCToken(address _tokenContractAddress, address _to, uint256 _amount) onlyOwner {
		require(ERC20(_tokenContractAddress).transfer(_to, _amount));
	}

}