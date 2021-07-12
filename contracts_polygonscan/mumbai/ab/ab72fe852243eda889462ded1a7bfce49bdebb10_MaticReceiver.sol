/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.6.12;

/**
* @notice Dummy State Sender contract to simulate plasma state sender while testing
*/
contract MaticReceiver {
    event Synced(address indexed _sender, bytes _data);
    
    /// @dev Receive data on Matic
    function onStateReceive(bytes calldata _data) external {
        emit Synced(msg.sender, _data);
    }
}