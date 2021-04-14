// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
import "./ScaleBuying.sol";
import "./InitialLiquidityOffering.sol";
import "./DelegateOwnershipManager.sol";
import "./AbqErc20.sol";

/// @notice Contract used to ratify the ICO and ILO for the ABQ token.
contract SaleRatification
{
    /// @notice Ratify the ICO and ILO for the ABQ token.
    /// @param _ilo The intended Initial Liquidity Offering (ILO) to use.
    /// @param _ico The intended Initial Coin Offering (ICO) to use.
    /// @param _treasury The Aardbanq DAO treasury that bounty tokens will be minted for.
    /// @param _ownershipManager The delegate manager for the ownership and minting permissions for the ABQ token.
    /// @param _token The ABQ token.
    function ratify(InitialLiquidityOffering _ilo, ScaleBuying _ico, address _treasury, DelegateOwnershipManager _ownershipManager, AbqErc20 _token)
        external
    {
        // CG: set the pricer for the ILO as the ICO and the liquidity establisher for the ICO as the ILO
        _ilo.setPricer(_ico);
        _ico.setLiquidityEstablisher(_ilo);

        // CG: Give ownership of the token to the DelegateOwnershipManager and give mint permission to the ICO and ILO.
        _token.changeOwner(address(_ownershipManager));
        _ownershipManager.setMintPermission(address(_ilo), true);
        _ownershipManager.setMintPermission(address(_ico), true);

        _ownershipManager.mint(address(_ico), 11585 ether); // CG: Auction tokens
        _ownershipManager.mint(address(_treasury), 50000 ether);    // CG: Bounty tokens
    }
}