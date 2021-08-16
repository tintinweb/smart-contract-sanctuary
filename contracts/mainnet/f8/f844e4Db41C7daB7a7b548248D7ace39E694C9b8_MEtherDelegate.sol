pragma solidity 0.5.17;

import "./MEther.sol";

/**
 * @title Moma's MEtherDelegate Contract
 * @notice Ether MToken is delegated to
 * @author Moma
 */
contract MEtherDelegate is MEther, MDelegateInterface {
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