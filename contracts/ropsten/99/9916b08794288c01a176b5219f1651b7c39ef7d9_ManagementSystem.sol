/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity >=0.7.0 < 0.9.0;


contract ManagementSystem   {

    struct dataHash{
        bytes32 hash;
        address[] dataRequesters;
        bool isExist;
    }

    address public dataOwner;
    address[] public dataRequesters;
    mapping(bytes32 => dataHash) public dataHashes;
    
    event FileAdded(bytes32 hash, address uploader);

    error fileAlreadyExists(bytes32 hash, address uploader);

    constructor()   {
        dataOwner = msg.sender;
    }

    function addFileHash(bytes32 hash) public {
        require(msg.sender == dataOwner);

        if (dataHashes[hash].isExist)
            revert fileAlreadyExists({
                hash: hash,
                uploader: dataOwner
            });

        dataHashes[hash].hash = hash;
        dataHashes[hash].isExist = true;

        emit FileAdded(hash, dataOwner);
    }
}