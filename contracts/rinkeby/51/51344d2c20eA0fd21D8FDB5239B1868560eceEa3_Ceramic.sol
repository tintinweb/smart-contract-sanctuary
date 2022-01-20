// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";

/**
 * @title Ceramic contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract Ceramic is ERC721Burnable {
    using SafeMath for uint256;

    uint256 public mintPrice;
    uint256 public maxToMint;
    uint256 public maxToMintInPrivateSale;
    uint256 public MAX_CERAMIC_SUPPLY;

    bool public saleIsActive;
    bool public privateSaleIsActive;

    mapping(bytes32 => bool) public digestUsed;
    string public constant CONTRACT_NAME = "Ceramic Contract";

    address private constant wallet =
        0xa1E40541060FB96Aa63E27DfD327b384c3a1CDe3;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address user,uint256 num,uint256 deadline)");

    event PrivateMint(address user, uint256 num);

    constructor() ERC721("Royal Ceramic Club", "RCCT") {
        MAX_CERAMIC_SUPPLY = 5000;
        mintPrice = 0 ether;
        maxToMint = 10;
        saleIsActive = false;
        maxToMintInPrivateSale = 3;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set price to mint a Ceramic.
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMaxToMint(uint256 _maxValue) external onlyOwner {
        maxToMint = _maxValue;
    }

    /**
     * Set maximum count to mint per once in private sale.
     */
    function setMaxToMintInPrivateSale(uint256 _maxValue) external onlyOwner {
        maxToMintInPrivateSale = _maxValue;
    }

    /**
     * Mint Ceramics by owner
     */
    function reserveCeramics(address _to, uint256 _numberOfTokens)
        external
        onlyOwner
    {
        require(_to != address(0), "Invalid address to reserve.");

        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(_to, totalSupply());
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrivateSaleState() external onlyOwner {
        privateSaleIsActive = !privateSaleIsActive;
    }

    /**
     * Mints Ceramics in public sale
     */
    function mintCeramics(uint256 _numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            _numberOfTokens <= maxToMint,
            "Invalid amount to mint per once"
        );
        require(
            totalSupply().add(_numberOfTokens) <= MAX_CERAMIC_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            mintPrice.mul(_numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * Mints Ceramics in private sale
     */
    function mintCeramicsInPrivateSale(
        address user,
        uint256 num,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(privateSaleIsActive, "Privte sale is not active.");
        require(msg.sender == user, "Invalid user.");
        require(block.timestamp <= deadline, "Passed deadline.");
        require(
            num <= maxToMintInPrivateSale,
            "Invalid amount to mint per once"
        );
        require(
            totalSupply().add(num) <= MAX_CERAMIC_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            mintPrice.mul(num) <= msg.value,
            "Ether value sent is not correct"
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(MINT_TYPEHASH, user, num, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(!digestUsed[digest], "Already used");
        require(signatory == owner(), "Invalid signatory");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, totalSupply());
        }

        digestUsed[digest] = true;

        emit PrivateMint(user, num);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(wallet).transfer(balance);
    }
}