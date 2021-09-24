// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {
    L1ArbitrumMessenger
} from "arb-bridge-peripherals/contracts/tokenbridge/ethereum/L1ArbitrumMessenger.sol";

import {IL2RebaseGateway} from "../../_interfaces/bridge-gateways/l2/IL2RebaseGateway.sol";
import {IL2TransferGateway} from "../../_interfaces/bridge-gateways/l2/IL2TransferGateway.sol";

import {IAmpleforth} from "uFragments/contracts/interfaces/IAmpleforth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITokenVault} from "../../_interfaces/ITokenVault.sol";

/**
 * @title AMPLArbitrumGateway: AMPL-Arbitrum Gateway Contract
 * @dev This contract is deployed on the base chain (Ethereum).
 *
 *      It's a pass-through contract between the Arbitrum's bridge and
 *      the Ampleforth policy.
 *
 */
contract AMPLArbitrumGateway is
    IL2RebaseGateway,
    IL2TransferGateway,
    L1ArbitrumMessenger,
    Initializable
{
    using SafeMath for uint256;

    address public immutable ampl;
    address public immutable policy;
    address public immutable vault;

    address public arbitrumInbox;
    address public counterpartGateway;

    // @dev Validate transaction commits over the bridge
    modifier onlyBridgeGateway() {
        address bridge = address(super.getBridge(arbitrumInbox));
        require(msg.sender == bridge, "AMPLArbitrumGateway: NOT_FROM_BRIDGE");

        address l2ToL1Sender = super.getL2ToL1Sender(arbitrumInbox);
        require(
            l2ToL1Sender == counterpartGateway,
            "AMPLArbitrumGateway: ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    /**
     * @dev Builds the payload and transmits rebase report to Arbitrum.
     * @param destinationGasParams The gas parameters for the satellite execution.
     */
    function reportRebaseInit(GasParams memory destinationGasParams) external payable override {
        uint256 recordedGlobalAmpleforthEpoch = IAmpleforth(policy).epoch();
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        emit XCRebaseReportOut(recordedGlobalAmpleforthEpoch, recordedGlobalAMPLSupply);

        // TODO: log sequence number
        sendTxToL2(
            arbitrumInbox,
            counterpartGateway,
            tx.origin,
            msg.value,
            0,
            destinationGasParams.maxSubmissionCost,
            destinationGasParams.maxGas,
            destinationGasParams.gasPriceBid,
            abi.encodeWithSelector(
                IL2RebaseGateway.reportRebaseCommit.selector,
                recordedGlobalAmpleforthEpoch,
                recordedGlobalAMPLSupply
            )
        );
    }

    /*
     * @dev Implemented on the satellite chain, phase 2 of `reportRebaseInit`
     */
    function reportRebaseCommit(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        override
    {
        require(false, "AMPLArbitrumGateway: NOT_IMPLEMENTED");
    }

    /**
     * @dev Transfers specified amount from the {msg.sender}'s wallet and locks it in the vault contract,
     *      notifies the bridge about the transfer.
     * @param recipientInTargetChain Address of the recipient wallet in the satellite.
     * @param amount Amount of tokens to be locked on ethereum.
     * @param destinationGasParams The gas parameters for the satellite execution.
     */
    function transferInit(
        address recipientInTargetChain,
        uint256 amount,
        GasParams memory destinationGasParams
    ) external payable override {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        ITokenVault(vault).lock(ampl, msg.sender, amount);

        emit XCTransferOut(msg.sender, recipientInTargetChain, amount, recordedGlobalAMPLSupply);

        sendTxToL2(
            arbitrumInbox,
            counterpartGateway,
            tx.origin,
            msg.value,
            0,
            destinationGasParams.maxSubmissionCost,
            destinationGasParams.maxGas,
            destinationGasParams.gasPriceBid,
            abi.encodeWithSelector(
                IL2TransferGateway.transferCommit.selector,
                msg.sender,
                recipientInTargetChain,
                amount,
                recordedGlobalAMPLSupply
            )
        );
    }

    /**
     * @dev Calculates the amount of amples to be unlocked based on the share of total supply and
     *      transfers it to the recipient.
     * @param senderInSourceChain Address of the sender wallet in the satellite.
     * @param recipient Address of the recipient wallet in ethereum.
     * @param amount Amount of tokens that were {burnt} on the L2.
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer.
     */
    function transferCommit(
        address senderInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external override onlyBridgeGateway {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        emit XCTransferIn(
            senderInSourceChain,
            recipient,
            amount,
            globalAMPLSupply,
            recordedGlobalAMPLSupply
        );

        uint256 unlockAmount = amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);
        ITokenVault(vault).unlock(ampl, recipient, unlockAmount);
    }

    constructor(
        address ampl_,
        address policy_,
        address vault_
    ) public {
        ampl = ampl_;
        policy = policy_;
        vault = vault_;
    }

    function initialize(address arbitrumInbox_, address counterpartGateway_) public initializer {
        arbitrumInbox = arbitrumInbox_;
        counterpartGateway = counterpartGateway_;
    }
}

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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";
import "arb-bridge-eth/contracts/bridge/interfaces/IOutbox.sol";

/// @notice L1 utility contract to assist with L1 <=> L2 interactions
/// @dev this is an abstract contract instead of library so the functions can be easily overriden when testing
abstract contract L1ArbitrumMessenger {
    event TxToL2(address indexed _from, address indexed _to, uint256 indexed _seqNum, bytes _data);

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal virtual returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2(
                _inbox,
                _to,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        uint256 seqNum = IInbox(_inbox).createRetryableTicket{ value: _l1CallValue }(
            _to,
            _l2CallValue,
            _maxSubmissionCost,
            _user,
            _user,
            _maxGas,
            _gasPriceBid,
            _data
        );
        emit TxToL2(_user, _to, seqNum, _data);
        return seqNum;
    }

    function getBridge(address _inbox) internal view virtual returns (IBridge) {
        return IInbox(_inbox).bridge();
    }

    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function getL2ToL1Sender(address _inbox) internal view virtual returns (address) {
        IOutbox outbox = IOutbox(getBridge(_inbox).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l2ToL1Sender != address(0), "NO_SENDER");
        return l2ToL1Sender;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma experimental ABIEncoderV2;

import {IRebaseGatewayEvents} from "../_events/IRebaseGatewayEvents.sol";
import {IL2GasParams} from "./IL2GasParams.sol";

interface IL2RebaseGateway is IRebaseGatewayEvents, IL2GasParams {
    function reportRebaseInit(GasParams memory destinationGasParams) external payable;

    function reportRebaseCommit(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma experimental ABIEncoderV2;

import {ITransferGatewayEvents} from "../_events/ITransferGatewayEvents.sol";
import {IL2GasParams} from "./IL2GasParams.sol";

interface IL2TransferGateway is ITransferGatewayEvents, IL2GasParams {
    function transferInit(
        address recipientInTargetChain,
        uint256 amount,
        GasParams memory destinationGasParams
    ) external payable;

    function transferCommit(
        address senderInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external;
}

// pragma solidity ^0.4.24;

// Public interface definition for the Ampleforth supply policy on Ethereum (the base-chain)
interface IAmpleforth {
    function epoch() external view returns (uint256);

    function lastRebaseTimestampSec() external view returns (uint256);

    function inRebaseWindow() external view returns (bool);

    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface ITokenVault {
    function lock(
        address token,
        address depositor,
        uint256 amount
    ) external;

    function unlock(
        address token,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IRebaseGatewayEvents {
    // Logged on the base chain gateway (ethereum) when rebase report is propagated out
    event XCRebaseReportOut(
        // epoch from the Ampleforth Monetary Policy on the base chain
        uint256 globalAmpleforthEpoch,
        // totalSupply of AMPL ERC-20 contract on the base chain
        uint256 globalAMPLSupply
    );

    // Logged on the satellite chain gateway (tron, acala, near) when bridge reports most recent rebase
    event XCRebaseReportIn(
        // new value coming in from the base chain
        uint256 globalAmpleforthEpoch,
        // new value coming in from the base chain
        uint256 globalAMPLSupply,
        // existing value on the satellite chain
        uint256 recordedGlobalAmpleforthEpoch,
        // existing value on the satellite chain
        uint256 recordedGlobalAMPLSupply
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma experimental ABIEncoderV2;

interface IL2GasParams {
    struct GasParams {
        uint256 maxSubmissionCost;
        uint256 maxGas;
        uint256 gasPriceBid;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface ITransferGatewayEvents {
    // Logged on source chain when cross-chain transfer is initiated
    event XCTransferOut(
        // user sending funds
        address indexed sender,
        // user receiving funds, set to address(0) if unavailable
        address indexed recipientInTargetChain,
        // amount to be locked/burnt
        uint256 amount,
        // existing value on the current source chain
        uint256 recordedGlobalAMPLSupply
    );

    // Logged on target chain when cross-chain transfer is completed
    event XCTransferIn(
        // user sending funds, set to address(0) if unavailable
        address indexed senderInSourceChain,
        // user receiving funds
        address indexed recipient,
        // value on remote chain when transaction was initiated
        uint256 globalAMPLSupply,
        // amount to be unlocked/mint
        uint256 amount,
        // existing value on the current target chain
        uint256 recordedGlobalAMPLSupply
    );
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}