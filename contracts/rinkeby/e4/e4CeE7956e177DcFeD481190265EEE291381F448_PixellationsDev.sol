/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity 0.8.9;

contract PixellationsDev {
    
    uint256 public tokenCount = 0;
    
    function fakeMint() public returns (uint256) {
        tokenCount++;
        return tokenCount;
    }
    
    function getRandomNumber(uint256 token, uint256 min, uint256 max) public pure returns (uint256) {
        uint256 range = max - min;
        return max - uint256(keccak256(abi.encodePacked(token))) % range - 1;
    }
    
    function longString(uint256 min, uint256 max) public view returns (string memory result) {
        uint256 maxLength = getRandomNumber(tokenCount, min, max);
        for (uint256 i = 0; i < maxLength; i++) {
            result = string(abi.encodePacked(result, 'star ', uint2str(i), ' '));
        }
        return result;
    }
    
    // From https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
}