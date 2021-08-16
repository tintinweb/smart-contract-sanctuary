pragma solidity 0.5.17;

import "./MErc20.sol";

/**
 * @title Moma's MErc20Delegate Contract
 * @notice MTokens which wrap an EIP-20 underlying and are delegated to
 * @author Moma
 */
contract MErc20Delegate is MErc20, MDelegateInterface {
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

        require(msg.sender == momaMaster.admin(), "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == momaMaster.admin(), "only the admin may call _resignImplementation");
    }
}