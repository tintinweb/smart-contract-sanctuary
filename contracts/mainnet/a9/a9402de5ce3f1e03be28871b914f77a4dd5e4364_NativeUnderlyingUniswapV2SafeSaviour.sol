/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/saviours/NativeUnderlyingUniswapV2SafeSaviour.sol
pragma solidity =0.6.7 >=0.6.0 <0.8.0 >=0.6.7 <0.7.0;

////// src/interfaces/CoinJoinLike.sol
/* pragma solidity 0.6.7; */

abstract contract CoinJoinLike {
    function systemCoin() virtual public view returns (address);
    function safeEngine() virtual public view returns (address);
    function join(address, uint256) virtual external;
}

////// src/interfaces/CollateralJoinLike.sol
/* pragma solidity ^0.6.7; */

abstract contract CollateralJoinLike {
    function safeEngine() virtual public view returns (address);
    function collateralType() virtual public view returns (bytes32);
    function collateral() virtual public view returns (address);
    function decimals() virtual public view returns (uint256);
    function contractEnabled() virtual public view returns (uint256);
    function join(address, uint256) virtual external;
}

////// src/interfaces/ERC20Like.sol
/* pragma solidity ^0.6.7; */

abstract contract ERC20Like {
    function approve(address guy, uint wad) virtual public returns (bool);
    function transfer(address dst, uint wad) virtual public returns (bool);
    function balanceOf(address) virtual external view returns (uint256);
    function transferFrom(address src, address dst, uint wad)
        virtual
        public
        returns (bool);
}

////// src/interfaces/GebSafeManagerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract GebSafeManagerLike {
    function safes(uint256) virtual public view returns (address);
    function ownsSAFE(uint256) virtual public view returns (address);
    function safeCan(address,uint256,address) virtual public view returns (uint256);
}

////// src/interfaces/LiquidationEngineLike.sol
/* pragma solidity ^0.6.7; */

abstract contract LiquidationEngineLike_3 {
    function safeSaviours(address) virtual public view returns (uint256);
}

////// src/interfaces/OracleRelayerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract OracleRelayerLike_2 {
    function collateralTypes(bytes32) virtual public view returns (address, uint256, uint256);
    function liquidationCRatio(bytes32) virtual public view returns (uint256);
    function redemptionPrice() virtual public returns (uint256);
}

////// src/interfaces/PriceFeedLike.sol
/* pragma solidity ^0.6.7; */

abstract contract PriceFeedLike {
    function priceSource() virtual public view returns (address);
    function read() virtual public view returns (uint256);
    function getResultWithValidity() virtual external view returns (uint256,bool);
}

////// src/interfaces/SAFEEngineLike.sol
/* pragma solidity ^0.6.7; */

abstract contract SAFEEngineLike_8 {
    function approveSAFEModification(address) virtual external;
    function safeRights(address,address) virtual public view returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) virtual public view returns (
        uint256 lockedCollateral,  // [wad]
        uint256 generatedDebt      // [wad]
    );
    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,    // [wad]
        int256 deltaDebt           // [wad]
    ) virtual external;
}

////// src/interfaces/SAFESaviourRegistryLike.sol
/* pragma solidity ^0.6.7; */

abstract contract SAFESaviourRegistryLike {
    function markSave(bytes32 collateralType, address safeHandler) virtual external;
}

////// src/interfaces/TaxCollectorLike.sol
/* pragma solidity 0.6.7; */

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) public virtual returns (uint256);
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

////// src/interfaces/SafeSaviourLike.sol
// Copyright (C) 2020 Reflexer Labs, INC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.6.7; */

/* import "./CollateralJoinLike.sol"; */
/* import "./CoinJoinLike.sol"; */
/* import "./OracleRelayerLike.sol"; */
/* import "./SAFEEngineLike.sol"; */
/* import "./LiquidationEngineLike.sol"; */
/* import "./PriceFeedLike.sol"; */
/* import "./ERC20Like.sol"; */
/* import "./GebSafeManagerLike.sol"; */
/* import "./TaxCollectorLike.sol"; */
/* import "./SAFESaviourRegistryLike.sol"; */

/* import "../utils/ReentrancyGuard.sol"; */

abstract contract SafeSaviourLike is ReentrancyGuard {
    // Checks whether a saviour contract has been approved by governance in the LiquidationEngine
    modifier liquidationEngineApproved(address saviour) {
        require(liquidationEngine.safeSaviours(saviour) == 1, "SafeSaviour/not-approved-in-liquidation-engine");
        _;
    }
    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), "SafeSaviour/null-owner");
        require(either(owner == safeManager.ownsSAFE(safeID), safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1), "SafeSaviour/not-owning-safe");

        _;
    }

    // --- Variables ---
    LiquidationEngineLike_3   public liquidationEngine;
    TaxCollectorLike        public taxCollector;
    OracleRelayerLike_2       public oracleRelayer;
    GebSafeManagerLike      public safeManager;
    SAFEEngineLike_8          public safeEngine;
    SAFESaviourRegistryLike public saviourRegistry;

    // The amount of tokens the keeper gets in exchange for the gas spent to save a SAFE
    uint256 public keeperPayout;          // [wad]
    // The minimum fiat value that the keeper must get in exchange for saving a SAFE
    uint256 public minKeeperPayoutValue;  // [wad]
    /*
      The proportion between the keeperPayout (if it's in collateral) and the amount of collateral or debt that's in a SAFE to be saved.
      Alternatively, it can be the proportion between the fiat value of keeperPayout and the fiat value of the profit that a keeper
      could make if a SAFE is liquidated right now. It ensures there's no incentive to intentionally put a SAFE underwater and then
      save it just to make a profit that's greater than the one from participating in collateral auctions
    */
    uint256 public payoutToSAFESize;

    // --- Constants ---
    uint256 public constant ONE               = 1;
    uint256 public constant HUNDRED           = 100;
    uint256 public constant THOUSAND          = 1000;
    uint256 public constant WAD_COMPLEMENT    = 10**9;
    uint256 public constant WAD               = 10**18;
    uint256 public constant RAY               = 10**27;
    uint256 public constant MAX_UINT          = uint(-1);

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event SaveSAFE(address indexed keeper, bytes32 indexed collateralType, address indexed safeHandler, uint256 collateralAddedOrDebtRepaid);

    // --- Functions to Implement ---
    function saveSAFE(address,bytes32,address) virtual external returns (bool,uint256,uint256);
    function getKeeperPayoutValue() virtual public returns (uint256);
    function keeperPayoutExceedsMinValue() virtual public returns (bool);
    function canSave(bytes32,address) virtual external returns (bool);
    function tokenAmountUsedToSave(bytes32,address) virtual public returns (uint256);
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

////// src/interfaces/UniswapLiquidityManagerLike.sol
/* pragma solidity 0.6.7; */

abstract contract UniswapLiquidityManagerLike {
    function getToken0FromLiquidity(uint256) virtual public view returns (uint256);
    function getToken1FromLiquidity(uint256) virtual public view returns (uint256);

    function getLiquidityFromToken0(uint256) virtual public view returns (uint256);
    function getLiquidityFromToken1(uint256) virtual public view returns (uint256);

    function removeLiquidity(
      uint256 liquidity,
      uint128 amount0Min,
      uint128 amount1Min,
      address to
    ) public virtual returns (uint256, uint256);
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
contract SafeMath_2 {
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

////// src/saviours/NativeUnderlyingUniswapV2SafeSaviour.sol
// Copyright (C) 2021 Reflexer Labs, INC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/* import "../interfaces/UniswapLiquidityManagerLike.sol"; */
/* import "../interfaces/SaviourCRatioSetterLike.sol"; */
/* import "../interfaces/SafeSaviourLike.sol"; */
/* import "../math/SafeMath.sol"; */

contract NativeUnderlyingUniswapV2SafeSaviour is SafeMath_2, SafeSaviourLike {
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
        require(authorizedAccounts[msg.sender] == 1, "NativeUnderlyingUniswapV2SafeSaviour/account-not-authorized");
        _;
    }

    mapping (address => uint256) public allowedUsers;
    /**
     * @notice Allow a user to deposit assets
     * @param usr User to whitelist
     */
    function allowUser(address usr) external isAuthorized {
        allowedUsers[usr] = 1;
        emit AllowUser(usr);
    }
    /**
     * @notice Disallow a user from depositing assets
     * @param usr User to disallow
     */
    function disallowUser(address usr) external isAuthorized {
        allowedUsers[usr] = 0;
        emit DisallowUser(usr);
    }
    /**
    * @notice Checks whether an address is an allowed user
    **/
    modifier isAllowed {
        require(
          either(restrictUsage == 0, both(restrictUsage == 1, allowedUsers[msg.sender] == 1)),
          "NativeUnderlyingUniswapV2SafeSaviour/account-not-allowed"
        );
        _;
    }

    // --- Structs ---
    struct Reserves {
        uint256 systemCoins;
        uint256 collateralCoins;
    }

    // --- Variables ---
    // Flag that tells whether usage of the contract is restricted to allowed users
    uint256                        public restrictUsage;

    // Whether the system coin is token0 in the Uniswap pool or not
    bool                           public isSystemCoinToken0;
    // Amount of LP tokens currently protecting each position
    mapping(address => uint256)    public lpTokenCover;
    // Amount of system coin/collateral tokens that Safe owners can get back
    mapping(address => Reserves)   public underlyingReserves;
    // Liquidity manager contract for Uniswap v2/v3
    UniswapLiquidityManagerLike    public liquidityManager;
    // The ERC20 system coin
    ERC20Like                      public systemCoin;
    // The system coin join contract
    CoinJoinLike                   public coinJoin;
    // The collateral join contract for adding collateral in the system
    CollateralJoinLike             public collateralJoin;
    // The LP token
    ERC20Like                      public lpToken;
    // The collateral token
    ERC20Like                      public collateralToken;
    // Oracle providing the system coin price feed
    PriceFeedLike                  public systemCoinOrcl;
    // Contract that defines desired CRatios for each Safe after it is saved
    SaviourCRatioSetterLike        public cRatioSetter;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event AllowUser(address usr);
    event DisallowUser(address usr);
    event ModifyParameters(bytes32 indexed parameter, uint256 val);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event Deposit(
      address indexed caller,
      address indexed safeHandler,
      uint256 lpTokenAmount
    );
    event Withdraw(
      address indexed caller,
      address indexed safeHandler,
      address dst,
      uint256 lpTokenAmount
    );
    event GetReserves(
      address indexed caller,
      address indexed safeHandler,
      uint256 systemCoinAmount,
      uint256 collateralAmount,
      address dst
    );

    constructor(
        bool isSystemCoinToken0_,
        address coinJoin_,
        address collateralJoin_,
        address cRatioSetter_,
        address systemCoinOrcl_,
        address liquidationEngine_,
        address taxCollector_,
        address oracleRelayer_,
        address safeManager_,
        address saviourRegistry_,
        address liquidityManager_,
        address lpToken_,
        uint256 minKeeperPayoutValue_
    ) public {
        require(coinJoin_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-coin-join");
        require(collateralJoin_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-collateral-join");
        require(cRatioSetter_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-cratio-setter");
        require(systemCoinOrcl_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-system-coin-oracle");
        require(oracleRelayer_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-oracle-relayer");
        require(liquidationEngine_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-liquidation-engine");
        require(taxCollector_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-tax-collector");
        require(safeManager_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-safe-manager");
        require(saviourRegistry_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-saviour-registry");
        require(liquidityManager_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-liq-manager");
        require(lpToken_ != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-lp-token");
        require(minKeeperPayoutValue_ > 0, "NativeUnderlyingUniswapV2SafeSaviour/invalid-min-payout-value");

        authorizedAccounts[msg.sender] = 1;

        isSystemCoinToken0   = isSystemCoinToken0_;
        minKeeperPayoutValue = minKeeperPayoutValue_;

        coinJoin             = CoinJoinLike(coinJoin_);
        collateralJoin       = CollateralJoinLike(collateralJoin_);
        cRatioSetter         = SaviourCRatioSetterLike(cRatioSetter_);
        liquidationEngine    = LiquidationEngineLike_3(liquidationEngine_);
        taxCollector         = TaxCollectorLike(taxCollector_);
        oracleRelayer        = OracleRelayerLike_2(oracleRelayer_);
        systemCoinOrcl       = PriceFeedLike(systemCoinOrcl_);
        systemCoin           = ERC20Like(coinJoin.systemCoin());
        safeEngine           = SAFEEngineLike_8(coinJoin.safeEngine());
        safeManager          = GebSafeManagerLike(safeManager_);
        saviourRegistry      = SAFESaviourRegistryLike(saviourRegistry_);
        liquidityManager     = UniswapLiquidityManagerLike(liquidityManager_);
        lpToken              = ERC20Like(lpToken_);
        collateralToken      = ERC20Like(collateralJoin.collateral());

        systemCoinOrcl.getResultWithValidity();
        oracleRelayer.redemptionPrice();

        require(collateralJoin.contractEnabled() == 1, "NativeUnderlyingUniswapV2SafeSaviour/join-disabled");
        require(address(collateralToken) != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-col-token");
        require(address(safeEngine) != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-safe-engine");
        require(address(systemCoin) != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-sys-coin");

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("minKeeperPayoutValue", minKeeperPayoutValue);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("taxCollector", taxCollector_);
        emit ModifyParameters("systemCoinOrcl", systemCoinOrcl_);
        emit ModifyParameters("liquidationEngine", liquidationEngine_);
        emit ModifyParameters("liquidityManager", liquidityManager_);
    }

    // --- Administration ---
    /**
     * @notice Modify an uint256 param
     * @param parameter The name of the parameter
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "minKeeperPayoutValue") {
            require(val > 0, "NativeUnderlyingUniswapV2SafeSaviour/null-min-payout");
            minKeeperPayoutValue = val;
        }
        else if (parameter == "restrictUsage") {
            require(val <= 1, "NativeUnderlyingUniswapV2SafeSaviour/invalid-restriction");
            restrictUsage = val;
        }
        else revert("NativeUnderlyingUniswapV2SafeSaviour/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /**
     * @notice Modify an address param
     * @param parameter The name of the parameter
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-data");

        if (parameter == "systemCoinOrcl") {
            systemCoinOrcl = PriceFeedLike(data);
            systemCoinOrcl.getResultWithValidity();
        }
        else if (parameter == "oracleRelayer") {
            oracleRelayer = OracleRelayerLike_2(data);
            oracleRelayer.redemptionPrice();
        }
        else if (parameter == "liquidityManager") {
            liquidityManager = UniswapLiquidityManagerLike(data);
        }
        else if (parameter == "liquidationEngine") {
            liquidationEngine = LiquidationEngineLike_3(data);
        }
        else if (parameter == "taxCollector") {
            taxCollector = TaxCollectorLike(data);
        }
        else revert("NativeUnderlyingUniswapV2SafeSaviour/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Transferring Reserves ---
    /*
    * @notify Get back system coins or collateral tokens that were withdrawn from Uniswap and not used to save a specific SAFE
    * @param safeID The ID of the safe that was previously saved and has leftover funds that can be withdrawn
    * @param dst The address that will receive
    */
    function getReserves(uint256 safeID, address dst) external controlsSAFE(msg.sender, safeID) nonReentrant {
        address safeHandler = safeManager.safes(safeID);
        (uint256 systemCoins, uint256 collateralCoins) =
          (underlyingReserves[safeHandler].systemCoins, underlyingReserves[safeHandler].collateralCoins);

        require(either(systemCoins > 0, collateralCoins > 0), "NativeUnderlyingUniswapV2SafeSaviour/no-reserves");
        delete(underlyingReserves[safeManager.safes(safeID)]);

        if (systemCoins > 0) {
          systemCoin.transfer(dst, systemCoins);
        }

        if (collateralCoins > 0) {
          collateralToken.transfer(dst, collateralCoins);
        }

        emit GetReserves(msg.sender, safeHandler, systemCoins, collateralCoins, dst);
    }

    // --- Adding/Withdrawing Cover ---
    /*
    * @notice Deposit lpToken in the contract in order to provide cover for a specific SAFE managed by the SAFE Manager
    * @param safeID The ID of the SAFE to protect. This ID should be registered inside GebSafeManager
    * @param lpTokenAmount The amount of collateralToken to deposit
    */
    function deposit(uint256 safeID, uint256 lpTokenAmount) external isAllowed() liquidationEngineApproved(address(this)) nonReentrant {
        require(lpTokenAmount > 0, "NativeUnderlyingUniswapV2SafeSaviour/null-lp-amount");

        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(safeID);
        require(safeHandler != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-handler");

        // Check that the SAFE has debt
        (, uint256 safeDebt) =
          SAFEEngineLike_8(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeDebt > 0, "NativeUnderlyingUniswapV2SafeSaviour/safe-does-not-have-debt");

        // Update the lpToken balance used to cover the SAFE and transfer tokens to this contract
        lpTokenCover[safeHandler] = add(lpTokenCover[safeHandler], lpTokenAmount);
        require(lpToken.transferFrom(msg.sender, address(this), lpTokenAmount), "NativeUnderlyingUniswapV2SafeSaviour/could-not-transfer-lp");

        emit Deposit(msg.sender, safeHandler, lpTokenAmount);
    }
    /*
    * @notice Withdraw lpToken from the contract and provide less cover for a SAFE
    * @dev Only an address that controls the SAFE inside the SAFE Manager can call this
    * @param safeID The ID of the SAFE to remove cover from. This ID should be registered inside the SAFE Manager
    * @param lpTokenAmount The amount of lpToken to withdraw
    * @param dst The address that will receive the LP tokens
    */
    function withdraw(uint256 safeID, uint256 lpTokenAmount, address dst) external controlsSAFE(msg.sender, safeID) nonReentrant {
        require(lpTokenAmount > 0, "NativeUnderlyingUniswapV2SafeSaviour/null-lp-amount");

        // Fetch the handler from the SAFE manager
        address safeHandler = safeManager.safes(safeID);
        require(lpTokenCover[safeHandler] >= lpTokenAmount, "NativeUnderlyingUniswapV2SafeSaviour/not-enough-to-withdraw");

        // Withdraw cover and transfer collateralToken to the caller
        lpTokenCover[safeHandler] = sub(lpTokenCover[safeHandler], lpTokenAmount);
        lpToken.transfer(dst, lpTokenAmount);

        emit Withdraw(msg.sender, safeHandler, dst, lpTokenAmount);
    }

    // --- Saving Logic ---
    /*
    * @notice Saves a SAFE by withdrawing liquidity and repaying debt and/or adding more collateral
    * @dev Only the LiquidationEngine can call this
    * @param keeper The keeper that called LiquidationEngine.liquidateSAFE and that should be rewarded for spending gas to save a SAFE
    * @param collateralType The collateral type backing the SAFE that's being liquidated
    * @param safeHandler The handler of the SAFE that's being liquidated
    * @return Whether the SAFE has been saved, the amount of LP tokens that were used to withdraw liquidity as well as the amount of
    *         system coins sent to the keeper as their payment (this implementation always returns 0)
    */
    function saveSAFE(address keeper, bytes32 collateralType, address safeHandler) override external returns (bool, uint256, uint256) {
        require(address(liquidationEngine) == msg.sender, "NativeUnderlyingUniswapV2SafeSaviour/caller-not-liquidation-engine");
        require(keeper != address(0), "NativeUnderlyingUniswapV2SafeSaviour/null-keeper-address");

        if (both(both(collateralType == "", safeHandler == address(0)), keeper == address(liquidationEngine))) {
            return (true, uint(-1), uint(-1));
        }

        // Check that this is handling the correct collateral
        require(collateralType == collateralJoin.collateralType(), "NativeUnderlyingUniswapV2SafeSaviour/invalid-collateral-type");

        // Check that the SAFE has a non null amount of LP tokens covering it
        require(lpTokenCover[safeHandler] > 0, "NativeUnderlyingUniswapV2SafeSaviour/null-cover");

        // Tax the collateral
        taxCollector.taxSingle(collateralType);

        // Get the amount of tokens used to top up the SAFE
        (uint256 safeDebtRepaid, uint256 safeCollateralAdded) =
          getTokensForSaving(safeHandler, oracleRelayer.redemptionPrice());

        // There must be tokens used to save the SAVE
        require(either(safeDebtRepaid > 0, safeCollateralAdded > 0), "NativeUnderlyingUniswapV2SafeSaviour/cannot-save-safe");

        // Get the amounts of tokens sent to the keeper as payment
        (uint256 keeperSysCoins, uint256 keeperCollateralCoins) =
          getKeeperPayoutTokens(safeHandler, oracleRelayer.redemptionPrice(), safeDebtRepaid, safeCollateralAdded);

        // There must be tokens that go to the keeper
        require(either(keeperSysCoins > 0, keeperCollateralCoins > 0), "NativeUnderlyingUniswapV2SafeSaviour/cannot-pay-keeper");

        // Store cover amount in local var
        uint256 totalCover = lpTokenCover[safeHandler];
        delete(lpTokenCover[safeHandler]);

        // Mark the SAFE in the registry as just having been saved
        saviourRegistry.markSave(collateralType, safeHandler);

        // Withdraw all liquidity
        uint256 sysCoinBalance        = systemCoin.balanceOf(address(this));
        uint256 collateralCoinBalance = collateralToken.balanceOf(address(this));

        lpToken.approve(address(liquidityManager), totalCover);
        liquidityManager.removeLiquidity(totalCover, 0, 0, address(this));

        // Checks after removing liquidity
        require(
          either(systemCoin.balanceOf(address(this)) > sysCoinBalance, collateralToken.balanceOf(address(this)) > collateralCoinBalance),
          "NativeUnderlyingUniswapV2SafeSaviour/faulty-remove-liquidity"
        );

        // Compute remaining balances of tokens that will go into reserves
        sysCoinBalance        = sub(sub(systemCoin.balanceOf(address(this)), sysCoinBalance), add(safeDebtRepaid, keeperSysCoins));
        collateralCoinBalance = sub(
          sub(collateralToken.balanceOf(address(this)), collateralCoinBalance), add(safeCollateralAdded, keeperCollateralCoins)
        );

        // Update reserves
        if (sysCoinBalance > 0) {
          underlyingReserves[safeHandler].systemCoins = add(
            underlyingReserves[safeHandler].systemCoins, sysCoinBalance
          );
        }
        if (collateralCoinBalance > 0) {
          underlyingReserves[safeHandler].collateralCoins = add(
            underlyingReserves[safeHandler].collateralCoins, collateralCoinBalance
          );
        }

        // Save the SAFE
        if (safeDebtRepaid > 0) {
          // Approve the coin join contract to take system coins and repay debt
          systemCoin.approve(address(coinJoin), safeDebtRepaid);
          // Calculate the non adjusted system coin amount
          uint256 nonAdjustedSystemCoinsToRepay = div(mul(safeDebtRepaid, RAY), getAccumulatedRate(collateralType));

          // Join system coins in the system and repay the SAFE's debt
          coinJoin.join(address(this), safeDebtRepaid);
          safeEngine.modifySAFECollateralization(
            collateralType,
            safeHandler,
            address(0),
            address(this),
            int256(0),
            -int256(nonAdjustedSystemCoinsToRepay)
          );
        }

        if (safeCollateralAdded > 0) {
          // Approve collateralToken to the collateral join contract
          collateralToken.approve(address(collateralJoin), safeCollateralAdded);

          // Join collateralToken in the system and add it in the saved SAFE
          collateralJoin.join(address(this), safeCollateralAdded);
          safeEngine.modifySAFECollateralization(
            collateralType,
            safeHandler,
            address(this),
            address(0),
            int256(safeCollateralAdded),
            int256(0)
          );
        }

        // Pay keeper
        if (keeperSysCoins > 0) {
          systemCoin.transfer(keeper, keeperSysCoins);
        }

        if (keeperCollateralCoins > 0) {
          collateralToken.transfer(keeper, keeperCollateralCoins);
        }

        // Emit an event
        emit SaveSAFE(keeper, collateralType, safeHandler, totalCover);

        return (true, totalCover, 0);
    }

    // --- Getters ---
    /*
    * @notify Must be implemented according to the interface although it always returns 0
    */
    function getKeeperPayoutValue() override public returns (uint256) {
        return 0;
    }
    /*
    * @notify Must be implemented according to the interface although it always returns false
    */
    function keeperPayoutExceedsMinValue() override public returns (bool) {
        return false;
    }
    /*
    * @notice Determine whether a SAFE can be saved with the current amount of lpTokenCover deposited as cover for it
    * @param safeHandler The handler of the SAFE which the function takes into account
    * @return Whether the SAFE can be saved or not
    */
    function canSave(bytes32, address safeHandler) override external returns (bool) {
        // Fetch the redemption price first
        uint256 redemptionPrice = oracleRelayer.redemptionPrice();

        // Fetch the amount of tokens used to save the SAFE
        (uint256 safeDebtRepaid, uint256 safeCollateralAdded) =
          getTokensForSaving(safeHandler, redemptionPrice);

        // Fetch the amount of tokens sent to the keeper
        (uint256 keeperSysCoins, uint256 keeperCollateralCoins) =
          getKeeperPayoutTokens(safeHandler, redemptionPrice, safeDebtRepaid, safeCollateralAdded);

        // If there are some tokens used to save the SAFE and some tokens used to repay the keeper, return true
        if (both(
          either(safeDebtRepaid > 0, safeCollateralAdded > 0),
          either(keeperSysCoins > 0, keeperCollateralCoins > 0)
        )) {
          return true;
        }

        return false;
    }
    /*
    * @notice Return the total amount of LP tokens covering a specific SAFE
    * @param collateralType The SAFE collateral type (ignored in this implementation)
    * @param safeHandler The handler of the SAFE which the function takes into account
    * @return The total LP token cover for a specific SAFE
    */
    function tokenAmountUsedToSave(bytes32, address safeHandler) override public returns (uint256) {
        return lpTokenCover[safeHandler];
    }
    /*
    * @notify Fetch the collateral's price
    */
    function getCollateralPrice() public view returns (uint256) {
        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        if (ethFSM == address(0)) return 0;

        (uint256 priceFeedValue, bool hasValidValue) = PriceFeedLike(ethFSM).getResultWithValidity();
        if (!hasValidValue) return 0;

        return priceFeedValue;
    }
    /*
    * @notify Fetch the system coin's market price
    */
    function getSystemCoinMarketPrice() public view returns (uint256) {
        (uint256 priceFeedValue, bool hasValidValue) = systemCoinOrcl.getResultWithValidity();
        if (!hasValidValue) return 0;

        return priceFeedValue;
    }
    /*
    * @notify Get the target collateralization ratio that a SAFE should have after it's saved
    * @param safeHandler The handler/address of the SAFE whose target collateralization ratio is retrieved
    */
    function getTargetCRatio(address safeHandler) public view returns (uint256) {
        bytes32 collateralType = collateralJoin.collateralType();
        uint256 defaultCRatio  = cRatioSetter.defaultDesiredCollateralizationRatios(collateralType);
        uint256 targetCRatio   = (cRatioSetter.desiredCollateralizationRatios(collateralType, safeHandler) == 0) ?
          defaultCRatio : cRatioSetter.desiredCollateralizationRatios(collateralType, safeHandler);
        return targetCRatio;
    }
    /*
    * @notify Return the amount of system coins and collateral tokens retrieved from the LP position covering a specific SAFE
    * @param safeHandler The handler/address of the targeted SAFE
    */
    function getLPUnderlying(address safeHandler) public view returns (uint256, uint256) {
        uint256 coverAmount = lpTokenCover[safeHandler];

        if (coverAmount == 0) return (0, 0);

        (uint256 sysCoinsFromLP, uint256 collateralFromLP) = (isSystemCoinToken0) ?
          (liquidityManager.getToken0FromLiquidity(coverAmount), liquidityManager.getToken1FromLiquidity(coverAmount)) :
          (liquidityManager.getToken1FromLiquidity(coverAmount), liquidityManager.getToken0FromLiquidity(coverAmount));

        return (sysCoinsFromLP, collateralFromLP);
    }
    /*
    * @notice Return the amount of system coins and/or collateral tokens used to save a SAFE
    * @param safeHandler The handler/address of the targeted SAFE
    * @param redemptionPrice The system coin redemption price used in calculations
    */
    function getTokensForSaving(address safeHandler, uint256 redemptionPrice)
      public view returns (uint256, uint256) {
        if (either(lpTokenCover[safeHandler] == 0, redemptionPrice == 0)) {
            return (0, 0);
        }

        // Get the default CRatio for the SAFE
        (uint256 depositedCollateralToken, uint256 safeDebt) =
          SAFEEngineLike_8(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        uint256 targetCRatio = getTargetCRatio(safeHandler);
        if (either(safeDebt == 0, targetCRatio == 0)) {
            return (0, 0);
        }

        // Get the collateral market price
        uint256 collateralPrice = getCollateralPrice();
        if (collateralPrice == 0) {
            return (0, 0);
        }

        // Calculate how much debt would need to be repaid
        uint256 debtToRepay = mul(
          mul(HUNDRED, mul(depositedCollateralToken, collateralPrice) / WAD) / targetCRatio, RAY
        ) / redemptionPrice;

        if (either(debtToRepay >= safeDebt, debtBelowFloor(collateralJoin.collateralType(), debtToRepay))) {
            return (0, 0);
        }
        safeDebt    = mul(safeDebt, getAccumulatedRate(collateralJoin.collateralType())) / RAY;
        debtToRepay = sub(safeDebt, debtToRepay);

        // Calculate underlying amounts received from LP withdrawal
        (uint256 sysCoinsFromLP, uint256 collateralFromLP) = getLPUnderlying(safeHandler);

        // Determine total debt to repay; return if the SAFE can be saved solely by repaying debt, continue calculations otherwise
        if (sysCoinsFromLP >= debtToRepay) {
            return (debtToRepay, 0);
        } else {
            // Calculate the amount of collateral that would need to be added to the SAFE
            uint256 scaledDownDebtValue = mul(add(mul(redemptionPrice, sub(safeDebt, sysCoinsFromLP)) / RAY, ONE), targetCRatio) / HUNDRED;

            uint256 collateralTokenNeeded = div(mul(scaledDownDebtValue, WAD), collateralPrice);
            collateralTokenNeeded         = (depositedCollateralToken < collateralTokenNeeded) ?
              sub(collateralTokenNeeded, depositedCollateralToken) : MAX_UINT;

            // See if there's enough collateral to add to the SAFE in order to save it
            if (collateralTokenNeeded <= collateralFromLP) {
              return (sysCoinsFromLP, collateralTokenNeeded);
            } else {
              return (0, 0);
            }
        }
    }
    /*
    * @notice Return the amount of system coins and/or collateral tokens used to pay a keeper
    * @param safeHandler The handler/address of the targeted SAFE
    * @param redemptionPrice The system coin redemption price used in calculations
    * @param safeDebtRepaid The amount of system coins that are already used to save the targeted SAFE
    * @param safeCollateralAdded The amount of collateral tokens that are already used to save the targeted SAFE
    */
    function getKeeperPayoutTokens(address safeHandler, uint256 redemptionPrice, uint256 safeDebtRepaid, uint256 safeCollateralAdded)
      public view returns (uint256, uint256) {
        // Get the system coin and collateral market prices
        uint256 collateralPrice    = getCollateralPrice();
        uint256 sysCoinMarketPrice = getSystemCoinMarketPrice();
        if (either(collateralPrice == 0, sysCoinMarketPrice == 0)) {
            return (0, 0);
        }

        // Calculate underlying amounts received from LP withdrawal
        (uint256 sysCoinsFromLP, uint256 collateralFromLP) = getLPUnderlying(safeHandler);

        // Check if the keeper can get system coins and if yes, compute how many
        uint256 keeperSysCoins;
        if (sysCoinsFromLP > safeDebtRepaid) {
            uint256 remainingSystemCoins = sub(sysCoinsFromLP, safeDebtRepaid);
            uint256 payoutInSystemCoins  = div(mul(minKeeperPayoutValue, WAD), sysCoinMarketPrice);

            if (payoutInSystemCoins <= remainingSystemCoins) {
              return (payoutInSystemCoins, 0);
            } else {
              keeperSysCoins = remainingSystemCoins;
            }
        }

        // Calculate how much collateral the keeper will get
        if (collateralFromLP <= safeCollateralAdded) return (0, 0);

        uint256 remainingCollateral        = sub(collateralFromLP, safeCollateralAdded);
        uint256 remainingKeeperPayoutValue = sub(minKeeperPayoutValue, mul(keeperSysCoins, sysCoinMarketPrice) / WAD);
        uint256 collateralTokenNeeded      = div(mul(remainingKeeperPayoutValue, WAD), collateralPrice);

        // If there are enough collateral tokens retreived from LP in order to pay the keeper, return the token amounts
        if (collateralTokenNeeded <= remainingCollateral) {
          return (keeperSysCoins, collateralTokenNeeded);
        } else {
          // Otherwise, return zeroes
          return (0, 0);
        }
    }
    /*
    * @notify Returns whether a target debt amount is below the debt floor of a specific collateral type
    * @param collateralType The collateral type whose floor we compare against
    * @param targetDebtAmount The target debt amount for a SAFE that has collateralType collateral in it
    */
    function debtBelowFloor(bytes32 collateralType, uint256 targetDebtAmount) public view returns (bool) {
        (, , , , uint256 debtFloor, ) = safeEngine.collateralTypes(collateralType);
        return (mul(targetDebtAmount, RAY) < debtFloor);
    }
    /*
    * @notify Get the accumulated interest rate for a specific collateral type
    * @param The collateral type for which to retrieve the rate
    */
    function getAccumulatedRate(bytes32 collateralType)
      public view returns (uint256 accumulatedRate) {
        (, accumulatedRate, , , , ) = safeEngine.collateralTypes(collateralType);
    }
}