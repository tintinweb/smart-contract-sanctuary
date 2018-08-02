pragma solidity 0.4.24;

  //--------------------------------------------------------------------------------------------------
  // Math operations with safety checks that throw on error
  //--------------------------------------------------------------------------------------------------
library SafeMath {

  //--------------------------------------------------------------------------------------------------
  // Multiplies two numbers, throws on overflow.
  //--------------------------------------------------------------------------------------------------
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  //--------------------------------------------------------------------------------------------------
  // Integer division of two numbers, truncating the quotient.
  //--------------------------------------------------------------------------------------------------
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  //--------------------------------------------------------------------------------------------------
  // Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  //--------------------------------------------------------------------------------------------------
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  //--------------------------------------------------------------------------------------------------
  // Adds two numbers, throws on overflow.
  //--------------------------------------------------------------------------------------------------
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  //--------------------------------------------------------------------------------------------------
  // Returns fractional amount
  //--------------------------------------------------------------------------------------------------
  function getFractionalAmount(uint256 _amount, uint256 _percentage)
  internal
  pure
  returns (uint256) {
    return div(mul(_amount, _percentage), 100);
  }

  //--------------------------------------------------------------------------------------------------
  // Convert bytes to uint
  // TODO: needs testing: use SafeMath
  //--------------------------------------------------------------------------------------------------
  function bytesToUint(bytes b) internal pure returns (uint256) {
      uint256 number;
      for(uint i=0; i < b.length; i++){
          number = number + uint(b[i]) * (2**(8 * (b.length - (i+1))));
      }
      return number;
  }

}

// ----------------------------------------------------------------------------
// Receive approval and then execute function
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ------------------------------------------------------------------------
// Standard ERC20 Token Contract.
// Fixed Supply with burn capabilities
// ------------------------------------------------------------------------
contract MyBitToken is ERC20Interface{
    using SafeMath for uint; 

    // ------------------------------------------------------------------------
    /// Token supply, balances and allowance
    // ------------------------------------------------------------------------
    uint internal supply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    // ------------------------------------------------------------------------
    // Token Information
    // ------------------------------------------------------------------------
    string public name;                   // Full Token name
    uint8 public decimals;                // How many decimals to show
    string public symbol;                 // An identifier


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) 
    public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        supply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        emit Transfer(address(0), msg.sender, _initialAmount);    // Transfer event indicating token creation
    }

    // ------------------------------------------------------------------------
    // Transfer _amount tokens to address _to 
    // Sender must have enough tokens. Cannot send to 0x0.
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0));         // Use burn() function instead
        require(_to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer _amount of tokens if _from has allowed msg.sender to do so
    //  _from must have enough tokens + must have approved msg.sender 
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0)); 
        require(_to != address(this)); 
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address _spender, uint _amount) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token holder can notify a contract that it has been approved
    // to spend _amount of tokens
    // ------------------------------------------------------------------------
    function approveAndCall(address _spender, uint _amount, bytes _data) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Removes senders tokens from supply.
    // Lowers user balance and totalSupply by _amount
    // ------------------------------------------------------------------------   
    function burn(uint _amount) 
    public 
    returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        supply = supply.sub(_amount);
        emit LogBurn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // An approved sender can burn _amount tokens of user _from
    // Lowers user balance and supply by _amount 
    // ------------------------------------------------------------------------    
    function burnFrom(address _from, uint _amount) 
    public 
    returns (bool success) {
        balances[_from] = balances[_from].sub(_amount);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);             // Subtract from the sender&#39;s allowance
        supply = supply.sub(_amount);                              // Update supply
        emit LogBurn(_from, _amount);
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the number of tokens in circulation
    // ------------------------------------------------------------------------
    function totalSupply()
    public 
    view 
    returns (uint tokenSupply) { 
        return supply; 
    }

    // ------------------------------------------------------------------------
    // Returns the token balance of user
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenHolder) 
    public 
    view 
    returns (uint balance) {
        return balances[_tokenHolder];
    }

    // ------------------------------------------------------------------------
    // Returns amount of tokens _spender is allowed to transfer or burn
    // ------------------------------------------------------------------------
    function allowance(address _tokenHolder, address _spender) 
    public 
    view 
    returns (uint remaining) {
        return allowed[_tokenHolder][_spender];
    }

    // ------------------------------------------------------------------------
    // Fallback function
    // Won&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () 
    public 
    payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Event: Logs the amount of tokens burned and the address of the burner
    // ------------------------------------------------------------------------
    event LogBurn(address indexed _burner, uint indexed _amountBurned); 
}


// ---------------------------------------------------------------------------------
// This contract holds all long-term data for the MyBit smart-contract systems
// All values are stored in mappings using a bytes32 keys.
// The bytes32 is derived from keccak256(variableName, uniqueID) => value
// ---------------------------------------------------------------------------------
contract Database {

    // --------------------------------------------------------------------------------------
    // Storage Variables
    // --------------------------------------------------------------------------------------
    mapping(bytes32 => uint) public uintStorage;
    mapping(bytes32 => string) public stringStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
    mapping(bytes32 => bytes32) public bytes32Storage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => int) public intStorage;



    // --------------------------------------------------------------------------------------
    // Constructor: Sets the owners of the platform
    // Owners must set the contract manager to add more contracts
    // --------------------------------------------------------------------------------------
    constructor(address _ownerOne, address _ownerTwo, address _ownerThree)
    public {
        boolStorage[keccak256(abi.encodePacked(&quot;owner&quot;, _ownerOne))] = true;
        boolStorage[keccak256(abi.encodePacked(&quot;owner&quot;, _ownerTwo))] = true;
        boolStorage[keccak256(abi.encodePacked(&quot;owner&quot;, _ownerThree))] = true;
        emit LogInitialized(_ownerOne, _ownerTwo, _ownerThree);
    }


    // --------------------------------------------------------------------------------------
    // ContractManager will be the only contract that can add/remove contracts on the platform.
    // Invariants: ContractManager address must not be null.
    // ContractManager must not be set, Only owner can call this function.
    // --------------------------------------------------------------------------------------
    function setContractManager(address _contractManager)
    external {
        require(_contractManager != address(0));
        require(boolStorage[keccak256(abi.encodePacked(&quot;owner&quot;, msg.sender))]);
        // require(addressStorage[keccak256(abi.encodePacked(&quot;contract&quot;, &quot;ContractManager&quot;))] == address(0));   TODO: Allow swapping of CM for testing
        addressStorage[keccak256(abi.encodePacked(&quot;contract&quot;, &quot;ContractManager&quot;))] = _contractManager;
        boolStorage[keccak256(abi.encodePacked(&quot;contract&quot;, _contractManager))] = true;
        emit LogContractManager(_contractManager, msg.sender); 
    }

    // --------------------------------------------------------------------------------------
    //  Storage functions
    // --------------------------------------------------------------------------------------

    function setAddress(bytes32 _key, address _value)
    onlyMyBitContract
    external {
        addressStorage[_key] = _value;
    }

    function setUint(bytes32 _key, uint _value)
    onlyMyBitContract
    external {
        uintStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value)
    onlyMyBitContract
    external {
        stringStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value)
    onlyMyBitContract
    external {
        bytesStorage[_key] = _value;
    }

    function setBytes32(bytes32 _key, bytes32 _value)
    onlyMyBitContract
    external {
        bytes32Storage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value)
    onlyMyBitContract
    external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value)
    onlyMyBitContract
    external {
        intStorage[_key] = _value;
    }


    // --------------------------------------------------------------------------------------
    // Deletion functions
    // --------------------------------------------------------------------------------------

    function deleteAddress(bytes32 _key)
    onlyMyBitContract
    external {
        delete addressStorage[_key];
    }

    function deleteUint(bytes32 _key)
    onlyMyBitContract
    external {
        delete uintStorage[_key];
    }

    function deleteString(bytes32 _key)
    onlyMyBitContract
    external {
        delete stringStorage[_key];
    }

    function deleteBytes(bytes32 _key)
    onlyMyBitContract
    external {
        delete bytesStorage[_key];
    }

    function deleteBytes32(bytes32 _key)
    onlyMyBitContract
    external {
        delete bytes32Storage[_key];
    }

    function deleteBool(bytes32 _key)
    onlyMyBitContract
    external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key)
    onlyMyBitContract
    external {
        delete intStorage[_key];
    }



    // --------------------------------------------------------------------------------------
    // Caller must be registered as a contract within the MyBit Dapp through ContractManager.sol
    // --------------------------------------------------------------------------------------
    modifier onlyMyBitContract() {
        require(boolStorage[keccak256(abi.encodePacked(&quot;contract&quot;, msg.sender))]);
        _;
    }

    // --------------------------------------------------------------------------------------
    // Events
    // --------------------------------------------------------------------------------------
    event LogInitialized(address indexed _ownerOne, address indexed _ownerTwo, address indexed _ownerThree);
    event LogContractManager(address indexed _contractManager, address indexed _initiator); 
}


// Can use this contract to give tokens away.
// Note: This is not secure and has no limits placed. Use for test-net only.
contract TokenFaucet {

  MyBitToken public token;
  Database public database; 
  uint public tokensInFaucet;
  bytes32 private accessPass; 

  uint public oneYear = uint(31536000);    // 365 days in seconds


  constructor(address _database, address _tokenAddress, bytes32 _accessPass)
  public  {
    database = Database(_database); 
    token = MyBitToken(_tokenAddress);
    accessPass = _accessPass; 
  }

  // For owner to deposit tokens easier
  function receiveApproval(address _from, uint _amount, address _token, bytes _data)
  external {
    require(_token == msg.sender && _token == address(token));
    require(token.transferFrom(_from, this, _amount));
    tokensInFaucet += _amount;
    emit TokenDeposit(_from, _amount, block.number);
  }

  function deposit(uint _amount)
  external {
    require(token.transferFrom(msg.sender, this, _amount));
    tokensInFaucet += _amount;
    emit TokenDeposit(msg.sender, _amount, block.number);
  }

  // Weak defense with password. Not Secure
  function withdraw(uint _amount, string _pass)
  external {
    require (tokensInFaucet >= _amount);
    require (keccak256(abi.encodePacked(_pass)) == accessPass); 
    tokensInFaucet -= _amount;
    token.transfer(msg.sender, _amount);
    emit TokenWithdraw(msg.sender, _amount, block.number);
  }

    // Weak defense with password. Not Secure
  function register(uint _amount, string _pass)
  external {
    require (tokensInFaucet >= _amount);
    require (keccak256(abi.encodePacked(_pass)) == accessPass); 
    tokensInFaucet -= _amount;
    token.transfer(msg.sender, _amount);
    database.setUint(keccak256(abi.encodePacked(&quot;userAccess&quot;, msg.sender)), 1);
    uint expiry = now + oneYear;
    assert (expiry > now && expiry > oneYear);   // Check for overflow
    database.setUint(keccak256(abi.encodePacked(&quot;userAccessExpiration&quot;, msg.sender)), expiry);
    emit TokenWithdraw(msg.sender, _amount, block.number);
  }

  function changePass(bytes32 _newPass)
  external 
  anyOwner
  returns (bool) { 
    accessPass = _newPass; 
    return true; 
  }

  //------------------------------------------------------------------------------------------------------------------
  // Verify that the sender is a registered owner
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked(&quot;owner&quot;, msg.sender))));
    _;
  }

  event TokenWithdraw(address _sender, uint _amount, uint _blockNumber);
  event TokenDeposit(address _depositer, uint _amount, uint _blockNumber);
}