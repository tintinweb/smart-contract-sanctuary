/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

library GeoSpecial {
    /**
     * @dev mutiple arithmatic, types and logical checks can be implemented
     * to ensure proper propogation of the contract when calling this library.
     * However, checks are actually done in the contract itself as a result of
     * the owner having the freedom in picking and choosing from the list of outcomes
     * that this library produces. mainly the functions:
     * 1- `GeoPoly.addToMints`
     * 2- `GeoPoly.resetReservedNFTs`
     */
    function disect(bytes calldata _in) public pure returns(bytes32[] memory){ //  
        bytes32[] memory output = new bytes32[](5);
        uint256 curIdx = 0;
        uint256 oIdx = 0;
        for(uint256 i=0; i<_in.length; i++){
            if(_in[i] == 0x2f){
                output[oIdx] = bytes32(_in[curIdx:i]);
                oIdx++;
                curIdx = i+1;
            }
        }
        output[4] = bytes32(_in[curIdx:_in.length]);
        return(output);
    }
        
    function format(bytes32[] memory _inArr) public pure returns(uint256 category, uint256 tier, uint256 price, string memory lat, string memory lng){
        category = uint256(asciiToInteger(_inArr[0]));
        tier = uint256(asciiToInteger(_inArr[1]));
        price = uint256(asciiToInteger(_inArr[2]));
        lat = bytes32ToString(_inArr[3]);
        lng = bytes32ToString(_inArr[4]);
    }
    
    function convertStringToByes(string calldata _in) public pure returns(bytes calldata _out){

        _out = bytes(_in);
    }
    
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint256 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    function asciiToInteger(bytes32 x) public pure returns (uint256) {
            uint256 y;
            for (uint256 i = 0; i < 32; i++) {
                uint256 c = (uint256(x) >> (248 - i * 8)) & 0xff;
                if (48 <= c && c <= 57)
                    y += (c - 48) * 10 ** i;
                 else if (65 <= c && c <= 90)
                    y += (c - 65 + 10) * 10 ** i;
                else if (97 <= c && c <= 122)
                    y += (c - 97 + 10) * 10 ** i;
                else
                    break;
            }
            return y;
    }
    
    function doAll(string calldata _in) public pure returns(uint256 cat, uint256 tier, uint256 _price, string memory lat, string memory lng){

        return(format(disect(convertStringToByes(_in))));
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
 
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

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

}