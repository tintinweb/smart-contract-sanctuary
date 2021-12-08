// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IToken.sol';

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract BridgeBase {
    IToken public token;
    address public admin;
    mapping(address => mapping(uint => bool )) public processedNonces;
    enum Step { Burn, Mint}
    event Burn(uint tokenId, Step indexed step);
    event Mint(address owner, string tokenURI, string tokenMeta);
    
    constructor(address _token) {
        admin = msg.sender;
        token = IToken(_token);
    }
    
    modifier onlyAdmin () {
        require(msg.sender == admin, 'Access faild. Only Admin.');
        _;
    }

    function burn(address _owner, uint256 _tokenId) external onlyAdmin{
        token.bridgeBurn(_owner, _tokenId);
        emit Burn(_tokenId, Step.Burn);
    }
    
    function mint(address _owner, string memory _tokenURI, string memory _tokenMeta) external onlyAdmin{
        token.bridgeMint(_owner, _tokenURI, _tokenMeta);
        emit Mint(_owner, _tokenURI, _tokenMeta);
    }
    
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
    
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            
            s := mload(add(sig, 64))
            
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}