pragma solidity ^0.8.0;

contract Storage {
    struct File {
        string ipfsHash;
        string mime;
        string name;
        uint256 uploadedAt;
        uint32 likes;
    }

    mapping (address => mapping (string => File)) ownerToFiles;

    event FileUploaded(address indexed owner, string ipfsHash, string mime, string name, uint256 uploadedAt);

    function uploadFile(string memory uuid, string memory ipfsHash, string memory mime, string memory name)
    public {
        require(bytes(ipfsHash).length == 46);
        require(bytes(mime).length > 0 && bytes(mime).length < 256);
        require(bytes(name).length > 0 && bytes(name).length < 256);

        uint256 uploadedAt = block.timestamp;
        File memory file = File(ipfsHash, mime, name, uploadedAt, 0);

        ownerToFiles[msg.sender][uuid] = file;

        emit FileUploaded(msg.sender, ipfsHash, mime, name, uploadedAt);
    }

    function getFile(address owner, string memory uuid)
    public view returns (
        string memory ipfsHash,
        string memory mime,
        string memory name,
        uint256 uploadedAt,
        uint32 likes
    ) {
        File storage file = ownerToFiles[owner][uuid];

        return (file.ipfsHash, file.mime, file.name, file.uploadedAt, file.likes);
    }

    function like(address owner, string memory uuid)
    public {
        ownerToFiles[owner][uuid].likes++;
    }
}