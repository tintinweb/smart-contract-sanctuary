// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ICoverData} from "../Interfaces/ICoverData.sol";
import {IClaimData} from "../Interfaces/IClaimData.sol";
import {IListingData} from "../Interfaces/IListingData.sol";
import {IPlatformData} from "../Interfaces/IPlatformData.sol";
import {ICoverGateway} from "../Interfaces/ICoverGateway.sol";
import {IListingGateway} from "../Interfaces/IListingGateway.sol";
import {IClaimGateway} from "../Interfaces/IClaimGateway.sol";
import {IPool} from "../Interfaces/IPool.sol";
import {IClaimHelper} from "../Interfaces/IClaimHelper.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract ClaimGateway is IClaimGateway, Pausable {
    // State variables
    ICoverGateway public coverGateway;
    IListingGateway public listingGateway;
    ICoverData public coverData;
    IClaimData public claimData;
    IListingData public listingData;
    IPlatformData public platformData;
    IPool public pool;
    IClaimHelper public claimHelper;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;

    // Events
    event CollectPremium(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event RefundPremium(
        uint256 requestId,
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event TakeBackDeposit(
        uint256 offerId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event RefundDeposit(
        uint256 requestId,
        uint256 coverId,
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event ValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    event InvalidClaim(uint256 coverId, uint256 claimId);
    // Dev withdraw expired payout
    event WithdrawExpiredPayout(
        address devWallet,
        uint8 currencyType,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );

        coverGateway = ICoverGateway(cg.getLatestAddress("CG"));
        listingGateway = IListingGateway(cg.getLatestAddress("LG"));
        coverData = ICoverData(cg.getLatestAddress("CD"));
        claimData = IClaimData(cg.getLatestAddress("CM"));
        listingData = IListingData(cg.getLatestAddress("LD"));
        platformData = IPlatformData(cg.getLatestAddress("PD"));
        pool = IPool(cg.getLatestAddress("PL"));
        claimHelper = IClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev Called when member make claim over cover, that cover come from take offer
     * @param coverId id of cover
     * @param roundId number attribute from subgraph
     */
    function submitClaim(uint256 coverId, uint80 roundId)
        external
        whenNotPaused
    {
        // msg.sender must cover's owner
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        require(cover.holder == msg.sender, "ERR_CLG_1");

        // Only accept coverId that coming from taje offer
        require(cover.listingType == ListingType.OFFER, "ERR_CLG_27");

        // get startAt & endAt of Cover
        uint256 startAt = coverGateway.getStartAt(coverId);
        uint256 endAt = coverGateway.getEndAt(coverId);

        // cover must start
        require(startAt != 0, "ERR_CLG_2");

        // cover must be still active
        require(
            startAt <= block.timestamp && block.timestamp <= endAt,
            "ERR_CLG_3"
        );

        // Make sure there is no valid claim
        // Limit only able to make 1 valid claim &$ cannot make multiple valid claim
        require(!claimData.isValidClaimExistOnCover(coverId), "ERR_CLG_4");

        // Cannot use same roundId to submit claim on cover
        require(!claimData.coverIdToRoundId(coverId, roundId), "ERR_CLG_5");

        // Update Cover to roundId
        claimData.setCoverIdToRoundId(coverId, roundId);

        // Price feed aggregator
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Call aggregator
        (, , , uint256 eventTimestamp, ) = priceFeed.getRoundData(roundId);

        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp && eventTimestamp <= endAt,
            "ERR_CLG_6"
        );

        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, roundId),
            "ERR_CLG_7"
        );

        // add filing claim
        uint256 claimId = claimData.addClaim(
            coverId,
            cover.offerId,
            roundId,
            eventTimestamp,
            msg.sender
        );

        // + 1 hours is a buffer time
        if (
            (eventTimestamp + cg.monitoringPeriod()) + 1 hours <=
            block.timestamp
        ) {
            // Check validity and make payout
            _checkValidityAndPayout(claimId, priceFeedAddr);
        }
    }

    /**
     * @dev Called by insurance holder for check claim status over cover, that cover come from take offer
     */
    function checkPayout(uint256 claimId) external override whenNotPaused {
        uint256 coverId = claimData.claimToCover(claimId);

        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnCover(coverId), "ERR_CLG_4");

        Claim memory claim = claimData.getClaimById(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        // Price feed aggregator
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        // Call aggregator
        (, , uint256 startedAt, , ) = AggregatorV3Interface(priceFeedAddr)
            .getRoundData(claim.roundId);

        require(
            ((startedAt + cg.monitoringPeriod()) + 1 hours) < block.timestamp,
            "ERR_CLG_8"
        );

        require(
            block.timestamp <=
                (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod()),
            "ERR_CLG_9"
        );

        _checkValidityAndPayout(claimId, priceFeedAddr);
    }

    /**
     * @dev Check validity status of pending claim
     */
    function _checkValidityAndPayout(uint256 claimId, address priceFeedAddr)
        internal
    {
        Claim memory claim = claimData.getClaimById(claimId);

        // For stablecoins devaluation will decided based on oracle
        (bool isClaimValid, uint256 assetPrice, uint8 decimals) = claimHelper
            .checkClaimForDevaluation(priceFeedAddr, claim.roundId);

        // Get Cover id
        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        if (isClaimValid) {
            // Calculate Payout
            uint256 payout = claimHelper.getPayoutOfCover(
                cover,
                assetPrice,
                decimals
            );

            // Get cover offer
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                cover.offerId
            );

            // emit event
            emit ValidClaim(
                coverId,
                claimId,
                uint8(coverOffer.insuredSumCurrency),
                payout
            );

            require(
                claimData.coverToPayout(coverId) + payout <= cover.insuredSum,
                "ERR_CLG_10"
            );

            // Set cover to payout
            claimData.setCoverToPayout(coverId, payout);
            // Update total payout of offer cover
            claimData.setOfferIdToPayout(cover.offerId, payout);

            // send payout
            pool.transferAsset(
                cover.holder,
                coverOffer.insuredSumCurrency,
                payout
            );

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.VALID
            );
        } else {
            // emit event
            emit InvalidClaim(coverId, claimId);

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.INVALID
            );
        }
    }

    /**
     * @dev will only be able to call by funders of cover request to collect premium from holder
     */
    function collectPremiumOfRequestByFunder(uint256 coverId)
        external
        override
        whenNotPaused
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // Make sure cover coming from provide request
        require(cover.listingType == ListingType.REQUEST, "ERR_CLG_11");
        // check if request is fully funded or (reach target and passing expired date)
        require(
            coverGateway.isRequestCoverSucceed(cover.requestId),
            "ERR_CLG_2"
        );

        // check if msg.sender is funder of cover
        require(coverData.isFunderOfCover(msg.sender, coverId), "ERR_CLG_12");

        // check if funder already collect premium for request
        require(!coverData.isPremiumCollected(coverId), "ERR_CLG_13");

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );

        // calculate premium for funder
        // formula : (fund provide by funder / insured sum of request) * premium sum
        uint256 totalPremium = (cover.insuredSum * coverRequest.premiumSum) /
            coverRequest.insuredSum;

        // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
        uint256 premiumToProvider = (totalPremium * 8) / 10;
        uint256 premiumToDev = totalPremium - premiumToProvider;

        // trigger event
        emit CollectPremium(
            cover.requestId,
            coverId,
            msg.sender,
            uint8(coverRequest.premiumCurrency),
            premiumToProvider
        );

        // mark funder as premium collectors
        coverData.setPremiumCollected(coverId);

        // Send 80% to Provider/Funder
        pool.transferAsset(
            msg.sender,
            coverRequest.premiumCurrency,
            premiumToProvider
        );
        // Send 20% to Dev wallet
        pool.transferAsset(
            coverGateway.devWallet(),
            coverRequest.premiumCurrency,
            premiumToDev
        );
    }

    /**
     * @dev only be able to call by holder to refund premium on Cover Request
     */
    function refundPremium(uint256 requestId) external override whenNotPaused {
        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            requestId
        );

        // only creator of request
        require(coverRequest.holder == msg.sender, "ERR_CLG_14");

        // check if already refund premium
        require(!listingData.requestIdToRefundPremium(requestId), "ERR_CLG_15");

        // check whethers request if success or fail
        // if request success & fully funded (either FULL FUNDING or PARTIAL FUNDING)
        // only the remaining premiumSum can be withdrawn
        // if request success & partiallly funded & time passing expired listing
        // only the remaining premiumSum can be withdrawn
        // if request unsuccessful & time passing expired listing
        // withdrawn all premium sum
        uint256 premiumWithdrawn;
        if (coverGateway.isRequestCoverSucceed(requestId)) {
            // withdraw remaining premium
            // formula : (remaining insured sum / insured sum of request) * premium sum
            premiumWithdrawn =
                ((coverRequest.insuredSum -
                    listingData.requestIdToInsuredSumTaken(requestId)) *
                    coverRequest.premiumSum) /
                coverRequest.insuredSum;
        } else if (
            !listingData.isRequestReachTarget(requestId) &&
            (block.timestamp > coverRequest.expiredAt)
        ) {
            // fail request, cover request creator will be able to refund all premium
            premiumWithdrawn = coverRequest.premiumSum;
        } else {
            // can be caused by request not fullfil criteria to start cover
            // and not yet reach expired time
            revert("ERR_CLG_16");
        }

        if (premiumWithdrawn != 0) {
            // emit event
            emit RefundPremium(
                requestId,
                msg.sender,
                uint8(coverRequest.premiumCurrency),
                premiumWithdrawn
            );

            // mark the request has been refunded
            listingData.setRequestIdToRefundPremium(requestId);

            // transfer asset
            pool.transferAsset(
                msg.sender,
                coverRequest.premiumCurrency,
                premiumWithdrawn
            );
        } else {
            revert("ERR_CLG_17");
        }
    }

    /**
     * @dev will be call by funder of offer cover will send back deposit that funder already spend for offer cover
     */
    function takeBackDepositOfCoverOffer(uint256 offerId)
        external
        override
        whenNotPaused
    {
        CoverOffer memory coverOffer = listingData.getCoverOfferById(offerId);
        // must call by funder/creator of offer cover
        require(msg.sender == coverOffer.funder, "ERR_CLG_18");

        // current time must passing lockup period
        require(block.timestamp > coverOffer.expiredAt, "ERR_CLG_19");

        // check is there any cover that still depend on this one
        require(
            coverData.offerIdToLastCoverEndTime(offerId) > 0 &&
                block.timestamp > coverData.offerIdToLastCoverEndTime(offerId),
            "ERR_CLG_20"
        );

        // check is pending claim exists
        require(claimData.offerToPendingClaims(offerId) == 0, "ERR_CLG_21");

        // check if already take back deposit
        require(!listingData.isDepositOfOfferTakenBack(offerId), "ERR_CLG_22");

        // check remaining deposit
        uint256 remainingDeposit = coverOffer.insuredSum -
            claimData.offerIdToPayout(offerId);

        if (remainingDeposit > 0) {
            // emit event
            emit TakeBackDeposit(
                offerId,
                msg.sender,
                uint8(coverOffer.insuredSumCurrency),
                remainingDeposit
            );

            // mark deposit already taken
            listingData.setDepositOfOfferTakenBack(offerId);

            // send remaining deposit
            pool.transferAsset(
                msg.sender,
                coverOffer.insuredSumCurrency,
                remainingDeposit
            );
        } else {
            revert("ERR_CLG_24");
        }
    }

    /**
     * @dev will be call by funder that provide a cover request will send back deposit that funder already spend for a cover request
     */
    function refundDepositOfProvideCover(uint256 coverId)
        external
        override
        whenNotPaused
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // cover must be coming from provide request
        require(cover.listingType == ListingType.REQUEST, "ERR_CLG_24");
        // check if msg.sender is funders of request
        require(coverData.isFunderOfCover(msg.sender, coverId), "ERR_CLG_12");
        // check if already take back deposit
        require(!listingData.isDepositTakenBack(coverId), "ERR_CLG_22");

        // check is there any pending claims on Cover Request
        require(
            claimData.requestToPendingCollectiveClaims(cover.requestId) == 0,
            "ERR_CLG_21"
        );

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            cover.requestId
        );
        uint256 coverEndAt = coverGateway.getEndAt(coverId);

        // Cover Request is fail when request not reaching target & already passing listing expired time
        bool isCoverRequestFail = !listingData.isRequestReachTarget(
            cover.requestId
        ) && (block.timestamp > coverRequest.expiredAt);

        // Calculate payout for cover & Remaining deposit
        // Payout for the cover = Payout for request * cover.insuredSum / Insured Sum Taken
        uint256 coverToPayout = (claimData.requestIdToPayout(cover.requestId) *
            cover.insuredSum) /
            listingData.requestIdToInsuredSumTaken(cover.requestId);
        // Remaining deposit = Insured Sum - payout for the cover
        uint256 remainingDeposit = cover.insuredSum - coverToPayout;

        // If ( cover request succedd & cover already expired & there is remaining deposit )
        // or cover request fail
        // then able to refund all funding
        // Otherwise cannot do refund
        if (
            (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                coverEndAt < block.timestamp &&
                (remainingDeposit > 0)) || isCoverRequestFail
        ) {
            // emit event
            emit RefundDeposit(
                cover.requestId,
                coverId,
                msg.sender,
                uint8(coverRequest.insuredSumCurrency),
                remainingDeposit
            );

            // mark cover as desposit already taken back
            listingData.setIsDepositTakenBack(coverId);

            // Set Cover Payout
            claimData.setCoverToPayout(coverId, coverToPayout);

            // send deposit
            pool.transferAsset(
                msg.sender,
                coverRequest.insuredSumCurrency,
                remainingDeposit
            );
        } else {
            revert("ERR_CLG_25");
        }
    }

    /**
     * @dev Only be able called by Developer to withdraw Valid Expired Payout
     */
    function withdrawExpiredPayout() external override whenNotPaused {
        // Only dev wallet address can call function
        require(msg.sender == cg.getLatestAddress("DW"), "ERR_AUTH_3");

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint256 amount = claimData.totalExpiredPayout(CurrencyType(j));
            if (amount > 0) {
                // Change the value
                claimData.resetTotalExpiredPayout(CurrencyType(j));
                // transfer
                pool.transferAsset(
                    cg.getLatestAddress("DW"),
                    CurrencyType(j),
                    amount
                );
                // Emit event
                emit WithdrawExpiredPayout(
                    cg.getLatestAddress("DW"),
                    uint8(CurrencyType(j)),
                    amount
                );
            }
        }
    }

    /**
     * @dev Check all pending claims over Cover based on Cover listing type and Funder
     */
    function validateAllPendingClaims(ListingType listingType, address funder)
        external
        override
    {
        // get list of listing id
        uint256[] memory listingIds = (listingType == ListingType.OFFER)
            ? listingData.getFunderToOffers(funder)
            : coverData.getFunderToRequestId(funder);

        // Loop and Validate expired pending claims on every listing id
        for (uint256 i = 0; i < listingIds.length; i++) {
            claimHelper.execExpiredPendingClaims(listingType, listingIds[i]);
        }
    }

    /**
     * @dev Check all pending claims over Cover based on Cover listing type and listing id(Cover Request Id/ Cover Offer Id)
     */
    function validatePendingClaims(ListingType listingType, uint256 listingId)
        external
        override
        whenNotPaused
    {
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaims(listingType, listingId);
    }

    /**
     * @dev Check pending claims over Cover
     */
    function validatePendingClaimsByCover(uint256 coverId) external override {
        // Get Cover
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        // Price feed aggregator address
        address priceFeedAddr = claimHelper.getPriceFeedAddress(cover);
        // Validate expired pending claims
        claimHelper.execExpiredPendingClaimsByCoverId(priceFeedAddr, coverId);
    }

    /**
     * @dev Check pending claims by claim id
     */
    function validatePendingClaimsById(uint256 claimId)
        external
        override
        whenNotPaused
    {
        // Validate expired pending claims
        claimHelper.checkValidityClaim(claimId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IClaimData is Master {
    // State Variables but treat as a view functions

    function requestIdToRoundId(uint256, uint80)
        external
        view
        virtual
        returns (bool);

    function totalExpiredPayout(CurrencyType)
        external
        view
        virtual
        returns (uint256);

    function isValidClaimExistOnRequest(uint256)
        external
        view
        virtual
        returns (bool);

    function requestIdToPayout(uint256) external view virtual returns (uint256);

    function offerIdToPayout(uint256) external view virtual returns (uint256);

    function offerToPendingClaims(uint256)
        external
        view
        virtual
        returns (uint16);

    function coverIdToRoundId(uint256, uint80)
        external
        view
        virtual
        returns (bool);

    function isValidClaimExistOnCover(uint256)
        external
        view
        virtual
        returns (bool);

    function collectiveClaimToRequest(uint256)
        external
        view
        virtual
        returns (uint256);

    function coverToPendingClaims(uint256)
        external
        view
        virtual
        returns (uint16);

    function requestToPendingCollectiveClaims(uint256)
        external
        view
        virtual
        returns (uint16);

    function claimToCover(uint256) external view virtual returns (uint256);

    function coverToPayout(uint256) external view virtual returns (uint256);

    // Functions

    function addClaim(
        uint256 coverId,
        uint256 offerId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external virtual returns (uint256);

    function setCoverToPayout(uint256 coverId, uint256 payout) external virtual;

    function setOfferIdToPayout(uint256 offerId, uint256 payout)
        external
        virtual;

    function getCoverToClaims(uint256 coverId)
        external
        view
        virtual
        returns (uint256[] memory);

    function setCoverIdToRoundId(uint256 coverId, uint80 roundId)
        external
        virtual;

    function updateClaimState(
        uint256 claimId,
        uint256 offerId,
        ClaimState state
    ) external virtual;

    function getClaimById(uint256 claimId)
        external
        view
        virtual
        returns (Claim memory);

    function addCollectiveClaim(
        uint256 requestId,
        uint80 roundId,
        uint256 roundTimestamp,
        address holder
    ) external virtual returns (uint256);

    function setRequestIdToRoundId(uint256 requestId, uint80 roundId)
        external
        virtual;

    function setIsValidClaimExistOnRequest(uint256 requestId) external virtual;

    function updateCollectiveClaimState(
        uint256 collectiveClaimId,
        ClaimState state
    ) external virtual;

    function setRequestIdToPayout(uint256 requestId, uint256 payout)
        external
        virtual;

    function getCollectiveClaimById(uint256 collectiveClaimId)
        external
        view
        virtual
        returns (CollectiveClaim memory);

    function addTotalExpiredPayout(CurrencyType currencyType, uint256 amount)
        external
        virtual;

    function resetTotalExpiredPayout(CurrencyType currencyType)
        external
        virtual;

    function getRequestToCollectiveClaims(uint256 requestId)
        external
        view
        virtual
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IClaimGateway is Master {
    function checkPayout(uint256 claimId) external virtual;

    function collectPremiumOfRequestByFunder(uint256 coverId) external virtual;

    function refundPremium(uint256 requestId) external virtual;

    function takeBackDepositOfCoverOffer(uint256 offerId) external virtual;

    function refundDepositOfProvideCover(uint256 coverId) external virtual;

    function withdrawExpiredPayout() external virtual;

    function validateAllPendingClaims(ListingType listingType, address funder)
        external
        virtual;

    function validatePendingClaims(ListingType listingType, uint256 listingId)
        external
        virtual;

    function validatePendingClaimsByCover(uint256 coverId) external virtual;

    function validatePendingClaimsById(uint256 claimId) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IClaimHelper is Master {
    function getPriceFeedAddress(InsuranceCover memory cover)
        public
        view
        virtual
        returns (address priceFeedAddr);

    function isValidPastDevaluation(address priceFeedAddr, uint80 roundId)
        external
        view
        virtual
        returns (bool isValidDevaluation);

    function getPayoutOfCover(
        InsuranceCover memory cover,
        uint256 assetPrice,
        uint8 decimals
    ) public view virtual returns (uint256);

    function execExpiredPendingClaims(ListingType listingType, uint256 id)
        external
        virtual;

    function execExpiredPendingClaimsByCoverId(
        address priceFeedAddr,
        uint256 coverId
    ) public virtual;

    function checkValidityClaim(uint256 claimId) external virtual;

    function getPayoutOfRequest(
        uint256 requestId,
        CoverRequest memory coverRequest,
        uint256 assetPrice,
        uint8 decimals
    ) public view virtual returns (uint256);

    function isFunderHasPendingClaims(
        ListingType listingType,
        address funderAddr
    ) external view virtual returns (bool state);

    function isPendingClaimExistOnCover(uint256 coverId)
        external
        view
        virtual
        returns (bool statePendingClaimExists);

    function checkClaimForDevaluation(address aggregatorAddress, uint80 roundId)
        public
        view
        virtual
        returns (
            bool isValidClaim,
            uint256 assetPrice,
            uint8 decimals
        );

    function convertPrice(uint256[] memory withdrawable, uint256[] memory lock)
        external
        view
        virtual
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockInUSD,
            uint8 usdDecimals
        );
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

import {Master} from "../Master/Master.sol";

abstract contract ICoverData is Master {
    function isPremiumCollected(uint256) external view virtual returns (bool);

    function coverIdToCoverMonths(uint256)
        external
        view
        virtual
        returns (uint8);

    function insuranceCoverStartAt(uint256)
        external
        view
        virtual
        returns (uint256);

    function isFunderOfCover(address, uint256)
        external
        view
        virtual
        returns (bool);

    function offerIdToLastCoverEndTime(uint256)
        external
        view
        virtual
        returns (uint256);

    function storeCoverByTakeOffer(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external virtual;

    function storeBookingByTakeRequest(CoverFunding memory booking)
        external
        virtual;

    function storeCoverByTakeRequest(
        InsuranceCover memory cover,
        uint8 coverMonths,
        address funder
    ) external virtual;

    function getCoverById(uint256 coverId)
        external
        view
        virtual
        returns (InsuranceCover memory cover);

    function getBookingById(uint256 bookingId)
        external
        view
        virtual
        returns (CoverFunding memory coverFunding);

    function getCoverMonths(uint256 coverId)
        external
        view
        virtual
        returns (uint8);

    function getCoversByOfferId(uint256 offerId)
        external
        view
        virtual
        returns (uint256[] memory);

    function getFunderToCovers(address member)
        external
        view
        virtual
        returns (uint256[] memory);

    function setPremiumCollected(uint256 coverId) external virtual;

    function getCoversByRequestId(uint256 requestId)
        external
        view
        virtual
        returns (uint256[] memory);

    function getFunderToRequestId(address funder)
        external
        view
        virtual
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

abstract contract ICoverGateway is Master {
    function devWallet() external virtual returns (address);

    function buyCover(BuyCover calldata buyCoverData) external virtual;

    function provideCover(ProvideCover calldata provideCoverData)
        external
        virtual;

    function isRequestCoverSucceed(uint256 requestId)
        external
        view
        virtual
        returns (bool state);

    function getStartAt(uint256 coverId)
        external
        view
        virtual
        returns (uint256 startAt);

    function getEndAt(uint256 coverId)
        external
        view
        virtual
        returns (uint256 endAt);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

abstract contract IListingData is Master {
    function requestIdToInsuredSumTaken(uint256)
        external
        view
        virtual
        returns (uint256);

    function coverRequestFullyFundedAt(uint256)
        external
        view
        virtual
        returns (uint256);

    function requestIdToRefundPremium(uint256)
        external
        view
        virtual
        returns (bool);

    function isDepositTakenBack(uint256) external view virtual returns (bool);

    function offerIdToInsuredSumTaken(uint256)
        external
        view
        virtual
        returns (uint256);

    function isDepositOfOfferTakenBack(uint256)
        external
        view
        virtual
        returns (bool);

    function storedRequest(
        CoverRequest memory inputRequest,
        CoinPricingInfo memory assetPricing,
        CoinPricingInfo memory feePricing,
        address member
    ) external virtual;

    function getCoverRequestById(uint256 requestId)
        external
        view
        virtual
        returns (CoverRequest memory coverRequest);

    function getCoverRequestLength() external view virtual returns (uint256);

    function storedOffer(
        CoverOffer memory inputOffer,
        CoinPricingInfo memory feePricing,
        CoinPricingInfo memory assetPricing,
        uint8 depositPeriod,
        address member
    ) external virtual;

    function getCoverOfferById(uint256 offerId)
        external
        view
        virtual
        returns (CoverOffer memory offer);

    function getCoverOffersListByAddr(address member)
        external
        view
        virtual
        returns (uint256[] memory);

    function getCoverOfferLength() external view virtual returns (uint256);

    function updateOfferInsuredSumTaken(
        uint256 offerId,
        uint256 insuredSumTaken
    ) external virtual;

    function updateRequestInsuredSumTaken(
        uint256 requestId,
        uint256 insuredSumTaken
    ) external virtual;

    function isRequestReachTarget(uint256 requestId)
        external
        view
        virtual
        returns (bool);

    function isRequestFullyFunded(uint256 requestId)
        external
        view
        virtual
        returns (bool);

    function setCoverRequestFullyFundedAt(
        uint256 requestId,
        uint256 fullyFundedAt
    ) external virtual;

    function setRequestIdToRefundPremium(uint256 requestId) external virtual;

    function setDepositOfOfferTakenBack(uint256 offerId) external virtual;

    function setIsDepositTakenBack(uint256 coverId) external virtual;

    function getBuyerToRequests(address holder)
        external
        view
        virtual
        returns (uint256[] memory);

    function getFunderToOffers(address funder)
        external
        view
        virtual
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

abstract contract IListingGateway is Master {
    function createCoverRequest(
        address from,
        uint256 value,
        bytes memory payData
    ) external virtual;

    function createCoverOffer(
        address from,
        uint256 value,
        bytes memory payData
    ) external virtual;

    function getListActiveCoverOffer()
        external
        view
        virtual
        returns (uint256 listLength, uint256[] memory coverOfferIds);

    function getInsuredSumTakenOfCoverOffer(uint256 coverOfferId)
        external
        view
        virtual
        returns (uint256 insuredSumTaken);

    function getChainlinkPrice(uint8 currencyType)
        external
        view
        virtual
        returns (
            uint80 roundId,
            int256 price,
            uint8 decimals
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IPlatformData is Master {
    function getOraclePriceFeedAddress(string calldata symbol)
        external
        view
        virtual
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Master} from "../Master/Master.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
abstract contract IPool is Master {
    function transferAndBurnInfi(uint256 listingFee) external virtual;

    function getListingFee(
        CurrencyType insuredSumCurrency,
        uint256 insuredSum,
        uint256 feeCoinPrice,
        uint80 roundId
    ) external view virtual returns (uint256);

    function acceptAsset(
        address from,
        CurrencyType currentyType,
        uint256 amount,
        bytes memory premiumPermit
    ) external virtual;

    function transferAsset(
        address to,
        CurrencyType currentyType,
        uint256 amount
    ) external virtual;

    function verifyMessage(CoinPricingInfo memory coinPricing, address whose)
        external
        view
        virtual;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IConfig} from "../Interfaces/IConfig.sol";
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