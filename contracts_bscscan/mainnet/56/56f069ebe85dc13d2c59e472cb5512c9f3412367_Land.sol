// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "ERC721.sol";
import "ERC20.sol";
import "Counters.sol";
import "Ownable.sol";
import "Strings.sol";

contract Land is ERC721, Ownable {

    uint256 public maxSupply = 4096;

    ERC20 public metaxToken;

    uint256 public metaxFee = 100 ether;

    mapping(uint256 => Position) public tokens;

    struct Position {
        uint256 x;
        uint256 y;
    }

    event eventXY(uint256 tokenId, uint256 x, uint256 y);
    event eventXYString(uint256 tokenId, string x, string y);

    constructor() ERC721("DreamIsland", "DreamIsland") public {

    }

    function setMetaxAddress(address _metaxAddress) public onlyOwner
    {
        metaxToken = ERC20(_metaxAddress);
    }

    function setMetaxFee(uint256 _metaxFee) public onlyOwner
    {
        metaxFee = _metaxFee;
    }

    function withdraw(uint256 amount) public onlyOwner
    {
        metaxToken.transfer(msg.sender, amount);
    }

    function mint() public returns (uint256)
    {
        require(totalSupply() < maxSupply, "Total supply reached");
        require(metaxToken.balanceOf(msg.sender) >= metaxFee, "transfer amount exceeds balance");
        require(metaxToken.allowance(msg.sender, address(this)) >= metaxFee, "transfer amount exceeds allowance");

        metaxToken.transferFrom(msg.sender, address(this), metaxFee);

        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);

        uint256 x;
        uint256 y;
        (x, y) = calcXY(tokenId);
        tokens[tokenId] = Position(x, y);

        return tokenId;
    }

    function mintBatch(uint256 num) public returns (uint256[] memory)
    {
        require(num <= 10, "Limit Exceeded");
        require(totalSupply() + num < maxSupply, "Total supply reached");
        require(metaxToken.balanceOf(msg.sender) >= metaxFee * num, "transfer amount exceeds balance");
        require(metaxToken.allowance(msg.sender, address(this)) >= metaxFee * num, "transfer amount exceeds allowance");

        uint256[] memory tokenIds = new uint256[](num);
        for (uint256 i = 0; i < num; i++)
        {
            uint256 tokenId = mint();
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    function calcXY(uint256 tokenId) public pure returns (uint256, uint256)
    {
        tokenId--;
        uint256 baseX = 0;
        uint256 baseY = 0;
        uint256 x = tokenId % 64;
        uint256 y = tokenId / 64;
        x = baseX + x;
        y = baseY + y;
        return (x, y);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory x = Strings.toString(tokens[tokenId].x);
        string memory y = Strings.toString(tokens[tokenId].y);


        if (bytes(baseURI()).length > 0)
        {
            return string(abi.encodePacked(baseURI(), tokenId.toString(), ".json"));
        }
        else
        {
            string memory atrrOutput = makeAttributeParts(x, y);
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "DreamIsland (', x, ', ', y, ')", "description": "Open the MetaverseX Mystery Box, you will definitely get a piece of Metaxland,each piece of land has a unique coordinate.All the land are NFT items, which have a high potential for appreciation. When the Metaversex 3D game will coming，everyone can find their land in the game and create buildings or decorations.", "image": "ipfs://QmULa1t4yeEZR1Vmsq7YVBfZe2yHBRMfedySTixYDKvUfn"', ',"properties":', atrrOutput, '}'))));
            return string(abi.encodePacked('data:application/json;base64,', json));
        }
    }

    function makeAttributeParts(string memory x, string memory y) internal pure returns (string memory){
        string[11] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Land X", "value": "';
        attrParts[1] = x;
        attrParts[2] = '" }, { "trait_type": "Land Y","value": "';
        attrParts[3] = y;
        attrParts[4] = '" }]';

        string memory atrrOutput = string(abi.encodePacked(attrParts[0], attrParts[1], attrParts[2], attrParts[3], attrParts[4]));
        return atrrOutput;
    }

}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}