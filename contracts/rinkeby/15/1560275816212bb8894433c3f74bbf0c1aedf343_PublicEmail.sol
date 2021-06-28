/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity 0.8.6;

contract PublicEmail {
    mapping(bytes32 => bool) usernameHashExists;

    event UserRegistered(
        bytes32 indexed usernameHash,
        address indexed addr,
        string encryptedUsername,
        string publicKey
    );
    event EmailSent(
        address indexed from,
        address indexed to,
        string mailHash
    );
    event ContactsUpdated(bytes32 indexed usernameHash, string fileHash);

    function registerUser(
        bytes32 usernameHash,
        string calldata encryptedUsername,
        string calldata publicKey
    ) public {
        require(usernameHashExists[usernameHash] == false, 'User already exists');
        usernameHashExists[usernameHash] = true;
        emit UserRegistered(usernameHash, msg.sender, encryptedUsername, publicKey);
    }

    function sendEmail(
        address recipient,
        string calldata mailHash
    ) public {
        emit EmailSent(tx.origin, recipient, mailHash);
    }
}