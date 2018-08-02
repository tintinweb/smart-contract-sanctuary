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

//-----------------------------------------------------------------------------------------------------------------------
// Standard getters for common variables stored in Database.
// Database variables are stored as sha3 hashes of variable name + id&#39;s.
// TODO: Add function to get how much more Eth asset needs (USD needed -> ETH price)
//-----------------------------------------------------------------------------------------------------------------------
contract API {

  Database public database;

  constructor(address _database)
  public {
    database = Database(_database);
  }


  //-----------------------------------------------------------------------------------------------------------------------
  //                                                 Initial Variables
  //-----------------------------------------------------------------------------------------------------------------------

  function MyBitFoundation()
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked(&quot;MyBitFoundation&quot;)));
  }

  function InstallerEscrow()
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked(&quot;InstallerEscrow&quot;)));
  }

  function myBitFoundationPercentage()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;myBitFoundationPercentage&quot;)));
  }

  function installerPercentage()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;installerPercentage&quot;)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                               Contract State
  //-----------------------------------------------------------------------------------------------------------------------
  function isPaused(address _contractAddress)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked(&quot;pause&quot;, _contractAddress)));
  }

  function contractAddress(string _name)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked(&quot;contract&quot;, _name)));
  }

  function contractExists(address _contractAddress)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked(&quot;contract&quot;, _contractAddress)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                Permissions Information
  //-----------------------------------------------------------------------------------------------------------------------
  function userAccess(address _user)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;userAccess&quot;, _user)));
  }

  function isOwner(address _user)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked(&quot;owner&quot;, _user)));
  }

  function getFunctionAuthorizationHash(address _contractAddress, address _signer, string _functionName, bytes32 _agreedParameter)
  public
  pure
  returns (bytes32) {
    return keccak256(abi.encodePacked(_contractAddress, _signer, _functionName, _agreedParameter));
  }

  function isFunctionAuthorized(bytes32 _functionAuthorizationHash)
  public
  view
  returns (bool) {
    return database.boolStorage(_functionAuthorizationHash);
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                  Platform Costs
  //-----------------------------------------------------------------------------------------------------------------------


  // USD cost of different levels of access on the platform (1 = create/fund assets, 2 = staking/TBA, 3 = marketplace)
  function accessTokenFee(uint _accessLevelDesired)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;accessTokenFee&quot;, _accessLevelDesired)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                  Asset Revenue Information
  //-----------------------------------------------------------------------------------------------------------------------

  // Total amount of income earned by the asset
  function assetIncome(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;assetIncome&quot;, _assetID)));
  }

  // Deprecated after Intimate Alpha (0.1): Moving to &#39;assetIncome&#39; for Open-Alpha (0.2)
  function totalReceived(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;assetIncome&quot;, _assetID)));
  }

  // Amount of income paid to funders
  function totalPaidToFunders(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;totalPaidToFunders&quot;, _assetID)));
  }

  // Amount of income already paid to the funder
  function totalPaidToFunder(bytes32 _assetID, address _funder)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;totalPaidToFunder&quot;, _assetID, _funder)));
  }

  /* // Deprecated after Intimate Alpha (0.1): totalReceived == assetIncome for Open-Alpha (0.2)
  function getAmountOwed(bytes32 _assetID, address _user)
  public
  view
  returns (uint){
    if (ownershipUnits(_assetID, _user) == 0) { return 0; }
    return ((totalReceived(_assetID) * ownershipUnits(_assetID, _user)) / amountRaised(_assetID)) - totalPaidToFunder(_assetID, _user);
  } */

  // Returns the amount of WEI owed to asset owner  AmountOwed = (userIncome - userIncomeAlreadyPaid)
  function getAmountOwed(bytes32 _assetID, address _user)
  public
  view
  returns (uint){
    if (ownershipUnits(_assetID, _user) == 0) { return 0; }
    return ((assetIncome(_assetID) * ownershipUnits(_assetID, _user)) / amountRaised(_assetID)) - totalPaidToFunder(_assetID, _user);
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                             Funding Information
  //-----------------------------------------------------------------------------------------------------------------------
  function ownershipUnits(bytes32 _assetID, address _user)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;ownershipUnits&quot;, _assetID, _user)));
  }

  function amountRaised(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;amountRaised&quot;, _assetID)));
  }

  function fundingStage(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;fundingStage&quot;, _assetID)));
  }

  function amountToBeRaised(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;amountToBeRaised&quot;, _assetID)));
  }

  function fundingDeadline(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;fundingDeadline&quot;, _assetID)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                AssetManager and Escrow
  //-----------------------------------------------------------------------------------------------------------------------

  // Indicates which address is in charge of operating this asset. 1 manager per asset
  function assetManager(bytes32 _assetID)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked(&quot;assetManager&quot;, _assetID)));
  }

  // Percentage of income sent to asset manager
  function managerPercentage(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;managerPercentage&quot;, _assetID)));
  }

    // Percentage of income sent to asset manager
  function managerIncome(address _manager)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;managerIncome&quot;, _manager)));
  }

  // Amount of MYB locked for this asset
  function escrowedForAsset(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;escrowedForAsset&quot;, _assetID)));
  }

  // Total amount of MYB locked by user for all platform assets
  function escrowedMYB(address _manager)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;escrowedMYB&quot;, _manager)));
  }

  // Total amount of MYB deposited in the token escrow contract
  // NOTE: This MYB is not locked and can be withdrawn at any time
  function depositedMYB(address _manager)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;depositedMYB&quot;, _manager)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                          Staking Information
  //-----------------------------------------------------------------------------------------------------------------------


  // Returns address of staker covering the escrow for this asset
  function assetStaker(bytes32 _assetID)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked(&quot;assetStaker&quot;, _assetID)));
  }

  // Amount of MYB locked for this asset   (Deprecated: variable now stored as &quot;escrowedForAsset&quot; for release 0.2)
  function lockedForAsset(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;escrowedForAsset&quot;, _assetID)));
  }

  // Time when the request for
  function escrowExpiration(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;escrowExpiration&quot;, _assetID)));
  }

  // Time when the request for
  function stakingExpiration(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;stakingExpiration&quot;, _assetID)));
  }

  function stakerIncomeShare(bytes32 _assetID)
  public 
  view 
  returns (uint) { 
    return database.uintStorage(keccak256(abi.encodePacked(&quot;stakerIncomeShare&quot;, _assetID))); 
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                 OracleHub
  //-----------------------------------------------------------------------------------------------------------------------

  function ethUSDPrice()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;ethUSDPrice&quot;)));
  }

  function mybUSDPrice()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;mybUSDPrice&quot;)));
  }

  // The unix-timestamp when ETH and MYB prices need to be updated
  function priceExpiration()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked(&quot;priceExpiration&quot;)));
  }

  // Returns time in seconds until price needs to be updated
  function priceTimeToExpiration()
  public
  view
  returns (uint) {
    uint expiration = database.uintStorage(keccak256(abi.encodePacked(&quot;priceExpiration&quot;)));
    if (now > expiration) return 0;
    return (expiration - now);
  }

  // The number of seconds each ETH & MYB price update is valid for (initialVariables.sol)
  function priceUpdateTimeline()
  public 
  view 
  returns (uint) { 
    return database.uintStorage(keccak256(abi.encodePacked(&quot;priceUpdateTimeline&quot;))); 
  }

function ()
public {
  revert();
}





}