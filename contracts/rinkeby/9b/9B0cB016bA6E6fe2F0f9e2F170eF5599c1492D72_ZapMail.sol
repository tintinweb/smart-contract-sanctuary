/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity 0.8.4;

contract ZapMail {
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
        string mailHash,
        string threadHash,
        bytes32 indexed threadId
    );
    event ContactsUpdated(bytes32 indexed usernameHash, string fileHash);

    function registerUser(
        bytes32 usernameHash,
        string memory encryptedUsername,
        string memory publicKey
    ) public {
        require(usernameHashExists[usernameHash] == false);
        usernameHashExists[usernameHash] = true;
        emit UserRegistered(usernameHash, msg.sender, encryptedUsername, publicKey);
    }

    function sendEmail(
        address[] memory recipients,
        string memory mailHash,
        string memory threadHash,
        bytes32 threadId
    ) public {
        for (uint256 i = 0; i < recipients.length; ++i) {
            emit EmailSent(tx.origin, recipients[i], mailHash, threadHash, threadId);
        }
    }
}