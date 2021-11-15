// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IAuthorizer.sol";
import "./interfaces/IWETH.sol";

import "./VaultAuthorization.sol";
import "./FlashLoans.sol";
import "./Swaps.sol";

/**
 * @dev The `Vault` is Balancer V2's core contract. A single instance of it exists for the entire network, and it is the
 * entity used to interact with Pools by Liquidity Providers who join and exit them, Traders who swap, and Asset
 * Managers who withdraw and deposit tokens.
 *
 * The `Vault`'s source code is split among a number of sub-contracts, with the goal of improving readability and making
 * understanding the system easier. Most sub-contracts have been marked as `abstract` to explicitly indicate that only
 * the full `Vault` is meant to be deployed.
 *
 * Roughly speaking, these are the contents of each sub-contract:
 *
 *  - `AssetManagers`: Pool token Asset Manager registry, and Asset Manager interactions.
 *  - `Fees`: set and compute protocol fees.
 *  - `FlashLoans`: flash loan transfers and fees.
 *  - `PoolBalances`: Pool joins and exits.
 *  - `PoolRegistry`: Pool registration, ID management, and basic queries.
 *  - `PoolTokens`: Pool token registration and registration, and balance queries.
 *  - `Swaps`: Pool swaps.
 *  - `UserBalance`: manage user balances (Internal Balance operations and external balance transfers)
 *  - `VaultAuthorization`: access control, relayers and signature validation.
 *
 * Additionally, the different Pool specializations are handled by the `GeneralPoolsBalance`,
 * `MinimalSwapInfoPoolsBalance` and `TwoTokenPoolsBalance` sub-contracts, which in turn make use of the
 * `BalanceAllocation` library.
 *
 * The most important goal of the `Vault` is to make token swaps use as little gas as possible. This is reflected in a
 * multitude of design decisions, from minor things like the format used to store Pool IDs, to major features such as
 * the different Pool specialization settings.
 *
 * Finally, the large number of tasks carried out by the Vault means its bytecode is very large, close to exceeding
 * the contract size limit imposed by EIP 170 (https://eips.ethereum.org/EIPS/eip-170). Manual tuning of the source code
 * was required to improve code generation and bring the bytecode size below this limit. This includes extensive
 * utilization of `internal` functions (particularly inside modifiers), usage of named return arguments, dedicated
 * storage access methods, dynamic revert reason generation, and usage of inline assembly, to name a few.
 */
contract Vault is VaultAuthorization, FlashLoans, Swaps {
    constructor(
        IAuthorizer authorizer,
        IWETH weth,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration
    ) VaultAuthorization(authorizer) AssetHelpers(weth) TemporarilyPausable(pauseWindowDuration, bufferPeriodDuration) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setPaused(bool paused) external override nonReentrant authenticate {
        _setPaused(paused);
    }

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view override returns (IWETH) {
        return _WETH();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../../lib/openzeppelin/IERC20.sol";

/**
 * @dev Interface for the WETH token contract used internally for wrapping and unwrapping, to support
 * sending and receiving ETH in joins, swaps, and internal balance deposits and withdrawals.
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/Authentication.sol";
import "../lib/helpers/TemporarilyPausable.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/SignaturesValidator.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAuthorizer.sol";

/**
 * @dev Manages access control of Vault permissioned functions by relying on the Authorizer and signature validation.
 *
 * Additionally handles relayer access and approval.
 */
abstract contract VaultAuthorization is
    IVault,
    ReentrancyGuard,
    Authentication,
    SignaturesValidator,
    TemporarilyPausable
{
    // Ideally, we'd store the type hashes as immutable state variables to avoid computing the hash at runtime, but
    // unfortunately immutable variables cannot be used in assembly, so we just keep the precomputed hashes instead.

    // _JOIN_TYPE_HASH = keccak256("JoinPool(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    bytes32 private constant _JOIN_TYPE_HASH = 0x3f7b71252bd19113ff48c19c6e004a9bcfcca320a0d74d58e85877cbd7dcae58;

    // _EXIT_TYPE_HASH = keccak256("ExitPool(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    bytes32 private constant _EXIT_TYPE_HASH = 0x8bbc57f66ea936902f50a71ce12b92c43f3c5340bb40c27c4e90ab84eeae3353;

    // _SWAP_TYPE_HASH = keccak256("Swap(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    bytes32 private constant _SWAP_TYPE_HASH = 0xe192dcbc143b1e244ad73b813fd3c097b832ad260a157340b4e5e5beda067abe;

    // _BATCH_SWAP_TYPE_HASH = keccak256("BatchSwap(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    bytes32 private constant _BATCH_SWAP_TYPE_HASH = 0x9bfc43a4d98313c6766986ffd7c916c7481566d9f224c6819af0a53388aced3a;

    // _SET_RELAYER_TYPE_HASH =
    //     keccak256("SetRelayerApproval(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    bytes32
        private constant _SET_RELAYER_TYPE_HASH = 0xa3f865aa351e51cfeb40f5178d1564bb629fe9030b83caf6361d1baaf5b90b5a;

    IAuthorizer private _authorizer;
    mapping(address => mapping(address => bool)) private _approvedRelayers;

    /**
     * @dev Reverts unless `user` is the caller, or the caller is approved by the Authorizer to call this function (that
     * is, it is a relayer for that function), and either:
     *  a) `user` approved the caller as a relayer (via `setRelayerApproval`), or
     *  b) a valid signature from them was appended to the calldata.
     *
     * Should only be applied to external functions.
     */
    modifier authenticateFor(address user) {
        _authenticateFor(user);
        _;
    }

    constructor(IAuthorizer authorizer)
        // The Vault is a singleton, so it simply uses its own address to disambiguate action identifiers.
        Authentication(bytes32(uint256(address(this))))
        SignaturesValidator("Balancer V2 Vault")
    {
        _setAuthorizer(authorizer);
    }

    function setAuthorizer(IAuthorizer newAuthorizer) external override nonReentrant authenticate {
        _setAuthorizer(newAuthorizer);
    }

    function _setAuthorizer(IAuthorizer newAuthorizer) private {
        emit AuthorizerChanged(newAuthorizer);
        _authorizer = newAuthorizer;
    }

    function getAuthorizer() external view override returns (IAuthorizer) {
        return _authorizer;
    }

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external override nonReentrant whenNotPaused authenticateFor(sender) {
        _approvedRelayers[sender][relayer] = approved;
        emit RelayerApprovalChanged(relayer, sender, approved);
    }

    function hasApprovedRelayer(address user, address relayer) external view override returns (bool) {
        return _hasApprovedRelayer(user, relayer);
    }

    /**
     * @dev Reverts unless `user` is the caller, or the caller is approved by the Authorizer to call the entry point
     * function (that is, it is a relayer for that function) and either:
     *  a) `user` approved the caller as a relayer (via `setRelayerApproval`), or
     *  b) a valid signature from them was appended to the calldata.
     */
    function _authenticateFor(address user) internal {
        if (msg.sender != user) {
            // In this context, 'permission to call a function' means 'being a relayer for a function'.
            _authenticateCaller();

            // Being a relayer is not sufficient: `user` must have also approved the caller either via
            // `setRelayerApproval`, or by providing a signature appended to the calldata.
            if (!_hasApprovedRelayer(user, msg.sender)) {
                _validateSignature(user, Errors.USER_DOESNT_ALLOW_RELAYER);
            }
        }
    }

    /**
     * @dev Returns true if `user` approved `relayer` to act as a relayer for them.
     */
    function _hasApprovedRelayer(address user, address relayer) internal view returns (bool) {
        return _approvedRelayers[user][relayer];
    }

    function _canPerform(bytes32 actionId, address user) internal view override returns (bool) {
        // Access control is delegated to the Authorizer.
        return _authorizer.canPerform(actionId, user, address(this));
    }

    function _typeHash() internal pure override returns (bytes32 hash) {
        // This is a simple switch-case statement, trivially written in Solidity by chaining else-if statements, but the
        // assembly implementation results in much denser bytecode.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // The function selector is located at the first 4 bytes of calldata. We copy the first full calldata
            // 256 word, and then perform a logical shift to the right, moving the selector to the least significant
            // 4 bytes.
            let selector := shr(224, calldataload(0))

            // With the selector in the least significant 4 bytes, we can use 4 byte literals with leading zeros,
            // resulting in dense bytecode (PUSH4 opcodes).
            switch selector
                case 0xb95cac28 {
                    hash := _JOIN_TYPE_HASH
                }
                case 0x8bdb3913 {
                    hash := _EXIT_TYPE_HASH
                }
                case 0x52bbbe29 {
                    hash := _SWAP_TYPE_HASH
                }
                case 0x945bcec9 {
                    hash := _BATCH_SWAP_TYPE_HASH
                }
                case 0xfa6e671d {
                    hash := _SET_RELAYER_TYPE_HASH
                }
                default {
                    hash := 0x0000000000000000000000000000000000000000000000000000000000000000
                }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

// This flash loan provider was based on the Aave protocol's open source
// implementation and terminology and interfaces are intentionally kept
// similar

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./Fees.sol";
import "./interfaces/IFlashLoanRecipient.sol";

/**
 * @dev Handles Flash Loans through the Vault. Calls the `receiveFlashLoan` hook on the flash loan recipient
 * contract, which implements the `IFlashLoanRecipient` interface.
 */
abstract contract FlashLoans is Fees, ReentrancyGuard, TemporarilyPausable {
    using SafeERC20 for IERC20;

    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external override nonReentrant whenNotPaused {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        uint256[] memory feeAmounts = new uint256[](tokens.length);
        uint256[] memory preLoanBalances = new uint256[](tokens.length);

        // Used to ensure `tokens` is sorted in ascending order, which ensures token uniqueness.
        IERC20 previousToken = IERC20(0);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];

            _require(token > previousToken, token == IERC20(0) ? Errors.ZERO_TOKEN : Errors.UNSORTED_TOKENS);
            previousToken = token;

            preLoanBalances[i] = token.balanceOf(address(this));
            feeAmounts[i] = _calculateFlashLoanFeeAmount(amount);

            _require(preLoanBalances[i] >= amount, Errors.INSUFFICIENT_FLASH_LOAN_BALANCE);
            token.safeTransfer(address(recipient), amount);
        }

        recipient.receiveFlashLoan(tokens, amounts, feeAmounts, userData);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 preLoanBalance = preLoanBalances[i];

            // Checking for loan repayment first (without accounting for fees) makes for simpler debugging, and results
            // in more accurate revert reasons if the flash loan protocol fee percentage is zero.
            uint256 postLoanBalance = token.balanceOf(address(this));
            _require(postLoanBalance >= preLoanBalance, Errors.INVALID_POST_LOAN_BALANCE);

            // No need for checked arithmetic since we know the loan was fully repaid.
            uint256 receivedFeeAmount = postLoanBalance - preLoanBalance;
            _require(receivedFeeAmount >= feeAmounts[i], Errors.INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT);

            _payFeeAmount(token, receivedFeeAmount);
            emit FlashLoan(recipient, token, amounts[i], receivedFeeAmount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/EnumerableMap.sol";
import "../lib/openzeppelin/EnumerableSet.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeCast.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./PoolBalances.sol";
import "./interfaces/IPoolSwapStructs.sol";
import "./interfaces/IGeneralPool.sol";
import "./interfaces/IMinimalSwapInfoPool.sol";
import "./balances/BalanceAllocation.sol";

/**
 * Implements the Vault's high-level swap functionality.
 *
 * Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. They need not trust the Pool
 * contracts to do this: all security checks are made by the Vault.
 *
 * The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
 * In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
 * and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
 * More complex swaps, such as one 'token in' to multiple tokens out can be achieved by batching together
 * individual swaps.
 */
abstract contract Swaps is ReentrancyGuard, PoolBalances {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    using Math for int256;
    using Math for uint256;
    using SafeCast for uint256;
    using BalanceAllocation for bytes32;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        authenticateFor(funds.sender)
        returns (uint256 amountCalculated)
    {
        // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        _require(block.timestamp <= deadline, Errors.SWAP_DEADLINE);

        // This revert reason is for consistency with `batchSwap`: an equivalent `swap` performed using that function
        // would result in this error.
        _require(singleSwap.amount > 0, Errors.UNKNOWN_AMOUNT_IN_FIRST_SWAP);

        IERC20 tokenIn = _translateToIERC20(singleSwap.assetIn);
        IERC20 tokenOut = _translateToIERC20(singleSwap.assetOut);
        _require(tokenIn != tokenOut, Errors.CANNOT_SWAP_SAME_TOKEN);

        // Initializing each struct field one-by-one uses less gas than setting all at once.
        IPoolSwapStructs.SwapRequest memory poolRequest;
        poolRequest.poolId = singleSwap.poolId;
        poolRequest.kind = singleSwap.kind;
        poolRequest.tokenIn = tokenIn;
        poolRequest.tokenOut = tokenOut;
        poolRequest.amount = singleSwap.amount;
        poolRequest.userData = singleSwap.userData;
        poolRequest.from = funds.sender;
        poolRequest.to = funds.recipient;
        // The lastChangeBlock field is left uninitialized.

        uint256 amountIn;
        uint256 amountOut;

        (amountCalculated, amountIn, amountOut) = _swapWithPool(poolRequest);
        _require(singleSwap.kind == SwapKind.GIVEN_IN ? amountOut >= limit : amountIn <= limit, Errors.SWAP_LIMIT);

        _receiveAsset(singleSwap.assetIn, amountIn, funds.sender, funds.fromInternalBalance);
        _sendAsset(singleSwap.assetOut, amountOut, funds.recipient, funds.toInternalBalance);

        // If the asset in is ETH, then `amountIn` ETH was wrapped into WETH.
        _handleRemainingEth(_isETH(singleSwap.assetIn) ? amountIn : 0);
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        authenticateFor(funds.sender)
        returns (int256[] memory assetDeltas)
    {
        // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        _require(block.timestamp <= deadline, Errors.SWAP_DEADLINE);

        InputHelpers.ensureInputLengthMatch(assets.length, limits.length);

        // Perform the swaps, updating the Pool token balances and computing the net Vault asset deltas.
        assetDeltas = _swapWithPools(swaps, assets, funds, kind);

        // Process asset deltas, by either transferring assets from the sender (for positive deltas) or to the recipient
        // (for negative deltas).
        uint256 wrappedEth = 0;
        for (uint256 i = 0; i < assets.length; ++i) {
            IAsset asset = assets[i];
            int256 delta = assetDeltas[i];
            _require(delta <= limits[i], Errors.SWAP_LIMIT);

            if (delta > 0) {
                uint256 toReceive = uint256(delta);
                _receiveAsset(asset, toReceive, funds.sender, funds.fromInternalBalance);

                if (_isETH(asset)) {
                    wrappedEth = wrappedEth.add(toReceive);
                }
            } else if (delta < 0) {
                uint256 toSend = uint256(-delta);
                _sendAsset(asset, toSend, funds.recipient, funds.toInternalBalance);
            }
        }

        // Handle any used and remaining ETH.
        _handleRemainingEth(wrappedEth);
    }

    // For `_swapWithPools` to handle both 'given in' and 'given out' swaps, it internally tracks the 'given' amount
    // (supplied by the caller), and the 'calculated' amount (returned by the Pool in response to the swap request).

    /**
     * @dev Given the two swap tokens and the swap kind, returns which one is the 'given' token (the token whose
     * amount is supplied by the caller).
     */
    function _tokenGiven(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20) {
        return kind == SwapKind.GIVEN_IN ? tokenIn : tokenOut;
    }

    /**
     * @dev Given the two swap tokens and the swap kind, returns which one is the 'calculated' token (the token whose
     * amount is calculated by the Pool).
     */
    function _tokenCalculated(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20) {
        return kind == SwapKind.GIVEN_IN ? tokenOut : tokenIn;
    }

    /**
     * @dev Returns an ordered pair (amountIn, amountOut) given the 'given' and 'calculated' amounts, and the swap kind.
     */
    function _getAmounts(
        SwapKind kind,
        uint256 amountGiven,
        uint256 amountCalculated
    ) private pure returns (uint256 amountIn, uint256 amountOut) {
        if (kind == SwapKind.GIVEN_IN) {
            (amountIn, amountOut) = (amountGiven, amountCalculated);
        } else {
            // SwapKind.GIVEN_OUT
            (amountIn, amountOut) = (amountCalculated, amountGiven);
        }
    }

    /**
     * @dev Performs all `swaps`, calling swap hooks on the Pool contracts and updating their balances. Does not cause
     * any transfer of tokens - instead it returns the net Vault token deltas: positive if the Vault should receive
     * tokens, and negative if it should send them.
     */
    function _swapWithPools(
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        SwapKind kind
    ) private returns (int256[] memory assetDeltas) {
        assetDeltas = new int256[](assets.length);

        // These variables could be declared inside the loop, but that causes the compiler to allocate memory on each
        // loop iteration, increasing gas costs.
        BatchSwapStep memory batchSwapStep;
        IPoolSwapStructs.SwapRequest memory poolRequest;

        // These store data about the previous swap here to implement multihop logic across swaps.
        IERC20 previousTokenCalculated;
        uint256 previousAmountCalculated;

        for (uint256 i = 0; i < swaps.length; ++i) {
            batchSwapStep = swaps[i];

            bool withinBounds = batchSwapStep.assetInIndex < assets.length &&
                batchSwapStep.assetOutIndex < assets.length;
            _require(withinBounds, Errors.OUT_OF_BOUNDS);

            IERC20 tokenIn = _translateToIERC20(assets[batchSwapStep.assetInIndex]);
            IERC20 tokenOut = _translateToIERC20(assets[batchSwapStep.assetOutIndex]);
            _require(tokenIn != tokenOut, Errors.CANNOT_SWAP_SAME_TOKEN);

            // Sentinel value for multihop logic
            if (batchSwapStep.amount == 0) {
                // When the amount given is zero, we use the calculated amount for the previous swap, as long as the
                // current swap's given token is the previous calculated token. This makes it possible to swap a
                // given amount of token A for token B, and then use the resulting token B amount to swap for token C.
                _require(i > 0, Errors.UNKNOWN_AMOUNT_IN_FIRST_SWAP);
                bool usingPreviousToken = previousTokenCalculated == _tokenGiven(kind, tokenIn, tokenOut);
                _require(usingPreviousToken, Errors.MALCONSTRUCTED_MULTIHOP_SWAP);
                batchSwapStep.amount = previousAmountCalculated;
            }

            // Initializing each struct field one-by-one uses less gas than setting all at once
            poolRequest.poolId = batchSwapStep.poolId;
            poolRequest.kind = kind;
            poolRequest.tokenIn = tokenIn;
            poolRequest.tokenOut = tokenOut;
            poolRequest.amount = batchSwapStep.amount;
            poolRequest.userData = batchSwapStep.userData;
            poolRequest.from = funds.sender;
            poolRequest.to = funds.recipient;
            // The lastChangeBlock field is left uninitialized

            uint256 amountIn;
            uint256 amountOut;
            (previousAmountCalculated, amountIn, amountOut) = _swapWithPool(poolRequest);

            previousTokenCalculated = _tokenCalculated(kind, tokenIn, tokenOut);

            // Accumulate Vault deltas across swaps
            assetDeltas[batchSwapStep.assetInIndex] = assetDeltas[batchSwapStep.assetInIndex].add(amountIn.toInt256());
            assetDeltas[batchSwapStep.assetOutIndex] = assetDeltas[batchSwapStep.assetOutIndex].sub(
                amountOut.toInt256()
            );
        }
    }

    /**
     * @dev Performs a swap according to the parameters specified in `request`, calling the Pool's contract hook and
     * updating the Pool's balance.
     *
     * Returns the amount of tokens going into or out of the Vault as a result of this swap, depending on the swap kind.
     */
    function _swapWithPool(IPoolSwapStructs.SwapRequest memory request)
        private
        returns (
            uint256 amountCalculated,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        // Get the calculated amount from the Pool and update its balances
        address pool = _getPoolAddress(request.poolId);
        PoolSpecialization specialization = _getPoolSpecialization(request.poolId);

        if (specialization == PoolSpecialization.TWO_TOKEN) {
            amountCalculated = _processTwoTokenPoolSwapRequest(request, IMinimalSwapInfoPool(pool));
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            amountCalculated = _processMinimalSwapInfoPoolSwapRequest(request, IMinimalSwapInfoPool(pool));
        } else {
            // PoolSpecialization.GENERAL
            amountCalculated = _processGeneralPoolSwapRequest(request, IGeneralPool(pool));
        }

        (amountIn, amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);
        emit Swap(request.poolId, request.tokenIn, request.tokenOut, amountIn, amountOut);
    }

    function _processTwoTokenPoolSwapRequest(IPoolSwapStructs.SwapRequest memory request, IMinimalSwapInfoPool pool)
        private
        returns (uint256 amountCalculated)
    {
        // For gas efficiency reasons, this function uses low-level knowledge of how Two Token Pool balances are
        // stored internally, instead of using getters and setters for all operations.

        (
            bytes32 tokenABalance,
            bytes32 tokenBBalance,
            TwoTokenPoolBalances storage poolBalances
        ) = _getTwoTokenPoolSharedBalances(request.poolId, request.tokenIn, request.tokenOut);

        // We have the two Pool balances, but we don't know which one is 'token in' or 'token out'.
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

        // In Two Token Pools, token A has a smaller address than token B
        if (request.tokenIn < request.tokenOut) {
            // in is A, out is B
            tokenInBalance = tokenABalance;
            tokenOutBalance = tokenBBalance;
        } else {
            // in is B, out is A
            tokenOutBalance = tokenABalance;
            tokenInBalance = tokenBBalance;
        }

        // Perform the swap request and compute the new balances for 'token in' and 'token out' after the swap
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            tokenInBalance,
            tokenOutBalance
        );

        // We check the token ordering again to create the new shared cash packed struct
        poolBalances.sharedCash = request.tokenIn < request.tokenOut
            ? BalanceAllocation.toSharedCash(tokenInBalance, tokenOutBalance) // in is A, out is B
            : BalanceAllocation.toSharedCash(tokenOutBalance, tokenInBalance); // in is B, out is A
    }

    function _processMinimalSwapInfoPoolSwapRequest(
        IPoolSwapStructs.SwapRequest memory request,
        IMinimalSwapInfoPool pool
    ) private returns (uint256 amountCalculated) {
        bytes32 tokenInBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenIn);
        bytes32 tokenOutBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenOut);

        // Perform the swap request and compute the new balances for 'token in' and 'token out' after the swap
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            tokenInBalance,
            tokenOutBalance
        );

        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenIn] = tokenInBalance;
        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenOut] = tokenOutBalance;
    }

    /**
     * @dev Calls the onSwap hook for a Pool that implements IMinimalSwapInfoPool: both Minimal Swap Info and Two Token
     * Pools do this.
     */
    function _callMinimalSwapInfoPoolOnSwapHook(
        IPoolSwapStructs.SwapRequest memory request,
        IMinimalSwapInfoPool pool,
        bytes32 tokenInBalance,
        bytes32 tokenOutBalance
    )
        internal
        returns (
            bytes32 newTokenInBalance,
            bytes32 newTokenOutBalance,
            uint256 amountCalculated
        )
    {
        uint256 tokenInTotal = tokenInBalance.total();
        uint256 tokenOutTotal = tokenOutBalance.total();
        request.lastChangeBlock = Math.max(tokenInBalance.lastChangeBlock(), tokenOutBalance.lastChangeBlock());

        // Perform the swap request callback, and compute the new balances for 'token in' and 'token out' after the swap
        amountCalculated = pool.onSwap(request, tokenInTotal, tokenOutTotal);
        (uint256 amountIn, uint256 amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);

        newTokenInBalance = tokenInBalance.increaseCash(amountIn);
        newTokenOutBalance = tokenOutBalance.decreaseCash(amountOut);
    }

    function _processGeneralPoolSwapRequest(IPoolSwapStructs.SwapRequest memory request, IGeneralPool pool)
        private
        returns (uint256 amountCalculated)
    {
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

        // We access both token indexes without checking existence, because we will do it manually immediately after.
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[request.poolId];
        uint256 indexIn = poolBalances.unchecked_indexOf(request.tokenIn);
        uint256 indexOut = poolBalances.unchecked_indexOf(request.tokenOut);

        if (indexIn == 0 || indexOut == 0) {
            // The tokens might not be registered because the Pool itself is not registered. We check this to provide a
            // more accurate revert reason.
            _ensureRegisteredPool(request.poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

        // EnumerableMap stores indices *plus one* to use the zero index as a sentinel value - because these are valid,
        // we can undo this.
        indexIn -= 1;
        indexOut -= 1;

        uint256 tokenAmount = poolBalances.length();
        uint256[] memory currentBalances = new uint256[](tokenAmount);

        request.lastChangeBlock = 0;
        for (uint256 i = 0; i < tokenAmount; i++) {
            // Because the iteration is bounded by `tokenAmount`, and no tokens are registered or deregistered here, we
            // know `i` is a valid token index and can use `unchecked_valueAt` to save storage reads.
            bytes32 balance = poolBalances.unchecked_valueAt(i);

            currentBalances[i] = balance.total();
            request.lastChangeBlock = Math.max(request.lastChangeBlock, balance.lastChangeBlock());

            if (i == indexIn) {
                tokenInBalance = balance;
            } else if (i == indexOut) {
                tokenOutBalance = balance;
            }
        }

        // Perform the swap request callback and compute the new balances for 'token in' and 'token out' after the swap
        amountCalculated = pool.onSwap(request, currentBalances, indexIn, indexOut);
        (uint256 amountIn, uint256 amountOut) = _getAmounts(request.kind, request.amount, amountCalculated);
        tokenInBalance = tokenInBalance.increaseCash(amountIn);
        tokenOutBalance = tokenOutBalance.decreaseCash(amountOut);

        // Because no tokens were registered or deregistered between now or when we retrieved the indexes for
        // 'token in' and 'token out', we can use `unchecked_setAt` to save storage reads.
        poolBalances.unchecked_setAt(indexIn, tokenInBalance);
        poolBalances.unchecked_setAt(indexOut, tokenOutBalance);
    }

    // This function is not marked as `nonReentrant` because the underlying mechanism relies on reentrancy
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external override returns (int256[] memory) {
        // In order to accurately 'simulate' swaps, this function actually does perform the swaps, including calling the
        // Pool hooks and updating balances in storage. However, once it computes the final Vault Deltas, it
        // reverts unconditionally, returning this array as the revert data.
        //
        // By wrapping this reverting call, we can decode the deltas 'returned' and return them as a normal Solidity
        // function would. The only caveat is the function becomes non-view, but off-chain clients can still call it
        // via eth_call to get the expected result.
        //
        // This technique was inspired by the work from the Gnosis team in the Gnosis Safe contract:
        // https://github.com/gnosis/safe-contracts/blob/v1.2.0/contracts/GnosisSafe.sol#L265
        //
        // Most of this function is implemented using inline assembly, as the actual work it needs to do is not
        // significant, and Solidity is not particularly well-suited to generate this behavior, resulting in a large
        // amount of generated bytecode.

        if (msg.sender != address(this)) {
            // We perform an external call to ourselves, forwarding the same calldata. In this call, the else clause of
            // the preceding if statement will be executed instead.

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(msg.data);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // This call should always revert to decode the actual asset deltas from the revert reason
                switch success
                    case 0 {
                        // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                        // stored there as we take full control of the execution and then immediately return.

                        // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                        // there was another revert reason and we should forward it.
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                        // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                        if eq(eq(error, 0xfa61cc1200000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                        // The returndata contains the signature, followed by the raw memory representation of an array:
                        // length + data. We need to return an ABI-encoded representation of this array.
                        // An ABI-encoded array contains an additional field when compared to its raw memory
                        // representation: an offset to the location of the length. The offset itself is 32 bytes long,
                        // so the smallest value we  can use is 32 for the data to be located immediately after it.
                        mstore(0, 32)

                        // We now copy the raw memory array from returndata into memory. Since the offset takes up 32
                        // bytes, we start copying at address 0x20. We also get rid of the error signature, which takes
                        // the first four bytes of returndata.
                        let size := sub(returndatasize(), 0x04)
                        returndatacopy(0x20, 0x04, size)

                        // We finally return the ABI-encoded array, which has a total length equal to that of the array
                        // (returndata), plus the 32 bytes for the offset.
                        return(0, add(size, 32))
                    }
                    default {
                        // This call should always revert, but we fail nonetheless if that didn't happen
                        invalid()
                    }
            }
        } else {
            int256[] memory deltas = _swapWithPools(swaps, assets, funds, kind);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We will return a raw representation of the array in memory, which is composed of a 32 byte length,
                // followed by the 32 byte int256 values. Because revert expects a size in bytes, we multiply the array
                // length (stored at `deltas`) by 32.
                let size := mul(mload(deltas), 32)

                // We send one extra value for the error signature "QueryError(int256[])" which is 0xfa61cc12.
                // We store it in the previous slot to the `deltas` array. We know there will be at least one available
                // slot due to how the memory scratch space works.
                // We can safely overwrite whatever is stored in this slot as we will revert immediately after that.
                mstore(sub(deltas, 0x20), 0x00000000000000000000000000000000000000000000000000000000fa61cc12)
                let start := sub(deltas, 0x04)

                // When copying from `deltas` into returndata, we copy an additional 36 bytes to also return the array's
                // length and the error signature.
                revert(start, add(size, 36))
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.7.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./IAuthentication.sol";

/**
 * @dev Building block for performing access control on external functions.
 *
 * This contract is used via the `authenticate` modifier (or the `_authenticateCaller` function), which can be applied
 * to external functions to only make them callable by authorized accounts.
 *
 * Derived contracts must implement the `_canPerform` function, which holds the actual access control logic.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    /**
     * @dev The main purpose of the `actionIdDisambiguator` is to prevent accidental function selector collisions in
     * multi contract systems.
     *
     * There are two main uses for it:
     *  - if the contract is a singleton, any unique identifier can be used to make the associated action identifiers
     *    unique. The contract's own address is a good option.
     *  - if the contract belongs to a family that shares action identifiers for the same functions, an identifier
     *    shared by the entire family (and no other contract) should be used instead.
     */
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./ITemporarilyPausable.sol";

/**
 * @dev Allows for a contract to be paused during an initial period after deployment, disabling functionality. Can be
 * used as an emergency switch in case a security vulnerability or threat is identified.
 *
 * The contract can only be paused during the Pause Window, a period that starts at deployment. It can also be
 * unpaused and repaused any number of times during this period. This is intended to serve as a safety measure: it lets
 * system managers react quickly to potentially dangerous situations, knowing that this action is reversible if careful
 * analysis later determines there was a false alarm.
 *
 * If the contract is paused when the Pause Window finishes, it will remain in the paused state through an additional
 * Buffer Period, after which it will be automatically unpaused forever. This is to ensure there is always enough time
 * to react to an emergency, even if the threat is discovered shortly before the Pause Window expires.
 *
 * Note that since the contract can only be paused within the Pause Window, unpausing during the Buffer Period is
 * irreversible.
 */
abstract contract TemporarilyPausable is ITemporarilyPausable {
    // The Pause Window and Buffer Period are timestamp-based: they should not be relied upon for sub-minute accuracy.
    // solhint-disable not-rely-on-time

    uint256 private constant _MAX_PAUSE_WINDOW_DURATION = 90 days;
    uint256 private constant _MAX_BUFFER_PERIOD_DURATION = 30 days;

    uint256 private immutable _pauseWindowEndTime;
    uint256 private immutable _bufferPeriodEndTime;

    bool private _paused;

    constructor(uint256 pauseWindowDuration, uint256 bufferPeriodDuration) {
        _require(pauseWindowDuration <= _MAX_PAUSE_WINDOW_DURATION, Errors.MAX_PAUSE_WINDOW_DURATION);
        _require(bufferPeriodDuration <= _MAX_BUFFER_PERIOD_DURATION, Errors.MAX_BUFFER_PERIOD_DURATION);

        uint256 pauseWindowEndTime = block.timestamp + pauseWindowDuration;

        _pauseWindowEndTime = pauseWindowEndTime;
        _bufferPeriodEndTime = pauseWindowEndTime + bufferPeriodDuration;
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    modifier whenNotPaused() {
        _ensureNotPaused();
        _;
    }

    /**
     * @dev Returns the current contract pause status, as well as the end times of the Pause Window and Buffer
     * Period.
     */
    function getPausedState()
        external
        view
        override
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        )
    {
        paused = !_isNotPaused();
        pauseWindowEndTime = _getPauseWindowEndTime();
        bufferPeriodEndTime = _getBufferPeriodEndTime();
    }

    /**
     * @dev Sets the pause state to `paused`. The contract can only be paused until the end of the Pause Window, and
     * unpaused until the end of the Buffer Period.
     *
     * Once the Buffer Period expires, this function reverts unconditionally.
     */
    function _setPaused(bool paused) internal {
        if (paused) {
            _require(block.timestamp < _getPauseWindowEndTime(), Errors.PAUSE_WINDOW_EXPIRED);
        } else {
            _require(block.timestamp < _getBufferPeriodEndTime(), Errors.BUFFER_PERIOD_EXPIRED);
        }

        _paused = paused;
        emit PausedStateChanged(paused);
    }

    /**
     * @dev Reverts if the contract is paused.
     */
    function _ensureNotPaused() internal view {
        _require(_isNotPaused(), Errors.PAUSED);
    }

    /**
     * @dev Returns true if the contract is unpaused.
     *
     * Once the Buffer Period expires, the gas cost of calling this function is reduced dramatically, as storage is no
     * longer accessed.
     */
    function _isNotPaused() internal view returns (bool) {
        // After the Buffer Period, the (inexpensive) timestamp check short-circuits the storage access.
        return block.timestamp > _getBufferPeriodEndTime() || !_paused;
    }

    // These getters lead to reduced bytecode size by inlining the immutable variables in a single place.

    function _getPauseWindowEndTime() private view returns (uint256) {
        return _pauseWindowEndTime;
    }

    function _getBufferPeriodEndTime() private view returns (uint256) {
        return _bufferPeriodEndTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "./BalancerErrors.sol";
import "./ISignaturesValidator.sol";
import "../openzeppelin/EIP712.sol";

/**
 * @dev Utility for signing Solidity function calls.
 *
 * This contract relies on the fact that Solidity contracts can be called with extra calldata, and enables
 * meta-transaction schemes by appending an EIP712 signature of the original calldata at the end.
 *
 * Derived contracts must implement the `_typeHash` function to map function selectors to EIP712 structs.
 */
abstract contract SignaturesValidator is ISignaturesValidator, EIP712 {
    // The appended data consists of a deadline, plus the [v,r,s] signature. For simplicity, we use a full 256 bit slot
    // for each of these values, even if 'v' is typically an 8 bit value.
    uint256 internal constant _EXTRA_CALLDATA_LENGTH = 4 * 32;

    // Replay attack prevention for each user.
    mapping(address => uint256) internal _nextNonce;

    constructor(string memory name) EIP712(name, "1") {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getDomainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getNextNonce(address user) external view override returns (uint256) {
        return _nextNonce[user];
    }

    /**
     * @dev Reverts with `errorCode` unless a valid signature for `user` was appended to the calldata.
     */
    function _validateSignature(address user, uint256 errorCode) internal {
        uint256 nextNonce = _nextNonce[user]++;
        _require(_isSignatureValid(user, nextNonce), errorCode);
    }

    function _isSignatureValid(address user, uint256 nonce) private view returns (bool) {
        uint256 deadline = _deadline();

        // The deadline is timestamp-based: it should not be relied upon for sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        if (deadline < block.timestamp) {
            return false;
        }

        bytes32 typeHash = _typeHash();
        if (typeHash == bytes32(0)) {
            // Prevent accidental signature validation for functions that don't have an associated type hash.
            return false;
        }

        // All type hashes have this format: (bytes calldata, address sender, uint256 nonce, uint256 deadline).
        bytes32 structHash = keccak256(abi.encode(typeHash, keccak256(_calldata()), msg.sender, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = _signature();

        address recoveredAddress = ecrecover(digest, v, r, s);

        // ecrecover returns the zero address on recover failure, so we need to handle that explicitly.
        return recoveredAddress != address(0) && recoveredAddress == user;
    }

    /**
     * @dev Returns the EIP712 type hash for the current entry point function, which can be identified by its function
     * selector (available as `msg.sig`).
     *
     * The type hash must conform to the following format:
     *  <name>(bytes calldata, address sender, uint256 nonce, uint256 deadline)
     *
     * If 0x00, all signatures will be considered invalid.
     */
    function _typeHash() internal view virtual returns (bytes32);

    /**
     * @dev Extracts the signature deadline from extra calldata.
     *
     * This function returns bogus data if no signature is included.
     */
    function _deadline() internal pure returns (uint256) {
        // The deadline is the first extra argument at the end of the original calldata.
        return uint256(_decodeExtraCalldataWord(0));
    }

    /**
     * @dev Extracts the signature parameters from extra calldata.
     *
     * This function returns bogus data if no signature is included. This is not a security risk, as that data would not
     * be considered a valid signature in the first place.
     */
    function _signature()
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // v, r and s are appended after the signature deadline, in that order.
        v = uint8(uint256(_decodeExtraCalldataWord(0x20)));
        r = _decodeExtraCalldataWord(0x40);
        s = _decodeExtraCalldataWord(0x60);
    }

    /**
     * @dev Returns the original calldata, without the extra bytes containing the signature.
     *
     * This function returns bogus data if no signature is included.
     */
    function _calldata() internal pure returns (bytes memory result) {
        result = msg.data; // A calldata to memory assignment results in memory allocation and copy of contents.
        if (result.length > _EXTRA_CALLDATA_LENGTH) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We simply overwrite the array length with the reduced one.
                mstore(result, sub(calldatasize(), _EXTRA_CALLDATA_LENGTH))
            }
        }
    }

    /**
     * @dev Returns a 256 bit word from 'extra' calldata, at some offset from the expected end of the original calldata.
     *
     * This function returns bogus data if no signature is included.
     */
    function _decodeExtraCalldataWord(uint256 offset) private pure returns (bytes32 result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := calldataload(add(sub(calldatasize(), _EXTRA_CALLDATA_LENGTH), offset))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

// Based on the ReentrancyGuard library from OpenZeppelin contracts, altered to reduce bytecode size.
// Modifier code is inlined by the compiler, which causes its code to appear multiple times in the codebase. By using
// private functions, we achieve the same end result with slightly higher runtime gas costs but reduced bytecode size.

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
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        _require(_status != _ENTERED, Errors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IWETH.sol";
import "./IAsset.sol";
import "./IAuthorizer.sol";
import "./IFlashLoanRecipient.sol";
import "../ProtocolFeesCollector.sol";

import "../../lib/helpers/ISignaturesValidator.sol";
import "../../lib/helpers/ITemporarilyPausable.sol";

pragma solidity ^0.7.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        // Silence state mutability warning without generating bytecode.
        // See https://github.com/ethereum/solidity/issues/10090#issuecomment-741789128 and
        // https://github.com/ethereum/solidity/issues/2691
        this;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "../../lib/openzeppelin/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin/IERC20.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/helpers/Authentication.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAuthorizer.sol";

/**
 * @dev This an auxiliary contract to the Vault, deployed by it during construction. It offloads some of the tasks the
 * Vault performs to reduce its overall bytecode size.
 *
 * The current values for all protocol fee percentages are stored here, and any tokens charged as protocol fees are
 * sent to this contract, where they may be withdrawn by authorized entities. All authorization tasks are delegated
 * to the Vault's own authorizer.
 */
contract ProtocolFeesCollector is Authentication, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Absolute maximum fee percentages (1e18 = 100%, 1e16 = 1%).
    uint256 private constant _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE = 50e16; // 50%
    uint256 private constant _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE = 1e16; // 1%

    IVault public immutable vault;

    // All fee percentages are 18-decimal fixed point numbers.

    // The swap fee is charged whenever a swap occurs, as a percentage of the fee charged by the Pool. These are not
    // actually charged on each individual swap: the `Vault` relies on the Pools being honest and reporting fees due
    // when users join and exit them.
    uint256 private _swapFeePercentage;

    // The flash loan fee is charged whenever a flash loan occurs, as a percentage of the tokens lent.
    uint256 private _flashLoanFeePercentage;

    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    constructor(IVault _vault)
        // The ProtocolFeesCollector is a singleton, so it simply uses its own address to disambiguate action
        // identifiers.
        Authentication(bytes32(uint256(address(this))))
    {
        vault = _vault;
    }

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external nonReentrant authenticate {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            token.safeTransfer(recipient, amount);
        }
    }

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external authenticate {
        _require(newSwapFeePercentage <= _MAX_PROTOCOL_SWAP_FEE_PERCENTAGE, Errors.SWAP_FEE_PERCENTAGE_TOO_HIGH);
        _swapFeePercentage = newSwapFeePercentage;
        emit SwapFeePercentageChanged(newSwapFeePercentage);
    }

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external authenticate {
        _require(
            newFlashLoanFeePercentage <= _MAX_PROTOCOL_FLASH_LOAN_FEE_PERCENTAGE,
            Errors.FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH
        );
        _flashLoanFeePercentage = newFlashLoanFeePercentage;
        emit FlashLoanFeePercentageChanged(newFlashLoanFeePercentage);
    }

    function getSwapFeePercentage() external view returns (uint256) {
        return _swapFeePercentage;
    }

    function getFlashLoanFeePercentage() external view returns (uint256) {
        return _flashLoanFeePercentage;
    }

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts) {
        feeAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            feeAmounts[i] = tokens[i].balanceOf(address(this));
        }
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 actionId, address account) internal view override returns (bool) {
        return _getAuthorizer().canPerform(actionId, account, address(this));
    }

    function _getAuthorizer() internal view returns (IAuthorizer) {
        return vault.getAuthorizer();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "./BalancerErrors.sol";

import "../../vault/interfaces/IAsset.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IAsset[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./IERC20.sol";

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
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/FixedPoint.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./ProtocolFeesCollector.sol";
import "./VaultAuthorization.sol";
import "./interfaces/IVault.sol";

/**
 * @dev To reduce the bytecode size of the Vault, most of the protocol fee logic is not here, but in the
 * ProtocolFeesCollector contract.
 */
abstract contract Fees is IVault {
    using SafeERC20 for IERC20;

    ProtocolFeesCollector private immutable _protocolFeesCollector;

    constructor() {
        _protocolFeesCollector = new ProtocolFeesCollector(IVault(this));
    }

    function getProtocolFeesCollector() public view override returns (ProtocolFeesCollector) {
        return _protocolFeesCollector;
    }

    /**
     * @dev Returns the protocol swap fee percentage.
     */
    function _getProtocolSwapFeePercentage() internal view returns (uint256) {
        return getProtocolFeesCollector().getSwapFeePercentage();
    }

    /**
     * @dev Returns the protocol fee amount to charge for a flash loan of `amount`.
     */
    function _calculateFlashLoanFeeAmount(uint256 amount) internal view returns (uint256) {
        // Fixed point multiplication introduces error: we round up, which means in certain scenarios the charged
        // percentage can be slightly higher than intended.
        uint256 percentage = getProtocolFeesCollector().getFlashLoanFeePercentage();
        return FixedPoint.mulUp(amount, percentage);
    }

    function _payFeeAmount(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            token.safeTransfer(address(getProtocolFeesCollector()), amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "./LogExpMath.sol";
import "../helpers/BalancerErrors.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            _require(aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            _require(aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((aInflated - 1) / b) + 1;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        if (raw < maxError) {
            return 0;
        } else {
            return sub(raw, maxError);
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        return add(raw, maxError);
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General internal License for more details.

// You should have received a copy of the GNU General internal License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);

        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = ln_36(base);
        } else {
            logBase = ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = ln_36(arg);
        } else {
            logArg = ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev High precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// Based on the EnumerableMap library from OpenZeppelin contracts, altered to include the following:
//  * a map from IERC20 to bytes32
//  * entries are stored in mappings instead of arrays, reducing implicit storage reads for out-of-bounds checks
//  * unchecked_at and unchecked_valueAt, which allow for more gas efficient data reads in some scenarios
//  * unchecked_indexOf and unchecked_setAt, which allow for more gas efficient data writes in some scenarios
//
// Additionally, the base private functions that work on bytes32 were removed and replaced with a native implementation
// for IERC20 keys, to reduce bytecode size and runtime costs.

// We're using non-standard casing for the unchecked functions to differentiate them, so we need to turn off that rule
// solhint-disable func-name-mixedcase

import "./IERC20.sol";

import "../helpers/BalancerErrors.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 */
library EnumerableMap {
    // The original OpenZeppelin implementation uses a generic Map type with bytes32 keys: this was replaced with
    // IERC20ToBytes32Map, which uses IERC20 keys natively, resulting in more dense bytecode.

    struct IERC20ToBytes32MapEntry {
        IERC20 _key;
        bytes32 _value;
    }

    struct IERC20ToBytes32Map {
        // Number of entries in the map
        uint256 _length;
        // Storage of map keys and values
        mapping(uint256 => IERC20ToBytes32MapEntry) _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(IERC20 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        bytes32 value
    ) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        // Equivalent to !contains(map, key)
        if (keyIndex == 0) {
            uint256 previousLength = map._length;
            map._entries[previousLength] = IERC20ToBytes32MapEntry({ _key: key, _value: value });
            map._length = previousLength + 1;

            // The entry is stored at previousLength, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = previousLength + 1;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Updates the value for an entry, given its key's index. The key index can be retrieved via
     * {unchecked_indexOf}, and it should be noted that key indices may change when calling {set} or {remove}. O(1).
     *
     * This function performs one less storage read than {set}, but it should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_setAt(
        IERC20ToBytes32Map storage map,
        uint256 index,
        bytes32 value
    ) internal {
        map._entries[index]._value = value;
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(IERC20ToBytes32Map storage map, IERC20 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        // Equivalent to contains(map, key)
        if (keyIndex != 0) {
            // To delete a key-value pair from the _entries pseudo-array in O(1), we swap the entry to delete with the
            // one at the highest index, and then remove this last entry (sometimes called as 'swap and pop').
            // This modifies the order of the pseudo-array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            IERC20ToBytes32MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            delete map._entries[lastIndex];
            map._length = lastIndex;

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(IERC20ToBytes32Map storage map) internal view returns (uint256) {
        return map._length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        _require(map._length > index, Errors.OUT_OF_BOUNDS);
        return unchecked_at(map, index);
    }

    /**
     * @dev Same as {at}, except this doesn't revert if `index` it outside of the map (i.e. if it is equal or larger
     * than {length}). O(1).
     *
     * This function performs one less storage read than {at}, but should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        IERC20ToBytes32MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Same as {unchecked_At}, except it only returns the value and not the key (performing one less storage
     * read). O(1).
     */
    function unchecked_valueAt(IERC20ToBytes32Map storage map, uint256 index) internal view returns (bytes32) {
        return map._entries[index]._value;
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map. Reverts with `errorCode` otherwise.
     */
    function get(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        uint256 errorCode
    ) internal view returns (bytes32) {
        uint256 index = map._indexes[key];
        _require(index > 0, errorCode);
        return unchecked_valueAt(map, index - 1);
    }

    /**
     * @dev Returns the index for `key` **plus one**. Does not revert if the key is not in the map, and returns 0
     * instead.
     */
    function unchecked_indexOf(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (uint256) {
        return map._indexes[key];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

// Based on the EnumerableSet library from OpenZeppelin contracts, altered to remove the base private functions that
// work on bytes32, replacing them with a native implementation for address values, to reduce bytecode size and runtime
// costs.
// The `unchecked_at` function was also added, which allows for more gas efficient data reads in some scenarios.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // The original OpenZeppelin implementation uses a generic Set type with bytes32 values: this was replaced with
    // AddressSet, which uses address keys natively, resulting in more dense bytecode.

    struct AddressSet {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            address lastValue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastValue;
            // Update the index for the moved value
            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        _require(set._values.length > index, Errors.OUT_OF_BOUNDS);
        return unchecked_at(set, index);
    }

    /**
     * @dev Same as {at}, except this doesn't revert if `index` it outside of the set (i.e. if it is equal or larger
     * than {length}). O(1).
     *
     * This function performs one less storage read than {at}, but should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_at(AddressSet storage set, uint256 index) internal view returns (address) {
        return set._values[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        _require(value < 2**255, Errors.SAFE_CAST_VALUE_CANT_FIT_INT256);
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./Fees.sol";
import "./PoolTokens.sol";
import "./UserBalance.sol";
import "./interfaces/IBasePool.sol";

/**
 * @dev Stores the Asset Managers (by Pool and token), and implements the top level Asset Manager and Pool interfaces,
 * such as registering and deregistering tokens, joining and exiting Pools, and informational functions like `getPool`
 * and `getPoolTokens`, delegating to specialization-specific functions as needed.
 *
 * `managePoolBalance` handles all Asset Manager interactions.
 */
abstract contract PoolBalances is Fees, ReentrancyGuard, PoolTokens, UserBalance {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable override whenNotPaused {
        // This function doesn't have the nonReentrant modifier: it is applied to `_joinOrExit` instead.

        // Note that `recipient` is not actually payable in the context of a join - we cast it because we handle both
        // joins and exits at once.
        _joinOrExit(PoolBalanceChangeKind.JOIN, poolId, sender, payable(recipient), _toPoolBalanceChange(request));
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external override {
        // This function doesn't have the nonReentrant modifier: it is applied to `_joinOrExit` instead.
        _joinOrExit(PoolBalanceChangeKind.EXIT, poolId, sender, recipient, _toPoolBalanceChange(request));
    }

    // This has the exact same layout as JoinPoolRequest and ExitPoolRequest, except the `maxAmountsIn` and
    // `minAmountsOut` are called `limits`. Internally we use this struct for both since these two functions are quite
    // similar, but expose the others to callers for clarity.
    struct PoolBalanceChange {
        IAsset[] assets;
        uint256[] limits;
        bytes userData;
        bool useInternalBalance;
    }

    /**
     * @dev Converts a JoinPoolRequest into a PoolBalanceChange, with no runtime cost.
     */
    function _toPoolBalanceChange(JoinPoolRequest memory request)
        private
        pure
        returns (PoolBalanceChange memory change)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            change := request
        }
    }

    /**
     * @dev Converts an ExitPoolRequest into a PoolBalanceChange, with no runtime cost.
     */
    function _toPoolBalanceChange(ExitPoolRequest memory request)
        private
        pure
        returns (PoolBalanceChange memory change)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            change := request
        }
    }

    /**
     * @dev Implements both `joinPool` and `exitPool`, based on `kind`.
     */
    function _joinOrExit(
        PoolBalanceChangeKind kind,
        bytes32 poolId,
        address sender,
        address payable recipient,
        PoolBalanceChange memory change
    ) private nonReentrant withRegisteredPool(poolId) authenticateFor(sender) {
        // This function uses a large number of stack variables (poolId, sender and recipient, balances, amounts, fees,
        // etc.), which leads to 'stack too deep' issues. It relies on private functions with seemingly arbitrary
        // interfaces to work around this limitation.

        InputHelpers.ensureInputLengthMatch(change.assets.length, change.limits.length);

        // We first check that the caller passed the Pool's registered tokens in the correct order, and retrieve the
        // current balance for each.
        IERC20[] memory tokens = _translateToIERC20(change.assets);
        bytes32[] memory balances = _validateTokensAndGetBalances(poolId, tokens);

        // The bulk of the work is done here: the corresponding Pool hook is called, its final balances are computed,
        // assets are transferred, and fees are paid.
        (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory paidProtocolSwapFeeAmounts
        ) = _callPoolBalanceChange(kind, poolId, sender, recipient, change, balances);

        // All that remains is storing the new Pool balances.
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _setTwoTokenPoolCashBalances(poolId, tokens[0], finalBalances[0], tokens[1], finalBalances[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _setMinimalSwapInfoPoolBalances(poolId, tokens, finalBalances);
        } else {
            // PoolSpecialization.GENERAL
            _setGeneralPoolBalances(poolId, finalBalances);
        }

        bool positive = kind == PoolBalanceChangeKind.JOIN; // Amounts in are positive, out are negative
        emit PoolBalanceChanged(
            poolId,
            sender,
            tokens,
            // We can unsafely cast to int256 because balances are actually stored as uint112
            _unsafeCastToInt256(amountsInOrOut, positive),
            paidProtocolSwapFeeAmounts
        );
    }

    /**
     * @dev Calls the corresponding Pool hook to get the amounts in/out plus protocol fee amounts, and performs the
     * associated token transfers and fee payments, returning the Pool's final balances.
     */
    function _callPoolBalanceChange(
        PoolBalanceChangeKind kind,
        bytes32 poolId,
        address sender,
        address payable recipient,
        PoolBalanceChange memory change,
        bytes32[] memory balances
    )
        private
        returns (
            bytes32[] memory finalBalances,
            uint256[] memory amountsInOrOut,
            uint256[] memory dueProtocolFeeAmounts
        )
    {
        (uint256[] memory totalBalances, uint256 lastChangeBlock) = balances.totalsAndLastChangeBlock();

        IBasePool pool = IBasePool(_getPoolAddress(poolId));
        (amountsInOrOut, dueProtocolFeeAmounts) = kind == PoolBalanceChangeKind.JOIN
            ? pool.onJoinPool(
                poolId,
                sender,
                recipient,
                totalBalances,
                lastChangeBlock,
                _getProtocolSwapFeePercentage(),
                change.userData
            )
            : pool.onExitPool(
                poolId,
                sender,
                recipient,
                totalBalances,
                lastChangeBlock,
                _getProtocolSwapFeePercentage(),
                change.userData
            );

        InputHelpers.ensureInputLengthMatch(balances.length, amountsInOrOut.length, dueProtocolFeeAmounts.length);

        // The Vault ignores the `recipient` in joins and the `sender` in exits: it is up to the Pool to keep track of
        // their participation.
        finalBalances = kind == PoolBalanceChangeKind.JOIN
            ? _processJoinPoolTransfers(sender, change, balances, amountsInOrOut, dueProtocolFeeAmounts)
            : _processExitPoolTransfers(recipient, change, balances, amountsInOrOut, dueProtocolFeeAmounts);
    }

    /**
     * @dev Transfers `amountsIn` from `sender`, checking that they are within their accepted limits, and pays
     * accumulated protocol swap fees.
     *
     * Returns the Pool's final balances, which are the current balances plus `amountsIn` minus accumulated protocol
     * swap fees.
     */
    function _processJoinPoolTransfers(
        address sender,
        PoolBalanceChange memory change,
        bytes32[] memory balances,
        uint256[] memory amountsIn,
        uint256[] memory dueProtocolFeeAmounts
    ) private returns (bytes32[] memory finalBalances) {
        // We need to track how much of the received ETH was used and wrapped into WETH to return any excess.
        uint256 wrappedEth = 0;

        finalBalances = new bytes32[](balances.length);
        for (uint256 i = 0; i < change.assets.length; ++i) {
            uint256 amountIn = amountsIn[i];
            _require(amountIn <= change.limits[i], Errors.JOIN_ABOVE_MAX);

            // Receive assets from the sender - possibly from Internal Balance.
            IAsset asset = change.assets[i];
            _receiveAsset(asset, amountIn, sender, change.useInternalBalance);

            if (_isETH(asset)) {
                wrappedEth = wrappedEth.add(amountIn);
            }

            uint256 feeAmount = dueProtocolFeeAmounts[i];
            _payFeeAmount(_translateToIERC20(asset), feeAmount);

            // Compute the new Pool balances. Note that the fee amount might be larger than `amountIn`,
            // resulting in an overall decrease of the Pool's balance for a token.
            finalBalances[i] = (amountIn >= feeAmount) // This lets us skip checked arithmetic
                ? balances[i].increaseCash(amountIn - feeAmount)
                : balances[i].decreaseCash(feeAmount - amountIn);
        }

        // Handle any used and remaining ETH.
        _handleRemainingEth(wrappedEth);
    }

    /**
     * @dev Transfers `amountsOut` to `recipient`, checking that they are within their accepted limits, and pays
     * accumulated protocol swap fees from the Pool.
     *
     * Returns the Pool's final balances, which are the current `balances` minus `amountsOut` and fees paid
     * (`dueProtocolFeeAmounts`).
     */
    function _processExitPoolTransfers(
        address payable recipient,
        PoolBalanceChange memory change,
        bytes32[] memory balances,
        uint256[] memory amountsOut,
        uint256[] memory dueProtocolFeeAmounts
    ) private returns (bytes32[] memory finalBalances) {
        finalBalances = new bytes32[](balances.length);
        for (uint256 i = 0; i < change.assets.length; ++i) {
            uint256 amountOut = amountsOut[i];
            _require(amountOut >= change.limits[i], Errors.EXIT_BELOW_MIN);

            // Send tokens to the recipient - possibly to Internal Balance
            IAsset asset = change.assets[i];
            _sendAsset(asset, amountOut, recipient, change.useInternalBalance);

            uint256 feeAmount = dueProtocolFeeAmounts[i];
            _payFeeAmount(_translateToIERC20(asset), feeAmount);

            // Compute the new Pool balances. A Pool's token balance always decreases after an exit (potentially by 0).
            finalBalances[i] = balances[i].decreaseCash(amountOut.add(feeAmount));
        }
    }

    /**
     * @dev Returns the total balance for `poolId`'s `expectedTokens`.
     *
     * `expectedTokens` must exactly equal the token array returned by `getPoolTokens`: both arrays must have the same
     * length, elements and order. Additionally, the Pool must have at least one registered token.
     */
    function _validateTokensAndGetBalances(bytes32 poolId, IERC20[] memory expectedTokens)
        private
        view
        returns (bytes32[] memory)
    {
        (IERC20[] memory actualTokens, bytes32[] memory balances) = _getPoolTokens(poolId);
        InputHelpers.ensureInputLengthMatch(actualTokens.length, expectedTokens.length);
        _require(actualTokens.length > 0, Errors.POOL_NO_TOKENS);

        for (uint256 i = 0; i < actualTokens.length; ++i) {
            _require(actualTokens[i] == expectedTokens[i], Errors.TOKENS_MISMATCH);
        }

        return balances;
    }

    /**
     * @dev Casts an array of uint256 to int256, setting the sign of the result according to the `positive` flag,
     * without checking whether the values fit in the signed 256 bit range.
     */
    function _unsafeCastToInt256(uint256[] memory values, bool positive)
        private
        pure
        returns (int256[] memory signedValues)
    {
        signedValues = new int256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            signedValues[i] = positive ? int256(values[i]) : -int256(values[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/openzeppelin/IERC20.sol";

import "./IVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev IPools with the General specialization setting should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will
 * grant to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IBasePool.sol";

/**
 * @dev Pool contracts with the MinimalSwapInfo or TwoToken specialization settings should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will grant
 * to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IMinimalSwapInfoPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../../lib/math/Math.sol";

// This library is used to create a data structure that represents a token's balance for a Pool. 'cash' is how many
// tokens the Pool has sitting inside of the Vault. 'managed' is how many tokens were withdrawn from the Vault by the
// Pool's Asset Manager. 'total' is the sum of these two, and represents the Pool's total token balance, including
// tokens that are *not* inside of the Vault.
//
// 'cash' is updated whenever tokens enter and exit the Vault, while 'managed' is only updated if the reason tokens are
// moving is due to an Asset Manager action. This is reflected in the different methods available: 'increaseCash'
// and 'decreaseCash' for swaps and add/remove liquidity events, and 'cashToManaged' and 'managedToCash' for events
// transferring funds to and from the Asset Manager.
//
// The Vault disallows the Pool's 'cash' from becoming negative. In other words, it can never use any tokens that are
// not inside the Vault.
//
// One of the goals of this library is to store the entire token balance in a single storage slot, which is why we use
// 112 bit unsigned integers for 'cash' and 'managed'. For consistency, we also disallow any combination of 'cash' and
// 'managed' that yields a 'total' that doesn't fit in 112 bits.
//
// The remaining 32 bits of the slot are used to store the most recent block when the total balance changed. This
// can be used to implement price oracles that are resilient to 'sandwich' attacks.
//
// We could use a Solidity struct to pack these three values together in a single storage slot, but unfortunately
// Solidity only allows for structs to live in either storage, calldata or memory. Because a memory struct still takes
// up a slot in the stack (to store its memory location), and because the entire balance fits in a single stack slot
// (two 112 bit values plus the 32 bit block), using memory is strictly less gas performant. Therefore, we do manual
// packing and unpacking.
//
// Since we cannot define new types, we rely on bytes32 to represent these values instead, as it doesn't have any
// associated arithmetic operations and therefore reduces the chance of misuse.
library BalanceAllocation {
    using Math for uint256;

    // The 'cash' portion of the balance is stored in the least significant 112 bits of a 256 bit word, while the
    // 'managed' part uses the following 112 bits. The most significant 32 bits are used to store the block

    /**
     * @dev Returns the total amount of Pool tokens, including those that are not currently in the Vault ('managed').
     */
    function total(bytes32 balance) internal pure returns (uint256) {
        // Since 'cash' and 'managed' are 112 bit values, we don't need checked arithmetic. Additionally, `toBalance`
        // ensures that 'total' always fits in 112 bits.
        return cash(balance) + managed(balance);
    }

    /**
     * @dev Returns the amount of Pool tokens currently in the Vault.
     */
    function cash(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance) & mask;
    }

    /**
     * @dev Returns the amount of Pool tokens that are being managed by an Asset Manager.
     */
    function managed(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance >> 112) & mask;
    }

    /**
     * @dev Returns the last block when the total balance changed.
     */
    function lastChangeBlock(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(32) - 1;
        return uint256(balance >> 224) & mask;
    }

    /**
     * @dev Returns the difference in 'managed' between two balances.
     */
    function managedDelta(bytes32 newBalance, bytes32 oldBalance) internal pure returns (int256) {
        // Because `managed` is a 112 bit value, we can safely perform unchecked arithmetic in 256 bits.
        return int256(managed(newBalance)) - int256(managed(oldBalance));
    }

    /**
     * @dev Returns the total balance for each entry in `balances`, as well as the latest block when the total
     * balance of *any* of them last changed.
     */
    function totalsAndLastChangeBlock(bytes32[] memory balances)
        internal
        pure
        returns (
            uint256[] memory results,
            uint256 lastChangeBlock_ // Avoid shadowing
        )
    {
        results = new uint256[](balances.length);
        lastChangeBlock_ = 0;

        for (uint256 i = 0; i < results.length; i++) {
            bytes32 balance = balances[i];
            results[i] = total(balance);
            lastChangeBlock_ = Math.max(lastChangeBlock_, lastChangeBlock(balance));
        }
    }

    /**
     * @dev Returns true if `balance`'s 'total' balance is zero. Costs less gas than computing 'total' and comparing
     * with zero.
     */
    function isZero(bytes32 balance) internal pure returns (bool) {
        // We simply need to check the least significant 224 bytes of the word: the block does not affect this.
        uint256 mask = 2**(224) - 1;
        return (uint256(balance) & mask) == 0;
    }

    /**
     * @dev Returns true if `balance`'s 'total' balance is not zero. Costs less gas than computing 'total' and comparing
     * with zero.
     */
    function isNotZero(bytes32 balance) internal pure returns (bool) {
        return !isZero(balance);
    }

    /**
     * @dev Packs together `cash` and `managed` amounts with a block to create a balance value.
     *
     * For consistency, this also checks that the sum of `cash` and `managed` (`total`) fits in 112 bits.
     */
    function toBalance(
        uint256 _cash,
        uint256 _managed,
        uint256 _blockNumber
    ) internal pure returns (bytes32) {
        uint256 _total = _cash + _managed;

        // Since both 'cash' and 'managed' are positive integers, by checking that their sum ('total') fits in 112 bits
        // we are also indirectly checking that both 'cash' and 'managed' themselves fit in 112 bits.
        _require(_total >= _cash && _total < 2**112, Errors.BALANCE_TOTAL_OVERFLOW);

        // We assume the block fits in 32 bits - this is expected to hold for at least a few decades.
        return _pack(_cash, _managed, _blockNumber);
    }

    /**
     * @dev Increases a Pool's 'cash' (and therefore its 'total'). Called when Pool tokens are sent to the Vault (except
     * for Asset Manager deposits).
     *
     * Updates the last total balance change block, even if `amount` is zero.
     */
    function increaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 currentManaged = managed(balance);
        uint256 newLastChangeBlock = block.number;

        return toBalance(newCash, currentManaged, newLastChangeBlock);
    }

    /**
     * @dev Decreases a Pool's 'cash' (and therefore its 'total'). Called when Pool tokens are sent from the Vault
     * (except for Asset Manager withdrawals).
     *
     * Updates the last total balance change block, even if `amount` is zero.
     */
    function decreaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 currentManaged = managed(balance);
        uint256 newLastChangeBlock = block.number;

        return toBalance(newCash, currentManaged, newLastChangeBlock);
    }

    /**
     * @dev Moves 'cash' into 'managed', leaving 'total' unchanged. Called when an Asset Manager withdraws Pool tokens
     * from the Vault.
     */
    function cashToManaged(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 newManaged = managed(balance).add(amount);
        uint256 currentLastChangeBlock = lastChangeBlock(balance);

        return toBalance(newCash, newManaged, currentLastChangeBlock);
    }

    /**
     * @dev Moves 'managed' into 'cash', leaving 'total' unchanged. Called when an Asset Manager deposits Pool tokens
     * into the Vault.
     */
    function managedToCash(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 newManaged = managed(balance).sub(amount);
        uint256 currentLastChangeBlock = lastChangeBlock(balance);

        return toBalance(newCash, newManaged, currentLastChangeBlock);
    }

    /**
     * @dev Sets 'managed' balance to an arbitrary value, changing 'total'. Called when the Asset Manager reports
     * profits or losses. It's the Manager's responsibility to provide a meaningful value.
     *
     * Updates the last total balance change block, even if `newManaged` is equal to the current 'managed' value.
     */
    function setManaged(bytes32 balance, uint256 newManaged) internal view returns (bytes32) {
        uint256 currentCash = cash(balance);
        uint256 newLastChangeBlock = block.number;
        return toBalance(currentCash, newManaged, newLastChangeBlock);
    }

    // Alternative mode for Pools with the Two Token specialization setting

    // Instead of storing cash and external for each 'token in' a single storage slot, Two Token Pools store the cash
    // for both tokens in the same slot, and the managed for both in another one. This reduces the gas cost for swaps,
    // because the only slot that needs to be updated is the one with the cash. However, it also means that managing
    // balances is more cumbersome, as both tokens need to be read/written at the same time.
    //
    // The field with both cash balances packed is called sharedCash, and the one with external amounts is called
    // sharedManaged. These two are collectively called the 'shared' balance fields. In both of these, the portion
    // that corresponds to token A is stored in the least significant 112 bits of a 256 bit word, while token B's part
    // uses the next least significant 112 bits.
    //
    // Because only cash is written to during a swap, we store the last total balance change block with the
    // packed cash fields. Typically Pools have a distinct block per token: in the case of Two Token Pools they
    // are the same.

    /**
     * @dev Extracts the part of the balance that corresponds to token A. This function can be used to decode both
     * shared cash and managed balances.
     */
    function _decodeBalanceA(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance) & mask;
    }

    /**
     * @dev Extracts the part of the balance that corresponds to token B. This function can be used to decode both
     * shared cash and managed balances.
     */
    function _decodeBalanceB(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance >> 112) & mask;
    }

    // To decode the last balance change block, we can simply use the `blockNumber` function.

    /**
     * @dev Unpacks the shared token A and token B cash and managed balances into the balance for token A.
     */
    function fromSharedToBalanceA(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
        // Note that we extract the block from the sharedCash field, which is the one that is updated by swaps.
        // Both token A and token B use the same block
        return toBalance(_decodeBalanceA(sharedCash), _decodeBalanceA(sharedManaged), lastChangeBlock(sharedCash));
    }

    /**
     * @dev Unpacks the shared token A and token B cash and managed balances into the balance for token B.
     */
    function fromSharedToBalanceB(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
        // Note that we extract the block from the sharedCash field, which is the one that is updated by swaps.
        // Both token A and token B use the same block
        return toBalance(_decodeBalanceB(sharedCash), _decodeBalanceB(sharedManaged), lastChangeBlock(sharedCash));
    }

    /**
     * @dev Returns the sharedCash shared field, given the current balances for token A and token B.
     */
    function toSharedCash(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
        // Both balances are assigned the same block  Since it is possible a single one of them has changed (for
        // example, in an Asset Manager update), we keep the latest (largest) one.
        uint32 newLastChangeBlock = uint32(Math.max(lastChangeBlock(tokenABalance), lastChangeBlock(tokenBBalance)));

        return _pack(cash(tokenABalance), cash(tokenBBalance), newLastChangeBlock);
    }

    /**
     * @dev Returns the sharedManaged shared field, given the current balances for token A and token B.
     */
    function toSharedManaged(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
        // We don't bother storing a last change block, as it is read from the shared cash field.
        return _pack(managed(tokenABalance), managed(tokenBBalance), 0);
    }

    // Shared functions

    /**
     * @dev Packs together two uint112 and one uint32 into a bytes32
     */
    function _pack(
        uint256 _leastSignificant,
        uint256 _midSignificant,
        uint256 _mostSignificant
    ) private pure returns (bytes32) {
        return bytes32((_mostSignificant << 224) + (_midSignificant << 112) + _leastSignificant);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./AssetManagers.sol";
import "./PoolRegistry.sol";
import "./balances/BalanceAllocation.sol";

abstract contract PoolTokens is ReentrancyGuard, PoolRegistry, AssetManagers {
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];

    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external override nonReentrant whenNotPaused onlyPool(poolId) {
        InputHelpers.ensureInputLengthMatch(tokens.length, assetManagers.length);

        // Validates token addresses and assigns Asset Managers
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            _require(token != IERC20(0), Errors.INVALID_TOKEN);

            _poolAssetManagers[poolId][token] = assetManagers[i];
        }

        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _require(tokens.length == 2, Errors.TOKENS_LENGTH_MUST_BE_2);
            _registerTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _registerMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
            // PoolSpecialization.GENERAL
            _registerGeneralPoolTokens(poolId, tokens);
        }

        emit TokensRegistered(poolId, tokens, assetManagers);
    }

    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens)
        external
        override
        nonReentrant
        whenNotPaused
        onlyPool(poolId)
    {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _require(tokens.length == 2, Errors.TOKENS_LENGTH_MUST_BE_2);
            _deregisterTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _deregisterMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
            // PoolSpecialization.GENERAL
            _deregisterGeneralPoolTokens(poolId, tokens);
        }

        // The deregister calls above ensure the total token balance is zero. Therefore it is now safe to remove any
        // associated Asset Managers, since they hold no Pool balance.
        for (uint256 i = 0; i < tokens.length; ++i) {
            delete _poolAssetManagers[poolId][tokens[i]];
        }

        emit TokensDeregistered(poolId, tokens);
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        )
    {
        bytes32[] memory rawBalances;
        (tokens, rawBalances) = _getPoolTokens(poolId);
        (balances, lastChangeBlock) = rawBalances.totalsAndLastChangeBlock();
    }

    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        )
    {
        bytes32 balance;
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        if (specialization == PoolSpecialization.TWO_TOKEN) {
            balance = _getTwoTokenPoolBalance(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            balance = _getMinimalSwapInfoPoolBalance(poolId, token);
        } else {
            // PoolSpecialization.GENERAL
            balance = _getGeneralPoolBalance(poolId, token);
        }

        cash = balance.cash();
        managed = balance.managed();
        lastChangeBlock = balance.lastChangeBlock();
        assetManager = _poolAssetManagers[poolId][token];
    }

    /**
     * @dev Returns all of `poolId`'s registered tokens, along with their raw balances.
     */
    function _getPoolTokens(bytes32 poolId) internal view returns (IERC20[] memory tokens, bytes32[] memory balances) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _getTwoTokenPoolTokens(poolId);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _getMinimalSwapInfoPoolTokens(poolId);
        } else {
            // PoolSpecialization.GENERAL
            return _getGeneralPoolTokens(poolId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/math/Math.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";
import "../lib/openzeppelin/SafeCast.sol";
import "../lib/openzeppelin/SafeERC20.sol";

import "./AssetTransfersHandler.sol";
import "./VaultAuthorization.sol";

/**
 * Implement User Balance interactions, which combine Internal Balance and using the Vault's ERC20 allowance.
 *
 * Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
 * transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
 * when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
 * gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
 *
 * Internal Balance management features batching, which means a single contract call can be used to perform multiple
 * operations of different kinds, with different senders and recipients, at once.
 */
abstract contract UserBalance is ReentrancyGuard, AssetTransfersHandler, VaultAuthorization {
    using Math for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    // Internal Balance for each token, for each account.
    mapping(address => mapping(IERC20 => uint256)) private _internalTokenBalance;

    function getInternalBalance(address user, IERC20[] memory tokens)
        external
        view
        override
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = _getInternalBalance(user, tokens[i]);
        }
    }

    function manageUserBalance(UserBalanceOp[] memory ops) external payable override nonReentrant {
        // We need to track how much of the received ETH was used and wrapped into WETH to return any excess.
        uint256 ethWrapped = 0;

        // Cache for these checks so we only perform them once (if at all).
        bool checkedCallerIsRelayer = false;
        bool checkedNotPaused = false;

        for (uint256 i = 0; i < ops.length; i++) {
            UserBalanceOpKind kind;
            IAsset asset;
            uint256 amount;
            address sender;
            address payable recipient;

            // This destructuring by calling `_validateUserBalanceOp` seems odd, but results in reduced bytecode size.
            (kind, asset, amount, sender, recipient, checkedCallerIsRelayer) = _validateUserBalanceOp(
                ops[i],
                checkedCallerIsRelayer
            );

            if (kind == UserBalanceOpKind.WITHDRAW_INTERNAL) {
                // Internal Balance withdrawals can always be performed by an authorized account.
                _withdrawFromInternalBalance(asset, sender, recipient, amount);
            } else {
                // All other operations are blocked if the contract is paused.

                // We cache the result of the pause check and skip it for other operations in this same transaction
                // (if any).
                if (!checkedNotPaused) {
                    _ensureNotPaused();
                    checkedNotPaused = true;
                }

                if (kind == UserBalanceOpKind.DEPOSIT_INTERNAL) {
                    _depositToInternalBalance(asset, sender, recipient, amount);

                    // Keep track of all ETH wrapped into WETH as part of a deposit.
                    if (_isETH(asset)) {
                        ethWrapped = ethWrapped.add(amount);
                    }
                } else {
                    // Transfers don't support ETH.
                    _require(!_isETH(asset), Errors.CANNOT_USE_ETH_SENTINEL);
                    IERC20 token = _asIERC20(asset);

                    if (kind == UserBalanceOpKind.TRANSFER_INTERNAL) {
                        _transferInternalBalance(token, sender, recipient, amount);
                    } else {
                        // TRANSFER_EXTERNAL
                        _transferToExternalBalance(token, sender, recipient, amount);
                    }
                }
            }
        }

        // Handle any remaining ETH.
        _handleRemainingEth(ethWrapped);
    }

    function _depositToInternalBalance(
        IAsset asset,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _increaseInternalBalance(recipient, _translateToIERC20(asset), amount);
        _receiveAsset(asset, amount, sender, false);
    }

    function _withdrawFromInternalBalance(
        IAsset asset,
        address sender,
        address payable recipient,
        uint256 amount
    ) private {
        // A partial decrease of Internal Balance is disallowed: `sender` must have the full `amount`.
        _decreaseInternalBalance(sender, _translateToIERC20(asset), amount, false);
        _sendAsset(asset, amount, recipient, false);
    }

    function _transferInternalBalance(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // A partial decrease of Internal Balance is disallowed: `sender` must have the full `amount`.
        _decreaseInternalBalance(sender, token, amount, false);
        _increaseInternalBalance(recipient, token, amount);
    }

    function _transferToExternalBalance(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (amount > 0) {
            token.safeTransferFrom(sender, recipient, amount);
            emit ExternalBalanceTransfer(token, sender, recipient, amount);
        }
    }

    /**
     * @dev Increases `account`'s Internal Balance for `token` by `amount`.
     */
    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal override {
        uint256 currentBalance = _getInternalBalance(account, token);
        uint256 newBalance = currentBalance.add(amount);
        _setInternalBalance(account, token, newBalance, amount.toInt256());
    }

    /**
     * @dev Decreases `account`'s Internal Balance for `token` by `amount`. If `allowPartial` is true, this function
     * doesn't revert if `account` doesn't have enough balance, and sets it to zero and returns the deducted amount
     * instead.
     */
    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool allowPartial
    ) internal override returns (uint256 deducted) {
        uint256 currentBalance = _getInternalBalance(account, token);
        _require(allowPartial || (currentBalance >= amount), Errors.INSUFFICIENT_INTERNAL_BALANCE);

        deducted = Math.min(currentBalance, amount);
        // By construction, `deducted` is lower or equal to `currentBalance`, so we don't need to use checked
        // arithmetic.
        uint256 newBalance = currentBalance - deducted;
        _setInternalBalance(account, token, newBalance, -(deducted.toInt256()));
    }

    /**
     * @dev Sets `account`'s Internal Balance for `token` to `newBalance`.
     *
     * Emits an `InternalBalanceChanged` event. This event includes `delta`, which is the amount the balance increased
     * (if positive) or decreased (if negative). To avoid reading the current balance in order to compute the delta,
     * this function relies on the caller providing it directly.
     */
    function _setInternalBalance(
        address account,
        IERC20 token,
        uint256 newBalance,
        int256 delta
    ) private {
        _internalTokenBalance[account][token] = newBalance;
        emit InternalBalanceChanged(account, token, delta);
    }

    /**
     * @dev Returns `account`'s Internal Balance for `token`.
     */
    function _getInternalBalance(address account, IERC20 token) internal view returns (uint256) {
        return _internalTokenBalance[account][token];
    }

    /**
     * @dev Destructures a User Balance operation, validating that the contract caller is allowed to perform it.
     */
    function _validateUserBalanceOp(UserBalanceOp memory op, bool checkedCallerIsRelayer)
        private
        view
        returns (
            UserBalanceOpKind,
            IAsset,
            uint256,
            address,
            address payable,
            bool
        )
    {
        // The only argument we need to validate is `sender`, which can only be either the contract caller, or a
        // relayer approved by `sender`.
        address sender = op.sender;

        if (sender != msg.sender) {
            // We need to check both that the contract caller is a relayer, and that `sender` approved them.

            // Because the relayer check is global (i.e. independent of `sender`), we cache that result and skip it for
            // other operations in this same transaction (if any).
            if (!checkedCallerIsRelayer) {
                _authenticateCaller();
                checkedCallerIsRelayer = true;
            }

            _require(_hasApprovedRelayer(sender, msg.sender), Errors.USER_DOESNT_ALLOW_RELAYER);
        }

        return (op.kind, op.asset, op.amount, sender, op.recipient, checkedCallerIsRelayer);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./IPoolSwapStructs.sol";

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `currentBalances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `currentBalances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/helpers/InputHelpers.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/openzeppelin/SafeERC20.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./UserBalance.sol";
import "./balances/BalanceAllocation.sol";
import "./balances/GeneralPoolsBalance.sol";
import "./balances/MinimalSwapInfoPoolsBalance.sol";
import "./balances/TwoTokenPoolsBalance.sol";

abstract contract AssetManagers is
    ReentrancyGuard,
    GeneralPoolsBalance,
    MinimalSwapInfoPoolsBalance,
    TwoTokenPoolsBalance
{
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Stores the Asset Manager for each token of each Pool.
    mapping(bytes32 => mapping(IERC20 => address)) internal _poolAssetManagers;

    function managePoolBalance(PoolBalanceOp[] memory ops) external override nonReentrant whenNotPaused {
        // This variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        // loop iteration, increasing gas costs.
        PoolBalanceOp memory op;

        for (uint256 i = 0; i < ops.length; ++i) {
            // By indexing the array only once, we don't spend extra gas in the same bounds check.
            op = ops[i];

            bytes32 poolId = op.poolId;
            _ensureRegisteredPool(poolId);

            IERC20 token = op.token;
            _require(_isTokenRegistered(poolId, token), Errors.TOKEN_NOT_REGISTERED);
            _require(_poolAssetManagers[poolId][token] == msg.sender, Errors.SENDER_NOT_ASSET_MANAGER);

            PoolBalanceOpKind kind = op.kind;
            uint256 amount = op.amount;
            (int256 cashDelta, int256 managedDelta) = _performPoolManagementOperation(kind, poolId, token, amount);

            emit PoolBalanceManaged(poolId, msg.sender, token, cashDelta, managedDelta);
        }
    }

    /**
     * @dev Performs the `kind` Asset Manager operation on a Pool.
     *
     * Withdrawals will transfer `amount` tokens to the caller, deposits will transfer `amount` tokens from the caller,
     * and updates will set the managed balance to `amount`.
     *
     * Returns a tuple with the 'cash' and 'managed' balance deltas as a result of this call.
     */
    function _performPoolManagementOperation(
        PoolBalanceOpKind kind,
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) private returns (int256, int256) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        if (kind == PoolBalanceOpKind.WITHDRAW) {
            return _withdrawPoolBalance(poolId, specialization, token, amount);
        } else if (kind == PoolBalanceOpKind.DEPOSIT) {
            return _depositPoolBalance(poolId, specialization, token, amount);
        } else {
            // PoolBalanceOpKind.UPDATE
            return _updateManagedBalance(poolId, specialization, token, amount);
        }
    }

    /**
     * @dev Moves `amount` tokens from a Pool's 'cash' to 'managed' balance, and transfers them to the caller.
     *
     * Returns the 'cash' and 'managed' balance deltas as a result of this call, which will be complementary.
     */
    function _withdrawPoolBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _twoTokenPoolCashToManaged(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _minimalSwapInfoPoolCashToManaged(poolId, token, amount);
        } else {
            // PoolSpecialization.GENERAL
            _generalPoolCashToManaged(poolId, token, amount);
        }

        if (amount > 0) {
            token.safeTransfer(msg.sender, amount);
        }

        // Since 'cash' and 'managed' are stored as uint112, `amount` is guaranteed to also fit in 112 bits. It will
        // therefore always fit in a 256 bit integer.
        cashDelta = int256(-amount);
        managedDelta = int256(amount);
    }

    /**
     * @dev Moves `amount` tokens from a Pool's 'managed' to 'cash' balance, and transfers them from the caller.
     *
     * Returns the 'cash' and 'managed' balance deltas as a result of this call, which will be complementary.
     */
    function _depositPoolBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _twoTokenPoolManagedToCash(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _minimalSwapInfoPoolManagedToCash(poolId, token, amount);
        } else {
            // PoolSpecialization.GENERAL
            _generalPoolManagedToCash(poolId, token, amount);
        }

        if (amount > 0) {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }

        // Since 'cash' and 'managed' are stored as uint112, `amount` is guaranteed to also fit in 112 bits. It will
        // therefore always fit in a 256 bit integer.
        cashDelta = int256(amount);
        managedDelta = int256(-amount);
    }

    /**
     * @dev Sets a Pool's 'managed' balance to `amount`.
     *
     * Returns the 'cash' and 'managed' balance deltas as a result of this call (the 'cash' delta will always be zero).
     */
    function _updateManagedBalance(
        bytes32 poolId,
        PoolSpecialization specialization,
        IERC20 token,
        uint256 amount
    ) private returns (int256 cashDelta, int256 managedDelta) {
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            managedDelta = _setTwoTokenPoolManagedBalance(poolId, token, amount);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            managedDelta = _setMinimalSwapInfoPoolManagedBalance(poolId, token, amount);
        } else {
            // PoolSpecialization.GENERAL
            managedDelta = _setGeneralPoolManagedBalance(poolId, token, amount);
        }

        cashDelta = 0;
    }

    /**
     * @dev Returns true if `token` is registered for `poolId`.
     */
    function _isTokenRegistered(bytes32 poolId, IERC20 token) private view returns (bool) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _isTwoTokenPoolTokenRegistered(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _isMinimalSwapInfoPoolTokenRegistered(poolId, token);
        } else {
            // PoolSpecialization.GENERAL
            return _isGeneralPoolTokenRegistered(poolId, token);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/ReentrancyGuard.sol";

import "./VaultAuthorization.sol";

/**
 * @dev Maintains the Pool ID data structure, implements Pool ID creation and registration, and defines useful modifiers
 * and helper functions for ensuring correct behavior when working with Pools.
 */
abstract contract PoolRegistry is ReentrancyGuard, VaultAuthorization {
    // Each pool is represented by their unique Pool ID. We use `bytes32` for them, for lack of a way to define new
    // types.
    mapping(bytes32 => bool) private _isPoolRegistered;

    // We keep an increasing nonce to make Pool IDs unique. It is interpreted as a `uint80`, but storing it as a
    // `uint256` results in reduced bytecode on reads and writes due to the lack of masking.
    uint256 private _nextPoolNonce;

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     */
    modifier withRegisteredPool(bytes32 poolId) {
        _ensureRegisteredPool(poolId);
        _;
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool, and the caller is the Pool's contract.
     */
    modifier onlyPool(bytes32 poolId) {
        _ensurePoolIsSender(poolId);
        _;
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     */
    function _ensureRegisteredPool(bytes32 poolId) internal view {
        _require(_isPoolRegistered[poolId], Errors.INVALID_POOL_ID);
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool, and the caller is the Pool's contract.
     */
    function _ensurePoolIsSender(bytes32 poolId) private view {
        _ensureRegisteredPool(poolId);
        _require(msg.sender == _getPoolAddress(poolId), Errors.CALLER_NOT_POOL);
    }

    function registerPool(PoolSpecialization specialization)
        external
        override
        nonReentrant
        whenNotPaused
        returns (bytes32)
    {
        // Each Pool is assigned a unique ID based on an incrementing nonce. This assumes there will never be more than
        // 2**80 Pools, and the nonce will not overflow.

        bytes32 poolId = _toPoolId(msg.sender, specialization, uint80(_nextPoolNonce));

        _require(!_isPoolRegistered[poolId], Errors.INVALID_POOL_ID); // Should never happen as Pool IDs are unique.
        _isPoolRegistered[poolId] = true;

        _nextPoolNonce += 1;

        // Note that msg.sender is the pool's contract
        emit PoolRegistered(poolId, msg.sender, specialization);
        return poolId;
    }

    function getPool(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (address, PoolSpecialization)
    {
        return (_getPoolAddress(poolId), _getPoolSpecialization(poolId));
    }

    /**
     * @dev Creates a Pool ID.
     *
     * These are deterministically created by packing the Pool's contract address and its specialization setting into
     * the ID. This saves gas by making this data easily retrievable from a Pool ID with no storage accesses.
     *
     * Since a single contract can register multiple Pools, a unique nonce must be provided to ensure Pool IDs are
     * unique.
     *
     * Pool IDs have the following layout:
     * | 20 bytes pool contract address | 2 bytes specialization setting | 10 bytes nonce |
     * MSB                                                                              LSB
     *
     * 2 bytes for the specialization setting is a bit overkill: there only three of them, which means two bits would
     * suffice. However, there's nothing else of interest to store in this extra space.
     */
    function _toPoolId(
        address pool,
        PoolSpecialization specialization,
        uint80 nonce
    ) internal pure returns (bytes32) {
        bytes32 serialized;

        serialized |= bytes32(uint256(nonce));
        serialized |= bytes32(uint256(specialization)) << (10 * 8);
        serialized |= bytes32(uint256(pool)) << (12 * 8);

        return serialized;
    }

    /**
     * @dev Returns the address of a Pool's contract.
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolAddress(bytes32 poolId) internal pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        return address(uint256(poolId) >> (12 * 8));
    }

    /**
     * @dev Returns the specialization setting of a Pool.
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolSpecialization(bytes32 poolId) internal pure returns (PoolSpecialization specialization) {
        // 10 byte logical shift left to remove the nonce, followed by a 2 byte mask to remove the address.
        uint256 value = uint256(poolId >> (10 * 8)) & (2**(2 * 8) - 1);

        // Casting a value into an enum results in a runtime check that reverts unless the value is within the enum's
        // range. Passing an invalid Pool ID to this function would then result in an obscure revert with no reason
        // string: we instead perform the check ourselves to help in error diagnosis.

        // There are three Pool specialization settings: general, minimal swap info and two tokens, which correspond to
        // values 0, 1 and 2.
        _require(value < 3, Errors.INVALID_POOL_ID);

        // Because we have checked that `value` is within the enum range, we can use assembly to skip the runtime check.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            specialization := value
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/EnumerableMap.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";

abstract contract GeneralPoolsBalance {
    using BalanceAllocation for bytes32;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    // Data for Pools with the General specialization setting
    //
    // These Pools use the IGeneralPool interface, which means the Vault must query the balance for *all* of their
    // tokens in every swap. If we kept a mapping of token to balance plus a set (array) of tokens, it'd be very gas
    // intensive to read all token addresses just to then do a lookup on the balance mapping.
    //
    // Instead, we use our customized EnumerableMap, which lets us read the N balances in N+1 storage accesses (one for
    // each token in the Pool), access the index of any 'token in' a single read (required for the IGeneralPool call),
    // and update an entry's value given its index.

    // Map of token -> balance pairs for each Pool with this specialization. Many functions rely on storage pointers to
    // a Pool's EnumerableMap to save gas when computing storage slots.
    mapping(bytes32 => EnumerableMap.IERC20ToBytes32Map) internal _generalPoolsBalances;

    /**
     * @dev Registers a list of tokens in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * Requirements:
     *
     * - `tokens` must not be registered in the Pool
     * - `tokens` must not contain duplicates
     */
    function _registerGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            // EnumerableMaps require an explicit initial value when creating a key-value pair: we use zero, the same
            // value that is found in uninitialized storage, which corresponds to an empty balance.
            bool added = poolBalances.set(tokens[i], 0);
            _require(added, Errors.TOKEN_ALREADY_REGISTERED);
        }
    }

    /**
     * @dev Deregisters a list of tokens in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * Requirements:
     *
     * - `tokens` must be registered in the Pool
     * - `tokens` must have zero balance in the Vault
     * - `tokens` must not contain duplicates
     */
    function _deregisterGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);
            _require(currentBalance.isZero(), Errors.NONZERO_TOKEN_BALANCE);

            // We don't need to check remove's return value, since _getGeneralPoolBalance already checks that the token
            // was registered.
            poolBalances.remove(token);
        }
    }

    /**
     * @dev Sets the balances of a General Pool's tokens to `balances`.
     *
     * WARNING: this assumes `balances` has the same length and order as the Pool's tokens.
     */
    function _setGeneralPoolBalances(bytes32 poolId, bytes32[] memory balances) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < balances.length; ++i) {
            // Since we assume all balances are properly ordered, we can simply use `unchecked_setAt` to avoid one less
            // storage read per token.
            poolBalances.unchecked_setAt(i, balances[i]);
        }
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a General Pool from cash into managed.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _generalPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a General Pool from managed into cash.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _generalPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    /**
     * @dev Sets `token`'s managed balance in a General Pool to `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _setGeneralPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateGeneralPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    /**
     * @dev Sets `token`'s balance in a General Pool to the result of the `mutation` function when called with the
     * current balance and `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the General specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _updateGeneralPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private returns (int256) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);

        bytes32 newBalance = mutation(currentBalance, amount);
        poolBalances.set(token, newBalance);

        return newBalance.managedDelta(currentBalance);
    }

    /**
     * @dev Returns an array with all the tokens and balances in a General Pool. The order may change when tokens are
     * registered or deregistered.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     */
    function _getGeneralPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        tokens = new IERC20[](poolBalances.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            // Because the iteration is bounded by `tokens.length`, which matches the EnumerableMap's length, we can use
            // `unchecked_at` as we know `i` is a valid token index, saving storage reads.
            (tokens[i], balances[i]) = poolBalances.unchecked_at(i);
        }
    }

    /**
     * @dev Returns the balance of a token in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * Requirements:
     *
     * - `token` must be registered in the Pool
     */
    function _getGeneralPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return _getGeneralPoolBalance(poolBalances, token);
    }

    /**
     * @dev Same as `_getGeneralPoolBalance` but using a Pool's storage pointer, which saves gas in repeated reads and
     * writes.
     */
    function _getGeneralPoolBalance(EnumerableMap.IERC20ToBytes32Map storage poolBalances, IERC20 token)
        private
        view
        returns (bytes32)
    {
        return poolBalances.get(token, Errors.TOKEN_NOT_REGISTERED);
    }

    /**
     * @dev Returns true if `token` is registered in a General Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     */
    function _isGeneralPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return poolBalances.contains(token);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/EnumerableSet.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";
import "../PoolRegistry.sol";

abstract contract MinimalSwapInfoPoolsBalance is PoolRegistry {
    using BalanceAllocation for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Data for Pools with the Minimal Swap Info specialization setting
    //
    // These Pools use the IMinimalSwapInfoPool interface, and so the Vault must read the balance of the two tokens
    // in the swap. The best solution is to use a mapping from token to balance, which lets us read or write any token's
    // balance in a single storage access.
    //
    // We also keep a set of registered tokens. Because tokens with non-zero balance are by definition registered, in
    // some balance getters we skip checking for token registration if a non-zero balance is found, saving gas by
    // performing a single read instead of two.

    mapping(bytes32 => mapping(IERC20 => bytes32)) internal _minimalSwapInfoPoolsBalances;
    mapping(bytes32 => EnumerableSet.AddressSet) internal _minimalSwapInfoPoolsTokens;

    /**
     * @dev Registers a list of tokens in a Minimal Swap Info Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Minimal Swap Info specialization setting.
     *
     * Requirements:
     *
     * - `tokens` must not be registered in the Pool
     * - `tokens` must not contain duplicates
     */
    function _registerMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            bool added = poolTokens.add(address(tokens[i]));
            _require(added, Errors.TOKEN_ALREADY_REGISTERED);
            // Note that we don't initialize the balance mapping: the default value of zero corresponds to an empty
            // balance.
        }
    }

    /**
     * @dev Deregisters a list of tokens in a Minimal Swap Info Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Minimal Swap Info specialization setting.
     *
     * Requirements:
     *
     * - `tokens` must be registered in the Pool
     * - `tokens` must have zero balance in the Vault
     * - `tokens` must not contain duplicates
     */
    function _deregisterMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            _require(_minimalSwapInfoPoolsBalances[poolId][token].isZero(), Errors.NONZERO_TOKEN_BALANCE);

            // For consistency with other Pool specialization settings, we explicitly reset the balance (which may have
            // a non-zero last change block).
            delete _minimalSwapInfoPoolsBalances[poolId][token];

            bool removed = poolTokens.remove(address(token));
            _require(removed, Errors.TOKEN_NOT_REGISTERED);
        }
    }

    /**
     * @dev Sets the balances of a Minimal Swap Info Pool's tokens to `balances`.
     *
     * WARNING: this assumes `balances` has the same length and order as the Pool's tokens.
     */
    function _setMinimalSwapInfoPoolBalances(
        bytes32 poolId,
        IERC20[] memory tokens,
        bytes32[] memory balances
    ) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            _minimalSwapInfoPoolsBalances[poolId][tokens[i]] = balances[i];
        }
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a Minimal Swap Info Pool from cash into managed.
     *
     * This function assumes `poolId` exists, corresponds to the Minimal Swap Info specialization setting, and that
     * `token` is registered for that Pool.
     */
    function _minimalSwapInfoPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a Minimal Swap Info Pool from managed into cash.
     *
     * This function assumes `poolId` exists, corresponds to the Minimal Swap Info specialization setting, and that
     * `token` is registered for that Pool.
     */
    function _minimalSwapInfoPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    /**
     * @dev Sets `token`'s managed balance in a Minimal Swap Info Pool to `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the Minimal Swap Info specialization setting, and that
     * `token` is registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _setMinimalSwapInfoPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    /**
     * @dev Sets `token`'s balance in a Minimal Swap Info Pool to the result of the `mutation` function when called with
     * the current balance and `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the Minimal Swap Info specialization setting, and that
     * `token` is registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _updateMinimalSwapInfoPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) internal returns (int256) {
        bytes32 currentBalance = _getMinimalSwapInfoPoolBalance(poolId, token);

        bytes32 newBalance = mutation(currentBalance, amount);
        _minimalSwapInfoPoolsBalances[poolId][token] = newBalance;

        return newBalance.managedDelta(currentBalance);
    }

    /**
     * @dev Returns an array with all the tokens and balances in a Minimal Swap Info Pool. The order may change when
     * tokens are registered or deregistered.
     *
     * This function assumes `poolId` exists and corresponds to the Minimal Swap Info specialization setting.
     */
    function _getMinimalSwapInfoPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        tokens = new IERC20[](poolTokens.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            // Because the iteration is bounded by `tokens.length`, which matches the EnumerableSet's length, we can use
            // `unchecked_at` as we know `i` is a valid token index, saving storage reads.
            IERC20 token = IERC20(poolTokens.unchecked_at(i));
            tokens[i] = token;
            balances[i] = _minimalSwapInfoPoolsBalances[poolId][token];
        }
    }

    /**
     * @dev Returns the balance of a token in a Minimal Swap Info Pool.
     *
     * Requirements:
     *
     * - `poolId` must be a Minimal Swap Info Pool
     * - `token` must be registered in the Pool
     */
    function _getMinimalSwapInfoPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        bytes32 balance = _minimalSwapInfoPoolsBalances[poolId][token];

        // A non-zero balance guarantees that the token is registered. If zero, we manually check if the token is
        // registered in the Pool. Token registration implies that the Pool is registered as well, which lets us save
        // gas by not performing the check.
        bool tokenRegistered = balance.isNotZero() || _minimalSwapInfoPoolsTokens[poolId].contains(address(token));

        if (!tokenRegistered) {
            // The token might not be registered because the Pool itself is not registered. We check this to provide a
            // more accurate revert reason.
            _ensureRegisteredPool(poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

        return balance;
    }

    /**
     * @dev Returns true if `token` is registered in a Minimal Swap Info Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Minimal Swap Info specialization setting.
     */
    function _isMinimalSwapInfoPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        return poolTokens.contains(address(token));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/helpers/BalancerErrors.sol";
import "../../lib/openzeppelin/IERC20.sol";

import "./BalanceAllocation.sol";
import "../PoolRegistry.sol";

abstract contract TwoTokenPoolsBalance is PoolRegistry {
    using BalanceAllocation for bytes32;

    // Data for Pools with the Two Token specialization setting
    //
    // These are similar to the Minimal Swap Info Pool case (because the Pool only has two tokens, and therefore there
    // are only two balances to read), but there's a key difference in how data is stored. Keeping a set makes little
    // sense, as it will only ever hold two tokens, so we can just store those two directly.
    //
    // The gas savings associated with using these Pools come from how token balances are stored: cash amounts for token
    // A and token B are packed together, as are managed amounts. Because only cash changes in a swap, there's no need
    // to write to this second storage slot. A single last change block number for both tokens is stored with the packed
    // cash fields.

    struct TwoTokenPoolBalances {
        bytes32 sharedCash;
        bytes32 sharedManaged;
    }

    // We could just keep a mapping from Pool ID to TwoTokenSharedBalances, but there's an issue: we wouldn't know to
    // which tokens those balances correspond. This would mean having to also check which are registered with the Pool.
    //
    // What we do instead to save those storage reads is keep a nested mapping from the token pair hash to the balances
    // struct. The Pool only has two tokens, so only a single entry of this mapping is set (the one that corresponds to
    // that pair's hash).
    //
    // This has the trade-off of making Vault code that interacts with these Pools cumbersome: both balances must be
    // accessed at the same time by using both token addresses, and some logic is needed to determine how the pair hash
    // is computed. We do this by sorting the tokens, calling the token with the lowest numerical address value token A,
    // and the other one token B. In functions where the token arguments could be either A or B, we use X and Y instead.
    //
    // If users query a token pair containing an unregistered token, the Pool will generate a hash for a mapping entry
    // that was not set, and return zero balances. Non-zero balances are only possible if both tokens in the pair
    // are registered with the Pool, which means we don't have to check the TwoTokenPoolTokens struct, and can save
    // storage reads.

    struct TwoTokenPoolTokens {
        IERC20 tokenA;
        IERC20 tokenB;
        mapping(bytes32 => TwoTokenPoolBalances) balances;
    }

    mapping(bytes32 => TwoTokenPoolTokens) private _twoTokenPoolTokens;

    /**
     * @dev Registers tokens in a Two Token Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Two Token specialization setting.
     *
     * Requirements:
     *
     * - `tokenX` and `tokenY` must not be the same
     * - The tokens must be ordered: tokenX < tokenY
     */
    function _registerTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
        // Not technically true since we didn't register yet, but this is consistent with the error messages of other
        // specialization settings.
        _require(tokenX != tokenY, Errors.TOKEN_ALREADY_REGISTERED);

        _require(tokenX < tokenY, Errors.UNSORTED_TOKENS);

        // A Two Token Pool with no registered tokens is identified by having zero addresses for tokens A and B.
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        _require(poolTokens.tokenA == IERC20(0) && poolTokens.tokenB == IERC20(0), Errors.TOKENS_ALREADY_SET);

        // Since tokenX < tokenY, tokenX is A and tokenY is B
        poolTokens.tokenA = tokenX;
        poolTokens.tokenB = tokenY;

        // Note that we don't initialize the balance mapping: the default value of zero corresponds to an empty
        // balance.
    }

    /**
     * @dev Deregisters tokens in a Two Token Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Two Token specialization setting.
     *
     * Requirements:
     *
     * - `tokenX` and `tokenY` must be registered in the Pool
     * - both tokens must have zero balance in the Vault
     */
    function _deregisterTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
        (
            bytes32 balanceA,
            bytes32 balanceB,
            TwoTokenPoolBalances storage poolBalances
        ) = _getTwoTokenPoolSharedBalances(poolId, tokenX, tokenY);

        _require(balanceA.isZero() && balanceB.isZero(), Errors.NONZERO_TOKEN_BALANCE);

        delete _twoTokenPoolTokens[poolId];

        // For consistency with other Pool specialization settings, we explicitly reset the packed cash field (which may
        // have a non-zero last change block).
        delete poolBalances.sharedCash;
    }

    /**
     * @dev Sets the cash balances of a Two Token Pool's tokens.
     *
     * WARNING: this assumes `tokenA` and `tokenB` are the Pool's two registered tokens, and are in the correct order.
     */
    function _setTwoTokenPoolCashBalances(
        bytes32 poolId,
        IERC20 tokenA,
        bytes32 balanceA,
        IERC20 tokenB,
        bytes32 balanceB
    ) internal {
        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        TwoTokenPoolBalances storage poolBalances = _twoTokenPoolTokens[poolId].balances[pairHash];
        poolBalances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a Two Token Pool from cash into managed.
     *
     * This function assumes `poolId` exists, corresponds to the Two Token specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _twoTokenPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    /**
     * @dev Transforms `amount` of `token`'s balance in a Two Token Pool from managed into cash.
     *
     * This function assumes `poolId` exists, corresponds to the Two Token specialization setting, and that `token` is
     * registered for that Pool.
     */
    function _twoTokenPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    /**
     * @dev Sets `token`'s managed balance in a Two Token Pool to `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the Two Token specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _setTwoTokenPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal returns (int256) {
        return _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    /**
     * @dev Sets `token`'s balance in a Two Token Pool to the result of the `mutation` function when called with
     * the current balance and `amount`.
     *
     * This function assumes `poolId` exists, corresponds to the Two Token specialization setting, and that `token` is
     * registered for that Pool.
     *
     * Returns the managed balance delta as a result of this call.
     */
    function _updateTwoTokenPoolSharedBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private returns (int256) {
        (
            TwoTokenPoolBalances storage balances,
            IERC20 tokenA,
            bytes32 balanceA,
            ,
            bytes32 balanceB
        ) = _getTwoTokenPoolBalances(poolId);

        int256 delta;
        if (token == tokenA) {
            bytes32 newBalance = mutation(balanceA, amount);
            delta = newBalance.managedDelta(balanceA);
            balanceA = newBalance;
        } else {
            // token == tokenB
            bytes32 newBalance = mutation(balanceB, amount);
            delta = newBalance.managedDelta(balanceB);
            balanceB = newBalance;
        }

        balances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
        balances.sharedManaged = BalanceAllocation.toSharedManaged(balanceA, balanceB);

        return delta;
    }

    /*
     * @dev Returns an array with all the tokens and balances in a Two Token Pool. The order may change when
     * tokens are registered or deregistered.
     *
     * This function assumes `poolId` exists and corresponds to the Two Token specialization setting.
     */
    function _getTwoTokenPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

        // Both tokens will either be zero (if unregistered) or non-zero (if registered), but we keep the full check for
        // clarity.
        if (tokenA == IERC20(0) || tokenB == IERC20(0)) {
            return (new IERC20[](0), new bytes32[](0));
        }

        // Note that functions relying on this getter expect tokens to be properly ordered, so we use the (A, B)
        // ordering.

        tokens = new IERC20[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        balances = new bytes32[](2);
        balances[0] = balanceA;
        balances[1] = balanceB;
    }

    /**
     * @dev Same as `_getTwoTokenPoolTokens`, except it returns the two tokens and balances directly instead of using
     * an array, as well as a storage pointer to the `TwoTokenPoolBalances` struct, which can be used to update it
     * without having to recompute the pair hash and storage slot.
     */
    function _getTwoTokenPoolBalances(bytes32 poolId)
        private
        view
        returns (
            TwoTokenPoolBalances storage poolBalances,
            IERC20 tokenA,
            bytes32 balanceA,
            IERC20 tokenB,
            bytes32 balanceB
        )
    {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        tokenA = poolTokens.tokenA;
        tokenB = poolTokens.tokenB;

        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        poolBalances = poolTokens.balances[pairHash];

        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    /**
     * @dev Returns the balance of a token in a Two Token Pool.
     *
     * This function assumes `poolId` exists and corresponds to the General specialization setting.
     *
     * This function is convenient but not particularly gas efficient, and should be avoided during gas-sensitive
     * operations, such as swaps. For those, _getTwoTokenPoolSharedBalances provides a more flexible interface.
     *
     * Requirements:
     *
     * - `token` must be registered in the Pool
     */
    function _getTwoTokenPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        // We can't just read the balance of token, because we need to know the full pair in order to compute the pair
        // hash and access the balance mapping. We therefore rely on `_getTwoTokenPoolBalances`.
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

        if (token == tokenA) {
            return balanceA;
        } else if (token == tokenB) {
            return balanceB;
        } else {
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }
    }

    /**
     * @dev Returns the balance of the two tokens in a Two Token Pool.
     *
     * The returned balances are those of token A and token B, where token A is the lowest of token X and token Y, and
     * token B the other.
     *
     * This function also returns a storage pointer to the TwoTokenPoolBalances struct associated with the token pair,
     * which can be used to update it without having to recompute the pair hash and storage slot.
     *
     * Requirements:
     *
     * - `poolId` must be a Minimal Swap Info Pool
     * - `tokenX` and `tokenY` must be registered in the Pool
     */
    function _getTwoTokenPoolSharedBalances(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    )
        internal
        view
        returns (
            bytes32 balanceA,
            bytes32 balanceB,
            TwoTokenPoolBalances storage poolBalances
        )
    {
        (IERC20 tokenA, IERC20 tokenB) = _sortTwoTokens(tokenX, tokenY);
        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);

        poolBalances = _twoTokenPoolTokens[poolId].balances[pairHash];

        // Because we're reading balances using the pair hash, if either token X or token Y is not registered then
        // *both* balance entries will be zero.
        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

        // A non-zero balance guarantees that both tokens are registered. If zero, we manually check whether each
        // token is registered in the Pool. Token registration implies that the Pool is registered as well, which
        // lets us save gas by not performing the check.
        bool tokensRegistered = sharedCash.isNotZero() ||
            sharedManaged.isNotZero() ||
            (_isTwoTokenPoolTokenRegistered(poolId, tokenA) && _isTwoTokenPoolTokenRegistered(poolId, tokenB));

        if (!tokensRegistered) {
            // The tokens might not be registered because the Pool itself is not registered. We check this to provide a
            // more accurate revert reason.
            _ensureRegisteredPool(poolId);
            _revert(Errors.TOKEN_NOT_REGISTERED);
        }

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    /**
     * @dev Returns true if `token` is registered in a Two Token Pool.
     *
     * This function assumes `poolId` exists and corresponds to the Two Token specialization setting.
     */
    function _isTwoTokenPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];

        // The zero address can never be a registered token.
        return (token == poolTokens.tokenA || token == poolTokens.tokenB) && token != IERC20(0);
    }

    /**
     * @dev Returns the hash associated with a given token pair.
     */
    function _getTwoTokenPairHash(IERC20 tokenA, IERC20 tokenB) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    /**
     * @dev Sorts two tokens in ascending order, returning them as a (tokenA, tokenB) tuple.
     */
    function _sortTwoTokens(IERC20 tokenX, IERC20 tokenY) private pure returns (IERC20, IERC20) {
        return tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/math/Math.sol";
import "../lib/helpers/BalancerErrors.sol";
import "../lib/openzeppelin/IERC20.sol";
import "../lib/helpers/AssetHelpers.sol";
import "../lib/openzeppelin/SafeERC20.sol";
import "../lib/openzeppelin/Address.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IVault.sol";

abstract contract AssetTransfersHandler is AssetHelpers {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @dev Receives `amount` of `asset` from `sender`. If `fromInternalBalance` is true, it first withdraws as much
     * as possible from Internal Balance, then transfers any remaining amount.
     *
     * If `asset` is ETH, `fromInternalBalance` must be false (as ETH cannot be held as internal balance), and the funds
     * will be wrapped into WETH.
     *
     * WARNING: this function does not check that the contract caller has actually supplied any ETH - it is up to the
     * caller of this function to check that this is true to prevent the Vault from using its own ETH (though the Vault
     * typically doesn't hold any).
     */
    function _receiveAsset(
        IAsset asset,
        uint256 amount,
        address sender,
        bool fromInternalBalance
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
            _require(!fromInternalBalance, Errors.INVALID_ETH_INTERNAL_BALANCE);

            // The ETH amount to receive is deposited into the WETH contract, which will in turn mint WETH for
            // the Vault at a 1:1 ratio.

            // A check for this condition is also introduced by the compiler, but this one provides a revert reason.
            // Note we're checking for the Vault's total balance, *not* ETH sent in this transaction.
            _require(address(this).balance >= amount, Errors.INSUFFICIENT_ETH);
            _WETH().deposit{ value: amount }();
        } else {
            IERC20 token = _asIERC20(asset);

            if (fromInternalBalance) {
                // We take as many tokens from Internal Balance as possible: any remaining amounts will be transferred.
                uint256 deductedBalance = _decreaseInternalBalance(sender, token, amount, true);
                // Because `deductedBalance` will be always the lesser of the current internal balance
                // and the amount to decrease, it is safe to perform unchecked arithmetic.
                amount -= deductedBalance;
            }

            if (amount > 0) {
                token.safeTransferFrom(sender, address(this), amount);
            }
        }
    }

    /**
     * @dev Sends `amount` of `asset` to `recipient`. If `toInternalBalance` is true, the asset is deposited as Internal
     * Balance instead of being transferred.
     *
     * If `asset` is ETH, `toInternalBalance` must be false (as ETH cannot be held as internal balance), and the funds
     * are instead sent directly after unwrapping WETH.
     */
    function _sendAsset(
        IAsset asset,
        uint256 amount,
        address payable recipient,
        bool toInternalBalance
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
            // Sending ETH is not as involved as receiving it: the only special behavior is it cannot be
            // deposited to Internal Balance.
            _require(!toInternalBalance, Errors.INVALID_ETH_INTERNAL_BALANCE);

            // First, the Vault withdraws deposited ETH from the WETH contract, by burning the same amount of WETH
            // from the Vault. This receipt will be handled by the Vault's `receive`.
            _WETH().withdraw(amount);

            // Then, the withdrawn ETH is sent to the recipient.
            recipient.sendValue(amount);
        } else {
            IERC20 token = _asIERC20(asset);
            if (toInternalBalance) {
                _increaseInternalBalance(recipient, token, amount);
            } else {
                token.safeTransfer(recipient, amount);
            }
        }
    }

    /**
     * @dev Returns excess ETH back to the contract caller, assuming `amountUsed` has been spent. Reverts
     * if the caller sent less ETH than `amountUsed`.
     *
     * Because the caller might not know exactly how much ETH a Vault action will require, they may send extra.
     * Note that this excess value is returned *to the contract caller* (msg.sender). If caller and e.g. swap sender are
     * not the same (because the caller is a relayer for the sender), then it is up to the caller to manage this
     * returned ETH.
     */
    function _handleRemainingEth(uint256 amountUsed) internal {
        _require(msg.value >= amountUsed, Errors.INSUFFICIENT_ETH);

        uint256 excess = msg.value - amountUsed;
        if (excess > 0) {
            msg.sender.sendValue(excess);
        }
    }

    /**
     * @dev Enables the Vault to receive ETH. This is required for it to be able to unwrap WETH, which sends ETH to the
     * caller.
     *
     * Any ETH sent to the Vault outside of the WETH unwrapping mechanism would be forever locked inside the Vault, so
     * we prevent that from happening. Other mechanisms used to send ETH to the Vault (such as being the recipient of an
     * ETH swap, Pool exit or withdrawal, contract self-destruction, or receiving the block mining reward) will result
     * in locked funds, but are not otherwise a security or soundness issue. This check only exists as an attempt to
     * prevent user error.
     */
    receive() external payable {
        _require(msg.sender == address(_WETH()), Errors.ETH_TRANSFER);
    }

    // This contract uses virtual internal functions instead of inheriting from the modules that implement them (in
    // this case UserBalance) in order to decouple it from the rest of the system and enable standalone testing by
    // implementing these with mocks.

    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal virtual;

    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool capped
    ) internal virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "../../vault/interfaces/IAsset.sol";
import "../../vault/interfaces/IWETH.sol";

abstract contract AssetHelpers {
    // solhint-disable-next-line var-name-mixedcase
    IWETH private immutable _weth;

    // Sentinel value used to indicate WETH with wrapping/unwrapping semantics. The zero address is a good choice for
    // multiple reasons: it is cheap to pass as a calldata argument, it is a known invalid token and non-contract, and
    // it is an address Pools cannot register as a token.
    address private constant _ETH = address(0);

    constructor(IWETH weth) {
        _weth = weth;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _WETH() internal view returns (IWETH) {
        return _weth;
    }

    /**
     * @dev Returns true if `asset` is the sentinel value that represents ETH.
     */
    function _isETH(IAsset asset) internal pure returns (bool) {
        return address(asset) == _ETH;
    }

    /**
     * @dev Translates `asset` into an equivalent IERC20 token address. If `asset` represents ETH, it will be translated
     * to the WETH contract.
     */
    function _translateToIERC20(IAsset asset) internal view returns (IERC20) {
        return _isETH(asset) ? _WETH() : _asIERC20(asset);
    }

    /**
     * @dev Same as `_translateToIERC20(IAsset)`, but for an entire array.
     */
    function _translateToIERC20(IAsset[] memory assets) internal view returns (IERC20[] memory) {
        IERC20[] memory tokens = new IERC20[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
            tokens[i] = _translateToIERC20(assets[i]);
        }
        return tokens;
    }

    /**
     * @dev Interprets `asset` as an IERC20 token. This function should only be called on `asset` if `_isETH` previously
     * returned false for it, that is, if `asset` is guaranteed not to be the ETH sentinel value.
     */
    function _asIERC20(IAsset asset) internal pure returns (IERC20) {
        return IERC20(address(asset));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

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
        assembly {
            size := extcodesize(account)
        }
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
        _require(address(this).balance >= amount, Errors.ADDRESS_INSUFFICIENT_BALANCE);

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        _require(success, Errors.ADDRESS_CANNOT_SEND_VALUE);
    }
}

