// SPDX-License-Identifier: MIT

/*
CrypToadz Created By:
  ___  ____  ____  __  __  ____  __    ____  _  _ 
 / __)(  _ \( ___)(  \/  )(  _ \(  )  (_  _)( \( )
( (_-. )   / )__)  )    (  )___/ )(__  _)(_  )  ( 
 \___/(_)\_)(____)(_/\/\_)(__)  (____)(____)(_)\_) 
(https://cryptoadz.io)

ChainToadz Programmed By:
 __      __         __    __                 
/  \    /  \_____ _/  |__/  |_  _________.__.
\   \/\/   /\__  \\   __\   __\/  ___<   |  |
 \        /  / __ \|  |  |  |  \___ \ \___  |
  \__/\  /  (____  /__|  |__| /____  >/ ____|
       \/        \/                \/ \/     
(https://wattsy.art)
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./GIFEncoder.sol";

error ImageNotFound();
error AnimationNotFound();

/** @notice Pixel renderer using basic drawing instructions: fill, line, and dot. */
library PixelRenderer {

    struct Point2D {
        int32 x;
        int32 y;
    }

    struct Line2D {
        Point2D v0;
        Point2D v1;
        uint32 color;
    }

    struct DrawFrame {
        bytes buffer;
        uint position;
        GIFEncoder.GIFFrame frame;
        uint32[255] colors;
    }

    function drawFrame(DrawFrame memory f) internal pure returns (DrawFrame memory) {       

        (uint32 instructionCount, uint position) = readUInt32(f.buffer, f.position);
        f.position = position;

        for(uint32 i = 0; i < instructionCount; i++) {

            uint8 instructionType = uint8(f.buffer[f.position++]);                   

            if(instructionType == 0) {                                     
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                for (uint16 x = 0; x < f.frame.width; x++) {
                    for (uint16 y = 0; y < f.frame.height; y++) {
                        f.frame.buffer[f.frame.width * y + x] = color;
                    }
                }
            }
            else if(instructionType == 1)
            {                
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                line(f.frame, PixelRenderer.Line2D(
                    PixelRenderer.Point2D(int8(uint8(f.buffer[f.position++])), int8(uint8(f.buffer[f.position++]))), 
                    PixelRenderer.Point2D(int8(uint8(f.buffer[f.position++])), int8(uint8(f.buffer[f.position++]))),
                    color));
            }
            else if(instructionType == 2)
            {   
                uint32 color = f.colors[uint8(f.buffer[f.position++])]; 
                dot(f.frame, int8(uint8(f.buffer[f.position++])), int8(uint8(f.buffer[f.position++])), color);
            }
        }

        return f;
    }    

    function getColorTable(bytes memory buffer, uint position) internal pure returns(uint32[255] memory colors, uint) {
        colors[0] = 0xFF000000;
        uint8 colorCount = uint8(buffer[position++]);
        for(uint8 i = 0; i < colorCount; i++) {
            uint32 r = uint32(uint8(buffer[position++]));
            uint32 g = uint32(uint8(buffer[position++]));
            uint32 b = uint32(uint8(buffer[position++]));
            uint32 color = 0;
            color |= 255 << 24;
            color |= r << 16;
            color |= g << 8;
            color |= b << 0;
            colors[i + 1] = color;                
        }
        return (colors, position);
    }

    function dot(
        GIFEncoder.GIFFrame memory frame,
        int32 x,
        int32 y,
        uint32 color
    ) private pure {
        uint32 p = uint32(int16(frame.width) * y + x);
        frame.buffer[p] = color;
    }

    function line(GIFEncoder.GIFFrame memory frame, Line2D memory f)
        private
        pure
    {
        int256 x0 = f.v0.x;
        int256 x1 = f.v1.x;
        int256 y0 = f.v0.y;
        int256 y1 = f.v1.y;

        int256 dx = abs(x1 - x0);
        int256 dy = abs(y1 - y0);

        int256 err = (dx > dy ? dx : -dy) / 2;

        for (;;) {
            if (
                x0 <= int32(0) + int16(frame.width) - 1 &&
                x0 >= int32(0) &&
                y0 <= int32(0) + int16(frame.height) - 1 &&
                y0 >= int32(0)
            ) {
                uint256 p = uint256(int16(frame.width) * y0 + x0);
                frame.buffer[p] = f.color;
            }

            if (x0 == x1 && y0 == y1) break;
            int256 e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += x0 < x1 ? int8(1) : -1;
            }
            if (e2 < dy) {
                err += dx;
                y0 += y0 < y1 ? int8(1) : -1;
            }
        }
    }

    function readUInt32(bytes memory buffer, uint position) private pure returns (uint32, uint) {
        uint8 d1 = uint8(buffer[position++]);
        uint8 d2 = uint8(buffer[position++]);
        uint8 d3 = uint8(buffer[position++]);
        uint8 d4 = uint8(buffer[position++]);
        return ((16777216 * d4) + (65536 * d3) + (256 * d2) + d1, position);
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

/** @notice Interface describing ChainToadz, so other contracts can wrap and call into it if they want to share our data. */
interface IChainToadz {

    /** @notice Produces the token metadata as a JSON document  */
    function getTokenMetadata(uint tokenId) external view returns (string memory metadata);

    /** @notice Renders the canonical token image as an embedded data URI  */
    function getImageDataUri(uint tokenId) external view returns (string memory uri);

    /** @notice Renders a custom animation as an embedded data URI  */
    function getAnimationDataUri(uint tokenId, uint animationId) external view returns(string memory uri);    

    /** @notice Renders the raw GIF image for the canonical token image */
    function getImage(uint tokenId) external view returns (GIFEncoder.GIF memory gif);

    /** @notice Renders the raw GIF image for a custom animation */
    function getAnimation(uint tokenId, uint animationId) external view returns (GIFEncoder.GIF memory gif);
}

contract ChainToadz is ERC721, IChainToadz {

    bytes constant private JSON_URI_PREFIX = "data:application/json;base64,";    
    bytes constant private SVG_URI_PREFIX = "data:image/svg+xml;base64,";
    
    struct Point2D {
        int32 x;
        int32 y;
    }

    struct Line2D {
        Point2D v0;
        Point2D v1;
        uint32 color;
    }

    address private _admin;
    
    string private _tokenName;
    string private _externalUrl;
    string private _description;

    mapping(uint => bytes) public tokenData;
    mapping(uint => mapping(uint => bytes)) public animationData;
    mapping(uint => mapping(uint => string)) public animationName;

    mapping(uint => uint) tokenAnimation;

    mapping(uint8 => string) public accessoryOne;    
    mapping(uint8 => string) public accessoryTwo;
    mapping(uint8 => string) public background;
    mapping(uint8 => string) public body;
    mapping(uint8 => string) public clothes;
    mapping(uint8 => string) public custom;
    mapping(uint8 => string) public eyes;
    mapping(uint8 => string) public head;
    mapping(uint8 => string) public mouth;    
    mapping(uint8 => string) public names;
   
    function setAccessoryOne(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        accessoryOne[key] = value;
    }

    function setAccessoryTwo(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        accessoryTwo[key] = value;
    }

    function setBackground(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        background[key] = value;
    }

    function setBody(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        body[key] = value;
    }

    function setClothes(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        clothes[key] = value;
    }

    function setCustom(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        custom[key] = value;
    }

    function setEyes(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        eyes[key] = value;
    }

    function setHead(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        head[key] = value;
    }

    function setMouth(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        mouth[key] = value;
    }
    
    function setName(uint8 key, string memory value) external {
        require(_msgSender() == _admin);
        names[key] = value;
    }

    constructor() ERC721("ChainToadz", "CHAINTOADZ") {  
        _admin = _msgSender();

        _tokenName = "ChainToadz";
        _externalUrl = "https://cryptoadz.io";
        _description = "A small, warty, amphibious creature that resides in the metaverse (and entirely on the blockchain).";        

        accessoryOne[1] = "Drive-thru";
        accessoryOne[2] = "Explorer";
        accessoryOne[3] = "Fly Lick";
        accessoryOne[4] = "Four Flies";
        accessoryOne[5] = "Mysterious Hoodie";
        accessoryOne[6] = "One Fly";
        accessoryOne[7] = "Three Flies";
        accessoryOne[8] = "Toxic Lumps";
        accessoryOne[9] = "Two Flies";

        accessoryTwo[1] = "Blush";
        accessoryTwo[2] = "Chocolate";
        accessoryTwo[3] = "Earring";
        accessoryTwo[4] = "Just for the Looks";
        accessoryTwo[5] = "Long Cigarette";
        accessoryTwo[6] = "Shackles";
        accessoryTwo[7] = "Short Cigarette";
        accessoryTwo[8] = "Watch";

        background[1] = "95";
        background[2] = "Blanket";
        background[3] = "Blood";
        background[4] = "Bruise";
        background[5] = "Bubblegum";
        background[6] = "Damp";
        background[7] = "Dark";
        background[8] = "Ghost Crash";
        background[9] = "Greige";
        background[10] = "Grey Foam";
        background[11] = "Greyteal";
        background[12] = "Matrix";
        background[13] = "Middlegrey";
        background[14] = "Mold";
        background[15] = "Salmon";
        background[16] = "Universe Foam";
        background[17] = "Violet";

        body[1] = "Albino";
        body[2] = "Alien";
        body[3] = "Angry";
        body[4] = "Ape";
        body[5] = "Berry";
        body[6] = "Big Ghost";
        body[7] = "Blood Bones";
        body[8] = "Blue Cat";
        body[9] = "Bones";
        body[10] = "Booger";
        body[11] = "Chimp";
        body[12] = "Creep";
        body[13] = "Dog";
        body[14] = "Gargoyle";
        body[15] = "Ghost";
        body[16] = "Ghost Bones";
        body[17] = "Gorilla";
        body[18] = "Gremplin Blue";
        body[19] = "Gremplin Green";
        body[20] = "Gummy Blue";
        body[21] = "Gummy Peach";
        body[22] = "Gummy Raspberry";
        body[23] = "Gummy Slime";
        body[24] = "Gummy Tropical";
        body[25] = "Hypnotic";
        body[26] = "Lasagna";
        body[27] = "Normal";
        body[28] = "Only Socks";
        body[29] = "Pasty";
        body[30] = "Pox";
        body[31] = "Sleepy";
        body[32] = "Toadbot";
        body[33] = "Toadenza";
        body[34] = "Undead";

        clothes[1] = "Force Hoodie";
        clothes[2] = "Grey Hoodie";
        clothes[3] = "Slime Hoodie";

        custom[1] = "Legendary";
        custom[2] = "Licked - Don't Look in the Mirror";
        custom[3] = "Licked - Hallucination";
        custom[4] = "Licked - Warped";
        custom[5] = "Murdered by Fronkz";

        eyes[1] = "3D";
        eyes[2] = "Anime";
        eyes[3] = "Awake";
        eyes[4] = "Bandit";
        eyes[5] = "Big Crazy Orange";
        eyes[6] = "Big Crazy Red";
        eyes[7] = "Big Yellow Side-eye";
        eyes[8] = "Black & Blue Goggles";
        eyes[9] = "Blue Eyeshadow";
        eyes[10] = "Butthole";
        eyes[11] = "Cool Shades";        
        eyes[12] = "Creep";
        eyes[13] = "Croaked";
        eyes[14] = "Dilated";
        eyes[15] = "Glowing Blue";
        eyes[16] = "Glowing Red";
        eyes[17] = "Gold Specs";
        eyes[18] = "Green Eyeshadow";
        eyes[19] = "Gremplin";
        eyes[20] = "Judgment";
        eyes[21] = "Nerd";
        eyes[22] = "Nice Shades";
        eyes[23] = "Nounish Blue";
        eyes[24] = "Nounish Red";
        eyes[25] = "Patch";
        eyes[26] = "Red & Black Goggles";
        eyes[27] = "Round Shades";
        eyes[28] = "Thick Round";
        eyes[29] = "Thick Square";
        eyes[30] = "Undead";
        eyes[31] = "Vampire";
        eyes[32] = "Violet Goggles";
        eyes[33] = "White & Red Goggles";

        head[1] = "Aqua Mohawk";
        head[2] = "Aqua Puff";
        head[3] = "Aqua Shave";
        head[4] = "Aqua Sidepart";
        head[5] = "Backward Cap";
        head[6] = "Black Sidepart";
        head[7] = "Blonde Pigtails";
        head[8] = "Blue Pigtails";
        head[9] = "Blue Shave";
        head[10] = "Bowlcut";
        head[11] = "Brain";
        head[12] = "Crazy Blonde";
        head[13] = "Dark Pigtails";
        head[14] = "Dark Single Bun";
        head[15] = "Dark Tall Hat";
        head[16] = "Fez";
        head[17] = "Floppy Hat";
        head[18] = "Fun Cap";
        head[19] = "Grey Knit Hat";
        head[20] = "Orange Bumps";
        head[21] = "Orange Double Buns";
        head[22] = "Orange Knit Hat";
        head[23] = "Orange Shave";
        head[24] = "Orange Tal Hat";
        head[25] = "Periwinkle Cap";
        head[26] = "Pink Puff";
        head[27] = "Plaid Cap";
        head[28] = "Rainbow Mohawk";
        head[29] = "Red Gnome";
        head[30] = "Rusty Cap";
        head[31] = "Short Feathered Hat";
        head[32] = "Stringy";
        head[33] = "Super Stringy";
        head[34] = "Swampy Bumps";
        head[35] = "Swampy Crazy";
        head[36] = "Swampy Double Bun";
        head[37] = "Swampy Flattop";
        head[38] = "Swampy Sidepart";
        head[39] = "Swampy Single Bun";
        head[40] = "Swept Orange";
        head[41] = "Swept Purple";
        head[42] = "Swept Teal";
        head[43] = "Teal Gnome";
        head[44] = "Teal Knit Hat";
        head[45] = "Toadstool";
        head[46] = "Tophat";
        head[47] = "Truffle";
        head[48] = "Vampire";
        head[49] = "Wild Black";
        head[50] = "Wild Orange";
        head[51] = "Wild White";
        head[52] = "Wizard";
        head[53] = "Yellow Flattop";

        mouth[1] = "Bandit Smile";
        mouth[2] = "Bandit Wide";
        mouth[3] = "Beard";
        mouth[4] = "Blue Smile";
        mouth[5] = "Croak";
        mouth[6] = "Green Bucktooth";
        mouth[7] = "Lincoln";
        mouth[8] = "Peach Smile";
        mouth[9] = "Pink Bucktooth";
        mouth[10] = "Purple Wide";
        mouth[11] = "Ribbit Blue";
        mouth[12] = "Sad";
        mouth[13] = "Shifty";
        mouth[14] = "Slimy";
        mouth[15] = "Teal Smile";
        mouth[16] = "Teal Wide";
        mouth[17] = "Vampire";
        mouth[18] = "Well Actually";

        names[1] = "0xtoad";
        names[2] = "2croakchanes";
        names[3] = "41croak6";
        names[4] = "91croak5";
        names[5] = "9croak99";
        names[6] = "Adventurer";
        names[7] = "Aversanoad";
        names[8] = "BNToad";
        names[9] = "Barcroaka";
        names[10] = "Basglyphtoad";
        names[11] = "Bastoad";
        names[12] = "Belethtoad";
        names[13] = "Chanzerotoad";
        names[14] = "Cheftoad";
        names[15] = "Clairetoad";
        names[16] = "Colonel Floorbin";
        names[17] = "Croaklehat";
        names[18] = "Crycroak";
        names[19] = "Deezetoad";
        names[20] = "Dinfoad";
        names[21] = "Domtoad";
        names[22] = "Drocroak";
        names[23] = "Emmytoad";
        names[24] = "Erintoad";
        names[25] = "Fronkz Henchman 1";
        names[26] = "Fronkz Henchman 2";
        names[27] = "Geebztoad";
        names[28] = "Gustoad";
        names[29] = "Heeeeeeeetoad";
        names[30] = "Hero Of The Swamp";
        names[31] = "Herrerratoad";
        names[32] = "Huntoad";
        names[33] = "Hypetoad";
        names[34] = "Jeztoad";
        names[35] = "King Gremplin";
        names[36] = "Koppertoad";
        names[37] = "Leetoad";
        names[38] = "Little Sister";
        names[39] = "Marlotoad";
        names[40] = "Miketoad";
        names[41] = "Motitoad";
        names[42] = "Moxtoad";
        names[43] = "Mr7croak3";
        names[44] = "Nourtoad";
        names[45] = "Onitoad";
        names[46] = "Rastertoad";
        names[47] = "Samjtoad";
        names[48] = "Senecatoad";
        names[49] = "Slowbrodicktoad";
        names[50] = "Snowfroad";
        names[51] = "Sobytoad";
        names[52] = "Spcvetovd";
        names[53] = "Sumtoad";
        names[54] = "Tappytoad";
        names[55] = "Termitoad";
        names[56] = "Tiodan";
        names[57] = "Toadbeef";
        names[58] = "Trilltoad";
        names[59] = "VGFtoad";
        names[60] = "Vegtoad";
        names[61] = "Westoad";
        names[62] = "Yuppietoad";
        names[63] = "Zolitoad";        
    }

    /** @notice Emitted when a single token metadata updates. */ 
    event TokenMetadataUpdated(uint256 indexed tokenId);

    /** @notice Emitted when all token metadata is considered stale. */ 
    event TokensMetadataUpdated();

    function setTokenDetails(string memory tokenName, string memory external_url, string memory description) external {
        require(_msgSender() == _admin);
        _tokenName = tokenName;
        _externalUrl = external_url;
        _description = description;        
        emit TokensMetadataUpdated();
    }

    function setTokenAnimation(uint tokenId, uint animationId) external {
        require(ownerOf(tokenId) == _msgSender());
        if(animationId != 0 && animationData[tokenId][animationId].length == 0) revert AnimationNotFound();
        tokenAnimation[tokenId] = animationId;
        emit TokenMetadataUpdated(tokenId);
    }
    
    function setTokenData(uint tokenId, bytes memory data) external {
        require(_msgSender() == _admin);
        tokenData[tokenId] = data; 
        require(tokenData[tokenId].length == data.length);
        emit TokenMetadataUpdated(tokenId);
    }

    function setAnimationData(uint tokenId, uint animationId, bytes memory data) external {
        require(_msgSender() == _admin);
        require(animationId > 0);
        animationData[tokenId][animationId] = data; 
        require(animationData[tokenId][animationId].length == data.length);       
        if(tokenAnimation[tokenId] == animationId) {
            emit TokenMetadataUpdated(tokenId);
        }
    }

    function setAnimationName(uint tokenId, uint animationId, string memory value) external {
        require(_msgSender() == _admin);
        if(animationId == 0 || (animationId != 0 && animationData[tokenId][animationId].length == 0)) revert AnimationNotFound();
        animationName[tokenId][animationId] = value;
        if(tokenAnimation[tokenId] == animationId) {
            emit TokenMetadataUpdated(tokenId);
        }
    }

    /** @notice Produces the token metadata as a JSON document  */
    function getTokenMetadata(uint tokenId) public override view returns (string memory metadata) {        
        return createTokenMetadata(tokenId);
    }

    function createTokenMetadata(uint tokenId) private view returns (string memory metadata) {
        
        uint animationId = tokenAnimation[tokenId];
        
        string memory imageUri = GIFEncoder.getDataUri(animationId == 0 ? getImage(tokenId) : getAnimation(tokenId, animationId));

        string memory imageData = string(abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 100 100" style="enable-background:new 0 0 100 100;" xml:space="preserve">',
            '<image style="image-rendering:-moz-crisp-edges;image-rendering:-webkit-crisp-edges;image-rendering:pixelated;" width="100" height="100" xlink:href="', 
            imageUri, '"/></svg>'));

        metadata = string(abi.encodePacked('{"description":"', _description, 
        '","external_url":"', _externalUrl, 
        '","image_data":"', abi.encodePacked(SVG_URI_PREFIX, Base64.encode(bytes(imageData), bytes(imageData).length)),
        '","name":"', _tokenName, ' #', toString(tokenId), 
        '",',getTokenMetadataAttributes(tokenId),
        '}'));
    }

    function getTokenMetadataAttributes(uint tokenId) private view returns (string memory attributes) {

        bytes memory buffer = tokenData[tokenId];
        uint position = 0;
        require(buffer.length > 0);   

        uint8 numberOfTraits = 0;

        attributes = string(abi.encodePacked('"attributes":['));
        {
            (string memory a, uint8 t) = appendTrait(attributes, "Background", background[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Body", body[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        position++;

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Clothes", clothes[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Eyes", eyes[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Head", head[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Mouth", mouth[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Accessory I", accessoryOne[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Accessory II", accessoryTwo[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;          
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Custom", custom[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;          
        }

        if(tokenAnimation[tokenId] != 0)
        {
            (string memory a, uint8 t) = appendTrait(attributes, "Animation", animationName[tokenId][tokenAnimation[tokenId]], numberOfTraits);
            attributes = a;
            numberOfTraits = t;          
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Name", names[uint8(buffer[position++])], numberOfTraits);
            attributes = a;
            numberOfTraits = t;          
        }

        attributes = string(abi.encodePacked(attributes, ',{"trait_type":"# Traits","value":"', toString(numberOfTraits), '"}]'));
    }

    function appendTrait(string memory attributes, string memory trait_type, string memory value, uint8 numberOfTraits) private pure returns (string memory, uint8) {        
        if(bytes(value).length > 0) {
            numberOfTraits++;
            attributes = string(abi.encodePacked(attributes, numberOfTraits > 1 ? ',' : '', '{"trait_type":"', trait_type, '","value":"', value, '"}'));
        }
        return (attributes, numberOfTraits);
    }

    /** @notice Renders the raw GIF image for the canonical token image */
    function getImage(uint tokenId) public override view returns (GIFEncoder.GIF memory gif) 
    {
        bytes memory buffer = tokenData[tokenId];
        if(buffer.length == 0) revert ImageNotFound();
        uint position = 11;

        (uint32[255] memory colors, uint p) = PixelRenderer.getColorTable(buffer, position);
        position = p;

        gif.width = 36;
        gif.height = 36;

        {
            GIFEncoder.GIFFrame memory frame;
            frame.width = gif.width;
            frame.height = gif.height;

            PixelRenderer.DrawFrame memory f = PixelRenderer.DrawFrame(buffer, position, frame, colors);
            f = PixelRenderer.drawFrame(f);            

            frame.buffer = f.frame.buffer;
            frame.width = f.frame.width;
            frame.height = f.frame.height;

            gif.frames[gif.frameCount++] = frame;           
        }
    }

    /** @notice Renders the canonical token image as an embedded data URI  */
    function getImageDataUri(uint tokenId) external override view returns(string memory) {
        GIFEncoder.GIF memory gif = getImage(tokenId);
        string memory dataUri = GIFEncoder.getDataUri(gif);
        return dataUri;
    }

    /** @notice Renders the raw GIF image for a custom animation */
    function getAnimation(uint tokenId, uint animationId) public override view returns (GIFEncoder.GIF memory gif)
    {
        uint32[255] memory colors;
        {
            bytes memory tokenBuffer = tokenData[tokenId];
            if(tokenBuffer.length == 0) revert ImageNotFound();
            (colors,) = PixelRenderer.getColorTable(tokenBuffer, 11);
            require(colors[1] != 0);
        }      
        
        gif.width = 36;
        gif.height = 36;
        
        {
            bytes memory buffer = animationData[tokenId][animationId];
            if(buffer.length == 0) revert AnimationNotFound();        
            uint position = 0;

            uint8 frameCount = uint8(buffer[position++]);

            for(uint8 i = 0; i < frameCount; i++) {

                GIFEncoder.GIFFrame memory frame;
                frame.width = gif.width;
                frame.height = gif.height;

                uint16 delay;
                {
                    uint8 d1 = uint8(buffer[position++]);
                    uint8 d2 = uint8(buffer[position++]);
                    delay = (256 * d2) + d1;

                    frame.delay = delay;
                }                

                PixelRenderer.DrawFrame memory f = PixelRenderer.DrawFrame(buffer, position, frame, colors);
                f = PixelRenderer.drawFrame(f);
                position = f.position;
                gif.frames[gif.frameCount++] = f.frame;
            }
        }       
    }

    /** @notice Renders a custom animation as an embedded data URI  */
    function getAnimationDataUri(uint tokenId, uint animationId) external override view returns(string memory) {
        GIFEncoder.GIF memory gif = getAnimation(tokenId, animationId);
        string memory dataUri = GIFEncoder.getDataUri(gif);
        return dataUri;
    }
    
    function toString(uint value) private pure returns (string memory) {
        bytes memory reversed = new bytes(78);
        uint i = 0;
        while (value != 0) {
            uint remainder = value % 10;
            value = value / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        return string(s);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory metadata = createTokenMetadata(tokenId);
        string memory dataUri = string(abi.encodePacked(JSON_URI_PREFIX, Base64.encode(bytes(metadata), bytes(metadata).length)));
        return dataUri;      
    }

    function updateAdmin(address newAdmin) public {
        require(_msgSender() == _admin);
        require(newAdmin != address(0x0));
        _admin = newAdmin;       
    }

    function mint(uint tokenId) public {
        require(_msgSender() == _admin);
        _safeMint(_msgSender(), tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

import "./Base64.sol";

/*
 __      __         __    __                 
/  \    /  \_____ _/  |__/  |_  _________.__.
\   \/\/   /\__  \\   __\   __\/  ___<   |  |
 \        /  / __ \|  |  |  |  \___ \ \___  |
  \__/\  /  (____  /__|  |__| /____  >/ ____|
       \/        \/                \/ \/     
(https://wattsy.art)
*/

/** @notice Encodes image data in GIF format. GIF is much more compact than SVG, allows for animation (SVG does as well), and also represents images that are already rastered. 
            This is important if the art shouldn't change fundamentally depending on which process is doing the SVG rendering, such as a browser or custom application.
 */
library GIFEncoder {
    
    uint32 internal constant MASK = (1 << 12) - 1;
    uint32 internal constant CLEAR_CODE = 256;
    uint32 internal constant END_CODE = 257;
    uint16 internal constant CODE_START = 258;
    uint16 internal constant TREE_TABLE_LENGTH = 4096;
    uint16 internal constant CODE_TABLE_LENGTH = TREE_TABLE_LENGTH - CODE_START;

    bytes public constant HEADER = hex"474946383961";
    bytes public constant NETSCAPE = hex"21FF0b4E45545343415045322E300301000000";
    bytes public constant GIF_URI_PREFIX = "data:image/gif;base64,";

    struct GCT {
        uint32 start;
        uint32 count;
    }

    struct LZW {
        uint16 codeCount;
        int32 codeBitsUsed;
        uint32 activePrefix;
        uint32 activeSuffix;
        uint32[CODE_TABLE_LENGTH] codeTable;
        uint16[TREE_TABLE_LENGTH] treeRoots;
        Pending pending;
    }

    struct Pending {
        uint32 value;
        int32 bits;
        uint32 chunkSize;
    }

    struct GIF {
        uint32 frameCount;
        GIFFrame[10] frames;
        uint16 width;
        uint16 height;
    }

    struct GIFFrame {
        uint32[1296] buffer;
        uint16 delay;
        uint16 width;
        uint16 height;
    }

    function getDataUri(GIF memory gif) internal pure returns (string memory) {
        (bytes memory buffer, uint length) = encode(gif);
        string memory base64 = Base64.encode(buffer, length);
        return string(abi.encodePacked(GIF_URI_PREFIX, base64));
    }

    function encode(GIF memory gif) private pure returns (bytes memory buffer, uint length) {
        buffer = new bytes(gif.width * gif.height * 3);
        uint32 position = 0;

        // header
        position = writeBuffer(buffer, position, HEADER);

        // logical screen descriptor
        {
            position = writeUInt16(buffer, position, gif.width);
            position = writeUInt16(buffer, position, gif.height);

            uint8 packed = 0;
            packed |= 1 << 7;
            packed |= 7 << 4;
            packed |= 0 << 3;
            packed |= 7 << 0;

            position = writeByte(buffer, position, packed);
            position = writeByte(buffer, position, 0);
            position = writeByte(buffer, position, 0);
        }

        // global color table
        GCT memory gct;
        gct.start = position;
        gct.count = 1;
        {
            for (uint256 i = 0; i < 768; i++) {
                position = writeByte(buffer, position, 0);
            }
        }

        if (gif.frameCount > 1) {
            // netscape extension block
            position = writeBuffer(buffer, position, NETSCAPE);
        }

        uint32[CODE_TABLE_LENGTH] memory codeTable;

        for (uint256 i = 0; i < gif.frameCount; i++) {
            // graphic control extension
            {
                position = writeByte(buffer, position, 0x21);
                position = writeByte(buffer, position, 0xF9);
                position = writeByte(buffer, position, 0x04);

                uint8 packed = 0;
                packed |= (gif.frameCount > 1 ? 2 : 0) << 2;
                packed |= 0 << 1;
                packed |= 1 << 0;
                position = writeByte(buffer, position, packed);

                position = writeUInt16(buffer, position, gif.frameCount > 1 ? gif.frames[i].delay : uint16(0));                
                position = writeByte(buffer, position, 0);
                position = writeByte(buffer, position, 0);
            }

            // image descriptor
            {
                position = writeByte(buffer, position, 0x2C);
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, gif.frames[i].width);
                position = writeUInt16(buffer, position, gif.frames[i].height);

                uint8 packed = 0;
                packed |= 0 << 7;
                packed |= 0 << 6;
                packed |= 0 << 5;
                packed |= 0 << 0;
                position = writeByte(buffer, position, packed);
            }

            // image data
            {
                uint16[TREE_TABLE_LENGTH] memory treeRoots;

                (uint32 p, uint32 c) = writeImageData(
                    buffer,
                    position,
                    gct,
                    gif.frames[i],
                    LZW(0, 9, 0, 0, codeTable, treeRoots, Pending(0, 0, 0))
                );
                position = p;
                gct.count = c;
            }
        }

        // trailer
        position = writeByte(buffer, position, 0x3B);

        return (buffer, position);
    }

    function writeBuffer(
        bytes memory buffer,
        uint32 position,
        bytes memory value
    ) private pure returns (uint32) {
        for (uint256 i = 0; i < value.length; i++)
            buffer[position++] = bytes1(value[i]);
        return position;
    }

    function writeByte(
        bytes memory buffer,
        uint32 position,
        uint8 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(value);
        return position;
    }

    function writeUInt16(
        bytes memory buffer,
        uint32 position,
        uint16 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(uint8(uint16(value >> 0)));
        buffer[position++] = bytes1(uint8(uint16(value >> 8)));
        return position;
    }

    function writeImageData(
        bytes memory buffer,
        uint32 position,
        GCT memory gct,
        GIFFrame memory frame,
        LZW memory lzw
    ) private pure returns (uint32, uint32) {
                
        position = writeByte(buffer, position, 8);
        position = writeByte(buffer, position, 0);

        lzw.codeCount = 0;
        lzw.codeBitsUsed = 9;

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                CLEAR_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[0]
            );
            gct.count = c;
            lzw.activePrefix = p;
        }        

        for (uint32 i = 1; i < frame.width * frame.height; i++) {

            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[i]
            );
            gct.count = c;
            lzw.activeSuffix = p;

            position = writeColor(buffer, position, lzw);
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                lzw.activePrefix,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                END_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        if (lzw.pending.bits > 0) {
            position = writeChunked(
                buffer,
                position,
                uint8(lzw.pending.value & 0xFF),
                lzw.pending
            );
            lzw.pending.value = 0;
            lzw.pending.bits = 0;
        }

        if (lzw.pending.chunkSize > 0) {
            buffer[position - lzw.pending.chunkSize - 1] = bytes1(
                uint8(uint32(lzw.pending.chunkSize))
            );
            lzw.pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return (position, gct.count);
    }

    function writeColor(bytes memory buffer, uint32 position, LZW memory lzw) private pure returns (uint32) {
        uint32 lastTreePosition = 0;
        uint32 foundSuffix = 0;

        bool found = false;
        {
            uint32 treePosition = lzw.treeRoots[lzw.activePrefix];
            while (treePosition != 0) {
                lastTreePosition = treePosition;
                foundSuffix = lzw.codeTable[treePosition - CODE_START] & 0xFF;

                if (lzw.activeSuffix == foundSuffix) {
                    lzw.activePrefix = treePosition;
                    found = true;
                    break;
                } else if (lzw.activeSuffix < foundSuffix) {
                    treePosition = (lzw.codeTable[treePosition - CODE_START] >> 8) & MASK;
                } else {
                    treePosition = lzw.codeTable[treePosition - CODE_START] >> 20;
                }
            }
        }

        if (!found) {
            {
                (
                    uint32 p,
                    Pending memory pending
                ) = writeVariableBitsChunked(
                        buffer,
                        position,
                        lzw.activePrefix,
                        lzw.codeBitsUsed,
                        lzw.pending
                    );
                position = p;
                lzw.pending = pending;
            }

            if (lzw.codeCount == CODE_TABLE_LENGTH) {
                {
                    (
                        uint32 p,
                        Pending memory pending
                    ) = writeVariableBitsChunked(
                            buffer,
                            position,
                            CLEAR_CODE,
                            lzw.codeBitsUsed,
                            lzw.pending
                        );
                    position = p;
                    lzw.pending = pending;
                }

                for (uint16 j = 0; j < TREE_TABLE_LENGTH; j++) {
                    lzw.treeRoots[j] = 0;
                }
                lzw.codeCount = 0;
                lzw.codeBitsUsed = 9;
            } else {
                if (lastTreePosition == 0)
                    lzw.treeRoots[lzw.activePrefix] = uint16(CODE_START + lzw.codeCount);
                else if (lzw.activeSuffix < foundSuffix)
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 8)) | (uint32(CODE_START + lzw.codeCount) << 8);
                else {
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 20)) | (uint32(CODE_START + lzw.codeCount) << 20);
                }

                if (uint32(CODE_START + lzw.codeCount) == (uint32(1) << uint32(lzw.codeBitsUsed))) {
                    lzw.codeBitsUsed++;
                }

                lzw.codeTable[lzw.codeCount++] = lzw.activeSuffix;
            }

            lzw.activePrefix = lzw.activeSuffix;
        }

        return position;
    }    

    function writeVariableBitsChunked(
        bytes memory buffer,
        uint32 position,
        uint32 value,
        int32 bits,
        Pending memory pending
    ) private pure returns (uint32, Pending memory) {
        while (bits > 0) {
            int32 takeBits = min(bits, 8 - pending.bits);
            uint32 takeMask = uint32((uint32(1) << uint32(takeBits)) - 1);

            pending.value |= ((value & takeMask) << uint32(pending.bits));

            pending.bits += takeBits;
            bits -= takeBits;
            value >>= uint32(takeBits);

            if (pending.bits == 8) {
                position = writeChunked(
                    buffer,
                    position,
                    uint8(pending.value & 0xFF),
                    pending
                );
                pending.value = 0;
                pending.bits = 0;
            }
        }

        return (position, pending);
    }

    function writeChunked(
        bytes memory buffer,
        uint32 position,
        uint8 value,
        Pending memory pending
    ) private pure returns (uint32) {
        position = writeByte(buffer, position, value);
        pending.chunkSize++;

        if (pending.chunkSize == 255) {
            buffer[position - 256] = bytes1(uint8(255));
            pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return position;
    }

    function getColorTableIndex(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32, uint32) {
        if (target >> 24 != 0xFF) return (colorCount, 0);

        uint32 i = 1;
        for (; i < colorCount; i++) {
            if (uint8(buffer[colorTableStart + i * 3 + 0]) != uint8(target >> 16)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 1]) != uint8(target >> 8)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 2]) != uint8(target >> 0)
            ) continue;
            return (colorCount, i);
        }

        if (colorCount == 256) {
            return (
                colorCount,
                getColorTableBestMatch(
                    buffer,
                    colorTableStart,
                    colorCount,
                    target
                )
            );
        } else {
            buffer[colorTableStart + colorCount * 3 + 0] = bytes1(uint8(target >> 16));
            buffer[colorTableStart + colorCount * 3 + 1] = bytes1(uint8(target >> 8));
            buffer[colorTableStart + colorCount * 3 + 2] = bytes1(uint8(target >> 0));
            return (colorCount + 1, colorCount);
        }
    }

    function getColorTableBestMatch(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32) {
        uint32 bestDistance = type(uint32).max;
        uint32 bestIndex = 0;

        for (uint32 i = 1; i < colorCount; i++) {
            uint32 distance;
            {
                uint8 rr = uint8(buffer[colorTableStart + i * 3 + 0]) - uint8(target >> 16);
                uint8 gg = uint8(buffer[colorTableStart + i * 3 + 1]) - uint8(target >> 8);
                uint8 bb = uint8(buffer[colorTableStart + i * 3 + 2]) - uint8(target >> 0);
                distance = rr * rr + gg * gg + bb * bb;
            }
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = i;
            }
        }

        return bestIndex;
    }

    function max(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 >= val2) ? val1 : val2;
    }

    function min(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 <= val2) ? val1 : val2;
    }

    function min(int32 val1, int32 val2) private pure returns (int32) {
        return (val1 <= val2) ? val1 : val2;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data, uint length) internal pure returns (string memory) {
        if (data.length == 0 || length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((length + 2) / 3);

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}