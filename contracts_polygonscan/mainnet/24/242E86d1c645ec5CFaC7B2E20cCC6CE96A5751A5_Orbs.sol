// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//truffle-flatten'd from @openzeppelin/[email protected]
import "./OZFlattened.sol";
import "./Generator.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Orbs is ERC721Enumerable, Ownable{

    //Error codes, inspired from HTTP errors codes
    string constant TOKEN_ID_OUTOFRANGE = "400";
    string constant TOKEN_MINT_FORBIDDEN = "403";
    string constant TOKEN_NOTFOUND = "404";
    string constant TOKEN_ALREADY_BURNED = "409";

    // Mapping address to mint count
    mapping(address => uint256) private _mintCount;

    // Burned token tracker
    mapping(uint256 => bool) private _burnedToken;

    uint256 constant maxTokenId = 504;
    constructor() ERC721("Orbs OnChained", "ORBS") {

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) 
    {
        return interfaceId == 0x2a55205a || //ERC2981 NFT Royalty Standard
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view 
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), TOKEN_NOTFOUND);
        return (owner(), salePrice / 10);
    }

    /**
     * @dev mint a new Token.
     */
    function mintToken(
        address to,
        uint256 tokenId
    ) public virtual {
        require(msg.sender == owner() || _mintCount[msg.sender] < 3, TOKEN_MINT_FORBIDDEN);
        require(tokenId < maxTokenId, TOKEN_ID_OUTOFRANGE);
        require(!_burnedToken[tokenId], TOKEN_ALREADY_BURNED);
        _mintCount[msg.sender]++;
        _safeMint(to, tokenId, '');
    }

    /**
     * @dev mint a new Token to caller's address.
     */
    function mintTokenToSelf(
        uint256 tokenId
    ) public virtual {
        mintToken(msg.sender, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     */
    function burnToken(uint256 tokenId) public virtual {
        require(!_burnedToken[tokenId], TOKEN_ALREADY_BURNED);
        _burnedToken[tokenId] = true;
        _burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        virtual
        override
        view
        returns (string memory)
    {
        require(_exists(tokenId), TOKEN_NOTFOUND);
        return Generator.getTokenMetadataURI(tokenId, 8, 6);
    }
}