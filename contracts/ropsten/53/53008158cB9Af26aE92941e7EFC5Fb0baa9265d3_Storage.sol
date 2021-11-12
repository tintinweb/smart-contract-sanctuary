/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

contract Storage {
    struct File {
        uint256 fileId;
        string fileHash;
        uint256 fileSize;
        string fileType;
        string fileName;
        string fileDescription;
        uint256 uploadTime;
        address uploader;
    }

    File[] public files;

    uint256 public fileIndex = 0;

    event FileUploaded(
        uint256 fileId,
        string fileHash,
        uint256 fileSize,
        string fileType,
        string fileName,
        string fileDescription,
        uint256 uploadTime,
        address indexed uploader
    );

    event FileDeleted(
        uint256 fileId,
        uint256 deleteTime,
        address indexed deleter
    );

    event FileUpdated(
        uint256 fileId,
        string fileName,
        string fileDescription,
        uint256 updatedTime,
        address indexed updater
    );

    function uploadFile(
        string memory _fileHash,
        uint256 _fileSize,
        string memory _fileType,
        string memory _fileName,
        string memory _fileDescription
    ) external {
        require(bytes(_fileHash).length > 0);
        require(bytes(_fileType).length > 0);
        require(bytes(_fileDescription).length > 0);
        require(bytes(_fileName).length > 0);
        require(msg.sender != address(0));
        require(_fileSize > 0);

        fileIndex++;

        File memory newFile = File(
            fileIndex,
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            _fileDescription,
            block.timestamp,
            msg.sender
        );

        files.push(newFile);

        emit FileUploaded(
            fileIndex,
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            _fileDescription,
            block.timestamp,
            msg.sender
        );
    }

    function updateFile(uint256 _fileId, string memory _fileDescription)
        external
    {
        require(bytes(_fileDescription).length > 0);
        require(msg.sender != address(0));

        uint256 i = findFile(_fileId);

        if (files[i].uploader != msg.sender)
            revert("You can not update files that is not yours");

        files[i].fileDescription = _fileDescription;

        emit FileUpdated(
            _fileId,
            files[i].fileName,
            _fileDescription,
            block.timestamp,
            msg.sender
        );
    }

    function deleteFile(uint256 _fileId) external {
        require(msg.sender != address(0));

        uint256 i = findFile(_fileId);
        uint256 totalFileCount = files.length;

        if (files[i].uploader != msg.sender)
            revert("You can not delete files that is not yours");

        files[i] = files[totalFileCount - 1];
        delete files[totalFileCount - 1];
        files.pop();

        emit FileDeleted(_fileId, block.timestamp, msg.sender);
    }

    function getTotalFile() external view returns (uint256 length) {
        return files.length;
    }

    function fileExist(uint256 _fileId) external view returns (bool success) {
        for (uint256 i = 0; i < files.length; i++) {
            if (files[i].fileId == _fileId) {
                return true;
            }
        }

        return false;
    }

    function findFile(uint256 _fileId) internal view returns (uint256) {
        for (uint256 i = 0; i < files.length; i++) {
            if (files[i].fileId == _fileId) {
                return i;
            }
        }

        revert("This file does not exist");
    }
}