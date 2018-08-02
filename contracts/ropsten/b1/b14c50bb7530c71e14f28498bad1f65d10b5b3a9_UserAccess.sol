pragma solidity 0.4.24;


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

//------------------------------------------------------------------------------------------------------------------
// This contract controls users access to the MyBit platform. TokenBurn will call this contract to add new users, once MyBit tokens have been burnt
// There are 3 levels of access on the platform. First is basic access (creating/funding assets), Second is ability to stake, Third is ability to trade assets
//------------------------------------------------------------------------------------------------------------------
contract UserAccess{

  Database public database;
  uint public oneYear = uint(31536000);    // 365 days in seconds

  //------------------------------------------------------------------------------------------------------------------
  // Constructor: Inititalize Database
  //------------------------------------------------------------------------------------------------------------------
  constructor(address _database)
  public  {
    database = Database(_database);
  }

  //------------------------------------------------------------------------------------------------------------------
  // Owner can manually grant access to a user here. WIll be used for KYC approval
  // Invariants: Only called by Token Burning contract or Owner. Access level must be between 1-4
  // @Param: Address of new user.
  // @Param: The level of access granted by owner/burningcontract
  // TODO: owner requirement is removed for alpha testing
  //------------------------------------------------------------------------------------------------------------------
  function approveUser(address _newUser, uint _accessLevel)
  // anyOwner
  noEmptyAddress(_newUser)
  external
  returns (bool) {
    require(_accessLevel < uint(4) && _accessLevel != uint(0));
    database.setUint(keccak256(abi.encodePacked(&quot;userAccess&quot;, _newUser)), _accessLevel);
    uint expiry = now + oneYear;
    assert (expiry > now && expiry > oneYear);   // Check for overflow
    database.setUint(keccak256(abi.encodePacked(&quot;userAccessExpiration&quot;, _newUser)), expiry);
    emit LogUserApproved(_newUser, _accessLevel);
    return true;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Owner can remove access for users if needed
  // Invariants: Only owner can call.
  // @Param: User to be removed
  //------------------------------------------------------------------------------------------------------------------
  function removeUser(address _user)
  anyOwner
  external
  returns (bool) {
    uint accessLevel = database.uintStorage(keccak256(abi.encodePacked(&quot;userAccess&quot;, _user)));
    database.deleteUint(keccak256(abi.encodePacked(&quot;userAccess&quot;, _user)));
    database.deleteUint(keccak256(abi.encodePacked(&quot;userAccessExpiration&quot;, _user)));
    emit LogUserRemoved(_user, accessLevel);
    return true;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Owner can approve KYC for user
  //------------------------------------------------------------------------------------------------------------------
  function approveKYC(address _user)
  anyOwner
  external
  returns (bool) {
    database.setBool(keccak256(abi.encodePacked(&quot;kycApproved&quot;, msg.sender)), true);
    emit LogKYCApproved(msg.sender, _user);
  }

  //------------------------------------------------------------------------------------------------------------------
  // Deny empty address parameters
  //------------------------------------------------------------------------------------------------------------------
  modifier noEmptyAddress(address _param) {
    require(_param != address(0));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Only owners can call these functions
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked(&quot;owner&quot;, msg.sender))));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  //                                        Events
  //------------------------------------------------------------------------------------------------------------------
  event LogUserApproved(address _user, uint _approvalLevel);
  event LogUserRemoved(address indexed _user, uint indexed _accessLevel);
  event LogKYCApproved(address _owner, address _user);
}