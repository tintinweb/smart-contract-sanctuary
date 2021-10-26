// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {GatewayMessageHandler} from "arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/GatewayMessageHandler.sol";
import {L1ArbitrumMessenger} from "arb-bridge-peripherals/contracts/tokenbridge/ethereum/L1ArbitrumMessenger.sol";

import {IArbitrumBCRebaseGateway, IArbitrumBCTransferGateway, IArbitrumSCRebaseGateway, IArbitrumSCTransferGateway} from "../../_interfaces/bridge-gateways/IArbitrumGateway.sol";
import {IAmpleforth} from "uFragments/contracts/interfaces/IAmpleforth.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ITokenVault} from "../../_interfaces/ITokenVault.sol";

interface IArbitrumRouter {
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);
}

/// @dev Abstract l2 gateway contarct implementation to define function selectors
abstract contract ArbitrumXCAmpleGateway is IArbitrumSCRebaseGateway, IArbitrumSCTransferGateway {
    function reportRebaseCommit(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        override
    {
        require(false, "ArbitrumXCAmpleGateway: NOT_IMPLEMENTED");
    }

    function finalizeInboundTransfer(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable override {
        require(false, "ArbitrumXCAmpleGateway: NOT_IMPLEMENTED");
    }
}

/**
 * @title AMPLArbitrumGateway: AMPL-Arbitrum Gateway Contract
 * @dev This contract is deployed on the base chain (Ethereum).
 *
 *      It's a pass-through contract between the Arbitrum's bridge and
 *      the Ampleforth policy.
 *
 */
contract AMPLArbitrumGateway is
    IArbitrumBCRebaseGateway,
    IArbitrumBCTransferGateway,
    L1ArbitrumMessenger,
    Initializable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //--------------------------------------------------------------------------
    // AMPL Base chain gateway attributes

    /// @dev Address of the AMPL ERC20 on the base chain.
    address public immutable ampl;

    /// @dev Address of the Ampleforth monetary policy on the base chain.
    address public immutable policy;

    /// @dev Address of the token vault which escrows funds on the base chain.
    address public immutable vault;

    //--------------------------------------------------------------------------
    // Arbitrum gateway attributes

    /// @dev Address of the arbitrum bridge inbox.
    address public inbox;

    /// @dev Address if the arbitrum bridge router.
    address public router;

    /// @dev Address of the counterpart gateway contract on the arbitrum chain
    ///      which "finalizes" cross chain transactions.
    address public counterpartGateway;

    /// @dev Address of XCAmple token on the satellite chain.
    address public xcAmple;

    //--------------------------------------------------------------------------
    // Modifiers

    // @dev Validate incoming transactions before "finalization".
    modifier onlyCounterpartGateway() {
        address bridge = address(super.getBridge(inbox));
        require(msg.sender == bridge, "AMPLArbitrumGateway: NOT_FROM_BRIDGE");

        address l2ToL1Sender = super.getL2ToL1Sender(inbox);
        require(
            l2ToL1Sender == counterpartGateway,
            "AMPLArbitrumGateway: ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    //--------------------------------------------------------------------------
    // Constructor

    /**
     * @notice Instantiate the contract with references.
     * @param ampl_ Address of the AMPL ERC-20 on the Base Chain.
     * @param policy_ Address of the Ampleforth monetary policy on the Base Chain.
     * @param vault_ Address of the vault contract.
     */
    constructor(
        address ampl_,
        address policy_,
        address vault_
    ) public {
        ampl = ampl_;
        policy = policy_;
        vault = vault_;
    }

    /**
     * @notice Initialize contract with the addresses from the satellite chain (arbitrum).
     * @param inbox_ Address of the arbitrum bridge inbox on the base chain.
     * @param router_ Address of the arbitrum token transfer router on the base chain.
     * @param xcAmple_ Address of the XCAmple ERC-20 on the satellite chain.
     * @param counterpartGateway_ Address the counterpart gateway contract on the satellite chain.
     */
    function initialize(
        address inbox_,
        address router_,
        address xcAmple_,
        address counterpartGateway_,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) public initializer {
        inbox = inbox_;
        router = router_;
        xcAmple = xcAmple_;
        counterpartGateway = counterpartGateway_;

        // Gateway registeres itself with the arbitrum router
        IArbitrumRouter(router_).setGateway(
            address(this),
            _maxGas,
            _gasPriceBid,
            _maxSubmissionCost
        );
    }

    //--------------------------------------------------------------------------
    // External methods

    /**
     * @notice Builds the payload and transmits rebase report to Arbitrum.
     * @param _maxSubmissionCost Amount of ETH allocated to pay for the base submission fee.
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution.
     * @param _gasPriceBid Gas price for L2 execution.
     * @return res abi encoded inbox sequence number.
     */
    function reportRebaseInit(
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable override returns (bytes memory) {
        require(xcAmple != address(0), "AMPLArbitrumGateway: NOT_INITIALIZED");

        uint256 recordedGlobalAmpleforthEpoch = IAmpleforth(policy).epoch();
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        emit XCRebaseReportOut(recordedGlobalAmpleforthEpoch, recordedGlobalAMPLSupply);

        uint256 seqNumber = sendTxToL2(
            inbox,
            counterpartGateway,
            tx.origin,
            msg.value,
            0,
            L2GasParams({
                _maxSubmissionCost: _maxSubmissionCost,
                _maxGas: _maxGas,
                _gasPriceBid: _gasPriceBid
            }),
            abi.encodeWithSelector(
                ArbitrumXCAmpleGateway.reportRebaseCommit.selector,
                recordedGlobalAmpleforthEpoch,
                recordedGlobalAMPLSupply
            )
        );

        emit RebaseReportInitiated(seqNumber);

        return abi.encode(seqNumber);
    }

    /**
     * @notice Deposit AMPL from Ethereum into Arbitrum.
     * @param _l1Token L1 address of the AMPL ERC20.
     * @param _to account to be credited with the tokens in the L2 (can be the user's L2 account or a contract).
     * @param _amount Token Amount.
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution.
     * @param _gasPriceBid Gas price for L2 execution.
     * @param _data encoded data from router and user.
     * @return res abi encoded inbox sequence number.
     */
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable override returns (bytes memory) {
        require(msg.sender == router, "AMPLArbitrumGateway: NOT_FROM_ROUTER");

        require(_l1Token == ampl, "AMPLArbitrumGateway: ONLY_AMPL_ALLOWED");

        require(xcAmple != address(0), "AMPLArbitrumGateway: NOT_INITIALIZED");

        L2GasParams memory gasParams = L2GasParams({
            _maxSubmissionCost: 0, // set by the router
            _maxGas: _maxGas,
            _gasPriceBid: _gasPriceBid
        });

        address from;
        (from, gasParams._maxSubmissionCost) = _parseDataFromRouterOnTransfer(_data);

        // Lock funds and log outbound transfer
        uint256 recordedGlobalAMPLSupply;
        {
            recordedGlobalAMPLSupply = IERC20(_l1Token).totalSupply();

            // NOTE: The usual xc-transfer flow involves the depositer approving the vault
            //       and initiating the transfer. However the arbitrum implementation expects
            //       the user to approve the gateway. We thus add this extra step to confirm
            //       to both interfaces.
            //       1) User approves the gateway
            //       2) Tokens transfer from user => gateway => vault
            IERC20(_l1Token).safeTransferFrom(from, address(this), _amount);
            IERC20(_l1Token).approve(vault, _amount);

            ITokenVault(vault).lock(_l1Token, from, _amount);

            emit XCTransferOut(from, address(0), _amount, recordedGlobalAMPLSupply);
        }

        // Execute cross-chain transfer
        return
            abi.encode(
                createOutboundTransfer(
                    _l1Token,
                    from,
                    _to,
                    _amount,
                    gasParams,
                    recordedGlobalAMPLSupply
                )
            );
    }

    /**
     * @notice Finalizes a withdrawal via Outbox message; callable only by L2Gateway.outboundTransfer
     * @param _l1Token L1 address of the AMPL ERC20.
     * @param _from initiator of withdrawal.
     * @param _to address the L2 withdrawal call set as the destination.
     * @param _amount Token amount being withdrawn.
     * @param _data encoded exitNum (Sequentially increasing exit counter determined by the L2Gateway)
     *        and recordedGlobalAMPLSupply from the source chain.
     */
    function finalizeInboundTransfer(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable override onlyCounterpartGateway {
        require(_l1Token == ampl, "AMPLArbitrumGateway: ONLY_AMPL_ALLOWED");

        // Decode data from the bridge
        uint256 exitNum;
        uint256 globalAMPLSupply;
        (exitNum, globalAMPLSupply) = abi.decode(_data, (uint256, uint256));

        // Log inbound transfer and release funds
        // NOTE: this fails with the aribturm UI which approves this contract NOT the vault.
        // TODO: safe transfer from user to self and then forward to the vault.
        uint256 unlockAmount;
        {
            uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

            emit XCTransferIn(address(0), _to, globalAMPLSupply, _amount, recordedGlobalAMPLSupply);

            unlockAmount = _amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);

            ITokenVault(vault).unlock(ampl, _to, unlockAmount);
        }

        emit WithdrawalFinalized(_l1Token, _from, _to, exitNum, unlockAmount);
    }

    //--------------------------------------------------------------------------
    // View methods

    /// @return The L2 AMPL token address.
    function calculateL2TokenAddress(address token) public view override returns (address) {
        if (token != ampl) {
            return address(0);
        }
        return xcAmple;
    }

    /// @return The encoded outbound call data with the current globalAMPLSupply.
    function getOutboundCalldata(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external view override returns (bytes memory) {
        return _getOutboundCalldata(_l1Token, _from, _to, _amount, IERC20(ampl).totalSupply());
    }

    //--------------------------------------------------------------------------
    // Internal methods

    /// @dev Parses data packed by the router
    /// @return The depositor address and maxSubmissionCost
    function _parseDataFromRouterOnTransfer(bytes calldata _data)
        internal
        returns (address, uint256)
    {
        address from;
        bytes memory packedDataFromRouter;
        (from, packedDataFromRouter) = GatewayMessageHandler.parseFromRouterToGateway(_data);

        uint256 maxSubmissionCost;
        bytes memory extraData;
        (maxSubmissionCost, extraData) = abi.decode(packedDataFromRouter, (uint256, bytes));

        require(extraData.length == 0, "AMPLArbitrumGateway: EXTRA_DATA_DISABLED");

        return (from, maxSubmissionCost);
    }

    /// @dev Builds and executes the outbound transfer.
    /// @return seqNumber The bridge sequence number.
    function createOutboundTransfer(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        L2GasParams memory _gasParams,
        uint256 recordedGlobalAMPLSupply
    ) internal returns (uint256) {
        // packed data sent over the bridge
        bytes memory _outboundCallData = _getOutboundCalldata(
            _l1Token,
            _from,
            _to,
            _amount,
            recordedGlobalAMPLSupply
        );

        // Send data through the arbitrum bridge
        // Extra eth gets forwarded to the _from address on L2
        uint256 seqNumber = sendTxToL2(
            inbox,
            counterpartGateway,
            _from,
            msg.value, // we forward the L1 call value to the inbox
            0, // l2 call value 0 by default
            _gasParams,
            _outboundCallData
        );

        emit DepositInitiated(_l1Token, _from, _to, seqNumber, _amount);

        return seqNumber;
    }

    /// @dev Packs data for the outbound token transfer (with the current AMPL supply).
    /// @return The packed byte array.
    function _getOutboundCalldata(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 recordedGlobalAMPLSupply
    ) internal view returns (bytes memory) {
        bytes memory packedData = abi.encode(recordedGlobalAMPLSupply);

        bytes memory outboundCalldata = abi.encodeWithSelector(
            ArbitrumXCAmpleGateway.finalizeInboundTransfer.selector,
            _l1Token,
            _from,
            _to,
            _amount,
            packedData
        );

        return outboundCalldata;
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

/// @notice this library manages encoding and decoding of gateway communication
library GatewayMessageHandler {
    // these are for communication from L1 to L2 gateway

    function encodeToL2GatewayMsg(bytes memory gatewayData, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(gatewayData, callHookData);
    }

    function parseFromL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (bytes memory gatewayData, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (gatewayData, callHookData) = abi.decode(_data, (bytes, bytes));
    }

    // these are for communication from L2 to L1 gateway

    function encodeFromL2GatewayMsg(uint256 exitNum, bytes memory callHookData)
        internal
        pure
        returns (bytes memory res)
    {
        res = abi.encode(exitNum, callHookData);
    }

    function parseToL1GatewayMsg(bytes calldata _data)
        internal
        pure
        returns (uint256 exitNum, bytes memory callHookData)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        (exitNum, callHookData) = abi.decode(_data, (uint256, bytes));
    }

    // these are for communication from router to gateway

    function encodeFromRouterToGateway(address _from, bytes calldata _data)
        internal
        pure
        returns (bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.encode(_from, _data);
    }

    function parseFromRouterToGateway(bytes calldata _data)
        internal
        pure
        returns (address, bytes memory res)
    {
        // abi decode may revert, but the encoding is done by L1 gateway, so we trust it
        return abi.decode(_data, (address, bytes));
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
import {IBCRebaseGatewayEvents, ISCRebaseGatewayEvents, ITransferGatewayEvents} from "./IGateway.sol";
import {ITokenGateway} from "arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/ITokenGateway.sol";

// Arbitrum chains expect the cross chain transaction to "pre-pay" in eth
// for execution on the other chain
// https://developer.offchainlabs.com/docs/l1_l2_messages

interface IArbitrumBCRebaseGateway is IBCRebaseGatewayEvents {
    event RebaseReportInitiated(uint256 indexed _sequenceNumber);

    function reportRebaseInit(
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable returns (bytes memory);
}

interface IArbitrumSCRebaseGateway is ISCRebaseGatewayEvents {
    event RebaseReportFinalized(uint256 indexed _exitNum);

    function reportRebaseCommit(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply) external;
}

interface IArbitrumTransferGateway is ITransferGatewayEvents, ITokenGateway {
    function getOutboundCalldata(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external view returns (bytes memory);
}

interface IArbitrumBCTransferGateway is IArbitrumTransferGateway {
    event DepositInitiated(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _sequenceNumber,
        uint256 _amount
    );

    event WithdrawalFinalized(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _exitNum,
        uint256 _amount
    );
}

interface IArbitrumSCTransferGateway is IArbitrumTransferGateway {
    event DepositFinalized(
        address indexed l1Token,
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawalInitiated(
        address l1Token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _l2ToL1Id,
        uint256 _exitNum,
        uint256 _amount
    );
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

interface IBCRebaseGatewayEvents {
    // Logged on the base chain gateway (ethereum) when rebase report is propagated out
    event XCRebaseReportOut(
        // epoch from the Ampleforth Monetary Policy on the base chain
        uint256 globalAmpleforthEpoch,
        // totalSupply of AMPL ERC-20 contract on the base chain
        uint256 globalAMPLSupply
    );
}

interface ISCRebaseGatewayEvents {
    // Logged on the satellite chain gateway when bridge reports most recent rebase
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

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}