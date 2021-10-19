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
contract Rings is ERC721Enumerable, Ownable{

    //Error codes, inspired from HTTP errors codes
    string constant TOKEN_ID_OUTOFRANGE = "400";
    string constant TOKEN_OPERATION_FORBIDDEN = "403";
    string constant TOKEN_NOTFOUND = "404";
    string constant TOKEN_ALREADY_BURNED = "409";

    // Mapping address to mint count
    mapping(address => uint256) private _mintCount;

    // Burned token tracker
    mapping(uint256 => bool) private _burnedToken;

    uint256 constant maxTokenId = 61;
    constructor() ERC721("Rings OnChained", "RING") {

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
        require(msg.sender == owner() || _mintCount[msg.sender] < 3, TOKEN_OPERATION_FORBIDDEN);
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
        require(msg.sender == ownerOf(tokenId) || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), TOKEN_OPERATION_FORBIDDEN);
        require(!_burnedToken[tokenId], TOKEN_ALREADY_BURNED);
        _burnedToken[tokenId] = true;
        _burn(tokenId);
    }

    /**
     * @dev Return metadata for `tokenId`.
     */
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
        
        bytes memory initialColorHex = Generator.getColorHex(tokenId, 5, 1);
        bytes memory initialColorHexB64=Generator.getb64FromBytes3(initialColorHex);
        bytes memory colorB64x2=Generator.getb64FromBytes3(abi.encodePacked(initialColorHexB64,"I"));
        bytes memory numberB64 = Generator.getb64FromBytes3(Generator.fillString(tokenId, bytes("    0\""), 4));
        
        bytes memory gradientEffect = abi.encodePacked(Generator.gradientStartNoId,
            Generator.gradientId);
        
        for(uint i = 0;i<3;i++)
        {
            gradientEffect = abi.encodePacked(gradientEffect,
            Generator.offsetPercent,
            Generator.eightyPercent,
            Generator.offsetColor,
            i==1 ? colorB64x2 : Generator.darkColorB64x2,
            Generator.endOfColorB64x2);
        }
        gradientEffect = abi.encodePacked(gradientEffect,Generator.gradientEnd);
        
        bytes memory circlePhi = abi.encodePacked(Generator.circleBegin,
            Generator.circleRadiusPhi,
            Generator.circleEndNoFill,
            Generator.fillGradientB64x2,
            Generator.endOfTagPadded,
            Generator.circleEndTag);        

        bytes memory orbEffect = abi.encodePacked(
            Generator.circleBegin,
            Generator.circleRadiusBig,
            Generator.circleEndNoFill,
            Generator.darkColorEndTagPaddedB64x2,
            Generator.defsStart);
        
        orbEffect = abi.encodePacked(orbEffect,
            gradientEffect,
            Generator.defsEnd,
            circlePhi,
            Generator.closeSvgJson);

        bytes memory retB64=abi.encodePacked(
            Generator.backgroundDesc,"UmluZyB3aXRoIGNvbG9yICAj",
            initialColorHexB64,
            "IiwibmFtZSI6ICJSaW5n",
            numberB64,
            Generator.imageDataB64,
            Generator.svgHeaderB64,
            orbEffect);

        bytes memory chars=bytes("NV1rEQX");
        uint16[7] memory pos=[uint16(587),731,809,811,847,848,849];
        for(uint i=0;i<pos.length;i++)
        {
            retB64[pos[i]] = chars[i];
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            retB64));
    }
}