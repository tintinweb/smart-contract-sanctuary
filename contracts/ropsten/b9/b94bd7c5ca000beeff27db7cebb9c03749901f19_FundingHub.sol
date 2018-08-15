pragma solidity 0.4.24;

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

  //------------------------------------------------------------------------------------------------------------------
  // This contract is where users can fund assets or receive refunds from failed funding periods. Funding stages are represented by uints.
  // Funding stages: 0: funding hasn&#39;t started, 1: currently being funded, 2: funding failed,  3: funding success, 4: asset is live
  //------------------------------------------------------------------------------------------------------------------
  contract FundingHub {
    using SafeMath for *;

    Database public database;

    bool private rentrancy_lock;    // Prevents re-entrancy attack

    //------------------------------------------------------------------------------------------------------------------
    // Contructor:
    // @Param: The address for the MyBit database
    //------------------------------------------------------------------------------------------------------------------
    constructor(address _database)
    public {
        database = Database(_database);
    }

    //------------------------------------------------------------------------------------------------------------------
    // Users can send Ether here to fund asset if funding goal hasn&#39;t been reached and the funding period isn&#39;t over.
    // Invariants: Requires Eth be sent with transaction |  Must be in funding stage. Must be under goal | Must have KYC approved. | contract is not paused
    //------------------------------------------------------------------------------------------------------------------
    function fund(bytes32 _assetID)
    external
    payable
    requiresEther
    whenNotPaused
    atStage(_assetID, uint(1))
    priceUpdated
    fundingLimit(_assetID)
    // onlyApproved   TODO: uncomment when inner-alpha done
    returns (bool) {
      uint ownershipUnits = database.uintStorage(keccak256(abi.encodePacked("ownershipUnits", _assetID, msg.sender)));
      if (ownershipUnits == 0) {
        emit LogNewFunder(_assetID, msg.sender);    // Create event to reference list of funders
      }
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
      database.setUint(keccak256(abi.encodePacked("amountRaised", _assetID)), amountRaised.add(msg.value));
      database.setUint(keccak256(abi.encodePacked("ownershipUnits", _assetID, msg.sender)), ownershipUnits.add(msg.value));
      emit LogAssetFunded(_assetID, msg.sender, msg.value);
      return true;
    }

    //------------------------------------------------------------------------------------------------------------------
    // This is called once funding has succeeded. Sends Ether to installer, foundation and Token Holders
    // Invariants: Must be in stage FundingSuccess | MyBitFoundation + AssetEscrow  + BugEscrow addresses are set | Contract is not paused
    // Note: Will fail if addresses + percentages are not set. AmountRaised = WeiRaised = ownershipUnits
    // TODO: Installer gets extra 1-2 wei from solidity rounding down when faced with fraction
    // TODO: Create asset tokens here
    //------------------------------------------------------------------------------------------------------------------
    function payout(bytes32 _assetID)
    external
    nonReentrant
    whenNotPaused
    atStage(_assetID, uint(3))       // Can only get to stage 3 by receiving enough funding within time limit
    returns (bool) {
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
      uint myBitAmount = amountRaised.getFractionalAmount(database.uintStorage(keccak256(abi.encodePacked("myBitFoundationPercentage"))));
      uint installerAmount = amountRaised.sub(myBitAmount);
      database.addressStorage(keccak256(abi.encodePacked("MyBitFoundation"))).transfer(myBitAmount);             // Must be normal account
      database.addressStorage(keccak256(abi.encodePacked("InstallerEscrow"))).transfer(installerAmount);             // Must be normal account
      database.setUint(keccak256(abi.encodePacked("fundingStage", _assetID)), uint(4));
      emit LogAssetPayout(_assetID, amountRaised);
      return true;
    }

    //------------------------------------------------------------------------------------------------------------------
    // This function needs to be called to allow refunds to be made. Signals to the myBitHub contract that funding has failed + moves stage to Funding failed
    // Invariants: Must be still be in funding stage | must be passed deadline
    //------------------------------------------------------------------------------------------------------------------
    function initiateRefund(bytes32 _assetID)
    external
    fundingPeriodOver(_assetID)
    atStage(_assetID, uint(1))
    returns (bool) {
      database.setUint(keccak256(abi.encodePacked("fundingStage", _assetID)), uint(2));
      emit LogAssetFundingFailed(_assetID, database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID))));
      return true;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Contributors can retrieve their funds here if campaign is finished + failure and initateRefund() has been called.
    // Invariants: sender must have ownershipUnits | Must be in failed funding stage || No re-entry | Contract must not be paused
    //------------------------------------------------------------------------------------------------------------------
    function refund(bytes32 _assetID)
    external
    nonReentrant
    whenNotPaused
    atStage(_assetID, uint(2))
    returns (bool) {
      uint ownershipUnits = database.uintStorage(keccak256(abi.encodePacked("ownershipUnits", _assetID, msg.sender)));
      require (ownershipUnits > uint(0));
      database.deleteUint(keccak256(abi.encodePacked("ownershipUnits", _assetID, msg.sender)));
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
      database.setUint(keccak256(abi.encodePacked("amountRaised", _assetID)), amountRaised.sub(ownershipUnits));
      msg.sender.transfer(ownershipUnits);
      emit LogRefund(_assetID, msg.sender, ownershipUnits);
      return true;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Must be authorized by 1 of the 3 owners and then can be called by any of the other 2
    // Invariants: Must be 1 of 3 owners. Cannot be called by same owner who authorized the function to be called.
    //------------------------------------------------------------------------------------------------------------------
    function destroy(address _functionInitiator, address _holdingAddress)
    anyOwner
    public {
      require(_functionInitiator != msg.sender);
      require(database.boolStorage(keccak256(abi.encodePacked(address(this), _functionInitiator, "destroy", keccak256(abi.encodePacked(_holdingAddress))))));
      emit LogDestruction(_holdingAddress, address(this).balance, msg.sender);
      selfdestruct(_holdingAddress);
    }


    //------------------------------------------------------------------------------------------------------------------
    //                                            Modifiers
    //------------------------------------------------------------------------------------------------------------------

    //------------------------------------------------------------------------------------------------------------------
    // Requires caller is one of the three owners
    //------------------------------------------------------------------------------------------------------------------
    modifier anyOwner {
      require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Requires that the contract is not paused
    //------------------------------------------------------------------------------------------------------------------
    modifier whenNotPaused {
      require(!database.boolStorage(keccak256(abi.encodePacked("pause", address(this)))));
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Don&#39;t let function caller re-enter function before initial transaction finishes
    //------------------------------------------------------------------------------------------------------------------
    modifier nonReentrant() {
      require(!rentrancy_lock);
      rentrancy_lock = true;
      _;
      rentrancy_lock = false;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Requires that Ether is sent with the transaction
    //------------------------------------------------------------------------------------------------------------------
    modifier requiresEther() {
      require(msg.value > 0);
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Requires user has burnt tokens to access this function
    //------------------------------------------------------------------------------------------------------------------
    modifier onlyApproved{
      require(database.uintStorage(keccak256(abi.encodePacked("userAccess", msg.sender))) >= uint(1));
      require(database.uintStorage(keccak256(abi.encodePacked("userAccessExpiration", msg.sender))) > now);
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Transitions funding period to success if enough Ether is raised
    // Must be in funding stage 3 (currently being funded).
    // Deletes funding raising variables if current transaction puts it over the goal.
    // TODO: Limit how far over the goal users are allowed to fund?
    //------------------------------------------------------------------------------------------------------------------
    modifier fundingLimit(bytes32 _assetID) {
      require(now <= database.uintStorage(keccak256(abi.encodePacked("fundingDeadline", _assetID))));
      uint currentEthPrice = database.uintStorage(keccak256(abi.encodePacked("ethUSDPrice")));
      assert (currentEthPrice > uint(0));
      _;
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID))); 
      if (amountRaised.mul(currentEthPrice).div(1e18) >= database.uintStorage(keccak256(abi.encodePacked("amountToBeRaised", _assetID)))) {
         database.setUint(keccak256(abi.encodePacked("fundingStage", _assetID)), uint(3));
         emit LogAssetFundingSuccess(_assetID, currentEthPrice, amountRaised);
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // Check that the Ether/USD prices have been updated
    //------------------------------------------------------------------------------------------------------------------
    modifier priceUpdated {
      require (now < database.uintStorage(keccak256(abi.encodePacked("priceExpiration"))));
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Requires the funding stage is at a particular stage
    //------------------------------------------------------------------------------------------------------------------
    modifier atStage(bytes32 _assetID, uint _stage) {
      require(database.uintStorage(keccak256(abi.encodePacked("fundingStage", _assetID))) == _stage);
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Requires that the funding deadline has passed
    //------------------------------------------------------------------------------------------------------------------
    modifier fundingPeriodOver(bytes32 _assetID) {
      require(now >= database.uintStorage(keccak256(abi.encodePacked("fundingDeadline", _assetID))));
      _;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Fallback: Reject Ether
    //------------------------------------------------------------------------------------------------------------------
    function ()
    public {
      revert();
    }


    //------------------------------------------------------------------------------------------------------------------
    //                                            Events
    //------------------------------------------------------------------------------------------------------------------

    event LogNewFunder(bytes32 indexed _assetID, address indexed _funder);
    event LogAssetFunded(bytes32 indexed _assetID, address indexed _sender, uint _amount);
    event LogAssetFundingFailed(bytes32 indexed _assetID, uint _amountRaised);
    event LogAssetFundingSuccess(bytes32 indexed _assetID, uint _currentEthPrice, uint _amountRaised);
    event LogRefund(bytes32 indexed _assetID, address indexed _funder, uint _amount);
    event LogAssetPayout(bytes32 indexed _assetID, uint _amount);
    event LogDestruction(address indexed _locationSent, uint indexed _amountSent, address indexed _caller);
  }