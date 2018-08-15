pragma solidity ^0.4.23;

contract DDM1 {
    event Publish(
        address indexed _from,
        bytes32 _hash_start,
        bytes32 _hash_end,
        bytes1 _ptype
    );

    function publishMetaData(bytes32 _hash_start,bytes32 _hash_end,bytes1 _ptype) public {
        emit Publish(msg.sender, _hash_start, _hash_end, _ptype);
    }
}