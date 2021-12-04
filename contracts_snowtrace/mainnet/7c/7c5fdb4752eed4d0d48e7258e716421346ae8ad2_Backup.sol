/**
 *Submitted for verification at snowtrace.io on 2021-12-04
*/

pragma solidity 0.8.10;

contract Backup {
    mapping(address => bytes) public backups;

    function backup(bytes calldata ciphertext) external {
        backups[msg.sender] = ciphertext;
    }
}