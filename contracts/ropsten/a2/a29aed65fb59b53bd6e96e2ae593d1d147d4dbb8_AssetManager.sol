pragma solidity 0.4.24;


//------------------------------------------------------------------------------------------------------------------
// @title where AssetManagers and Stakers can manage escrowed tokens
//------------------------------------------------------------------------------------------------------------------
contract AssetManager {
using SafeMath for uint;

  Database public database;


  //------------------------------------------------------------------------------------------------------------------
  // Constructor
  // @Param: Address of the database contract
  //------------------------------------------------------------------------------------------------------------------
  constructor(address _database)
  public {
    database = Database(_database);
  }

  //------------------------------------------------------------------------------------------------------------------
  // AssetManager can withdraw any escrowed tokens that are no longer needed in escrow here
  // Invariant: If asset has a staker, then the escrow belongs to staker. Otherwise it belongs to AssetManager
  // TODO: Clean this function up 
  //------------------------------------------------------------------------------------------------------------------
  function unlockEscrow(bytes32 _assetID)
  external
  accessApproved(1) {
    if (database.addressStorage(keccak256(abi.encodePacked("assetStaker", _assetID))) != address(0)) { 
      require(database.addressStorage(keccak256(abi.encodePacked("assetStaker", _assetID))) == msg.sender);
      require(database.uintStorage(keccak256(abi.encodePacked("stakingExpiration", _assetID))) < now); 
    }
    else { require(database.addressStorage(keccak256(abi.encodePacked("assetManager", _assetID))) == msg.sender); }
    uint amountToUnlock = database.uintStorage(keccak256(abi.encodePacked("escrowedForAsset", _assetID)));
    assert(amountToUnlock > uint(0));
    uint fundingStage = database.uintStorage(keccak256(abi.encodePacked("fundingStage", _assetID)));
    if (fundingStage == uint(2) || fundingStage == uint(5) || fundingStage == uint(0)) { 
      releaseEscrow(_assetID, msg.sender, amountToUnlock);     // Unlock all of the escrowed MYB since asset has finished it&#39;s lifecycle
    }
    else {
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
      uint assetIncome = database.uintStorage(keccak256(abi.encodePacked("assetIncome", _assetID)));
      uint percentageROI = database.uintStorage(keccak256(abi.encodePacked(assetIncome, _assetID))).mul(uint(100)).div(amountRaised);    // Ratio of  incomeProduced / funding cost  (both in WEI)
      if (percentageROI > uint(100)) { releaseEscrow(_assetID, msg.sender, amountToUnlock); }
      if (percentageROI > uint(75)) { releaseEscrow(_assetID, msg.sender, amountToUnlock.mul(uint(75)).div(uint(100))); }
      if (percentageROI > uint(50)) { releaseEscrow(_assetID, msg.sender, amountToUnlock.mul(uint(50)).div(uint(100))); }
      if (percentageROI > uint(25)) { releaseEscrow(_assetID, msg.sender, amountToUnlock.mul(uint(25)).div(uint(100))); }
    }
  }

  //------------------------------------------------------------------------------------------------------------------
  // Releases escrowed tokens. Only called internally.
  // TODO: make sure safemath throws if there is not enough MYB deposited
  //------------------------------------------------------------------------------------------------------------------
  function releaseEscrow(bytes32 _assetID, address _user, uint _amount)
  internal {
    assert (_amount > 0); 
    uint amountLockedForAsset = database.uintStorage(keccak256(abi.encodePacked("escrowedForAsset", _assetID)));
    uint totalEscrowedAmount = database.uintStorage(keccak256(abi.encodePacked("escrowedMYB", _user)));
    uint depositedAmount = database.uintStorage(keccak256(abi.encodePacked("depositedMYB", _user)));
    database.setUint(keccak256(abi.encodePacked("escrowedForAsset", _assetID)), amountLockedForAsset.sub(_amount));
    database.setUint(keccak256(abi.encodePacked("escrowedMYB", _user)), totalEscrowedAmount.sub(_amount));
    database.setUint(keccak256(abi.encodePacked("depositedMYB", _user)), depositedAmount.add(_amount));
    emit LogEscrowUnlocked(_assetID, _user, _amount);
  }

    //------------------------------------------------------------------------------------------------------------------
  // Asset manager can be changed by owner or governance authority here
  // @Param: Address of the replacement operator
  //------------------------------------------------------------------------------------------------------------------
  function replaceAssetManager(address _newManager, bytes32 _assetID)
  external
  anyOwner
  returns (bool) {
    require(database.uintStorage(keccak256(abi.encodePacked("userAccess", _newManager))) >= uint(1));   // Make sure new asset manager is approved
    require(database.uintStorage(keccak256(abi.encodePacked("userAccessExpiration", _newManager))) > now);
    address oldAssetManager = database.addressStorage(keccak256(abi.encodePacked("assetManager", _assetID)));
    require(oldAssetManager != address(0));
    database.setAddress(keccak256(abi.encodePacked("assetManager", _assetID)), _newManager);
    emit LogAssetManagerReplaced(_assetID, oldAssetManager, _newManager);
    return true;
  }


  //------------------------------------------------------------------------------------------------------------------
  //                                            Modifiers
  //------------------------------------------------------------------------------------------------------------------

  //------------------------------------------------------------------------------------------------------------------
  // Must have access level greater than or equal to 1
  //------------------------------------------------------------------------------------------------------------------
  modifier accessApproved(uint _accessLevel) {
    require(database.uintStorage(keccak256(abi.encodePacked("userAccess", msg.sender))) >= uint(_accessLevel));
    require(database.uintStorage(keccak256(abi.encodePacked("userAccessExpiration", msg.sender))) > now);
    _;
  }

    //------------------------------------------------------------------------------------------------------------------
  // Verify that the sender is a registered owner
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

  event LogEscrowUnlocked(bytes32 _assetID, address _user, uint _amount);
  event LogAssetManagerReplaced(bytes32 _assetID, address oldAssetManager, address _newManager);


}

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
  
  // ---------------------------------------------------------------------------------
// This contract holds all long-term data for the MyBit smart-contract systems
// All values are stored in mappings using a bytes32 keys.
// The bytes32 is derived from keccak256(variableName, uniqueID) => value
// ---------------------------------------------------------------------------------

}
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
        boolStorage[keccak256(abi.encodePacked("owner", _ownerOne))] = true;
        boolStorage[keccak256(abi.encodePacked("owner", _ownerTwo))] = true;
        boolStorage[keccak256(abi.encodePacked("owner", _ownerThree))] = true;
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
        require(boolStorage[keccak256(abi.encodePacked("owner", msg.sender))]);
        require(addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] == address(0));
        addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] = _contractManager;
        boolStorage[keccak256(abi.encodePacked("contract", _contractManager))] = true;
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
        require(boolStorage[keccak256(abi.encodePacked("contract", msg.sender))]);
        _;
    }

    // --------------------------------------------------------------------------------------
    // Events
    // --------------------------------------------------------------------------------------
    event LogInitialized(address indexed _ownerOne, address indexed _ownerTwo, address indexed _ownerThree);

}