pragma solidity ^0.6.2;

pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

contract eventMetadataStorage is Initializable {

    // IGETAccessControl public gAC;
    IGETAccessControl public GET_BOUNCER;

    struct EventStruct {
        address event_address; 
        address integrator_address;
        address underwriter_address;
        string event_name;
        string shop_url;
        string image_url;
        // bytes[2] event_urls; // [bytes shopUrl, bytes eventImageUrl]
        bytes32[4] event_metadata; // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
        uint256[2] event_times; // -> [uin256 startingTime, uint256 endingTime]
        bool set_aside; // -> false = default
        // bytes[] extra_data;
        bytes32[] extra_data;
    }

    mapping(address => EventStruct) public allEventStructs;

    address[] public eventAddresses;  

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    event newEventRegistered(
      address indexed eventAddress, 
      string indexed eventName,
      uint256 indexed timestamp
    );

    event AccessControlSet(
      address indexed requester,
      address indexed new_accesscontrol
    );

    event UnderWriterSet(
      address indexed eventAddress,
      address indexed underWriterAddress,
      address indexed requester
    );

    // TODO change bouncer name
    function __initialize_metadata(
      address _address_bouncer
      ) public initializer {
        GET_BOUNCER = IGETAccessControl(_address_bouncer);
    }

    function setAccessControl(
      address _new_bouncer
      ) public {
        require(GET_BOUNCER.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "setAccessControl: ILLEGAL ADMIN");
        GET_BOUNCER = IGETAccessControl(_new_bouncer);
        emit AccessControlSet(msg.sender, _new_bouncer);
    }

    function setUnderwriterAddress(
      address _eventAddress, 
      address _wrapping_contract
      ) public {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "setUnderwriterAddress: ILLEGAL RELAYER");
        allEventStructs[_eventAddress].underwriter_address = _wrapping_contract;
        emit UnderWriterSet(_eventAddress, _wrapping_contract, msg.sender);
    }

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string memory eventName, 
      string memory shopUrl,
      string memory imageUrl,
      bytes32[4] memory eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] memory eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      // bytes[] memory extraData
      bytes32[] memory extraData,
      bool isPrivate
      ) public {

      require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "registerEvent: ILLEGAL RELAYER");

      address underwriterAddress = 0x0000000000000000000000000000000000000000;

      allEventStructs[eventAddress] = EventStruct(
        eventAddress, 
        integratorAccountPublicKeyHash,
        underwriterAddress,
        eventName, 
        shopUrl,
        imageUrl,
        eventMeta, 
        eventTimes, 
        setAside,
        extraData
      );

      eventAddresses.push(eventAddress);

      emit newEventRegistered(
        eventAddress,
        eventName,
        block.timestamp
      );
    
    }

    function getUnderwriterAddress(
      address eventAddress
      ) public virtual view returns (
        address _underwriter_address
      )
      {
        _underwriter_address = allEventStructs[eventAddress].underwriter_address;
      }

    function isInventoryUnderwritten(address eventAddress)
        public virtual view
        returns (
          bool _is_set_aside
        )
        {
          _is_set_aside = allEventStructs[eventAddress].set_aside;
        }

    function getEventData(address eventAddress)
        public virtual view
        returns (
          address _integrator_address,
          address _underwriter_address,
          string memory _event_name,
          string memory _shop_url,
          string memory _image_url,
          bytes32[4] memory _event_meta,
          uint256[2] memory _event_times,
          bool _set_aside,
          bytes32[] memory _extra_data
          )    
        {
          EventStruct storage mdata = allEventStructs[eventAddress];
          _integrator_address = mdata.integrator_address;
          _underwriter_address = mdata.underwriter_address;
          _event_name = mdata.event_name;
          _shop_url = mdata.shop_url;
          _image_url = mdata.image_url;
          _event_meta = mdata.event_metadata;
          _event_times = mdata.event_times;
          _set_aside = mdata.set_aside;
          _extra_data = mdata.extra_data;
      }

    function getEventCount() public view returns(uint256 eventCount) 
    {
      eventCount = eventAddresses.length;
      // return eventAddresses.length;
    }

}

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}