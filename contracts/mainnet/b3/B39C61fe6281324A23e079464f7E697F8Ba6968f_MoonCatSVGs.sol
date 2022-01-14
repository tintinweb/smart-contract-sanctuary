/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMoonCatReference {
    function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
    function setDoc (address contractAddress, string calldata name, string calldata description) external;
}

interface IMoonCatTraits {
    function kTraitsOf (bytes5 catId) external view returns (bool genesis, bool pale, uint8 facing, uint8 expression, uint8 pattern, uint8 pose);
}

interface IMoonCatColors {
    function colorsOf (bytes5 catId) external view returns (uint8[24] memory);
}

/**
 * @title MoonCatSVGs
 * @notice On Chain MoonCat Image Generation
 * @dev Builds SVGs of MoonCat Images
 */
contract MoonCatSVGs {

    /* External Contracts */

    IMoonCatRescue MoonCatRescue = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);

    IMoonCatReference MoonCatReference;
    IMoonCatTraits MoonCatTraits;
    IMoonCatColors MoonCatColors;

    address MoonCatAcclimatorAddress = 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69;

    uint8[16] public CatBox = [53, 49, 42, 34,
                               51, 49, 40, 28,
                               51, 49, 34, 44,
                               53, 37, 40, 42];

    string constant public Face = "57 51,59 51,59 53,61 53,61 55,67 55,67 53,69 53,69 51,71 51,71 53,69 53,69 55,71 55,71 57,73 57,73 67,71 67,71 69,57 69,57 67,55 67,55 57,57 57,57 55,59 55,59 53,57 53";

    string[4] public Border =
        ["57 49,59 49,59 51,61 51,61 53,67 53,67 51,69 51,69 49,71 49,71 51,73 51,73 55,75 55,75 59,85 59,85 61,87 61,87 65,89 65,89 61,87 61,87 55,93 55,93 59,95 59,95 69,93 69,93 71,89 71,89 75,87 75,87 77,85 77,85 79,83 79,83 81,81 81,81 83,61 83,61 77,59 77,59 75,57 75,57 69,55 69,55 67,53 67,53 55,55 55,55 51,57 51",
         "57 49,59 49,59 51,61 51,61 53,67 53,67 51,69 51,69 49,71 49,71 51,73 51,73 55,83 55,83 57,89 57,89 61,91 61,91 71,89 71,89 73,87 73,87 75,85 75,85 77,69 77,69 75,53 75,53 73,51 73,51 65,53 65,53 55,55 55,55 51,57 51",
         "57 49,59 49,59 51,61 51,61 53,67 53,67 51,69 51,69 49,73 49,73 55,75 55,75 69,79 69,79 71,83 71,83 75,85 75,85 85,83 85,83 87,81 87,81 89,77 89,77 93,71 93,71 91,65 91,65 93,61 93,61 91,59 91,59 83,57 83,57 77,55 77,55 75,51 75,51 69,55 69,55 67,53 67,53 55,55 55,55 51,57 51",
         "57 49,61 49,61 53,67 53,67 51,69 51,69 49,73 49,73 53,77 53,77 51,79 51,79 49,83 49,83 45,81 45,81 43,77 43,77 45,73 45,73 37,85 37,85 39,89 39,89 45,91 45,91 51,93 51,93 61,91 61,91 67,93 67,93 73,91 73,91 77,89 77,89 79,81 79,81 77,75 77,75 75,71 75,71 77,69 77,69 79,63 79,63 77,61 77,61 79,53 79,53 73,55 73,55 71,57 71,57 69,55 69,55 67,53 67,53 53,55 53,55 51,57 51"];

    string[4] public Coat =
        ["59 71,71 71,71 69,73 69,73 67,75 67,75 61,83 61,83 63,85 63,85 67,91 67,91 59,89 59,89 57,91 57,91 59,93 59,93 67,91 67,91 69,87 69,87 73,85 73,85 75,83 75,83 77,81 77,81 79,79 79,79 81,77 81,77 75,79 75,79 73,69 73,69 75,71 75,71 79,69 79,69 77,67 77,67 75,65 75,65 79,63 79,63 77,61 77,61 75,59 75",
         "53 69,57 69,57 71,73 71,73 73,81 73,81 71,83 71,83 69,85 69,85 67,81 67,81 65,79 65,79 67,81 67,81 71,79 71,79 69,73 69,73 67,75 67,75 59,77 59,77 57,81 57,81 59,87 59,87 63,89 63,89 69,87 69,87 71,85 71,85 73,83 73,83 75,71 75,71 71,69 71,69 73,65 73,65 71,59 71,59 73,55 73,55 71,53 71",
         "55 69,57 69,57 71,71 71,71 69,73 69,73 71,75 71,75 75,77 75,77 85,79 85,79 81,81 81,81 77,79 77,79 73,77 73,77 71,79 71,79 73,81 73,81 77,83 77,83 83,81 83,81 85,79 85,79 87,75 87,75 89,69 89,69 87,67 87,67 85,71 85,71 83,75 83,75 81,69 81,69 85,67 85,67 77,65 77,65 75,67 75,67 73,61 73,61 77,63 77,63 79,61 79,61 89,65 89,65 87,63 87,63 85,61 85,61 81,59 81,59 75,57 75,57 73,55 73",
         "89 49,85 49,85 43,81 43,81 41,77 41,77 43,75 43,75 39,83 39,83 41,87 41,87 47,89 47,89 53,91 53,91 59,89 59,89 67,91 67,91 71,89 71,89 75,87 75,87 77,85 77,85 75,79 75,79 71,83 71,83 73,81 73,81 75,85 75,85 73,87 73,87 69,85 69,85 63,83 63,83 65,79 65,79 67,77 67,77 71,73 71,73 73,69 73,69 75,65 75,65 73,63 73,63 75,59 75,59 77,57 77,57 57,55 57,55 53,57 53,57 57,71 57,71 53,73 53,73 57,57 57,57 73,59 73,59 71,71 71,71 69,75 69,75 57,77 57,77 55,79 55,79 53,81 53,81 51,89 51"];

    string[4] public Tummy =
        ["71 73,77 73,77 75,75 75,75 79,73 79,73 75,71 75",
         "75 69,79 69,79 71,75 71",
         "61 79,67 79,67 87,63 87,63 85,61 85",
         "83 63,85 63,85 67,83 67,83 69,77 69,77 67,79 67,79 65,83 65"];


    uint8[] public Eyes = [2,0,0,0,
                           59,59,67,59];

    uint8[] public Whiskers = [4,4,4,4,
                               59,63,67,63,61,65,65,65,
                               59,57,67,57,61,65,65,65,
                               59,61,67,61,61,65,65,65,
                               57,63,59,63,67,63,69,63];

    uint8[] public Skin = [6,5,7,7,
                           57,53,69,53,63,63,63,79,69,79,75,79,
                           57,53,69,53,63,63,59,71,63,71,
                           57,53,69,53,63,63,53,71,63,75,63,89,73,89,
                           57,53,69,53,63,63,77,73,55,75,65,75,83,75];

    uint8[882] public Patterns = [16,17,17,18,34,25,27,40,62,53,56,70,
                                  61,55,65,55,55,59,71,59,79,61,91,61,55,63,71,63,77,63,83,63,81,65,91,65,87,67,85,69,59,73,69,75,
                                  61,55,65,55,55,59,71,59,79,59,85,59,77,61,83,61,55,63,71,63,87,65,55,69,67,71,83,71,73,73,77,73,81,73,
                                  61,55,65,55,55,59,71,59,55,63,71,63,57,71,73,71,59,73,71,73,79,73,75,75,73,77,81,77,81,81,79,83,61,85,
                                  77,39,81,39,81,41,85,41,85,45,81,53,61,55,65,55,77,55,83,55,79,57,55,59,71,59,55,63,71,63,89,67,59,73,67,73,
                                  69,51,67,53,57,57,59,57,89,57,57,59,91,59,71,61,77,61,79,61,81,61,91,61,71,63,79,63,81,63,83,63,55,65,81,65,73,67,73,69,75,69,61,71,63,71,65,71,71,71,73,71,75,71,79,71,81,71,63,73,79,73,81,73,83,73,81,75,
                                  69,51,67,53,57,57,59,57,57,59,81,59,83,59,85,59,71,61,83,61,85,61,71,63,55,65,77,65,77,67,79,67,53,69,55,69,55,71,57,71,71,71,71,73,73,73,75,73,77,73,
                                  69,51,67,53,57,57,59,57,57,59,71,61,71,63,55,65,57,71,59,71,61,71,63,71,77,71,59,73,79,73,71,75,75,75,79,75,73,77,75,77,73,79,75,79,75,81,75,83,61,85,61,87,63,87,
                                  75,39,77,39,79,39,81,39,75,41,81,41,69,51,81,51,83,51,85,51,67,53,71,53,79,53,81,53,83,53,77,55,79,55,81,55,83,55,57,57,59,57,79,57,81,57,57,59,87,59,71,61,85,61,87,61,71,63,85,63,87,63,55,65,87,65,87,67,89,67,59,71,61,71,63,71,65,71,61,73,
                                  57,51,59,53,57,55,59,55,61,55,55,57,57,57,59,57,61,57,63,57,55,59,57,59,61,59,63,59,55,61,57,61,59,61,61,61,63,61,65,61,81,61,55,63,57,63,59,63,61,63,65,63,81,63,83,63,55,65,57,65,59,65,61,65,63,65,65,65,81,65,83,65,57,67,59,67,61,67,63,67,65,67,79,67,81,67,83,67,85,67,87,67,89,67,71,69,73,69,81,69,83,69,67,71,69,71,71,71,73,71,75,71,65,73,67,73,67,75,69,75,69,77,75,79,
                                  57,51,59,53,57,55,59,55,61,55,55,57,57,57,59,57,61,57,63,57,55,59,57,59,61,59,63,59,55,61,57,61,59,61,61,61,63,61,65,61,83,61,85,61,55,63,57,63,59,63,61,63,65,63,83,63,85,63,87,63,55,65,57,65,59,65,61,65,63,65,65,65,81,65,83,65,85,65,87,65,57,67,59,67,61,67,63,67,65,67,85,67,87,67,83,69,85,69,63,71,65,71,67,71,83,71,
                                  57,51,59,53,57,55,59,55,61,55,55,57,57,57,59,57,61,57,63,57,55,59,57,59,61,59,63,59,55,61,57,61,59,61,61,61,63,61,65,61,55,63,57,63,59,63,61,63,65,63,55,65,57,65,59,65,61,65,63,65,65,65,57,67,59,67,61,67,63,67,65,67,67,73,65,75,67,75,69,75,67,77,69,77,75,81,79,81,81,81,73,83,75,83,79,83,61,85,73,85,75,85,77,85,61,87,63,87,73,87,73,89,
                                  85,43,85,45,85,47,87,47,57,51,81,51,83,51,85,51,87,51,55,53,59,53,83,53,85,53,87,53,55,55,57,55,59,55,61,55,55,57,57,57,59,57,61,57,63,57,55,59,57,59,61,59,63,59,55,61,57,61,59,61,61,61,63,61,65,61,55,63,57,63,59,63,61,63,65,63,75,63,77,63,79,63,55,65,57,65,59,65,61,65,63,65,65,65,75,65,77,65,57,67,59,67,61,67,63,67,65,67,75,67,71,69,73,69,75,69,87,69,65,71,67,71,69,71,71,71,87,71,65,73,67,73,85,73,87,73,83,75,85,75];


    /**
     * @dev Wrap a chunk of SVG objects with a group that flips their appearance horizontally.
     */
    function flip (bytes memory svgData) public pure returns (bytes memory) {
        return abi.encodePacked("<g transform=\"scale(-1,1) translate(-128,0)\">", svgData, "</g>");
    }

    /**
     * @dev Transform a set of coordinate points into an SVG polygon object.
     */
    function polygon(string memory points, uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
        return abi.encodePacked("<polygon points=\"",
                                points,
                                "\" fill=\"rgb(",uint2str(r),",",uint2str(g),",",uint2str(b),
                                ")\"/>"
                                );
    }

    /**
     * @dev Transform a coordinate point into SVG rectangles.
     */
    function setPixel (bytes memory imageData, uint8 x, uint8 y) internal pure returns (bytes memory) {
        return abi.encodePacked(imageData,
                                "<use href=\"#r",
                                "\" x=\"",uint2str(x),
                                "\" y=\"",uint2str(y),
                                "\"/>");
    }

    /**
     * @dev Transform a set of coordinate points into a collection of SVG rectangles.
     */
    function pixelGroup (uint8[] memory data, uint8 index) public pure returns (bytes memory) {
        bytes memory pixels;
        uint startIndex = 2;
        for (uint i = 0; i < index; i++) {
            startIndex += data[i];
        }
        uint endIndex = startIndex + data[index];

        for (uint i = startIndex; i < endIndex; i++){
            uint p = i * 2;
            pixels = setPixel(pixels, data[p], data[p+1]);
        }
        return pixels;
    }

    /**
     * @dev For a given MoonCat pose and pattern ID, return a collection of SVG rectangles drawing that pattern.
     */
    function getPattern (uint8 pose, uint8 pattern) public view returns (bytes memory) {
        bytes memory pixels;
        if (pattern > 0) {
            pattern -= 1;
            uint index = (pattern << 2) + pose;
            uint startIndex = 6;
            for (uint i = 0; i < index; i++) {
                startIndex += Patterns[i];
            }
            uint endIndex = startIndex + Patterns[index];
            for (uint i = startIndex; i < endIndex; i++){
                uint p = i * 2;
                pixels = setPixel(pixels, Patterns[p], Patterns[p+1]);
            }
        }
        return pixels;
    }

    /**
     * @dev Wrap a collection of SVG rectangle "pixels" in a group to color them all the same color.
     */
    function colorGroup (bytes memory pixels, uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
        return abi.encodePacked("<g fill=\"rgb(",uint2str(r),",",uint2str(g),",",uint2str(b),")\">",
                                pixels,
                                "</g>");
    }

    /**
     * @dev Wrap a collection of SVG rectangle "pixels" in a group to create a colored glow around them.
     */
    function glowGroup (bytes memory pixels, uint8 r, uint8 g, uint8 b) public pure returns (bytes memory) {
        return abi.encodePacked("<g style=\"filter:drop-shadow(0px 0px 2px rgb(",uint2str(r), ",", uint2str(g), ",", uint2str(b),"))\">",
                                pixels,
                                "</g>");
    }

    /**
     * @dev Given specific MoonCat trait information, assemble the main visual SVG objects to represent a MoonCat with those traits.
     */
    function getPixelData (uint8 facing, uint8 expression, uint8 pose, uint8 pattern, uint8[24] memory colors)
        public
        view
        returns (bytes memory)
    {
        bytes memory border = polygon(Border[pose], colors[3], colors[4], colors[5]);
        bytes memory face = polygon(Face, colors[9], colors[10], colors[11]);
        bytes memory coat = polygon(Coat[pose], colors[9], colors[10], colors[11]);
        bytes memory skin = colorGroup(pixelGroup(Skin, pose), colors[15], colors[16], colors[17]);
        bytes memory tummy = polygon(Tummy[pose], colors[12], colors[13], colors[14]);
        bytes memory patt = colorGroup(getPattern(pose, pattern), colors[6], colors[7], colors[8]);
        bytes memory whiskers = colorGroup(pixelGroup(Whiskers, expression), colors[12], colors[13], colors[14]);
        bytes memory eyes = colorGroup(pixelGroup(Eyes, 0), colors[3], colors[4], colors[5]);

        bytes memory data;

        if (pattern == 2) {
            data = abi.encodePacked(border,
                                    face,
                                    coat,
                                    skin,
                                    tummy,
                                    whiskers,
                                    patt,
                                    eyes);
        } else {
            data = abi.encodePacked(border,
                                    face,
                                    coat,
                                    skin,
                                    tummy,
                                    patt,
                                    whiskers,
                                    eyes);
        }

        if (facing == 1) {
            return flip(data);
        }
        return data;
    }

    /**
     * @dev Construct SVG header/wrapper tag for a given set of canvas dimensions.
     */
    function svgTag (uint8 x, uint8 y, uint8 w, uint8 h) public pure returns (bytes memory) {
        return abi.encodePacked("<svg xmlns=\"http://www.w3.org/2000/svg\" preserveAspectRatio=\"xMidYMid slice\" viewBox=\"",
                                uint2str(x), " ",
                                uint2str(y), " ",
                                uint2str(w), " ",
                                uint2str(h),
                                "\" width=\"",
                                uint2str(uint32(w)*5),
                                "\" height=\"",
                                uint2str(uint32(h)*5),
                                "\" shape-rendering=\"crispEdges\" style=\"image-rendering:pixelated\"><defs><rect id=\"r\" width=\"2\" height=\"2\" /></defs>");
    }

    /**
     * @dev Convert a MoonCat facing and pose trait information into an SVG viewBox definition to set that canvas size.
     */
    function boundingBox (uint8 facing, uint8 pose) public view returns (uint8 x, uint8 y, uint8 width, uint8 height) {
        x = CatBox[pose * 4 + 0] - 2;
        y = CatBox[pose * 4 + 1] - 2;
        width = CatBox[pose * 4 + 2] + 4;
        height = CatBox[pose * 4 + 3] + 4;

        if (facing == 1) {
            x = 128 - width - x;
        }
        return (x, y, width, height);
    }

    /**
     * @dev For a given MoonCat hex ID, create an SVG of their appearance, specifying glowing or not.
     */
    function imageOf (bytes5 catId, bool glow) public view returns (string memory) {
        (,,uint8 facing, uint8 expression, uint8 pattern, uint8 pose) = MoonCatTraits.kTraitsOf(catId);

        uint8[24] memory colors = MoonCatColors.colorsOf(catId);

        bytes memory pixelData = getPixelData(facing, expression, pose, pattern, colors);

        if (glow) {
            pixelData = glowGroup(pixelData, colors[0], colors[1], colors[2]);
        }

        (uint8 x, uint8 y, uint8 width, uint8 height) = boundingBox(facing, pose);

        return string(abi.encodePacked(svgTag(x, y, width, height),
                                       pixelData,
                                       "</svg>"));
    }

    /**
     * @dev For a given MoonCat hex ID, create an SVG of their appearance, glowing if they're Acclimated.
     */
    function imageOf (bytes5 catId) public view returns (string memory) {
        return imageOf(catId, MoonCatRescue.catOwners(catId) == MoonCatAcclimatorAddress);
    }

    /**
     * @dev For a given MoonCat rescue order, create an SVG of their appearance, specifying glowing or not.
     */
    function imageOf (uint256 rescueOrder, bool glow) public view returns (string memory) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        return imageOf(MoonCatRescue.rescueOrder(rescueOrder), glow);
    }

    /**
     * @dev For a given MoonCat rescue order, create an SVG of their appearance, glowing if they're Acclimated.
     */
    function imageOf (uint256 rescueOrder) public view returns (string memory) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        return imageOf(MoonCatRescue.rescueOrder(rescueOrder));
    }

    /**
     * @dev Convert an integer/numeric value into a string of that number's decimal value.
     */
    function uint2str (uint value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /* General */

    /**
     * @dev Get documentation about this contract.
     */
    function doc() public view returns (string memory name, string memory description, string memory details) {
        return MoonCatReference.doc(address(this));
    }

    constructor (address MoonCatReferenceAddress, address MoonCatTraitsAddress, address MoonCatColorsAddress) {
        owner = payable(msg.sender);
        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);

        MoonCatReference = IMoonCatReference(MoonCatReferenceAddress);
        MoonCatTraits = IMoonCatTraits(MoonCatTraitsAddress);
        MoonCatColors = IMoonCatColors(MoonCatColorsAddress);
    }

    address payable public owner;

    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address.
     */
    function transferOwnership (address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Update the location of the Reference Contract.
     */
    function setReferenceContract (address referenceContract) public onlyOwner {
        MoonCatReference = IMoonCatReference(referenceContract);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20 (address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721 (address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }
}