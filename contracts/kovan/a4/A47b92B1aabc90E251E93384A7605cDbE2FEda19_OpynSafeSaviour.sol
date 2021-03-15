// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract CollateralJoinLike {
    function safeEngine() public view virtual returns (address);

    function collateralType() public view virtual returns (bytes32);

    function collateral() public view virtual returns (address);

    function decimals() public view virtual returns (uint256);

    function contractEnabled() public view virtual returns (uint256);

    function join(address, uint256) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract ERC20Like {
    uint256 public totalSupply;

    function balanceOf(address guy) public virtual returns (uint256);

    function approve(address guy, uint256 wad) public virtual returns (bool);

    function transfer(address dst, uint256 wad) public virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract GebSafeManagerLike {
    function safes(uint256) public view virtual returns (address);

    function ownsSAFE(uint256) public view virtual returns (address);

    function safeCan(
        address,
        uint256,
        address
    ) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract LiquidationEngineLike {
    function safeSaviours(address) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

pragma experimental ABIEncoderV2;

enum ActionType {
    OpenVault,
    MintShortOption,
    BurnShortOption,
    DepositLongOption,
    WithdrawLongOption,
    DepositCollateral,
    WithdrawCollateral,
    SettleVault,
    Redeem,
    Call
}

struct ActionArgs {
    ActionType actionType;
    address owner;
    address secondAddress;
    address asset;
    uint256 vaultId;
    uint256 amount;
    uint256 index;
    bytes data;
}

abstract contract OpynV2ControllerLike {
    function operate(ActionArgs[] calldata _actions) external virtual;

    function getPayout(address _otoken, uint256 _amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OpynV2OTokenLike {
    function getOtokenDetails()
        external
        view
        virtual
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OpynV2WhitelistLike {
    function isWhitelistedOtoken(address _otoken) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OracleRelayerLike {
    function collateralTypes(bytes32)
        public
        view
        virtual
        returns (
            address,
            uint256,
            uint256
        );

    function liquidationCRatio(bytes32) public view virtual returns (uint256);

    function redemptionPrice() public virtual returns (uint256);
}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract PriceFeedLike {
    function priceSource() public view virtual returns (address);

    function getResultWithValidity() external view virtual returns (uint256, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract SAFEEngineLike {
    function safeRights(address, address) public view virtual returns (uint256);

    function collateralTypes(bytes32)
        public
        view
        virtual
        returns (
            uint256 debtAmount, // [wad]
            uint256 accumulatedRate, // [ray]
            uint256 safetyPrice, // [ray]
            uint256 debtCeiling, // [rad]
            uint256 debtFloor, // [rad]
            uint256 liquidationPrice // [ray]
        );

    function safes(bytes32, address)
        public
        view
        virtual
        returns (
            uint256 lockedCollateral, // [wad]
            uint256 generatedDebt // [wad]
        );

    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral, // [wad]
        int256 deltaDebt // [wad]
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract SAFESaviourRegistryLike {
    mapping(address => uint256) public authorizedAccounts;

    function markSave(bytes32 collateralType, address safeHandler) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

import './CollateralJoinLike.sol';
import './OracleRelayerLike.sol';
import './SAFEEngineLike.sol';
import './LiquidationEngineLike.sol';
import './PriceFeedLike.sol';
import './ERC20Like.sol';
import './GebSafeManagerLike.sol';
import './SAFESaviourRegistryLike.sol';

import '../utils/ReentrancyGuard.sol';

abstract contract SafeSaviourLike is ReentrancyGuard {
    // --- Variables ---
    LiquidationEngineLike public liquidationEngine;
    OracleRelayerLike public oracleRelayer;
    GebSafeManagerLike public safeManager;
    SAFEEngineLike public safeEngine;
    SAFESaviourRegistryLike public saviourRegistry;

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    // The amount of tokens the keeper gets in exchange for the gas spent to save a SAFE
    uint256 public keeperPayout; // [wad]
    // The minimum fiat value that the keeper must get in exchange for saving a SAFE
    uint256 public minKeeperPayoutValue; // [wad]
    /*
      The proportion between the keeperPayout (if it's in collateral) and the amount of collateral that's in a SAFE to be saved.
      Alternatively, it can be the proportion between the fiat value of keeperPayout and the fiat value of the profit that a keeper
      could make if a SAFE is liquidated right now. It ensures there's no incentive to intentionally put a SAFE underwater and then
      save it just to make a profit that's greater than the one from participating in collateral auctions
    */
    uint256 public payoutToSAFESize;
    // The default collateralization ratio a SAFE should have after it's saved
    uint256 public defaultDesiredCollateralizationRatio; // [percentage]

    // Desired CRatios for each SAFE after they're saved
    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;

    // --- Constants ---
    uint256 public constant ONE = 1;
    uint256 public constant HUNDRED = 100;
    uint256 public constant THOUSAND = 1000;
    uint256 public constant CRATIO_SCALE_DOWN = 10**25;
    uint256 public constant WAD_COMPLEMENT = 10**9;
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant MAX_CRATIO = 1000;
    uint256 public constant MAX_UINT = uint256(-1);

    // --- Events ---
    event SetDesiredCollateralizationRatio(
        address indexed caller,
        uint256 indexed safeID,
        address indexed safeHandler,
        uint256 cRatio
    );
    event SaveSAFE(
        address indexed keeper,
        bytes32 indexed collateralType,
        address indexed safeHandler,
        uint256 collateralAddedOrDebtRepaid
    );

    // --- Functions to Implement ---
    function saveSAFE(
        address,
        bytes32,
        address
    )
        external
        virtual
        returns (
            bool,
            uint256,
            uint256
        );

    function getKeeperPayoutValue() public virtual returns (uint256);

    function keeperPayoutExceedsMinValue() public virtual returns (bool);

    function canSave(address) external virtual returns (bool);

    function tokenAmountUsedToSave(address) public virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract UniswapV2Router02Like {
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.8.2;

import '../interfaces/SafeSaviourLike.sol';
import './OpynSafeSaviourOperator.sol';
import '../math/SafeMath.sol';

contract OpynSafeSaviour is SafeMath, SafeSaviourLike {
    // --- Variables ---
    // Amount of collateral deposited to cover each SAFE
    mapping(address => uint256) public oTokenCover;
    // oToken type selected by each SAFE
    mapping(address => address) public oTokenSelection;
    // The collateral join contract for adding collateral in the system
    CollateralJoinLike public collateralJoin;
    // The collateral token
    ERC20Like public collateralToken;
    // Operator handling all the Opyn logic
    OpynSafeSaviourOperator public opynSafeSaviourOperator;

    // Checks whether a saviour contract has been approved by governance in the LiquidationEngine
    modifier liquidationEngineApproved(address saviour) {
        require(liquidationEngine.safeSaviours(saviour) == 1, 'SafeSaviour/not-approved-in-liquidation-engine');
        _;
    }
    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), 'SafeSaviour/null-owner');
        require(
            either(
                owner == safeManager.ownsSAFE(safeID),
                safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1
            ),
            'SafeSaviour/not-owning-safe'
        );

        _;
    }

    // --- Events ---
    event Deposit(address indexed caller, address indexed safeHandler, uint256 amount);
    event Withdraw(address indexed caller, uint256 indexed safeID, address indexed safeHandler, uint256 amount);

    constructor(
        address _collateralJoin,
        address _liquidationEngine,
        address _oracleRelayer,
        address _safeManager,
        address _saviourRegistry,
        address _opynSafeSaviourOperator,
        uint256 _keeperPayout,
        uint256 _minKeeperPayoutValue,
        uint256 _payoutToSAFESize,
        uint256 _defaultDesiredCollateralizationRatio
    ) {
        require(_collateralJoin != address(0), 'OpynSafeSaviour/null-collateral-join');
        require(_liquidationEngine != address(0), 'OpynSafeSaviour/null-liquidation-engine');
        require(_oracleRelayer != address(0), 'OpynSafeSaviour/null-oracle-relayer');
        require(_safeManager != address(0), 'OpynSafeSaviour/null-safe-manager');
        require(_saviourRegistry != address(0), 'OpynSafeSaviour/null-saviour-registry');
        require(_opynSafeSaviourOperator != address(0), 'OpynSafeSaviour/null-opyn-safe-saviour-operator');
        require(_keeperPayout > 0, 'OpynSafeSaviour/invalid-keeper-payout');
        require(_minKeeperPayoutValue > 0, 'OpynSafeSaviour/invalid-min-payout-value');
        require(_payoutToSAFESize > 1, 'OpynSafeSaviour/invalid-payout-to-safe-size');
        require(_defaultDesiredCollateralizationRatio > 0, 'OpynSafeSaviour/null-default-cratio');

        keeperPayout = _keeperPayout;
        payoutToSAFESize = _payoutToSAFESize;
        minKeeperPayoutValue = _minKeeperPayoutValue;

        liquidationEngine = LiquidationEngineLike(_liquidationEngine);
        collateralJoin = CollateralJoinLike(_collateralJoin);
        oracleRelayer = OracleRelayerLike(_oracleRelayer);
        safeEngine = SAFEEngineLike(collateralJoin.safeEngine());
        safeManager = GebSafeManagerLike(_safeManager);
        saviourRegistry = SAFESaviourRegistryLike(_saviourRegistry);
        collateralToken = ERC20Like(collateralJoin.collateral());
        opynSafeSaviourOperator = OpynSafeSaviourOperator(_opynSafeSaviourOperator);

        require(address(safeEngine) != address(0), 'OpynSafeSaviour/null-safe-engine');

        uint256 scaledLiquidationRatio =
            oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;
        require(scaledLiquidationRatio > 0, 'OpynSafeSaviour/invalid-scaled-liq-ratio');
        require(
            both(
                _defaultDesiredCollateralizationRatio > scaledLiquidationRatio,
                _defaultDesiredCollateralizationRatio <= MAX_CRATIO
            ),
            'OpynSafeSaviour/invalid-default-desired-cratio'
        );

        require(collateralJoin.decimals() == 18, 'OpynSafeSaviour/invalid-join-decimals');
        require(collateralJoin.contractEnabled() == 1, 'OpynSafeSaviour/join-disabled');

        defaultDesiredCollateralizationRatio = _defaultDesiredCollateralizationRatio;
    }

    // --- Adding/Withdrawing Cover ---
    /*
     * @notice Deposit oToken in the contract in order to provide cover for a specific SAFE controlled by the SAFE Manager
     * @param safeID The ID of the SAFE to protect. This ID should be registered inside GebSafeManager
     * @param oTokenAmount The amount of oToken to deposit
     * @param oTokenType the address of the erc20 contract controlling the oTokens
     */
    function deposit(
        uint256 _safeID,
        uint256 _oTokenAmount,
        address _oTokenType
    ) external liquidationEngineApproved(address(this)) controlsSAFE(msg.sender, _safeID) nonReentrant {
        require(_oTokenAmount > 0, 'OpynSafeSaviour/null-oToken-amount');
        // Check that oToken has been whitelisted by a SaviourRegistry authorized account
        require(opynSafeSaviourOperator.oTokenWhitelist(_oTokenType) == true, 'OpynSafeSaviour/forbidden-otoken');

        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(_safeID);
        require(safeHandler != address(0), 'OpynSafeSaviour/null-handler');

        // Check that safe is either protected by provided oToken type or no type at all
        require(
            either(oTokenSelection[safeHandler] == _oTokenType, oTokenSelection[safeHandler] == address(0)),
            'OpynSafeSaviour/safe-otoken-incompatibility'
        );

        // Check that the SAFE has debt
        (, uint256 safeDebt) =
            SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeDebt > 0, 'OpynSafeSaviour/safe-does-not-have-debt');

        // Trigger transfer from oToken contract
        require(
            ERC20Like(_oTokenType).transferFrom(msg.sender, address(this), _oTokenAmount),
            'OpynSafeSaviour/could-not-transfer-collateralToken'
        );
        // Update the collateralToken balance used to cover the SAFE and transfer collateralToken to this contract
        oTokenCover[safeHandler] = add(oTokenCover[safeHandler], _oTokenAmount);

        // Check if SAFE oToken selection should be changed
        if (oTokenSelection[safeHandler] == address(0)) {
            oTokenSelection[safeHandler] = _oTokenType;
        }

        emit Deposit(msg.sender, safeHandler, _oTokenAmount);
    }

    /*
     * @notice Withdraw oToken from the contract and provide less cover for a SAFE
     * @dev Only an address that controls the SAFE inside GebSafeManager can call this
     * @param safeID The ID of the SAFE to remove cover from. This ID should be registered inside GebSafeManager
     * @param oTokenAmount The amount of oToken to withdraw
     */
    function withdraw(uint256 _safeID, uint256 _oTokenAmount) external controlsSAFE(msg.sender, _safeID) nonReentrant {
        require(_oTokenAmount > 0, 'OpynSafeSaviour/null-collateralToken-amount');

        // Fetch the handler from the SAFE manager
        address safeHandler = safeManager.safes(_safeID);
        require(oTokenCover[safeHandler] >= _oTokenAmount, 'OpynSafeSaviour/not-enough-to-withdraw');

        // Withdraw cover and transfer collateralToken to the caller
        oTokenCover[safeHandler] = sub(oTokenCover[safeHandler], _oTokenAmount);
        ERC20Like(oTokenSelection[safeHandler]).transfer(msg.sender, _oTokenAmount);

        // Check if balance of selected token
        if (oTokenCover[safeHandler] == 0) {
            oTokenSelection[safeHandler] = address(0);
        }

        emit Withdraw(msg.sender, _safeID, safeHandler, _oTokenAmount);
    }

    // --- Adjust Cover Preferences ---
    /*
     * @notice Sets the collateralization ratio that a SAFE should have after it's saved
     * @dev Only an address that controls the SAFE inside GebSafeManager can call this
     * @param safeID The ID of the SAFE to set the desired CRatio for. This ID should be registered inside GebSafeManager
     * @param cRatio The collateralization ratio to set
     */
    function setDesiredCollateralizationRatio(uint256 _safeID, uint256 _cRatio)
        external
        controlsSAFE(msg.sender, _safeID)
    {
        uint256 scaledLiquidationRatio =
            oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;
        address safeHandler = safeManager.safes(_safeID);

        require(scaledLiquidationRatio > 0, 'OpynSafeSaviour/invalid-scaled-liq-ratio');
        require(scaledLiquidationRatio < _cRatio, 'OpynSafeSaviour/invalid-desired-cratio');
        require(_cRatio <= MAX_CRATIO, 'OpynSafeSaviour/exceeds-max-cratio');

        desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler] = _cRatio;

        emit SetDesiredCollateralizationRatio(msg.sender, _safeID, safeHandler, _cRatio);
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
    function saveSAFE(
        address _keeper,
        bytes32 _collateralType,
        address _safeHandler
    )
        external
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        require(address(liquidationEngine) == msg.sender, 'OpynSafeSaviour/caller-not-liquidation-engine');
        require(_keeper != address(0), 'OpynSafeSaviour/null-keeper-address');

        if (both(both(_collateralType == '', _safeHandler == address(0)), _keeper == address(liquidationEngine))) {
            return (true, MAX_UINT, MAX_UINT);
        }

        require(_collateralType == collateralJoin.collateralType(), 'OpynSafeSaviour/invalid-collateral-type');
        require(oTokenSelection[_safeHandler] != address(0), 'OpynSafeSaviour/no-selected-otoken');

        // Check that the fiat value of the keeper payout is high enough
        require(keeperPayoutExceedsMinValue(), 'OpynSafeSaviour/small-keeper-payout-value');

        // Compute the amount of collateral that should be added to bring the safe to desired collateral ratio
        uint256 tokenAmountUsed = tokenAmountUsedToSave(_safeHandler);

        {
            // Stack too deep guard

            // Check that the amount of collateral locked in the safe is bigger than the keeper's payout
            (uint256 safeLockedCollateral, ) =
                SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), _safeHandler);
            require(safeLockedCollateral >= mul(keeperPayout, payoutToSAFESize), 'OpynSafeSaviour/tiny-safe');
        }

        // Compute and check the validity of the amount of collateralToken used to save the SAFE
        require(both(tokenAmountUsed != MAX_UINT, tokenAmountUsed != 0), 'OpynSafeSaviour/invalid-tokens-used-to-save');

        // The actual required collateral to provide is the sum of what is needed to bring the safe to its desired collateral ratio + the keeper reward
        uint256 requiredTokenAmount = add(keeperPayout, tokenAmountUsed);

        uint256 oTokenToApprove =
            opynSafeSaviourOperator.getOTokenAmountToApprove(
                oTokenSelection[_safeHandler],
                requiredTokenAmount,
                address(collateralToken)
            );

        require(oTokenCover[_safeHandler] >= oTokenToApprove, 'OpynSafeSaviour/otoken-balance-too-low');

        ERC20Like(oTokenSelection[_safeHandler]).approve(address(opynSafeSaviourOperator), oTokenToApprove);

        uint256 initialAmount = collateralToken.balanceOf(address(this));

        opynSafeSaviourOperator.redeemAndSwapOTokens(
            oTokenSelection[_safeHandler],
            oTokenToApprove,
            requiredTokenAmount,
            address(collateralToken)
        );

        uint256 receivedCollateralAmount = sub(collateralToken.balanceOf(address(this)), initialAmount);
        oTokenCover[_safeHandler] = sub(oTokenCover[_safeHandler], oTokenToApprove);

        // Check that balance has increased of at least required amount
        // This should never get triggered but is the ultimate check to ensure that the Safe Saviour Operator did its job properly
        require(
            receivedCollateralAmount >= requiredTokenAmount,
            'OpynSafeSaviour/not-enough-otoken-collateral-swapped'
        );

        saviourRegistry.markSave(_collateralType, _safeHandler);

        // Approve collateralToken to the collateral join contract
        collateralToken.approve(address(collateralJoin), 0);
        collateralToken.approve(address(collateralJoin), tokenAmountUsed);

        // Join collateralToken in the system and add it in the saved SAFE
        collateralJoin.join(address(this), tokenAmountUsed);
        safeEngine.modifySAFECollateralization(
            collateralJoin.collateralType(),
            _safeHandler,
            address(this),
            address(0),
            int256(tokenAmountUsed),
            int256(0)
        );

        // Send the fee to the keeper, the prize is recomputed to prevent dust
        collateralToken.transfer(_keeper, sub(receivedCollateralAmount, tokenAmountUsed));

        // Emit an event
        emit SaveSAFE(_keeper, _collateralType, _safeHandler, tokenAmountUsed);

        return (true, tokenAmountUsed, keeperPayout);
    }

    // --- Getters ---
    /*
     * @notice Compute whether the value of keeperPayout collateralToken is higher than or equal to minKeeperPayoutValue
     * @dev Used to determine whether it's worth it for the keeper to save the SAFE in exchange for keeperPayout collateralToken
     * @return A bool representing whether the value of keeperPayout collateralToken is >= minKeeperPayoutValue
     */
    function keeperPayoutExceedsMinValue() public view override returns (bool) {
        (address ethFSM, , ) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) =
            PriceFeedLike(PriceFeedLike(ethFSM).priceSource()).getResultWithValidity();

        if (either(!hasValidValue, priceFeedValue == 0)) {
            return false;
        }

        return (minKeeperPayoutValue <= mul(keeperPayout, priceFeedValue) / WAD);
    }

    /*
     * @notice Return the current value of the keeper payout
     */
    function getKeeperPayoutValue() public view override returns (uint256) {
        (address ethFSM, , ) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) =
            PriceFeedLike(PriceFeedLike(ethFSM).priceSource()).getResultWithValidity();

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
    function canSave(address _safeHandler) external override returns (bool) {
        uint256 tokenAmountUsed = tokenAmountUsedToSave(_safeHandler);

        if (tokenAmountUsed == MAX_UINT) {
            return false;
        }

        // Check if oToken balance is not empty
        if (oTokenCover[_safeHandler] == 0) {
            return false;
        }

        // Check that the fiat value of the keeper payout is high enough
        if (keeperPayoutExceedsMinValue() == false) {
            return false;
        }

        // check if safe too small to be saved
        (uint256 safeLockedCollateral, ) =
            SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), _safeHandler);
        if (safeLockedCollateral < mul(keeperPayout, payoutToSAFESize)) {
            return false;
        }

        uint256 oTokenToApprove =
            opynSafeSaviourOperator.getOTokenAmountToApprove(
                oTokenSelection[_safeHandler],
                add(tokenAmountUsed, keeperPayout),
                address(collateralToken)
            );

        // Check that owned oTokens are able to redeem enough collateral to save SAFE
        return (oTokenToApprove <= oTokenCover[_safeHandler]);
    }

    /*
     * @notice Calculate the amount of collateralToken used to save a SAFE and bring its CRatio to the desired level
     * @param safeHandler The handler of the SAFE which the function takes into account
     * @return The amount of collateralToken used to save the SAFE and bring its CRatio to the desired level
     */
    function tokenAmountUsedToSave(address _safeHandler) public override returns (uint256 tokenAmountUsed) {
        (uint256 depositedcollateralToken, uint256 safeDebt) =
            SAFEEngineLike(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), _safeHandler);
        (address ethFSM, , ) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) = PriceFeedLike(ethFSM).getResultWithValidity();

        // If the SAFE doesn't have debt or if the price feed is faulty, abort
        if (either(safeDebt == 0, either(priceFeedValue == 0, !hasValidValue))) {
            tokenAmountUsed = MAX_UINT;
            return tokenAmountUsed;
        }

        // Calculate the value of the debt equivalent to the value of the collateralToken that would need to be in the SAFE after it's saved
        uint256 targetCRatio =
            (desiredCollateralizationRatios[collateralJoin.collateralType()][_safeHandler] == 0)
                ? defaultDesiredCollateralizationRatio
                : desiredCollateralizationRatios[collateralJoin.collateralType()][_safeHandler];
        uint256 scaledDownDebtValue =
            mul(add(mul(oracleRelayer.redemptionPrice(), safeDebt) / RAY, ONE), targetCRatio) / HUNDRED;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

pragma experimental ABIEncoderV2;

import '../interfaces/OpynV2OTokenLike.sol';
import '../interfaces/OpynV2ControllerLike.sol';
import '../interfaces/OpynV2WhitelistLike.sol';
import '../interfaces/UniswapV2Router02Like.sol';
import '../interfaces/SAFESaviourRegistryLike.sol';
import '../interfaces/ERC20Like.sol';
import '../math/SafeMath.sol';

contract OpynSafeSaviourOperator is SafeMath {
    // The Opyn v2 Controller to interact with oTokens
    OpynV2ControllerLike public opynV2Controller;
    // The Opyn v2 Whitelist to check oTokens' validity
    OpynV2WhitelistLike public opynV2Whitelist;
    // The Uniswap v2 router 02 to swap collaterals
    UniswapV2Router02Like public uniswapV2Router02;
    // oToken type selected by each SAFE
    mapping(address => address) public oTokenSelection;
    // Entity whitelisting allowed saviours
    SAFESaviourRegistryLike public saviourRegistry;

    // Events
    event ToggleOToken(address oToken, uint256 whitelistState);

    constructor(
        address opynV2Controller_,
        address opynV2Whitelist_,
        address uniswapV2Router02_,
        address saviourRegistry_
    ) {
        require(opynV2Controller_ != address(0), 'OpynSafeSaviour/null-opyn-v2-controller');
        require(opynV2Whitelist_ != address(0), 'OpynSafeSaviour/null-opyn-v2-whitelist');
        require(uniswapV2Router02_ != address(0), 'OpynSafeSaviour/null-uniswap-v2-router02');
        require(saviourRegistry_ != address(0), 'OpynSafeSaviour/null-saviour-registry');

        opynV2Controller = OpynV2ControllerLike(opynV2Controller_);
        opynV2Whitelist = OpynV2WhitelistLike(opynV2Whitelist_);
        uniswapV2Router02 = UniswapV2Router02Like(uniswapV2Router02_);
        saviourRegistry = SAFESaviourRegistryLike(saviourRegistry_);
    }

    function isOTokenPutOption(address _otoken) external view returns (bool) {
        (, , , , , bool isPut) = OpynV2OTokenLike(_otoken).getOtokenDetails();
        return isPut;
    }

    function getOpynPayout(address _otoken, uint256 _amount) external view returns (uint256) {
        return opynV2Controller.getPayout(_otoken, _amount);
    }

    modifier isSaviourRegistryAuthorized() {
        require(saviourRegistry.authorizedAccounts(msg.sender) == 1, 'OpynSafeSaviour/account-not-authorized');
        _;
    }

    function redeemAndSwapOTokens(
        address _otoken,
        uint256 _amountIn,
        uint256 _amountOut,
        address _safeCollateral
    ) external {
        ERC20Like(_otoken).transferFrom(msg.sender, address(this), _amountIn);

        (address oTokenCollateral, , , , , ) = OpynV2OTokenLike(_otoken).getOtokenDetails();

        uint256 redeemedOTokenCollateral;

        {
            // Opyn Redeem

            uint256 preRedeemBalance = ERC20Like(oTokenCollateral).balanceOf(address(this));

            // Build Opyn Action
            ActionArgs[] memory redeemAction = new ActionArgs[](1);
            redeemAction[0].actionType = ActionType.Redeem;
            redeemAction[0].owner = address(0);
            redeemAction[0].secondAddress = address(this);
            redeemAction[0].asset = _otoken;
            redeemAction[0].vaultId = 0;
            redeemAction[0].amount = _amountIn;

            // Trigger oToken collateral redeem
            opynV2Controller.operate(redeemAction);

            redeemedOTokenCollateral = sub(ERC20Like(oTokenCollateral).balanceOf(address(this)), preRedeemBalance);
        }

        uint256 swappedSafeCollateral;

        {
            // Uniswap swap

            // Retrieve pre-swap WETH balance
            uint256 safeCollateralBalance = ERC20Like(_safeCollateral).balanceOf(address(this));

            // Path argument for the uniswap router
            address[] memory path = new address[](2);
            path[0] = oTokenCollateral;
            path[1] = _safeCollateral;

            ERC20Like(oTokenCollateral).approve(address(uniswapV2Router02), redeemedOTokenCollateral);

            uniswapV2Router02.swapExactTokensForTokens(
                redeemedOTokenCollateral,
                _amountOut,
                path,
                address(this),
                block.timestamp
            );

            // Retrieve post-swap WETH balance. Would overflow and throw if balance decreased
            swappedSafeCollateral = sub(ERC20Like(_safeCollateral).balanceOf(address(this)), safeCollateralBalance);
        }

        ERC20Like(_safeCollateral).transfer(msg.sender, swappedSafeCollateral);
    }

    function oTokenWhitelist(address _otoken) external view returns (bool) {
        return opynV2Whitelist.isWhitelistedOtoken(_otoken);
    }

    function getOTokenAmountToApprove(
        address _otoken,
        uint256 _requiredOutputAmount,
        address _safeCollateralAddress
    ) external view returns (uint256) {
        (address oTokenCollateralAddress, , , , , ) = OpynV2OTokenLike(_otoken).getOtokenDetails();

        address[] memory path = new address[](2);
        path[0] = oTokenCollateralAddress;
        path[1] = _safeCollateralAddress;

        uint256 oTokenCollateralAmountRequired = uniswapV2Router02.getAmountsIn(_requiredOutputAmount, path)[0];

        uint256 payoutPerToken = opynV2Controller.getPayout(_otoken, 1);

        require(payoutPerToken > 0, 'OpynSafeSaviour/no-collateral-to-redeem');

        uint256 amountToApprove = div(oTokenCollateralAmountRequired, payoutPerToken);

        // Integer division rounds to zero, better ensure we get at least the required amount
        if (mul(amountToApprove, payoutPerToken) < _requiredOutputAmount) {
            amountToApprove += 1;
        }

        return amountToApprove;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

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

    constructor() {
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
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}