pragma solidity 0.5.2; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
    
       
        .----------------.  .----------------.  .----------------. 
    | .--------------. || .--------------. || .--------------. |
    | |    _______   | || |      __      | || | ____    ____ | |
    | |   /  ___  |  | || |     /  \     | || ||_   \  /   _|| |
    | |  |  (__ \_|  | || |    / /\ \    | || |  |   \/   |  | |
    | |   &#39;.___`-.   | || |   / ____ \   | || |  | |\  /| |  | |
    | |  |`\____) |  | || | _/ /    \ \_ | || | _| |_\/_| |_ | |
    | |  |_______.&#39;  | || ||____|  |____|| || ||_____||_____|| |
    | |              | || |              | || |              | |
    | &#39;--------------&#39; || &#39;--------------&#39; || &#39;--------------&#39; |
     &#39;----------------&#39;  &#39;----------------&#39;  &#39;----------------&#39;  
       
   
// ======================= CORE FUNCTIONS ============================//

    &#39;Software Assent Management&#39; smart contract with following functions
        => Multi-ownership control
        => Higher degree of control by owner
        => Upgradeability using Unstructured Storage

// ========================= CORE LOGIC ==============================//
    
    (1) Four types of account management -
        (a) Software vendors/developers
        (b) businesses
        (c) employees
        (d) owner of the contract
    (2) Owner of the contract is supreme controller, who is highest authority to change
    addresses of all other types of accounts/wallets.
        (a) Process begins when owner of contract creates SW vendor account (which is
        just an ETH wallet address).
        (b) Then that authorised vendor can add/remove/update businesses account
        information (which again is ethereum wallet address) to whom licence is
        provided.
        (c) Businesses then can add/remove/update employees to view licence
        information.
    (3) Software vendor or developer will first submit licence information in smart contract.
    (4) Authorised employees of the company (business, vendor, owner) can look up for
    any licence information.
    (5) There will not events will be logged, because all the data is private to view for the Authorised bodies.


// Copyright (c) 2019 onwards Neocor AI Inc. ( https://neocor.ai )
// Contract designed by EtherAuthority ( https://EtherAuthority.io )
// Special thanks to openzeppelin for upgration inspiration: 
// https://github.com/zeppelinos/labs/tree/master/upgradeability_using_unstructured_storage
// =========================================================================================
*/ 



//*********************************************************************************//
//---------------------------- Contract to Manage Ownership -----------------------//
//*********************************************************************************//
//                                                                                 //
// Owner is set while deploying this contract as well as..                         //
// When this contract is used as implementation by the proxy contract              //
//                                                                                 //
//---------------------------------------------------------------------------------//
contract owned {
    
    /*==============================
    =       PUBLIC VARIABLES       =
    ==============================*/
    address public owner;
    

    /*==============================
    =           MODIFIERS          =
    ==============================*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    
    /*==============================
    =           FUNCTIONS          =
    ==============================*/
    /* constructor function to set ownership. While implementing this function in proxy, ownership need to set again. */
    constructor () public {
        owner = msg.sender;
    }
    
    /* function to transfer ownership to other address */
    function transferOwnership(address payable newOwner) onlyOwner public returns(bool) {
        owner = newOwner;
        return true;
    }
}
    
    
//********************************************************************************//
//----------------  SAM_v1 SMART CONTRACT - MAIN CODE STARTS HERE ----------------//
//********************************************************************************//
    
contract SAM_v1 is owned {
    
    
    /*===============================
    =         DATA STORAGE          =
    ===============================*/
    /* Struct holds all the software asset data */
    struct SoftwareAsset {
        uint256 saID;               // Unique numeric ID of software asset
        string vendorName;          // Vendor name, who issued the licence to business
        string businessName;        // Business Name to whome licence is issued
        address businessWallet;     // Wallet address of the business
        uint256 licenceIssueDate;   // Licence Issue Date
        uint256 licenceRenewDate;   // Licence Renew Date
        string licenceStatus;       // Current licence status. eg, Issued, Revoked, Blacklisted, etc.
    }
    
    /* Mapping holds SoftwareAsset data vendor => business => Unique saID => SoftwareAsset */
    mapping (address => mapping(address => mapping(uint256 => SoftwareAsset))) softwareAssetMapping;
    
    /* Mapping for vendor => bool */
    mapping (address => bool) vendorsMapping;
    
    /* Mapping for vendor => business => bool */
    mapping (address => mapping(address => bool)) businessesMapping;
    
    /* Mapping for business => employees => bool */
    mapping (address => mapping(address => bool)) employeesMapping;


    /* constructor function, which does not do really anything */
    constructor () public {}
    
    /* Fallback function is not necessary as incoming ether will be automatically rejected */
    //function () external {}


    /*===============================
    =         WRITE FUNCTIONS       =
    ===============================*/
    /**
     * @notice Function to add new vendor. This is called by only Owner
     * @param _vendorAddress Address of vendor
     * @return bool True for successful transaction otherwise false
     */
    function addNewVendor(address _vendorAddress) public onlyOwner returns(bool) {
        
        require(!vendorsMapping[_vendorAddress], &#39;Vendor is already added&#39;);
        require(_vendorAddress != address(0), &#39;Invalid vendor address&#39;);
        
        vendorsMapping[_vendorAddress] = true;
        return true;
    }
    
    /**
     * @notice Function to update any existing vendor. This is called by only Owner
     * @param _currentVendorAddress Current address of vendor, which owner want to update
     * @param _newVendorAddress New address of vendor
     * @return bool True for successful transaction otherwise false
     */
    function updateVendor(address _currentVendorAddress, address _newVendorAddress) public onlyOwner returns(bool){
        
        require(vendorsMapping[_currentVendorAddress], &#39;Vendor does not exist&#39;);
        require(_currentVendorAddress != address(0), &#39;Invalid vendor address&#39;);
        require(_newVendorAddress != address(0), &#39;Invalid vendor address&#39;);
        
        vendorsMapping[_currentVendorAddress] = false;
        vendorsMapping[_newVendorAddress] = true;
        
        return true;
    }
    
    /**
     * @notice Function to add new Business. This can be called by Vendor 
     * @param _businessAddress Address of business owner
     * @return bool True for successful transaction otherwise false
     */
    function addNewBusinessWallet(address _businessAddress) public returns(bool) {
        
        require(vendorsMapping[msg.sender], &#39;Caller is not authenticated&#39;);
        require(!businessesMapping[msg.sender][_businessAddress], &#39;Business is already added&#39;);
        require(_businessAddress != address(0), &#39;Invalid business address&#39;);
        
        businessesMapping[msg.sender][_businessAddress] = true;
        return true;
    }
    
    /**
     * @notice Function to update Business wallet. This can be called by Vendor
     * @param _currentBusinessAddress Current Address of business owner
     * @param _newBusinessAddress New Address of business owner, which needs to be updated
     * @return bool True for successful transaction otherwise false
     */
    function updateBusinessWallet(address _currentBusinessAddress, address _newBusinessAddress) public returns(bool) {
        
        require(vendorsMapping[msg.sender], &#39;Caller is not authenticated&#39;);
        require(businessesMapping[msg.sender][_currentBusinessAddress], &#39;Business does not exist&#39;);
        require(_currentBusinessAddress != address(0), &#39;Address is invalid&#39;);
        require(_newBusinessAddress != address(0), &#39;Address is invalid&#39;);
        
        businessesMapping[msg.sender][_currentBusinessAddress] = false;
        businessesMapping[msg.sender][_newBusinessAddress] = true;
        return true;
    }
    
    /**
     * @notice Function to add/update the software licence data. This function called only by vendor
     * @param saID_ software asset ID
     * @param vendorName_ Name of the vendor
     * @param businessName_ Name of the business
     * @param businessWallet_ Public wallet of the business
     * @param licenceIssueDate_ Date of licence issue in timestamp
     * @param licenceRenewDate_ Date of licence to renew in timestamp
     * @param status_ Status of the licence. It could be valid, pending, Blacklisted, etc.
     * @return bool It returns true for successful transaction else false
     */
    function addNewSoftwareData(uint256 saID_, string memory vendorName_, string memory businessName_, address businessWallet_, uint256 licenceIssueDate_, uint256 licenceRenewDate_, string memory status_) public returns(bool){
        
        require(vendorsMapping[msg.sender], &#39;Caller is not authenticated&#39;);
        require(saID_ != 0, &#39;Licence ID is invalid&#39;);
        
        //adding data to softwareAssetMapping
        softwareAssetMapping[msg.sender][businessWallet_][saID_].saID = saID_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].vendorName = vendorName_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].businessName = businessName_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].businessWallet = businessWallet_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].licenceIssueDate = licenceIssueDate_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].licenceRenewDate = licenceRenewDate_;
        softwareAssetMapping[msg.sender][businessWallet_][saID_].licenceStatus = status_;
        
        return true;
    }
    
    
    /**
     * @notice Function to add new employee. This can be called by business 
     * @param _vendorAddess Address of software vendor
     * @param _employeeAddress Address of employee who can access the software licence data
     * @return bool True for successful transaction otherwise false
     */
    function addNewEmployeeWallet(address _vendorAddess, address _employeeAddress) public returns(bool) {
        
        require(businessesMapping[_vendorAddess][msg.sender], &#39;Caller is not authenticated&#39;);
        require(!employeesMapping[msg.sender][_employeeAddress], &#39;Employee is already added&#39;);
        require(_employeeAddress != address(0), &#39;Invalid Employee address&#39;);
        
        employeesMapping[msg.sender][_employeeAddress] = true;
        return true;
    }
    
    
    /**
     * @notice Function to update existing employee wallet address. This can be called by business only
     * @param _vendorAddess Address of software vendor
     * @param _currentEmployeeAddress Address of existing employee, whose wallet address needs to be updated 
     * @param _newEmployeeAddress New Address of employee 
     * @return bool True for successful transaction otherwise false
     */
    function updateEmployeeWallet(address _vendorAddess, address _currentEmployeeAddress, address _newEmployeeAddress) public returns(bool) {
        
        require(businessesMapping[_vendorAddess][msg.sender], &#39;Caller is not authenticated&#39;);
        require(employeesMapping[msg.sender][_currentEmployeeAddress], &#39;Employee does not exist&#39;);
        require(_newEmployeeAddress != address(0), &#39;Invalid Employee address&#39;);
        
        employeesMapping[msg.sender][_currentEmployeeAddress] = false;
        employeesMapping[msg.sender][_newEmployeeAddress] = true;
        return true;
    }
    
    
    /*===============================
    =         READ FUNCTIONS        =
    ===============================*/
    
    /**
     * @notice This function is to request software related information
     * @notice This can be called by owner, vendor, business and employees and they receive their specific information if exist
     * @dev It first validates all the information requests. and once validated, it sends the information 
     * 
     * @param vendor Address of vendor
     * @param business Address if business
     * @param saID unique software asset ID
     * 
     * @return array of software information
     */
    function readSoftwareInformation(address vendor, address business, uint256 saID) public view returns(uint256, string memory, string memory, uint256, uint256, string memory) {

        // validates requester of the information
        require(
            msg.sender == owner || 
            vendorsMapping[msg.sender] || 
            businessesMapping[vendor][msg.sender] ||
            employeesMapping[business][msg.sender],
            &#39;Unauthenticated caller&#39;
        );
        
        // once caller is validated, then send the information
        return ( 
            softwareAssetMapping[vendor][business][saID].saID, 
            softwareAssetMapping[vendor][business][saID].vendorName, 
            softwareAssetMapping[vendor][business][saID].businessName, 
            softwareAssetMapping[vendor][business][saID].licenceIssueDate, 
            softwareAssetMapping[vendor][business][saID].licenceRenewDate, 
            softwareAssetMapping[vendor][business][saID].licenceStatus
        );
    }
    
    
    /*===============================
    =     UPGRADE CONTRACT CODE     =
    ===============================*/
    bool internal initialized;
    
    /**
     * @notice This is initialize function would be called only once while contract initialisation
     * @notice It will just set owner address
     */
    function initialize(
        address _owner
    ) public {
        
        require(!initialized);
        require(owner == address(0)); //When this methods called, then owner address must be zero

        owner = _owner;
        initialized = true;
    }
    
}


//********************************************************************************//
//----------------------  MAIN PROXY CONTRACTS SECTION STARTS --------------------//
//********************************************************************************//


/****************************************/
/*            Proxy Contract            */
/****************************************/
/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}


/****************************************/
/*    UpgradeabilityProxy Contract      */
/****************************************/
/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

  /**
   * @dev Constructor function
   */
  constructor () public {}

  /**
   * @dev Tells the address of the current implementation
   * @return address of the current implementation
   */
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}

/****************************************/
/*  OwnedUpgradeabilityProxy contract   */
/****************************************/
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor () public {
    setUpgradeabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
    _upgradeTo(implementation);
    (bool success,) = address(this).call.value(msg.value).gas(200000)(data);
    require(success);
  }
}


/****************************************/
/*        SAM PROXY Contract         */
/****************************************/

/**
 * @title SAM_proxy
 * @dev This contract proxies FiatToken calls and enables FiatToken upgrades
*/ 
contract SAM_proxy is OwnedUpgradeabilityProxy {
    constructor() public OwnedUpgradeabilityProxy() {
    }
}