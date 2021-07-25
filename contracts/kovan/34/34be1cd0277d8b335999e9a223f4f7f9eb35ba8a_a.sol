/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

contract a {
    uint[] public options;
    function setOption(uint a) external {
        options.push(a);
    }
    function getOptions(uint b) public view returns(uint[] memory result){
        uint arrayLength = options.length;
        uint resultLength = 0; 
        for(uint i=0; i < arrayLength; i++){
            if(options[i]>b){
                result[resultLength] = options[i];
                resultLength++;
            }
        }
    }
}