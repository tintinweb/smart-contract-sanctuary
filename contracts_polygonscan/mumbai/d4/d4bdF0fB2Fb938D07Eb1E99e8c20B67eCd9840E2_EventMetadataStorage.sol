/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File contracts/utils/ContextUpgradeable.sol


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/utils/SafeMathUpgradeable.sol


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/interfaces/IGETAccessControl.sol

pragma solidity ^0.8.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}


// File contracts/interfaces/IBaseGET.sol

pragma solidity ^0.8.0;

interface IBaseGET {

    enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

    struct TicketData {
        address eventAddress;
        bytes32[] ticketMetadata;
        uint256[2] salePrices;
        TicketStates state;
    }

    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        bytes32[] calldata ticketMetadata
    ) external;

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice
    ) external;

    function collateralMint(
        address basketAddress,
        address eventAddress, 
        uint256 primaryPrice,
        bytes32[] calldata ticketMetadata
    ) external returns(uint256);

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
        address externalAddress
     ) external;

    function setOnChainSwitch(
        bool _switchState
    ) external;
    
    /// VIEW FUNCTIONS

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);

    function addressToIndex(
        address ownerAddress
    ) external view returns (uint256);

    function viewPrimaryPrice(
        uint256 nftIndex
    ) external view returns (uint32);

    function viewLatestResalePrice(
        uint256 nftIndex
    ) external view returns (uint32);

    function viewEventOfIndex(
        uint256 nftIndex
    ) external view returns (address);

    function viewTicketMetadata(
        uint256 nftIndex
    ) external view returns (bytes32[] memory);

    function viewTicketState(
        uint256 nftIndex
    ) external view returns(uint);

}


// File contracts/interfaces/IEventMetadataStorage.sol

pragma solidity ^0.8.0;

interface IEventMetadataStorage {

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string calldata eventName, 
      string calldata shopUrl,
      string calldata imageUrl,
      bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      bytes32[] calldata extraData,
      bool isPrivate
      ) external;

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(address);

    function doesEventExist(
      address eventAddress
    ) external view returns(bool);

    event newEventRegistered(
      address indexed eventAddress, 
      string indexed eventName,
      uint256 indexed timestamp
    );

    event UnderWriterSet(
      address eventAddress,
      address underWriterAddress,
      address requester
    );

}


// File contracts/interfaces/IEventFinancing.sol

pragma solidity ^0.8.0;

interface IEventFinancing {

}


// File contracts/interfaces/INFT_ERC721V3.sol

pragma solidity ^0.8.0;

interface IGET_ERC721V3 {
    
    function mintERC721(
        address destinationAddress,
        string calldata ticketURI
    ) external returns(uint256);

    function mintERC721_V3(
        address destinationAddress
    ) external returns(uint256);
    
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns(uint256);
    
    function balanceOf(
        address owner
    ) external view returns(uint256);
    
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
    ) external;
    
    function changeBouncer(
        address _newBouncerAddress
    ) external;

    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);

    function ownerOf(
        uint256 nftIndex
    ) external view returns (address);

    function setApprovalForAll(
        address operator, 
        bool _approved) external;

}


// File contracts/interfaces/IEconomicsGET.sol

pragma solidity ^0.8.0;

interface IEconomicsGET {

    struct dynamicRateStruct {
        uint16 mint_rate; // 1
        uint16 resell_rate; // 2
        uint16 claim_rate; // 3
        uint16 crowd_rate; // 4
        uint16 scalper_fee; // 5
        uint16 extra_rate; // 6
        uint16 share_rate; // 7
        uint16 edit_rate; // 8
        uint16 max_base_price; // 9
        uint16 min_base_price; // 10
        uint16 reserve_slot_1; // 11
        uint16 reserve_slot_2; // 12
    }

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
    ) external returns (uint256);  

    function emptyBackpackBasic(
        uint256 nftIndex
    ) external returns (uint256);

    function chargeTaxRateBasic(
        uint256 nftIndex
    ) external;

    function swipeDepotBalance() external returns(uint256);

    function emergencyWithdrawFuel() external;

    function topUpBuffer(
            uint256 topUpAmount,
            uint256 priceGETTopUp,
            address relayerAddress,
            address bufferAddress
    ) external returns(uint256);

    function topUpRelayer(
            uint256 topUpAmount,
            uint256 priceGETTopUp,
            address relayerAddress
    ) external returns(uint256);

    /// VIEW FUNCTIONS

    function checkRelayerConfiguration(
        address _relayerAddress
    ) external view returns (bool);

    function balanceRelayerSilo(
        address relayerAddress
    ) external view returns (uint256);

    function valueRelayerSilo(
        address _relayerAddress
    ) external view returns(uint256);

    function estimateNFTMints(
        address _relayerAddress
    ) external view returns(uint256);

    function viewRelayerFactor(
        address _relayerAddress
    ) external view returns(uint256);

    function viewRelayerGETPrice(
        address _relayerAddress 
    ) external view returns (uint256);

    function viewBackPackValue(
        uint256 _nftIndex,
        address _relayerAddress
    ) external view returns (uint256);

    function viewBackPackBalance(
        uint256 _nftIndex
    ) external view returns (uint256);

    function viewDepotBalance() external view returns(uint256);
    function viewDepotValue() external view returns(uint256);
}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IfoundationContract.sol

pragma solidity ^0.8.0;

interface IfoundationContract {

    // TODO add interface for the foundation base contract 


}


// File contracts/interfaces/IGETProtocolConfiguration.sol

pragma solidity ^0.8.0;

interface IGETProtocolConfiguration {

    function GETgovernanceAddress() external view returns(address);
    function feeCollectorAddress() external view returns(address);
    function treasuryDAOAddress() external view returns(address);
    function stakingContractAddress() external view returns(address);
    function emergencyAddress() external view returns(address);
    function bufferAddress() external view returns(address);


    function AccessControlGET_proxy_address() external view returns(address);
    function baseGETNFT_proxy_address() external view returns(address);
    function getNFT_ERC721_proxy_address() external view returns(address);
    function eventMetadataStorage_proxy_address() external view returns(address);
    function getEventFinancing_proxy_address() external view returns(address);
    function economicsGET_proxy_address() external view returns(address);
    function fueltoken_get_address() external view returns(address);

    function basicTaxRate() external view returns(uint256);
    
    function priceGETUSD() external view returns(uint256);

    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external;

}


// File contracts/FoundationContract.sol

pragma solidity ^0.8.0;








contract FoundationContract is Initializable, ContextUpgradeable {
    
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint128;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;

    bytes32 private GET_GOVERNANCE;
    bytes32 private GET_ADMIN; 
    bytes32 private RELAYER_ROLE;
    bytes32 private FACTORY_ROLE;

    IGETProtocolConfiguration public CONFIGURATION;

    IGETAccessControl internal GET_BOUNCER;
    IBaseGET internal BASE;
    IGET_ERC721V3 internal GET_ERC721;
    IEventMetadataStorage internal METADATA;
    IEventFinancing internal FINANCE; // reserved slot
    IEconomicsGET internal ECONOMICS;
    IERC20 internal FUELTOKEN;

    event ContractSyncCompleted();

    function __FoundationContract_init_unchained(
        address _configurationAddress
    ) internal initializer {
        CONFIGURATION = IGETProtocolConfiguration(_configurationAddress);
        GET_GOVERNANCE = 0x8f56080c0d86264195811790c4a1d310776ff2c3a02bf8a3c20af9f01a045218;
        GET_ADMIN = 0xc78a2ac81d1427bc228e4daa9ddf3163091b3dfd17f74bdd75ef0b9166a23a7e;
        RELAYER_ROLE = 0xe2b7fb3b832174769106daebcfd6d1970523240dda11281102db9363b83b0dc4;
        FACTORY_ROLE = 0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
    }

    function __FoundationContract_init(
        address _configurationAddress
    ) public initializer {
        __Context_init();
        __FoundationContract_init_unchained(
            _configurationAddress
        );
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(GET_BOUNCER.hasRole(GET_ADMIN, msg.sender),
        "NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender),
        "NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender),
            "NOT_GOVERNANCE"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender),
        "NOT_FACTORY");
        _;
    }

    /**
    @dev calling this function will sync the global contract variables and instantiations with the DAO controlled configuration contract
    @notice can only be called by configurationGET contract
    TODO we could make this virtual, and then override the function in the contracts that inherit the foundation to instantiate the contracts that are relevant that particular contract
     */
    function syncConfiguration() external returns(bool) {

        // check if caller is configurationGETProxyAddress 
        require(msg.sender == address(CONFIGURATION), "CALLER_NOT_CONFIG");

        GET_BOUNCER = IGETAccessControl(
            CONFIGURATION.AccessControlGET_proxy_address()
        );

        BASE = IBaseGET(
            CONFIGURATION.baseGETNFT_proxy_address()
        );

        GET_ERC721 = IGET_ERC721V3(
            CONFIGURATION.getNFT_ERC721_proxy_address()
        );

        METADATA = IEventMetadataStorage(
            CONFIGURATION.eventMetadataStorage_proxy_address()
        );    

        FINANCE = IEventFinancing(
            CONFIGURATION.getEventFinancing_proxy_address()
        );            

        ECONOMICS = IEconomicsGET(
            CONFIGURATION.economicsGET_proxy_address()
        );        

        FUELTOKEN = IERC20(
            CONFIGURATION.fueltoken_get_address()
        );

        emit ContractSyncCompleted();
    
        return true;
    }

}


// File contracts/EventMetadataStorage.sol

pragma solidity ^0.8.0;

contract EventMetadataStorage is FoundationContract {

    function __initialize_metadata_unchained() internal initializer {
    }

    function __initialize_metadata(
      address configuration_address
    ) public initializer {
        __Context_init();
        __FoundationContract_init(
            configuration_address);
        __initialize_metadata_unchained();
    }

    struct EventStruct {
        address eventAddress; 
        address relayerAddress;
        address underWriterAddress;
        string eventName;
        string shopUrl;
        string imageUrl;
        bytes32[4] eventMetadata; // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
        uint256[2] eventTimes; // -> [uin256 startingTime, uint256 endingTime]
        bool setAside; // -> false = default
        bytes32[] extraData;
        bool privateEvent;
        bool created;
    }

    mapping(address => EventStruct) private allEventStructs;
    address[] private eventAddresses;  

    event NewEventRegistered(
      address indexed eventAddress,
      uint256 indexed getUsed,
      string eventName,
      uint256 indexed orderTime
    );

    event AccessControlSet(
      address indexed newAccesscontrol
    );

    event UnderWriterSet(
      address indexed eventAddress,
      address indexed underWriterAddress
    );

    event BaseConfigured(
        address baseAddress
    );

    // OPERATIONAL FUNCTIONS

    function registerEvent(
      address _eventAddress,
      address _integratorAccountPublicKeyHash,
      string memory _eventName, 
      string memory _shopUrl,
      string memory _imageUrl,
      bytes32[4] memory _eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] memory _eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool _setAside, // -> false = default
      bytes32[] memory _extraData,
      bool _isPrivate
      ) public onlyRelayer {

      address _underwriterAddress = 0x0000000000000000000000000000000000000000;

      EventStruct storage _event = allEventStructs[_eventAddress];
      _event.eventAddress = _eventAddress;
      _event.relayerAddress = _integratorAccountPublicKeyHash;
      _event.underWriterAddress = _underwriterAddress;
      _event.eventName = _eventName;
      _event.shopUrl = _shopUrl;
      _event.imageUrl = _imageUrl;
      _event.eventMetadata = _eventMeta;
      _event.eventTimes = _eventTimes;
      _event.setAside = _setAside;
      _event.extraData = _extraData;
      _event.privateEvent = _isPrivate;
      _event.created = true;

      eventAddresses.push(_eventAddress);

      emit NewEventRegistered(
        _eventAddress,
        0,
        _eventName,
        block.timestamp
      );
    }

    // VIEW FUNCTIONS

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
          address _relayerAddress,
          address _underWriterAddress,
          string memory _eventName,
          string memory _shopUrl,
          string memory _imageUrl,
          bytes32[4] memory _eventMeta,
          uint256[2] memory _eventTimes,
          bool _setAside,
          bytes32[] memory _extraData,
          bool _privateEvent
          )    
        {
          EventStruct storage mdata = allEventStructs[eventAddress];
          _relayerAddress = mdata.relayerAddress;
          _underWriterAddress = mdata.underWriterAddress;
          _eventName = mdata.eventName;
          _shopUrl = mdata.shopUrl;
          _imageUrl = mdata.imageUrl;
          _eventMeta = mdata.eventMetadata;
          _eventTimes = mdata.eventTimes;
          _setAside = mdata.setAside;
          _extraData = mdata.extraData;
          _privateEvent = mdata.privateEvent;
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