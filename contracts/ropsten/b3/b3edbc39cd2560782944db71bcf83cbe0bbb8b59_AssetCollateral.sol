pragma solidity 0.4.24;

contract AssetCollateral{
  using SafeMath for uint;
  API api;
  MyBitToken myb;
  address public owner;
  mapping(bytes32 => uint) public totalEscrow;
  mapping(bytes32 => uint) public escrowWithdrawn;
  mapping(bytes32 => bool) public escrowBool;
  mapping(bytes32 => address) public assetManager;
  constructor(address _api, address _myb) public{
    owner = msg.sender;
    api = API(_api);
    myb = MyBitToken(_myb);
  }
  function lockEscrow(bytes32 _assetID, address _assetManager, uint _escrow)
  external
  returns (bool){
    require(msg.sender == owner);
    require(_escrow > 0);
    require(!escrowBool[keccak256(abi.encodePacked(_assetID, _assetManager))]);
    escrowBool[keccak256(abi.encodePacked(_assetID, _assetManager))] = true;
    assetManager[_assetID] = _assetManager;
    totalEscrow[_assetID] = _escrow;
  }
  function withdrawEscrow(bytes32 _assetID)
  external
  returns (bool) {
    require(assetManager[_assetID] == msg.sender);
    uint unlockAmount = unlockedEscrow(_assetID);
    require(unlockAmount > 0);
    escrowWithdrawn[_assetID] = escrowWithdrawn[_assetID].add(unlockAmount);
    require(myb.transfer(msg.sender, unlockAmount));
    return true;
  }
  function changeOwner(address _newOwner)
  external
  returns (bool){
      require(msg.sender == owner);
      owner = _newOwner;
      return true;
  }
  function withdrawMYB()
  external
  returns (bool){
      require(msg.sender == owner);
      require(myb.transfer(msg.sender, myb.balanceOf(address(this))));
      return true;
  }
  // function unlockedEscrow(bytes32 _assetID)
  // view
  // public
  // returns (uint){
  //   uint roi = api.assetIncome(_assetID).mul(100).div(api.amountRaised(_assetID));
  //   if (roi >= 100) { return totalEscrow[_assetID].sub(escrowWithdrawn[_assetID]); }
  //   if (roi >= 75) { return totalEscrow[_assetID].mul(75).div(100).sub(escrowWithdrawn[_assetID]); }
  //   uint roiCheckpoints = roi.div(25);
  //   if(roiCheckpoints > 4) return totalEscrow[_assetID].sub(escrowWithdrawn[_assetID]);
  //   if(roiCheckpoints <= 4 && roiCheckpoints > 0){
  //     uint quarterEscrow = totalEscrow[_assetID].div(4);
  //     uint unlockAmount = roiCheckpoints.mul(quarterEscrow).sub(escrowWithdrawn[_assetID]);
  //     return unlockAmount;
  //   }
  //   else{
  //     return 0;
  //   }
  // }
  function unlockedEscrow(bytes32 _assetID)
  view
  public
  returns (uint){
    uint roi = api.assetIncome(_assetID).mul(100).div(api.amountRaised(_assetID));
    if (roi >= 100) { return totalEscrow[_assetID].sub(escrowWithdrawn[_assetID]); }
    if (roi >= 75) { return totalEscrow[_assetID].mul(75).div(100).sub(escrowWithdrawn[_assetID]); }
    if (roi >= 50) { return totalEscrow[_assetID].mul(50).div(100).sub(escrowWithdrawn[_assetID]); }
    if (roi >= 25) { return totalEscrow[_assetID].mul(25).div(100).sub(escrowWithdrawn[_assetID]); }
    return 0;
  }
  function remainingEscrow(bytes32 _assetID)
  view
  public
  returns (uint){
    return totalEscrow[_assetID].sub(escrowWithdrawn[_assetID]);
  }
  function redeemedEscrow(bytes32 _assetID)
  view
  public
  returns (uint) {
    return escrowWithdrawn[_assetID];
  }
  function roiEscrow(bytes32 _assetID)
  view
  public
  returns (uint) {
    uint roi = api.assetIncome(_assetID).mul(100).div(api.amountRaised(_assetID));
    return totalEscrow[_assetID].getFractionalAmount(roi);
  }
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
    return database.addressStorage(keccak256(abi.encodePacked("MyBitFoundation")));
  }

  function InstallerEscrow()
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked("InstallerEscrow")));
  }

  function myBitFoundationPercentage()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("myBitFoundationPercentage")));
  }

  function installerPercentage()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("installerPercentage")));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                               Contract State
  //-----------------------------------------------------------------------------------------------------------------------
  function isPaused(address _contractAddress)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked("pause", _contractAddress)));
  }


  function deployFinished()
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked("deployFinished")));
  }

  function contractAddress(string _name)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked("contract", _name)));
  }

  function contractExists(address _contractAddress)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked("contract", _contractAddress)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                Permissions Information
  //-----------------------------------------------------------------------------------------------------------------------
  function userAccess(address _user)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("userAccess", _user)));
  }

  function isOwner(address _user)
  public
  view
  returns (bool) {
    return database.boolStorage(keccak256(abi.encodePacked("owner", _user)));
  }

  function getFunctionAuthorized(address _contractAddress, address _signer, string _functionName, bytes32 _agreedParameter)
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

  function accessCostMYB(uint _accessLevelDesired)
  public
  view
  returns (uint) {
    uint mybPrice = mybUSDPrice();
    uint accessPrice = accessTokenFee(_accessLevelDesired);
    return (accessPrice * 10**21) / mybPrice;           // Returns # of MYB required (last 18 integers are decimals....will be very large number)
  }

  // USD cost of different levels of access on the platform (1 = create/fund assets, 2 = staking/TBA, 3 = marketplace)
  function accessTokenFee(uint _accessLevelDesired)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("accessTokenFee", _accessLevelDesired)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                  Asset Revenue Information
  //-----------------------------------------------------------------------------------------------------------------------

  // Total amount of income earned by the asset
  function assetIncome(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("assetIncome", _assetID)));
  }

  // Deprecated after Intimate Alpha (0.1): Moving to &#39;assetIncome&#39; for Open-Alpha (0.2)
  function totalReceived(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("assetIncome", _assetID)));
  }

  // Amount of income paid to funders
  function totalPaidToFunders(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunders", _assetID)));
  }

  // Amount of income already paid to the funder
  function totalPaidToFunder(bytes32 _assetID, address _funder)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("totalPaidToFunder", _assetID, _funder)));
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
    return database.uintStorage(keccak256(abi.encodePacked("ownershipUnits", _assetID, _user)));
  }

  function amountRaised(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("amountRaised", _assetID)));
  }

  function fundingStage(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("fundingStage", _assetID)));
  }

  function amountToBeRaised(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("amountToBeRaised", _assetID)));
  }

  function fundingDeadline(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("fundingDeadline", _assetID)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                AssetManager and Escrow
  //-----------------------------------------------------------------------------------------------------------------------

  // Indicates which address is in charge of operating this asset. 1 operator per asset
  function assetManager(bytes32 _assetID)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked("assetManager", _assetID)));
  }

  // Percentage of income sent to asset operator
  function managerPercentage(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("managerPercentage", _assetID)));
  }

  function assetManagerIncome(address _manager)
  public
  view
  returns (uint) {
      return database.uintStorage(keccak256(abi.encodePacked("managerIncome", _manager))); 
  }

  // Amount of MYB locked for this asset
  function escrowedForAsset(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("escrowedForAsset", _assetID)));
  }

  // Total amount of MYB locked by user for all platform assets
  function escrowedMYB(address _manager)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("escrowedMYB", _manager)));
  }

  // Total amount of MYB deposited in the operator escrow contract
  // NOTE: This MYB is not locked and can be withdrawn at any time
  function depositedMYB(address _manager)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("depositedMYB", _manager)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                          Staking Information
  //-----------------------------------------------------------------------------------------------------------------------


  // Returns address of staker covering the escrow for this asset
  function assetStaker(bytes32 _assetID)
  public
  view
  returns (address) {
    return database.addressStorage(keccak256(abi.encodePacked("assetStaker", _assetID)));
  }

  // Amount of MYB locked for this asset   (Deprecated: variable now stored as "escrowedForAsset" for release 0.2)
  function lockedForAsset(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("escrowedForAsset", _assetID)));
  }

  // Time when the request for
  function escrowExpiration(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("escrowExpiration", _assetID)));
  }

  // Time when the request for
  function stakingExpiration(bytes32 _assetID)
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("stakingExpiration", _assetID)));
  }

  function stakerIncomeShare(bytes32 _assetID)
  public
  view
  returns (uint) {
    database.uintStorage(keccak256(abi.encodePacked("stakerIncomeShare", _assetID)));
  }

  //-----------------------------------------------------------------------------------------------------------------------
  //                                                 OracleHub
  //-----------------------------------------------------------------------------------------------------------------------

  function ethUSDPrice()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("ethUSDPrice")));
  }

  function mybUSDPrice()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("mybUSDPrice")));
  }

  function priceExpiration()
  public
  view
  returns (uint) {
    return database.uintStorage(keccak256(abi.encodePacked("priceExpiration")));
  }

  // Returns time in seconds until price needs to be updated
  function priceTimeToExpiration()
  public
  view
  returns (uint) {
    uint expiration = database.uintStorage(keccak256(abi.encodePacked("priceExpiration")));
    if (now > expiration) return 0;
    return (expiration - now);
  }


function ()
public {
  revert();
}





}

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


// ----------------------------------------------------------------------------
// Receive approval and then execute function
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
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