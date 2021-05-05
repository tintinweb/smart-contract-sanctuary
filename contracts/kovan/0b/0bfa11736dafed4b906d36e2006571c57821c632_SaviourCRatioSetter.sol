/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/SaviourCRatioSetter.sol
pragma solidity =0.6.7 >=0.6.0 <0.8.0 >=0.6.7 <0.7.0;

////// src/interfaces/GebSafeManagerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract GebSafeManagerLike {
    function safes(uint256) virtual public view returns (address);
    function ownsSAFE(uint256) virtual public view returns (address);
    function safeCan(address,uint256,address) virtual public view returns (uint256);
}

////// src/interfaces/OracleRelayerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract OracleRelayerLike_2 {
    function collateralTypes(bytes32) virtual public view returns (address, uint256, uint256);
    function liquidationCRatio(bytes32) virtual public view returns (uint256);
    function redemptionPrice() virtual public returns (uint256);
}

////// src/utils/ReentrancyGuard.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

////// src/interfaces/SaviourCRatioSetterLike.sol
/* pragma solidity 0.6.7; */

/* import "./OracleRelayerLike.sol"; */
/* import "./GebSafeManagerLike.sol"; */

/* import "../utils/ReentrancyGuard.sol"; */

abstract contract SaviourCRatioSetterLike is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "SaviourCRatioSetter/account-not-authorized");
        _;
    }

    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), "SaviourCRatioSetter/null-owner");
        require(either(owner == safeManager.ownsSAFE(safeID), safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1), "SaviourCRatioSetter/not-owning-safe");

        _;
    }

    // --- Variables ---
    OracleRelayerLike_2  public oracleRelayer;
    GebSafeManagerLike public safeManager;

    // Default desired cratio for each individual collateral type
    mapping(bytes32 => uint256)                     public defaultDesiredCollateralizationRatios;
    // Minimum bound for the desired cratio for each collateral type
    mapping(bytes32 => uint256)                     public minDesiredCollateralizationRatios;
    // Desired CRatios for each SAFE after they're saved
    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;

    // --- Constants ---
    uint256 public constant MAX_CRATIO        = 1000;
    uint256 public constant CRATIO_SCALE_DOWN = 10**25;

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event SetDefaultCRatio(bytes32 indexed collateralType, uint256 cRatio);
    event SetMinDesiredCollateralizationRatio(
      bytes32 indexed collateralType,
      uint256 cRatio
    );
    event SetDesiredCollateralizationRatio(
      address indexed caller,
      bytes32 indexed collateralType,
      uint256 safeID,
      address indexed safeHandler,
      uint256 cRatio
    );

    // --- Functions ---
    function setDefaultCRatio(bytes32, uint256) virtual external;
    function setMinDesiredCollateralizationRatio(bytes32 collateralType, uint256 cRatio) virtual external;
    function setDesiredCollateralizationRatio(bytes32 collateralType, uint256 safeID, uint256 cRatio) virtual external;
}

////// src/math/SafeMath.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

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
contract SafeMath {
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

////// src/SaviourCRatioSetter.sol
/* pragma solidity 0.6.7; */

/* import "./interfaces/SaviourCRatioSetterLike.sol"; */
/* import "./math/SafeMath.sol"; */

contract SaviourCRatioSetter is SafeMath, SaviourCRatioSetterLike {
    constructor(
      address oracleRelayer_,
      address safeManager_
    ) public {
        require(oracleRelayer_ != address(0), "SaviourCRatioSetter/null-oracle-relayer");
        require(safeManager_ != address(0), "SaviourCRatioSetter/null-safe-manager");

        authorizedAccounts[msg.sender] = 1;

        oracleRelayer = OracleRelayerLike_2(oracleRelayer_);
        safeManager   = GebSafeManagerLike(safeManager_);

        oracleRelayer.redemptionPrice();

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
    }

    // --- Administration ---
    /**
     * @notice Modify an address param
     * @param parameter The name of the parameter
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "SaviourCRatioSetter/null-data");

        if (parameter == "oracleRelayer") {
            oracleRelayer = OracleRelayerLike_2(data);
            oracleRelayer.redemptionPrice();
        }
        else revert("SaviourCRatioSetter/modify-unrecognized-param");
    }
    /**
     * @notice Set the default desired CRatio for a specific collateral type
     * @param collateralType The name of the collateral type to set the default CRatio for
     * @param cRatio New default collateralization ratio
     */
    function setDefaultCRatio(bytes32 collateralType, uint256 cRatio) external override isAuthorized {
        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralType) / CRATIO_SCALE_DOWN;

        require(scaledLiquidationRatio > 0, "SaviourCRatioSetter/invalid-scaled-liq-ratio");
        require(both(cRatio > scaledLiquidationRatio, cRatio <= MAX_CRATIO), "SaviourCRatioSetter/invalid-default-desired-cratio");

        defaultDesiredCollateralizationRatios[collateralType] = cRatio;

        emit SetDefaultCRatio(collateralType, cRatio);
    }
    /*
    * @notify Set the minimum CRatio that every Safe must take into account when setting a desired CRatio
    * @param collateralType The collateral type for which to set the min desired CRatio
    * @param cRatio The min desired CRatio to set for collateralType
    */
    function setMinDesiredCollateralizationRatio(bytes32 collateralType, uint256 cRatio) external override isAuthorized {
        require(cRatio < MAX_CRATIO, "SaviourCRatioSetter/invalid-min-cratio");
        minDesiredCollateralizationRatios[collateralType] = cRatio;
        emit SetMinDesiredCollateralizationRatio(collateralType, cRatio);
    }

    // --- Adjust Cover Preferences ---
    /*
    * @notice Sets the collateralization ratio that a SAFE should have after it's saved
    * @dev Only an address that controls the SAFE inside GebSafeManager can call this
    * @param collateralType The collateral type used in the safe
    * @param safeID The ID of the SAFE to set the desired CRatio for. This ID should be registered inside GebSafeManager
    * @param cRatio The collateralization ratio to set
    */
    function setDesiredCollateralizationRatio(bytes32 collateralType, uint256 safeID, uint256 cRatio)
      external override controlsSAFE(msg.sender, safeID) {
        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralType) / CRATIO_SCALE_DOWN;
        address safeHandler = safeManager.safes(safeID);

        require(scaledLiquidationRatio > 0, "SaviourCRatioSetter/invalid-scaled-liq-ratio");
        require(either(cRatio >= minDesiredCollateralizationRatios[collateralType], cRatio == 0), "SaviourCRatioSetter/invalid-min-ratio");
        require(cRatio <= MAX_CRATIO, "SaviourCRatioSetter/exceeds-max-cratio");

        if (cRatio > 0) {
            require(scaledLiquidationRatio < cRatio, "SaviourCRatioSetter/invalid-desired-cratio");
        }

        desiredCollateralizationRatios[collateralType][safeHandler] = cRatio;

        emit SetDesiredCollateralizationRatio(msg.sender, collateralType, safeID, safeHandler, cRatio);
    }
}