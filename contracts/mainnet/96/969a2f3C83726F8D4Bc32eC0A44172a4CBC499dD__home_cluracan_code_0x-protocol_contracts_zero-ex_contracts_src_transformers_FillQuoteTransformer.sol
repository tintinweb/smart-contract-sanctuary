/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "../errors/LibTransformERC20RichErrors.sol";
import "../vendor/v3/IExchange.sol";
import "../vendor/v3/LibOrderHash.sol";
import "./bridges/IBridgeAdapter.sol";
import "./Transformer.sol";
import "./LibERC20Transformer.sol";

/// @dev A transformer that fills an ERC20 market sell/buy quote.
///      This transformer shortcuts bridge orders and fills them directly
contract FillQuoteTransformer is
    Transformer
{
    using LibERC20TokenV06 for IERC20TokenV06;
    using LibERC20Transformer for IERC20TokenV06;
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;
    using LibBytesV06 for bytes;

    /// @dev Whether we are performing a market sell or buy.
    enum Side {
        Sell,
        Buy
    }

    /// @dev Transform data to ABI-encode and pass into `transform()`.
    struct TransformData {
        // Whether we are performing a market sell or buy.
        Side side;
        // The token being sold.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 sellToken;
        // The token being bought.
        // This should be an actual token, not the ETH pseudo-token.
        IERC20TokenV06 buyToken;
        // The orders to fill.
        IExchange.Order[] orders;
        // Signatures for each respective order in `orders`.
        bytes[] signatures;
        // Maximum fill amount for each order. This may be shorter than the
        // number of orders, where missing entries will be treated as `uint256(-1)`.
        // For sells, this will be the maximum sell amount (taker asset).
        // For buys, this will be the maximum buy amount (maker asset).
        uint256[] maxOrderFillAmounts;
        // Amount of `sellToken` to sell or `buyToken` to buy.
        // For sells, this may be `uint256(-1)` to sell the entire balance of
        // `sellToken`.
        uint256 fillAmount;
        // Who to transfer unused protocol fees to.
        // May be a valid address or one of:
        // `address(0)`: Stay in flash wallet.
        // `address(1)`: Send to the taker.
        // `address(2)`: Send to the sender (caller of `transformERC20()`).
        address payable refundReceiver;
        // Required taker address for RFQT orders.
        // Null means any taker can fill it.
        address rfqtTakerAddress;
    }

    /// @dev Results of a call to `_fillOrder()`.
    struct FillOrderResults {
        // The amount of taker tokens sold, according to balance checks.
        uint256 takerTokenSoldAmount;
        // The amount of maker tokens sold, according to balance checks.
        uint256 makerTokenBoughtAmount;
        // The amount of protocol fee paid.
        uint256 protocolFeePaid;
    }

    /// @dev Intermediate state variables to get around stack limits.
    struct FillState {
        uint256 ethRemaining;
        uint256 boughtAmount;
        uint256 soldAmount;
        uint256 protocolFee;
        uint256 takerTokenBalanceRemaining;
        bool isRfqtAllowed;
    }

    /// @dev Emitted when a trade is skipped due to a lack of funds
    ///      to pay the 0x Protocol fee.
    /// @param orderHash The hash of the order that was skipped.
    event ProtocolFeeUnfunded(bytes32 orderHash);

    /// @dev The Exchange ERC20Proxy ID.
    bytes4 private constant ERC20_ASSET_PROXY_ID = 0xf47261b0;
    /// @dev The Exchange ERC20BridgeProxy ID.
    bytes4 private constant ERC20_BRIDGE_PROXY_ID = 0xdc1600f3;
    /// @dev Maximum uint256 value.
    uint256 private constant MAX_UINT256 = uint256(-1);
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the taker.
    address private constant REFUND_RECEIVER_TAKER = address(1);
    /// @dev If `refundReceiver` is set to this address, unpsent
    ///      protocol fees will be sent to the sender.
    address private constant REFUND_RECEIVER_SENDER = address(2);

    /// @dev The Exchange contract.
    IExchange public immutable exchange;
    /// @dev The ERC20Proxy address.
    address public immutable erc20Proxy;
    /// @dev The BridgeAdapter address
    IBridgeAdapter public immutable bridgeAdapter;

    /// @dev Create this contract.
    /// @param exchange_ The Exchange V3 instance.
    constructor(IExchange exchange_, IBridgeAdapter bridgeAdapter_)
        public
        Transformer()
    {
        exchange = exchange_;
        erc20Proxy = exchange_.getAssetProxy(ERC20_ASSET_PROXY_ID);
        bridgeAdapter = bridgeAdapter_;
    }

    /// @dev Sell this contract's entire balance of of `sellToken` in exchange
    ///      for `buyToken` by filling `orders`. Protocol fees should be attached
    ///      to this call. `buyToken` and excess ETH will be transferred back to the caller.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context)
        external
        override
        returns (bytes4 success)
    {
        TransformData memory data = abi.decode(context.data, (TransformData));
        FillState memory state;

        // Validate data fields.
        if (data.sellToken.isTokenETH() || data.buyToken.isTokenETH()) {
            LibTransformERC20RichErrors.InvalidTransformDataError(
                LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_TOKENS,
                context.data
            ).rrevert();
        }
        if (data.orders.length != data.signatures.length) {
            LibTransformERC20RichErrors.InvalidTransformDataError(
                LibTransformERC20RichErrors.InvalidTransformDataErrorCode.INVALID_ARRAY_LENGTH,
                context.data
            ).rrevert();
        }

        state.takerTokenBalanceRemaining = data.sellToken.getTokenBalanceOf(address(this));
        if (data.side == Side.Sell && data.fillAmount == MAX_UINT256) {
            // If `sellAmount == -1 then we are selling
            // the entire balance of `sellToken`. This is useful in cases where
            // the exact sell amount is not exactly known in advance, like when
            // unwrapping Chai/cUSDC/cDAI.
            data.fillAmount = state.takerTokenBalanceRemaining;
        }

        // Approve the ERC20 proxy to spend `sellToken`.
        data.sellToken.approveIfBelow(erc20Proxy, data.fillAmount);

        state.protocolFee = exchange.protocolFeeMultiplier().safeMul(tx.gasprice);
        state.ethRemaining = address(this).balance;
        // RFQT orders can only be filled if we have a valid calldata hash
        // (calldata was signed), and the actual taker matches the RFQT taker (if set).
        state.isRfqtAllowed = context.callDataHash != bytes32(0)
            && (data.rfqtTakerAddress == address(0) || context.taker == data.rfqtTakerAddress);

        // Fill the orders.
        for (uint256 i = 0; i < data.orders.length; ++i) {
            // Check if we've hit our targets.
            if (data.side == Side.Sell) {
                // Market sell check.
                if (state.soldAmount >= data.fillAmount) {
                    break;
                }
            } else {
                // Market buy check.
                if (state.boughtAmount >= data.fillAmount) {
                    break;
                }
            }

            // Fill the order.
            FillOrderResults memory results;
            if (data.side == Side.Sell) {
                // Market sell.
                results = _sellToOrder(
                    data.buyToken,
                    data.sellToken,
                    data.orders[i],
                    data.signatures[i],
                    data.fillAmount.safeSub(state.soldAmount).min256(
                        data.maxOrderFillAmounts.length > i
                        ? data.maxOrderFillAmounts[i]
                        : MAX_UINT256
                    ),
                    state
                );
            } else {
                // Market buy.
                results = _buyFromOrder(
                    data.buyToken,
                    data.sellToken,
                    data.orders[i],
                    data.signatures[i],
                    data.fillAmount.safeSub(state.boughtAmount).min256(
                        data.maxOrderFillAmounts.length > i
                        ? data.maxOrderFillAmounts[i]
                        : MAX_UINT256
                    ),
                    state
                );
            }

            // Accumulate totals.
            state.soldAmount = state.soldAmount.safeAdd(results.takerTokenSoldAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(results.makerTokenBoughtAmount);
            state.ethRemaining = state.ethRemaining.safeSub(results.protocolFeePaid);
            state.takerTokenBalanceRemaining = state.takerTokenBalanceRemaining.safeSub(results.takerTokenSoldAmount);
        }

        // Ensure we hit our targets.
        if (data.side == Side.Sell) {
            // Market sell check.
            if (state.soldAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillSellQuoteError(
                        address(data.sellToken),
                        state.soldAmount,
                        data.fillAmount
                    ).rrevert();
            }
        } else {
            // Market buy check.
            if (state.boughtAmount < data.fillAmount) {
                LibTransformERC20RichErrors
                    .IncompleteFillBuyQuoteError(
                        address(data.buyToken),
                        state.boughtAmount,
                        data.fillAmount
                    ).rrevert();
            }
        }

        // Refund unspent protocol fees.
        if (state.ethRemaining > 0 && data.refundReceiver != address(0)) {
            if (data.refundReceiver == REFUND_RECEIVER_TAKER) {
                context.taker.transfer(state.ethRemaining);
            } else if (data.refundReceiver == REFUND_RECEIVER_SENDER) {
                context.sender.transfer(state.ethRemaining);
            } else {
                data.refundReceiver.transfer(state.ethRemaining);
            }
        }
        return LibERC20Transformer.TRANSFORMER_SUCCESS;
    }

    /// @dev Try to sell up to `sellAmount` from an order.
    /// @param makerToken The maker/buy token.
    /// @param takerToken The taker/sell token.
    /// @param order The order to fill.
    /// @param signature The signature for `order`.
    /// @param sellAmount Amount of taker token to sell.
    /// @param state Intermediate state variables to get around stack limits.
    function _sellToOrder(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        IExchange.Order memory order,
        bytes memory signature,
        uint256 sellAmount,
        FillState memory state
    )
        private
        returns (FillOrderResults memory results)
    {
        IERC20TokenV06 takerFeeToken =
            _getTokenFromERC20AssetData(order.takerFeeAssetData);

        uint256 takerTokenFillAmount = sellAmount;

        if (order.takerFee != 0) {
            if (takerFeeToken == makerToken) {
                // Taker fee is payable in the maker token, so we need to
                // approve the proxy to spend the maker token.
                // It isn't worth computing the actual taker fee
                // since `approveIfBelow()` will set the allowance to infinite. We
                // just need a reasonable upper bound to avoid unnecessarily re-approving.
                takerFeeToken.approveIfBelow(erc20Proxy, order.takerFee);
            } else if (takerFeeToken == takerToken){
                // Taker fee is payable in the taker token, so we need to
                // reduce the fill amount to cover the fee.
                // takerTokenFillAmount' =
                //   (takerTokenFillAmount * order.takerAssetAmount) /
                //   (order.takerAssetAmount + order.takerFee)
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    order.takerAssetAmount,
                    order.takerAssetAmount.safeAdd(order.takerFee),
                    sellAmount
                );
            } else {
                //  Only support taker or maker asset denominated taker fees.
                LibTransformERC20RichErrors.InvalidTakerFeeTokenError(
                    address(takerFeeToken)
                ).rrevert();
            }
        }

        // Perform the fill.
        return _fillOrder(
            order,
            signature,
            takerTokenFillAmount,
            state,
            takerFeeToken == takerToken
        );
    }

    /// @dev Try to buy up to `buyAmount` from an order.
    /// @param makerToken The maker/buy token.
    /// @param takerToken The taker/sell token.
    /// @param order The order to fill.
    /// @param signature The signature for `order`.
    /// @param buyAmount Amount of maker token to buy.
    /// @param state Intermediate state variables to get around stack limits.
    function _buyFromOrder(
        IERC20TokenV06 makerToken,
        IERC20TokenV06 takerToken,
        IExchange.Order memory order,
        bytes memory signature,
        uint256 buyAmount,
        FillState memory state
    )
        private
        returns (FillOrderResults memory results)
    {
        IERC20TokenV06 takerFeeToken =
            _getTokenFromERC20AssetData(order.takerFeeAssetData);
        // Compute the default taker token fill amount.
        uint256 takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
            buyAmount,
            order.makerAssetAmount,
            order.takerAssetAmount
        );

        if (order.takerFee != 0) {
            if (takerFeeToken == makerToken) {
                // Taker fee is payable in the maker token.
                // Adjust the taker token fill amount to account for maker
                // tokens being lost to the taker fee.
                // takerTokenFillAmount' =
                //  (order.takerAssetAmount * buyAmount) /
                //  (order.makerAssetAmount - order.takerFee)
                takerTokenFillAmount = LibMathV06.getPartialAmountCeil(
                    buyAmount,
                    order.makerAssetAmount.safeSub(order.takerFee),
                    order.takerAssetAmount
                );
                // Approve the proxy to spend the maker token.
                // It isn't worth computing the actual taker fee
                // since `approveIfBelow()` will set the allowance to infinite. We
                // just need a reasonable upper bound to avoid unnecessarily re-approving.
                takerFeeToken.approveIfBelow(erc20Proxy, order.takerFee);
            } else if (takerFeeToken != takerToken) {
                //  Only support taker or maker asset denominated taker fees.
                LibTransformERC20RichErrors.InvalidTakerFeeTokenError(
                    address(takerFeeToken)
                ).rrevert();
            }
        }

        // Perform the fill.
        return _fillOrder(
            order,
            signature,
            takerTokenFillAmount,
            state,
            takerFeeToken == takerToken
        );
    }

    /// @dev Attempt to fill an order. If the fill reverts, the revert will be
    ///      swallowed and `results` will be zeroed out.
    /// @param order The order to fill.
    /// @param signature The order signature.
    /// @param takerAssetFillAmount How much taker asset to fill.
    /// @param state Intermediate state variables to get around stack limits.
    /// @param isTakerFeeInTakerToken Whether the taker fee token is the same as the
    ///        taker token.
    function _fillOrder(
        IExchange.Order memory order,
        bytes memory signature,
        uint256 takerAssetFillAmount,
        FillState memory state,
        bool isTakerFeeInTakerToken
    )
        private
        returns (FillOrderResults memory results)
    {
        // Clamp to remaining taker asset amount or order size.
        uint256 availableTakerAssetFillAmount =
            takerAssetFillAmount.min256(order.takerAssetAmount);
        availableTakerAssetFillAmount =
            availableTakerAssetFillAmount.min256(state.takerTokenBalanceRemaining);

        // If it is a Bridge order we fill this directly through the BridgeAdapter
        if (order.makerAssetData.readBytes4(0) == ERC20_BRIDGE_PROXY_ID) {
            (bool success, bytes memory resultData) = address(bridgeAdapter).delegatecall(
                abi.encodeWithSelector(
                    IBridgeAdapter.trade.selector,
                    order.makerAssetData,
                    address(_getTokenFromERC20AssetData(order.takerAssetData)),
                    availableTakerAssetFillAmount
                )
            );
            if (success) {
                results.makerTokenBoughtAmount = abi.decode(resultData, (uint256));
                results.takerTokenSoldAmount = availableTakerAssetFillAmount;
                // protocol fee paid remains 0
            }
            return results;
        } else {
            // If the order taker address is set to this contract's address then
            // this is an RFQT order, and we will only fill it if allowed to.
            if (order.takerAddress == address(this) && !state.isRfqtAllowed) {
                return results; // Empty results.
            }
            // Emit an event if we do not have sufficient ETH to cover the protocol fee.
            if (state.ethRemaining < state.protocolFee) {
                bytes32 orderHash = LibOrderHash.getTypedDataHash(
                    order,
                    exchange.EIP712_EXCHANGE_DOMAIN_HASH()
                );
                emit ProtocolFeeUnfunded(orderHash);
                return results;
            }
            try
                exchange.fillOrder
                    {value: state.protocolFee}
                    (order, availableTakerAssetFillAmount, signature)
                returns (IExchange.FillResults memory fillResults)
            {
                results.makerTokenBoughtAmount = fillResults.makerAssetFilledAmount;
                results.takerTokenSoldAmount = fillResults.takerAssetFilledAmount;
                results.protocolFeePaid = fillResults.protocolFeePaid;
                // If the taker fee is payable in the taker asset, include the
                // taker fee in the total amount sold.
                if (isTakerFeeInTakerToken) {
                    results.takerTokenSoldAmount =
                        results.takerTokenSoldAmount.safeAdd(fillResults.takerFeePaid);
                }
            } catch (bytes memory) {
                // Swallow failures, leaving all results as zero.
            }
        }
    }

    /// @dev Extract the token from plain ERC20 asset data.
    ///      If the asset-data is empty, a zero token address will be returned.
    /// @param assetData The order asset data.
    function _getTokenFromERC20AssetData(bytes memory assetData)
        private
        pure
        returns (IERC20TokenV06 token)
    {
        if (assetData.length == 0) {
            return IERC20TokenV06(address(0));
        }
        if (assetData.length != 36 ||
            LibBytesV06.readBytes4(assetData, 0) != ERC20_ASSET_PROXY_ID)
        {
            LibTransformERC20RichErrors
                .InvalidERC20AssetDataError(assetData)
                .rrevert();
        }
        return IERC20TokenV06(LibBytesV06.readAddress(assetData, 16));
    }
}
