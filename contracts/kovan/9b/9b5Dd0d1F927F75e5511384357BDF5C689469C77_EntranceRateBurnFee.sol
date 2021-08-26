// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./IFeeManager.sol";

/// @title Fee Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all fees
interface IFee {
    function activateForFund(address _comptrollerProxy, address _vaultProxy) external;

    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData) external;

    function payout(address _comptrollerProxy, address _vaultProxy)
        external
        returns (bool isPayable_);

    function getRecipientForFund(address _comptrollerProxy)
        external
        view
        returns (address recipient_);

    function settle(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    )
        external
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        );

    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool settles_, bool usesGav_);

    function update(
        address _comptrollerProxy,
        address _vaultProxy,
        IFeeManager.FeeHook _hook,
        bytes calldata _settlementData,
        uint256 _gav
    ) external;

    function updatesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        returns (bool updates_, bool usesGav_);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title FeeManager Interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the FeeManager
interface IFeeManager {
    // No fees for the current release are implemented post-redeemShares
    enum FeeHook {Continuous, PreBuyShares, PostBuyShares, PreRedeemShares}
    enum SettlementType {None, Direct, Mint, Burn, MintSharesOutstanding, BurnSharesOutstanding}

    function invokeHook(
        FeeHook,
        bytes calldata,
        uint256
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./utils/EntranceRateFeeBase.sol";

/// @title EntranceRateBurnFee Contract
/// @author Enzyme Council <[email protected]>
/// @notice An EntranceRateFee that burns the fee shares
contract EntranceRateBurnFee is EntranceRateFeeBase {
    constructor(address _feeManager)
        public
        EntranceRateFeeBase(_feeManager, IFeeManager.SettlementType.Burn)
    {}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FeeBase.sol";

/// @title EntranceRateFeeBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Calculates a fee based on a rate to be charged to an investor upon entering a fund
abstract contract EntranceRateFeeBase is FeeBase {
    using SafeMath for uint256;

    event FundSettingsAdded(address indexed comptrollerProxy, uint256 rate);

    event Settled(address indexed comptrollerProxy, address indexed payer, uint256 sharesQuantity);

    uint256 private constant ONE_HUNDRED_PERCENT = 10000;
    IFeeManager.SettlementType private immutable SETTLEMENT_TYPE;

    mapping(address => uint256) private comptrollerProxyToRate;

    constructor(address _feeManager, IFeeManager.SettlementType _settlementType)
        public
        FeeBase(_feeManager)
    {
        require(
            _settlementType == IFeeManager.SettlementType.Burn ||
                _settlementType == IFeeManager.SettlementType.Direct,
            "constructor: Invalid _settlementType"
        );
        SETTLEMENT_TYPE = _settlementType;
    }

    // EXTERNAL FUNCTIONS

    /// @notice Add the initial fee settings for a fund
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settingsData Encoded settings to apply to the fee for a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _settingsData)
        public
        virtual
        override
        onlyFeeManager
    {
        uint256 rate = abi.decode(_settingsData, (uint256));
        require(rate > 0, "addFundSettings: Fee rate must be >0");
        require(rate < ONE_HUNDRED_PERCENT, "addFundSettings: Fee rate max exceeded");

        comptrollerProxyToRate[_comptrollerProxy] = rate;

        emit FundSettingsAdded(_comptrollerProxy, rate);
    }

    /// @notice Settles the fee
    /// @param _comptrollerProxy The ComptrollerProxy of the fund
    /// @param _settlementData Encoded args to use in calculating the settlement
    /// @return settlementType_ The type of settlement
    /// @return payer_ The payer of shares due
    /// @return sharesDue_ The amount of shares due
    function settle(
        address _comptrollerProxy,
        address,
        IFeeManager.FeeHook,
        bytes calldata _settlementData,
        uint256
    )
        external
        override
        onlyFeeManager
        returns (
            IFeeManager.SettlementType settlementType_,
            address payer_,
            uint256 sharesDue_
        )
    {
        uint256 sharesBought;
        (payer_, , sharesBought) = __decodePostBuySharesSettlementData(_settlementData);

        uint256 rate = comptrollerProxyToRate[_comptrollerProxy];
        sharesDue_ = sharesBought.mul(rate).div(ONE_HUNDRED_PERCENT.add(rate));

        if (sharesDue_ == 0) {
            return (IFeeManager.SettlementType.None, address(0), 0);
        }

        emit Settled(_comptrollerProxy, payer_, sharesDue_);

        return (SETTLEMENT_TYPE, payer_, sharesDue_);
    }

    /// @notice Gets whether the fee settles and requires GAV on a particular hook
    /// @param _hook The FeeHook
    /// @return settles_ True if the fee settles on the _hook
    /// @return usesGav_ True if the fee uses GAV during settle() for the _hook
    function settlesOnHook(IFeeManager.FeeHook _hook)
        external
        view
        override
        returns (bool settles_, bool usesGav_)
    {
        if (_hook == IFeeManager.FeeHook.PostBuyShares) {
            return (true, false);
        }

        return (false, false);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `rate` variable for a fund
    /// @param _comptrollerProxy The ComptrollerProxy contract for the fund
    /// @return rate_ The `rate` variable value
    function getRateForFund(address _comptrollerProxy) external view returns (uint256 rate_) {
        return comptrollerProxyToRate[_comptrollerProxy];
    }

    /// @notice Gets the `SETTLEMENT_TYPE` variable
    /// @return settlementType_ The `SETTLEMENT_TYPE` variable value
    function getSettlementType()
        external
        view
        returns (IFeeManager.SettlementType settlementType_)
    {
        return SETTLEMENT_TYPE;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../IFee.sol";

/// @title FeeBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Abstract base contract for all fees
abstract contract FeeBase is IFee {
    address internal immutable FEE_MANAGER;

    modifier onlyFeeManager {
        require(msg.sender == FEE_MANAGER, "Only the FeeManger can make this call");
        _;
    }

    constructor(address _feeManager) public {
        FEE_MANAGER = _feeManager;
    }

    /// @notice Allows Fee to run logic during fund activation
    /// @dev Unimplemented by default, may be overrode.
    function activateForFund(address, address) external virtual override {
        return;
    }

    /// @notice Gets the recipient of the fee for a given fund
    /// @dev address(0) signifies the VaultProxy owner.
    /// Returns address(0) by default, can be overridden by fee.
    function getRecipientForFund(address)
        external
        view
        virtual
        override
        returns (address recipient_)
    {
        return address(0);
    }

    /// @notice Runs payout logic for a fee that utilizes shares outstanding as its settlement type
    /// @dev Returns false by default, can be overridden by fee
    function payout(address, address) external virtual override returns (bool) {
        return false;
    }

    /// @notice Update fee state after all settlement has occurred during a given fee hook
    /// @dev Unimplemented by default, can be overridden by fee
    function update(
        address,
        address,
        IFeeManager.FeeHook,
        bytes calldata,
        uint256
    ) external virtual override {
        return;
    }

    /// @notice Gets whether the fee updates and requires GAV on a particular hook
    /// @return updates_ True if the fee updates on the _hook
    /// @return usesGav_ True if the fee uses GAV during update() for the _hook
    /// @dev Returns false values by default, can be overridden by fee
    function updatesOnHook(IFeeManager.FeeHook)
        external
        view
        virtual
        override
        returns (bool updates_, bool usesGav_)
    {
        return (false, false);
    }

    /// @notice Helper to parse settlement arguments from encoded data for PreBuyShares fee hook
    function __decodePreBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (address buyer_, uint256 investmentAmount_)
    {
        return abi.decode(_settlementData, (address, uint256));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PreRedeemShares fee hook
    function __decodePreRedeemSharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (address redeemer_, uint256 sharesQuantity_)
    {
        return abi.decode(_settlementData, (address, uint256));
    }

    /// @notice Helper to parse settlement arguments from encoded data for PostBuyShares fee hook
    function __decodePostBuySharesSettlementData(bytes memory _settlementData)
        internal
        pure
        returns (
            address buyer_,
            uint256 investmentAmount_,
            uint256 sharesBought_
        )
    {
        return abi.decode(_settlementData, (address, uint256, uint256));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FEE_MANAGER` variable
    /// @return feeManager_ The `FEE_MANAGER` variable value
    function getFeeManager() external view returns (address feeManager_) {
        return FEE_MANAGER;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": true,
      "peephole": true,
      "yul": false
    },
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}