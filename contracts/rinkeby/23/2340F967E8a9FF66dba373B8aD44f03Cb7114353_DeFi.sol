// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract DeFi {
    // Constants
    uint8 HASH_LENGTH = 64;

    // Will DataStructure
    struct Will {
        string dataHash;
        string ownerICNumber;
        address owner;
    }

    Will[] public wills;

    mapping(string => uint256) public HashToWillID;
    mapping(string => bool) public HashExists;

    //Events
    event WillAdded(
        uint256 willID,
        string dataHash,
        string ownerICNumber,
        address owner
    );
    event WillHashUpdated(
        uint256 willID,
        string oldDataHash,
        string newDataHash,
        string ownerICNumber,
        address owner
    );

    function addWill(string memory _dataHash, string memory _ownerICNumber)
        external
    {
        require(bytes(_dataHash).length == HASH_LENGTH, "Invalid Data Hash.");
        require(bytes(_ownerICNumber).length > 0, "IC Number is required.");
        require(HashExists[_dataHash] == false, "Data hash already in the state.");
        _addWill(_dataHash, _ownerICNumber, msg.sender);
    }

    function UpdateWillHash(uint256 _willID, string memory _newHash) public {
        require(isWillOwner(_willID, msg.sender), "Unauthorized Operation!");
        require(HashExists[_newHash] == false, "Data hash already in the state.");
        _updateWillHash(_willID, _newHash);
    }

    function _addWill(
        string memory _dataHash,
        string memory _ownerICNumber,
        address _owner
    ) private {
        wills.push(Will(_dataHash, _ownerICNumber, _owner));
        uint256 willID = wills.length - 1;
        HashToWillID[_dataHash] = willID;
        HashExists[_dataHash] = true;
        emit WillAdded(willID, _dataHash, _ownerICNumber, _owner);
    }

    function _updateWillHash(uint256 _willID, string memory _newHash) private {
        string memory currentHash = wills[_willID].dataHash;
        wills[_willID].dataHash = _newHash;
        HashToWillID[_newHash] = _willID;
        HashExists[_newHash] = true;
        delete HashToWillID[currentHash];
        emit WillHashUpdated(
            _willID,
            currentHash,
            _newHash,
            wills[_willID].ownerICNumber,
            wills[_willID].owner
        );
    }

    function isWillOwner(uint256 _willID, address _owner)
        private
        view
        returns (bool)
    {
        return wills[_willID].owner == _owner;
    }
}