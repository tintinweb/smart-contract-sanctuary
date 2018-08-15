pragma solidity ^0.4.23;

contract DDM {
    event Publish(
        address indexed _from,
        bytes32 _data,
        bytes1 _ptype
    );

    function publishMetaData(bytes32 _data,bytes1 _ptype) public {
        emit Publish(msg.sender, _data, _ptype);
    }
}