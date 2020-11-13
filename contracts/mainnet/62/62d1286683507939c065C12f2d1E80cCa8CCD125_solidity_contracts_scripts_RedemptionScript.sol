pragma solidity 0.5.17;

import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";
import {TBTCDepositToken} from "../system/TBTCDepositToken.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";
import {VendingMachine} from "../system/VendingMachine.sol";
import {Deposit} from "../deposit/Deposit.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";

/// @notice A one-click script for redeeming TBTC into BTC.
/// @dev Wrapper script for VendingMachine.tbtcToBtc
/// This contract implements receiveApproval() and can therefore use
/// approveAndCall(). This pattern combines TBTC Token approval and
/// vendingMachine.tbtcToBtc() in a single transaction.
contract RedemptionScript is ITokenRecipient {
    using BytesLib for bytes;

    TBTCToken tbtcToken;
    VendingMachine vendingMachine;
    FeeRebateToken feeRebateToken;

    constructor(
        address _VendingMachine,
        address _TBTCToken,
        address _FeeRebateToken
    ) public {
        vendingMachine = VendingMachine(_VendingMachine);
        tbtcToken = TBTCToken(_TBTCToken);
        feeRebateToken = FeeRebateToken(_FeeRebateToken);
    }

    /// @notice Receives approval for a TBTC transfer, and calls `VendingMachine.tbtcToBtc` for a user.
    /// @dev Implements the approveAndCall receiver interface.
    /// @param _from The owner of the token who approved them for transfer.
    /// @param _amount Approved TBTC amount for the transfer.
    /// @param _extraData Encoded function call to `VendingMachine.tbtcToBtc`.
    function receiveApproval(
        address _from,
        uint256 _amount,
        address,
        bytes memory _extraData
    ) public { // not external to allow bytes memory parameters
        require(msg.sender == address(tbtcToken), "Only token contract can call receiveApproval");

        tbtcToken.transferFrom(_from, address(this), _amount);
        tbtcToken.approve(address(vendingMachine), _amount);

        // Verify _extraData is a call to tbtcToBtc.
        bytes4 functionSignature;
        assembly {
            functionSignature := and(mload(add(_extraData, 0x20)), not(0xff))
        }
        require(
            functionSignature == vendingMachine.tbtcToBtc.selector,
            "Bad _extraData signature. Call must be to tbtcToBtc."
        );

        // We capture the `returnData` in order to forward any nested revert message
        // from the contract call.
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) = address(vendingMachine).call(_extraData);

        string memory revertMessage;
        assembly {
            // A revert message is ABI-encoded as a call to Error(string).
            // Slicing the Error() signature (4 bytes) and Data offset (4 bytes)
            // leaves us with a pre-encoded string.
            // We also slice off the ABI-coded length of returnData (32).
            revertMessage := add(returnData, 0x44)
        }

        require(success, revertMessage);
    }
}
