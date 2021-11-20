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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ICoverData} from "../Interfaces/ICoverData.sol";
import {IClaimData} from "../Interfaces/IClaimData.sol";
import {IListingData} from "../Interfaces/IListingData.sol";
import {IPlatformData} from "../Interfaces/IPlatformData.sol";
import {ICoverGateway} from "../Interfaces/ICoverGateway.sol";
import {IListingGateway} from "../Interfaces/IListingGateway.sol";
import {IClaimHelper} from "../Interfaces/IClaimHelper.sol";
import {IPool} from "../Interfaces/IPool.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ClaimHelper is IClaimHelper {
    // State variables
    ICoverGateway public coverGateway;
    IListingGateway public listingGateway;
    ICoverData public coverData;
    IClaimData public claimData;
    IListingData public listingData;
    IPlatformData public platformData;
    IPool public pool;
    uint256 private constant PHASE_OFFSET = 64;
    uint256 private constant STABLECOINS_STANDARD_PRICE = 1;

    // Events
    // Indicate there is a fund from expired claim payout that can be owned by platform/dev
    event ExpiredValidClaim(
        uint256 coverId,
        uint256 claimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    // Indicate there the fund from expired claim payout still belongs to funder
    event ExpiredInvalidClaim(uint256 coverId, uint256 claimId);

    event ExpiredValidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId,
        uint8 payoutCurrency,
        uint256 totalPayout
    );
    event ExpiredInvalidCollectiveClaim(
        uint256 requestId,
        uint256 collectiveClaimId
    );

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
    }

    /**
     * @dev Calculate payout amount of Cover (in case member create claim)
     */
    function getPayoutOfCover(
        InsuranceCover memory cover,
        uint256 assetPrice,
        uint8 decimals
    ) public view override returns (uint256) {
        require(cover.listingType == ListingType.OFFER, "ERR_CLG_27");

        uint8 insuredSumCurrencyDecimals = cg.getCurrencyDecimal(
            uint8(
                listingData.getCoverOfferById(cover.offerId).insuredSumCurrency
            )
        );

        return
            calculatePayout(
                cover.insuredSum,
                insuredSumCurrencyDecimals,
                assetPrice,
                decimals
            );
    }

    function getPayoutOfRequest(
        uint256 requestId,
        CoverRequest memory coverRequest,
        uint256 assetPrice,
        uint8 decimals
    ) public view override returns (uint256) {
        uint8 insuredSumCurrencyDecimals = cg.getCurrencyDecimal(
            uint8(coverRequest.insuredSumCurrency)
        );

        return
            calculatePayout(
                listingData.requestIdToInsuredSumTaken(requestId),
                insuredSumCurrencyDecimals,
                assetPrice,
                decimals
            );
    }

    function calculatePayout(
        uint256 insuredSum,
        uint8 insuredSumCurrencyDecimals,
        uint256 assetPrice,
        uint8 decimals
    ) internal pure returns (uint256) {
        uint256 devaluationPerAsset = (STABLECOINS_STANDARD_PRICE *
            (10**decimals)) - uint256(assetPrice);

        // Get payout in USD : insured sum * asset devaluation
        uint256 payoutInUSD = (insuredSum * devaluationPerAsset) /
            (10**insuredSumCurrencyDecimals);
        // Convert payout in USD to insured sum currency
        uint256 payout = (payoutInUSD * (10**insuredSumCurrencyDecimals)) /
            assetPrice;

        return payout;
    }

    /**
     * @dev Generate Round Id (using chainlinks formula)
     */
    function getRoundId(uint16 phase, uint64 originalId)
        public
        pure
        returns (uint80)
    {
        return uint80((uint256(phase) << PHASE_OFFSET) | originalId);
    }

    /**
     * @dev Split round id to phase id & aggregator round id
     */
    function parseIds(uint256 roundId) public pure returns (uint16, uint64) {
        uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(roundId);

        return (phaseId, aggregatorRoundId);
    }

    /**
     * @dev Find out median price based on round id (price feed from chainlink)
     * @dev Called when member check claim status\
     * @dev using weighted median formula
     */
    function getMedian(address priceFeedAddr, uint80 startRoundId)
        public
        view
        returns (uint256 medianPrice, uint8 decimals)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 startOriginalRoundId) = parseIds(startRoundId);

        // Get Latest Round
        (, , uint256 timestampOfLatestRound, , ) = priceFeed.latestRoundData();

        // Get Event Round
        (, , uint256 timestampOfEvent, , ) = priceFeed.getRoundData(
            startRoundId
        );

        require(
            timestampOfEvent + cg.monitoringPeriod() < timestampOfLatestRound,
            "ERR_CLG_8"
        );

        // Initial Value
        uint64 currentOriginalRoundId = startOriginalRoundId;
        uint256[] memory priceArr = new uint256[](72 * 3);
        uint256[] memory timestampArr = new uint256[](72 * 3);
        uint256 startedAtTemp = timestampOfEvent;

        while (startedAtTemp <= timestampOfEvent + cg.monitoringPeriod()) {
            // Get Price
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, currentOriginalRoundId)
            );

            require(timestamp > 0, "ERR_CHNLNK_1");

            // update parameter value of loop
            startedAtTemp = timestamp;

            // Save value to array
            priceArr[(currentOriginalRoundId - startOriginalRoundId)] = uint256(
                price
            );
            timestampArr[
                (currentOriginalRoundId - startOriginalRoundId)
            ] = timestamp;

            // increment
            currentOriginalRoundId += 1;
        }

        // Initial Array for time diff
        uint256[] memory timeDiffArr = new uint256[](
            currentOriginalRoundId - startOriginalRoundId - 1
        );

        // Calculation for time different
        for (
            uint256 i = 0;
            i < (currentOriginalRoundId - startOriginalRoundId - 1);
            i++
        ) {
            if (i == 0) {
                timeDiffArr[0] = timestampArr[1] - timestampArr[0];
            } else if (
                i == (currentOriginalRoundId - startOriginalRoundId) - 2
            ) {
                timeDiffArr[i] =
                    (timestampOfEvent + cg.monitoringPeriod()) -
                    timestampArr[i];
            } else {
                timeDiffArr[i] = timestampArr[i + 1] - timestampArr[i];
            }
        }

        // Sorting
        quickSort(
            priceArr,
            timeDiffArr,
            0,
            (int64(currentOriginalRoundId) - int64(startOriginalRoundId) - 2) // last index of array
        );

        // Find Median Price
        uint256 commulativeSum = timestampOfEvent;
        uint256 selectedIndex;
        for (uint256 i = 0; i < timeDiffArr.length; i++) {
            commulativeSum += timeDiffArr[i];
            if (
                commulativeSum >=
                (timestampOfEvent + (cg.monitoringPeriod() / 2))
            ) {
                selectedIndex = i;
                break;
            }
        }

        return (priceArr[selectedIndex], priceFeed.decimals());
    }

    /**
     * @dev Quick Sort Sorting Algorithm, used for sorting price values of chainlink price feeds
     */
    function quickSort(
        uint256[] memory arr,
        uint256[] memory arr2,
        int256 left,
        int256 right
    ) public view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                (arr2[uint256(i)], arr2[uint256(j)]) = (
                    arr2[uint256(j)],
                    arr2[uint256(i)]
                );
                i++;
                j--;
            }
        }

        if (left < j) quickSort(arr, arr2, left, j);
        if (i < right) quickSort(arr, arr2, i, right);
    }

    /**
    @dev check validity of devaluation claim
    @return isValidClaim bool as state of valid claim
    @return assetPrice is devaluation price per asset
    @return decimals is decimals of price feed
     */
    function checkClaimForDevaluation(address aggregatorAddress, uint80 roundId)
        public
        view
        override
        returns (
            bool isValidClaim,
            uint256 assetPrice,
            uint8 decimals
        )
    {
        // Get median price and decimals
        (uint256 price, uint8 priceDecimals) = getMedian(
            aggregatorAddress,
            roundId
        );

        // threshold is a price that indicates stablecoins are devalued
        uint256 threshold = ((100 - cg.maxDevaluation()) *
            (STABLECOINS_STANDARD_PRICE * (10**priceDecimals))) / 100;
        // if price under threshold then its mark as devaluation
        // else mark as non-devaluation
        isValidClaim = price < threshold ? true : false;
        return (isValidClaim, price, priceDecimals);
    }

    /**
     * @dev Convert price from stablecoins curency to USD (Currently only support DAI, USDT, USDC)
     */
    function convertPrice(uint256[] memory withdrawable, uint256[] memory lock)
        external
        view
        override
        returns (
            uint256 totalWithdrawInUSD,
            uint256 totalLockInUSD,
            uint8 usdDecimals
        )
    {
        usdDecimals = 6;

        // Loop every currency
        for (uint8 j = 0; j < uint8(CurrencyType.END_ENUM); j++) {
            uint8 assetDecimals = cg.getCurrencyDecimal(j);
            // Get latest price of stable coins
            string memory coinId = cg.getCurrencyName(j);
            address priceFeedAddr = platformData.getOraclePriceFeedAddress(
                coinId
            );
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                priceFeedAddr
            );
            (, int256 currentPrice, , , ) = priceFeed.latestRoundData();
            uint8 priceFeedDecimals = priceFeed.decimals();

            // Formula : total asset * price per asset from pricefeed * usd decimals / asset decimals / price feed decimal
            totalWithdrawInUSD += ((withdrawable[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
            totalLockInUSD += ((lock[j] *
                uint256(currentPrice) *
                (10**usdDecimals)) /
                (10**assetDecimals) /
                (10**priceFeedDecimals));
        }

        return (totalWithdrawInUSD, totalLockInUSD, usdDecimals);
    }

    /**
     * @dev validate claim creation by looking at pricing in previous rounds that make up duration of 1 hour (cg.validationPreviousPeriod())
     */
    function isValidPastDevaluation(address priceFeedAddr, uint80 roundId)
        external
        view
        override
        returns (bool isValidDevaluation)
    {
        isValidDevaluation = true;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        // Get Phase Id & start original round id
        (uint16 phaseId, uint64 originalRoundId) = parseIds(roundId);
        // Call aggregator to Get Event Detail
        (, , uint256 eventStartedAt, , ) = priceFeed.getRoundData(roundId);
        uint256 prevStartedAt = 0;

        do {
            // deduct originalRoundId every iteration
            originalRoundId -= 1;

            // Call aggregator to get price and time
            (, int256 price, , uint256 timestamp, ) = priceFeed.getRoundData(
                getRoundId(phaseId, originalRoundId)
            );
            prevStartedAt = timestamp;
            require(uint256(price) > 0 && timestamp > 0, "ERR_PAST_VALUATION");

            // check price, must below standard/below 1$
            // threshold is a price that indicates stablecoins are devalued
            uint256 threshold = ((100 - cg.maxDevaluation()) *
                (STABLECOINS_STANDARD_PRICE * (10**priceFeed.decimals()))) /
                100;

            // Mark as non devaluation is eq or bigger tha nthreshold
            if (uint256(price) >= threshold) {
                isValidDevaluation = false;
                break;
            }

            // Will loop until check last 1 hour price (cg.validationPreviousPeriod())
        } while (
            prevStartedAt > eventStartedAt - cg.validationPreviousPeriod()
        );

        return isValidDevaluation;
    }

    /**
     * @dev Get chainlinks price feed address based on cover
     */
    function getPriceFeedAddress(InsuranceCover memory cover)
        public
        view
        override
        returns (address priceFeedAddr)
    {
        string memory coinId = (cover.listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(cover.requestId).coinId
            : listingData.getCoverOfferById(cover.offerId).coinId;
        priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);
    }

    /**
     * @dev check if any pending claim exists on cover , pending claim is a claim with state "Monitoring" and still on range of payout period
     */
    function isPendingClaimExistOnCover(uint256 coverId)
        external
        view
        override
        returns (bool statePendingClaimExists)
    {
        InsuranceCover memory cover = coverData.getCoverById(coverId);
        address priceFeedAddr = getPriceFeedAddress(cover);

        // Price feed aggregator
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        uint256[] memory claimIds = claimData.getCoverToClaims(coverId);

        // Loop all claim on the cover
        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);

            // check if any MONITORING claim and still on payout period
            // a.k.a check is there any claims that not yet trigger checkValidityAndPayout function
            if (claim.state == ClaimState.MONITORING) {
                // Call aggregator to get event tomestamp
                (, , , uint256 claimEventTimestamp, ) = priceFeed.getRoundData(
                    claim.roundId
                );

                if (
                    block.timestamp <=
                    (claimEventTimestamp +
                        cg.monitoringPeriod() +
                        cg.maxPayoutPeriod())
                ) {
                    statePendingClaimExists = true;
                    break;
                }
            }
        }
    }

    /**
     * @dev Check status of claim which already expired
     * @dev Expired claim is a claim that exceed the payout period
     */
    function execExpiredPendingClaims(ListingType listingType, uint256 id)
        external
        override
        onlyInternal
    {
        // Price feed aggregator address
        string memory coinId = (listingType == ListingType.REQUEST)
            ? listingData.getCoverRequestById(id).coinId
            : listingData.getCoverOfferById(id).coinId;
        address priceFeedAddr = platformData.getOraclePriceFeedAddress(coinId);

        if (listingType == ListingType.REQUEST) {
            execExpiredPendingClaimsByRequestId(priceFeedAddr, id);
        } else {
            uint256[] memory coverIds = coverData.getCoversByOfferId(id);
            for (uint256 i = 0; i < coverIds.length; i++) {
                execExpiredPendingClaimsByCoverId(priceFeedAddr, coverIds[i]);
            }
        }
    }

    /**
     * @dev Check status of claim which already expired
     * @dev Expired claim is a claim that exceed the payout period
     */
    function execExpiredPendingClaimsByCoverId(
        address priceFeedAddr,
        uint256 coverId
    ) public override onlyInternal {
        uint256[] memory claimIds = claimData.getCoverToClaims(coverId);

        for (uint256 j = 0; j < claimIds.length; j++) {
            Claim memory claim = claimData.getClaimById(claimIds[j]);
            if (claim.state == ClaimState.MONITORING) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(
                    priceFeedAddr
                );
                (, , uint256 startedAt, , ) = priceFeed.getRoundData(
                    claim.roundId
                );
                if (
                    block.timestamp >
                    (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod())
                ) {
                    _checkValidityClaim(claimIds[j], priceFeedAddr);
                }
            }
        }
    }

    function execExpiredPendingClaimsByRequestId(
        address priceFeedAddr,
        uint256 requestId
    ) public onlyInternal {
        uint256[] memory collectiveClaimIds = claimData
            .getRequestToCollectiveClaims(requestId);

        for (uint256 j = 0; j < collectiveClaimIds.length; j++) {
            CollectiveClaim memory collectiveClaim = claimData
                .getCollectiveClaimById(collectiveClaimIds[j]);
            if (collectiveClaim.state == ClaimState.MONITORING) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(
                    priceFeedAddr
                );
                (, , uint256 startedAt, , ) = priceFeed.getRoundData(
                    collectiveClaim.roundId
                );
                if (
                    block.timestamp >
                    (startedAt + cg.monitoringPeriod() + cg.maxPayoutPeriod())
                ) {
                    _checkValidityCollectiveClaim(
                        collectiveClaimIds[j],
                        priceFeedAddr
                    );
                }
            }
        }
    }

    /**
     * @dev Check pending claim by claim id
     */
    function checkValidityClaim(uint256 claimId) external override {
        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        // Price feed aggregator address
        address priceFeedAddr = getPriceFeedAddress(cover);

        _checkValidityClaim(claimId, priceFeedAddr);
    }

    /**
     * @dev Check pending claim by claim id
     */
    function _checkValidityClaim(uint256 claimId, address priceFeedAddr)
        internal
    {
        Claim memory claim = claimData.getClaimById(claimId);

        // For stablecoins devaluation will decided based on oracle
        (
            bool isClaimValid,
            uint256 assetPrice,
            uint8 decimals
        ) = checkClaimForDevaluation(priceFeedAddr, claim.roundId);

        uint256 coverId = claimData.claimToCover(claimId);
        InsuranceCover memory cover = coverData.getCoverById(coverId);

        if (isClaimValid) {
            // Get cover offer
            CoverOffer memory coverOffer = listingData.getCoverOfferById(
                cover.offerId
            );

            // Calculate Payout
            uint256 payout = 0;
            payout = getPayoutOfCover(cover, assetPrice, decimals);

            emit ExpiredValidClaim(
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

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.VALID_AFTER_EXPIRED
            );

            // Update total fund that can be owned by platform
            claimData.addTotalExpiredPayout(
                coverOffer.insuredSumCurrency,
                payout
            );
        } else {
            // Emit events
            emit ExpiredInvalidClaim(coverId, claimId);

            // update state of claim
            claimData.updateClaimState(
                claimId,
                cover.offerId,
                ClaimState.INVALID_AFTER_EXPIRED
            );
        }
    }

    function _checkValidityCollectiveClaim(
        uint256 collectiveClaimId,
        address priceFeedAddr
    ) internal {
        CollectiveClaim memory collectiveClaim = claimData
            .getCollectiveClaimById(collectiveClaimId);

        // For stablecoins devaluation will decided based on oracle
        (
            bool isClaimValid,
            uint256 assetPrice,
            uint8 decimals
        ) = checkClaimForDevaluation(priceFeedAddr, collectiveClaim.roundId);
        // Get Cover id
        uint256 requestId = claimData.collectiveClaimToRequest(
            collectiveClaimId
        );

        if (isClaimValid) {
            CoverRequest memory coverRequest = listingData.getCoverRequestById(
                requestId
            );
            // Calculate Payout
            uint256 payout = getPayoutOfRequest(
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
            emit ExpiredValidCollectiveClaim(
                requestId,
                collectiveClaimId,
                uint8(coverRequest.insuredSumCurrency),
                payout
            );
            // Update total payout of offer request
            claimData.setRequestIdToPayout(requestId, payout);

            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.VALID_AFTER_EXPIRED
            );
            // Update total fund that can be owned by platform
            claimData.addTotalExpiredPayout(
                coverRequest.insuredSumCurrency,
                payout
            );
        } else {
            // emit event
            emit ExpiredInvalidCollectiveClaim(requestId, collectiveClaimId);
            // update state of claim
            claimData.updateCollectiveClaimState(
                collectiveClaimId,
                ClaimState.INVALID_AFTER_EXPIRED
            );
        }
    }

    function isFunderHasPendingClaims(
        ListingType listingType,
        address funderAddr
    ) external view override returns (bool state) {
        uint256[] memory ids = (listingType == ListingType.OFFER)
            ? coverData.getFunderToCovers(funderAddr)
            : coverData.getFunderToRequestId(funderAddr);

        for (uint16 i = 0; i < ids.length; i++) {
            uint16 pendingClaims = (listingType == ListingType.OFFER)
                ? claimData.coverToPendingClaims(ids[i])
                : claimData.requestToPendingCollectiveClaims(ids[i]);

            if (pendingClaims > 0) return true;
        }
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