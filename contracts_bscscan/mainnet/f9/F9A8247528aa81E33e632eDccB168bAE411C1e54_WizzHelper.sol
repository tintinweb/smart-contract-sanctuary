/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

library WizzHelper {
    function findHeroBase(uint256 _mintIdx) public pure returns (uint256){
        if (_mintIdx < 2500){
            return 0;
        }else if (_mintIdx < 5000){
            return 0;
        }else if (_mintIdx < 7500){
            return 0;
        }else if (_mintIdx < 10000){
            return 0;
        }else if (_mintIdx < 11500){
            return 1;
        }else if (_mintIdx < 13000){
            return 1;
        }else if (_mintIdx < 14500){
            return 1;
        }else if (_mintIdx < 15250){
            return 2;
        }else if (_mintIdx < 16000){
            return 2;
        }else{
            return 10;
        }
    }

    function getNth(uint256 number, uint256 nth) public pure returns (uint256, uint256) { 
        uint256 _divsor = 10**nth; 
        uint256 cnt = 0;
        while (number >= _divsor*10) {
            number /= 10;
            cnt+=1;
        }
        uint256 _bSub = number;
        number /= 10;
        return ((_bSub - (number*10)), (cnt+nth));
    }
}