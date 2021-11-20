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

import {ICoverData} from "../Interfaces/ICoverData.sol";
import {IClaimData} from "../Interfaces/IClaimData.sol";
import {IListingData} from "../Interfaces/IListingData.sol";
import {IPlatformData} from "../Interfaces/IPlatformData.sol";
import {ICoverGateway} from "../Interfaces/ICoverGateway.sol";
import {IListingGateway} from "../Interfaces/IListingGateway.sol";
import {IClaimGateway} from "../Interfaces/IClaimGateway.sol";
import {IClaimHelper} from "../Interfaces/IClaimHelper.sol";
import {Master} from "../Master/Master.sol";
import {IPool} from "../Interfaces/IPool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CollectiveClaimGateway is Master {
    // State variables
    ICoverGateway private coverGateway;
    IListingGateway private listingGateway;
    IClaimGateway private claimGateway;
    ICoverData private coverData;
    IClaimData private claimData;
    IListingData private listingData;
    IPlatformData private platformData;
    IClaimHelper private claimHelper;
    IPool private pool;

    event CollectivePremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveRefundPremium(
        address funder,
        uint8 currencyType,
        uint256 totalPremium
    );
    event CollectiveTakeBackDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event CollectiveRefundDeposit(
        address funder,
        uint8 currencyType,
        uint256 totalDeposit
    );
    event ValidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );

    event InvalidCollectiveClaim(uint256 requestId, uint256 collectiveClaimId);

    function changeDependentContractAddress() external {
        // Only admin allowed to call this function
        require(
            IAccessControl(address(cg)).hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERR_AUTH_1"
        );
        coverGateway = ICoverGateway(cg.getLatestAddress("CG"));
        listingGateway = IListingGateway(cg.getLatestAddress("LG"));
        claimGateway = IClaimGateway(cg.getLatestAddress("CL"));
        coverData = ICoverData(cg.getLatestAddress("CD"));
        claimData = IClaimData(cg.getLatestAddress("CM"));
        listingData = IListingData(cg.getLatestAddress("LD"));
        platformData = IPlatformData(cg.getLatestAddress("PD"));
        pool = IPool(cg.getLatestAddress("PL"));
        claimHelper = IClaimHelper(cg.getLatestAddress("CH"));
    }

    /**
     * @dev called by creater of request to make a claim
     */
    function collectiveSubmitClaim(uint256 requestId, uint80 roundId) external {
        // Make sure request is succedd request
        require(coverGateway.isRequestCoverSucceed(requestId), "ERR_CLG_25");

        CoverRequest memory coverRequest = listingData.getCoverRequestById(
            requestId
        );
        // cover must be still active
        uint256 startAt = listingData.isRequestFullyFunded(requestId)
            ? listingData.coverRequestFullyFundedAt(requestId)
            : coverRequest.expiredAt;
        require(
            startAt <= block.timestamp &&
                block.timestamp <=
                (startAt + (uint256(coverRequest.coverMonths) * 30 days)), // end at of request
            "ERR_CLG_3"
        );

        // Check request own by msg.sender
        require(coverRequest.holder == msg.sender, "ERR_CLG_14");

        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnRequest(requestId), "ERR_CLG_4");

        // Cannot use same roundId to submit claim on cover
        require(!claimData.requestIdToRoundId(requestId, roundId), "ERR_CLG_5");
        claimData.setRequestIdToRoundId(requestId, roundId);

        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(requestId).coinId
        );

        // Call aggregator
        (, , , uint256 eventTimestamp, ) = AggregatorV3Interface(priceFeedAddr)
            .getRoundData(roundId);

        // validate timestamp of price feed, time of round id must in range of cover period
        require(
            startAt <= eventTimestamp &&
                eventTimestamp <=
                (startAt + (uint256(coverRequest.coverMonths) * 30 days)),
            "ERR_CLG_6"
        );

        // Check 1 hours before roundId, make sure the devaluation id valid
        require(
            claimHelper.isValidPastDevaluation(priceFeedAddr, roundId),
            "ERR_CLG_7"
        );

        uint256 collectiveClaimId = claimData.addCollectiveClaim(
            requestId,
            roundId,
            eventTimestamp,
            msg.sender
        );

        // + 1 hours is a buffer time
        if (
            (eventTimestamp + cg.monitoringPeriod()) + 1 hours <=
            block.timestamp
        ) {
            _checkValidityAndPayout(collectiveClaimId, priceFeedAddr);
        }
    }

    /**
     * @dev Check validity status of pending claim
     */
    function _checkValidityAndPayout(
        uint256 collectiveClaimId,
        address priceFeedAddr
    ) internal {
        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);

        // For stablecoins devaluation will decided based on oracle
        (bool isClaimValid, uint256 assetPrice, uint8 decimals) = claimHelper
            .checkClaimForDevaluation(priceFeedAddr, collectiveClaim.roundId);
        // Get Cover id
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );

        if (isClaimValid) {
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            // Calculate Payout
            uint256 payout = claimHelper.getPayoutOfRequest(
                requestId,
                coverRequest,
                assetPrice,
                decimals
            );

            require(
                payout <= listingData.requestIdToInsuredSumTaken(requestId),
                "ERR_CLG_10"
            );

            // emit event
            emit ValidCollectiveClaim(
                requestId,
                collectiveClaimId,
                uint8(coverRequest.insuredSumCurrency),
                payout
            );

            // Update total payout of offer request
            claimData.setRequestIdToPayout(requestId, payout);
            // send payout
            pool.transferAsset(
                coverRequest.holder,
                coverRequest.insuredSumCurrency,
                payout
            );
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.VALID
            );
        } else {
            // emit event
            emit InvalidCollectiveClaim(requestId, collectiveClaimId);
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.INVALID
            );
        }
    }

    /**
     * @dev function called by funder that provide on success cover request
     * function will send premium back to funder
     */
    function collectivePremiumForFunder() external {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // mark cover as premium collecter
                coverData.setPremiumCollected(coverId);

                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (totalPremium[j] > 0) {
                // Calcuclate Premium for Provider/Funder (80%) and Dev (20%)
                uint256 premiumToProvider = (totalPremium[j] * 8) / 10;
                uint256 premiumToDev = totalPremium[j] - premiumToProvider;

                // trigger event
                emit CollectivePremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumToProvider
                );

                // Send 80% to Provider/Funder
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumToProvider
                );

                // Send 20% to Dev wallet
                pool.transferAsset(
                    coverGateway.devWallet(),
                    CurrencyType(j),
                    premiumToDev
                );
            }
        }
    }

    /**
     * @dev View function to return value of total amount of premium, amount of withdrawable premium for each stablecoins currency
     */
    function getWithdrawablePremiumData(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawablePremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        // Get list cover id of funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(funderAddr);

        // initialize variable for store total premium for each currency
        uint256[] memory totalPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // loop each cover
        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);

            // only success request cover & premium which not yet collected will be count
            if (
                cover.listingType == ListingType.REQUEST &&
                coverGateway.isRequestCoverSucceed(cover.requestId) &&
                !coverData.isPremiumCollected(coverId)
            ) {
                // increase total premium based on currency type (premium currency)
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                totalPremium[uint8(coverRequest.premiumCurrency)] +=
                    (cover.insuredSum * coverRequest.premiumSum) /
                    coverRequest.insuredSum;
            }
        }

        (totalWithdrawablePremiumInUSD, , usdDecimals) = claimHelper
            .convertPrice(totalPremium, totalPremium);

        return (totalWithdrawablePremiumInUSD, totalPremium, usdDecimals);
    }

    /**
     * @dev return total of premium and total of withdrawable premium
     * called by holder for refund premium from cover request
     */
    function getPremiumDataOfCoverRequest(address holderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockPremiumInUSD,
            uint256[] memory withdrawablePremiumList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawablePremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockPremium = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            holderAddr
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );
            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            if (!listingData.requestIdToRefundPremium(requestId)) {
                if (isRequestCoverSuccedd || isFailRequest) {
                    withdrawablePremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += (
                        isFailRequest
                            ? coverRequest.premiumSum
                            : (((coverRequest.insuredSum -
                                listingData.requestIdToInsuredSumTaken(
                                    requestId
                                )) * coverRequest.premiumSum) /
                                coverRequest.insuredSum)
                    );
                } else {
                    lockPremium[
                        uint8(coverRequest.premiumCurrency)
                    ] += coverRequest.premiumSum;
                }
            }
        }

        (totalWithdrawInUSD, totalLockPremiumInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawablePremium, lockPremium);

        return (
            totalWithdrawInUSD,
            totalLockPremiumInUSD,
            withdrawablePremium,
            usdDecimals
        );
    }

    /**
     * @dev function called by holder of failed cover request
     * @dev function will send premium back to holder
     */
    function collectiveRefundPremium() external {
        // get list of request id that created by holder
        uint256[] memory listRequestIds = listingData.getBuyerToRequests(
            msg.sender
        );
        uint256[] memory premiumWithdrawn = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listRequestIds.length; i++) {
            uint256 requestId = listRequestIds[i];
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            bool isRequestCoverSuccedd = coverGateway.isRequestCoverSucceed(
                requestId
            );

            // fail request is request that not react target and already passing listing expired time
            bool isFailRequest = !listingData.isRequestReachTarget(requestId) &&
                (block.timestamp > coverRequest.expiredAt);

            // only request that
            // not yet refunded & (succedd request or fail request)
            // will count
            if (
                coverRequest.holder == msg.sender &&
                !listingData.requestIdToRefundPremium(requestId) &&
                (isRequestCoverSuccedd || isFailRequest)
            ) {
                // if fail request
                // then increase by CoverRequest.premiumSum a.k.a refund all premium
                // if cover succedd
                // then using formula : (remaining insured sum / insured sum of request) * premium sum
                // a.k.a only refund remaining premim sum
                premiumWithdrawn[uint8(coverRequest.premiumCurrency)] += (
                    isFailRequest
                        ? coverRequest.premiumSum
                        : (((coverRequest.insuredSum -
                            listingData.requestIdToInsuredSumTaken(requestId)) *
                            coverRequest.premiumSum) / coverRequest.insuredSum)
                );

                // mark request as refunded
                listingData.setRequestIdToRefundPremium(requestId);
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (premiumWithdrawn[j] > 0) {
                // emit event
                emit CollectiveRefundPremium(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    premiumWithdrawn[j]
                );
                // transfer asset
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    premiumWithdrawn[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder
     */
    function getDepositDataOfOfferCover(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDepositList,
            uint8 usdDecimals
        )
    {
        uint256[] memory withdrawableDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        // Get List Id of offers
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            funderAddr
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            // Get Offer Id
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            if (!listingData.isDepositOfOfferTakenBack(offerId)) {
                if (
                    block.timestamp > coverOffer.expiredAt &&
                    (coverData.offerIdToLastCoverEndTime(offerId) > 0 &&
                        block.timestamp >
                        coverData.offerIdToLastCoverEndTime(offerId)) &&
                    (claimData.offerToPendingClaims(offerId) == 0)
                ) {
                    // Get Withdrawable Deposit a.k.a deposit that not locked
                    // deduct by by payout
                    withdrawableDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                        coverOffer.insuredSum -
                        claimData.offerIdToPayout(offerId);
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
     * @dev function called by funder which creator of cover offer
     * function will send back deposit to funder
     */
    function collectiveRefundDepositOfCoverOffer() external {
        require(
            !claimHelper.isFunderHasPendingClaims(
                ListingType.OFFER,
                msg.sender
            ),
            "ERR_CLG_21"
        );
        // get list offer id of funder
        uint256[] memory listOfferIds = listingData.getFunderToOffers(
            msg.sender
        );
        uint256[] memory remainingDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );

        for (uint256 i = 0; i < listOfferIds.length; i++) {
            uint256 offerId = listOfferIds[i];
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                offerId
            );

            // only cover offer that
            // passing listing expired time
            // & there is no active cover depend on the offer
            // & not yet take back deposit
            if (
                msg.sender == coverOffer.funder &&
                block.timestamp > coverOffer.expiredAt &&
                (coverData.offerIdToLastCoverEndTime(offerId) == 0 ||
                    block.timestamp >
                    coverData.offerIdToLastCoverEndTime(offerId)) &&
                !listingData.isDepositOfOfferTakenBack(offerId) &&
                (claimData.offerToPendingClaims(offerId) == 0)
            ) {
                // increase total deposit based on currency type (premium currency)
                remainingDeposit[uint8(coverOffer.insuredSumCurrency)] +=
                    coverOffer.insuredSum -
                    claimData.offerIdToPayout(offerId);

                // mark deposit already taken
                listingData.setDepositOfOfferTakenBack(offerId);
            }
        }

        // loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (remainingDeposit[j] > 0) {
                // emit event
                emit CollectiveTakeBackDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    remainingDeposit[j]
                );

                // send deposit
                pool.transferAsset(
                    msg.sender,
                    CurrencyType(j),
                    remainingDeposit[j]
                );
            }
        }
    }

    /**
     * @dev return total of locked deposit and total of withdrawable deposit
     * called by funder for refund deposit on provide cover request
     */
    function getDepositOfProvideCover(address funderAddr)
        external
        view
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockDepositInUSD,
            uint256[] memory withdrawableDeposit,
            uint8 usdDecimals
        )
    {
        withdrawableDeposit = new uint256[](uint8(CurrencyType.END_ENUM));
        uint256[] memory lockDeposit = new uint256[](
            uint8(CurrencyType.END_ENUM)
        );
        uint256[] memory listCoverIds = coverData.getFunderToCovers(funderAddr);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            uint256 coverId = listCoverIds[i];
            InsuranceCover memory cover = coverData.getCoverById(coverId);
            if (
                cover.listingType == ListingType.REQUEST &&
                !listingData.isDepositTakenBack(coverId)
            ) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);
                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(coverId);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);
                // Remaining deposit
                uint256 remainingDeposit = cover.insuredSum -
                    claimData.coverToPayout(coverId);

                if (
                    (coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        !claimHelper.isPendingClaimExistOnCover(coverId) &&
                        (remainingDeposit > 0)) || isCoverRequestFail
                ) {
                    // Get withdrawable deposit
                    withdrawableDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                } else {
                    // Get Lock Deposit deduct by by payout
                    lockDeposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;
                }
            }
        }

        (totalWithdrawInUSD, totalLockDepositInUSD, usdDecimals) = claimHelper
            .convertPrice(withdrawableDeposit, lockDeposit);

        return (
            totalWithdrawInUSD,
            totalLockDepositInUSD,
            withdrawableDeposit,
            usdDecimals
        );
    }

    /**
     * @dev function called by FUNDER which PROVIDE FUND for COVER REQUEST
     * function will send back deposit to funder
     */
    function collectiveRefundDepositOfProvideRequest() external {
        require(
            !claimHelper.isFunderHasPendingClaims(
                ListingType.REQUEST,
                msg.sender
            ),
            "ERR_CLG_21"
        );

        // Initialize variabel for calculate deposit
        uint256[] memory deposit = new uint256[](uint8(CurrencyType.END_ENUM));

        // Get list cover id of which funded by funder
        uint256[] memory listCoverIds = coverData.getFunderToCovers(msg.sender);

        for (uint256 i = 0; i < listCoverIds.length; i++) {
            InsuranceCover memory cover = coverData.getCoverById(
                listCoverIds[i]
            );
            if (cover.listingType == ListingType.REQUEST) {
                // get Cover Request data
                CoverRequest memory coverRequest = listingData
                    .getCoverRequestById(cover.requestId);

                // get expired time of cover
                uint256 coverEndAt = coverGateway.getEndAt(listCoverIds[i]);
                // Cover Request is fail when request not reaching target & already passing listing expired time
                bool isCoverRequestFail = !listingData.isRequestReachTarget(
                    cover.requestId
                ) && (block.timestamp > coverRequest.expiredAt);

                // Calculate payout for cover & Remaining deposit
                // Payout for the cover = Payout for request * cover.insuredSum / Insured Sum Taken
                uint256 coverToPayout = (claimData.requestIdToPayout(
                    cover.requestId
                ) * cover.insuredSum) /
                    listingData.requestIdToInsuredSumTaken(cover.requestId);
                // Remaining deposit = Insured Sum - payout for the cover
                uint256 remainingDeposit = cover.insuredSum - coverToPayout;

                // caller must be a funder of the cover
                // deposit not taken back yet
                // there is NO pending claims on the cover
                // ((succedd cover request that passing expired cover time and doesnlt have valid claim) or fail request)
                if (
                    coverData.isFunderOfCover(msg.sender, listCoverIds[i]) &&
                    !listingData.isDepositTakenBack(listCoverIds[i]) &&
                    (claimData.coverToPendingClaims(listCoverIds[i]) == 0) &&
                    ((coverGateway.isRequestCoverSucceed(cover.requestId) &&
                        coverEndAt < block.timestamp &&
                        (remainingDeposit > 0)) || isCoverRequestFail)
                ) {
                    // increase total deposit based on currency type (premium currency)
                    deposit[
                        uint8(coverRequest.insuredSumCurrency)
                    ] += remainingDeposit;

                    // mark cover as desposit already taken back
                    listingData.setIsDepositTakenBack(listCoverIds[i]);

                    // Set Payout for cover
                    claimData.setCoverToPayout(listCoverIds[i], coverToPayout);
                }
            }
        }

        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            if (deposit[j] > 0) {
                // emit event
                emit CollectiveRefundDeposit(
                    msg.sender,
                    uint8(CurrencyType(j)),
                    deposit[j]
                );
                // send deposit
                pool.transferAsset(msg.sender, CurrencyType(j), deposit[j]);
            }
        }
    }

    /**
     * @dev Called by insurance holder for check claim status over cover, that cover come from take request
     */
    function checkPayout(uint256 collectiveClaimId) external {
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );
        // make sure there is no valid claim
        require(!claimData.isValidClaimExistOnRequest(requestId), "ERR_CLG_4");

        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);
        // Price feed aggregator
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(
            listingData.getCoverRequestById(requestId).coinId
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Call aggregator
        (, , uint256 startedAt, , ) = priceFeed.getRoundData(
            collectiveClaim.roundId
        );
        require(
            ((startedAt + cg.monitoringPeriod()) + 1 hours) < block.timestamp,
            "ERR_CLG_8"
        );
        // Check status of collective claim , must still on monitoring
        require(collectiveClaim.state == ClaimState.MONITORING, "ERR_CLG_26");
        require(
            block.timestamp <=
                (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod()),
            "ERR_CLG_9"
        );

        _checkValidityAndPayout(collectiveClaimId, priceFeedAddr);
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