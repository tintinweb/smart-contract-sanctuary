// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

contract NftPool is Ownable {
    string public constant CONTRACT_NAME = "NftPool";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PUT_NFT_TYPEHASH =
        keccak256("PutNft(address tokenAddress,uint256 tokenId)");
    bytes32 public constant WITHDRAW_NFT_TYPEHASH =
        keccak256(
            "WithdrawNft(address tokenAddress,uint256 tokenId,address owner)"
        );
    bytes32 public constant BUY_NFT_TYPEHASH =
        keccak256("BuyNft(address tokenAddress,uint256 tokenId,address owner)");

    IERC20 public paymentToken;
    mapping(address => mapping(uint256 => address)) nftInfo;

    address public admin = 0xa1E40541060FB96Aa63E27DfD327b384c3a1CDe3;

    event PuntNft(address tokenAddress, uint256 tokenId, address user);
    event WithdrawNft(address tokenAddress, uint256 tokenId, address user);
    event BuyNft(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 amount
    );

    constructor() {}

    function setBatt(IERC20 _paymentToken) external onlyOwner {
        paymentToken = _paymentToken;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function PutNft(
        address tokenAddress,
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(tx.origin == msg.sender, "Only EOA");
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(PUT_NFT_TYPEHASH, tokenAddress, tokenId)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        require(
            IERC721(tokenAddress).ownerOf(tokenId) == msg.sender,
            "This NFT does not belong to address"
        );

        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        nftInfo[tokenAddress][tokenId] = msg.sender;

        emit PuntNft(tokenAddress, tokenId, msg.sender);
    }

    function withdrawNft(
        address tokenAddress,
        uint256 tokenId,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(WITHDRAW_NFT_TYPEHASH, tokenAddress, tokenId, owner)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        require(nftInfo[tokenAddress][tokenId] == msg.sender, "Invalid owner");

        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        nftInfo[tokenAddress][tokenId] = address(0);

        emit WithdrawNft(tokenAddress, tokenId, msg.sender);
    }

    function buyNft(
        address tokenAddress,
        uint256 tokenId,
        address owner,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(BUY_NFT_TYPEHASH, tokenAddress, tokenId, owner)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint256 allowance = IERC20(paymentToken).allowance(
            msg.sender,
            address(this)
        );
        
        require(amount > 0, "Invalid amount");
        require(allowance >= amount, "Not approved");
        IERC20(paymentToken).transferFrom(msg.sender, owner, amount);

        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        nftInfo[tokenAddress][tokenId] = address(0);
        
        emit BuyNft(tokenAddress, tokenId, msg.sender, amount);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}