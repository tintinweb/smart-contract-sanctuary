// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

/// @title Central logger contract
/// @notice Log collector with only 1 purpose - to emit the event. Can be called from any contract
/** @dev Use like this:
*
* bytes32 internal constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
* address centralLoggerAddress = Registry(registry).getAddress(CENTRAL_LOGGER_ID);
* CentralLogger internal constant logger = CentralLogger(centralLoggerAddress);
*
* Or directly:
*   CentralLogger internal constant logger = CentralLogger(0xDEPLOYEDADDRESS);
*
* logger.log(
*            address(this),
*            msg.sender,
*            "openCreditLine",
*            abi.encode(msg.value, param1, param2)
*        );
*
* DO NOT USE delegateCall as it defies the centralisation purpose of this logger.
*/
contract CentralLogger {

	/// @notice Contracts' registry address
	address private immutable registry;

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

	/* solhint-disable-next-line func-visibility */
	constructor(address _registry) {
		registry = _registry;
	}

    /// @notice Log the event centraly
    /// @dev For gas impact see https://www.evm.codes/#a3
    /// @param _logName length must be less than 32 bytes
    function log(
        address _contract,
        address _caller,
        string memory _logName,
        bytes memory _data
    ) public {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}