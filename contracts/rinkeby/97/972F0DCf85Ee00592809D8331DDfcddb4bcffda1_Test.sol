// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Datetime.sol";
contract Test is Datetime{
    uint decimals = 10 ** 18;
    uint dayLen = 60*60*24;
    mapping(uint => mapping(uint => uint)) public signRatePath;
    constructor () public {
        signRatePath[3][202109] = 1*10**16;
        signRatePath[3][202110] = 2*10**16;
        signRatePath[3][202111] = 3*10**16;
    }
    function computStakingProfit(uint _time)  public view returns (uint profit){
        uint passMonths = passMonthCount(_time);
        uint computYear = uint(20210901)/uint(10000);
        uint computMonth = uint(20210901)/uint(100)%100;
        uint num;
        uint monthSecord;
        uint computEndTime = 20210901;
        for(uint8 i=0;i<=passMonths;i++){
            if(computMonth >12){
                computYear  = computYear + 1;
                computMonth = 1;
            }
            num = 1000000000000000000000*signRatePath[3][computYear*100+computMonth]*1*10**18;
            num = num/decimals/decimals;
            num = num*dayLen/getDaysInMonth(computMonth,computYear)*60*60*24;
            monthSecord = getDaysInMonth(computMonth,computYear) - computEndTime%100;
            monthSecord = monthSecord*60*60*24/dayLen;

            profit += num*monthSecord;
            if(computMonth < 12){
                computEndTime = computYear*10000+computMonth*100+100;
            }else{
                computEndTime = computYear*10000+10000+100;
            }
            
        }


    }
    function text1() public pure returns(uint){
        return uint(20210911)/uint(10000);
    }
    function text2() public pure returns(uint){
        return uint(20210911)/uint(100)%100;
    }
    function text4() public pure returns(uint){
        return uint(20210911)/uint(100);
    }
    function text3() public view returns(uint,uint,uint){
        uint num = 1000000000000000000000*signRatePath[3][2021*100+9]*1*10**18;
        num = num*dayLen*60*60*24/getDaysInMonth(9,2021);
        num = num/decimals/decimals;
        uint monthSecord = getDaysInMonth(9,2021) - 20210901%100 + 1;
        monthSecord = monthSecord*60*60*24/dayLen;
        return (num*monthSecord,num,monthSecord);
    }
    function text5() public view returns(uint,uint,uint){
        uint num = 1000000000000000000000*signRatePath[3][2021*100+10]*1*10**18;
        num = num*dayLen*60*60*24/getDaysInMonth(10,2021);
        num = num/decimals/decimals;
        uint monthSecord = 15;
        monthSecord = monthSecord*60*60*24/dayLen;
        return (num*monthSecord,num,monthSecord);
    }
    function passMonthCount(uint _time) public view returns (uint passMonths) {
        uint curDate;
        if(getYmd(_time) >= 20211211){
            curDate =  20211211;
        }else{
            // curDate = getYmd(block.timestamp);
            curDate = getYmd(_time);
            
        }
        uint passTime = curDate - 20210911;
        passMonths = passTime/100%100+passTime*12/10000;
    }

}