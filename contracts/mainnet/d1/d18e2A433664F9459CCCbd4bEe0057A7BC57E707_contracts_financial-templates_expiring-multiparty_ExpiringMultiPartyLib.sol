pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ExpiringMultiParty.sol";


/**
 * @title Provides convenient Expiring Multi Party contract utilities.
 * @dev Using this library to deploy EMP's allows calling contracts to avoid importing the full EMP bytecode.
 */
library ExpiringMultiPartyLib {
    /**
     * @notice Returns address of new EMP deployed with given `params` configuration.
     * @dev Caller will need to register new EMP with the Registry to begin requesting prices. Caller is also
     * responsible for enforcing constraints on `params`.
     * @param params is a `ConstructorParams` object from ExpiringMultiParty.
     * @return address of the deployed ExpiringMultiParty contract
     */
    function deploy(ExpiringMultiParty.ConstructorParams memory params) public returns (address) {
        ExpiringMultiParty derivative = new ExpiringMultiParty(params);
        return address(derivative);
    }
}
