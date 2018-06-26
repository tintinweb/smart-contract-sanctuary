contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  // Address(0) is the burnAddress.
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }
}

contract Killable is Ownable {

  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}

contract Accessible is Killable {

 	// Mapping the accounts.
    mapping(address => bool) public allowedAccounts;
    uint256 public numberOfAccounts;

    event AccessGranted(address newAccount);
    event AccessRemoved(address removedAccount);

    modifier onlyOwnerOrAllowed() {
        require(msg.sender == owner || allowedAccounts[msg.sender]);
        _;
    }

    modifier onlyAllowedAccount() {
        require(allowedAccounts[msg.sender]);
        _;
    }

    // Address(0) is the burnAddress.
    function grantAccess(address newAccount) public onlyOwnerOrAllowed {
    	// Check if is not the burnAddress and if not granted
        require(newAccount != address(0) && !allowedAccounts[newAccount]);
        allowedAccounts[newAccount] = true;
        numberOfAccounts += 1;

        require(numberOfAccounts != 0);
        // Emit event
        emit AccessGranted(newAccount);
    }

    function removeAccess(address removeAccount) public onlyOwnerOrAllowed {
    	// Check if already granted
        require(allowedAccounts[removeAccount]);
        require (numberOfAccounts >= 1);
        allowedAccounts[removeAccount] = false;
        numberOfAccounts -= 1;
        // Emit event
        emit AccessRemoved(removeAccount);
    }
}

interface Token {

	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value,
		uint256 _balance);

    event Approval(
    	address indexed _owner,
    	address indexed _spender,
    	uint256 _value);

    // OBSERVATION

    // Function must have been commented in this abstract contract because:
    // - in solidity defining a variable as public, automatically the language provides a getter for it;
    // - since the variable and the function name is the same, the next contract, implementing the
    //   abstract contract (inteface) will be considered abstract since shadowing occurs;
    // - if in a hierarchy all contracts are abstract, their deployment will result in a failure; 

	// @return The total amount of tokens.
	// function totalSupply() external constant returns (uint256 supply);

	// @param _owner The address from which the balance will be retrieved.
	// @return The balance of that account / address.
	// function balanceOf(address _owner) external constant returns (uint256  balance);

	// @notice Transfer &#39;_value&#39; token from &#39;msg.sender&#39; to &#39;_to&#39;.
	// @notice Emits Transfer event.
	// @param _to The address of the recipient.
	// @param _value The amount of token to be transferred.
	// @param {from: ...} The address of the sender (Metadata).
	// @return Whether the transfer was succesfull or not.
	function transfer(address _to, uint256 _value) external constant returns (bool success);

	// @notice Transfer &#39;_value&#39; token from &#39;_from&#39; to &#39;_to&#39; if amount is approved by &#39;_from&#39;.
	// @notice Emits Transfer event.
    // @param _from The address of the sender.
    // @param _to The address of the recipient.
	// @param _value The amount of token to be transferred.
	// @return Whether the transfer was succesfull or not.
	function transferFrom(address _from, address _to, uint256 _value) external constant returns (bool success);

	// @notice &#39;msg.sender&#39; approves &#39;_spender&#39; to spend &#39;_value&#39; tokens.
	// @notice Emits Approval event.
    // @param _spender The address of the account able to transfer the tokens.
    // @param _value The amount of Wei to be approved for transfer.
    // @return Whether the approval was successful or not.
    function approve(address _spender, uint256 _value) external constant  returns (bool success);

    // @param _owner The address of the account owning tokens.
    // @param _spender The address of the account able to transfer the tokens.
    // @return Amount of remaining tokens allowed to be spent.
    // function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
}

contract ERC20Token is Token, Accessible {
	// Since the modifier is public, Solidity already provides a getter function for the variable. 
	uint256 public totalSupply;

	// Take the address of an owner and return the balance of that particular address.
	mapping (address => uint256) public balanceOf;
	
	// Allowance map. &#39;owner&#39; as 1st key holds a map to all approvements with key &#39;spender&#39; and value &#39;amount&#39;.
	mapping (address => mapping (address => uint256)) public allowance;

	// function totalSupply() public constant returns (uint256 totalSupply) {
	// 	return totalSupply;
	// }

	// function balanceOf(address _owner) public constant returns (uint256 balance) {
 	//  return balanceOf[_owner];
 	// }

 	// Return true or throw an exception and revert the transfer.
 	// In case of revert will consume gas till the point that not meets the requierements.
	function transfer(address _to, uint256 _value) public returns (bool success){
		// Have sufficient funds.
		require (balanceOf[msg.sender] >= _value);
		// Transfer amount must be greater than 0.
		require (_value > 0);
		// Overflow check.
		require (balanceOf[_to] + _value > balanceOf[_to]);
		
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;

		require (balanceOf[_to] != 0);

		emit Transfer(msg.sender, _to, _value, balanceOf[msg.sender]);

		return true;
	}

 	// Return true or throw an exception and revert the transferFrom.
 	// In case of revert will consume gas till the point that not meets the requierements.
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		// Have sufficient funds.
		require (balanceOf[_from] >= _value);
		// Have sufficient allowance.
		require (allowance[_from][msg.sender] >= _value);
		// Transfer amount must be greater than 0.
		require (_value > 0);
		
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		require (balanceOf[_to] != 0);
		allowance[_from][msg.sender] -= _value;

		emit Transfer(_from, _to, _value, balanceOf[msg.sender]);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] += _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

    // function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}
    //   return allowance[_owner][_spender];
    // }
}

contract EduScienceToken is ERC20Token {

    string public name = &quot;EduScience&quot;;
    string public symbol = &quot;ESc&quot;;
    string public version = &quot;EduScience Token v1.0&quot;; 

	// Set the total number of tokens.
	constructor (uint256 _initialSupply) public {
		// State variable for the smart contract, written to the blockchain at each modification
		// _variable is for local variables -> Solidity convention
		totalSupply = _initialSupply;

		// Allocate the _initialSupply
		// msg is a global variable in Solidity that has several values. Sender is the address, sent via the metadata in JS
		balanceOf[msg.sender] = _initialSupply;
	}

	// Same as the normal transfer, but this is for interior usage, fee perception.
	// Major security breach: this function should be called only from other contracts => modifier onlyOwnerOrAllowed.
	function transfer(address _from, address _to, uint256 _value) public onlyOwnerOrAllowed returns (bool success){
		// Have sufficient funds.
		require (balanceOf[_from] >= _value);
		// Transfer amount must be greater than 0.
		require (_value > 0);
		// Overflow check.
		require (balanceOf[_to] + _value > balanceOf[_to]);
		
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		require (balanceOf[_to] != 0);

		emit Transfer(_from, _to, _value, balanceOf[_from]);

		return true;
	}
}