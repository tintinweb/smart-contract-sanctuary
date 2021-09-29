// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bag.sol";

contract Thriftbag is Bag {
    constructor(string memory name_, string memory symbol_) Bag(name_, symbol_) {}

    string[] internal Colors = [
        "Alice Blue",
        "Antique White",
        "Aqua",
        "Aquamarine",
        "Azure",
        "Beige",
        "Bisque",
        "Black",
        "Blanched Almond",
        "Blue",
        "Blue Violet",
        "Brown",
        "Burlywood",
        "Cadet Blue",
        "Chartreuse",
        "Chocolate",
        "Coral",
        "Cornflower Blue",
        "Cornsilk",
        "Crimson",
        "Cyan",
        "Dark Blue",
        "Dark Cyan",
        "Dark Goldenrod",
        "Dark Gray",
        "Dark Green",
        "Dark Khaki",
        "Dark Magenta",
        "Dark Olive Green",
        "Dark Orange",
        "Dark Orchid",
        "Dark Red",
        "Dark Salmon",
        "Dark Sea Green",
        "Dark Slate Blue",
        "Dark Slate Gray",
        "Dark Turquoise",
        "Dark Violet",
        "Deep Pink",
        "Deep Sky Blue",
        "Dim Gray",
        "Dodger Blue",
        "Firebrick",
        "Floral White",
        "Forest Green",
        "Fuchsia",
        "Gainsboro",
        "Ghost White",
        "Gold",
        "Goldenrod",
        "Gray",
        "Web Gray",
        "Green",
        "Web Green",
        "Green Yellow",
        "Honeydew",
        "Hot Pink",
        "Indian Red",
        "Indigo",
        "Ivory",
        "Khaki",
        "Lavender",
        "Lavender Blush",
        "Lawn Green",
        "Lemon Chiffon",
        "Light Blue",
        "Light Coral",
        "Light Cyan",
        "Light Goldenrod",
        "Light Gray",
        "Light Green",
        "Light Pink",
        "Light Salmon",
        "Light Sea Green",
        "Light Sky Blue",
        "Light Slate Gray",
        "Light Steel Blue",
        "Light Yellow",
        "Lime",
        "Lime Green",
        "Linen",
        "Magenta",
        "Maroon",
        "Web Maroon",
        "Medium Aquamarine",
        "Medium Blue",
        "Medium Orchid",
        "Medium Purple",
        "Medium Sea Green",
        "Medium Slate Blue",
        "Medium Spring Green",
        "Medium Turquoise",
        "Medium Violet Red",
        "Midnight Blue",
        "Mint Cream",
        "Misty Rose",
        "Moccasin",
        "Navajo White",
        "Navy Blue",
        "Old Lace",
        "Olive",
        "Olive Drab",
        "Orange",
        "Orange Red",
        "Orchid",
        "Pale Goldenrod",
        "Pale Green",
        "Pale Turquoise",
        "Pale Violet Red",
        "Papaya Whip",
        "Peach Puff",
        "Peru",
        "Pink",
        "Plum",
        "Powder Blue",
        "Purple",
        "Web Purple",
        "Rebecca Purple",
        "Red",
        "Rosy Brown",
        "Royal Blue",
        "Saddle Brown",
        "Salmon",
        "Sandy Brown",
        "Sea Green",
        "Seashell",
        "Sienna",
        "Silver",
        "Sky Blue",
        "Slate Blue",
        "Slate Gray",
        "Snow",
        "Spring Green",
        "Steel Blue",
        "Tan",
        "Teal",
        "Thistle",
        "Tomato",
        "Turquoise",
        "Violet",
        "Wheat",
        "White",
        "White Smoke",
        "Yellow",
        "Yellow Green"
    ];

    uint24[] internal ColorValues = [
        15792383,
        16444375,
        65535,
        8388564,
        15794175,
        16119260,
        16770244,
        0,
        16772045,
        255,
        9055202,
        10824234,
        14596231,
        6266528,
        8388352,
        13789470,
        16744272,
        6591981,
        16775388,
        14423100,
        65535,
        139,
        35723,
        12092939,
        11119017,
        25600,
        12433259,
        9109643,
        5597999,
        16747520,
        10040012,
        9109504,
        15308410,
        9419919,
        4734347,
        3100495,
        52945,
        9699539,
        16716947,
        49151,
        6908265,
        2003199,
        11674146,
        16775920,
        2263842,
        16711935,
        14474460,
        16316671,
        16766720,
        14329120,
        12500670,
        8421504,
        65280,
        32768,
        11403055,
        15794160,
        16738740,
        13458524,
        4915330,
        16777200,
        15787660,
        15132410,
        16773365,
        8190976,
        16775885,
        11393254,
        15761536,
        14745599,
        16448210,
        13882323,
        9498256,
        16758465,
        16752762,
        2142890,
        8900346,
        7833753,
        11584734,
        16777184,
        65280,
        3329330,
        16445670,
        16711935,
        11546720,
        8388608,
        6737322,
        205,
        12211667,
        9662683,
        3978097,
        8087790,
        64154,
        4772300,
        13047173,
        1644912,
        16121850,
        16770273,
        16770229,
        16768685,
        128,
        16643558,
        8421376,
        7048739,
        16753920,
        16729344,
        14315734,
        15657130,
        10025880,
        11529966,
        14381203,
        16773077,
        16767673,
        13468991,
        16761035,
        14524637,
        11591910,
        10494192,
        8388736,
        6697881,
        16711680,
        12357519,
        4286945,
        9127187,
        16416882,
        16032864,
        3050327,
        16774638,
        10506797,
        12632256,
        8900331,
        6970061,
        7372944,
        16775930,
        65407,
        4620980,
        13808780,
        32896,
        14204888,
        16737095,
        4251856,
        15631086,
        16113331,
        16777215,
        16119285,
        16776960,
        10145074
    ];

    string[] internal Fits = [
        "Slim",
        "Skinny",
        "Straight",
        "Regular",
        "Classic",
        "Relaxed",
        "Baggy",
        "Modern",
        "Loose"
    ];

    string[] internal Style = [
        "Street",
        "Ethnic",
        "Formal Office",
        "Business Casual",
        "Evening Black Tie",
        "Sports",
        "Girly",
        "Androgynous",
        "E Girl",
        "Scene",
        "Rocker Chic",
        "Skateboarders",
        "Goth",
        "Maternity",
        "Lolita",
        "Gothic Lolita",
        "Hip Hop",
        "Chave",
        "Kawaii",
        "Preppy",
        "Cowgirl",
        "Lagenlook",
        "Girl Next Door",
        "Casual Chic",
        "Geeky Chic",
        "Military",
        "Retro",
        "Flapper",
        "Tomboy",
        "Garconne",
        "Resort",
        "Camp",
        "Artsy",
        "Grunge",
        "Punk",
        "Boho Chic",
        "Biker",
        "Psychedelic",
        "Cosplay",
        "Haute Couture",
        "Modest",
        "Prairie Chic",
        "Rave",
        "Flamboyant",
        "Ankara",
        "Arthoe"
    ];

    string[] internal Items = [
        "Sweater",
        "Dress",
        "Hoodies",
        "T-shirt",
        "Flip-flops",
        "Shorts",
        "Skirt",
        "Jeans",
        "Shoes",
        "Coat",
        "High Heels",
        "Suit",
        "Cap",
        "Socks",
        "Shirt",
        "Bra",
        "Scarf",
        "Swimsuit",
        "Hat",
        "Gloves",
        "Jacket",
        "Long Coat",
        "Boots",
        "Sunglasses",
        "Tie",
        "Polo Shirt",
        "Leather Jackets"
    ];

    string[] private SpecialColors = ["Bronze", "Silver", "Platinum", "Golden"];

    uint24[] private SpecialColorValues = [13467442, 12632256, 15066338, 16766720];

    string[] private SpecialItems = [
        "Earrings",
        "Smartphone",
        "Earpods",
        "Wallet",
        "Necklace",
        "Wristwatch",
        "Ring",
        "Bracelet"
    ];
    string[] private empty;

    /**
     * @dev get color for a specific tokenId
     * @return string color name
     */
    function getColor(uint256 tokenId) public view returns (string memory) {
        requireIsItem(tokenId);
        return pickFromArray(tokenId, "COLOR", Colors, SpecialColors);
    }

    /**
     * @dev get color for a specific tokenId
     * @return string color hex code
     */
    function getColorCode(uint256 tokenId) public view returns (string memory) {
        requireIsItem(tokenId);
        return toHexColorString(pickFromUIntArray(tokenId, "COLOR", ColorValues, SpecialColorValues));
    }

    /**
     * @dev get clothing fit for a specific tokenId
     * @return string clothing fit
     */
    function getFit(uint256 tokenId) public view returns (string memory) {
        requireIsItem(tokenId);
        return pickFromArray(tokenId, "FIT", Fits, empty);
    }

    /**
     * @dev get style for a specific tokenId
     * @return string style
     */
    function getStyle(uint256 tokenId) public view returns (string memory) {
        requireIsItem(tokenId);
        return pickFromArray(tokenId, "STYLE", Style, empty);
    }

    /**
     * @dev get item type for a specific item
     * @return string style
     */
    function getType(uint256 tokenId) public view returns (string memory) {
        requireIsItem(tokenId);
        return pickFromArray(tokenId, "ITEM", Items, empty);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pickFromArray(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray,
        string[] memory secondaryArray
    ) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;

        if (secondaryArray.length > 0) {
            if (greatness > 14) {
                output = secondaryArray[rand % secondaryArray.length];
            }
            if (greatness >= 19) {
                output = secondaryArray[rand % secondaryArray.length];
            }
        }

        return output;
    }

    function pickFromUIntArray(
        uint256 tokenId,
        string memory keyPrefix,
        uint24[] memory sourceArray,
        uint24[] memory secondaryArray
    ) internal pure returns (uint24) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint24 output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;

        if (secondaryArray.length > 0) {
            if (greatness > 14) {
                output = secondaryArray[rand % secondaryArray.length];
            }
            if (greatness >= 19) {
                output = secondaryArray[rand % secondaryArray.length];
            }
        }

        return output;
    }

    function getDescription() internal pure override returns (string memory) {
        return
            "Thriftbags and items are uniquely generated and stored on chain. Check out the pack and unpack features and make your own unique combination. Feel free to use yours in any way you want.";
    }

    function getItem(uint256 tokenId) internal view override returns (string memory) {
        if (tokenId <= MAX_BAGS) {
            return "Thriftbag";
        } else {
            string memory color = getColor(tokenId);
            string memory fit = getFit(tokenId);
            string memory style = getStyle(tokenId);
            string memory item = getType(tokenId);

            return string(abi.encodePacked(color, " ", fit, " ", style, " ", item));
        }
    }

    function toRow(
        uint256 tokenId,
        string memory s1,
        uint256 y
    ) internal view override returns (string memory) {
        if (tokenId > MAX_BAGS) {
            string memory color = getColorCode(tokenId);
            return
                string(
                    abi.encodePacked(
                        '<rect width="18" height="18" x="10" y="',
                        toString(y - 14),
                        '" fill="',
                        color,
                        '" /><text x="32" y="',
                        toString(y),
                        '" class="base">',
                        s1,
                        "</text>"
                    )
                );
        }
        return super.toRow(tokenId, s1, y);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

    function toHexColorString(uint24 a) public pure returns (string memory) {
        uint8 count = 6;
        uint24 b = a;
        bytes memory res = new bytes(count);
        for (uint24 i = 0; i < count; ++i) {
            b = a % 16;
            b = b < 0 ? 0 : b;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(abi.encodePacked("#", res));
    }
}