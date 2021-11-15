//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

/*


███████╗██╗   ██╗███████╗██████╗ ██╗   ██╗    ██████╗  █████╗ ██╗   ██╗███████╗
██╔════╝██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
█████╗  ██║   ██║█████╗  ██████╔╝ ╚████╔╝     ██║  ██║███████║ ╚████╔╝ ███████╗
██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝      ██║  ██║██╔══██║  ╚██╔╝  ╚════██║
███████╗ ╚████╔╝ ███████╗██║  ██║   ██║       ██████╔╝██║  ██║   ██║   ███████║
╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                                               

*/

import "./EveryDayzDATA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TIRAL is ERC721, ERC721Enumerable {
    uint256 public supply;

    string[4] ears = [
        "<path d='M44.3309 121.252L44.5979 119.632L44.2047 118.037C38.9358 96.6656 35.9757 76.7414 36.1839 60.0955C36.3948 43.2284 39.8424 30.9918 46.0401 23.6577C51.7518 16.8986 61.0476 12.8871 77.0129 15.271C93.321 17.706 115.629 26.7648 145.26 45.284L146.619 46.1331L148.199 46.3936C199.486 54.8435 238.405 93.5116 232.701 142.654C187.173 164.413 160.617 185.872 117.196 230.787C68.4758 220.509 35.8858 172.51 44.3309 121.252Z' fill='url(#fill_pattern)' stroke='black' stroke-width='16'/>  <path d='M735.981 120.749L735.714 119.128L736.107 117.533C741.376 96.1621 744.336 76.2379 744.128 59.592C743.917 42.725 740.469 30.4884 734.272 23.1543C728.56 16.3952 719.264 12.3837 703.299 14.7675C686.991 17.2025 664.682 26.2614 635.052 44.7806L633.693 45.6297L632.112 45.8901C580.825 54.34 541.907 93.0082 547.61 142.151C593.139 163.91 619.695 185.369 663.116 230.283C711.836 220.006 744.426 172.006 735.981 120.749Z' fill='url(#fill_pattern)' stroke='black' stroke-width='16'/> ",
        "<path d='M199.566 115.458L199.55 115.738L199.561 116.018C199.8 122.463 200.051 128.087 200.272 133.035C200.727 143.226 201.054 150.554 200.888 156.291C200.651 164.497 199.405 167.983 196.895 171.013C193.994 174.516 189.199 177.755 179.965 183.994C179.498 184.309 179.02 184.632 178.531 184.963C168.694 191.612 155.134 200.943 136.648 216.112L136.37 216.339L136.122 216.598C130.478 222.486 126.308 224.14 123.915 224.097C122.233 224.066 119.656 223.097 117.158 217.46C114.635 211.765 112.864 202.512 112.698 189.094C112.534 175.784 113.951 158.808 117.451 137.959C122.356 108.741 142.343 79.5472 170.166 56.6444C194.359 36.729 223.964 22.006 253.467 16.2986C251.042 19.3621 248.371 22.3669 245.512 25.4345C243.777 27.296 241.949 29.2044 240.069 31.1663C235.528 35.9051 230.689 40.9553 226.154 46.407C212.942 62.2895 201.423 82.5156 199.566 115.458Z' fill='url(#fill_pattern)' stroke='black' stroke-width='12'/><path d='M564.364 115.458L564.38 115.738L564.37 116.018C564.13 122.463 563.879 128.087 563.658 133.035C563.204 143.226 562.876 150.554 563.042 156.291C563.279 164.497 564.525 167.983 567.035 171.013C569.937 174.516 574.732 177.755 583.965 183.994C584.432 184.309 584.91 184.632 585.399 184.963C595.236 191.612 608.796 200.943 627.283 216.112L627.56 216.339L627.808 216.598C633.452 222.486 637.622 224.14 640.015 224.097C641.697 224.066 644.275 223.097 646.772 217.46C649.295 211.765 651.066 202.512 651.232 189.094C651.396 175.784 649.98 158.808 646.479 137.959C641.574 108.741 621.587 79.5472 593.765 56.6444C569.571 36.729 539.966 22.006 510.463 16.2986C512.889 19.3621 515.559 22.3669 518.418 25.4345C520.153 27.296 521.982 29.2044 523.861 31.1663C528.402 35.9051 533.241 40.9553 537.776 46.407C550.988 62.2895 562.507 82.5156 564.364 115.458Z' fill='url(#fill_pattern)' stroke='black' stroke-width='12'/>",
        "<path d='M165.302 28.5395C229.468 39.1114 275.157 92.6624 267.214 155.037C210.045 181.459 177.123 207.417 122.581 262.639C59.9555 250.133 18.0782 190.106 28.5394 126.611C39.2236 61.7635 100.454 17.8554 165.302 28.5395Z' fill='url(#fill_pattern)' stroke='black' stroke-width='16'/><path d='M638.78 28.5395C574.613 39.1114 528.925 92.6624 536.867 155.037C594.036 181.459 626.959 207.417 681.501 262.639C744.126 250.133 786.003 190.106 775.542 126.611C764.858 61.7635 703.627 17.8554 638.78 28.5395Z' fill='url(#fill_pattern)' stroke='black' stroke-width='16'/>",
        "<path d='M256.988 87.694C265.941 82.4813 273.874 77.8621 280.627 73.5913C269.184 72.0196 253.134 71.2023 234.254 71.3956C208.014 71.6642 176.845 73.8753 146.111 78.4642C115.343 83.0581 85.2116 90.0058 60.9482 99.6671C36.4356 109.428 19.0079 121.531 12.0592 135.739L11.8346 136.198L11.5217 136.602C10.3828 138.074 10.308 139.053 10.4416 139.794C10.615 140.757 11.3232 142.216 13.2613 144.144C17.1923 148.054 24.4879 152.242 34.3176 156.499C53.7748 164.927 80.7072 172.627 103.246 179.063C109.962 180.981 115.091 181.271 119.68 180.392C124.305 179.506 128.816 177.351 134.194 173.686C139.437 170.112 145.197 165.325 152.528 159.232L153.354 158.545C161.016 152.178 170.196 144.587 181.767 135.984C204.891 118.79 226.82 105.388 245.607 94.3428C249.561 92.0181 253.358 89.8072 256.988 87.694Z' fill='url(#fill_pattern)' stroke='black' stroke-width='10'/><path d='M551.415 87.6595C542.462 82.4467 534.529 77.8276 527.776 73.5568C539.219 71.985 555.27 71.1678 574.149 71.361C600.389 71.6296 631.558 73.8407 662.292 78.4296C693.06 83.0236 723.191 89.9712 747.455 99.6325C771.968 109.393 789.395 121.496 796.344 135.704L796.568 136.163L796.881 136.568C798.02 138.039 798.095 139.018 797.961 139.76C797.788 140.722 797.08 142.181 795.142 144.109C791.211 148.019 783.915 152.207 774.085 156.465C754.628 164.892 727.696 172.592 705.157 179.028C698.441 180.946 693.312 181.236 688.723 180.357C684.098 179.471 679.587 177.316 674.209 173.651C668.966 170.078 663.206 165.291 655.875 159.197L655.049 158.51C647.387 152.144 638.207 144.552 626.636 135.949C603.512 118.756 581.583 105.354 562.796 94.3082C558.842 91.9835 555.045 89.7727 551.415 87.6595Z' fill='url(#fill_pattern)' stroke='black' stroke-width='10'/>"
    ];

    string[5] eyes = [
        "<rect x='209' y='262' width='145' height='15' fill='black'/><rect x='459' y='262' width='145' height='15' fill='black'/>",
        "<path d='M328 297.376C328 286.623 297.555 315.852 260 315.852C222.445 315.852 192 286.623 192 297.376C192 308.129 222.445 336.852 260 336.852C297.555 336.852 328 308.129 328 297.376Z' fill='black'/><path d='M485 297.376C485 286.623 515.445 315.852 553 315.852C590.555 315.852 621 286.623 621 297.376C621 308.129 590.555 336.852 553 336.852C515.445 336.852 485 308.129 485 297.376Z' fill='black'/>",
        "<line x1='250.657' y1='289.343' x2='310.657' y2='349.343' stroke='black' stroke-width='16'/><line y1='-8' x2='84.8528' y2='-8' transform='matrix(-0.707107 0.707107 0.707107 0.707107 316 295)' stroke='black' stroke-width='16'/><line x1='502.657' y1='289.343' x2='562.657' y2='349.343' stroke='black' stroke-width='16'/><line y1='-8' x2='84.8528' y2='-8' transform='matrix(-0.707107 0.707107 0.707107 0.707107 568 295)' stroke='black' stroke-width='16'/>",
        "<path d='M340.68 299.028C339.88 302.73 337.274 306.137 332.678 309.052C328.07 311.975 321.664 314.262 313.797 315.711C298.078 318.607 277.134 318.048 254.751 313.216C232.368 308.384 213.058 300.254 199.934 291.131C193.366 286.566 188.473 281.841 185.481 277.277C182.498 272.726 181.528 268.547 182.327 264.845C183.126 261.143 185.733 257.737 190.329 254.821C194.937 251.898 201.343 249.611 209.21 248.162C224.928 245.266 245.872 245.825 268.256 250.657C290.639 255.489 309.948 263.62 323.073 272.742C329.641 277.307 334.533 282.033 337.525 286.596C340.509 291.148 341.479 295.326 340.68 299.028Z' fill='#FEFEFE' stroke='black' stroke-width='6'/><path d='M340.996 297.562C339.437 304.784 331.419 310.854 317.654 313.974C304.153 317.034 286.22 316.94 267.114 312.816C248.008 308.691 231.633 301.379 220.597 293.023C209.344 284.502 204.544 275.665 206.103 268.443C207.662 261.221 215.68 255.151 229.446 252.031C242.946 248.971 260.879 249.065 279.985 253.189C299.091 257.314 315.467 264.626 326.502 272.982C337.755 281.503 342.555 290.34 340.996 297.562Z' fill='#5D605F' stroke='black' stroke-width='6'/><circle cx='292.016' cy='287.5' r='19' transform='rotate(12.1814 292.016 287.5)' fill='black'/><circle cx='280.726' cy='294.782' r='9.5' transform='rotate(12.1814 280.726 294.782)' fill='#F3F1F1'/><path d='M472.318 294.028C473.117 297.73 475.724 301.137 480.319 304.052C484.928 306.975 491.334 309.262 499.2 310.711C514.919 313.607 535.863 313.048 558.246 308.216C580.629 303.384 599.939 295.254 613.064 286.131C619.632 281.566 624.524 276.841 627.516 272.277C630.5 267.726 631.469 263.547 630.67 259.845C629.871 256.143 627.264 252.737 622.668 249.821C618.06 246.898 611.654 244.611 603.788 243.162C588.069 240.266 567.125 240.825 544.742 245.657C522.358 250.489 503.049 258.62 489.924 267.742C483.356 272.307 478.464 277.033 475.472 281.596C472.488 286.148 471.519 290.326 472.318 294.028Z' fill='#FEFEFE' stroke='black' stroke-width='6'/><path d='M472.001 292.562C473.56 299.784 481.578 305.854 495.344 308.974C508.844 312.034 526.777 311.94 545.883 307.816C564.989 303.691 581.365 296.379 592.4 288.023C603.653 279.502 608.453 270.665 606.894 263.443C605.335 256.221 597.317 250.151 583.552 247.031C570.051 243.971 552.118 244.065 533.012 248.189C513.906 252.314 497.531 259.626 486.495 267.982C475.242 276.503 470.442 285.34 472.001 292.562Z' fill='#5D605F' stroke='black' stroke-width='6'/><circle r='19' transform='matrix(-0.977484 0.211008 0.211008 0.977484 520.981 282.5)' fill='black'/><circle r='9.5' transform='matrix(-0.977484 0.211008 0.211008 0.977484 532.272 289.782)' fill='#F3F1F1'/>", //asian
        "<circle cx='281' cy='253' r='81' fill='#FEFEFE' stroke='black' stroke-width='6'/><circle cx='293' cy='253' r='69' fill='#0EB39F' stroke='black' stroke-width='6'/><circle cx='312' cy='258' r='19' fill='black'/><circle cx='302.5' cy='267.5' r='9.5' fill='#F3F1F1'/><circle r='81' transform='matrix(-1 0 0 1 532 253)' fill='#FEFEFE' stroke='black' stroke-width='6'/><circle r='69' transform='matrix(-1 0 0 1 520 253)' fill='#0EB29F' stroke='black' stroke-width='6'/><circle r='19' transform='matrix(-1 0 0 1 501 258)' fill='black'/><circle r='9.5' transform='matrix(-1 0 0 1 510.5 267.5)' fill='#F3F1F1'/>"
    ];

    string[3][1] colors = [
        [
            "<radialGradient id='fill_pattern' gradientUnits='userSpaceOnUse' ><stop offset='0%' stop-color='",
            "'/><stop offset='100%' stop-color='",
            "'/></radialGradient>"
        ]
    ];

    string[2][2] colorPalette = [
        ["#3A5BD0", "#D9FAFC"],
        ["#FCD9EC", "#D9FAFC"]
    ];

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function random(
        uint256 min,
        uint256 max,
        uint256 seed
    ) public pure returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(seed))) %
            (max - min);
        return randomnumber + min;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    //  Buy an NFT for 0.1 or x for 0.1 eth by x limitted to 5
    function mint() public payable {
        // require(msg.value >= price * qty, "!value");
        _mint(msg.sender, supply);
        supply = supply + 1;
    }

    function makeColorBackground(uint256 seed)
        public
        view
        returns (string memory)
    {
        string[2] memory color = colorPalette[
            (random(0, colorPalette.length, seed))
        ];
        string[3] memory background = colors[
            (random(0, colorPalette.length, seed))
        ];
        return
            string(
                abi.encodePacked(
                    background[0],
                    color[0],
                    background[1],
                    color[1],
                    background[2]
                )
            );
    }

    function generateSVG(uint256 seed) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg  xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 781 692'><path d='M379 635.808C379 644.683 371.885 657.004 358.174 667.49C344.761 677.747 326.145 685.308 305.5 685.308C284.79 685.308 263.422 677.655 247.301 665.46C231.124 653.222 221 637.059 221 620.308C221 618.538 221.446 617.58 221.92 616.968C222.448 616.289 223.418 615.522 225.232 614.853C229.069 613.439 235.043 613.041 242.812 613.446C249.683 613.805 257.247 614.737 264.933 615.684C265.763 615.786 266.595 615.888 267.427 615.99C275.801 617.016 284.322 617.998 291.5 617.998C305.029 617.998 327.978 618.16 347.47 621.136C357.273 622.632 365.695 624.771 371.51 627.671C377.464 630.64 379 633.466 379 635.808Z' fill='url(#fill_pattern)' stroke='black' stroke-width='12'/>  <path d='M433 635.511C433 644.387 440.115 656.708 453.826 667.194C467.239 677.451 485.855 685.011 506.5 685.011C527.21 685.011 548.578 677.359 564.699 665.164C580.876 652.926 591 636.762 591 620.011C591 618.242 590.554 617.284 590.08 616.672C589.553 615.992 588.582 615.225 586.769 614.557C582.932 613.142 576.957 612.744 569.188 613.15C562.317 613.509 554.753 614.44 547.067 615.387C546.237 615.489 545.406 615.592 544.573 615.694C536.199 616.719 527.678 617.702 520.5 617.702C506.971 617.702 484.022 617.864 464.531 620.839C454.727 622.336 446.305 624.475 440.49 627.375C434.536 630.344 433 633.169 433 635.511Z' fill='url(#fill_pattern)' stroke='black' stroke-width='12'/> <path d='M772.045 441.322C775.584 473.406 767.375 500.381 749.971 523.076C732.425 545.956 705.233 564.855 670.331 579.86C600.453 609.901 501.629 623.5 394.5 623.5C287.208 623.5 192.698 612.593 125.265 583.938C91.6375 569.648 65.1257 551.103 47.0303 527.66C29.0915 504.419 19.0857 475.934 19.0005 440.95C28.1375 366.412 69.2049 282.753 134.561 217.69C199.955 152.589 289.255 106.5 394.5 106.5C499.564 106.5 590.245 156.682 656.705 224.018C723.284 291.475 764.77 375.357 772.045 441.322Z' fill='url(#fill_pattern)' stroke='black' stroke-width='15'/>",
                    makeColorBackground(seed),
                    ears[random(0, ears.length, seed)],
                    eyes[random(0, eyes.length, seed)],
                    "</svg>"
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory image = generateSVG(_tokenId);
        string memory attributes = string(
            abi.encodePacked(
                '"}' // "attributes":[]}'
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    (
                        (
                            abi.encodePacked(
                                '{"name":"HELLO","image": ',
                                '"',
                                "data:image/svg+xml;utf8,",
                                image,
                                attributes
                            )
                        )
                    )
                )
            );
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

/*


███████╗██╗   ██╗███████╗██████╗ ██╗   ██╗    ██████╗  █████╗ ██╗   ██╗███████╗
██╔════╝██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
█████╗  ██║   ██║█████╗  ██████╔╝ ╚████╔╝     ██║  ██║███████║ ╚████╔╝ ███████╗
██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝      ██║  ██║██╔══██║  ╚██╔╝  ╚════██║
███████╗ ╚████╔╝ ███████╗██║  ██║   ██║       ██████╔╝██║  ██║   ██║   ███████║
╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                                               

*/

contract EVERYDAYZDATA {

     string[23] words = [
       "Bullish",
       "Bitcoin",
       "Ethereum",
       "EVERYDAYZ",
       "NFT",
       "GM",
       "GMI",
       "Surf",
       "love",
       "Only Up",
       "Only Down",
       "Satoshi",
       "Blue",
       "Aloha",
       "Survive",
       "Whale",
       "Shrimp",
       "Airdrop",
       "Gib",
       "Duvel",
       "Bear",
       "Bull",
       "F*CK"
    ];

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

