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

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibMathV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../src/vendor/v3/IExchange.sol";
import "./TestMintableERC20Token.sol";


contract TestFillQuoteTransformerExchange {

    struct FillBehavior {
        // How much of the order is filled, in taker asset amount.
        uint256 filledTakerAssetAmount;
        // Scaling for maker assets minted, in 1e18.
        uint256 makerAssetMintRatio;
    }

    uint256 private constant PROTOCOL_FEE_MULTIPLIER = 1337;

    using LibSafeMathV06 for uint256;

    function fillOrder(
        IExchange.Order calldata order,
        uint256 takerAssetFillAmount,
        bytes calldata signature
    )
        external
        payable
        returns (IExchange.FillResults memory fillResults)
    {
        require(
            signature.length != 0,
            "TestFillQuoteTransformerExchange/INVALID_SIGNATURE"
        );
        // The signature is the ABI-encoded FillBehavior data.
        FillBehavior memory behavior = abi.decode(signature, (FillBehavior));

        uint256 protocolFee = PROTOCOL_FEE_MULTIPLIER * tx.gasprice;
        require(
            msg.value == protocolFee,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_PROTOCOL_FEE"
        );
        // Return excess protocol fee.
        msg.sender.transfer(msg.value - protocolFee);

        // Take taker tokens.
        TestMintableERC20Token takerToken = _getTokenFromAssetData(order.takerAssetData);
        takerAssetFillAmount = LibSafeMathV06.min256(
            order.takerAssetAmount.safeSub(behavior.filledTakerAssetAmount),
            takerAssetFillAmount
        );
        require(
            takerToken.getSpendableAmount(msg.sender, address(this)) >= takerAssetFillAmount,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_TAKER_FUNDS"
        );
        takerToken.transferFrom(msg.sender, order.makerAddress, takerAssetFillAmount);

        // Mint maker tokens.
        uint256 makerAssetFilledAmount = LibMathV06.getPartialAmountFloor(
            takerAssetFillAmount,
            order.takerAssetAmount,
            order.makerAssetAmount
        );
        TestMintableERC20Token makerToken = _getTokenFromAssetData(order.makerAssetData);
        makerToken.mint(
            msg.sender,
            LibMathV06.getPartialAmountFloor(
                behavior.makerAssetMintRatio,
                1e18,
                makerAssetFilledAmount
            )
        );

        // Take taker fee.
        TestMintableERC20Token takerFeeToken = _getTokenFromAssetData(order.takerFeeAssetData);
        uint256 takerFee = LibMathV06.getPartialAmountFloor(
            takerAssetFillAmount,
            order.takerAssetAmount,
            order.takerFee
        );
        require(
            takerFeeToken.getSpendableAmount(msg.sender, address(this)) >= takerFee,
            "TestFillQuoteTransformerExchange/INSUFFICIENT_TAKER_FEE_FUNDS"
        );
        takerFeeToken.transferFrom(msg.sender, order.feeRecipientAddress, takerFee);

        fillResults.makerAssetFilledAmount = makerAssetFilledAmount;
        fillResults.takerAssetFilledAmount = takerAssetFillAmount;
        fillResults.makerFeePaid = uint256(-1);
        fillResults.takerFeePaid = takerFee;
        fillResults.protocolFeePaid = protocolFee;
    }

    function encodeBehaviorData(FillBehavior calldata behavior)
        external
        pure
        returns (bytes memory encoded)
    {
        return abi.encode(behavior);
    }

    function protocolFeeMultiplier()
        external
        pure
        returns (uint256)
    {
        return PROTOCOL_FEE_MULTIPLIER;
    }

    function getAssetProxy(bytes4)
        external
        view
        returns (address)
    {
        return address(this);
    }

    function _getTokenFromAssetData(bytes memory assetData)
        private
        pure
        returns (TestMintableERC20Token token)
    {
        return TestMintableERC20Token(LibBytesV06.readAddress(assetData, 16));
    }
}
