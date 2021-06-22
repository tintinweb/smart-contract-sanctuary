/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

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

// File: contracts/utils/ContextUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: contracts/utils/SafeMathUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IbaseGETNFT.sol

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IbaseGETNFT {

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside;
        bool scanned;
        bool valid;
    }

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);


    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external returns (uint256 nftIndex);

    function relayColleterizedMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
    ) external returns(uint256);

    function editTokenURIbyAddress(
        address originAddress,
        string calldata _newTokenURI
        ) external;

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external returns(uint256);

    function scanNFT(
        address originAddress,
        uint256 orderTime
        ) external returns(bool);

    function invalidateAddressNFT(
        address originAddress,
        uint256 orderTime
        ) external;

    function claimgetNFT(
        address originAddress, 
        address externalAddress) external;

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);

    function ticketMetadata(address originAddress)
      external  
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      );

    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 issuePrice,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
        ) external returns(uint256);

}

// File: contracts/interfaces/IticketFuelDepotGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IticketFuelDepotGET {

    function getActiveFuel() 
    external view returns(address);

    function calcNeededGET(
         uint256 dollarvalue)
         external view returns(uint256);

    function chargeProtocolTax(
        uint256 nftIndex
    ) external returns(uint256); 

    function fuelBackpack(
        uint256 nftIndex,
        uint256 amountBackpack
    ) external returns(bool);

    function swipeCollected() 
    external returns(uint256);

    function deductNFTTankIndex(
        uint256 nftIndex,
        uint256 amountDeduct
    ) external;

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

    event statechangeTaxed(
        uint256 nftIndex,
        uint256 GETTaxedAmount
    );

}

// File: contracts/interfaces/IGETAccessControl.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

// File: contracts/interfaces/IEconomicsGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEconomicsGET {
    function editCoreAddresses(
        address newBouncerAddress,
        address newFuelAddress,
        address newDepotAddress
    ) external;

    function getGETPrice() 
    external view returns(uint64);

    function balanceOfRelayer(
        address relayerAddress
    ) external;

    function setPriceGETUSD(
        uint256 newGETPrice)
        external;
    
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external;

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns(uint256);

    function fuelBackpackTicketBackfill(
        uint256 nftIndex,
        address relayerAddress,
        uint256 baseGETFee
        ) external returns(bool);


    function calcBackpackValue(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    function calcBackpackGET(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint256 indexed amountPacked
    );

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

}

// File: contracts/eventMetadataStorage.sol

pragma solidity >=0.5.0 <0.7.0;








contract eventMetadataStorage is Initializable, ContextUpgradeable {
    IGETAccessControl private GET_BOUNCER;
    IEconomicsGET private ECONOMICS;
    IbaseGETNFT private BASE;
    IticketFuelDepotGET private DEPOT;

    string public constant contractName = "eventMetadataStorage";
    string public constant contractVersion = "1";

    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");

    function _initialize_metadata(
      address address_bouncer,
      address address_economics,
      address address_fueldepot
      ) public initializer {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        ECONOMICS = IEconomicsGET(address_economics);
        DEPOT = IticketFuelDepotGET(address_fueldepot);
    }

    using SafeMathUpgradeable for uint256;

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
        bool private_event;
        bool created;
    }

    mapping(address => EventStruct) private allEventStructs;
    address[] private eventAddresses;  

    event newEventRegistered(
      address indexed eventAddress,
      uint256 indexed getUsed,
      string eventName,
      uint256 indexed orderTime
    );

    event AccessControlSet(
      address indexed NewAccesscontrol
    );

    event UnderWriterSet(
      address indexed eventAddress,
      address indexed underWriterAddress
    );

    event BaseConfigured(
        address baseAddress
    );


  // MODIFIERS

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_RELAYER");
        _;
    }
  
    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    // CONTRACT CONFIGURATION

    function setAccessControl(
      address newAddressBouncer
      ) external onlyAdmin {

        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        
        emit AccessControlSet(
          newAddressBouncer);
    }

    function configureBase(
      address base_address) public onlyAdmin {

        BASE = IbaseGETNFT(base_address);

        emit BaseConfigured(
            base_address);
    }

    function setUnderwriterAddress(
      address eventAddress, 
      address wrappingContract
      ) external onlyAdmin {

        allEventStructs[eventAddress].underwriter_address = wrappingContract;

        emit UnderWriterSet(
          eventAddress, 
          wrappingContract
        );
    }

    // OPERATIONAL FUNCTIONS

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
      ) public onlyRelayer {

      address underwriterAddress = 0x0000000000000000000000000000000000000000;

      if (isPrivate == true) {
        allEventStructs[eventAddress] = EventStruct(
          eventAddress, 
          integratorAccountPublicKeyHash,
          underwriterAddress,
          "Private event name", 
          "Private event URL",
          "Private image URL",
          eventMeta,
          eventTimes, 
          false,
          extraData,
          true,
          true
        );

      } else {

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
          extraData,
          isPrivate,
          true
        );
      }

      eventAddresses.push(eventAddress);

      emit newEventRegistered(
        eventAddress,
        0,
        eventName,
        block.timestamp
      );
    }

    // VIEW FUNCTIONS

    /** returns the EOA or contract address that has colleterized the NFT
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function getUnderwriterAddress(
      address eventAddress
      ) public virtual view returns (address)
      {
        return allEventStructs[eventAddress].underwriter_address;
      }

    /** returns if an event address is colleterized 
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function isInventoryUnderwritten(
      address eventAddress)
        public virtual view 
        returns (bool)
        {
          return allEventStructs[eventAddress].set_aside;
        }


    /** returns if an event address exists 
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function doesEventExist(
      address eventAddress
    ) public view virtual returns(bool)
    {
      return allEventStructs[eventAddress].created;
    }

    /** returns all metadata of an event
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
     */
    function getEventData(
      address eventAddress)
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
          bytes32[] memory _extra_data,
          bool _private_event
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
          _private_event = mdata.private_event;
      }

    function getEventCount() public view returns(uint256) 
    {
      return eventAddresses.length;
    }

    function returnStructEvent(
        address eventAddress
    ) public view returns (EventStruct memory)
    {
        return allEventStructs[eventAddress];
    }

}