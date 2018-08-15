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
        // require(addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] == address(0));   TODO: Allow swapping of CM for testing
        addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] = _contractManager;
        boolStorage[keccak256(abi.encodePacked("contract", _contractManager))] = true;
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
        require(boolStorage[keccak256(abi.encodePacked("contract", msg.sender))]);
        _;
    }

    // --------------------------------------------------------------------------------------
    // Events
    // --------------------------------------------------------------------------------------
    event LogInitialized(address indexed _ownerOne, address indexed _ownerTwo, address indexed _ownerThree);
    event LogContractManager(address indexed _contractManager, address indexed _initiator); 
}

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol

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


//----------------------------------------------------------------------------------------------------------------------------------------
// This contract is where users can initite funding periods for new assets.
// Stores asset information in Database. Owners can modify funding variables here.
//----------------------------------------------------------------------------------------------------------------------------------------
contract AssetCreation {
  using SafeMath for *;

  Database public database;
  uint public fundingTime = uint(3000);        // TODO: Testing number

  constructor(address _database)
  public  {
      database = Database(_database);
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // This begins the funding period for an asset. If asset is success it will be added to the assets variable here in AssetCreation
  // @Param: The amount of USD required for asset to achieve successfull funding
  // @Param: The percentage of revenue the asset manager will require to run the asset
  // @Param: The amount the asset manager has decided to escrow
  // @Param: The ID of the installer of this asset  (ie. Sha3("ATMInstallersAG"))
  // @Param: The type of asset being created. (ie. Sha3("BitcoinATM")) 
  // @Param: The block when the escrow request was created. If no escrow request was made, then any unique number will work
  //----------------------------------------------------------------------------------------------------------------------------------------
  function newAsset(uint _amountToBeRaised, uint _managerPercentage, uint _amountToEscrow, bytes32 _installerID, bytes32 _assetType, uint _blockAtCreation, bytes32 _ipfsHash)
  external
  whenNotPaused
  noEmptyBytes(_installerID)
  noEmptyBytes(_assetType)
  noEmptyBytes(_ipfsHash)
  returns (bool){
    // TODO: uncomment when inner-alpha done 
    // require(database.uintStorage(keccak256(abi.encodePacked("userAccess", msg.sender))) >= uint(1), "user does not have high enough access level");
    // require(database.uintStorage(keccak256(abi.encodePacked("userAccessExpiration", msg.sender))) > now , "User access has expired");
    require(_managerPercentage < uint(100) && _managerPercentage > uint(0) , "manager percentage is too high or too low");
    require(_amountToBeRaised > uint(100), "amountToBeRaised is too low");           // Minimum asset price
    bytes32 assetID = keccak256(abi.encodePacked(msg.sender, _amountToEscrow, _managerPercentage, _amountToBeRaised, _installerID, _assetType, _blockAtCreation));
    require(database.uintStorage(keccak256(abi.encodePacked("fundingStage", assetID))) == uint(0), "AssetID already exists.");    // This ensures the asset isn&#39;t currently live or being funded
    database.setUint(keccak256(abi.encodePacked("fundingStage", assetID)), uint(1));       // Allow this asset to receive funding
    address staker = database.addressStorage(keccak256(abi.encodePacked("assetStaker", assetID)));
    if (staker != address(0)) { 
      assert (database.uintStorage(keccak256(abi.encodePacked("stakingExpiration", assetID))) > now); 
      database.deleteUint(keccak256(abi.encodePacked("stakingExpiration", assetID)));  
    }
    else { require(lockAssetEscrow(assetID, _amountToEscrow, msg.sender), "locking asset escrow failed"); }
    database.setUint(keccak256(abi.encodePacked("amountToBeRaised", assetID)), _amountToBeRaised);
    database.setUint(keccak256(abi.encodePacked("managerPercentage", assetID)), _managerPercentage);
    database.setAddress(keccak256(abi.encodePacked("assetManager", assetID)), msg.sender);
    database.setUint(keccak256(abi.encodePacked("fundingDeadline", assetID)), fundingTime.add(now));
    emit LogAssetFundingStarted(assetID, _installerID, _assetType, _ipfsHash);    // assetType and installer ID are already indexed
    return true;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // This function locks MyBit tokens to the asset for the length of it&#39;s lifecycle
  //----------------------------------------------------------------------------------------------------------------------------------------
  function lockAssetEscrow(bytes32 _assetID, uint _amountToEscrow, address _escrowDepositer)
  internal
  returns (bool) {
    if (_amountToEscrow == 0) { return true; }
    uint escrowedMYB = database.uintStorage(keccak256(abi.encodePacked("escrowedMYB", _escrowDepositer)));
    uint depositedMYB = database.uintStorage(keccak256(abi.encodePacked("depositedMYB", _escrowDepositer)));
    // assert (_amountToEscrow <= depositedMYB);    // TODO: Safemath should throw here if this isn&#39;t the case
    database.setUint(keccak256(abi.encodePacked("depositedMYB", _escrowDepositer)), depositedMYB.sub(_amountToEscrow)); 
    database.setUint(keccak256(abi.encodePacked("escrowedMYB", _escrowDepositer)), escrowedMYB.add(_amountToEscrow));
    database.setUint(keccak256(abi.encodePacked("escrowedForAsset", _assetID)), _amountToEscrow);
    emit LogLockAssetEscrow(_escrowDepositer, _assetID, _amountToEscrow);
    return true;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // This removes asset functionality by setting it to an invalid stage. Must leave variables as users may need to withdrawl income.
  // Other owner must have approved the function to be called in Owned.sol (authorizeFunction())
  //----------------------------------------------------------------------------------------------------------------------------------------
  function removeAsset(bytes32 _assetID, address _functionSigner)
  external
  anyOwner
  noEmptyBytes(_assetID)
  whenNotPaused
  returns(bool) {
    require (_functionSigner != msg.sender);
    require(database.uintStorage(keccak256(abi.encodePacked("fundingStage", _assetID))) > uint(0));
    bytes32 functionHash = keccak256(abi.encodePacked(address(this), _functionSigner, "removeAsset", _assetID));
    require(database.boolStorage(functionHash));
    database.setBool(functionHash, false);
    database.setUint(keccak256(abi.encodePacked("fundingStage", _assetID)), uint(5));   // Asset won&#39;t receive income & ownership won&#39;t be able to be traded.
    emit LogAssetRemoved(_assetID, msg.sender);
    return true;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // Change the default funding time for new assets
  // Invariants: Only owner[0] can call  |  new funding time is not 0
  //----------------------------------------------------------------------------------------------------------------------------------------
  function changeFundingTime(uint _newTimeGivenForFunding)
  external
  anyOwner
  notZero(_newTimeGivenForFunding)
  returns (bool) {
    fundingTime = _newTimeGivenForFunding;
    emit LogFundingTimeChanged(msg.sender, _newTimeGivenForFunding);
    return true;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // Changes the platform fees received from funded assets
  // Requires multi-sig verification. With sha3() of the agreed percentages as the beneficiary parameter
  //----------------------------------------------------------------------------------------------------------------------------------------
  function changeFundingPercentages(uint _myBitFoundationPercentage, uint _installerPercentage, address _functionSigner)
  external
  anyOwner
  notZero(_myBitFoundationPercentage)
  notZero(_installerPercentage)
  returns (bool) {
    bytes32 functionHash = keccak256(abi.encodePacked(address(this), _functionSigner, "changeFundingPercentages", keccak256(abi.encodePacked(_myBitFoundationPercentage, _installerPercentage))));
    require(database.boolStorage(functionHash));
    require(_myBitFoundationPercentage.add(_installerPercentage) == uint(100));
    database.setBool(functionHash, false);
    database.setUint(keccak256(abi.encodePacked("myBitFoundationPercentage")), _myBitFoundationPercentage);
    database.setUint(keccak256(abi.encodePacked("installerPercentage")), _installerPercentage);
    emit LogFundingPercentageChanged(_myBitFoundationPercentage, _installerPercentage);
    return true;
  }

  //----------------------------------------------------------------------------------------------------------------------------------------
  // Must be authorized by 1 of the 3 owners and then can be called by any of the other 2
  // @Param: The address of the owner who authorized this function to be called in
  // Invariants: Must be 1 of 3 owners. Cannot be called by same owner who authorized the function to be called.
  //----------------------------------------------------------------------------------------------------------------------------------------
  function destroy(address _functionInitiator, address _holdingAddress)
  anyOwner
  public {
    require(_functionInitiator != msg.sender);
    bytes32 functionHash = keccak256(abi.encodePacked(address(this), _functionInitiator, "destroy", keccak256(abi.encodePacked(_holdingAddress))));
    require(database.boolStorage(functionHash));
    database.setBool(functionHash, false);
    emit LogDestruction(_holdingAddress, address(this).balance, msg.sender);
    selfdestruct(_holdingAddress);
  }



  //------------------------------------------------------------------------------------------------------------------
  //                                            Modifiers
  //------------------------------------------------------------------------------------------------------------------

  //------------------------------------------------------------------------------------------------------------------
  // Makes sure function won&#39;t run when contract has been paused
  //------------------------------------------------------------------------------------------------------------------
  modifier whenNotPaused {
    require(!database.boolStorage(keccak256(abi.encodePacked("pause", address(this)))));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Don&#39;t accept null value for bytes32 parameter
  //------------------------------------------------------------------------------------------------------------------
  modifier noEmptyBytes(bytes32 _data) {
    require(_data != bytes32(0));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Don&#39;t accept null value for uint
  //------------------------------------------------------------------------------------------------------------------
  modifier notZero(uint _uint) {
    require(_uint != 0);
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Sender must be a registered owner
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  //                                            Events
  //------------------------------------------------------------------------------------------------------------------

  event LogAssetFundingStarted(bytes32 indexed _assetID, bytes32 indexed _installerID, bytes32 indexed _assetType, bytes32 _ipfsHash);
  event LogLockAssetEscrow(address _from, bytes32 _assetID, uint _amountOf);
  event LogAssetRemoved(bytes32 indexed _assetID, address _remover);
  event LogFundingTimeChanged(address _sender, uint _newTimeForFunding);
  event LogFundingPercentageChanged(uint _myBitFoundationPercentage, uint _installerPercentage);
  event LogDestruction(address indexed _locationSent, uint indexed _amountSent, address indexed _caller);
}