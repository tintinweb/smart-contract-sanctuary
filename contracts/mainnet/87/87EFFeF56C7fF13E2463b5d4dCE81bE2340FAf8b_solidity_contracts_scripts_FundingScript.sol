pragma solidity 0.5.17;

import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";
import {TBTCDepositToken} from "../system/TBTCDepositToken.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";
import {VendingMachine} from "../system/VendingMachine.sol";

/// @notice A one-click script for minting TBTC from an unqualified TDT.
/// @dev Wrapper script for VendingMachine.unqualifiedDepositToTbtc
/// This contract implements receiveApproval() and can therefore use
/// approveAndCall(). This pattern combines TBTC Token approval and
/// vendingMachine.unqualifiedDepositToTbtc() in a single transaction.
contract FundingScript is ITokenRecipient {
    TBTCToken tbtcToken;
    VendingMachine vendingMachine;
    TBTCDepositToken tbtcDepositToken;
    FeeRebateToken feeRebateToken;

    constructor(
        address _VendingMachine,
        address _TBTCToken,
        address _TBTCDepositToken,
        address _FeeRebateToken
    ) public {
        vendingMachine = VendingMachine(_VendingMachine);
        tbtcToken = TBTCToken(_TBTCToken);
        tbtcDepositToken = TBTCDepositToken(_TBTCDepositToken);
        feeRebateToken = FeeRebateToken(_FeeRebateToken);
    }

    /// @notice Receives approval for a TDT transfer, and calls `VendingMachine.unqualifiedDepositToTbtc` for a user.
    /// @dev Implements the approveAndCall receiver interface.
    /// @param _from The owner of the token who approved them for transfer.
    /// @param _tokenId Approved TDT for the transfer.
    /// @param _extraData Encoded function call to `VendingMachine.unqualifiedDepositToTbtc`.
    function receiveApproval(
        address _from,
        uint256 _tokenId,
        address,
        bytes memory _extraData
    ) public { // not external to allow bytes memory parameters
        require(msg.sender == address(tbtcDepositToken), "Only token contract can call receiveApproval");

        tbtcDepositToken.transferFrom(_from, address(this), _tokenId);
        tbtcDepositToken.approve(address(vendingMachine), _tokenId);

        // Verify _extraData is a call to unqualifiedDepositToTbtc.
        bytes4 functionSignature;
        assembly {
            functionSignature := and(mload(add(_extraData, 0x20)), not(0xff))
        }
        require(
            functionSignature == vendingMachine.unqualifiedDepositToTbtc.selector,
            "Bad _extraData signature. Call must be to unqualifiedDepositToTbtc."
        );

        // Call the VendingMachine.
        // We could explictly encode the call to vending machine, but this would
        // involve manually parsing _extraData and allocating variables.
        // We capture the `returnData` in order to forward any nested revert message
        // from the contract call.
        /* solium-disable-next-line security/no-low-level-calls */
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

        // Transfer the TBTC and feeRebateToken to the user.
        tbtcToken.transfer(_from, tbtcToken.balanceOf(address(this)));
        feeRebateToken.transferFrom(address(this), _from, uint256(_tokenId));
    }
}
