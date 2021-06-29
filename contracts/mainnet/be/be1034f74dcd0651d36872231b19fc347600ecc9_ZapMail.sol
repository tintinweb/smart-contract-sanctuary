/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity 0.8.6;

contract ZapMail {
    mapping(bytes32 => bool) usernameHashExists;

    event UserRegistered(bytes32 indexed usernameHash, address indexed addr, string username, string publicKey);
    event EmailSent(address indexed from, address indexed to, string mailHash);
    event ContactsUpdated(bytes32 indexed usernameHash, string fileHash);

    function registerUser(
        bytes32 usernameHash,
        string calldata username,
        string calldata publicKey
    ) public {
        require(usernameHashExists[usernameHash] == false, 'User already exists');
        usernameHashExists[usernameHash] = true;
        emit UserRegistered(usernameHash, msg.sender, username, publicKey);
    }

    function sendEmail(address[] calldata recipients, string calldata mailHash) public {
        for (uint256 i = 0; i < recipients.length; ++i) {
            emit EmailSent(tx.origin, recipients[i], mailHash);
        }
    }

    function updateContacts(bytes32 usernameHash, string calldata fileHash) public {
        emit ContactsUpdated(usernameHash, fileHash);
    }
}