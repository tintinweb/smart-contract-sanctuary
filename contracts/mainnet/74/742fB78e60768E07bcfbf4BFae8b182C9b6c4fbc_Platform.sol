pragma solidity ^0.4.24;

// @author Roy Xu @dev-xu
// @title A shared storage contract for platform contracts to store and retrieve data
// @notice This contract holds all long-term data for smart-contract systems
// @dev The bytes32 hashes are derived from keccak256(variableName, uniqueID) => value
// @dec Can enable upgradeable contracts by setting a contract manager
contract Database {

    // Storage Variables
    mapping(bytes32 => uint) public uintStorage;
    mapping(bytes32 => string) public stringStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
    mapping(bytes32 => bytes32) public bytes32Storage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => int) public intStorage;



    // @notice Constructor: Sets the owners of the platform
    // @dev Owners must set the contract manager to add more contracts
    constructor(address[] _owners, bool _upgradeable)
    public {
      for(uint i=0; i<_owners.length; i++){
        require(_owners[i] != address(0), "Empty address");
        boolStorage[keccak256(abi.encodePacked("owner", _owners[i]))] = true;
        emit LogInitialized(_owners[i], _upgradeable);
      }
      if (_upgradeable){
        boolStorage[keccak256("upgradeable")] = true;
      }
    }

    // @notice ContractManager will be the only contract that can add/remove contracts on the platform.
    // @param (address) _contractManager is the contract which can upgrade/remove contracts to platform
    function enableContractManagement(address _contractManager)
    external
    returns (bool){
        require(_contractManager != address(0), "Empty address");
        require(boolStorage[keccak256(abi.encodePacked("owner", msg.sender))], "Not owner");
        require(addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] == address(0), "There is already a contract manager");
        addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] = _contractManager;
        boolStorage[keccak256(abi.encodePacked("contract", _contractManager))] = true;
        return true;
    }

    // @notice Storage functions
    function setAddress(bytes32 _key, address _value)
    onlyApprovedContract
    external {
        addressStorage[_key] = _value;
    }

    function setUint(bytes32 _key, uint _value)
    onlyApprovedContract
    external {
        uintStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value)
    onlyApprovedContract
    external {
        stringStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value)
    onlyApprovedContract
    external {
        bytesStorage[_key] = _value;
    }

    function setBytes32(bytes32 _key, bytes32 _value)
    onlyApprovedContract
    external {
        bytes32Storage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value)
    onlyApprovedContract
    external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value)
    onlyApprovedContract
    external {
        intStorage[_key] = _value;
    }


    // Deletion functions: Can alternatively use setter functions and set to null value (ie. uint = 0)
    function deleteAddress(bytes32 _key)
    onlyApprovedContract
    external {
        delete addressStorage[_key];
    }

    function deleteUint(bytes32 _key)
    onlyApprovedContract
    external {
        delete uintStorage[_key];
    }

    function deleteString(bytes32 _key)
    onlyApprovedContract
    external {
        delete stringStorage[_key];
    }

    function deleteBytes(bytes32 _key)
    onlyApprovedContract
    external {
        delete bytesStorage[_key];
    }

    function deleteBytes32(bytes32 _key)
    onlyApprovedContract
    external {
        delete bytes32Storage[_key];
    }

    function deleteBool(bytes32 _key)
    onlyApprovedContract
    external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key)
    onlyApprovedContract
    external {
        delete intStorage[_key];
    }


    // --------------------------------------------------------------------------------------
    //                                     Modifiers
    // --------------------------------------------------------------------------------------

    // Caller must be registered as a contract through ContractManager.sol
    modifier onlyApprovedContract() {
        require(boolStorage[keccak256(abi.encodePacked("contract", msg.sender))]);
        _;
    }

    // --------------------------------------------------------------------------------------
    //                                     Events
    // --------------------------------------------------------------------------------------
    event LogInitialized(address _owner, bool _upgradeable);
}

// Database interface
interface DBInterface {

  function setContractManager(address _contractManager)
  external;

    // --------------------Set Functions------------------------

    function setAddress(bytes32 _key, address _value)
    external;

    function setUint(bytes32 _key, uint _value)
    external;

    function setString(bytes32 _key, string _value)
    external;

    function setBytes(bytes32 _key, bytes _value)
    external;

    function setBytes32(bytes32 _key, bytes32 _value)
    external;

    function setBool(bytes32 _key, bool _value)
    external;

    function setInt(bytes32 _key, int _value)
    external;


     // -------------- Deletion Functions ------------------

    function deleteAddress(bytes32 _key)
    external;

    function deleteUint(bytes32 _key)
    external;

    function deleteString(bytes32 _key)
    external;

    function deleteBytes(bytes32 _key)
    external;

    function deleteBytes32(bytes32 _key)
    external;

    function deleteBool(bytes32 _key)
    external;

    function deleteInt(bytes32 _key)
    external;

    // ----------------Variable Getters---------------------

    function uintStorage(bytes32 _key)
    external
    view
    returns (uint);

    function stringStorage(bytes32 _key)
    external
    view
    returns (string);

    function addressStorage(bytes32 _key)
    external
    view
    returns (address);

    function bytesStorage(bytes32 _key)
    external
    view
    returns (bytes);

    function bytes32Storage(bytes32 _key)
    external
    view
    returns (bytes32);

    function boolStorage(bytes32 _key)
    external
    view
    returns (bool);

    function intStorage(bytes32 _key)
    external
    view
    returns (bool);
}

contract Events {
  DBInterface public database;

  constructor(address _database) public{
    database = DBInterface(_database);
  }

  function message(string _message)
  external
  onlyApprovedContract {
      emit LogEvent(_message, keccak256(abi.encodePacked(_message)), tx.origin);
  }

  function transaction(string _message, address _from, address _to, uint _amount, address _token)
  external
  onlyApprovedContract {
      emit LogTransaction(_message, keccak256(abi.encodePacked(_message)), _from, _to, _amount, _token, tx.origin);
  }

  function registration(string _message, address _account)
  external
  onlyApprovedContract {
      emit LogAddress(_message, keccak256(abi.encodePacked(_message)), _account, tx.origin);
  }

  function contractChange(string _message, address _account, string _name)
  external
  onlyApprovedContract {
      emit LogContractChange(_message, keccak256(abi.encodePacked(_message)), _account, _name, tx.origin);
  }

  function asset(string _message, string _uri, address _assetAddress, address _manager)
  external
  onlyApprovedContract {
      emit LogAsset(_message, keccak256(abi.encodePacked(_message)), _uri, keccak256(abi.encodePacked(_uri)), _assetAddress, _manager, tx.origin);
  }

  function escrow(string _message, address _assetAddress, bytes32 _escrowID, address _manager, uint _amount)
  external
  onlyApprovedContract {
      emit LogEscrow(_message, keccak256(abi.encodePacked(_message)), _assetAddress, _escrowID, _manager, _amount, tx.origin);
  }

  function order(string _message, bytes32 _orderID, uint _amount, uint _price)
  external
  onlyApprovedContract {
      emit LogOrder(_message, keccak256(abi.encodePacked(_message)), _orderID, _amount, _price, tx.origin);
  }

  function exchange(string _message, bytes32 _orderID, address _assetAddress, address _account)
  external
  onlyApprovedContract {
      emit LogExchange(_message, keccak256(abi.encodePacked(_message)), _orderID, _assetAddress, _account, tx.origin);
  }

  function operator(string _message, bytes32 _id, string _name, string _ipfs, address _account)
  external
  onlyApprovedContract {
      emit LogOperator(_message, keccak256(abi.encodePacked(_message)), _id, _name, _ipfs, _account, tx.origin);
  }

  function consensus(string _message, bytes32 _executionID, bytes32 _votesID, uint _votes, uint _tokens, uint _quorum)
  external
  onlyApprovedContract {
    emit LogConsensus(_message, keccak256(abi.encodePacked(_message)), _executionID, _votesID, _votes, _tokens, _quorum, tx.origin);
  }

  //Generalized events
  event LogEvent(string message, bytes32 indexed messageID, address indexed origin);
  event LogTransaction(string message, bytes32 indexed messageID, address indexed from, address indexed to, uint amount, address token, address origin); //amount and token will be empty on some events
  event LogAddress(string message, bytes32 indexed messageID, address indexed account, address indexed origin);
  event LogContractChange(string message, bytes32 indexed messageID, address indexed account, string name, address indexed origin);
  event LogAsset(string message, bytes32 indexed messageID, string uri, bytes32 indexed assetID, address asset, address manager, address indexed origin);
  event LogEscrow(string message, bytes32 indexed messageID, address asset, bytes32  escrowID, address indexed manager, uint amount, address indexed origin);
  event LogOrder(string message, bytes32 indexed messageID, bytes32 indexed orderID, uint amount, uint price, address indexed origin);
  event LogExchange(string message, bytes32 indexed messageID, bytes32 orderID, address indexed asset, address account, address indexed origin);
  event LogOperator(string message, bytes32 indexed messageID, bytes32 id, string name, string ipfs, address indexed account, address indexed origin);
  event LogConsensus(string message, bytes32 indexed messageID, bytes32 executionID, bytes32 votesID, uint votes, uint tokens, uint quorum, address indexed origin);


  // --------------------------------------------------------------------------------------
  // Caller must be registered as a contract through ContractManager.sol
  // --------------------------------------------------------------------------------------
  modifier onlyApprovedContract() {
      require(database.boolStorage(keccak256(abi.encodePacked("contract", msg.sender))));
      _;
  }

}

contract Platform {

  Database public database;
  Events public events;

  // @notice initialize database
  constructor(address _database, address _events)
  public {
    database = Database(_database);
    events = Events(_events);
  }

  // @notice The wallet to receive payments here before initiating crowdsale
  // @dev will overwrite old wallet address
  function setPlatformFundsWallet(address _walletAddress)
  external
  onlyOwner {
    database.setAddress(keccak256(abi.encodePacked("platform.wallet.funds")), _walletAddress);
    //emit LogPlatformWallet(_walletAddress);
    events.registration('Platform funds wallet', _walletAddress);
  }

  // @notice The wallet to receive asset tokens here before initiating crowdsale
  // @dev will overwrite old wallet address
  function setPlatformAssetsWallet(address _walletAddress)
  external
  onlyOwner {
    database.setAddress(keccak256(abi.encodePacked("platform.wallet.assets")), _walletAddress);
    //emit LogPlatformWallet(_walletAddress);
    events.registration('Platform assets wallet', _walletAddress);
  }

  // @notice The token that the platform uses for holding collateral
  function setPlatformToken(address _tokenAddress)
  external
  onlyOwner {
    //@dev Set the address for the platform token
    database.setAddress(keccak256(abi.encodePacked("platform.token")), _tokenAddress);
    events.registration('Platform token', _tokenAddress);
  }

  // @notice The percentage of the payment that the platform receives when investors contribute
  function setPlatformFee(uint _percent)
  external
  onlyOwner {
    database.setUint(keccak256(abi.encodePacked("platform.fee")), _percent);
  }

  // @notice Set the token address for the platform listing fee
  function setPlatformListingFeeToken(address _tokenAddress)
  external
  onlyOwner {
    //@dev Set the token address for the platform listing fee
    database.setAddress(keccak256(abi.encodePacked("platform.listingFeeToken")), _tokenAddress);
    events.registration('Platform listing fee token', _tokenAddress);
  }

  // @notice The amount of DAI the platform receives when an asset is listed
  function setPlatformListingFee(uint _amount)
  external
  onlyOwner {
    database.setUint(keccak256(abi.encodePacked("platform.listingFee")), _amount);
  }

  // @notice The percentage of the asset tokens the platform receives from the crowdsale
  function setPlatformPercentage(uint _percent)
  external
  onlyOwner {
    database.setUint(keccak256(abi.encodePacked("platform.percentage")), _percent);
  }

  // @notice Set the address of the token factory that clones the asset tokens
  function setTokenFactory(address _factory)
  external
  onlyOwner {
    database.setAddress(keccak256(abi.encodePacked("platform.tokenFactory")), _factory);
  }

  /*
  function setBurnrate(uint _percent)
  external
  onlyOwner {
    require(_percent < 100 && _percent >= 0);
    database.setUint(keccak256(abi.encodePacked("platform.burnRate")), _percent);
  }
  */

  // @notice platform owners can destroy contract here
  function destroy()
  onlyOwner
  external {
    events.transaction('PlatformFunds destroyed', address(this), msg.sender, address(this).balance, address(0));
    selfdestruct(msg.sender);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //                                                Modifiers                                                                     //
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // @notice Sender must be a registered owner
  modifier onlyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }






}