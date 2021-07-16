/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEPIKNFT {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable; 
}

contract TransferManager {

    address public admin;
    address public signer;
    address public epikOwner;
    address payable public vaultWallet;

    uint private _transferFee;
    string private _signPrefix;

    mapping(address => uint256) public nonces;

    IEPIKNFT public EPIKNFT;

    event TransferNFT(string orderId, address indexed user, uint256 tokenId);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "Not signer");
        _;
    }

    constructor(address _signer, address _EPIKNFT, address _epikOwner, address payable _vaultWallet) {
        admin = msg.sender;
        signer = _signer;
        EPIKNFT = IEPIKNFT(_EPIKNFT);
        epikOwner = _epikOwner;
        vaultWallet = _vaultWallet;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }

    function setSignerAddress(address _signer) public onlyAdmin {
        require(_signer != address(0), "Invalid signer address");
        
        signer = _signer;
    }

    function setEpikOwnerAddress(address _epikOwner) public onlyAdmin {
        require(_epikOwner != address(0), "Invalid epik owner address");
        
        epikOwner = _epikOwner;
    }
    
    function setNFTAddress(address _EPIKNFT) external onlyAdmin {
        EPIKNFT = IEPIKNFT(_EPIKNFT);
    }

    function setVaultAddress(address payable _vaultWallet) public onlyAdmin {
        require(_vaultWallet != address(0), "Invalid vault address");
        
        vaultWallet = _vaultWallet;
    }

    function setTransferFee() external payable onlyAdmin {
        _transferFee = msg.value;
    }

    function getTransferFee() public view returns(uint) {
        return _transferFee;
    }

    function setSignPrefix(string memory _prefix) external onlyAdmin {
        _signPrefix = _prefix;
    }

    function getSignPrefix() public view returns(string memory) {
        return _signPrefix;
    }

    function getMessageHash(address _to, uint256 _userId, uint256 _tokenId, uint256 _nonce)
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _userId, _tokenId, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public view returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked(_signPrefix, _messageHash));
    }

    function verify(
        address _to, uint256 _userId, uint256 _tokenId, uint256 _nonce,
        bytes memory signature
    )
        public view returns (bool)
    {
        bytes32 messageHash = getMessageHash(_to, _userId, _tokenId, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function transferItem(
        address _to, uint256 _userId, uint256 _tokenId, uint256 _nonce,
        bytes memory signature, string memory _orderId
    )
        public payable
    {
        if (_transferFee > 0) {
            require(msg.value == _transferFee, 'fee is not correct');
        }

        require(_nonce > 0 , 'Invalid nonce number');
        require(nonces[signer] < _nonce , 'Nonce is ready use');
        require(verify(_to, _userId, _tokenId, _nonce, signature) == true, "Verify failed");
        
        nonces[signer] = _nonce;
        IEPIKNFT(address(EPIKNFT)).transferFrom(epikOwner, _to, _tokenId);

        vaultWallet.transfer(msg.value);

        emit TransferNFT(_orderId, _to, _tokenId);
    }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}