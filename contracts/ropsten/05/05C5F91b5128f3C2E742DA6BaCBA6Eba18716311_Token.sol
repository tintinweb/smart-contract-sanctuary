pragma solidity >=0.4.24;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title CS188 Project 2
 *
 * @dev Implementation of a basic standard token.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol
 */
contract Token is IERC20{
	using SafeMath for uint256;
	
	string private _name  = "804989325";
	string private _symbol = "CS188";
	uint private _decimals = 18;
	
	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowed;
	uint256 private _totalSupply;
	
	function name() public view returns (string memory){
		return _name;
	}
	
	function symbol() public view returns (string memory){
		return _symbol;
	}
	
	function decimals() public view returns (uint){
		return _decimals;
	}
	
	constructor() {
		_balances[msg.sender] = 100 * 10**_decimals;
		emit Transfer(address(0), msg.sender, 100);
	}
	
	/**
	* @dev Total number of tokens in existence
	*/
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param owner The address to query the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address owner) public view override returns (uint256) {
		return _balances[owner];
	}

	/**
	 * @dev Function to check the amount of tokens that an owner allowed to a spender.
	 * @param owner address The address which owns the funds.
	 * @param spender address The address which will spend the funds.
	 * @return A uint256 specifying the amount of tokens still available for the spender.
	 */
	function allowance(address owner, address spender) public view override returns (uint256){
		return _allowed[owner][spender];
	}

	/**
	* @dev Transfer token for a specified address
	* @param to The address to transfer to.
	* @param value The amount to be transferred.
	*/
	function transfer(address to, uint256 value) public override returns (bool) {
		require(value <= _balances[msg.sender]);
		require(to != address(0));

		_balances[msg.sender] = _balances[msg.sender].sub(value);
		_balances[to] = _balances[to].add(value);
		emit Transfer(msg.sender, to, value);
		return true;
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
	function approve(address spender, uint256 value) public override returns (bool) {
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
	function transferFrom(address from, address to, uint256 value) public override returns (bool){
		require(value <= _balances[from]);
		require(value <= _allowed[from][msg.sender]);
		require(to != address(0));

		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);
		_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
		emit Transfer(from, to, value);
		return true;
	}
}