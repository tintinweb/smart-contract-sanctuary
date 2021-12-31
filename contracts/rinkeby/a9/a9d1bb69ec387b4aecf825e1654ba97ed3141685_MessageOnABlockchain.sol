pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
// This smart contract was written from and by RiddleDrops GmbH 2021

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

contract MessageOnABlockchain is ERC721, Ownable 
{    
    using Counters for Counters.Counter;        
    Counters.Counter private _tokenIds;  

    uint public maxTokens = 808;    
    uint private randomSeed;

    uint public priceInPaymentToken = 30000000e18;    
    address payable private targetWallet = payable(0x8ecFBB38544be03a56cf1666a9E1eB1629599365);    
  
    IERC20 public paymentContract;

    // Shape info
    struct Shapes
    {
        string name;
        string svg;
    }    

    // Traits 
    struct Traits
    {
        string message;
        uint bgColor;  
        uint[5] shape_keys;
        uint[5] shape_colors;    
    }

    // Message
    struct Token
    {
        string message;
        uint seed;
    }

    Shapes[17] private shapes;        
    string[17] private colors;
    string public base64Font;
    mapping (uint => Token) private tokenMeta;
    mapping (string => bool) private messageStore;

    constructor(IERC20 _paymentContract) ERC721("Message on a Blockchain", "MOABC") 
    {
        // Randomseed to start
        randomSeed = 10001000100011001010011; // Add 0 in front <3
        
        // SOS contract
        paymentContract = _paymentContract;
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
    function setMessage(uint256 tokenId, string calldata _message) external onlyOwner {
        tokenMeta[tokenId].message = _message;
    }

    function getMessage(uint256 tokenId) public view returns (string memory)
    {
        return tokenMeta[tokenId].message;
    }

    function messageExists(string calldata _message) public view returns (bool)
    {
        return messageStore[_message];
    }

    function getRandomSeed() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, randomSeed, block.timestamp, msg.sender, totalSupply())));
    }

    // In case contract changes
    function setSOSContract(IERC20 _paymentContract) external onlyOwner
    {
        // payment contract
        paymentContract = _paymentContract;
    }    

    // In case volatility forces a price adjustmenst
    function setPrice(uint _priceInPaymentToken) external onlyOwner
    {
        // payment contract
        priceInPaymentToken = _priceInPaymentToken;
    }    

    function setBase64Font(string memory _base64Font) external onlyOwner
    {
        base64Font = _base64Font;
    }

    function mint(string calldata _message) external {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= maxTokens,"Max Minted");    
        require(!messageExists(_message),"Message already exists");    

        paymentContract.transferFrom(msg.sender,targetWallet,priceInPaymentToken);        
        
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
        uint r;
        uint r_col;
        uint _shapeLength;
        uint _colorLength;
        uint _shapeKey;
        uint _colorKey;
        Traits memory memTraits;        

        // Get the seed to derive the traits
        r = tokenMeta[_tokenId].seed;

        _shapeLength = shapes.length; // saving a little gas
        _colorLength = colors.length; // saving a little gas

        // Background color
        memTraits.bgColor = r % _colorLength;

        // Messages        
        memTraits.message = tokenMeta[_tokenId].message;        

        // Element count
        uint _elementCount = r % 6;
        _elementCount = _elementCount < 2 ? 2 : _elementCount; // 2 Elements min, 5 max

        for (uint i = 0; i < _elementCount; i++){
            r = r - i;
            r_col = r - _elementCount - memTraits.bgColor;
            _shapeKey =  r % _shapeLength;
            _colorKey =  r_col % _colorLength;

            memTraits.shape_keys[i] = _shapeKey > 0 ? _shapeKey : 1; // never 0, fall back to 1 in case
            memTraits.shape_colors[i] =  _colorKey > 0 ? _colorKey : 1;
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
            '{"trait_type":"Background","value":"',
            string(abi.encodePacked(string(abi.encodePacked(colors[memTraits.bgColor])))), // Looks weird but gets rid of allocated bytes that bust the SVG
            '"}'
            ))));

        // SVG prep
        svg_output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRadio="xMinYMin meet" viewBox="0 0 350 350">';
        svg_output = string(abi.encodePacked(
            svg_output,
            '<rect style="fill:',colors[memTraits.bgColor],'" width="100%" height="100%" x="0" y="0" />'));
        

        // Elements
        for(uint i = 0; i < memTraits.shape_keys.length; i++)
        {
            if(memTraits.shape_keys[i] > 0)
            {
                attributes = string(abi.encodePacked(attributes,getShapeAttributes(memTraits.shape_keys[i],memTraits.shape_colors[i],i)));
                svg_output = string(abi.encodePacked(svg_output,getShapeSVG(memTraits.shape_keys[i],memTraits.shape_colors[i],i)));
            }            
        }

        // SVG Close + message
        // Fonts are tricky to handle in SVGs - just using any font will make the text look differently for every device that has not installed the font.
        // CSS offers an import possibilitiy to load fonts from an external source such as Google Fonts at loading
        // However, this was not an option because of a.) The style depends on availabilitiy of the external source and b.) If the SVG is embedded e.g. in an HTML img tag, the external source is ignored and the font falls back to a standard.
        // The best solution to this problem is to store the font base 64 encoded in this smart contract
        svg_output = string(abi.encodePacked(
            svg_output,
            '<style>@font-face {font-family: "candalregular";src: url(data:application/font-woff;charset=utf-8;base64,',
            base64Font,
            'font-weight: normal; font-style: normal;}</style><foreignObject  width="100%" height="350" x="0" y="0" requiredExtensions="http://www.w3.org/1999/xhtml">',
            '<div xmlns="http://www.w3.org/1999/xhtml" style="display: flex; align-items: center; position:relative; justify-content: center; height: 100%;">',
            '<p id="preview" style="padding: 0px; color: white; text-align: center; color: white; font-family: candalregular, sans-serif; font-size:40px; -webkit-text-stroke: 2px black;">',
            memTraits.message,
            '</p></div></foreignObject></svg>')); 

        string memory metaData =  string(abi.encodePacked(
                '{"name": "MOABC #',
                toString(tokenId),
                '", "description": "Your message, 100% generated and stored on the Ethereum blockchain. No IPFS, no centralized data storage or API.","image": "data:image/svg+xml;base64,',
                base64(bytes(svg_output)),
                '", "attributes":[',
                attributes,
                "]}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metaData))
            ));
    }

    function getShapeAttributes(uint shape_key, uint shape_color, uint i) public view returns (string memory) 
    {
        string memory compiledAttributes;
     
        compiledAttributes = string(abi.encodePacked(compiledAttributes,string(abi.encodePacked(
            ',{"trait_type":"Element ',
            toString(i),
            '","value":"',
            string(abi.encodePacked(shapes[shape_key].name)),
            '"}',
            ',{"trait_type":"Element ',
            toString(i),
            ' Color","value":"',
            string(abi.encodePacked(colors[shape_color])),
            '"}'
        ))));    
    
        return compiledAttributes;
    }

    function getShapeSVG(uint shape_key, uint shape_color, uint i) public view returns (string memory) 
    {
        string memory svg_output;  
        string memory traitSvg;                
        string memory colorName;
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
            string(abi.encodePacked(colorName)),
            '; opacity:0.75; }</style>'));

        // Drawing path
        svg_output = string(abi.encodePacked(
            svg_output,
            '<path class="e',
            toString(i),
            '" ',
            traitSvg));        
               
        return svg_output;
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

/** BASE 64 - Written by Brech Devos - taken from Wolf game contract*/  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
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