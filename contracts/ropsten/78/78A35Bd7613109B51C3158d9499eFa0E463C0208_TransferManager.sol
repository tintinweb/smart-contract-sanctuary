/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferManager {

    address public admin;
    address public signer;

    // event BuyItems(string orderId, string buyerId, address buyer, string[] itemIds, uint256[] amounts);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "Not signer");
        _;
    }

    constructor(address _signer) {
        admin = msg.sender;
        signer = _signer;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }

    function setSignerAddress(address _signer) public onlyAdmin {
        require(_signer != address(0), "Invalid signer address");
        
        signer = _signer;
    }

    function getMessageHash(address _to, uint _userId, string memory _message, uint _nonce)
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _userId, _message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}

