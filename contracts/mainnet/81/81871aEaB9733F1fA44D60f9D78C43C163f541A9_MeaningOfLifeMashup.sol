/*
   \  |                     _)                     _ \    _|      |     _)   _|       
  |\/ |   _ \   _` |  __ \   |  __ \    _` |      |   |  |        |      |  |     _ \ 
  |   |   __/  (   |  |   |  |  |   |  (   |      |   |  __|      |      |  __|   __/ 
 _|  _| \___| \__,_| _|  _| _| _|  _| \__, |     \___/  _|       _____| _| _|   \___| 
                                      |___/
                          \  |               |                                        
                         |\/ |   _` |   __|  __ \   |   |  __ \                       
                         |   |  (   | \__ \  | | |  |   |  |   |                      
                        _|  _| \__,_| ____/ _| |_| \__,_|  .__/                       
                                                          _|                          
                                                                        
by maciej wisniewski                                                                                                                                                                                                 
*/

//SPDX-License-Identifier: MIT

/**
 * CREATE MASHUP
 * To create your own Meaning-Of-Life mashup copy this file
 * and follow the instructions inside it. All instructions begin with `CREATE MASHUP`.
 *
 * Once you are happy with the result publish it on the Rinkeby Test Network.
 * Test it thoroughly at https://rinkeby.mofl.cc
 * You will also be able to preview your mashups on the OpenSea testnet at
 * https://testnets.opensea.io/collection/meaning-of-life
 *
 * Finally publish your Mashup CC on the Ethereum Mainnet.
 * Add your mashup to the Available Mashups list at https://www.mofl.cc/add
 */

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Required interface of a CulturalContract compliant contract.
 */
interface ICulturalContract {
    /**
     * @dev Returns cRNA number, cRNA length and cRNA unit length.
     *
     * cRNA defines the attributes of an ERC721 token.
     * cRNA is divided into units. Every unit defines a set of attributes.
     * cRNAs can be easily manipulated using simple mathematical operations providing
     * many possibilities for remixes and mashups.
     *
     */
    function culturalRNA(uint256 tokenId)
        external
        returns (
            uint256 cRNA,
            uint256 numberLength,
            uint256 unitLength
        );

    /**
     * @dev Remixes ERC721 token based on the `input`.
     */
    function remix(uint256 tokenId, string memory input) external;

    /**
     * @dev Returns mashup result of ERC721 token from a given `mashupAddress`.
     */
    function mashup(uint256 tokenId, address payable mashupAddress)
        external
        payable
        returns (string memory);

    /**
     * @dev Returns `mashupFee` from `mashupAddress`.
     */
    function mashupFee(address mashupAddress) external returns (uint256);
}

/**
 * @dev Optional interface of a CulturalContract compliant contract.
 */
interface ICulturalContractMetadata {
    /**
     * @dev Returns the CulturalContract name.
     */
    function ccName() external view returns (string memory);

    /**
     * @dev Returns the CulturalContract symbol.
     */
    function ccSymbol() external view returns (string memory);

    /**
     * @dev Returns the CulturalContract author.
     */
    function ccAuthor() external view returns (string memory);
}

abstract contract CulturalContract is
    ICulturalContract,
    ICulturalContractMetadata,
    ERC165,
    ReentrancyGuard,
    Ownable
{
    /**
     * @dev See {ICulturalContract-culturalRNA}.
     */
    function culturalRNA(uint256)
        external
        pure
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0);
    }

    /**
     * @dev See {ICulturalContract-remix}.
     */
    function remix(uint256, string memory) external virtual override {}

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Note: the ERC-165 identifier for ICulturalContract interface is 0xf9ae973e
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICulturalContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

contract MeaningOfLifeMashup is CulturalContract {
    /**
     * CREATE MASHUP
     * The SVG code below represents a sample Meaning-Of-Life token that has been remixed and mashed up.
     * The middle section defines the mashup.
     * To create your own mashup you need to replace or change the mashup section.
     * You can view and edit it in any SVG compliant editor.
     */
    /*
<!--MEANING-OF-LIFE SVG CODE-->
<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">
    <style type="text/css">
        .txt {
            fill: black;
            font-family: "Open Sans", sans-serif;
            font-size: 0.75em;
        }
    </style>
    <rect width="100%" height="100%" fill="lightgray" />

    <!--MASHUP CODE STARTS HERE-->
    <style type="text/css">
        .gd1 {
            fill: url(#gd1);
        }
        .gd2 {
            fill: url(#gd2);
        }
    </style>
    <defs>
        <!--Sun/Moon color-->
        <linearGradient id="gd1" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" style="stop-color:rgba(255,255,255,0);stop-opacity:1" />
            <!--opacity  0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1-->
            <stop offset="100%" style="stop-color:moccasin;stop-opacity:0.9" />
        </linearGradient>

        <!--Sky color-->
        <linearGradient id="gd2" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="260">
            <stop offset="0" style="stop-color:midnightblue" />
            <stop offset="1" style="stop-color:darkred;stop-opacity:0" />
        </linearGradient>
        <!--Mask-->
        <clipPath id="lsm">
            <path d="M233.7,262.1l34.3-0.7c3.3,0.2,6.5,0.2,9.8,0.1c1.6-0.1,3.2-0.3,4.7-0.4c0.7,0,25.6,2,26.1,3
            c13.8,0,27.6,0.1,41.4,0.1c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c7.4,0,86.4-3.5,86.4-3.5
            l25.2,0.2l6.4,0.2c5.5-0.3,10.9,0.1,16.4-0.3c3-0.2,20.9-1,24.6,0c3.9,1.1,11.4,0.3,11.4,0.3l19.7,3.4c0,0,1-1.1,1.5-1.9
            c0.9-1.4,1.5-2.8,1.8-4.2c0.3-18,0.7-27,1-27c0.3,0,0.6,9,0.8,26.9c0.5,1.4,1.1,2.9,2,4.3c0.6,0.9,1.2,1.6,1.6,2.1
            c11.4,0,22.8,0.1,34.2,0.1C233.2,263.4,233.4,262.8,233.7,262.1z" />
        </clipPath>

    </defs>

    <g clip-path="url(#lsm)">
        <!--Sun/Moon animation path-->
        <path d="M-69,5C87.3,106.4,140.9,149.4,154.6,167.4c3.4,4.5,21.8,30.6,55.6,55.2c0,0,1.6,1.2,3.3,2.4
	    c36,25.3,164.6,40.9,200,45" fill="none" id="ap1"></path>

        <!--Sun/Moon-->
        <circle cx="" cy="" r="60" class="gd1">
            <animateMotion dur="60s" repeatCount="indefinite">
                <mpath href="#ap1"></mpath>
            </animateMotion>
        </circle>

        <!--Landscape/Cityscape-->
        <path class="gd2" d="M233.7,262.1l34.3-0.7c3.3,0.2,6.5,0.2,9.8,0.1c1.6-0.1,3.2-0.3,4.7-0.4c0.7,0,25.6,2,26.1,3
        c13.8,0,27.6,0.1,41.4,0.1c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c7.4,0,86.4-3.5,86.4-3.5
        l25.2,0.2l6.4,0.2c5.5-0.3,10.9,0.1,16.4-0.3c3-0.2,20.9-1,24.6,0c3.9,1.1,11.4,0.3,11.4,0.3l19.7,3.4c0,0,1-1.1,1.5-1.9
        c0.9-1.4,1.5-2.8,1.8-4.2c0.3-18,0.7-27,1-27c0.3,0,0.6,9,0.8,26.9c0.5,1.4,1.1,2.9,2,4.3c0.6,0.9,1.2,1.6,1.6,2.1
        c11.4,0,22.8,0.1,34.2,0.1C233.2,263.4,233.4,262.8,233.7,262.1z" fill="none" clip-path="url(#lsm)" />

    </g>
    <!--MASHUP CODE ENDS HERE-->

    <text x="5" y="310" class="txt">In the early evening on September 21, 1996 in New York City</text>
    <text x="5" y="330" class="txt">we all gathered at my place. We sat and talked and listened.</text>
</svg>
*/

    /**
     * Stores the Meaning-Of-Life CC address.
     */
    address public constant CC_ADDRESS_FOR_MASHUP =
        0x569b426a4137C7a7bc72056157007f1aB2A3d064;

    /**
     * CREATE MASHUP
     * Set your mashup price.
     */
    uint256 private mashupFeeAmount = 0.05 ether;

    /**
     * CREATE MASHUP
     * Change the mashupName.
     */
    string private mashupName = "MeaningOfLife Mashup 1";

    /**
     * CREATE MASHUP
     * Change the mashupSymbol.
     */
    string private mashupSymbol = "MLM1";

    /**
     * CREATE MASHUP
     * Change the mashupAuthor.
     */
    string private mashupAuthor = "maciej wisniewski";

    /**
     * CREATE MASHUP
     * `skyColor` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private skyColor = [
        "aliceblue",
        "antiquewhite",
        "azure",
        "beige",
        "bisque",
        "black",
        "blanchedalmond",
        "blue",
        "blueviolet",
        "brown",
        "burlywood",
        "cadetblue",
        "chocolate",
        "coral",
        "cornflowerblue",
        "cornsilk",
        "crimson",
        "darkblue",
        "darkgoldenrod",
        "darkkhaki",
        "darkmagenta",
        "darkorange",
        "darkorchid",
        "darkred",
        "darksalmon",
        "darkslateblue",
        "darkslategray",
        "darkviolet",
        "deeppink",
        "deepskyblue",
        "dodgerblue",
        "firebrick",
        "floralwhite",
        "fuchsia",
        "gainsboro",
        "ghostwhite",
        "goldenrod",
        "gray",
        "honeydew",
        "hotpink",
        "indianred",
        "indigo",
        "ivory",
        "khaki",
        "lavender",
        "lavenderblush",
        "lemonchiffon",
        "lightblue",
        "lightcoral",
        "lightcyan",
        "lightgoldenrodyellow",
        "lightpink",
        "lightsalmon",
        "lightskyblue",
        "lightslategray",
        "lightsteelblue",
        "lightyellow",
        "linen",
        "magenta",
        "maroon",
        "mediumblue",
        "mediumorchid",
        "mediumpurple",
        "mediumslateblue",
        "mediumvioletred",
        "midnightblue",
        "mintcream",
        "mistyrose",
        "moccasin",
        "navajowhite",
        "navy",
        "oldlace",
        "orange",
        "orangered",
        "orchid",
        "palegoldenrod",
        "palevioletred",
        "papayawhip",
        "peachpuff",
        "peru",
        "pink",
        "plum",
        "powderblue",
        "purple",
        "red",
        "rosybrown",
        "royalblue",
        "saddlebrown",
        "salmon",
        "sandybrown",
        "seashell",
        "sienna",
        "silver",
        "skyblue",
        "slateblue",
        "slategray",
        "snow",
        "steelblue",
        "tan",
        "teal",
        "thistle",
        "tomato",
        "violet",
        "wheat",
        "white"
    ];

    /**
     * CREATE MASHUP
     * `sunMoonColor` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private sunMoonColor = [
        "black",
        "blue",
        "blueviolet",
        "brown",
        "burlywood",
        "cadetblue",
        "chocolate",
        "coral",
        "cornflowerblue",
        "crimson",
        "cyan",
        "darkblue",
        "darkcyan",
        "darkgoldenrod",
        "darkkhaki",
        "darkmagenta",
        "darkorange",
        "darkorchid",
        "darkred",
        "darksalmon",
        "darkslateblue",
        "darkslategray",
        "darkviolet",
        "deeppink",
        "deepskyblue",
        "dodgerblue",
        "firebrick",
        "fuchsia",
        "gold",
        "goldenrod",
        "hotpink",
        "indianred",
        "indigo",
        "khaki",
        "lightblue",
        "lightcoral",
        "lightpink",
        "lightsalmon",
        "lightskyblue",
        "lightslategray",
        "lightsteelblue",
        "lime",
        "magenta",
        "maroon",
        "mediumblue",
        "mediumorchid",
        "mediumpurple",
        "mediumslateblue",
        "mediumvioletred",
        "midnightblue",
        "moccasin",
        "navajowhite",
        "navy",
        "orange",
        "orangered",
        "orchid",
        "palegoldenrod",
        "palevioletred",
        "papayawhip",
        "peachpuff",
        "peru",
        "pink",
        "plum",
        "powderblue",
        "purple",
        "red",
        "rosybrown",
        "royalblue",
        "saddlebrown",
        "salmon",
        "sandybrown",
        "sienna",
        "silver",
        "skyblue",
        "slateblue",
        "slategray",
        "steelblue",
        "tan",
        "teal",
        "thistle",
        "tomato",
        "violet",
        "wheat",
        "yellow"
    ];

    /**
     * CREATE MASHUP
     * `sunMoonSize` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private sunMoonSize = ["20", "30", "40", "50", "60", "70", "80"];

    /**
     * CREATE MASHUP
     * `lightDirection` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private lightDirection = [
        'x1="100%" y1="0%" x2="0%" y2="0%"',
        'x1="0%" y1="100%" x2="0%" y2="0%"',
        'x1="0%" y1="0%" x2="1000%" y2="0%"',
        'x1="0%" y1="0%" x2="0%" y2="100%"'
    ];

    /**
     * CREATE MASHUP
     * `sunMoonOpacity` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private sunMoonOpacity = [
        "0.2",
        "0.3",
        "0.4",
        "0.5",
        "0.6",
        "0.7",
        "0.8",
        "0.9",
        "1"
    ];

    /**
     * CREATE MASHUP
     * `sunMoonAnimationPath` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private sunMoonAnimationPath = [
        "M-51.5,306.5c34.4-91.1,120.2-152.8,216.5-156c100.2-3.3,192.7,57.4,230.5,151.5",
        "M-51.5,306.5c58.4-30.4,137.3-79.3,216.5-156C244.6,73.4,296.3-4.4,328.5-62",
        "M-69,5C87.3,106.4,140.9,149.4,154.6,167.4c3.4,4.5,21.8,30.6,55.6,55.2c0,0,1.6,1.2,3.3,2.4 c36,25.3,164.6,40.9,200,45",
        "M32,334c103.7-125.9,146.7-163.9,166-173.1c5.1-2.4,34.5-15.2,65.4-43.2c0,0,1.5-1.4,3-2.7 c32.1-30.1,73.6-152.8,84.8-186.6",
        "M-83,220.7c163.1,2.4,219.6,12.2,238.8,21.5c5.1,2.5,33.5,17.4,74.6,24.1c0,0,2,0.3,4,0.6 c43.5,6.3,165.3-37.9,198.7-50.4",
        "M433,246.8c-163.1,2.1-219.9-6.2-239.3-14.9c-5.1-2.3-33.9-16.5-75.2-22c0,0-2-0.3-4-0.5 c-43.7-5.1-164.2,42.4-197.3,55.8",
        "M94,108.5c3.5-20.6,106.5-31.6,118-6.5c5.5,12.1-10.3,32.3-26,41C146.9,164.7,91.3,124.7,94,108.5z",
        "M232,266.2c-3.4,20.7-106.5,31.7-118,6.7c-5.5-12.1,10.3-32.3,25.9-41C179,210.1,234.7,250,232,266.2z",
        "M27.2,211.1c8.4-20.7,260.8-32.6,289-7.6c13.6,12-25.1,32.4-63.5,41.2C157,266.9,20.6,227.4,27.2,211.1z",
        "M318.9,77.6C311.1,98.3,73.7,111,47,86.1c-12.8-12,23.5-32.5,59.6-41.5C196.6,22.3,325.1,61.3,318.9,77.6z",
        "M63.2,49c41.2-56.1,265.7,29.7,247,115.8c-9,41.5-74.2,82.2-120.1,89.6C75.8,272.9,30.9,93,63.2,49z",
        "M175,254.7c-1.5,12.7-40.2,18.9-44.3,3.3c-1.9-7.5,4.2-19.9,10.2-25.2C155.8,219.6,176.2,244.7,175,254.7z",
        "M227.9,100.8c1.9-12.7,40.7-17.8,44.3-2.1c1.7,7.6-4.7,19.8-10.8,24.9C246.2,136.4,226.5,110.7,227.9,100.8z",
        "M96.7,145.2c9.7,9.2-10.5,47.3-26.2,41.3c-7.6-2.9-13.9-16-14.4-24.5C54.7,140.7,89.1,138,96.7,145.2z",
        "M31.7,262.8c-12.9,3.5-35-33.5-21.7-43.8c6.4-5,20.8-3.6,28.4,0.3C57.3,229.2,41.8,260,31.7,262.8z",
        "M304.3,201.7c13.1-2.6,32.4,36,18.4,45.3c-6.7,4.5-21.1,2.1-28.3-2.5C276.3,233.2,294,203.7,304.3,201.7z",
        "M163.7-32.1c36.9-4.6,73.1,78.6,76.8,118.5c1.5,16.1-2.2,27.1-3.1,29.7c-6.5,19.1-20.1,29.4-23.1,31.7 c-21.1,16-55.9,13.8-72.1-14.2c-1.8-3-8.4-14.5-8-24.9c0.1-2.7-17.5-86.4,0.9-116.5C139.4-14.8,148.8-30.2,163.7-32.1z",
        "M248.8,113.7c18.5-51.5-2.6-112.3-35.5-135.5c-45.1-31.7-109.7,9.1-118,72.1c-6.2,46.6,19.6,97.3,56,113.4 C186.3,179.2,231.2,162.7,248.8,113.7z"
    ];

    /**
     * CREATE MASHUP
     * `horizonFog` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private horizonFog = ["250", "260", "270", "280", "290", "300"];

    /**
     * CREATE MASHUP
     * `skyPath` is specific to this mashup (MLM1).
     * You can reuse it or delete it.
     */
    string[] private skyPath = [
        "M350,250.6c-3.3-0.1-8.4-0.2-14.7-0.4c-25.4-0.6-36.3-0.3-47-0.7c-37.2-1.4-52.1-4.3-90.6-6.7 c-6.9-0.4-12.4-0.7-17.7-0.9c-34.6-1.4-60-1.5-67.8-1.5c-20.5,0-54.4-0.7-112.2-4c0-39.4,0-78.9,0-118.3C0,78.5,0,39,0-0.6 c116.7,0,233.3,0,350,0c0,42.7,0,85.4,0,128.1C350,168.6,350,209.6,350,250.6z",
        "M350,255.3c-3.6-0.6-9.1-1.7-15.7-3.7c-24.2-7.2-28.9-16.1-42.3-21c-26.7-9.8-39.8,13.3-94.3,12.2 c-8.3-0.2-7.2-0.7-17.7-0.9c-34-0.8-59.1,4.3-67,5.7c-20.4,3.8-54.3,7.3-113,5c0-44.9,0-89.7,0-134.6C0,78.5,0,39,0-0.6 c116.7,0,233.3,0,350,0c0,42.7,0,85.4,0,128.1C350,170.1,350,212.7,350,255.3z",
        "M350,220.3c-2,0.7-5.2,1.7-9,3c-36.7,12.3-40,13.7-45.3,15.3c-37.7,11.3-78.8-0.3-98,4.2 c-7.2,1.7-15,3.8-15,3.8c-5.6,1.5-9.6,2.7-9.8,2.7c-7.4,2.1-55.2,0.1-172.8-9.4c0-40.6,0-81.3,0-121.9C0,78.5,0,39,0-0.6 c116.7,0,233.3,0,350,0c0,42.7,0,85.4,0,128.1C350,158.5,350,189.4,350,220.3z",
        "M350,259c0-43.8,0-87.7,0-131.5c0-42.7,0-85.4,0-128.1H0C0,39,0,78.5,0,118.1c0,46.1,0,92.3,0,138.4 c54,5.8,113.8,9.7,178.5,10C240.4,266.8,297.8,263.8,350,259z",
        "M350,259c0-43.8,0-87.7,0-131.5c0-42.7,0-85.4,0-128.1H0C0,39,0,78.5,0,118.1c0,46.1,0,92.3,0,138.4 C49.7,247,304.3,249.5,350,259z",
        "M350,273c0-48.5,0-97,0-145.5c0-42.7,0-85.4,0-128.1H0C0,39,0,78.5,0,118.1c0,44.3,0,88.6,0,132.9 c16.5,0.8,40.9,2.2,70.5,4.5c52.5,4.1,88,8.7,108,11C218.1,271,275.3,275.1,350,273z",
        "M350,268.7c0-47.1,0-94.1,0-141.2c0-42.7,0-85.4,0-128.1H0C0,39,0,78.5,0,118.1c0,48.5,0,96.9,0,145.4 c23.4-1.6,41.5-4,54-6c6.1-1,10.2-1.7,16.5-2c20.1-0.9,34.7,4.2,42.5,6.5c13.2,3.9,30.6,4.1,65.5,4.5c43.6,0.5,41.4-4.8,73.5-2.5 c22.4,1.6,30.3,4.6,57,5.5C326.4,270.1,340.7,269.4,350,268.7z",
        "M350,127.5c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c23.4-1.6,41.5-4,54-6c2.7-0.4,5-0.8,7.3-1.1 c0.8-1.4,2.1-2.4,4.2-2.4c1.1,0,2.1,0.3,2.8,0.8c0.4-2.1,2-3.8,4.7-3.8c2.5,0,4,1.5,4.6,3.4c0.8-0.8,1.9-1.4,3.4-1.4 c2.3,0,3.8,1.3,4.4,2.9c12.5,1.2,21.9,4.4,27.6,6.1c13.2,3.9,106.9-0.3,139,2c22.4,1.6,88.7,5.4,98,4.7 C350,221.6,350,174.6,350,127.5z",
        "M350,268.7c0-47.1,0-94.1,0-141.2c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c9.3-0.6,153.7-4.2,153.9-6.9c0.6-6.6,9.1,7.1,12.4,7.1c3.2,0,5.5-1.2,12.7,2.8c1.6,0.9,106.2,1.3,106.2,1.3 c6.7-0.6,14.7-1.1,24.1-1.1c-0.8-1.4,9.1-1.4,8.3,0C327.3,266.8,338.2,267.4,350,268.7z",
        "M350,268.7c0-47.1,0-94.1,0-141.2c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c35.5,6.9,64.1,6.9,84,5.5c31.2-2.1,47.4-8.1,82.3-5.3c27.2,2.1,24,6.3,45.2,6.3c18.1,0.1,57.4-2.8,73.7-2.2c0,0,0,0,0,0 c6.7-0.6,14.7-1.1,24.1-1.1C308.6,265.2,338.2,267.4,350,268.7z",
        "M350,268.7c0-47.1,0-94.1,0-141.2c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4l45.2,1.7L79,265l12.5,3 l57.4,2.2l34.1,1.1l26.9-0.2l46.5-1.6C256.5,269.5,338.2,267.4,350,268.7z",
        "M350,268.7c0-47.1,0-94.1,0-141.2c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4L350,268.7z",
        "M349.6,239.5c0.2-37.3,0.3-74.6,0.4-112c0.1-42.7,0.1-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c227,13,312.5,12.3,317,4.5c0.3-0.6,2.4-5,7-9c5.6-4.9,9.9-4.6,16-9C342.6,248.2,346.2,245,349.6,239.5z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4l31.7,0.4c4.2-2.5,9.4-2.8,14.1-1.7c0.7,0.2,1.2,0.4,1.7,0.7 c3.6-1.8,7.4-2.7,11.1-4.2c1.5-0.6,3.9,0.1,4.9,1.3c0.2,0.2,0.3,0.5,0.5,0.7c1-1.6,2.9-2.6,5.3-2c3.5,1,7,3.8,10.6,3 c4-0.8,6.7,0.3,9.2,2.8c11.8,0,33.5,0,59.9-0.1c0.7-1.6,2.1-2.9,4.4-2.9c1,0,1.8,0.2,2.5,0.6c0.7-0.4,1.5-0.6,2.5-0.6 c2.3,0,3.8,1.3,4.4,2.9c23.1,0,48.8-0.1,74.2-0.1c0.9-0.8,2.1-1.3,3.3-1.3h3.5c0.3,0,0.6,0,0.9,0.1c0.5-1.3,1.5-2.4,3.2-2.9 c3.6-1,7-0.5,10.3,1.1c0.6,0.3,1.2,0.6,1.8,1c0.8-1.1,2.1-1.8,3.8-1.8h4.1c0.8-1.2,2.1-2,3.9-2c0.3,0,0.7,0,1,0.1 c1.2-1.6,3.3-2.5,5.4-1.9c5.3,1.5,9.9,5.5,15,7.5c22-0.1,41.5-0.1,56.2-0.2c0.2-45.5,0.4-91,0.5-136.5 C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,35.6,0,71.3,0,106.9c2,0.2,3.5,1.7,4.3,3.6c0.2,0.6,0.6,1.5,1.1,2.4 c0.4,0.7,1.1,1.8,1.2,1.8c0.1,0.1,0.1,0.1,0.2,0.2c25.7,9,82.8,22.7,109,28.9c10,0.9,20.2,0.5,30,3.1L156,265 c0.1-0.2,0.3-0.4,0.4-0.5c2.3-2.4,8.4-3.5,8.4-3.5l5.8-1.3l9.1-1.2c4.2-14,4.5,6.4,4.5,6.4l165.2-0.9c0.2-45.5,0.4-91,0.5-136.5 C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4l79.5,1l14.1,0.2c0.7-0.5,1.7-0.8,2.9-0.7c10.4,0.7,20.5-2.2,30.9-3.2 c1.1-0.1,2.2-0.2,3.3-0.3c10.2-2.6,20.5-3.5,31.4-3.5c2.7,0,4.3,1.7,4.7,3.8c3.9,0.3,7.7,0.8,11.6,1.5c3.3,0.6,6.5,1.5,9.7,2.6 c42-0.2,84-0.4,126-0.7c5.2-1,10.2-2.7,15.3-4c2.7-0.7,9.4,0.4,11.5-0.5c2.7-1.1,8.7-1.4,9.3-2.7c0-43.2,0-86.3,0-129.5 C350,84.8,350,42.1,350-0.6z",
        "M349.5,264c0.2-45.5,0.4-91,0.5-136.5c0.1-42.7,0.1-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c24-6,48-12,72-18c19.2,6.6,38.3,13.1,57.5,19.7c10.2-5.1,21.4-9.8,33.5-13.7C240.4,226.8,312.4,248.9,349.5,264z",
        "M349.5,264c0.2-45.5,0.4-91,0.5-136.5c0.1-42.7,0.1-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c14.4-5.6,35.8-12.9,62.5-17.5c44.5-7.7,78.9-3.9,105.5-1C223.9,251.1,282,257,349.5,264z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c14.3-3.3,36.1-7.4,63-9c39.7-2.3,49.6,3.4,88.3,4.4 c0.4-2.1,4.7-3.9,4.7-3.9s4.4,1.9,4.7,4c0.2-0.4,0.4-0.7,0.7-1c0.9-1,3.5-1.5,3.5-1.5l3.5,1.5c0,0,0.5,0.7,0.8,1c1,0,1.9,0,2.8-0.1 c0-0.1,0-0.2,0-0.3c0.2-1.4,1.5-2.1,2.3-3c0.5-0.5,1.2-1.4,1.5-2.9c0.8,0.8,1.6,1.6,2.3,2.4c0,0,2.5,1.2,3,2.3c0.2,0.3,0.5,1,0.5,1 s1.1-0.1,1.6-0.1c0.5-1.9,4.6-3.4,4.6-3.4c0.6,0.2,1.2,0.4,1.9,0.8c1.9,1,3.1,2.5,3.7,3.4c11.7-1.2,29.2-3.5,50.3-8.1 c19-4.1,17.6-5,24.8-5.5c15.7-1,24.6,3.2,63.4,13.7c7.5,2,13.7,3.6,17.5,4.6c0.2-45.5,0.4-91,0.5-136.5 C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,36.9,0,73.7,0,110.6c7.8,2.1,24.1,6.3,24.1,6.3c0.3-3.3,0.7-6.7,1-10 c0.3,3.4,0.6,6.9,0.8,10.3c0,0-0.5,0-0.8-0.1c1.5,0.4,3.1,0.8,4.7,1.1c0-1,0.3-3.1,0.3-3.1l6.2-3.5c0,0,4,3.6,3.5,6.2 c0.2-1,0.2,1,0.1,0.5c0.1,0.5,0.2,1.1,0.4,1.6c0.1,0.3,0.1,0.5,0.2,0.8C75,247,113.3,254.1,154.8,259c73.9,8.8,139.9,8.7,194.7,5 c0.2-45.5,0.4-91,0.5-136.5C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c70.9,6.3,121.1,1.5,154.8-4.5c19-3.4,38.2-6.2,57.2-10 c50.1-10.1,64.4-16.4,87-12c6.6,1.3,15,3.7,24.4,8.5c0.5-0.5,1.8-2.1,1.8-2.1s0.3-1.2,0.8-2.8c-2.7-2.5-1.9-8.2,2.5-8.8 c0.4-1.4,0.8-2.3,1-2.3c0.2,0,0.5,0.6,0.9,2.4c4.3,0.9,4.8,6.9,1.6,9.1c0.3,1.9,2,7,1.7,5.1c-0.3-2.7,2.6-5,5-5c2.9,0,4.7,2.3,5,5 c0.4,2.9,0,5.8-0.2,8.7c4.2,0.1,4,7.6,4,7.6s1.3,1.2,2,1.8c0.2-45.5,0.4-91,0.5-136.5C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c3.1-1.2,33.2-3.2,66-4.6c0.8-0.7,1.8-1.1,3-1.2 c9.3-0.7,22.4-6.1,30.1,0.1c1.9-0.1,3.8-0.1,5.7-0.1c0.1-0.1,0.2-0.2,0.4-0.2c2.9-1.6,5.9-3.2,9.3-3c3,0.1,5.6,1.6,8.2,2.9 c18.8-0.2,32.1,0.3,32.1,1.8c0.2,5,76.8,0.4,87.7,0.7c41.6,0.9,77.8,2.6,107,4.3c0.2-45.5,0.4-91,0.5-136.5 C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c20.8,0.7,41.7,1.2,62.9,1.6c0.6-1.7,4.5-3.1,4.5-3.1l14,1.8l5.3,1.7 c0,0,23.8,0.4,35.9,0.5c0.4-0.7,1.1-1.3,2-1.7c1.8-0.8,5.1-1.7,5.1-1.7l4.8-3.7l4.8,3.7l3.9-0.2l4.9-4.5l4.8,3.8 c0,0,13,2.1,19.7,2.1l23.6,0.1l25.7-1c1.7-1,5.9,0.5,5.9,0.5l4.6-3.6l4.8,4.7c0,0,1.9-0.2,2.9-0.3c1.9-0.2,3.2,0.6,4,1.7 c35.7-0.4,70.9-1.1,105.5-2.1c0.2-45.5,0.4-91,0.5-136.5C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c83.8,12,142.9,9.2,142.9,9.2l4.8-5.7l4.4,2.8c0,0,3.4-2.2,4.3-3.4 c0.5-0.7,3.6-4.9,3.6-4.9l4.4-7.1l2.9,0.9c0,0,2.1-2.9,4.4-2.9c0.4,0,1.2,0.1,1.2,0.1c1.2-2.3,2.3-4.5,3.5-6.8 c1.7,2.9,3.4,5.9,5,8.8c0,0,0.1,0,0.1,0c0.8-1.1,3.8-1.8,3.8-1.8l4.8,4.5l3.9-2.5c0,0,2.4,3,2.4,3c0,0,2.3,3,2.4,3 c4.1,2,8.7,3.3,12.9,5.6c9.7,5.3,43.5,7.4,137.8-2.3c0.2-45.5,0.4-91,0.5-136.5C350.1,84.8,350.1,42.1,350-0.6z",
        "M350-0.6H0v118.7c0,49.6,0,99.3,0,148.9c25.4,0,50.8-0.1,76.1-0.2c0.3-0.4,1.3-1.1,1.3-1.1s12.4-1.4,18.4-1.3 c2.7,0,5.5,0.1,8.2,0.1l11.4-5.1l15.2-0.9c0,0,0.1-0.1,0.1-0.1l19.9-3.3c-2-2.9-0.7-8,3.9-8c4.8,0,6,5.5,3.7,8.4l15.9,4.8 c0,0,0.3,0.3,0.5,0.5c4.6,0.3,9.1,0.7,13.7,1.1c1.5,0.1,2.7,0.8,3.5,1.8c11-0.4,22-0.7,33-1.3c7-0.4,24.6,3.3,24.6,3.3l53.5-0.7 l15.6-3.7l31.1-1.8c0.2-43.9,0.4-87.8,0.5-131.6C350.1,84.8,350.1,42.1,350-0.6z",
        "M350,127.5c0-42.7,0-85.4,0-128.1H0v118.7c0,49.6,0,99.3,0,148.9c63.3,1.3,101.8-4.2,125.7-9.7 c14-3.2,19.8-5.7,35-7.7c33.7-4.3,55.7,1.6,65-11c2.1-2.9,6.4-10.4,12.7-10.6c1.7,0,3.2,0.4,4.6,1.3c8.9-0.1,17.8-0.6,26.7-0.6 c3.7,0,5.3,3.2,4.7,6.1c2.1,0.3,4,0.9,5.4,1.6c1.8,0.8,3,1.6,3.1,1.7c2.4,1.6,21.7,9.9,67,28.6C350,220.3,350,173.9,350,127.5z",
        "M350-0.6H0v118.7c0,48.5,0,96.9,0,145.4c50.9,1.6,103.1,2.6,156.3,2.8C212,266.6,320.5,249,320.5,249 s2.3-5.7,5.6-5.9c0.5,0,1.1,0,1.6,0.1c0.4,0,0.8,0,1.2,0.1c0.2,0,0.3,0,0.3,0s1.3-0.9,1.4-1.3c0.6-3.6,5.6-8.9,5.6-8.9 s5.3,3.9,6.7,10c0-0.6,0.2-1.6,0.2-1.6l2.3-3c0.7-0.1,1.4-0.1,2-0.2c0.8-0.1,1.7-0.2,2.5-0.3c0-36.8,0-73.6,0-110.3 C350,84.8,350,42.1,350-0.6z",
        "M200.9,260.3c1.3,0.5,2.2,1,3.5,1.2c2.1,0.3,4.2,0.3,6.3,0.7c2,0.4,3.9,1,5.8,1.7c18.9,3.2,41.6,5.7,67.2,5.7 c25.3,0,47.6-2.3,66.3-5.3c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,37.8,0,75.6,0,113.4c1,0.2,2,0.6,2.9,1.3 c2.7,2.2,5.6,4.5,8.9,5.8c3.8,3.4,5.8,3.6,6.9,3.1c1.2-0.6,1.9-2.4,2.9-2.2c0.5,0.1,0.9,0.6,1,1c0.8,0.8,1.7,1.6,2.7,2.4 c4.8,4,9.8,6.5,14.2,8.2c9.9,1.6,20.8,2.8,32.5,3.6c16.1,1,30.8,0.7,43.9-0.2c21.5-0.1,31.2-4.5,36.1-8.7c1.5-1.3,6.1-5.7,11.3-4.9 c2.6,0.4,3.8,2.5,6.1,3.7C169.5,244.5,183.8,253.2,200.9,260.3z",
        "M336,247.2c0,0,0.1-0.8,0.1-1.2l4.8-3.7c0,0,6-0.5,9-1.2c0-37.9,0-75.8,0-113.7c0-42.7,0-85.4,0-128.1H0v118.7 c0,48.5,0,96.9,0,145.4c15.5,0,57.4,0.1,72.9,0.1c46.9,0.1,137.1,0.3,137.1,0.3s1.6,0.3,2,0.4c-0.4-1.9-0.9-3.8-1.3-5.7l14,0.9 c7.8,0.6,15.6,1.2,23.4,1.7l12.4-4c0,0,13.4,0.3,20.1,0.2c0.1-0.1,0.3-0.3,0.3-0.3l32.5-4.7c0,0,0.1,0,0.2,0 c0.2-0.9,1.4-2.6,1.4-2.6l9-2.6L336,247.2z",
        "M233.7,262.1l34.3-0.7c3.3,0.2,6.5,0.2,9.8,0.1c1.6-0.1,3.2-0.3,4.7-0.4c0.7,0,25.6,2,26.1,3 c13.8,0,27.6,0.1,41.4,0.1c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c7.4,0,86.4-3.5,86.4-3.5 l25.2,0.2l6.4,0.2c5.5-0.3,10.9,0.1,16.4-0.3c3-0.2,20.9-1,24.6,0c3.9,1.1,11.4,0.3,11.4,0.3l19.7,3.4c0,0,1-1.1,1.5-1.9 c0.9-1.4,1.5-2.8,1.8-4.2c0.3-18,0.7-27,1-27c0.3,0,0.6,9,0.8,26.9c0.5,1.4,1.1,2.9,2,4.3c0.6,0.9,1.2,1.6,1.6,2.1 c11.4,0,22.8,0.1,34.2,0.1C233.2,263.4,233.4,262.8,233.7,262.1z",
        "M215.3,260c1.4,0.3,2,0.6,2.8,0.8c2.9,0.8,7.7,0.2,15.3-6.4c14.6,4,31.9,7.6,51.6,9.6c25,2.6,47,2,65,0.2 c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c24,0.2,48.3,0.3,72.9,0.1c44.8-0.3,88.6-1.3,131.4-2.9 C207,259.8,210.9,259,215.3,260z",
        "M294,263.8c0.3,0,1.5-1.6,1.5-1.6l5.4-0.2l5.1,2.1c13.9,0.1,28.5,0.2,44,0.2c0-45.6,0-91.2,0-136.8 c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c12.5-2.6,29.8-5.2,50.3-5.5c12.3-0.2,22.1,0.5,27.3,1 c1.8,0.2,3.2,0.3,3.4,0.3c9.1,0.9,66.4-0.4,212.7-6.3C293.2,261.4,293.5,263.7,294,263.8z",
        "M350,127.5c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c5.1,0,13.1,0,22,0v-0.9l5-5 c0,0,5.8-0.6,8.7-0.7c0,0,9.1-5.9,15.2-6c8.2-5.3,22.6-2.7,31-2.4c5.1,0.2,22.6-0.2,45.5-0.8c0.2-0.9,1.3-2.3,1.3-2.3l3.5-1.5 l2.7,0.8l4.6-3.1l3.8,1.8l5.5-2c0,0,0.8,0.2,1.1,0.4c0-0.4,0-0.8-0.1-1.3c-0.2-2.7,5-5,5-5s4.6,2.2,5,4.7c0.1,0,0.4-0.1,0.4-0.1 l3.5,1.5l0.8,1.1l2.7-0.9l4.4,2.7l2.6-0.7l3.5,1.5c0,0,0.5,0.7,0.8,1c52.1-1.2,107.1-2.1,115.7,0c1,0.3,1.8,0.8,2.4,1.4 c1,0,10.8,3.8,10.8,3.8s4.2,1.7,6,1.5c3.2-0.4,9.4,5.2,9.4,5.2s4.2,0,6.4,0c2.1,0,5.4,5.9,5.4,5.9s10.2,0,15.3,0 C350,218.7,350,173.1,350,127.5z",
        "M350,127.5c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c3.4,0,13.7,0,13.7,0l4.6-3.5l2.4,0.6 c0.1-0.5,0.2-1,0.5-1.1c1-0.1,1.9,8.8,3.2,8.8c0.6,0,1.4-2.5,2.1-9.8c0.2-0.4,0.5-0.9,1.1-1.1c0.8-0.2,1.1,0.7,2.1,0.8 c1.4,0.2,2.3-1.3,3.4-0.9c0.3,0.1,0.6,0.4,0.7,0.6c0.6,6.3,1.3,7.9,1.9,8c1.3,0.1,2.4-7.3,3.5-7.2c0.4,0,0.6,1,0.7,1.9 c0.8-0.8,3.4-1.4,3.4-1.4l4.8,4.2c2-0.1,5.7-0.2,10.3,0c7.9,0.4,13.8,1.5,14.9,1.8c14.9,2.7,67.2-0.6,95-1.3 c33.6-0.9,31.3,2.1,79.3,1.7c21.5-0.2,39.1-0.9,50.5-1.5c0.3-0.5,2-2.5,2-2.5c1.5,0.6,3.1,0.2,4.2-1c1-1.1,1.2-2.6,0.7-4 c0.2,0,1.2,0.1,1.4,0.2c0.7-2.5,0.8-4.3,1.2-4.3c0.4,0,0.2,2.8,1.4,6.2c0.4,0.6,3,5.5,3,5.5s25.4,0.1,38,0.1 C350,218.7,350,173.1,350,127.5z",
        "M350,127.5c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4c15.5,0,57.4,0.1,72.9,0.1 c25.5,0,73.6-0.4,76.4,0.2s1.1-4.8,1.1-4.8s7.9-1.2,13.4,3.5c4.2-0.5,8.2-2.1,12.4-2.8c4.9-0.9,14.9-2.2,14.9-2.2 c0.4,4.1,0.9,8.1,1.3,12.2c2.8-3.7,5.6-7.3,8.3-11c0,0,17,3.4,25.7,3.7c1.6,0,2.8,0.7,3.6,1.6c40,0.1,80,0.2,120.1,0.4 C350,218.7,350,173.1,350,127.5z",
        "M350,264.3c0-45.6,0-91.2,0-136.8c0-42.7,0-85.4,0-128.1H0v118.7c0,48.5,0,96.9,0,145.4 c14.2,4.1,25.4,4,32.7,3.2c16.3-1.8,24.2-7.9,41.3-6.7c7.4,0.5,9.6,1.9,18.7,4c23.2,5.3,47.7,3.8,96.7,0.7c7.1-0.4,8.3-0.6,12-0.7 c22.5-0.4,28.2,4.2,37-0.3c6.9-3.5,7.6-8.5,13-8.3c5.1,0.1,6.8,4.6,13.3,6.3c6.5,1.7,12.1-0.9,14.3-1.7 C287,257.1,305.7,256.5,350,264.3z"
    ];

    /**
     * Constructor
     */
    constructor() Ownable() {}

    /**
     * @dev See {ICulturalContract-mashupFee}.
     */
    function mashupFee(address) public view override returns (uint256) {
        return mashupFeeAmount;
    }

    /**
     * @dev Sets mashup price.
     *
     * CREATE MASHUP
     * You can change your `mashupFeeAmount` at https://etherscan.io by selecting `Write Contract`, `Connect to Web3` and
     * `setMashupFee` using the same address (wallet) you published the contract with.
     *
     * IMPORTANT!
     * You need to verify and publish your contract source code at https://etherscan.io before doing that.
     * To submit your contract for verification go to https://etherscan.io/address/YOUR_MASHUP_ADDRESS#code
     * select `Verify and Publish` and follow the instructions.
     */
    function setMashupFee(uint256 newMashupFee) public onlyOwner {
        mashupFeeAmount = newMashupFee;
    }

    /**
     * @dev Returns a pseudorandom number.
     */
    function mix(uint256 tokenId) internal view returns (uint256) {
        uint256 mixNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, tokenId))
        );
        return mixNumber;
    }

    /**
     * @dev Returns lightDirection.
     *
     * CREATE MASHUP
     * `getLightDirection` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `lightDirection` array.
     * You can repurpose it or delete it.
     */
    function getLightDirection(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    lightDirection[mix(tokenId) % lightDirection.length]
                )
            );
    }

    /**
     * @dev Returns sunMoonOpacity.
     *
     * CREATE MASHUP
     * `getSunMoonOpacity` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `sunMoonOpacity` array.
     * You can repurpose it it or delete it.
     */
    function getSunMoonOpacity(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    sunMoonOpacity[mix(tokenId) % sunMoonOpacity.length]
                )
            );
    }

    /**
     * @dev Returns sunMoonAnimationPath.
     *
     * CREATE MASHUP
     * `getSunMoonPath` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `sunMoonAnimationPath` array.
     * You can repurpose it or delete it.
     */
    function getSunMoonPath(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    sunMoonAnimationPath[
                        mix(tokenId) % sunMoonAnimationPath.length
                    ]
                )
            );
    }

    /**
     * @dev Returns skyColor.
     *
     * CREATE MASHUP
     * `getSkyColor1` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `skyColor` array.
     * You can repurpose it it or delete it.
     */
    function getSkyColor1(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(abi.encodePacked(skyColor[mix(tokenId) % skyColor.length]));
    }

    /**
     * @dev Returns skyColor.
     *
     * CREATE MASHUP
     * `getSkyColor2` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `skyColor` array.
     * You can repurpose it or delete it.
     */
    function getSkyColor2(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(skyColor[mix(tokenId + 1) % skyColor.length])
            );
    }

    /**
     * @dev Returns sunMoonColor.
     *
     * CREATE MASHUP
     * `getSunMoonColor` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `sunMoonColor` array.
     * You can repurpose it or delete it.
     */
    function getSunMoonColor(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    sunMoonColor[mix(tokenId) % sunMoonColor.length]
                )
            );
    }

    /**
     * @dev Returns horizonFog.
     *
     * CREATE MASHUP
     * `getHorizonFog` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `horizonFog` array.
     * You can repurpose it or delete it.
     */
    function getHorizonFog(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(horizonFog[mix(tokenId) % horizonFog.length])
            );
    }

    /**
     * @dev Returns sunMoonSize.
     *
     * CREATE MASHUP
     * `getSunMoonSize` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `sunMoonSize` array.
     * You can repurpose it or delete it.
     */
    function getSunMoonSize(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(sunMoonSize[mix(tokenId) % sunMoonSize.length])
            );
    }

    /**
     * @dev Returns skyPath.
     *
     * CREATE MASHUP
     * `getSkyPath` is a function specific to this mashup (MLM1).
     * It picks a pseudorandom value from the `skyPath` array.
     * You can repurpose it or delete it.
     */
    function getSkyPath(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(skyPath[mix(tokenId) % skyPath.length]));
    }

    /**
     * @dev See {ICulturalContract-mashup}.
     *
     * CREATE MASHUP
     * This is the function that puts everything together.
     * It calls the mashup specific functions and concatenates the returns into an SVG string.
     * You need to tailor it to your own needs to make it suitable for your mashup.
     */
    function mashup(uint256 tokenId, address payable cContractAddress)
        public
        payable
        override
        nonReentrant
        returns (string memory)
    {
        require(
            CC_ADDRESS_FOR_MASHUP == cContractAddress,
            "Not known Cultural Contract"
        );

        string[21] memory svgString;

        svgString[
            0
        ] = '<style type="text/css">.gd1{fill: url(#gd1);}.gd2{fill: url(#gd2);}</style><defs><linearGradient id="gd1" ';
        svgString[1] = getLightDirection(tokenId);
        svgString[
            2
        ] = '><stop offset="0%" style="stop-color:rgba(255,255,255,0);stop-opacity:1"/><stop offset="100%" style="stop-color:';
        svgString[3] = getSunMoonColor(tokenId);
        svgString[4] = ";stop-opacity:";
        svgString[5] = getSunMoonOpacity(tokenId);
        svgString[
            6
        ] = '"/></linearGradient><linearGradient id="gd2" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="';
        svgString[7] = getHorizonFog(tokenId);
        svgString[8] = '"><stop offset="0" style="stop-color:';
        svgString[9] = getSkyColor1(tokenId);
        svgString[10] = '"/><stop offset="1" style="stop-color:';
        svgString[11] = getSkyColor2(tokenId);
        svgString[
            12
        ] = ';stop-opacity:0"/></linearGradient><clipPath id="lsm"><path d="';
        svgString[13] = getSkyPath(tokenId);
        svgString[
            14
        ] = '"/></clipPath></defs><g clip-path="url(#lsm)"><path d="';
        svgString[15] = getSunMoonPath(tokenId);
        svgString[16] = '" fill="none" id="ap1"></path><circle cx="" cy="" r="';
        svgString[17] = getSunMoonSize(tokenId);
        svgString[
            18
        ] = '" class="gd1"><animateMotion dur="40s" repeatCount="indefinite"><mpath href="#ap1"></mpath></animateMotion></circle><path class="gd2" d="';
        svgString[19] = getSkyPath(tokenId);
        svgString[20] = '" fill="none" clip-path="url(#lsm)" /></g>';

        string memory svg = string(
            abi.encodePacked(
                svgString[0],
                svgString[1],
                svgString[2],
                svgString[3],
                svgString[4],
                svgString[5],
                svgString[6]
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                svgString[7],
                svgString[8],
                svgString[9],
                svgString[10],
                svgString[11],
                svgString[12],
                svgString[13]
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                svgString[14],
                svgString[15],
                svgString[16],
                svgString[17],
                svgString[18],
                svgString[19],
                svgString[20]
            )
        );
        svg = string(abi.encodePacked(svg));
        return svg;
    }

    /**
     * CREATE MASHUP
     * Withdraw your funds at https://etherscan.io by selecting `Write Contract`,
     * `Connect to Web3` and `withdraw` using the same address (wallet) you published the contract with.
     * The funds will be send to your address (wallet).
     *
     * IMPORTANT!
     * You need to verify and publish your contract source code at https://etherscan.io before doing that.
     * To submit your contract for verification go to https://etherscan.io/address/YOUR_MASHUP_ADDRESS#code
     * select `Verify and Publish` and follow the instructions.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @dev Function to receive Ether. msg.data must be empty.
     */
    receive() external payable {}

    /**
     * @dev Fallback function is called when msg.data is not empty.
     */
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev See {ICulturalContractMetadata-ccName}.
     */
    function ccName() public view virtual override returns (string memory) {
        return mashupName;
    }

    /**
     * @dev See {ICulturalContractMetadata-ccSymbol}.
     */
    function ccSymbol() public view virtual override returns (string memory) {
        return mashupSymbol;
    }

    /**
     * @dev See {ICulturalContractMetadata-ccAuthor}.
     */
    function ccAuthor() public view virtual override returns (string memory) {
        return mashupAuthor;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}