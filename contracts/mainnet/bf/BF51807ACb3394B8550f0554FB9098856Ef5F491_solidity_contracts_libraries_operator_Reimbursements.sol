pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";
import "../../TokenStaking.sol";

library Reimbursements {
    using SafeMath for uint256;
    using BytesLib for bytes;

    /// @notice Reimburses callback execution cost and surplus based on actual gas
    /// usage to the submitter's beneficiary address and if necessary to the
    /// callback requestor (surplus recipient).
    /// @param stakingContract Staking contract to get the address of the beneficiary
    /// @param gasPriceCeiling Gas price ceiling in wei
    /// @param gasLimit Gas limit set for the callback
    /// @param gasSpent Gas spent by the submitter on the callback
    /// @param callbackFee Fee paid for the callback by the requestor
    /// @param callbackSurplusRecipientData Data containing surplus recipient address
    function reimburseCallback(
        TokenStaking stakingContract,
        uint256 gasPriceCeiling,
        uint256 gasLimit,
        uint256 gasSpent,
        uint256 callbackFee,
        bytes memory callbackSurplusRecipientData
    ) public {
        uint256 gasPrice = gasPriceCeiling;
        // We need to check if tx.gasprice is non-zero as a workaround to a bug
        // in go-ethereum:
        // https://github.com/ethereum/go-ethereum/pull/20189
        if (tx.gasprice > 0 && tx.gasprice < gasPriceCeiling) {
            gasPrice = tx.gasprice;
        }

        // Obtain the actual callback gas expenditure and refund the surplus.
        //
        // In case of heavily underpriced transactions, EVM may wrap the call
        // with additional opcodes. In this case gasSpent > gasLimit.
        // The worst scenario cost is included in entry verification fee.
        // If this happens we return just the gasLimit here.
        uint256 actualCallbackGas = gasSpent < gasLimit ? gasSpent : gasLimit;
        uint256 actualCallbackFee = actualCallbackGas.mul(gasPrice);

        // Get the beneficiary.
        address payable beneficiary = stakingContract.beneficiaryOf(msg.sender);

        // If we spent less on the callback than the customer transferred for the
        // callback execution, we need to reimburse the difference.
        if (actualCallbackFee < callbackFee) {
            uint256 callbackSurplus = callbackFee.sub(actualCallbackFee);
            // Reimburse submitter with his actual callback cost.
            beneficiary.call.value(actualCallbackFee)("");

            // Return callback surplus to the requestor.
            // Expecting 32 bytes data containing 20 byte address
            if (callbackSurplusRecipientData.length == 32) {
                address surplusRecipient = callbackSurplusRecipientData.toAddress(12);
                surplusRecipient.call.gas(8000).value(callbackSurplus)("");
            }
        } else {
            // Reimburse submitter with the callback payment sent by the requestor.
            beneficiary.call.value(callbackFee)("");
        }
    }
}
