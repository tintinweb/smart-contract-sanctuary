pragma solidity ^0.5.16;

import "./CCollateralCapErc20.sol";

/**
 * @title Cream's CCollateralCapErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Cream
 */
contract CCollateralCapErc20Delegate is CCollateralCapErc20 {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");

        // Set internal cash when becoming implementation
        internalCash = getCashOnChain();

        // Set CToken version in comptroller
        ComptrollerInterfaceExtension(address(comptroller)).updateCTokenVersion(address(this), ComptrollerV2Storage.Version.COLLATERALCAP);
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}