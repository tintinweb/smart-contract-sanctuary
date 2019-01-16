pragma solidity 0.4.24;

//------------------------------------------------------------------------------------------------------------------
// Asset contract manages all payments, withdrawls and trading of ownershipUnits for live assets
// All information about assets are stored in Database.sol.
//------------------------------------------------------------------------------------------------------------------
contract Asset {
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
  // Revenue produced by the asset will be sent here
  // Invariants: Requires Eth is sent with transaction | Asset must be "live" (stage 4)
  // @Param: The ID of the asset to send to
  // @Param: A note that can be left by the payee
  //------------------------------------------------------------------------------------------------------------------
  function receiveIncome(bytes32 _assetID, bytes32 _note)
  external
  payable
  requiresEther
  atStage(_assetID, uint(4))
  returns (bool)  {
    uint assetIncome = database.uintStorage(keccak256(abi.encodePacked("assetIncome", _assetID)));
    uint managerShare = msg.value.getFractionalAmount(database.uintStorage(keccak256(abi.encodePacked("managerPercentage", _assetID))));
    require(distributeStakingShare(_assetID, managerShare)); 
    database.setUint(keccak256(abi.encodePacked("assetIncome", _assetID)), assetIncome.add(msg.value.sub(managerShare)));
    emit LogIncomeReceived(msg.sender, msg.value, _assetID, _note);
    return true;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Revenue produced by the asset will be sent here
  // Invariants: Requires Eth is sent with transaction | Asset must be "live" (stage 4)
  // @Param: The ID of the asset earning income
  // @Param: The amount of WEI owed to the staker or manager
  //------------------------------------------------------------------------------------------------------------------
  function distributeStakingShare(bytes32 _assetID, uint _managerAmount)
  internal 
  returns (bool) { 
    address staker = database.addressStorage(keccak256(abi.encodePacked("assetStaker", _assetID))); 
    address manager = database.addressStorage(keccak256(abi.encodePacked("assetManager", _assetID))); 
    if (staker != address(0)){ 
      uint stakerShare = database.uintStorage(keccak256(abi.encodePacked("stakerIncomeShare", _assetID))); 
      uint stakerPortion = _managerAmount.mul(stakerShare).div(100); 
      assert (stakerPortion > 0); 
      assert (setManagerIncome(staker, stakerPortion)); 
      if (stakerPortion < _managerAmount){ assert (setManagerIncome(manager, _managerAmount.sub(stakerPortion)));  }
      return true;  
    }
    else { 
      assert (setManagerIncome(manager, _managerAmount)); 
      return true;
    }
  }

  //------------------------------------------------------------------------------------------------------------------
  // Revenue produced by the asset will be sent here
  // Invariants: Requires Eth is sent with transaction | Asset must be "live" (stage 4)
  // @Param: The ID of the asset earning income
  // @Param: The amount of WEI owed to the staker or manager
  //------------------------------------------------------------------------------------------------------------------
  function setManagerIncome(address _manager, uint _managerAmount)
  internal 
  returns (bool) { 
      uint managerOwed = database.uintStorage(keccak256(abi.encodePacked("managerIncome", _manager))); 
      database.setUint(keccak256(abi.encodePacked("managerIncome", _manager)), managerOwed.add(_managerAmount)); 
      return true;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Revenue produced by the asset will be sent here
  // @dev: Requires Eth is sent with transaction | Asset must be "live" (stage 4)
  // @param: bytes32: The ID of the asset 
  //------------------------------------------------------------------------------------------------------------------
  function withdrawManagerIncome(bytes32 _assetID)
  external
  atStage(_assetID, uint(4))
  returns (bool) { 
    uint owed = database.uintStorage(keccak256(abi.encodePacked("managerIncome", msg.sender))); 
    require(owed > 0); 
    database.setUint(keccak256(abi.encodePacked("managerIncome", msg.sender)), 0); 
    msg.sender.transfer(owed); 
  }

  //------------------------------------------------------------------------------------------------------------------
  // Asset funders can receive their share of the income here
  // Invariants: Asset must be live. Sender must have ownershipUnits in the asset. There must be income earned.
  // @Param: The assetID this funder is trying to withdraw from
  // @Param: Boolean, whether or not the user wants the withdraw to go to an external address
  //------------------------------------------------------------------------------------------------------------------
  function withdraw(bytes32 _assetID)
  external
  whenNotPaused
  returns (bool){
    uint ownershipUnits = database.uintStorage(keccak256(abi.encodePacked("ownershipUnits", _assetID, msg.sender)));
    require (ownershipUnits > uint(0));
    uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
    uint totalPaidToFunders = database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunders", _assetID)));
    uint totalPaidToFunder = database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunder", _assetID, msg.sender)));
    uint assetIncome = database.uintStorage(keccak256(abi.encodePacked("assetIncome", _assetID)));
    uint payment = (assetIncome.mul(ownershipUnits).div(amountRaised)).sub(totalPaidToFunder);
    assert (payment != uint(0));
    assert (totalPaidToFunders <= assetIncome);    // Don&#39;t let amount paid to funders exceed amount received
    database.setUint(keccak256(abi.encodePacked("totalPaidToFunder", _assetID, msg.sender)), totalPaidToFunder.add(payment));
    database.setUint(keccak256(abi.encodePacked("totalPaidToFunders", _assetID)), totalPaidToFunders.add(payment));
    msg.sender.transfer(payment);
    emit LogIncomeWithdrawl(msg.sender, payment);
    return true;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Asset funders can receive their share of the income here
  // Invariants: Asset must be live. Sender must have ownershipUnits in the asset. There must be income earned.
  // @Param: The assetID this funder is trying to withdraw from
  // @Param: Boolean, whether or not the user wants the withdraw to go to an external address
  //------------------------------------------------------------------------------------------------------------------
  function batchWithdraw(bytes32[] _assetIDs)
  external
  whenNotPaused
  returns (bool){
    require(_assetIDs.length < 5); 
    uint payment = 0; 
    for (uint i = 0; i < _assetIDs.length; i++){
      bytes32 assetID = _assetIDs[i];
      uint ownershipUnits = database.uintStorage(keccak256(abi.encodePacked("ownershipUnits", assetID, msg.sender)));
      require (ownershipUnits > uint(0));
      uint amountRaised = database.uintStorage(keccak256(abi.encodePacked("amountRaised", assetID)));
      uint totalPaidToFunders = database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunders", assetID)));
      uint totalPaidToFunder = database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunder", assetID, msg.sender)));
      uint assetIncome = database.uintStorage(keccak256(abi.encodePacked("assetIncome", assetID)));
      uint thisPayment = (assetIncome.mul(ownershipUnits).div(amountRaised)).sub(totalPaidToFunder);
      assert (thisPayment != uint(0));
      assert (totalPaidToFunders <= assetIncome);    // Don&#39;t let amount paid to funders exceed amount received
      database.setUint(keccak256(abi.encodePacked("totalPaidToFunder", assetID, msg.sender)), totalPaidToFunder.add(thisPayment));
      database.setUint(keccak256(abi.encodePacked("totalPaidToFunders", assetID)), totalPaidToFunders.add(thisPayment));
      payment = payment.add(thisPayment); 
    }
    msg.sender.transfer(payment);
    emit LogIncomeWithdrawl(msg.sender, payment);
    return true;
  }


  //------------------------------------------------------------------------------------------------------------------
  // Must be authorized by 1 of the 3 owners and then can be called by any of the other 2
  // @Param: The address of the owner who authorized this function to be called in
  // Invariants: Must be 1 of 3 owners. Cannot be called by same owner who authorized the function to be called.
  //------------------------------------------------------------------------------------------------------------------
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
  // Checks that the asset is at the proper funding stage
  //------------------------------------------------------------------------------------------------------------------
  modifier atStage(bytes32 _assetID, uint _stage) {
    require(database.uintStorage(keccak256(abi.encodePacked("fundingStage", _assetID))) == _stage);
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Checks that the user has reached a high enough access level
  //------------------------------------------------------------------------------------------------------------------
  modifier onlyApproved(uint8 _accessLevel) {
    require(database.uintStorage(keccak256(abi.encodePacked("userAccess", msg.sender))) >= _accessLevel);
    require(database.uintStorage(keccak256(abi.encodePacked("userAccessExpiration", msg.sender))) > now);
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Makes sure function won&#39;t run when contract has been paused
  //------------------------------------------------------------------------------------------------------------------
  modifier whenNotPaused {
    require(!database.boolStorage(keccak256(abi.encodePacked("pause", this))));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Throw if Ether hasn&#39;t been sent
  //------------------------------------------------------------------------------------------------------------------
  modifier requiresEther() {
    require(msg.value > 0);
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Verify that the sender is a registered owner
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Fallback
  //------------------------------------------------------------------------------------------------------------------
  function ()
  public {
    revert();
  }

  //------------------------------------------------------------------------------------------------------------------
  //------------------------------------------------------------------------------------------------------------------
  //                                     Events
  //------------------------------------------------------------------------------------------------------------------
  //------------------------------------------------------------------------------------------------------------------

  event LogDestruction(address indexed _locationSent, uint indexed _amountSent, address indexed _caller);
  event LogIncomeReceived(address _sender, uint indexed _amount, bytes32 indexed _assetID, bytes32 _note);
  event LogIncomeWithdrawl(address _funder, uint _amount);
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