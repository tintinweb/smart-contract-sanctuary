// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./InitializableUpgradeabilityProxy.sol";
import "./BaseAdminUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract OwnedUpgradeabilityProxy is
    BaseAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    /**
     * Contract constructor.
     * @param _logic address of the initial implementation.
     * @param _admin Address of the proxy administrator.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */

    function initialize(
        address _logic,
        address _admin,
        bytes memory _data
    ) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(_logic, _data);
        _setAdmin(_admin);
        emit Initialized(_admin, _logic);
    }

    event Initialized(address admin, address _logic);

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    // prettier-ignore
    function _willFallback() override internal {
        require(
          _admin() != address(0),
          "Can't fallback if admin is not set"
        );
        require(
            msg.sender != _admin(),
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}
