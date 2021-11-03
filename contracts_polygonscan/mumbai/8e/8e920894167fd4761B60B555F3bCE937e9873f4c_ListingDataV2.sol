// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

contract ListingDataV2 is Master {
    // State Variable
    // Cover Request
    CoverRequest[] internal requests; // CoverRequest.id
    mapping(uint256 => uint256) public requestIdToInsuredSumTaken;
    mapping(address => uint256[]) internal buyerToRequests;
    mapping(string => uint256[]) internal coinIdToRequests;
    mapping(uint256 => uint256) public coverRequestFullyFundedAt;
    mapping(uint256 => bool) public requestIdToRefundPremium;
    mapping(uint256 => bool) public isDepositTakenBack; // coverId -> true/false
    // Cover Offer
    CoverOffer[] internal offers; // CoverOffer.id
    mapping(uint256 => uint256) public offerIdToInsuredSumTaken;
    mapping(address => uint256[]) internal funderToOffers;
    mapping(string => uint256[]) internal coinIdToOffers;
    mapping(uint256 => bool) public isDepositOfOfferTakenBack; // offer id => state of take back deposit
    mapping(uint256 => uint256) public testToTest;

    // Events
    event CreateRequest(
        uint256 id,
        address indexed holder,
        CoverRequest request,
        CoinPricingInfo assetPricing,
        CoinPricingInfo feePricing
    );
    event CreateOffer(
        uint256 id,
        address indexed funder,
        CoverOffer coverOffer,
        CoinPricingInfo feePricing,
        CoinPricingInfo assetPricing,
        uint8 depositPeriod
    );
    event DepositOfOfferTakenBack(uint256 offerId);
    event DepositTakenBack(uint256 coverId);
    event RequestFullyFunded(uint256 requestId, uint256 fullyFundedAt);
    event PremiumRefunded(uint256 requestId);

    /**
     * @dev Save listing data of cover request
     */
    function storedRequest(
        CoverRequest memory inputRequest,
        CoinPricingInfo memory assetPricing,
        CoinPricingInfo memory feePricing,
        address member
    ) external {
        requests.push(inputRequest);
        uint256 requestId = requests.length - 1;
        buyerToRequests[member].push(requestId);
        coinIdToRequests[inputRequest.coinId].push(requestId);
        requestIdToInsuredSumTaken[requestId] = 0; // set insured sum taken to 0 as iniitial value
        emit CreateRequest(
            requestId,
            member,
            inputRequest,
            assetPricing,
            feePricing
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    function isiData() external {
        coverRequestFullyFundedAt[100] = 100;
    }

    /**
     * @dev Get cover request detail
     */
    function getCoverRequestById(uint256 requestId)
        external
        view
        returns (CoverRequest memory coverRequest)
    {
        return requests[requestId];
    }

    /**
     * @dev Get length of array contains Cover Request(s)
     */
    function getCoverRequestLength() external view returns (uint256) {
        return requests.length;
    }

    /**
     * @dev Save cover offer listing data
     */
    function storedOffer(
        CoverOffer memory inputOffer,
        CoinPricingInfo memory feePricing,
        CoinPricingInfo memory assetPricing,
        uint8 depositPeriod,
        address member
    ) external {
        offers.push(inputOffer);
        uint256 offerId = offers.length - 1;
        funderToOffers[member].push(offerId);
        coinIdToOffers[inputOffer.coinId].push(offerId);
        offerIdToInsuredSumTaken[offerId] = 0; // set insured sum remaining to 0 as initial
        emit CreateOffer(
            offerId,
            member,
            inputOffer,
            feePricing,
            assetPricing,
            depositPeriod
        );
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get detail of Cover Offer
     */
    function getCoverOfferById(uint256 offerId)
        external
        view
        returns (CoverOffer memory coverOffer)
    {
        return offers[offerId];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getCoverOffersListByAddr(address member)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[member];
    }

    /**
     * @dev Get length of array contains Cover Offer(s)
     */
    function getCoverOfferLength() external view returns (uint256) {
        return offers.length;
    }

    /**
     * @dev Called when member take offer to update insured sum taken on Cover Offer
     */
    function updateOfferInsuredSumTaken(
        uint256 offerId,
        uint256 insuredSumTaken
    ) external {
        offerIdToInsuredSumTaken[offerId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when member take request to update insured sum taken on Cover Request
     */
    function updateRequestInsuredSumTaken(
        uint256 requestId,
        uint256 insuredSumTaken
    ) external {
        requestIdToInsuredSumTaken[requestId] = insuredSumTaken;
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Check whether Cover Request reach target
     * @dev For Partial : must reach minimal 25% of insured sum
     * @dev For Full : must react minimal 100% - 2 token of insured sum
     */
    function isRequestReachTarget(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        return
            requestIdToInsuredSumTaken[requestId] >= request.insuredSumTarget;
    }

    /**
     * @dev Check whether Cover Request fully funded
     * @dev Must react minimal 100% - 2 token of insured sum
     */
    function isRequestFullyFunded(uint256 requestId)
        external
        view
        returns (bool)
    {
        CoverRequest memory request = requests[requestId];
        uint8 decimal = cg.getCurrencyDecimal(
            uint8(request.insuredSumCurrency)
        );
        uint256 tolerance = 2 * (10**decimal);

        return
            (request.insuredSum - requestIdToInsuredSumTaken[requestId]) <=
            tolerance;
    }

    /**
     * @dev Called when Cover Request fully funded
     */
    function setCoverRequestFullyFundedAt(
        uint256 requestId,
        uint256 fullyFundedAt
    ) external {
        coverRequestFullyFundedAt[requestId] = fullyFundedAt;
        emit RequestFullyFunded(requestId, fullyFundedAt);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when holder refund premium
     * @dev Refund premium condition :
     * @dev Withdraw premium of fail Cover Request or Withdraw of remaining premium on Cover Request
     */
    function setRequestIdToRefundPremium(uint256 requestId) external {
        requestIdToRefundPremium[requestId] = true;
        emit PremiumRefunded(requestId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit
     * @dev Withdraw of remaining deposit on Cover Offer
     */
    function setDepositOfOfferTakenBack(uint256 offerId) external {
        isDepositOfOfferTakenBack[offerId] = true;
        emit DepositOfOfferTakenBack(offerId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Called when funder refund/take back deposit, to mark deposit had taken
     */
    function setIsDepositTakenBack(uint256 coverId) external {
        isDepositTakenBack[coverId] = true;
        emit DepositTakenBack(coverId);
        // Check the caller is internal address
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
    }

    /**
     * @dev Get list of request id(s) that funded by member
     */
    function getBuyerToRequests(address holder)
        external
        view
        returns (uint256[] memory)
    {
        return buyerToRequests[holder];
    }

    /**
     * @dev Get list of offer id(s) that funded by member/funder
     */
    function getFunderToOffers(address funder)
        external
        view
        returns (uint256[] memory)
    {
        return funderToOffers[funder];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IConfig} from "./IConfig.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Master {
    // Used publicly
    IConfig internal cg;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    // Storage and Payload
    enum CoverType {
        SMART_PROTOCOL_FAILURE,
        STABLECOIN_DEVALUATION,
        CUSTODIAN_FAILURE,
        RUGPULL_LIQUIDITY_SCAM
    }
    enum CurrencyType {
        USDT,
        USDC,
        DAI,
        END_ENUM
    }
    enum InsuredSumRule {
        PARTIAL,
        FULL
    }
    enum ListingType {
        REQUEST,
        OFFER
    }

    enum ClaimState {
        MONITORING,
        INVALID,
        VALID,
        INVALID_AFTER_EXPIRED,
        VALID_AFTER_EXPIRED
    }

    // For passing parameter and store state variables
    struct CoverRequest {
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint8 coverMonths; // represent month value 1-12
        uint256 insuredSum;
        uint256 insuredSumTarget; // if full funding : insuredSum - 2$
        CurrencyType insuredSumCurrency;
        uint256 premiumSum;
        CurrencyType premiumCurrency;
        uint256 expiredAt; // now + 14 days
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address holder; // may validate or not validate if same as msg.sender
    }

    // For passing parameter and store state variables
    struct CoverOffer {
        uint8 minCoverMonths; // represent month value 1-12 (expiredAt + 1 month - now >= minCoverMonths)
        uint256 insuredSum;
        CurrencyType insuredSumCurrency;
        uint256 premiumCostPerMonth; // $0.02 per $1 insured per Month (2000) a.k.a Premium Cost Per month per asset
        CurrencyType premiumCurrency;
        // IMPORTANT: max date for buying cover = expiredAt + 1 month
        uint256 expiredAt; // despositEndDate - 14 days beforeDepositEndDate
        string coinId; // CoinGecko
        CoverLimit coverLimit;
        InsuredSumRule insuredSumRule;
        address funder; // may validate or not validate if same as msg.sender
    }

    // Storage struct
    // Relationship: CoverCoverOffer ||--< Cover
    // Relationship: CoverRequest ||--< Cover
    // Relationship: One cover can have only one offer
    // Relationship: One cover can have only one request
    struct InsuranceCover {
        // type computed from (offerId != 0) or (requestId != 0)

        // If BuyCover (take offer)
        uint256 offerId; // from BuyCover.offerId
        // If CoverFunding (take request)
        uint256 requestId; // from CoverFunding.requestId
        // uint[] provideIds;

        ListingType listingType;
        // will validate claimSender
        address holder; // from BuyCover.buyer or CoverRequest.buyer
        // will validate maximum claimSum
        uint256 insuredSum; // from BuyCover.insuredSum or sum(CoverFunding.fundingSum)
        // will validate maximum claimQuantity
        uint256 coverQty; // from BuyCover.coverQty or CoverRequest.coverQty
    }

    // Storage: "Booking" object when take request
    // Relationship: CoverRequest ||--< CoverFunding
    struct CoverFunding {
        uint256 requestId;
        address funder;
        // insurance data:
        uint256 fundingSum; // part or portion of total insuredSum
    }

    // Payload: object when take offer
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct BuyCover {
        uint256 offerId;
        address buyer;
        // insurance data:
        uint8 coverMonths; // represent month value 1-12
        uint256 coverQty; // coverQty decimals depends on coinIdToDecimals mapping
        uint256 insuredSum; // need validation : coverQty * assetPricing.coinPrice
        CoinPricingInfo assetPricing;
        bytes premiumPermit;
    }

    // Payload: object when take request
    // Virtual struct/type for payload (type of payloadBuyCover)
    struct ProvideCover {
        uint256 requestId;
        address provider;
        // insurance data:
        uint256 fundingSum;
        CoinPricingInfo assetPricing;
        bytes assetPermit;
    }

    // For passing Coin and Listing Fee info, required for validation
    struct CoinPricingInfo {
        string coinId;
        string coinSymbol;
        uint256 coinPrice; // decimals 6
        uint256 lastUpdatedAt;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CoverLimit {
        CoverType coverType;
        uint256[] territoryIds; // Platform Id, Price Feed Id, Custodian Id , (Dex Pool Id not Yet implemented)
    }

    struct Platform {
        string name;
        string website;
    }

    struct Oracle {
        string name;
        string website;
    }

    struct PriceFeed {
        uint256 oracleId;
        uint256 chainId;
        uint8 decimals;
        address proxyAddress;
    }

    struct Custodian {
        string name;
        string website;
    }

    struct EIP2612Permit {
        address owner;
        uint256 value;
        address spender;
        uint256 deadline;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct DAIPermit {
        address holder;
        address spender;
        uint256 nonce;
        uint256 expiry;
        bool allowed;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    struct CreateCoverRequestData {
        CoverRequest request; //
        CoinPricingInfo assetPricing; //
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes premiumPermit; // for transfer DAI, USDT, USDC
    }

    struct CreateCoverOfferData {
        CoverOffer offer; //
        CoinPricingInfo assetPricing;
        uint8 depositPeriod;
        CoinPricingInfo feePricing; //
        uint80 roundId; // insured sum to usd for calculate fee price
        bytes fundingPermit; // for transfer DAI, USDT, USDC
    }

    // Structs
    struct Claim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    struct CollectiveClaim {
        uint80 roundId; // round id that represent start of dropping value
        uint256 claimTime;
        uint256 payout;
        ClaimState state;
    }

    // Modifier
    modifier onlyInternal() {
        require(cg.isInternal(msg.sender), "ERR_AUTH_2");
        _;
    }

    /**
     * @dev change config contract address
     * @param configAddress is the new address
     */
    function changeConfigAddress(address configAddress) external {
        // Only admin allowed to call this function
        if (address(cg) != address(0)) {
            require(
                IAccessControl(address(cg)).hasRole(
                    DEFAULT_ADMIN_ROLE,
                    msg.sender
                ),
                "ERR_AUTH_1"
            );
        }
        // Change config address
        cg = IConfig(configAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IConfig {
    /**
     * @dev return address of Infi Token
     */
    function infiTokenAddr() external returns (address);

    /**
     * @dev return address of contract based on Initial Contract Name
     */
    function getLatestAddress(bytes2 _contractName)
        external
        returns (address payable contractAddress);

    /**
     * @dev check whether caller is internal smart contract
     * @dev internal smart contracts are smart contracts that used on Infi Project
     */
    function isInternal(address _add) external returns (bool);

    /**
     * @dev get decimals of given currency code/number
     */
    function getCurrencyDecimal(uint8 _currencyType)
        external
        view
        returns (uint8);

    /**
     * @dev get name of given currency code/number
     */
    function getCurrencyName(uint8 _currencyType)
        external
        view
        returns (string memory);

    function maxDevaluation() external view returns (uint256);

    function monitoringPeriod() external view returns (uint256);

    function maxPayoutPeriod() external view returns (uint256);

    function validationPreviousPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}