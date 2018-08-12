pragma solidity ^0.4.23;

contract PublishMetaData {
    event Publish(
        address indexed _from,
        bytes32 _data
    );

    function publishMetaData(bytes32 _data) public {
        emit Publish(msg.sender, _data);
    }
}