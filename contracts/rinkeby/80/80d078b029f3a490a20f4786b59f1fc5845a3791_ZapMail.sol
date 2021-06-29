/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity 0.8.6;

contract ZapMail {
    mapping(string => bool) usernameExists;

    event UserRegistered(address indexed addr, string username, string publicKey);
    event EmailSent(address indexed from, address indexed to, string mailHash);
    event ContactsUpdated(string indexed usernameHash, string fileHash);

    function registerUser(string calldata username, string calldata publicKey) public {
        require(usernameExists[username] == false, 'User already exists');
        usernameExists[username] = true;
        emit UserRegistered(msg.sender, username, publicKey);
    }

    function sendEmail(address[] calldata recipients, string calldata mailHash) public {
        for (uint256 i = 0; i < recipients.length; ++i) {
            emit EmailSent(tx.origin, recipients[i], mailHash);
        }
    }

    function updateContacts(string calldata username, string calldata fileHash) public {
        emit ContactsUpdated(username, fileHash);
    }
}