/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// File: contracts/proxy/Initializable.sol

pragma solidity ^0.6.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/GSN/ContextUpgradeable.sol

// SPDX-License-Identifier: MIT

contract IGETAccessControlUpgradeable {

    function hasRole(bytes32, address) public view returns (bool) {}

}
// pragma experimental ABIEncoderV2;

contract metadataLogicV2 is Initializable {

    IGETAccessControlUpgradeable public gAC;
    // address public deployer_address;

    // // Mappings for the ticketIsuer data storage
    // mapping(address => TicketIssuerStruct) public allTicketIssuerStructs;
    // address[] public ticketIssuerAddresses;

    // Mappings for the event data storage
    mapping(address => EventStruct) public allEventStructs;
    address[] public eventAddresses;  
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function __initialize_metadata(address _address_gAC) public initializer {
      gAC = IGETAccessControlUpgradeable(_address_gAC);
    }

    function setAccessControl(address _new_gAC) public {
      require(gAC.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "primaryMint: sender must have minter role to mint");
      gAC = IGETAccessControlUpgradeable(_new_gAC);
    }

    event newEventRegistered(address indexed eventAddress, string indexed eventName, uint256 indexed _timestamp);

    struct EventStruct {
        address event_address;
        string event_name;
        string shop_url;
        bytes32 latitude;
        bytes32 longitude;
        bytes32 currency;
        uint256 start_time;
        // uint256 grossRevenuePrimary;
        // uint256 grossRevenueSecondary;
        bytes32 ticketeer_name;
        bytes event_metadata;
        // uint256 listPointerE;
        // uint256 listPointerE;
    }
  
  // /** 
  // * @dev storage function metadata of a primary market trade (issuer 2 fan)
  // * @param eventAddress address of event controlling getNFT 
  // * @param nftIndex unique index of getNFT
  // * @param orderTimeP timestamp passed on by ticket issuer of order time of database ticket twin (primary market getNFT)
  // * @param pricePaidP price of primary sale as passed on by ticket issuer
  // */  
  // function addNftMetaPrimary(address eventAddress, uint256 nftIndex, uint256 orderTimeP, uint256 pricePaidP) public virtual returns(bool success){
  //     EventStruct storage c = allEventStructs[eventAddress];
  //     // c.amountNFTs++;
  //     // c.ordersprimary[nftIndex] = OrdersPrimary({_nftIndex: nftIndex, _pricePaidP: pricePaidP, _orderTimeP: orderTimeP});
  //     c.grossRevenuePrimary += pricePaidP;
  //     emit primaryMarketNFTSold(eventAddress, nftIndex, pricePaidP);
  //     return true;
  // }

  // /** 
  // * @dev storage function metadata of a secondary market trade (fan 2 fan)
  // * @param eventAddress address of event controlling getNFT 
  // * @param nftIndex unique index of getNFT
  // * @param orderTimeS timestamp passed on by ticket issuer of order time of database ticket twin (secondary market getNFT)
  // * @param pricePaidS price of secondary sale as passed on by ticket issuer
  // */   
  // function addNftMetaSecondary(address eventAddress, uint256 nftIndex, uint256 orderTimeS, uint256 pricePaidS) public virtual returns(bool success) {
  //     EventStruct storage c = allEventStructs[eventAddress];
  //     // c.orderssecondary[nftIndex] = OrdersSecondary({_nftIndex: nftIndex, _pricePaidS: pricePaidS, _orderTimeS: orderTimeS});
  //     c.grossRevenueSecondary += pricePaidS;
  //     emit secondaryMarketNFTSold(eventAddress, nftIndex, pricePaidS);
  //     return true;
  // }

  // function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName) public virtual returns(bool success) { 

  //   allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_address = ticketIssuerAddress;
  //   allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_name = ticketIssuerName;
  //   // allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_url = ticketIssuerUrl;

  //   emit newTicketIssuerMetaData(ticketIssuerAddress, ticketIssuerName, block.timestamp);
    
  //   ticketIssuerAddresses.push(ticketIssuerAddress);
  //   allTicketIssuerStructs[ticketIssuerAddress].listPointerT = ticketIssuerAddresses.length - 1;
  //   return true;
  // }

  // function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory ticketeerName, bytes memory eventData) public {

  //   allEventStructs[eventAddress].event_address = eventAddress;
  //   allEventStructs[eventAddress].event_name = eventName;
  //   allEventStructs[eventAddress].shop_url = shopUrl;

  //   allEventStructs[eventAddress].ticketeer_name = ticketeerName;
  //   allEventStructs[eventAddress].event_metadata = eventData;
  //   // eventAddresses.push(eventAddress);

  //   // allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;

  //   emit newEventRegistered(eventAddress, eventName, block.timestamp);
  // }

  function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, bytes32 latitude, bytes32 longitude, bytes32 currency, uint256 startingTime, bytes32 ticketeerName, bytes memory eventData) public virtual {

    require(gAC.hasRole(FACTORY_ROLE, msg.sender), "primaryMint: sender must have minter role to mint");

    allEventStructs[eventAddress].event_address = eventAddress;
    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    allEventStructs[eventAddress].latitude = latitude;
    allEventStructs[eventAddress].longitude = longitude;
    allEventStructs[eventAddress].currency = currency;
    allEventStructs[eventAddress].start_time = startingTime;  
    allEventStructs[eventAddress].ticketeer_name = ticketeerName;
    allEventStructs[eventAddress].event_metadata = eventData;
    eventAddresses.push(eventAddress);
    // allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;

    // EventStruct memory e = allEventStructs[eventAddress];
    // e.event_address = eventAddress;
    // e.event_name = eventName;
    // e.shop_url = shopUrl;
    // e.latitude = latitude;
    // e.longitude = longitude;
    // e.currency = currency;
    // e.start_time = startingTime;  
    // e.ticketeer_name = ticketeerName;
    // // e.event_metadata = eventData;
    // eventAddresses.push(eventAddress);
    // e.listPointerE = eventAddresses.length -1;
  }
 
  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, uint256 startTime) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        allEventStructs[eventAddress].start_time);
        // allEventStructs[eventAddress].ticketissuer_address,
        // allEventStructs[eventAddress].amountNFTs,
        // allEventStructs[eventAddress].grossRevenuePrimary);
  }

  function getEventCount() public view returns(uint256 eventCount) {
    return eventAddresses.length;
  }

  // function fetchPrimaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaidP) {
  //   return(
  //       allEventStructs[eventAddress].ordersprimary[nftIndex]._nftIndex,
  //       allEventStructs[eventAddress].ordersprimary[nftIndex]._pricePaidP
  //       );
  // }

  // function fetchSecondaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaidS) {
  //   return(
  //       allEventStructs[eventAddress].orderssecondary[nftIndex]._nftIndex,
  //       allEventStructs[eventAddress].orderssecondary[nftIndex]._pricePaidS
  //       );
  // }

  // function isEvent(address eventAddress) public view returns(bool isIndeed) {
  //   if(eventAddresses.length == 0) return false;
  //   return (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress);
  // }

  // function getEventCount() public view returns(uint256 eventCount) {
  //   return eventAddresses.length;
  // }

  //   /**
  //   * @dev returns if address is registered as a ticketIssuer
  //   * @param ticketIssuerAddress address of ticket issuer 
  //   */
  // function isTicketIssuer(address ticketIssuerAddress) public view returns(bool isIndeed) {
  //   if(ticketIssuerAddresses.length == 0) return false;
  //   return (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress);
  // }

  //   /**
  //   * @dev outputs total amount of ticketIssuers
  //   */
  // function getTicketIssuerCount() public view returns(uint256 ticketIssuerCount) {
  //   return ticketIssuerAddresses.length;
  // }
}