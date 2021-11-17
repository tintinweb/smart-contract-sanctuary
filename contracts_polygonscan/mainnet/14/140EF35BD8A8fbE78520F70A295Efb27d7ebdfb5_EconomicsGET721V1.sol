// Sources flattened with hardhat v2.6.4 https://hardhat.org

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
        require(_initializing || !_initialized, "Already initialized");

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

    function __Context_init_unchained() internal initializer {}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    enum TicketStates {
        UNSCANNED,
        SCANNED,
        CLAIMABLE,
        INVALIDATED,
        PREMINTED,
        COLLATERALIZED
    }
    // enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

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
    ) external returns (uint256);

    function scanNFT(address originAddress, uint256 orderTime) external returns (bool);

    function invalidateAddressNFT(address originAddress, uint256 orderTime) external;

    function claimgetNFT(address originAddress, address externalAddress) external;

    function setOnChainSwitch(bool _switchState, uint256 _refactorSwapIndex) external;

    /// VIEW FUNCTIONS

    function isNFTClaimable(uint256 nftIndex, address ownerAddress) external view returns (bool);

    function returnStruct(uint256 nftIndex) external view returns (TicketData memory);

    function addressToIndex(address ownerAddress) external view returns (uint256);

    function viewPrimaryPrice(uint256 nftIndex) external view returns (uint32);

    function viewLatestResalePrice(uint256 nftIndex) external view returns (uint32);

    function viewEventOfIndex(uint256 nftIndex) external view returns (address);

    function viewTicketMetadata(uint256 nftIndex) external view returns (bytes32[] memory);

    function viewTicketState(uint256 nftIndex) external view returns (uint256);
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

    function getUnderwriterAddress(address eventAddress) external view returns (address);

    function doesEventExist(address eventAddress) external view returns (bool);

    event NewEventRegistered(address indexed eventAddress, string indexed eventName, uint256 indexed timestamp);

    event UnderWriterSet(address eventAddress, address underWriterAddress, address requester);
}

// File contracts/interfaces/IEventFinancing.sol

pragma solidity ^0.8.0;

interface IEventFinancing {}

// File contracts/interfaces/INFT_ERC721V3.sol

pragma solidity ^0.8.0;

interface IGET_ERC721V3 {
    function mintERC721(address destinationAddress, string calldata ticketURI) external returns (uint256);

    function mintERC721_V3(address destinationAddress) external returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function relayerTransferFrom(
        address originAddress,
        address destinationAddress,
        uint256 nftIndex
    ) external;

    function changeBouncer(address _newBouncerAddress) external;

    function isNftIndex(uint256 nftIndex) external view returns (bool);

    function ownerOf(uint256 nftIndex) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;
}

// File contracts/interfaces/IEconomicsGET.sol

pragma solidity ^0.8.0;

interface IEconomicsGET {
    struct DynamicRateStruct {
        bool configured; // 0
        uint32 mintRate; // 1
        uint32 resellRate; // 2
        uint32 claimRate; // 3
        uint32 crowdRate; // 4
        uint32 scalperFee; // 5
        uint32 extraFee; // 6
        uint32 shareRate; // 7
        uint32 editRate; // 8
        uint32 maxBasePrice; // 9
        uint32 minBasePrice; // 10
        uint32 reserveSlot_1; // 11
        uint32 reserveSlot_2; // 12
    }

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
    ) external returns (uint256);

    function emptyBackpackBasic(uint256 nftIndex) external returns (uint256);

    function chargeTaxRateBasic(uint256 nftIndex) external;

    function swipeDepotBalance() external;

    function emergencyWithdrawAllFuel() external;

    function topUpBuffer(
        uint256 topUpAmount,
        uint256 priceGETTopUp,
        address relayerAddress,
        address bufferAddress
    ) external returns (uint256);

    function setRelayerBuffer(address _relayerAddress, address _bufferAddressRelayer) external;

    /// VIEW FUNCTIONS

    function checkRelayerConfiguration(address _relayerAddress) external view returns (bool);

    function balanceRelayerSilo(address relayerAddress) external view returns (uint256);

    function valueRelayerSilo(address _relayerAddress) external view returns (uint256);

    function estimateNFTMints(address _relayerAddress) external view returns (uint256);

    function viewRelayerFactor(address _relayerAddress) external view returns (uint256);

    function viewRelayerGETPrice(address _relayerAddress) external view returns (uint256);

    function viewBackPackValue(uint256 _nftIndex, address _relayerAddress) external view returns (uint256);

    function viewBackPackBalance(uint256 _nftIndex) external view returns (uint256);

    function viewDepotBalance() external view returns (uint256);

    function viewDepotValue() external view returns (uint256);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    function GETgovernanceAddress() external view returns (address);

    function feeCollectorAddress() external view returns (address);

    function treasuryDAOAddress() external view returns (address);

    function stakingContractAddress() external view returns (address);

    function emergencyAddress() external view returns (address);

    function bufferAddress() external view returns (address);

    function AccessControlGET_proxy_address() external view returns (address);

    function baseGETNFT_proxy_address() external view returns (address);

    function getNFT_ERC721_proxy_address() external view returns (address);

    function eventMetadataStorage_proxy_address() external view returns (address);

    function getEventFinancing_proxy_address() external view returns (address);

    function economicsGET_proxy_address() external view returns (address);

    function fueltoken_get_address() external view returns (address);

    function basicTaxRate() external view returns (uint256);

    function priceGETUSD() external view returns (uint256);

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

    function __FoundationContract_init_unchained(address _configurationAddress) internal initializer {
        CONFIGURATION = IGETProtocolConfiguration(_configurationAddress);
        GET_GOVERNANCE = 0x8f56080c0d86264195811790c4a1d310776ff2c3a02bf8a3c20af9f01a045218;
        GET_ADMIN = 0xc78a2ac81d1427bc228e4daa9ddf3163091b3dfd17f74bdd75ef0b9166a23a7e;
        RELAYER_ROLE = 0xe2b7fb3b832174769106daebcfd6d1970523240dda11281102db9363b83b0dc4;
        FACTORY_ROLE = 0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
    }

    function __FoundationContract_init(address _configurationAddress) public initializer {
        __Context_init();
        __FoundationContract_init_unchained(_configurationAddress);
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender), "NOT_GOVERNANCE");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "NOT_FACTORY");
        _;
    }

    /**
    @dev calling this function will sync the global contract variables and instantiations with the DAO controlled configuration contract
    @notice can only be called by configurationGET contract
    TODO we could make this virtual, and then override the function in the contracts that inherit the foundation to instantiate the contracts that are relevant that particular contract
     */
    function syncConfiguration() external returns (bool) {
        // check if caller is configurationGETProxyAddress
        require(msg.sender == address(CONFIGURATION), "CALLER_NOT_CONFIG");

        GET_BOUNCER = IGETAccessControl(CONFIGURATION.AccessControlGET_proxy_address());

        BASE = IBaseGET(CONFIGURATION.baseGETNFT_proxy_address());

        GET_ERC721 = IGET_ERC721V3(CONFIGURATION.getNFT_ERC721_proxy_address());

        METADATA = IEventMetadataStorage(CONFIGURATION.eventMetadataStorage_proxy_address());

        FINANCE = IEventFinancing(CONFIGURATION.getEventFinancing_proxy_address());

        ECONOMICS = IEconomicsGET(CONFIGURATION.economicsGET_proxy_address());

        FUELTOKEN = IERC20(CONFIGURATION.fueltoken_get_address());

        return true;
    }
}

// File contracts/utils/ReentrancyGuardUpgradeable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// File contracts/EconomicsGET.sol

pragma solidity ^0.8.0;

contract EconomicsGET721V1 is FoundationContract, ReentrancyGuardUpgradeable {
    function __EconomicsGET_init_unchained() internal initializer {}

    function __EconomicsGET_init(address _configurationAddress) public initializer {
        __Context_init();
        __FoundationContract_init(_configurationAddress);
        __EconomicsGET_init_unchained();
    }

    // INCREASED DEFINITION
    // data structure containing all the different rates for a particular relayer
    // 100% (1) 1000_000, 10% (0.1) = 1000_00, 1% (0.01) = 1000_0, 0.1% (0.001) = 1000, 0.01% (0.0001) = 100, 0.001% (0,00001) = 10, 0.0001% = (0.000001) = 1 ---> so all scaled by 1000 000
    // USD values (min, max) are scaled by 1000
    struct DynamicRateStruct {
        bool configured; // 0
        uint32 mintRate; // 1
        uint32 resellRate; // 2
        uint32 claimRate; // 3
        uint32 crowdRate; // 4
        uint32 scalperFee; // 5
        uint32 extraFee; // 6
        uint32 shareRate; // 7
        uint32 editRate; // 8
        uint32 maxBasePrice; // 9
        uint32 minBasePrice; // 10
        uint32 reserveSlot_1; // 11
        uint32 reserveSlot_2; // 12
    }

    // data structure containing all data of a topUp (receipt)
    struct TopUpReceipt {
        uint256 amountToppedUp; // in wei 1GET = 1e18
        uint256 priceGETUSDTopUp; // in usd $1 = 1e3
        uint256 newDCAPrice; // in usd $1 = 1e3
    }

    // struct storing the accumulated DCA stats of a relayer
    struct RelayerDCAStruct {
        uint256 totalPaidUSD; // in usd $1 = 1e3
        uint256 totalTokens; // in wei 1GET = 1e18
    }

    // ticketeer identity(relayer) to their fee configuration struct
    mapping(address => DynamicRateStruct) private relayerRates;

    // tracking of the amount of top ups done by this realyer
    mapping(address => uint256) private topUpsRelayerCount;

    // cached mintrate x relayerGETPrice x 100000000
    mapping(address => uint256) private cachedMintFactor;

    // nested mapping containing the indexed receipts of a relayer
    mapping(address => mapping(uint256 => TopUpReceipt)) private receiptDrawer;

    // mapping with relayer silo balance, in GET, in wei 1e18
    mapping(address => uint256) private relayerSiloBalance;

    // mapping storing the average price per GET topped up (used to value GET in silo)
    mapping(address => RelayerDCAStruct) private relayerDCAs;

    // the relayerGETPrice of a relayer (the USD/GET price the silo balance is valued at)
    mapping(address => uint256) private relayerGETPrice;

    // mapping of basic_balance of NFT by nftIndex
    mapping(uint256 => uint256) private backpackBasicBalance;

    // count of total amount of collected GET
    uint256 private collectedDepot;

    // average NFT basePrice of a relayer (x1000)
    mapping(address => uint256) private averageBasePrice;

    // mapping used to track what relayers are configured properly
    mapping(address => bool) private isRelayerConfigured;

    // mapping between buffer and relayer
    mapping(address => address) private relayerBufferAddress;

    // EVENTS ECONOMICS GET

    event AveragePriceUpdated(
        address indexed relayerUpdated,
        uint256 indexed oldRelayerPrice,
        uint256 indexed newRelayerPrice
    );

    event RelayerToppedUp(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    );

    event RelayerToppedUpBuffer(
        address indexed relayerAddress,
        uint256 indexed topUpAmount,
        uint256 priceGETTopUp,
        uint256 indexed newsiloprice
    );

    event AverageSiloPriceUpdated(address relayerAddress, uint256 oldPrice, uint256 newPrice);

    event SiloBalanceCorrected(address relayerAddress, uint256 oldBalance, uint256 newBalance, uint256 difference);

    event DepotSwiped(address feeCollectorAddress, uint256 balance);

    event RelayerConfiguration(address relayerAddress, uint32[12] dynamicRates);

    event BackPackDrainedBasic(uint256 nftIndex, uint256 amountCollected);

    event BackPackDrainedUpsell(uint256 nftIndex, uint256 amountCollected);

    event ReceiptInDrawer(address relayerAddress, uint256 amountToppedUp);

    event FeeCollectorSet(address newFeeCollector);

    event FactorUpdated(address relayerAddress, uint256 mintFactor);

    event RelayerConfigurationCleared(address relayerAddress);

    event CollectedDepotNullified(uint256 newDepotBalance);

    event RelayerBufferMapped(address relayerAddress, address bufferAddressRelayer);

    event EmergencyWithdraw(address recipientFuel, uint256 amountFuel);

    // MODIFIERS ECONOMICSGET //

    modifier onlyConfigured(address _relayerAddress) {
        require(isRelayerConfigured[_relayerAddress], "RELAYER_NOT_CONFIGURED");
        _;
    }

    /// OPERATIONAL FUNCTIONS

    /**
    @param _relayerAddress the relayer address the new relayerRateStruct belongs to
    @param  dynamicRates array containing all the dyanmic rates x10 000
     */
    function setDynamicRateStruct(address _relayerAddress, uint32[12] calldata dynamicRates) external onlyAdmin {
        require(_relayerAddress != address(0), "ADDRESS_ZERO");

        // storing the new configuration in gas effiicent manner
        DynamicRateStruct storage _rates = relayerRates[_relayerAddress];
        _rates.configured = true; // 0
        _rates.mintRate = dynamicRates[0]; // 1
        _rates.resellRate = dynamicRates[1]; // 2
        _rates.claimRate = dynamicRates[2]; // 3
        _rates.crowdRate = dynamicRates[3]; // 4
        _rates.scalperFee = dynamicRates[4]; // 5
        _rates.extraFee = dynamicRates[5]; // 6
        _rates.shareRate = dynamicRates[6]; // 7
        _rates.editRate = dynamicRates[7]; // 8
        _rates.maxBasePrice = dynamicRates[8]; // 9
        _rates.minBasePrice = dynamicRates[9]; // 10
        _rates.reserveSlot_1 = dynamicRates[10]; // 11
        _rates.reserveSlot_2 = dynamicRates[11]; // 12

        if (relayerBufferAddress[_relayerAddress] != address(0x0)) {
            isRelayerConfigured[_relayerAddress] = true;
        }

        _updateMintFactor(_relayerAddress, dynamicRates[0]);

        emit RelayerConfiguration(_relayerAddress, dynamicRates);
    }

    function setRelayerBuffer(address _relayerAddress, address _bufferAddressRelayer) external onlyAdmin {
        relayerBufferAddress[_relayerAddress] = _bufferAddressRelayer;

        if (relayerRates[_relayerAddress].configured == true) {
            isRelayerConfigured[_relayerAddress] = true;
        }

        emit RelayerBufferMapped(_relayerAddress, _bufferAddressRelayer);
    }

    /** clears out the configured dynamic rates of a relayer
    @param _relayerAddress address of the relayer
     */
    function clearDynamicRateStruct(address _relayerAddress) external onlyAdmin {
        delete relayerRates[_relayerAddress];

        isRelayerConfigured[_relayerAddress] = false;
        cachedMintFactor[_relayerAddress] = 0;

        emit RelayerConfigurationCleared(_relayerAddress);
    }

    /** @notice tops up the silo balance of a relayer, buffer pays the fuel tokens 
    @param _topUpAmount amount of fuel tokens that will be topped up
    @param _priceGETTopUp USD price per GET that is paid and will be locked
    @param _relayerAddress address of relayer
    */
    function topUpRelayerFromBuffer(
        uint256 _topUpAmount,
        uint256 _priceGETTopUp,
        address _relayerAddress
    ) external onlyAdmin nonReentrant onlyConfigured(_relayerAddress) returns (uint256) {
        require(_topUpAmount > 0, "ZERO_TOPPED_UP");

        require(_priceGETTopUp > 0 || _priceGETTopUp != 0, "INVALID_GET_PRICE");

        // check if the relayer has enough fuel tokens on their address to topUp
        require(FUELTOKEN.balanceOf(relayerBufferAddress[_relayerAddress]) >= _topUpAmount, "BALANCE_BUFFER_TOO_LOW");

        // check if relayer has allowed the economicsGET contract to move tokens on their behalf
        require(
            FUELTOKEN.allowance(relayerBufferAddress[_relayerAddress], address(this)) >= _topUpAmount,
            "ALLOWANCE_BUFFER_ERROR"
        );

        // transfer fuel tokens from buffer address to economicsGET
        bool topUpFuel = FUELTOKEN.transferFrom(relayerBufferAddress[_relayerAddress], address(this), _topUpAmount);
        require(topUpFuel, "TRANSFER_FAILED_TOPUPGET");

        // update silo balance of the relayer
        relayerSiloBalance[_relayerAddress] += _topUpAmount;

        // update the average silo price, as the topUp might have effected the average DCA topup
        uint256 _newSiloPrice = _calculateNewAveragePrice(_topUpAmount, _priceGETTopUp, _relayerAddress);

        topUpsRelayerCount[_relayerAddress] += 1;

        _storeTopUpReceipt(_relayerAddress, _priceGETTopUp, _topUpAmount, _newSiloPrice);

        // as the silo price is updated, the mintFactor needs to be recalculated
        _updateMintFactor(_relayerAddress, relayerRates[_relayerAddress].mintRate);

        emit RelayerToppedUpBuffer(_relayerAddress, _topUpAmount, _priceGETTopUp, _newSiloPrice);

        // return the new silo balance
        return relayerSiloBalance[_relayerAddress];
    }

    /**  fuels NFT backpack, called from primarySale()
    @param _nftIndex index of NFT that is minted
    @param _relayerAddress address of relayer that will be billed
    @param _basePrice USD price of ticket order (mulitplied by 1000)
    @notice if min_base_price is 0, free tickets cost no GET fuel
    */
    function fuelBackpackTicket(
        uint256 _nftIndex,
        address _relayerAddress,
        uint256 _basePrice
    ) external onlyFactory onlyConfigured(_relayerAddress) returns (uint256) {
        uint32 _min = relayerRates[_relayerAddress].minBasePrice;
        // baseprice is below minimum, minimum price is used for fuel calculation
        if (_basePrice < _min) {
            return _refineFuel(_nftIndex, _relayerAddress, _min);
        }
        uint32 _max = relayerRates[_relayerAddress].maxBasePrice;
        // baseprice is above minimum, maximim price is used for fuel calculation
        if (_basePrice > _max) {
            return _refineFuel(_nftIndex, _relayerAddress, _max);
        }
        // baseprice is in between min/max, nft value is used for fuel calculation
        return _refineFuel(_nftIndex, _relayerAddress, _basePrice);
    }

       /** @notice tax the basic backpack of a nftIndex
        @param _nftIndex nftIndex being taxed
        returns amount that has been taxed by the DAO
        */
        function chargeTaxRateBasic(
            uint256 _nftIndex
        ) external onlyFactory returns(uint256) {

            uint256 _tax = CONFIGURATION.basicTaxRate() * backpackBasicBalance[_nftIndex] / 1_00_00;

            // add _tax to collectedDepot
            collectedDepot += _tax;

            // deduct from backpack balance
            backpackBasicBalance[_nftIndex] -= _tax;

            return _tax;
        }

    /** empties the basic backpack of an nftex 
    @param _nftIndex nftIndex being emptied
    returns amount of GET that was in the backpack
    */
    function emptyBackpackBasic(uint256 _nftIndex) external onlyFactory returns (uint256) {
        // check if nftIndex exists
        require(GET_ERC721.isNftIndex(_nftIndex), "ECONOMICS_INDEX_UNKNOWN");

        // fetch current balance of backpack
        uint256 _bal = backpackBasicBalance[_nftIndex];

        if (_bal == 0) {
            return 0;
        }

        // add _tax to collectedDepot (for the DAO)
        collectedDepot += _bal;

        // set basic backpack balance to 0
        delete backpackBasicBalance[_nftIndex];

        return _bal;
    }

    /** 
    @param _relayerAddress the relayerAddress of the silo that needs to be corrected
    @param _newBalance the correct/intended balance of the silo in GET 
    @notice the collectedDepot balance will be used as 'counter post' 
     */
    function correctBalanceSilo(
        address _relayerAddress,
        uint256 _newBalance /** in wei */
    ) external onlyAdmin {
        uint256 _oldBalance = relayerSiloBalance[_relayerAddress];
        uint256 _difference;

        // calculate the difference between new and old, to correct the Depot balnce. Could be positive and negative
        if (_newBalance > _oldBalance) {
            // Process refund to relayer
            // _difference is negative so remove from the collectedDepot by getting the positive difference.
            _difference = (_newBalance - _oldBalance);
            require(_difference < collectedDepot, "NOT_ENOUGH_IN_DEPOT");
            collectedDepot = collectedDepot - _difference;
        } else {
            // Process balance correction to depot
            // _difference is positive, reverse _old + _new to get positive difference and add.
            collectedDepot = collectedDepot + (_oldBalance - _newBalance);
        }

        emit SiloBalanceCorrected(_relayerAddress, _oldBalance, _newBalance, _difference);
    }

    /** resets the collectedDepot balance.
    @notice function is useful for if for whatever reason the balance doesn't reflecft what has been truely collected
     */
    function correctedDepotCorrection(uint256 _newDepotBalance) external onlyAdmin {
        require(_newDepotBalance > 0, "NEW_BALANCE_NEGATIVE");

        collectedDepot = _newDepotBalance;

        emit CollectedDepotNullified(_newDepotBalance);
    }

    /**
    @notice moves GET from the depot to the feeCollectorAddress
    @dev this function can be called by anyone
     */
    function swipeDepotBalance() external nonReentrant {
        require(collectedDepot > 0, "NOTHING_TO_SWIPE");

        require(FUELTOKEN.balanceOf(address(this)) >= collectedDepot, "COLLECTED_BALANCE_INVALID");

        require(_transferGET(CONFIGURATION.feeCollectorAddress(), collectedDepot), "GET_SWIPE_TRANSFER_FAILED");

        emit DepotSwiped(CONFIGURATION.feeCollectorAddress(), collectedDepot);

        collectedDepot = 0;
    }

    /** 
    @notice this function removes all the GET, belonging to the backpacks, silos as well as the depot
    */
    function emergencyWithdrawAllFuel() external onlyAdmin {
        emit EmergencyWithdraw(CONFIGURATION.feeCollectorAddress(), FUELTOKEN.balanceOf(address(this)));

        require(
            _transferGET(CONFIGURATION.feeCollectorAddress(), FUELTOKEN.balanceOf(address(this))),
            "GET_SWIPE_TRANSFER_FAILED"
        );
    }

    function _transferGET(address _toAddress, uint256 _amountGET) internal returns (bool) {
        // guard against rounding errors;
        // if GET amount to send is greater than contract balance,
        // send full contract balance
        if (_amountGET > FUELTOKEN.balanceOf(address(this))) {
            _amountGET = FUELTOKEN.balanceOf(address(this));
        }

        // if stable transfer was successful, transferring the fractions to the buyer
        bool swipeFuel = FUELTOKEN.transfer(_toAddress, _amountGET);
        return swipeFuel;
    }

    function _updateMintFactor(address _relayerAddress, uint32 _mintRate) internal {
        uint256 _getprice = relayerGETPrice[_relayerAddress];

        if (_getprice == 0) {
            // relayer silo has no GET price yet
            _getprice = CONFIGURATION.priceGETUSD(); // fallback to global GET price
        }

        if (_mintRate == 0) {
            // relayer not yet configured
            _mintRate = 30000; // this is a meaningless default figure as it will always be overwritten after a configuration of the relayerRates
        }

        uint256 _mintFactor = (1_00000_00000_00 / _getprice) * _mintRate;

        cachedMintFactor[_relayerAddress] = _mintFactor;

        emit FactorUpdated(_relayerAddress, _mintFactor);
    }

    /**  calculates average GET price for relayer after an topup (DCA price of GET top ups)
    @param _topUpAmount amount of GET that has been topped up x10^18
    @param _priceGETTopUp USD price per GET that is being topped in the silo
    @param _relayerAddress relayeraddress that has topped up their silo
    */
    function _calculateNewAveragePrice(
        uint256 _topUpAmount,
        uint256 _priceGETTopUp,
        address _relayerAddress
    ) internal returns (uint256) {
        // fetch the old silo value of the relayer
        uint256 _siloprice = relayerGETPrice[_relayerAddress];

        if (_siloprice == 0) {
            // this is the first topUp of this relayer

            // first top up, so all GET is valued at the same price regardless of amount topped up
            relayerGETPrice[_relayerAddress] = _priceGETTopUp;

            // store total voluem USD
            relayerDCAs[_relayerAddress].totalPaidUSD = (_topUpAmount * _priceGETTopUp);

            // store total amount of GET topped up
            relayerDCAs[_relayerAddress].totalTokens = _topUpAmount;

            emit AveragePriceUpdated(_relayerAddress, 0, _priceGETTopUp);

            return _priceGETTopUp;
        }

        // there have been topUps before by this relayer, we need to average the price
        // _newAveragePrice = ((total revenue pas top ups) + (revenue current topUp)) / ((amount GET topped up in the pas) + (amount topped up now))
        uint256 _newPrice = (relayerDCAs[_relayerAddress].totalPaidUSD + (_topUpAmount * _priceGETTopUp)) /
            (relayerDCAs[_relayerAddress].totalTokens + _topUpAmount);

        // update the total revenue USD topped up
        relayerDCAs[_relayerAddress].totalPaidUSD += _topUpAmount * _priceGETTopUp;

        // update the total amount of GET historically topped up
        relayerDCAs[_relayerAddress].totalTokens += _topUpAmount;

        // update silo price
        relayerGETPrice[_relayerAddress] = _newPrice;

        emit AverageSiloPriceUpdated(_relayerAddress, _siloprice, _newPrice);

        return _newPrice;
    }

    /**
    @param _nftIndex index of the nft that is being fueled
    @param _relayerAddress address of the relayer requesting and paying for the mint
    @param _basePrice usd price multiplied by 1e3 of the nft
    @return uint256 the amount of GET in wei 1e18 that is fueled into the backpack
     */
    function _refineFuel(
        uint256 _nftIndex,
        address _relayerAddress,
        uint256 _basePrice
    ) internal returns (uint256) {
        // calculate how much GET equates to the FIAT value needed in the backpack
        uint256 _amountget = _basePrice * cachedMintFactor[_relayerAddress];

        // check if silo balance is sufficient to fuel the backpack
        require(_amountget < relayerSiloBalance[_relayerAddress], "SILO_BALANCE_INSUFFICIENT");

        // update silo balance
        relayerSiloBalance[_relayerAddress] -= _amountget;

        // add balance to backpack balance
        backpackBasicBalance[_nftIndex] = _amountget;

        return _amountget;
    }

    /** stores topUp receipt in the contract
    @param _relayerAddress address of relayer that is topped up
    @param _amountToppedUp amount of GET in wei being topped up
    @param _newAverageSiloPrice the USD value per GET x1000 of the 
     */
    function _storeTopUpReceipt(
        address _relayerAddress,
        uint256 _priceGETUSDOrder,
        uint256 _amountToppedUp,
        uint256 _newAverageSiloPrice
    ) internal {
        TopUpReceipt storage receipts = receiptDrawer[_relayerAddress][topUpsRelayerCount[_relayerAddress]];

        receipts.amountToppedUp = _amountToppedUp;
        receipts.priceGETUSDTopUp = _priceGETUSDOrder;
        receipts.newDCAPrice = _newAverageSiloPrice;

        emit ReceiptInDrawer(_relayerAddress, _amountToppedUp);
    }

    //// VIEW FUNCTIONS ////

    function checkRelayerConfiguration(address _relayerAddress) external view returns (bool) {
        return isRelayerConfigured[_relayerAddress];
    }

    /** the GET balance in wei of relayer
    @param _relayerAddress address of integrator/ticketeer
     */
    function balanceRelayerSilo(address _relayerAddress) external view returns (uint256) {
        return relayerSiloBalance[_relayerAddress];
    }

    /**  returns USD value of the GET in the relayers silo
    @param _relayerAddress address of relayer
    @notice the output will be 1e3 higher as it an USD value
    */
    function valueRelayerSilo(address _relayerAddress) public view returns (uint256) {
        //
        return
            (relayerGETPrice[_relayerAddress] * relayerSiloBalance[_relayerAddress]) / 1_00000_00000_00000_000; /** correct for wei denomination dividing by 1e18 */
    }

    function viewRelayerRates(address _relayerAddress) external view returns (DynamicRateStruct memory) {
        return relayerRates[_relayerAddress];
    }

    // returns the baseMint factor (catched for reduced gas costs)
    function viewRelayerFactor(address _relayerAddress) external view returns (uint256) {
        return cachedMintFactor[_relayerAddress];
    }

    // returns the GET silo rate of a relayer
    function viewRelayerGETPrice(address _relayerAddress) external view returns (uint256) {
        return relayerGETPrice[_relayerAddress];
    }

    // returns GET balance in WEI of a relayer silo
    function viewBackPackBalance(uint256 _nftIndex) external view returns (uint256) {
        return backpackBasicBalance[_nftIndex];
    }

    // returns the value of the GET in the backpack using the silo rate of the relayer that minted the NF
    function viewBackPackValue(uint256 _nftIndex, address _relayerAddress) external view returns (uint256) {
        return (backpackBasicBalance[_nftIndex] * relayerGETPrice[_relayerAddress]) / 1_00000_00000_00000_000;
    }

    function viewDepotBalance() external view returns (uint256) {
        return collectedDepot;
    }

    function viewDepotValue() external view returns (uint256) {
        return (collectedDepot * CONFIGURATION.priceGETUSD()) / 1_00000_00000_00000_000;
    }

    function viewBufferOfRelayer(address _relayerAddress) public view returns (address) {
        return relayerBufferAddress[_relayerAddress];
    }
}