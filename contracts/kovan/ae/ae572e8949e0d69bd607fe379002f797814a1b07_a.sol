/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

contract a {
    uint[] public options;
    function setOption(uint a) external {
        options.push(a);
    }
    function getOptions(uint b) external returns(uint[] memory result){
        uint arrayLength = options.length;
        uint resultLength = 0; 
        for(uint i=0; i < arrayLength; i++){
            if(options[i]>b){
                resultLength++;
            }
        }
        result = new uint[](resultLength);
        uint j=0;
        for(uint i=0; i < arrayLength; i++){
            if(options[i]>b){
                result[j] = options[i];
                j++;
            }
        }
        require (b>0,'error');
        options.push(b);
    }
    function aaa(uint a) external{
        require(a>5,'addfds');
    }
}