/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// File: contracts/root/StateSender/IStateSender.sol

pragma solidity 0.6.6;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

// File: contracts/root/StateSender/DummyStateSender.sol

pragma solidity 0.6.6;


/**
* @notice Dummy State Sender contract to simulate plasma state sender while testing
*/
contract DummyStateSender is IStateSender {
    /**
     * @notice Event emitted when when syncState is called
     * @dev Heimdall bridge listens to this event and sends the data to receiver contract on child chain
     * @param id Id of the sync, increamented for each event in case of actual state sender contract
     * @param contractAddress the contract receiving data on child chain
     * @param data bytes data to be sent
     */
    event StateSynced(
        uint256 indexed id,
        address indexed contractAddress,
        bytes data
    );

    /**
     * @notice called to send data to child chain
     * @dev sender and receiver contracts need to be registered in case of actual state sender contract
     * @param receiver the contract receiving data on child chain
     * @param data bytes data to be sent
     */
    function syncState(address receiver, bytes calldata data) external override {
        emit StateSynced(1, receiver, data);
    }
}