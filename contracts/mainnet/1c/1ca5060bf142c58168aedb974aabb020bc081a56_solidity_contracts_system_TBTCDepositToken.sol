pragma solidity 0.5.17;

import {ERC721Metadata} from "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import {DepositFactoryAuthority} from "./DepositFactoryAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title tBTC Deposit Token for tracking deposit ownership
/// @notice The tBTC Deposit Token, commonly referenced as the TDT, is an
///         ERC721 non-fungible token whose ownership reflects the ownership
///         of its corresponding deposit. Each deposit has one TDT, and vice
///         versa. Owning a TDT is equivalent to owning its corresponding
///         deposit. TDTs can be transferred freely. tBTC's VendingMachine
///         contract takes ownership of TDTs and in exchange returns fungible
///         TBTC tokens whose value is backed 1-to-1 by the corresponding
///         deposit's BTC.
/// @dev Currently, TDTs are minted using the uint256 casting of the
///      corresponding deposit contract's address. That is, the TDT's id is
///      convertible to the deposit's address and vice versa. TDTs are minted
///      automatically by the factory during each deposit's initialization. See
///      DepositFactory.createNewDeposit() for more info on how the TDT is minted.
contract TBTCDepositToken is ERC721Metadata, DepositFactoryAuthority {

    constructor(address _depositFactoryAddress)
        ERC721Metadata("tBTC Deposit Token", "TDT")
    public {
        initialize(_depositFactoryAddress);
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token
    /// @param _tokenId uint256 ID of the token to be minted
    function mint(address _to, uint256 _tokenId) external onlyFactory {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /// @notice           Allow another address to spend on the caller's behalf.
    ///                   Set allowance for other address and notify.
    ///                   Allows `_spender` to transfer the specified TDT
    ///                   on your behalf and then ping the contract about it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface below to receive approval notifications.
    /// @param _spender   `ITokenRecipient`-conforming contract authorized to
    ///        operate on the approved token.
    /// @param _tdtId     The TDT they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(
        ITokenRecipient _spender,
        uint256 _tdtId,
        bytes memory _extraData
    ) public returns (bool) { // not external to allow bytes memory parameters
        approve(address(_spender), _tdtId);
        _spender.receiveApproval(msg.sender, _tdtId, address(this), _extraData);
        return true;
    }
}
