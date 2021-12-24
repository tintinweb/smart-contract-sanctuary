/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity ^0.5.0;

contract Storage {
    struct File {
        string ipfsHash;
        string mime;
        string name;
        uint256 uploadedAt;
        uint32 downloads;
    }

    mapping (address => mapping (string => File)) ownerToFiles;

    event FileUploaded(address indexed owner, string ipfsHash, string mime, string name, uint256 uploadedAt);

    event EmergencyStop(address indexed owner);

    function uploadFile(string memory uuid, string memory ipfsHash, string memory mime, string memory name)
    public returns (bool success) {
        require(bytes(ipfsHash).length == 46);
        require(bytes(mime).length > 0 && bytes(mime).length < 256);
        require(bytes(name).length > 0 && bytes(name).length < 256);

        uint256 uploadedAt = now;
        File memory file = File(ipfsHash, mime, name, uploadedAt, 0);

        ownerToFiles[msg.sender][uuid] = file;

        emit FileUploaded(msg.sender, ipfsHash, mime, name, uploadedAt);

        success = true;
    }

    function getFile(address owner, string memory uuid)
    public view returns (
        string memory ipfsHash,
        string memory mime,
        string memory name,
        uint256 uploadedAt,
        uint32 downloads
    ) {
        File storage file = ownerToFiles[owner][uuid];

        return (file.ipfsHash, file.mime, file.name, file.uploadedAt, file.downloads);
    }

    function incrementDownloads(address owner, string memory uuid)
    public {
        ownerToFiles[owner][uuid].downloads++;
    }
}