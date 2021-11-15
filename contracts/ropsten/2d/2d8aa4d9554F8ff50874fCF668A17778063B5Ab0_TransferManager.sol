// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract TransferManager {

    address public admin;
    address public signer;
    address payable public vaultWallet;
    string public salt = "\x19Ethereum Signed Message:\n32";

    uint private _transferFee;

    mapping(address => uint256) public nonces;

    IERC721 public EPIKNFT;

    event WithdrawItem(address indexed sender, address indexed receiver, uint256 indexed tokenId, string userId, uint nonce);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "Not signer");
        _;
    }

    constructor(address _signer, address _EPIKNFT, address payable _vaultWallet) {
        admin = msg.sender;
        signer = _signer;
        EPIKNFT = IERC721(_EPIKNFT);
        vaultWallet = _vaultWallet;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }
    
    function setSalt(string memory _salt) external onlyAdmin {
        salt = _salt;
    }

    function setSignerAddress(address _signer) public onlyAdmin {
        require(_signer != address(0), "Invalid address");
        
        signer = _signer;
    }

    function setNFTAddress(address _epikNFT) external onlyAdmin {
        EPIKNFT = IERC721(_epikNFT);
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

    function getMessageHash(address _from, address _to, string memory _userId, uint256 _tokenId, uint256 _nonce)
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_from, _to, _userId, _tokenId, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public view returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked(salt, _messageHash));
    }

    function verify(address _from, address _to, string memory _userId, 
        uint256 _tokenId, uint256 _nonce, bytes memory signature
    )
        public view returns (bool)
    {
        bytes32 messageHash = getMessageHash(_from, _to, _userId, _tokenId, _nonce);
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

    function transferItem(address _to, string memory _userId, uint256 _tokenId, uint256 _nonce, 
            bytes memory signature) public payable {
                
        require(_nonce > 0 , 'Invalid nonce number');
        require(nonces[msg.sender] < _nonce , 'Nonce is ready use');
        require(verify(msg.sender, _to, _userId, _tokenId, _nonce, signature) == true, "Invalid signature");

        require(msg.value == _transferFee, 'fee is not correct');

        nonces[msg.sender] = _nonce;
        EPIKNFT.transferFrom(signer, _to, _tokenId);

        if(msg.value > 0) vaultWallet.transfer(msg.value);

        emit WithdrawItem(msg.sender, _to, _tokenId, _userId, _nonce);
    }

}

