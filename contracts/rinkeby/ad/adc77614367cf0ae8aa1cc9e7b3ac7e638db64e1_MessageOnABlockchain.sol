pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
// This smart contract was written from and by RiddleDrops GmbH 2021

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

import {Base64} from 'Base64.sol';

contract MessageOnABlockchain is ERC721, Ownable 
{    
    using Counters for Counters.Counter;        
    Counters.Counter private _tokenIds;  

    uint private maxTokens = 808;    
    uint private priceInSOS = 20000000e18;
    uint private randomSeed;

    bytes32[17] private colors;
    address payable private targetWallet = payable(0x8ecFBB38544be03a56cf1666a9E1eB1629599365);    
  
    IERC20 public sosContract;

    // Shape info
    struct Shapes
    {
        bytes32 name;
        string svg;
    }    

    // Traits 
    struct Traits
    {
        bytes32 message;
        uint bgColor;  
        uint[5] shape_keys;
        uint[5] shape_colors;    
    }

    // Message
    struct Token
    {
            bytes32 message;
            uint seed;
    }

    Shapes[17] private shapes;        
    mapping (uint => Token) private tokenMeta;
    mapping (bytes32 => bool) private messageStore;

    constructor(IERC20 _openDAOContract) ERC721("Message on a Blockchain", "MOABC") 
    {
        // Randomseed to start
        randomSeed = 10001000100011001010011; // Add 0 in front <3
        
        // SOS contract
        sosContract = _openDAOContract;
        shapes[0].name = 'Triangle'; // Fallback
        shapes[0].svg = 'd="M 175 0 L 350 350 L 0 350 Z" />'; // Fallback
        shapes[1].name = 'Triangle';
        shapes[1].svg = 'd="M 175 0 L 350 350 L 0 350 Z" />';
        shapes[2].name = 'Triangle flipped';
        shapes[2].svg = 'd="M 175 350 L 0 0 L 350 0 Z" />';
        shapes[3].name = 'Triangle left';
        shapes[3].svg = 'd="M 0 175 L 350 0 L 350 350 Z" />';
        shapes[4].name = 'Triangle right';
        shapes[4].svg = 'd="M 350 175 L 0 350 L 0 0 Z" />';
        shapes[5].name = 'Star';
        shapes[5].svg = 'd="M 175 0 L 230 120 L 350 135 L 255 218 L 300 350 L 175 285 L 50 350 L 95 218 L 0 135 L 120 120 Z" />';        
        shapes[6].name = 'Pentagon flipped';
        shapes[6].svg = 'd="M 175 350 L 350 175 L 270 0 L 80 0 L 0 175 Z" />';
        shapes[7].name = 'Hexagon';
        shapes[7].svg = 'd="M 0 175 L 90 0 L 260 0 L 350 175 L 260 350 L 90 350 Z" />';
        shapes[8].name = '4-Star';
        shapes[8].svg = 'd="M 175 0 L 230 130 L 350 175 L 230 220 L 175 350 L 120 220 L 0 175 L 120 130 Z" />';
        shapes[9].name = 'Diamond';
        shapes[9].svg = 'd="M 175 0 L 350 175 L 175 350 L 0 175 Z" />';
        shapes[10].name = 'Stairway to Heaven';
        shapes[10].svg = 'd="M 0 350 L 0 300 L 50 300 L 50 250 L 100 250 L 100 200 L 150 200 L 150 150 L 200 150 L 200 100 L 250 100 L 250 50 L 300 50 L 300 0 L 350 0 L 350 350 Z" />';
        shapes[11].name = 'Stairway to Hell';
        shapes[11].svg = 'd="M 0 350 L 50 350 L 50 300 L 100 300 L 100 250 L 150 250 L 150 200 L 200 200 L 200 150 L 250 150 L 250 100 L 300 100 L 300 50 L 350 50 L 350 0 L 0 0 Z" />';        
        shapes[12].name = 'The L';
        shapes[12].svg = 'd="M 0 0 L 87 0 L 87 263 L 175 263 L 175 350 L 0 350 Z" />';
        shapes[13].name = 'The L mirrored';
        shapes[13].svg = 'd="M 350 350 L 175 350 L 175 263 L 263 263 L 263 0 L 350 0 Z" />';
        shapes[14].name = 'Block left';
        shapes[14].svg = 'd="M 0 350 L 50 350 L 50 300 L 100 300 L 100 250 L 150 250 L 150 200 L 200 200 L 200 150 L 150 150 L 150 100 L 100 100 L 100 50 L 50 50 L 50 0 L 0 0 Z" />';
        shapes[15].name = 'Block top';
        shapes[15].svg = 'd="M 350 0 L 350 50 L 300 50 L 300 100 L 250 100 L 250 150 L 200 150 L 200 200 L 150 200 L 150 150 L 100 150 L 100 100 L 50 100 L 50 50 L 0 50 L 0 0 Z" />';
        shapes[16].name = 'Zig zag';
        shapes[16].svg = 'd="M 350 350 L 350 300 L 300 300 L 300 250 L 250 250 L 250 200 L 200 200 L 200 150 L 150 150 L 150 100 L 100 100 L 100 50 L 50 50 L 50 0 L 0 0 L 0 0 Z" />';
      
        colors[0] = "Aquamarine"; // Fallback
        colors[1] = "Aquamarine";
        colors[2] = "Lavenderblush";
        colors[3] = "Lightpink";
        colors[4] = "Lightblue";
        colors[5] = "Lightsalmon";
        colors[6] = "Lightgoldenrodyellow";
        colors[7] = "Peachpuff";
        colors[8] = "Powderblue";
        colors[9] = "Thistle";
        colors[10] = "Mediumaquamarine";
        colors[11] = "Lightsteelblue";
        colors[12] = "Lightgreen";
        colors[13] = "Mistyrose";
        colors[14] = "Tomato";
        colors[15] = "Lavender";
        colors[16] = "Blanchedalmond";
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Only to overwrite hate speech or to fix upon request of owner
    function setMessage(uint256 tokenId, bytes32 _message) external onlyOwner {
        tokenMeta[tokenId].message = _message;
    }

    function getMessage(uint256 tokenId) public view returns (string memory)
    {
        return bytes32ToString(tokenMeta[tokenId].message);
    }

    function messageExists(bytes32 _message) public view returns (bool)
    {
        return messageStore[_message];
    }

    function getRandomSeed() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, randomSeed, block.timestamp, msg.sender, totalSupply())));
    }

    function mint(bytes32 _message) external {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= maxTokens,"Max Minted");    
        require(!messageExists(_message),"Message already exists");    

        //sosContract.transferFrom(msg.sender,targetWallet,priceInSOS);        
        
        // Get a seed - pseudo random number for the traits
        // Saves massive amounts of gas to only store this seed
        uint newSeed = getRandomSeed();
        
        // Save to storage
        randomSeed = newSeed;
        tokenMeta[id] = Token(_message,randomSeed);        
        messageStore[_message] = true;
        _safeMint(msg.sender, id);
    }

    function getTraits(uint256 _tokenId) public view returns (Traits memory) {        
        uint _r;
        uint _rMash;        
        uint _shapeLength;
        uint _colorLength;
        Traits memory memTraits;        

        // Get the seed to derive the traits
        _r = tokenMeta[_tokenId].seed;

        _shapeLength = shapes.length; // saving a little gas
        _colorLength = colors.length; // saving a little gas

        // Background color
        memTraits.bgColor = _r % _colorLength;

        // Messages        
        memTraits.message = tokenMeta[_tokenId].message;        

        // Element count
        uint _elementCount = _r % 6;
        _elementCount = _elementCount < 2 ? 2 : _elementCount; // 2 Elements min, 5 max
        _rMash = uint(keccak256(abi.encodePacked(_r, _elementCount))) % _elementCount;
        for (uint i = 0; i < _elementCount; i++){
            _r = _r - _rMash;
            memTraits.shape_keys[i] = _r % _shapeLength +1; // never 0       
            memTraits.shape_colors[i] = _r % _colorLength +1; // never 0
        }

        return memTraits;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Traits memory memTraits;        
        string memory attributes;
        string memory svg_output;
        memTraits = getTraits(tokenId);

        // Background Trait
        attributes = string(abi.encodePacked(string(abi.encodePacked(
            '{"trait_type":","Background","value":"',
            bytes32ToString(colors[memTraits.bgColor]),
            '"}'
            ))));

        // SVG prep
        svg_output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRadio="xMinYMin meet" viewBox="0 0 350 350">';
        svg_output = string(abi.encodePacked(
            svg_output,
            '<rect style="fill:',colors[memTraits.bgColor],';fill-opacity:1;stroke:#000000;stroke-width:0.25;stroke-miterlimit:4;stroke-opacity:1" width="100%" height="100%" x="0" y="0" />'));
        

        // Elements
        for(uint i = 0; i < memTraits.shape_keys.length; i++)
        {
            attributes = string(abi.encodePacked(attributes,getShapeAttributes(memTraits.shape_keys[i],memTraits.shape_colors[i],i)));
            svg_output = string(abi.encodePacked(svg_output,getShapeSVG(memTraits.shape_keys[i],memTraits.shape_colors[i],i)));
        }

        // SVG Close
        svg_output = string(abi.encodePacked(
            svg_output,
            '<foreignObject  width="100%" height="350" x="0" y="0" requiredExtensions="http://www.w3.org/1999/xhtml"><div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: center; position:relative; justify-content: center; height: 100%;"><p id="preview" style="padding: 0px; color: white; font-family: Cooper Black; font-size:40px; -webkit-text-stroke: 2px black;">',
            memTraits.message,
            '</p></div></foreignObject></svg>'));       

        string memory metaData =  string(abi.encodePacked(
                '{"name": "MOABC #',
                toString(tokenId),
                '", "description": "Your message, 100% generated and stored on the Ethereum blockchain. No IPFS, no centralized data storage or API.","image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg_output)),
                '", "attributes":[',
                attributes,
                "]}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(metaData))
            ));
    }

    function getShapeAttributes(uint shape_key, uint shape_color, uint i) public view returns (string memory) 
    {
        string memory compiledAttributes;
     
        compiledAttributes = string(abi.encodePacked(compiledAttributes,string(abi.encodePacked(
            ',{"trait_type":","Element ',
            toString(i),
            '","value":"',
            bytes32ToString(shapes[shape_key].name),
            '"}',
            ',{"trait_type":","Element ',
            toString(i),
            ' Color","value":"',
            bytes32ToString(colors[shape_color]),
            '"}'
        ))));    
    
        return compiledAttributes;
    }

    function getShapeSVG(uint shape_key, uint shape_color, uint i) public view returns (string memory) 
    {
        string memory svg_output;  
        string memory traitSvg;                
        bytes32 colorName;
        uint color;
        uint shapeKey;
    
        color = shape_color;
        colorName = colors[color];
        shapeKey = shape_key;
        traitSvg = shapes[shapeKey].svg;

        // Style definition
        svg_output = string(abi.encodePacked(
            svg_output,
            '<style>.e',
            toString(i),
            ' { fill: ',
            bytes32ToString(colorName),
            '; opacity:0.75;stroke:#000000;stroke-width:0.25; }</style>'));

        // Drawing path
        svg_output = string(abi.encodePacked(
            svg_output,
            '<path class="e',
            toString(i),
            '" ',
            traitSvg));        
               
        return svg_output;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}