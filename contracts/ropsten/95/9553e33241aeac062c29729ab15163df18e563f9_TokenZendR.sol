pragma solidity ^0.4.23;

// File: contracts\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts\Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts\Tokenzendr.sol

contract TokenZendR is Ownable, Pausable {

	/**  
	* @dev Details of each transfer  
	* @param _contract contract address of ER20 token to transfer  
	* @param _to receiving account  
	* @param _amount number of tokens to transfer _to account  
	* @param _failed if transfer was successful or not  
	*/  
	struct Transfer {  
	  address _contract;  
	  address _to;  
	  uint _amount;  
	  bool _failed;  
	}

	/**
	* @dev a mapping from transaction ID&#39;s to the sender address
	* that initiates them. Owners can create several transactions
	*/
	mapping (address => uint[]) public transactionIndexesToSender;

	/**
	* @dev a list of all transfers successful or unsuccessful
	*/
	Transfer[] public transactions;
	address public owner;

	/**
	* @dev list of all supported tokens for transfer
	* @param string token symbol
	* @param address contract address of token
	*/
	mapping(bytes32 => address) public tokens;

	ERC20 public ERC20Interface;

	/**
	* @dev Event to notfy if transfer successful or failed
	* after account approval verified
	*/
	event TransferSuccessful(address indexed _from, address indexed _to, uint256 _amount);
	event TransferFailed(address indexed _from, address indexed _to, uint256 _amount);

	constructor() public{
		owner = msg.sender;
	}
	/**
	* @dev add address of token to list of supported tokens using 
	* token symbol as identifier in mapping
	*/
	function addNewToken(bytes32 _symbol, address _address)
	public
	onlyOwner
	returns (bool){
		tokens[_symbol] = _address;
		return true;
	}

	/**
	* @dev remove address of token no more supported
	*/
	function removeToken(bytes32 _symbol)
	public
	onlyOwner
	returns(bool){
		require(tokens[_symbol] != 0x0);
		delete(tokens[_symbol]);
		return true;
	}

	/**
	* @dev method that handles transfer of ERC20 tokens to other address
	* it assumes the calling addres has approved this contract as spender
	* @param _symbol indentifier mapping to a token contract address
	* @param _to beneficiary address
	@param _amount numbers of token to transfer
	*/
	function transferTokens(bytes32 _symbol, address _to, uint256 _amount) public whenNotPaused{
		require(tokens[_symbol] != 0x0);
		require(_amount > 0);
		address _contract = tokens[_symbol];
		address _from = msg.sender;

		ERC20Interface = ERC20(_contract);

		uint256 transactionId = transactions.push(
			Transfer({
				_contract: _contract,
				_to: _to,
				_amount: _amount,
				_failed: true
				})
		);
		transactionIndexesToSender[_from].push(transactionId - 1);

		if(_amount > ERC20Interface.allowance(_from, address(this))){
		emit TransferFailed(_from ,_to,_amount);	
		revert();														 
		}
		ERC20Interface.transferFrom(_from, _to, _amount);

		transactions[transactionId - 1]._failed = false;

		emit TransferSuccessful(_from, _to, _amount);
	}

	/**
	* @dev allow contract to receive funds
	*/
	function() public payable{}

	/**
	* @dev withdraw funds from this contract
	* @param beneficiary address to receive ether
	*/
	function withdraw(address beneficiary) public payable onlyOwner
	whenNotPaused{
		beneficiary.transfer(address(this).balance);
	}

}