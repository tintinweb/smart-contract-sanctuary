// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBallerBars.sol";
import "./ChainsLibrary.sol";
import "./IChains.sol";
import "./IChainsTraits.sol";

contract Chains is ERC721Enumerable, Ownable {

    /**

     _______  ________ __    __      _______   ______  __       __       ________ _______
    |       \|        \  \  |  \    |       \ /      \|  \     |  \     |        \       \
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓    | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     | ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓__   | ▓▓▓\| ▓▓    | ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓     | ▓▓     | ▓▓__   | ▓▓__| ▓▓
    | ▓▓    ▓▓ ▓▓  \  | ▓▓▓▓\ ▓▓    | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓     | ▓▓  \  | ▓▓    ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓  | ▓▓\▓▓ ▓▓    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓ \▓▓▓▓    | ▓▓__/ ▓▓ ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓_____| ▓▓  | ▓▓
    | ▓▓    ▓▓ ▓▓     \ ▓▓  \▓▓▓    | ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     \ ▓▓  | ▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓

     _______  ______ _______       ________ __    __ ________
    |       \|      \       \     |        \  \  |  \        \
    | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\     \▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓__| ▓▓ ▓▓__
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓    ▓▓ ▓▓  \
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓
    | ▓▓__/ ▓▓_| ▓▓_| ▓▓__/ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓_____
    | ▓▓    ▓▓   ▓▓ \ ▓▓    ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓     \
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓         \▓▓   \▓▓   \▓▓\▓▓▓▓▓▓▓▓

     _______  __        ______   ______  __    __  ______  __    __  ______  ______ __    __
    |       \|  \      /      \ /      \|  \  /  \/      \|  \  |  \/      \|      \  \  |  \
    | ▓▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ /  ▓▓  ▓▓▓▓▓▓\ ▓▓  | ▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓\ | ▓▓
    | ▓▓__/ ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓   \▓▓ ▓▓/  ▓▓| ▓▓   \▓▓ ▓▓__| ▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓▓\| ▓▓
    | ▓▓    ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓     | ▓▓    ▓▓ ▓▓    ▓▓ | ▓▓ | ▓▓▓▓\ ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓     | ▓▓  | ▓▓ ▓▓   __| ▓▓▓▓▓\ | ▓▓   __| ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓\▓▓ ▓▓
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓__/ ▓▓ ▓▓__/  \ ▓▓ \▓▓\| ▓▓__/  \ ▓▓  | ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓ \▓▓▓▓
    | ▓▓    ▓▓ ▓▓     \\▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓\\▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓  \▓▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓\▓▓▓▓▓▓\▓▓   \▓▓

    **/

    // RGV2YmVycnkjNDAzMCBhbmQgcG9ua3lwaW5rIzc5MTMgd2VyZSBoZXJl

    using ChainsLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
        string pixels;
        uint256 pixelCount;
    }

    // Mappings
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(uint256 => uint256) internal tokenIdToTimestamp;

    // uint256s
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 SEED_NONCE = 0;

    // Addresses
    address _genOneChainsAddress;
    address _genOneBallerBarsAddress;
    address _genTwoBallerBarsAddress;

    bool public _paused = true;

    uint256 public _combinedTotalSupply = 3406;

    uint256 _reserveMinted = 0;

    constructor() ERC721("Chains", "CHAIN") {}

    function rarityGen0(uint256 r) private pure returns (uint256) {
        if (r >= 330)    {return 4;}
        if (r >= 150)    {return 3;}
        if (r >=  30)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen1(uint256 r) private pure returns (uint256) {
        if (r >= 504)    {return 9;}
        if (r >= 414)    {return 8;}
        if (r >= 330)    {return 7;}
        if (r >= 252)    {return 6;}
        if (r >= 180)    {return 5;}
        if (r >= 114)    {return 4;}
        if (r >=  54)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen2(uint256 r) private pure returns (uint256) {
        if (r >= 471)    {return 9;}
        if (r >= 372)    {return 8;}
        if (r >= 285)    {return 7;}
        if (r >= 207)    {return 6;}
        if (r >= 135)    {return 5;}
        if (r >=  69)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen3(uint256 r) private pure returns (uint256) {
        if (r >= 462)    {return 7;}
        if (r >= 336)    {return 6;}
        if (r >= 222)    {return 5;}
        if (r >= 120)    {return 4;}
        if (r >=  33)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen4(uint256 r) private pure returns (uint256) {
        if (r >=  93)    {return 7;}
        if (r >=  63)    {return 6;}
        if (r >=  45)    {return 5;}
        if (r >=  33)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }
    function rarityGen5(uint256 r) private pure returns (uint256) {
        if (r >=  93)    {return 7;}
        if (r >=  63)    {return 6;}
        if (r >=  45)    {return 5;}
        if (r >=  33)    {return 4;}
        if (r >=  21)    {return 3;}
        if (r >=   9)    {return 2;}
        if (r >=   3)    {return 1;}
        return 0;
    }

    function hash(
        uint256 _t,
        address _a
    ) internal returns (string memory) {
        // This will generate a 7 character string.
        // The last 6 digits are random, the first is 0, due to the chain is not being burned.
        SEED_NONCE++;

        bytes memory buffer = new bytes(7);
        buffer[0] = bytes1(uint8(48));

    unchecked {
        for (uint _c=0; _c<4; _c++) {
            uint256 _largeRandom =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _t,
                        _a,
                        _c,
                        SEED_NONCE
                    )
                )
            );


            for (uint i=0; i<4; i++) {
                buffer[1] = bytes1(uint8(48 + rarityGen0(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[2] = bytes1(uint8(48 + rarityGen1(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[3] = bytes1(uint8(48 + rarityGen2(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[4] = bytes1(uint8(48 + rarityGen3(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[5] = bytes1(uint8(48 + rarityGen4(_largeRandom % 600)));
                _largeRandom /= 600;
                buffer[6] = bytes1(uint8(48 + rarityGen5(_largeRandom % 600)));

                string memory currentHash = string(buffer);

                if (hashToMinted[currentHash] == false) {
                    return currentHash;
                }

                _largeRandom /= 600;
            }
        }

        // use background 4
        buffer[6] = bytes1(uint8(48 + 4));
    }
        return string(buffer);
    }

    /**
     * @dev Returns the current baller bar cost of a mint.
     */

    function currentBallerBarsCost() public view returns (uint256) {
        uint256 _totalSupply = _combinedTotalSupply;
        if (_totalSupply <= 3000)
            return 4 ether;
        if (_totalSupply > 3000 && _totalSupply <= 4000)
            return 8 ether;
        if (_totalSupply > 4000 && _totalSupply <= 5000)
            return 16 ether;
        return 24 ether;
    }

    /**
     * @dev Mint reserve. Owner only, for giveaways and tests
     * @param tokenQuantity Quantity of tokens
     */

    function mintReserve(uint256 tokenQuantity) onlyOwner external  {
        require(_reserveMinted+tokenQuantity<7,"EXCEEDS_RESERVE_MINTS");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            ++_reserveMinted;
            mintInternal();
        }
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */

    function mintInternal() internal {
        require(_combinedTotalSupply < MAX_SUPPLY);
        require(tx.origin == msg.sender);

        uint256 thisTokenId = _combinedTotalSupply;

        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender);

        hashToMinted[tokenIdToHash[thisTokenId]] = true;

        tokenIdToTimestamp[thisTokenId] = block.timestamp;

        _combinedTotalSupply++;
        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mint for BallerBars
     * @param ballerBarsGeneration The generation of Baller Bars to use.
     */

    function mintWithBallerBars(uint256 ballerBarsGeneration) public {
        require(_paused==false,"PAUSED");
        IBallerBars ballerBarsContract = getBallerBarsContract(ballerBarsGeneration);
        ballerBarsContract.burnFrom(msg.sender, currentBallerBarsCost());
        mintInternal();
    }

    /**
     * @dev Mint for BallerBars with both BallerBars generation one and generation 2
     * @param bbOneAmount The amount of BB generation one to burn
     * @param bbOneAmount The amount of BB generation two to burn
     */

    function mintWithBallerBarsSpecial(uint256 bbOneAmount, uint256 bbTwoAmount) public {
        require(_paused==false,"PAUSED");
        require(bbOneAmount+bbTwoAmount==currentBallerBarsCost(),"INVALID_COMBINATION");

        IBallerBars ballerBarsGenOneContract = IBallerBars(_genOneBallerBarsAddress);
        IBallerBars ballerBarsGenTwoContract = IBallerBars(_genTwoBallerBarsAddress);

        ballerBarsGenOneContract.burnFrom(msg.sender, bbOneAmount);
        ballerBarsGenTwoContract.burnFrom(msg.sender, bbTwoAmount);

        mintInternal();
    }

    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }

    /**
     * @dev Burns previous generation chain and mints new one.
     * @param _tokenId The token to burn.
     */

    function burnGenOneForMint(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");
        IChains chainsGenOne = IChains(_genOneChainsAddress);

        hashToMinted[chainsGenOne._tokenIdToHash(_tokenId)] = true;

        //Burn token
        chainsGenOne.transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        mintInternal();
    }

    /**
     * @dev Migrates previous generation chain to this one.
     * @param _tokenId The token to migrate
     */

    function migrateGenOne(uint256 _tokenId) public {
        require(_paused==false,"PAUSED");
        migrate(_tokenId);
    }

    /**
     * @dev Migrates previous generation chain
     * @param _tokenId The token to migrate
     */

    function migrate(uint _tokenId) internal {
        require(_tokenId < 3406, "TOKEN_ID_TOO_HIGH");

        IChains chainsGenOne = IChains(_genOneChainsAddress);

        tokenIdToHash[_tokenId] = chainsGenOne._tokenIdToHash(_tokenId);
        hashToMinted[tokenIdToHash[_tokenId]] = true;

        tokenIdToTimestamp[_tokenId] = chainsGenOne.getTokenTimestamp(_tokenId);

        //Burn token
        chainsGenOne.transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        _mint(msg.sender, _tokenId);
    }

    /**
     * @dev Hash to SVG function
     */

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory svgString;

        string memory bgString;
        string memory bgColor;
        //

        bool[24][24] memory placedPixels;

        uint8 bgIndex =  ChainsLibrary.parseInt(ChainsLibrary.substring(_hash, 6, 7)); // BG

        if ( bgIndex == 0 ) {
            bgColor = "2596be";
        } else if ( bgIndex == 1 ) {
            bgColor = "10447c";
        } else if ( bgIndex == 2 ) {
            bgColor = "c8fcfc";
        } else if ( bgIndex == 3 ) {
            bgColor = "383434";
        } else if ( bgIndex == 4 ) {
            bgColor = "ffe4bc";
        } else if ( bgIndex == 5 ) {
            bgColor = "d0ccfc";
        }else if ( bgIndex == 6 ) {
            bgColor = "e0dcdc";
        }

        if ( bgIndex < 7 ) { // bg color 7 is none
            bgString = string(
                    abi.encodePacked(
                        'style="background-color:#',
                        bgColor,
                        '" '
                    )
                );
        } else {
            bgString = "";
        }

        for (uint8 i = 0; i < 6; i++) {  // 7 (we should skip BG here, so 6 will be final)
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            (,,string memory pixels,uint256 pixelCount)= IChainsTraits(_genOneChainsAddress).traitTypes(i, thisTraitIndex);

            for (
                uint16 j = 0;
                j < pixelCount; // <
                j++
            ) {
                string memory thisPixel = ChainsLibrary.substring(
                    pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = uint8(bytes(thisPixel)[0]) - 96;
                uint8 y = uint8(bytes(thisPixel)[1]) - 96;

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        ChainsLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="c" xmlns="http://www.w3.org/2000/svg" ',
                'preserveAspectRatio="xMinYMin meet" viewBox="0 0 26 26" ',
                bgString,
                ' > ',
                svgString,
                '<style>rect{width:1px;height:1px;}#c{shape-rendering: crispedges;}.c00{fill:#d844cf}.c01{fill:#f1f1f1}.c02{fill:#ff4b54}.c03{fill:#ff6b71}.c04{fill:#ff5c64}.c05{fill:#ff132f}.c06{fill:#ff4651}.c07{fill:#ff444f}.c08{fill:#ff3644}.c09{fill:#ff3543}.c10{fill:#ff3845}.c11{fill:#ff4d57}.c12{fill:#c146fb}.c13{fill:#333aff}.c14{fill:#c2defc}.c15{fill:#eaf4ff}.c16{fill:#e3eefa}.c17{fill:#cfe4fa}.c18{fill:#b61ffc}.c19{fill:#bf42fb}.c20{fill:#bc35fb}.c21{fill:#bd36fb}.c22{fill:#fee4bf}.c23{fill:#ff8800}.c24{fill:#ffd300}.c25{fill:#ffc200}.c26{fill:#ff9a00}.c27{fill:#ffb100}.c28{fill:#ffa000}.c29{fill:#f6d900}.c30{fill:#f0ce00}.c31{fill:#eed100}.c32{fill:#00e58b}.c33{fill:#00df71}.c34{fill:#00e280}.c35{fill:#00cb59}.c36{fill:#00d874}.c37{fill:#00d963}.c38{fill:#00d36c}.c39{fill:#00de7c}.c40{fill:#ebb7a5}.c41{fill:#e3aa96}.c42{fill:#094378}.c43{fill:#c1a900}.c44{fill:#dcc000}.c45{fill:#fade11}.c46{fill:#f8dc09}.c47{fill:#00c5e6}.c48{fill:#dcdcdc}.c49{fill:#c1f8f9}.c50{fill:#b2b8b9}.c51{fill:#aab0b1}.c52{fill:#b0b4b5}.c53{fill:#e2a38d}.c54{fill:#eba992}.c55{fill:#e8b2a0}.c56{fill:#ff0043}.c57{fill:#f6767b}.c58{fill:#c74249}.c59{fill:#aa343a}.c60{fill:#4047ff}.c61{fill:#585eff}.c62{fill:#4d54ff}.c63{fill:#222bff}.c64{fill:#3d44ff}.c65{fill:#3b42ff}.c66{fill:#3239ff}.c67{fill:#343bff}.c68{fill:#4249ff}.c69{fill:#333333}.c70{fill:#222222}.c71{fill:#ccccff}</style></svg>'
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 7; i++) { //9
            uint8 thisTraitIndex = ChainsLibrary.parseInt(
                ChainsLibrary.substring(_hash, i, i + 1)
            );

            (string memory traitName,string memory traitType,,) = IChainsTraits(_genOneChainsAddress).traitTypes(i, thisTraitIndex);

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"},'
                )
            );

        }

        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"display_type": "boost_number", "trait_type": "BB Boost", "value":',
                ChainsLibrary.toString(IBallerBars(_genTwoBallerBarsAddress)._calculateBoost(_hash)),'}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    ChainsLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "BlockChain #',
                                    ChainsLibrary.toString(_tokenId),
                                    '", "description": "The BlockChains collection serves as the first',
                                    'phase of Ben Baller','Did The BlockChain.","image": "data:image/svg+xml;base64,',
                                    ChainsLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */

    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    ChainsLibrary.substring(tokenHash, 1, 7)
                )
            );
        }

        return tokenHash;
    }


    /**
     * @dev Returns the mint timestamp of a tokenId
     * @param _tokenId The tokenId to return the timestamp for.
     */

    function getTokenTimestamp(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToTimestamp[_tokenId];
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */

    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function togglePauseStatus() external onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Sets BB contract address based on generation
     * @param ballerBarsAddress The BB contract address
     * @param generation The generation of chains contract
     */

    function setBallerBarsAddress(address ballerBarsAddress,uint256 generation) onlyOwner public {
        require(generation==1||generation==2,"INVALID_GEN");
        if(generation == 1){
            _genOneBallerBarsAddress = ballerBarsAddress;
        }else if(generation == 2){
            _genTwoBallerBarsAddress = ballerBarsAddress;
        }
    }

    /**
     * @dev Sets generation one chains contract address
     * @param genOneChainsAddress The chains contract address
     */

    function setGenOneChainsAddress(address genOneChainsAddress) onlyOwner public {
        _genOneChainsAddress = genOneChainsAddress;
    }

    /**
     * @dev Returns BB contract based on generation
     * @param generation The generation of contract to return. 1 or 2
     */

    function getBallerBarsContract(uint256 generation) internal view returns (IBallerBars) {
        if(generation == 1){
            return IBallerBars(_genOneBallerBarsAddress);
        }else if(generation == 2){
            return IBallerBars(_genTwoBallerBarsAddress);
        }else{
            revert("INVALID_GEN");
        }
    }

    /**
     * @dev Returns the number of rare assets of a tokenId
     * @param _tokenId The tokenId to return the number of rare assets for.
     */

    function getTokenRarityCount(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        require(_tokenId<3406,"NOT_GEN_ONE_CHAIN");
        return IChains(_genOneChainsAddress).getTokenRarityCount(_tokenId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IChainsTraits {
    function traitTypes(uint256 i, uint256 j)
        external
        view
        returns (string memory,string memory,string memory,uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IChains is IERC721Enumerable {

    function getTokenTimestamp(uint256 _tokenId)
        external
        view
        returns (uint256);

    function getTokenRarityCount(uint256 _tokenId)
        external
        view
        returns (uint256);

    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IBallerBars is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function burnUnclaimed(uint256[] memory _tokenIds, uint256 amount) external;
    function _calculateBoost(string memory _hash) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ChainsLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}