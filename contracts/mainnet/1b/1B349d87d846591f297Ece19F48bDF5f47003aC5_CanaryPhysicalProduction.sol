// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./ICanary.sol";

contract CanaryPhysicalProduction is ERC721 {
    using Strings for uint256;

    struct AttestationData {
        bytes32 attestationPayloadHash;
        string attestationPayload;
        uint256 attestationTimestamp;
    }

    // Constant Variables related to SVG Generation
    uint8 constant NO_OF_ROWS = 30;
    uint8 constant NO_OF_COLS = 30;
    uint8 constant ROW_START = 20;
    uint8 constant COL_START = 20;
    uint8 constant NO_OF_HAIRROWS = NO_OF_ROWS - ROW_START;
    uint8 constant NO_OF_HAIRCOLS = NO_OF_COLS - COL_START;

    uint16 constant ROW_HEIGHT = 10;
    uint16 constant COL_WIDTH = 10;

    string internal constant PLACEHOLDER_SVG_PRE =
       '<svg width=\"620\" height=\"620\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 300 300\"><defs><filter id=\"a\"><feComponentTransfer><feFuncA type=\"discrete\" tableValues=\"0 1\"/></feComponentTransfer><feGaussianBlur stdDeviation=\"23\"/></filter></defs><path stroke=\"#000\" stroke-width=\"8\" fill-opacity=\"10%\" filter=\"url(#a)\" d=\"M0 0h300v300H0z\"/><text style=\"font:38px monospace\" x=\"50%\" y=\"50%\" text-anchor=\"middle\">';

    string internal constant MUNDI_PRE =
        '<svg width=\"620\" height=\"620\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"-10 -20 320 320\">';

    string internal constant MUNDI_MID =
        '<rect id=\"bg\" x=\"-10\" y=\"-20\" width=\"320\" height=\"320\"/> <g id=\"hair\"> <rect x=\"40\" y=\"160\" width=\"10\" height=\"10\"/> <polygon points=\"90,220 90,210 80,210 80,200 70,200 70,210 60,210 60,200 70,190 70,160 80,160 80,150 70,150 60,140 50,150 60,160 60,190 50,190 50,180 40,180 40,190 30,190 30,200 50,200 50,210 30,210 30,220 50,220 50,230 30,230 30,240 40,250 50,250 50,260 30,260 30,280 20,290 10,290 10,300 60,300 60,280 100,280 100,230\"/> <polygon points=\"100,60 100,50 90,50 90,40 80,40 80,60 70,70 60,70 60,100 50,110 50,120 60,130 70,130 70,120 80,120 80,140 90,130 90,80 100,80 100,70 110,70 110,60\"/> <rect x=\"80\" y=\"290\" width=\"10\" height=\"10\"/> <polygon points=\"110,120 110,130 100,140 100,120\"/> <polygon points=\"120,20 120,30 110,40 90,40 90,30 110,30 110,20\"/> <rect x=\"150\" y=\"140\" width=\"10\" height=\"10\"/> <rect x=\"160\" y=\"180\" width=\"10\" height=\"10\"/> <polygon points=\"240,90 230,100 220,100 220,90 210,90 210,80 200,80 200,70 190,60 190,50 170,50 160,40 150,40 150,30 160,30 160,20 150,20 150,30 140,30 140,40 130,40 130,10 170,10 170,30 180,30 180,20 190,20 200,30 190,30 190,40 200,40 210,50 220,50 220,60 230,70 230,80\"/> <polygon points=\"260,290 260,300 250,300 250,290 240,290 230,280 230,270 240,270 240,280 250,280\"/> <polygon points=\"250,230 250,240 260,240 260,250 270,260 280,260 280,270 270,270 270,280 250,280 250,260 240,260 240,250 230,250 230,240 240,240 240,210 230,210 230,190 220,180 210,180 210,140 200,140 200,130 180,130 180,120 190,120 200,110 210,110 210,100 220,100 220,120 230,120 230,140 240,150 230,160 230,170 250,190 260,190 260,210 250,210 250,220 260,220 260,210 270,200 280,200 280,210 270,210 270,230\"/> <rect x=\"270\" y=\"290\" width=\"10\" height=\"10\"/> <rect x=\"290\" y=\"290\" width=\"10\" height=\"10\"/> <polygon points=\"220,190 220,200 210,210 210,220 200,230 200,240 210,240 210,250 200,250 200,270 210,280 210,290 200,300 190,300 180,290 180,280 160,280 160,270 150,260 140,260 140,280 130,280 130,270 120,260 120,250 140,250 145,245 150,250 170,250 170,240 180,240 180,230 190,230 190,220 200,220 200,210 190,210 190,200 210,200 210,190\"/> </g> <g id=\"bg\"> <rect x=\"40\" y=\"280\" width=\"10\" height=\"10\"/> <rect x=\"60\" y=\"220\" width=\"10\" height=\"10\"/> <polygon points=\"90,260 80,270 60,270 60,260 70,260 70,240 80,240 80,250 90,250\"/> <rect x=\"70\" y=\"90\" width=\"10\" height=\"10\"/> </g> <g id=\"skin\"> <rect x=\"30\" y=\"220\" width=\"10\" height=\"10\"/> <rect x=\"60\" y=\"260\" width=\"10\" height=\"10\"/> <polygon points=\"70,190 70,210 60,210 60,200\"/> <rect x=\"120\" y=\"20\" width=\"10\" height=\"10\"/> <rect x=\"130\" y=\"180\" width=\"10\" height=\"10\"/> <rect x=\"240\" y=\"260\" width=\"10\" height=\"10\"/> <polygon points=\"260,280 260,290 250,280\"/> <polygon points=\"100,110 100,140 90,140 80,150 80,140 90,130 90,110\"/> <polygon points=\"100,230 90,220 90,210 80,210 80,170 90,170 90,200 100,210 110,210 120,220 120,260 130,270 130,280 140,280 140,260 150,260 150,270 160,270 160,280 180,280 180,290 190,300 90,300 90,280 100,280\"/> <polygon points=\"130,30 130,50 120,50 110,60 100,60 100,50 90,50 90,40 110,40 120,30\"/> <polygon points=\"140,120 130,120 120,130 110,130 110,110 130,110\"/> <polygon points=\"170,160 170,180 160,180 160,160 150,160 150,150 160,150\"/> <polygon points=\"210,80 210,110 200,110 190,120 180,120 180,130 200,130 200,160 190,150 180,150 180,140 170,130 160,130 160,120 170,110 170,100 180,100 180,110 190,110 200,100 200,80\"/> <polygon points=\"200,210 200,220 190,220 190,230 180,230 180,240 170,240 170,230 130,230 130,220 160,220 160,210 170,210 170,220 180,220 180,210 170,200 140,200 140,190 170,190 180,200 190,200 190,210\"/> <polygon points=\"210,170 210,200 190,200 200,190 200,180\"/> <polygon points=\"250,140 250,150 240,150 230,140 230,120 240,120 240,140\"/> </g> <g id=\"skin-in\"> <polygon points=\"170,230 170,250 150,250 145,245 140,250 120,250 120,220 110,210 100,210 90,200 90,170 80,170 80,150 90,140 100,140 110,130 120,130 130,120 140,120 140,130 130,130 130,140 120,140 120,150 90,150 90,160 100,170 100,180 120,200 130,200 135,205 130,210 130,240 140,240 140,230\"/> <polygon points=\"140,170 140,180 130,180\"/> <rect x=\"140\" y=\"30\" width=\"10\" height=\"10\"/> <polygon points=\"120,100 120,110 110,110 110,120 100,120 100,110 90,110 90,100\"/> <polygon points=\"180,210 180,220 170,220 170,210 160,210 160,220 140,220 140,210 150,210 150,200 170,200\"/> <polygon points=\"160,160 160,190 140,190 140,180 150,180 150,160\"/> <polygon points=\"180,140 180,150 170,150 170,140 150,140 150,120 160,110 160,100 170,100 170,110 160,120 160,130 170,130\"/> <polygon points=\"200,70 200,100 190,110 180,110 180,100 190,90 190,80 180,70 180,60 170,50 190,50 190,60\"/> <polygon points=\"210,140 210,170 200,180 200,190 190,200 180,200 170,190 170,160 180,170 180,190 190,190 190,170 195,165 200,170 200,140\"/> </g> <g id=\"skin-in-in\"> <rect x=\"130\" y=\"230\" width=\"10\" height=\"10\"/> <polygon points=\"110,100 90,100 90,80 100,80 100,90\"/> <polygon points=\"130,180 130,190 140,190 140,200 150,200 150,210 140,210 140,220 130,220 130,210 135,205 130,200 120,200 100,180 100,170 110,170 110,180 120,180 120,170 130,160 130,150 120,150 120,140 130,140 130,130 140,130 140,140 150,140 150,150 140,150 140,170\"/> <polygon points=\"190,80 190,90 180,100 160,100 160,110 150,120 140,120 130,110 120,110 120,100 140,100 140,110 150,110 150,100 160,90 170,90 170,80 160,80 160,70 170,60 160,50 160,40 180,60 180,70\"/> <polygon points=\"200,160 200,170 195,165 190,170 190,190 180,190 180,170 160,150 160,140 170,140 170,150 190,150\"/> </g> <polygon id=\"skin-core\" points=\"150,40 150,70 140,70 140,90 130,100 120,100 120,90 125,85 120,80 120,70 110,70 110,60 120,50 130,50 130,40 \"/> <g id=\"skin-apex\"> <polygon points=\"130,150 130,160 120,170 120,180 110,180 110,170 100,170 90,160 90,150\"/> <polygon points=\"125,85 120,90 120,100 110,100 100,90 100,70 120,70 120,80\"/> <polygon points=\"160,80 170,80 170,90 160,90 150,100 150,110 140,110 140,100 130,100 140,90 140,70 150,70 150,40 160,40 160,50 170,60 160,70\"/> <rect x=\"140\" y=\"120\" width=\"10\" height=\"20\"/> <rect x=\"140\" y=\"150\" width=\"10\" height=\"30\"/> </g><g id=\"hair\">';

    string internal constant MUNDI_POST = "</svg>";

    uint8[12][12] internal HAIR_MASK = [
        // ˅ first col is a border        // ˅ last col is also a border
        [1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0], // first row is a border
        [1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0] // last row is border
    ];

    string[] colors = [
        "#3C5F94", "#444444", "#485872", "#73A9FB", "#74E186", "#7C6290", "#935E9B", "#9CD654", "#A7CD76", "#B0A794", "#CA93D1", "#DBCDB3", "#DEAD6E", "#252929", "#EB9792", "#FFA24D",
        "#97C8B7", "#9AB8C7", "#9FD3C1", "#A3C0B6", "#A7B9C2", "#A8CCC0", "#ABCADA", "#B2C9D4", "#BCCCC8", "#BCDDD2", "#C2DED7", "#CEDAE0", "#CEE5DD", "#D5E3EA", "#D9E6ED", "#E1EBF0",
        "#215575", "#264659", "#334C5B", "#3E8195", "#417180", "#497886", "#50855C", "#58849D", "#59839A", "#5E956B", "#5EA16E", "#5EA970", "#68A476", "#6A9C76", "#70B07F", "#72BA83",
        "#64C795", "#67B490", "#6CBF9A", "#72C09C", "#7598A6", "#7998A5", "#7C99A9", "#7CA2B8", "#81A1AE", "#829EAE", "#84A7B5", "#86A6B9", "#86CFAD", "#87ACA0", "#8BB1A5", "#97B8AE",
        "#508DA4", "#528193", "#528F8F", "#5592A3", "#55A184", "#5689A5", "#58A57B", "#599DB0", "#5A937C", "#5C9AAB", "#608A8A", "#608AA0", "#6491A1", "#649C7D", "#699B9B", "#6CA38F",
        "#1F5271", "#26607A", "#2A6886", "#2A728F", "#335C6F", "#33936D", "#36809F", "#376C88", "#3F915E", "#407A56", "#42805E", "#446967", "#4D788F", "#558C6C", "#5A8877", "#5F937E",
        "#33588F", "#36383A", "#3D387E", "#3E7976", "#4F76B0", "#693771", "#769054", "#7AAB3A", "#95815B", "#97589F", "#A6625D", "#A99A7C", "#AA545D", "#B08751", "#BD55A6", "#CA8749"
    ];

    // Attestation related variables
    mapping(bytes32 => bool) public hashExists;
    mapping(uint256 => AttestationData) internal _tokenIdToAttestationData;
    address public immutable CANARY_ADDRESS;

    constructor(
        string memory name,
        string memory symbol,
        address canaryAddress
    ) ERC721(name, symbol) {
        CANARY_ADDRESS = canaryAddress;
    }

    // Public Functions

    /// @notice Returns attestation data
    function getAttestationData(uint256 tokenId)
        public
        view
        returns (
            string memory attestationPayload,
            bytes32 attestationPayloadHash,
            uint256 attestationTimestamp
        )
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return (
            _tokenIdToAttestationData[tokenId].attestationPayload,
            _tokenIdToAttestationData[tokenId].attestationPayloadHash,
            _tokenIdToAttestationData[tokenId].attestationTimestamp
        );
    }

  /// @dev Token URI including the image SVG data is dynamically generated
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_tokenIdToAttestationData[tokenId].attestationTimestamp == 0) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Physical Production Rights of The Greats #',
                                tokenId.toString(),
                                '", ',
                                '"image":"',
                                generatePlaceholderSvg(tokenId),
                                '" }'
                            )
                        )
                ));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Attestation of the Physical Production of The Greats #',
                            tokenId.toString(),
                            '", ',
                            '"image":"',
                            renderSVGFromHash(
                                _tokenIdToAttestationData[tokenId].attestationPayloadHash,
                                tokenId
                            ),
                            '", ',
                            '"attestation_timestamp":"',
                            _tokenIdToAttestationData[tokenId].attestationTimestamp.toString(),
                            '", ',
                            '"attestation_payload_base64":"',
                            Base64.encode(abi.encodePacked(_tokenIdToAttestationData[tokenId].attestationPayload)),
                            '" }'
                        )
                    )
                ));
    }

    // External Functions

    /// @notice Mints an Physical Production token for the corresponding Canary token ID
    function mint(uint256 canaryTokenId) external {
        require(!_exists(canaryTokenId), "Already minted");

        address owner = ICanary(CANARY_ADDRESS).ownerOf(canaryTokenId);

        require(owner == msg.sender, "Caller is not the owner of the token");
        require(
            ICanary(CANARY_ADDRESS).metadataAssigned(canaryTokenId),
            "Metadata is not assigned to the token yet"
        );

        _safeMint(msg.sender, canaryTokenId);
    }

    /// @notice Attestation is done by storing a payload that represents the attestation proof to the metadata of the token ID
    /// @dev Can only attest once for a particular Physical Production token
    function attest(uint256 tokenId, string memory payload) external {
        require(_exists(tokenId), "Token does not exist");
        require(
            _tokenIdToAttestationData[tokenId].attestationTimestamp == 0,
            "Attestation already done for this token ID"
        );
        require(bytes(payload).length > 0, "Payload string cannot be empty");

        bytes32 payloadHash = keccak256(abi.encodePacked(payload));

        require(hashExists[payloadHash] == false, "Hash already exists");

        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");

        hashExists[payloadHash] = true;
        _tokenIdToAttestationData[tokenId] = AttestationData(
            payloadHash,
            payload,
            block.timestamp
        );
    }

    // Internal Functions

    /// @dev Renders Mundi SVG dynamically based on the Keccak-256 hash of the attestation payload
    function renderSVGFromHash(bytes32 attestationPayloadHash, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint8[10][10] memory hairMap;

        // First 75 bits of the following are used
        uint8[256] memory hashInBinary = toBinaryArray(abi.encodePacked(attestationPayloadHash));

        uint256 bitOffset;

        for (uint8 row = 0; row < NO_OF_HAIRROWS; row++) {
            for (uint8 col = 0; col < NO_OF_HAIRCOLS; col++) {
                uint8 hairMaskV = HAIR_MASK[row + 1][col + 1];
                if (hairMaskV == 0) {
                    hairMap[row][col] = 0;
                } else {
                    hairMap[row][col] = hashInBinary[bitOffset++];
                }
            }
        }

        string memory tokenNumberRender = string(
            abi.encodePacked(
                '<text text-rendering=\"geometricPrecision\" font-family=\"Mundi\" font-size=\"25\" text-anchor=\"end\" x=\"300\" y=\"16\" id=\"number\">#', tokenId.toString(),
                "</text>"
            )
        );

        string
            memory hairSvg = '<rect x=\"200\" y=\"200\" width=\"100\" height=\"100\" id=\"bg\"/>';

        for (uint8 row = 0; row < NO_OF_HAIRROWS; row++) {
            for (uint8 col = 0; col < NO_OF_HAIRCOLS; col++) {
                uint8 hairMaskV = HAIR_MASK[row + 1][col + 1];
                if (hairMaskV == 0) continue;
                if (hairMap[row][col] == 0) continue;

                bool isTop = row == 0;
                bool isLeft = col == 0;
                bool isRight = col == NO_OF_HAIRCOLS - 1;
                bool isBottom = row == NO_OF_HAIRROWS - 1;

                uint8 top = isTop ? HAIR_MASK[row][col + 1] : hairMap[row - 1][col];
                uint8 left = isLeft ? HAIR_MASK[row + 1][col] : hairMap[row][col - 1];
                uint8 right = isRight ? HAIR_MASK[row + 1][col + 2] : hairMap[row][col + 1];
                uint8 bottom = isBottom ? HAIR_MASK[row + 2][col + 1] : hairMap[row + 1][col];

                hairSvg = string(
                    abi.encodePacked(
                        hairSvg,
                        generateHairPoint(col, row, top, left, right, bottom)
                    )
                );
            }
        }
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            MUNDI_PRE,
                            generateStylesheet(attestationPayloadHash),
                            MUNDI_MID,
                            hairSvg,
                            "</g>",
                            tokenNumberRender,
                            MUNDI_POST
                        )
                    )
                ));
    }

    // Internal functions

    /// @dev Renders the SVG hair component
    function generateHairPoint(
        uint8 col,
        uint8 row,
        uint8 top,
        uint8 left,
        uint8 right,
        uint8 bottom
    ) internal pure returns (string memory) {
        uint256 x = (col + COL_START) * COL_WIDTH;
        uint256 y = (row + ROW_START) * ROW_HEIGHT;

        string memory topLeft = string(abi.encodePacked(x.toString(), ",", y.toString()));
        string memory topRight = string(
            abi.encodePacked((x + COL_WIDTH).toString(), ",", y.toString())
        );
        string memory bottomLeft = string(
            abi.encodePacked(x.toString(), ",", (y + ROW_HEIGHT).toString())
        );
        string memory bottomRight = string(
            abi.encodePacked((x + COL_WIDTH).toString(), ",", (y + ROW_HEIGHT).toString())
        );

        string memory points;

        // if it's a diagonal, round the corner
        if (top != 0 && right != 0 && bottom == 0 && left == 0) {
            points = string(abi.encodePacked(topLeft, " ", topRight, " ", bottomRight));
        } else if (right != 0 && bottom != 0 && left == 0 && top == 0) {
            points = string(abi.encodePacked(topRight, " ", bottomRight, " ", bottomLeft));
        } else if (bottom != 0 && left != 0 && top == 0 && right == 0) {
            points = string(abi.encodePacked(bottomRight, " ", bottomLeft, " ", topLeft));
        } else if (left != 0 && top != 0 && right == 0 && bottom == 0) {
            points = string(abi.encodePacked(bottomLeft, " ", topLeft, " ", topRight));
        } else {
            points = string(
                abi.encodePacked(topLeft, " ", topRight, " ", bottomRight, " ", bottomLeft)
            );
        }

        return string(abi.encodePacked('<polygon points=\"', points, '\" id=\"hair\" />'));
    }

    /// @dev Converts bytes array into an integer array that represents corresponding binary representation
    function toBinaryArray(bytes memory b) internal pure returns (uint8[256] memory binary) {
        for (uint256 i = 0; i < 32; i++) {

            // Since each byte1 represents two hexadecimal chars, it needs to be split
            bytes1 rightHexByte = b[i] & 0x0F;
            bytes1 leftHexByte = b[i] >> 4;

            uint256 n = hexadecimalCharToInteger(leftHexByte);
            for (uint8 k = 0; k < 4; k++) {
                binary[3 + (8 * i) - k] = (n % 2 == 1) ? 1 : 0;
                n /= 2;
            }
            n = hexadecimalCharToInteger(rightHexByte);
            for (uint8 k = 0; k < 4; k++) {
                binary[7 + (8 * i) - k] = (n % 2 == 1) ? 1 : 0;
                n /= 2;
            }
        }
    }

    /**
     * @dev Generates the SVG stylesheet consisting of a deterministic color palette.
     * Composes the color palette based on last 7 bytes of the SHA-256 hash string.
     */
    function generateStylesheet(bytes32 attestationPayloadHash) internal view returns (string memory) {
        bytes memory b = abi.encodePacked(attestationPayloadHash);
        string[7] memory colorPalette;

        for (uint256 i = 0; i < 4; i++) {
            // Since each byte1 represents two hexadecimal chars, it needs to be split
            bytes1 leftHexByte = b[31 - i] >> 4;
            bytes1 rightHexByte = b[31 - i] & 0x0F;

            colorPalette[i * 2] = colors[((i * 2) * 16) + hexadecimalCharToInteger(rightHexByte)];
            if (i < 3) {
                colorPalette[(i * 2) + 1] = colors[(((i * 2) + 1) * 16) + hexadecimalCharToInteger(leftHexByte)];
            }
        }

        // Splitting as a workaround to stack too deep error
        string memory part1 = string(
            abi.encodePacked(
                "<style>#bg { fill: ",
                colorPalette[0],
                "; }",
                "#skin-apex { fill: ",
                colorPalette[1],
                "; }",
                "#skin-core { fill: ",
                colorPalette[2],
                "; }"
            )
        );

        string memory part2 = string(
            abi.encodePacked(
                "#skin-in-in { fill: ",
                colorPalette[3],
                "; }",
                "#skin-in { fill: ",
                colorPalette[4],
                "; }",
                "#skin { fill: ",
                colorPalette[5],
                "; }",
                "#hair { fill: ",
                colorPalette[6],
                "; }",
                "#number { font: 35px monospace; fill: #ffffff; font-smooth: never; -webkit-font-smoothing: none; }",
                "</style>"
            )
        );

        return string(abi.encodePacked(part1, part2));
    }

    /// @dev Converts Hexadecimal char to an integer (0 to 15)
    function generatePlaceholderSvg(uint256 tokenId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(abi.encodePacked(PLACEHOLDER_SVG_PRE, "#", tokenId.toString(), "</text></svg>"))
                )
            );
    }

    /// @dev Converts Hexadecimal char to an integer (0 to 15)
    function hexadecimalCharToInteger(bytes1 char) internal pure returns (uint256) {
        bytes1[16] memory alphabets = [
            bytes1(0x00),
            bytes1(0x01),
            bytes1(0x02),
            bytes1(0x03),
            bytes1(0x04),
            bytes1(0x05),
            bytes1(0x06),
            bytes1(0x07),
            bytes1(0x08),
            bytes1(0x09),
            bytes1(0x0a),
            bytes1(0x0b),
            bytes1(0x0c),
            bytes1(0x0d),
            bytes1(0x0e),
            bytes1(0x0f)
        ];
        for (uint256 i = 0; i < 16; i++) {
            if (char == alphabets[i]) {
                return i;
            }
        }
        revert("Input is not a hexadecimal char");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _ALPHABET = "0123456789abcdef";

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
            buffer[i] = _ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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
     * plain`call` is an unsafe replacement for a function call: use this
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

import "./IERC721.sol";

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

import "./IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/IERC165.sol";

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

import "./IERC721Enumerable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ICanary is IERC721Enumerable {
    function MAX_SUPPLY() external view returns (uint256 maxSupply);
    
    function tokenIdToMetadataIndex(uint256 tokenId) external view returns (uint256 metadataIndex);

    function metadataAssigned(uint256 tokenId) external view returns (bool assigned);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./utils/ERC165.sol";
import "./utils/Address.sol";
import "./utils/EnumerableSet.sol";
import "./utils/EnumerableMap.sol";
import "./utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}