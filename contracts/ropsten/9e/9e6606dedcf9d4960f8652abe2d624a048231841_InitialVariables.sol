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

//------------------------------------------------------------------------------------------
// This contract is involved in setting default variables.
// Must be deployed before platform can be run
//------------------------------------------------------------------------------------------
contract InitialVariables {
  using SafeMath for uint; 

Database public database;

//------------------------------------------------------------------------------------------
// Constructor: Initialize Database
//------------------------------------------------------------------------------------------
constructor(address _database)
public {
  database = Database(_database);
}
//------------------------------------------------------------------------------------------
// Initialized important variables
//------------------------------------------------------------------------------------------
function startDapp(address _myBitFoundation, address _installerEscrow)
external  {
  require(database.boolStorage(keccak256(abi.encodePacked(&quot;owner&quot;, msg.sender))));
  require(_myBitFoundation != address(0) && _installerEscrow != address(0));
  // --------------------Set Local Wallets-------------------------
  database.setAddress(keccak256(abi.encodePacked(&quot;MyBitFoundation&quot;)), _myBitFoundation);
  database.setAddress(keccak256(abi.encodePacked(&quot;InstallerEscrow&quot;)), _installerEscrow);
  // --------------------Asset Creation Variables-----------------
  database.setUint(keccak256(abi.encodePacked(&quot;myBitFoundationPercentage&quot;)), uint(1));
  database.setUint(keccak256(abi.encodePacked(&quot;installerPercentage&quot;)), uint(99));
  // ---------------------Access Price in USD--------------------------
  database.setUint(keccak256(abi.encodePacked(&quot;accessTokenFee&quot;, uint(1))), uint(25).mul(10**21));    // Add 18 decimals * 10^3 for MYB price 
  database.setUint(keccak256(abi.encodePacked(&quot;accessTokenFee&quot;, uint(2))), uint(75).mul(10**21));    // Add 18 decimals * 10^3 for MYB price 
  database.setUint(keccak256(abi.encodePacked(&quot;accessTokenFee&quot;, uint(3))), uint(100).mul(10**21));   // Add 18 decimals * 10^3 for MYB price 
  // -------------Oracle Variables-------------------------
  database.setUint(keccak256(abi.encodePacked(&quot;priceUpdateTimeline&quot;)), uint(86400));     // Market prices need to be updated every 24 hours
  emit LogInitialized(msg.sender, address(database));
}

// ------------------------------------------------------------------------------------------------
//  Change MyBitFoundation address
// ------------------------------------------------------------------------------------------------
function changeFoundationAddress(address _signer, string _functionName, address _newAddress)
external
noEmptyAddress(_newAddress)
anyOwner
multiSigRequired(_signer, _functionName, keccak256(abi.encodePacked(_newAddress))) 
returns (bool) {
  database.setAddress(keccak256(abi.encodePacked(&quot;MyBitFoundation&quot;)), _newAddress);
  return true; 
}

// ------------------------------------------------------------------------------------------------
//  Change InstallerEsrow address
// ------------------------------------------------------------------------------------------------
function changeInstallerEscrowAddress(address _signer, string _functionName, address _newAddress)
external
noEmptyAddress(_newAddress)
anyOwner
multiSigRequired(_signer, _functionName, keccak256(abi.encodePacked(_newAddress))) 
returns (bool) {
  database.setAddress(keccak256(abi.encodePacked(&quot;InstallerEscrow&quot;)), _newAddress);
  return true; 
}

// ------------------------------------------------------------------------------------------------
//  Change MyBitFoundation address
// ------------------------------------------------------------------------------------------------
function changeAccessTokenFee(address _signer, string _functionName, uint _accessLevel, uint _newPrice)
external
anyOwner 
multiSigRequired(_signer, _functionName, keccak256(abi.encodePacked(_accessLevel, _newPrice))) 
returns (bool) {
  database.setUint(keccak256(abi.encodePacked(&quot;accessTokenFee&quot;, _accessLevel)), _newPrice);
  return true;
}

// ------------------------------------------------------------------------------------------------
//  Set 24hr prices
// ------------------------------------------------------------------------------------------------
function setDailyPrices(uint _ethPrice, uint _mybPrice)
external 
anyOwner 
returns (bool) { 
    uint priceExpiration = database.uintStorage(keccak256(abi.encodePacked(&quot;priceUpdateTimeline&quot;))).add(now);
    emit LogPriceUpdate(database.uintStorage(keccak256(abi.encodePacked(&quot;ethUSDPrice&quot;))),database.uintStorage(keccak256(abi.encodePacked(&quot;mybUSDPrice&quot;)))); 
    database.setUint(keccak256(abi.encodePacked(&quot;ethUSDPrice&quot;)), _ethPrice);
    database.setUint(keccak256(abi.encodePacked(&quot;mybUSDPrice&quot;)), _mybPrice);
    database.setUint(keccak256(abi.encodePacked(&quot;priceExpiration&quot;)), priceExpiration);
    return true; 
}

function changePriceUpdateTimeline(uint _newPriceExpiration)
external
anyOwner
returns (bool) { 
    database.setUint(keccak256(abi.encodePacked(&quot;priceUpdateTimeline&quot;)), _newPriceExpiration);
    return true;

}


// ------------------------------------------------------------------------------------------------
//                                                Modifiers
// ------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------
//  Verify that sender is an owner
// ------------------------------------------------------------------------------------------------
modifier anyOwner {
  require(database.boolStorage(keccak256(abi.encodePacked(&quot;owner&quot;, msg.sender))));
  _;
}

// ------------------------------------------------------------------------------------------------
//  Verify address isn&#39;t null
// ------------------------------------------------------------------------------------------------
modifier noEmptyAddress(address _contract) {
  require(_contract != address(0));
  _;
}

// ------------------------------------------------------------------------------------------------
//  Verify that function has been signed off by another owner
// ------------------------------------------------------------------------------------------------
modifier multiSigRequired(address _signer, string _functionName, bytes32 _keyParam) {
  require(msg.sender != _signer);
  require(database.boolStorage(keccak256(abi.encodePacked(address(this), _signer, _functionName, _keyParam))));
  database.setBool(keccak256(abi.encodePacked(address(this), _signer, _functionName, _keyParam)), false);
  _;
}


//------------------------------------------------------------------------------------------
//                                  Events
//------------------------------------------------------------------------------------------
event LogInitialized(address _sender, address _database);
event LogPriceUpdate(uint _oldETHPrice, uint _oldMYBPrice); 

}