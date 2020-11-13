pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "./VendingMachineAuthority.sol";

/// @title  Fee Rebate Token
/// @notice The Fee Rebate Token (FRT) is a non fungible token (ERC721)
///         the ID of which corresponds to a given deposit address.
///         If the corresponding deposit is still active, ownership of this token
///         could result in reimbursement of the signer fee paid to open the deposit.
/// @dev    This token is minted automatically when a TDT (`TBTCDepositToken`)
///         is exchanged for TBTC (`TBTCToken`) via the Vending Machine (`VendingMachine`).
///         When the Deposit is redeemed, the TDT holder will be reimbursed
///         the signer fee if the redeemer is not the TDT holder and Deposit is not
///         at-term or in COURTESY_CALL.
contract FeeRebateToken is ERC721Metadata, VendingMachineAuthority {

    constructor(address _vendingMachine)
        ERC721Metadata("tBTC Fee Rebate Token", "FRT")
        VendingMachineAuthority(_vendingMachine)
    public {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token.
    /// @param _tokenId uint256 ID of the token to be minted.
    function mint(address _to, uint256 _tokenId) external onlyVendingMachine {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }
}
