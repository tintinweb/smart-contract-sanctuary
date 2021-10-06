/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.8.7;

contract colorgradient{
    
        /*string[15] private color1 = ["#FBE3B9","#FAB696","#0C9463","#2D334A","#698474","#889E81","#BAC7A7","#E5E4CC","#018383","#02A8A8","#42E6A4","#F5DEA3","#FFFFFF","#F9F6F7","#FFE8D6"];
        string[15] private color2 = ["#FFF119", "#FFA25C", "#234E3A", "#549E6F", "#DA9EDE", "#4F242C", "#1F71BB", "#D63A42", "#85BFC9", "#DAA4D6", "#783B00", "#000000", "#AAAAB3", "#D93998", "#5A3671"];
        string[15] private color3 = ["#946A63", "#1C6A63", "#9184B3", "#F0A17A", "#709436", "#42FCA2", "#5CFFDC", "#FCF942", "#34FFFF", "#8047D9", "#D0ABD9", "#369CA1", "#A05394", "#ED7842", "#FF001A"];
        string[15] private color4 = ["#2DE0FF", "#13606E", "#61A773", "#E0ABD3", "#FF90E4", "#E0D8D3", "#C2BDFF", "#A6001E", "#28B2E0", "#4A002B", "#6B00AA", "#FFBABD", "#FFBA13", "#E38481", "#FFFC33"];
        string[15] private color5 = ["#3FB330", "#0CA5AD", "#F475AD", "#FA7737", "#A05B30", "#A13045", "#C276F5", "#0076F5", "#E876F5", "#C4ADC7", "#FAEE82", "#1F3F2A", "#9D3691", "#997395", "#F5539C"];
    */
    mapping(uint256 => uint32) private _hexColors1;
    mapping(uint256 => uint32) private _hexColors2;
    mapping(uint32 => bool) public existingHexColorsA;
    
    /*constructor() public{
        
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getRandomNumber(uint256 tokenId) public view returns(uint256){
        uint256 rand = random(string(abi.encodePacked(block.timestamp,"colors",toString(tokenId))));
        return rand % 100;
    }
    function getColorArray(uint256 pca,uint256 tokenId) public view returns(string memory){
        string[15] memory finalColorArray;
        uint256 number = getRandomNumber(tokenId);
        uint256 index=0;
        if(pca==0){finalColorArray = color1;}
        if(pca==1){finalColorArray = color2;}
        if(pca==2){finalColorArray = color3;}
        if(pca==3){finalColorArray = color4;}
        if(pca==4){finalColorArray = color5;}
        
        if(number>=0 && number < 6){
            index=0;
            return finalColorArray[index];
        }
        if(number>=6 && number < 12){
            index=1;
            return finalColorArray[index];
        }
        if(number>=12 && number < 18){
            index=2;
            return finalColorArray[index];
        }
        if(number>=18 && number < 25){
            index=3;
            return finalColorArray[index];
        }
        if(number>=25 && number < 29){
            index=4;
            return finalColorArray[index];
        }
        if(number>=29 && number < 35){
            index=5;
            return finalColorArray[index];
        }
        if(number>=35 && number < 42){
            index=6;
            return finalColorArray[index];
        }
        if(number>=42 && number < 48){
            index=7;
            return finalColorArray[index];
        }
        if(number>=48 && number < 54){
            index=8;
            return finalColorArray[index];
        }
        if(number>=54 && number < 60){
            index=9;
            return finalColorArray[index];
        }
        if(number>=60 && number < 66){
            index=10;
            return finalColorArray[index];
        }
        if(number>=66 && number < 72){
            index=11;
            return finalColorArray[index];
        }
        if(number>=72 && number < 78){
            index=12;
            return finalColorArray[index];
        }
        if(number>=78 && number < 84){
            index=13;
            return finalColorArray[index];
        }
        if(number>=84 && number < 100){
            index=14;
            return finalColorArray[index];
        }
        return finalColorArray[index];
    }
    
    function getcolor(uint256 tokenId) public view returns(string memory){
        uint256 randomOfColorArray = random(string(abi.encodePacked(block.timestamp,toString(tokenId)))) % 10;
        uint256 rca=0;
        if(randomOfColorArray>=0 && randomOfColorArray < 2){rca=0;}
        if(randomOfColorArray>=2 && randomOfColorArray < 4){rca=1;}
        if(randomOfColorArray>=4 && randomOfColorArray < 6){rca=2;}
        if(randomOfColorArray>=6 && randomOfColorArray < 8){rca=3;}
        if(randomOfColorArray>=8 && randomOfColorArray < 10){rca=4;}
        return getColorArray(rca,tokenId);
    }*/
    
    function generateSVGImage(string memory hexString1,string memory hexstring2) internal pure returns(string memory){
        string[7] memory parts;
        
        parts[0] = '<svg width="400" height="400" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="200" height="200" fill="url(#paint0_linear)"/>';

        parts[1] = '<defs><linearGradient id="paint0_linear" x1="0" y1="100" x2="200" y2="100" gradientUnits="userSpaceOnUse">';
        
        parts[2] = '<stop stop-color="';
        
        parts[3] = hexString1;
        
        parts[4] ='"/><stop offset="1" stop-color="';
        
        parts[5] = hexstring2;
        
        parts[6] = '"/></linearGradient></defs></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        return output;
    }
    
    function uintToHexString(uint256 number) public pure returns(string memory) {
        bytes32 value = bytes32(number);
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(6);
        for (uint i = 0; i < 3; i++) {
            str[i*2] = alphabet[uint(uint8(value[i + 29] >> 4))];
            str[1+i*2] = alphabet[uint(uint8(value[i + 29] & 0x0f))];
        }
        
        return string(str);
    }
    
    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint quotesCount = 0;
        for (uint i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
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
    
    
    function generateAttributes(uint32 hexColorA, uint32 hexColorB,string memory hexStringA,string memory hexStringB) internal pure returns (string memory) {
        string memory rA = toString((hexColorA >> 16) & 0xFF);  // Extract the RR byte
        string memory gA = toString((hexColorA >> 8) & 0xFF);   // Extract the GG byte
        string memory bA = toString((hexColorA) & 0xFF);        // Extract the BB byte
        
        string memory rB = toString((hexColorB >> 16) & 0xFF);  // Extract the RR byte
        string memory gB = toString((hexColorB >> 8) & 0xFF);   // Extract the GG byte
        string memory bB = toString((hexColorB) & 0xFF);        // Extract the BB byte

        string memory rgbA = string(abi.encodePacked('rgb(', rA, ',', gA, ',', bA, ')'));
        string memory rgbB = string(abi.encodePacked('rgb(', rB, ',', gB, ',', bB, ')'));

        return string(
            abi.encodePacked(
                '"attributes":[',
                '{"trait_type":"Hex code","value":"#',
                hexStringA,'"and"',hexStringB,
                '"},'
                '{"trait_type":"RGB","value":"',
                rgbA,'{"trait_type":"RGB","value":"',rgbB,
                '"},',
                '{"trait_type":"Red","value":"',
                rA,'"and"','{"trait_type":"Red","value":"',rB,
                '"},',
                '{"trait_type":"Green","value":"',
                gA,'"and"','{"trait_type":"Red","value":"',gB,
                '"},',
                '{"trait_type":"Blue","value":"',
                bA,'"and"','{"trait_type":"Red","value":"',bB,
                '"}',
                ']'
            )
        );
    }
    
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        uint32 hexColorA = _hexColors1[tokenId];
        uint32 hexcolorB = _hexColors2[tokenId];
        string memory hexStringA = uintToHexString(hexColorA);
        string memory hexStringB = uintToHexString(hexcolorB);
        string memory image = Base64.encode(bytes(generateSVGImage(hexStringA,hexStringB)));
        
        return string(
            abi.encodePacked(
                'data:application/json',
                '{',
                '"image":"',
                'data:image/svg+xml;base64,',
                image,
                '",',
                '"image_data":"',
                escapeQuotes(generateSVGImage(hexStringA,hexStringB)),
                '",',
                generateAttributes(hexColorA,hexcolorB, hexStringA,hexStringB),
                '}'
            )
        );
    }
    
    function getTokenSVG(uint256 tokenId) public view returns (string memory) {
        uint32 hexColorA = _hexColors1[tokenId];
        uint32 hexColorB = _hexColors2[tokenId];
        string memory hexStringA = uintToHexString(hexColorA);
        string memory hexStringB = uintToHexString(hexColorB);
        return generateSVGImage(hexStringA,hexStringB);
    }
    
    function getBase64TokenSVG(uint256 tokenId) public view returns (string memory) {
        uint32 hexColorA = _hexColors1[tokenId];
        uint32 hexColorB = _hexColors2[tokenId];
        string memory hexStringA = uintToHexString(hexColorA);
        string memory hexStringB = uintToHexString(hexColorB);
        string memory image = Base64.encode(bytes(generateSVGImage(hexStringA,hexStringB)));
        return string(
            abi.encodePacked(
                'data:application/json;base64',
                image
            )
        );
    }
    
    function getHexColors(uint256 tokenId) public view returns (string memory) {
        uint32 hexColorA = _hexColors1[tokenId];
        uint32 hexColorB = _hexColors2[tokenId];
        string memory hexStringA = uintToHexString(hexColorA);
        string memory hexStringB = uintToHexString(hexColorB);
        return string(
            abi.encodePacked(
                '#',
                hexStringA,'"and"','#',hexStringB
            )
        );
    }
    
    function generateRandomHexColor(uint256 tokenId) internal returns (uint32) {
        uint32 hexColor = uint32(_rng() % 16777215);

        while (existingHexColorsA[hexColor] || existingHexColorsA[hexColor]) {
          hexColor = uint32(uint256(hexColor + block.timestamp * tokenId) % 16777215);
        }

        existingHexColorsA[hexColor] = true;
        if(_hexColors1[tokenId] <= 0){
            _hexColors1[tokenId] = hexColor;
        }
        else{
            _hexColors2[tokenId] = hexColor;
        }
        return hexColor;
    }
    
    function _rng() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty))) +
                uint256(keccak256(abi.encodePacked(block.coinbase))) / block.number + block.gaslimit;
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