pragma solidity 0.5.17;

/// @title Interface of recipient contract for `approveAndCall` pattern.
///        Implementors will be able to be used in an `approveAndCall`
///        interaction with a supporting contract, such that a token approval
///        can call the contract acting on that approval in a single
///        transaction.
///
///        See the `FundingScript` and `RedemptionScript` contracts as examples.
interface ITokenRecipient {
    /// Typically called from a token contract's `approveAndCall` method, this
    /// method will receive the original owner of the token (`_from`), the
    /// transferred `_value` (in the case of an ERC721, the token id), the token
    /// address (`_token`), and a blob of `_extraData` that is informally
    /// specified by the implementor of this method as a way to communicate
    /// additional parameters.
    ///
    /// Token calls to `receiveApproval` should revert if `receiveApproval`
    /// reverts, and reverts should remove the approval.
    ///
    /// @param _from The original owner of the token approved for transfer.
    /// @param _value For an ERC20, the amount approved for transfer; for an
    ///        ERC721, the id of the token approved for transfer.
    /// @param _token The address of the contract for the token whose transfer
    ///        was approved.
    /// @param _extraData An additional data blob forwarded unmodified through
    ///        `approveAndCall`, used to allow the token owner to pass
    ///         additional parameters and data to this method. The structure of
    ///         the extra data is informally specified by the implementor of
    ///         this interface.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}
