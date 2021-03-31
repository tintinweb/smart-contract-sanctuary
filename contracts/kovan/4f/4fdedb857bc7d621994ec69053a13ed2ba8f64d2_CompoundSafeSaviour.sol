/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

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

pragma solidity ^0.6.7;

// "0xad4AB4Cb7b8aDC45Bf2873507fC8700f3dFB9Dd3","0x75A807a667FbcB303f46c0F8Ca45fdfEF8fdC9AC","0xE5Ae4E49bEA485B5E5172EE6b1F99243cB15225c","0x807C8eCb73d9c8203d2b1369E678098B9370F2EA","0xB19bc2e13Bd6BAeeE8c0D8282387221D7f9b8833","100000000000000000","50000000000000000000","20","155"

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract LiquidationEngineLike {
    function safeSaviours(address) virtual public view returns (uint256);
}

abstract contract SAFESaviourRegistryLike {
    function markSave(bytes32 collateralType, address safeHandler) virtual external;
}

abstract contract CollateralJoinLike {
    function safeEngine() virtual public view returns (address);
    function collateralType() virtual public view returns (bytes32);
    function collateral() virtual public view returns (address);
    function decimals() virtual public view returns (uint256);
    function contractEnabled() virtual public view returns (uint256);
    function join(address, uint256) virtual external;
}

abstract contract ERC20Like {
    function approve(address guy, uint wad) virtual public returns (bool);
    function transfer(address dst, uint wad) virtual public returns (bool);
    function transferFrom(address src, address dst, uint wad)
        virtual
        public
        returns (bool);
}

abstract contract GebSafeManagerLike {
    function safes(uint256) virtual public view returns (address);
    function ownsSAFE(uint256) virtual public view returns (address);
    function safeCan(address,uint256,address) virtual public view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract OracleRelayerLike {
    function collateralTypes(bytes32) virtual public view returns (address, uint256, uint256);
    function liquidationCRatio(bytes32) virtual public view returns (uint256);
    function redemptionPrice() virtual public returns (uint256);
}

abstract contract PriceFeedLike {
    function priceSource() virtual public view returns (address);
    function getResultWithValidity() virtual external view returns (uint256,bool);
}

abstract contract SAFEEngineLike {
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


contract SAFESaviourRegistry {
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
        require(authorizedAccounts[msg.sender] == 1, "SAFESaviourRegistry/account-not-authorized");
        _;
    }

    // --- Other Modifiers ---
    modifier isSaviour {
        require(saviours[msg.sender] == 1, "SAFESaviourRegistry/not-a-saviour");
        _;
    }

    // --- Variables ---
    // Minimum amount of time that needs to elapse for a specific SAFE to be saved again
    uint256 public saveCooldown;

    // Timestamp for the last time when a specific SAFE has been saved
    mapping(bytes32 => mapping(address => uint256)) public lastSaveTime;

    // Whitelisted saviours
    mapping(address => uint256) public saviours;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 val);
    event ToggleSaviour(address saviour, uint256 whitelistState);
    event MarkSave(bytes32 indexed collateralType, address indexed safeHandler);

    constructor(uint256 saveCooldown_) public {
        require(saveCooldown_ > 0, "SAFESaviourRegistry/null-save-cooldown");
        authorizedAccounts[msg.sender] = 1;
        saveCooldown = saveCooldown_;
        emit ModifyParameters("saveCooldown", saveCooldown_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "SAFESaviourRegistry/add-uint-uint-overflow");
    }

    // --- Administration ---
    /*
    * @notice Change the saveCooldown value
    * @param parameter Name of the parameter to change
    * @param val The new value for the param
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        require(val > 0, "SAFESaviourRegistry/null-val");
        if (parameter == "saveCooldown") {
          saveCooldown = val;
        } else revert("SAFESaviourRegistry/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /*
    * @notice Whitelist/blacklist a saviour contract
    * @param saviour The saviour contract to whitelist/blacklist
    */
    function toggleSaviour(address saviour) external isAuthorized {
        if (saviours[saviour] == 0) {
          saviours[saviour] = 1;
        } else {
          saviours[saviour] = 0;
        }
        emit ToggleSaviour(saviour, saviours[saviour]);
    }

    // --- Core Logic ---
    /*
    * @notice Mark a new SAFE as just having been saved
    * @param collateralType The collateral type backing the SAFE
    * @param safeHandler The SAFE's handler
    */
    function markSave(bytes32 collateralType, address safeHandler) external isSaviour {
        require(
          either(lastSaveTime[collateralType][safeHandler] == 0,
          addition(lastSaveTime[collateralType][safeHandler], saveCooldown) < now),
          "SAFESaviourRegistry/wait-more-to-save"
        );
        lastSaveTime[collateralType][safeHandler] = now;
        emit MarkSave(collateralType, safeHandler);
    }
}

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
    LiquidationEngineLike   public liquidationEngine;
    OracleRelayerLike       public oracleRelayer;
    GebSafeManagerLike      public safeManager;
    SAFEEngineLike          public safeEngine;
    SAFESaviourRegistryLike public saviourRegistry;

    // The amount of tokens the keeper gets in exchange for the gas spent to save a SAFE
    uint256 public keeperPayout;          // [wad]
    // The minimum fiat value that the keeper must get in exchange for saving a SAFE
    uint256 public minKeeperPayoutValue;  // [wad]
    /*
      The proportion between the keeperPayout (if it's in collateral) and the amount of collateral that's in a SAFE to be saved.
      Alternatively, it can be the proportion between the fiat value of keeperPayout and the fiat value of the profit that a keeper
      could make if a SAFE is liquidated right now. It ensures there's no incentive to intentionally put a SAFE underwater and then
      save it just to make a profit that's greater than the one from participating in collateral auctions
    */
    uint256 public payoutToSAFESize;
    // The default collateralization ratio a SAFE should have after it's saved
    uint256 public defaultDesiredCollateralizationRatio;  // [percentage]

    // Desired CRatios for each SAFE after they're saved
    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;

    // --- Constants ---
    uint256 public constant ONE               = 1;
    uint256 public constant HUNDRED           = 100;
    uint256 public constant THOUSAND          = 1000;
    uint256 public constant CRATIO_SCALE_DOWN = 10**25;
    uint256 public constant WAD_COMPLEMENT    = 10**9;
    uint256 public constant WAD               = 10**18;
    uint256 public constant RAY               = 10**27;
    uint256 public constant MAX_CRATIO        = 1000;
    uint256 public constant MAX_UINT          = uint(-1);

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event SetDesiredCollateralizationRatio(address indexed caller, uint256 indexed safeID, address indexed safeHandler, uint256 cRatio);
    event SaveSAFE(address indexed keeper, bytes32 indexed collateralType, address indexed safeHandler, uint256 collateralAddedOrDebtRepaid);

    // --- Functions to Implement ---
    function saveSAFE(address,bytes32,address) virtual external returns (bool,uint256,uint256);
    function getKeeperPayoutValue() virtual public returns (uint256);
    function keeperPayoutExceedsMinValue() virtual public returns (bool);
    function canSave(address) virtual external returns (bool);
    function tokenAmountUsedToSave(address) virtual public returns (uint256);
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
contract Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

interface ICEth{
    function mint() external payable;
    function exchangeRateCurrent() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function balanceOf(address account)  external returns (uint256);
}

// CompoundSafeSaviour
contract CompoundSafeSaviour is SafeMath, SafeSaviourLike {
    // --- Variables ---
    // Amount of collateral deposited to cover each SAFE
    mapping(address => uint256) public collateralTokenCover;
    // The collateral join contract for adding collateral in the system
    CollateralJoinLike          public collateralJoin;
    // The collateral token
    ERC20Like                   public collateralToken;

    address cEth = 0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72; // KOVAN cToken

    // --- Events ---
    event Deposit(address indexed caller, address indexed safeHandler, uint256 amount);
    event Withdraw(address indexed caller, uint256 indexed safeID, address indexed safeHandler, uint256 amount);

    constructor(
      address collateralJoin_,
      address liquidationEngine_,
      address oracleRelayer_,
      address safeManager_,
      address saviourRegistry_,
      uint256 keeperPayout_,
      uint256 minKeeperPayoutValue_,
      uint256 payoutToSAFESize_,
      uint256 defaultDesiredCollateralizationRatio_
    ) public {
        require(collateralJoin_ != address(0), "GeneralTokenReserveSafeSaviour/null-collateral-join");
        require(liquidationEngine_ != address(0), "GeneralTokenReserveSafeSaviour/null-liquidation-engine");
        require(oracleRelayer_ != address(0), "GeneralTokenReserveSafeSaviour/null-oracle-relayer");
        require(safeManager_ != address(0), "GeneralTokenReserveSafeSaviour/null-safe-manager");
        require(saviourRegistry_ != address(0), "GeneralTokenReserveSafeSaviour/null-saviour-registry");
        require(keeperPayout_ > 0, "GeneralTokenReserveSafeSaviour/invalid-keeper-payout");
        require(defaultDesiredCollateralizationRatio_ > 0, "GeneralTokenReserveSafeSaviour/null-default-cratio");
        require(payoutToSAFESize_ > 1, "GeneralTokenReserveSafeSaviour/invalid-payout-to-safe-size");
        require(minKeeperPayoutValue_ > 0, "GeneralTokenReserveSafeSaviour/invalid-min-payout-value");

        keeperPayout         = keeperPayout_;
        payoutToSAFESize     = payoutToSAFESize_;
        minKeeperPayoutValue = minKeeperPayoutValue_;

        liquidationEngine    = LiquidationEngineLike(liquidationEngine_);
        collateralJoin       = CollateralJoinLike(collateralJoin_);
        oracleRelayer        = OracleRelayerLike(oracleRelayer_);
        safeEngine           = SAFEEngineLike(collateralJoin.safeEngine());
        safeManager          = GebSafeManagerLike(safeManager_);
        saviourRegistry      = SAFESaviourRegistryLike(saviourRegistry_);
        collateralToken      = ERC20Like(collateralJoin.collateral());

        require(address(safeEngine) != address(0), "GeneralTokenReserveSafeSaviour/null-safe-engine");
        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;

        require(scaledLiquidationRatio > 0, "GeneralTokenReserveSafeSaviour/invalid-scaled-liq-ratio");
        require(both(defaultDesiredCollateralizationRatio_ > scaledLiquidationRatio, defaultDesiredCollateralizationRatio_ <= MAX_CRATIO), "GeneralTokenReserveSafeSaviour/invalid-default-desired-cratio");
        require(collateralJoin.decimals() == 18, "GeneralTokenReserveSafeSaviour/invalid-join-decimals");
        require(collateralJoin.contractEnabled() == 1, "GeneralTokenReserveSafeSaviour/join-disabled");

        defaultDesiredCollateralizationRatio = defaultDesiredCollateralizationRatio_;
    }

    fallback() external payable {

    }

    // --- Adding/Withdrawing Cover ---
    /*
    * @notice Deposit collateralToken in the contract in order to provide cover for a specific SAFE controlled by the SAFE Manager
    * @param safeID The ID of the SAFE to protect. This ID should be registered inside GebSafeManager
    * @param collateralTokenAmount The amount of collateralToken to deposit
    */
    function deposit(uint256 safeID) external payable liquidationEngineApproved(address(this)) nonReentrant {
        require(msg.value > 0, "GeneralTokenReserveSafeSaviour/null-collateralToken-amount");

        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(safeID);
        require(safeHandler != address(0), "GeneralTokenReserveSafeSaviour/null-handler");

        // Check that the SAFE has debt
        (, uint256 safeDebt) =
          SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeDebt > 0, "GeneralTokenReserveSafeSaviour/safe-does-not-have-debt");

        // Update the collateralToken balance used to cover the SAFE and transfer collateralToken to this contract
        collateralTokenCover[safeHandler] = add(collateralTokenCover[safeHandler], msg.value);

        uint256 beforeBalance = IERC20(cEth).balanceOf(address(this));
        
        ICEth(cEth).mint{value: msg.value}();
        
        uint256 afterBalance = IERC20(cEth).balanceOf(address(this));
        
        require(beforeBalance < afterBalance, "GeneralTokenReserveSafeSaviour/could-not-transfer-collateralToken"); // new code
        // require(collateralToken.transferFrom(msg.sender, address(this), collateralTokenAmount), "GeneralTokenReserveSafeSaviour/could-not-transfer-collateralToken"); // old RAI code

        emit Deposit(msg.sender, safeHandler, msg.value);
    }
    /*
    * @notice Withdraw collateralToken from the contract and provide less cover for a SAFE
    * @dev Only an address that controls the SAFE inside GebSafeManager can call this
    * @param safeID The ID of the SAFE to remove cover from. This ID should be registered inside GebSafeManager
    * @param collateralTokenAmount The amount of collateralToken to withdraw
    */
    function withdraw(uint256 safeID, uint256 collateralTokenAmount) external controlsSAFE(msg.sender, safeID) nonReentrant {
        require(collateralTokenAmount > 0, "GeneralTokenReserveSafeSaviour/null-collateralToken-amount");

        // Fetch the handler from the SAFE manager
        address safeHandler = safeManager.safes(safeID);
        require(collateralTokenCover[safeHandler] >= collateralTokenAmount, "GeneralTokenReserveSafeSaviour/not-enough-to-withdraw");
        
        uint256 returnETH = div(mul(ICEth(cEth).exchangeRateCurrent(), collateralTokenAmount), 1e18);

        // Withdraw cover and transfer collateralToken to the caller
        collateralTokenCover[safeHandler] = sub(collateralTokenCover[safeHandler], collateralTokenAmount);
        IERC20(cEth).approve(cEth, collateralTokenAmount);
        ICEth(cEth).redeem(collateralTokenAmount); // Compound withdraw eth method
        payable(msg.sender).transfer(returnETH);

        emit Withdraw(msg.sender, safeID, safeHandler, collateralTokenAmount);
    }

    // --- Adjust Cover Preferences ---
    /*
    * @notice Sets the collateralization ratio that a SAFE should have after it's saved
    * @dev Only an address that controls the SAFE inside GebSafeManager can call this
    * @param safeID The ID of the SAFE to set the desired CRatio for. This ID should be registered inside GebSafeManager
    * @param cRatio The collateralization ratio to set
    */
    function setDesiredCollateralizationRatio(uint256 safeID, uint256 cRatio) external controlsSAFE(msg.sender, safeID) {
        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;
        address safeHandler = safeManager.safes(safeID);

        require(scaledLiquidationRatio > 0, "GeneralTokenReserveSafeSaviour/invalid-scaled-liq-ratio");
        require(scaledLiquidationRatio < cRatio, "GeneralTokenReserveSafeSaviour/invalid-desired-cratio");
        require(cRatio <= MAX_CRATIO, "GeneralTokenReserveSafeSaviour/exceeds-max-cratio");

        desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler] = cRatio;

        emit SetDesiredCollateralizationRatio(msg.sender, safeID, safeHandler, cRatio);
    }

    // --- Saving Logic ---
    /*
    * @notice Saves a SAFE by adding more collateralToken into it
    * @dev Only the LiquidationEngine can call this
    * @param keeper The keeper that called LiquidationEngine.liquidateSAFE and that should be rewarded for spending gas to save a SAFE
    * @param collateralType The collateral type backing the SAFE that's being liquidated
    * @param safeHandler The handler of the SAFE that's being saved
    * @return Whether the SAFE has been saved, the amount of collateralToken added in the SAFE as well as the amount of
    *         collateralToken sent to the keeper as their payment
    */
    function saveSAFE(address keeper, bytes32 collateralType, address safeHandler) override external returns (bool, uint256, uint256) {
        require(address(liquidationEngine) == msg.sender, "GeneralTokenReserveSafeSaviour/caller-not-liquidation-engine");
        require(keeper != address(0), "GeneralTokenReserveSafeSaviour/null-keeper-address");

        if (both(both(collateralType == "", safeHandler == address(0)), keeper == address(liquidationEngine))) {
            return (true, uint(-1), uint(-1));
        }

        require(collateralType == collateralJoin.collateralType(), "GeneralTokenReserveSafeSaviour/invalid-collateral-type");

        // Check that the fiat value of the keeper payout is high enough
        require(keeperPayoutExceedsMinValue(), "GeneralTokenReserveSafeSaviour/small-keeper-payout-value");

        // Check that the amount of collateral locked in the safe is bigger than the keeper's payout
        (uint256 safeLockedCollateral,) =
          SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeLockedCollateral >= mul(keeperPayout, payoutToSAFESize), "GeneralTokenReserveSafeSaviour/tiny-safe");

        // Compute and check the validity of the amount of collateralToken used to save the SAFE
        uint256 tokenAmountUsed = tokenAmountUsedToSave(safeHandler);
        require(both(tokenAmountUsed != MAX_UINT, tokenAmountUsed != 0), "GeneralTokenReserveSafeSaviour/invalid-tokens-used-to-save");

        // Check that there's enough collateralToken added as to cover both the keeper's payout and the amount used to save the SAFE
        require(collateralTokenCover[safeHandler] >= add(keeperPayout, tokenAmountUsed), "GeneralTokenReserveSafeSaviour/not-enough-cover-deposited");

        // Update the remaining cover
        collateralTokenCover[safeHandler] = sub(collateralTokenCover[safeHandler], add(keeperPayout, tokenAmountUsed));

        // Mark the SAFE in the registry as just being saved
        saviourRegistry.markSave(collateralType, safeHandler);

        IERC20(cEth).approve(cEth, add(keeperPayout, tokenAmountUsed));
        ICEth(cEth).redeemUnderlying(add(keeperPayout, tokenAmountUsed)); // Withdraw from Compound (cETH => ETH)
        IWETH(collateralJoin.collateral()).deposit{value: tokenAmountUsed}(); // ETH -> WETH

        // Approve collateralToken to the collateral join contract
        collateralToken.approve(address(collateralJoin), 0);
        collateralToken.approve(address(collateralJoin), tokenAmountUsed);

        // Join collateralToken in the system and add it in the saved SAFE
        collateralJoin.join(address(this), tokenAmountUsed);
        safeEngine.modifySAFECollateralization(
          collateralJoin.collateralType(),
          safeHandler,
          address(this),
          address(0),
          int256(tokenAmountUsed),
          int256(0)
        );

        // Send the fee to the keeper
        collateralToken.transfer(keeper, keeperPayout);

        // Emit an event
        emit SaveSAFE(keeper, collateralType, safeHandler, tokenAmountUsed);

        return (true, tokenAmountUsed, keeperPayout);
    }

    // --- Getters ---
    /*
    * @notice Compute whether the value of keeperPayout collateralToken is higher than or equal to minKeeperPayoutValue
    * @dev Used to determine whether it's worth it for the keeper to save the SAFE in exchange for keeperPayout collateralToken
    * @return A bool representing whether the value of keeperPayout collateralToken is >= minKeeperPayoutValue
    */
    function keeperPayoutExceedsMinValue() override public returns (bool) {
        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) = PriceFeedLike(PriceFeedLike(ethFSM).priceSource()).getResultWithValidity();

        if (either(!hasValidValue, priceFeedValue == 0)) {
          return false;
        }

        return (minKeeperPayoutValue <= mul(keeperPayout, priceFeedValue) / WAD);
    }
    /*
    * @notice Return the current value of the keeper payout
    */
    function getKeeperPayoutValue() override public returns (uint256) {
        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) = PriceFeedLike(PriceFeedLike(ethFSM).priceSource()).getResultWithValidity();

        if (either(!hasValidValue, priceFeedValue == 0)) {
          return 0;
        }

        return mul(keeperPayout, priceFeedValue) / WAD;
    }
    /*
    * @notice Determine whether a SAFE can be saved with the current amount of collateralToken deposited as cover for it
    * @param safeHandler The handler of the SAFE which the function takes into account
    * @return Whether the SAFE can be saved or not
    */
    function canSave(address safeHandler) override external returns (bool) {
        uint256 tokenAmountUsed = tokenAmountUsedToSave(safeHandler);

        if (tokenAmountUsed == MAX_UINT) {
            return false;
        }

        return (collateralTokenCover[safeHandler] >= add(tokenAmountUsed, keeperPayout));
    }
    /*
    * @notice Calculate the amount of collateralToken used to save a SAFE and bring its CRatio to the desired level
    * @param safeHandler The handler of the SAFE which the function takes into account
    * @return The amount of collateralToken used to save the SAFE and bring its CRatio to the desired level
    */
    function tokenAmountUsedToSave(address safeHandler) override public returns (uint256 tokenAmountUsed) {
        (uint256 depositedcollateralToken, uint256 safeDebt) =
          SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) = PriceFeedLike(ethFSM).getResultWithValidity();

        // If the SAFE doesn't have debt or if the price feed is faulty, abort
        if (either(safeDebt == 0, either(priceFeedValue == 0, !hasValidValue))) {
            tokenAmountUsed = MAX_UINT;
            return tokenAmountUsed;
        }

        // Calculate the value of the debt equivalent to the value of the collateralToken that would need to be in the SAFE after it's saved
        uint256 targetCRatio = (desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler] == 0) ?
          defaultDesiredCollateralizationRatio : desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler];
        uint256 scaledDownDebtValue = mul(add(mul(oracleRelayer.redemptionPrice(), safeDebt) / RAY, ONE), targetCRatio) / HUNDRED;

        // Compute the amount of collateralToken the SAFE needs to get to the desired CRatio
        uint256 collateralTokenAmountNeeded = mul(scaledDownDebtValue, WAD) / priceFeedValue;

        // If the amount of collateralToken needed is lower than the amount that's currently in the SAFE, return 0
        if (collateralTokenAmountNeeded <= depositedcollateralToken) {
          return 0;
        } else {
          // Otherwise return the delta
          return sub(collateralTokenAmountNeeded, depositedcollateralToken);
        }
    }
}