/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

library GeopolyFarmingHelper {
	function findIndexInArr(uint256 val, uint256[] memory arr) public pure returns(bool,uint256){
        for(uint256 i=0; i<arr.length; i++){
            if(val == arr[i]){
                return(true, i);
            }
        }
        return(false, 0);
    }

    function getFirstDigit(uint256 _in) public pure returns(uint256){
        uint256 temp = _in;
        while(temp >= 10){
            temp /= 10;
        }
        return temp;
    }

    function getValue(uint256 _in) public pure returns(uint256){
        uint256 temp = _in;
        uint256 cnt = 1;
        uint256 val = 0;
        while(temp >= 10){
            cnt += 1;
            temp /= 10;
        }
        if(cnt > 3){
            uint256 _dCnt = cnt-3;
            uint256 temp2 = 0;
            val = temp*(10**_dCnt);
            for(uint256 i=0; i<_dCnt; i++){
                temp2 = getFirstDigit((_in - (temp*(10**(cnt-1-i)) ) ));
                val += temp2*(10**(_dCnt-(i+1)));
                temp = temp2;
            }
        }else{
            val = temp;
        }
        return(val);
    }
}