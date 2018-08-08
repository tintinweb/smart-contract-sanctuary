pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Fileproof is Ownable {

    struct File {
        string user;
        uint timestamp;
        string hash;
        string fileUrl;
    }

    mapping (uint => File) public files;


    constructor() public { }

    function addFile(uint _id, string user, uint timestamp, string hash, string fileUrl) external onlyOwner {
        files[_id] = File({
            user: user,
            timestamp: timestamp,
            hash: hash,
            fileUrl: fileUrl
            });
    }

    function getFile(uint _id) public view returns(string, uint, string, string) {
        return (files[_id].user, files[_id].timestamp, files[_id].hash, files[_id].fileUrl);
    }


}