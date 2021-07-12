/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.6.12;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

interface IStateReceiver {
    function onStateReceive(uint256 stateId, bytes calldata data) external;
}


/**
* @notice Dummy State Sender contract to simulate plasma state sender while testing
*/
contract DCLStateSender {
    /// @dev Matic's Ethereum predicate
    address public predicate;


    /// @dev Event emitted on Matic to send data to Ethereum
    event Data(address indexed from, bytes bytes_data);


    constructor(address _predicate) public{
        predicate = _predicate;
    }

    /// @dev Send data to Matic
    function syncOnMatic(IStateSender _stateSender, address _receiver, bytes calldata _data) external {
       _stateSender.syncState(_receiver, _data);
    }

    /// @dev Receive data on Matic
    function onStateReceive(uint256, bytes calldata _data) external {
        (address _dest, bytes memory data) = abi.decode(_data, (address, bytes));

        (bool success,) = _dest.call(data);

        if (!success) {
            revert("Failed");
        }
    }


    /// @dev Receive data on Ethereum or Send data to Ethereum
    function setData(bytes calldata _data) external {
        if (msg.sender == predicate) {
            (address _dest, bytes memory data) = abi.decode(_data, (address, bytes));

            (bool success,) = _dest.call(data);
            
            if (!success) {
                revert("Failed");
            }
        } else {
            emit Data(msg.sender, _data);
        }
    }
}