/**
 *Submitted for verification at polygonscan.com on 2021-11-26
*/

contract test{
        // 生成6位随机数
    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);

        uint8 length = 0;
        for (uint256 i = 0; i < n; ) {
            bool found = false;
            uint256 value = (uint256(keccak256(abi.encode(randomValue, i*7))) % 30)+1;
            
            for(uint8 j = 0; j < length;j++){
                if(expandedValues[j] == value){
                    found = true;
                    break;
                } 
            }

            if (found == false){
                expandedValues[i] = value;
                length++;
                i++;
            }
        }
        return expandedValues;
    }
}