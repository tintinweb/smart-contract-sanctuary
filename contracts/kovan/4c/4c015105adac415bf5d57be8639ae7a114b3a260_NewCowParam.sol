/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// File: Volumes/code/remix/my/new_cow/MathX128.sol



pragma solidity ^0.8.7;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: Volumes/code/remix/my/new_cow/INewCowInviteParam.sol



pragma solidity ^0.8.7;

interface INewCowInviteParam {
    function oneLevelFee(uint amount,uint oneLevelNumber) external view returns(uint);
    
    function twoLevelFee(uint amount,uint twoLevelNumber) external view returns(uint);
}
// File: Volumes/code/remix/my/new_cow/INewCowParam.sol



pragma solidity ^0.8.7;


interface INewCowParam is INewCowInviteParam {
    function sellPrice(uint level) view external returns(uint);//用户购买价格
    
    function recoveryPrice(uint level) view external returns(uint);//牛牛回收价格
    
    function blindBoxPrice() view external returns(uint);//盲盒价格
    
    function blindBoxLevel(uint probabilityX128) view external returns(uint);//盲盒等级
    
    function upgradeSuccessProbability(uint level) view external returns(uint);//牛牛升级成功概率
    
    function upgradePrice(uint level) view external returns(uint);//牛牛升级价格
    
    function power(uint level) view external returns(uint);//牛牛算力
    
    function incomeFee(uint value,uint lastBlock) view external returns(uint);//牛牛算力收益手续费
}

// File: Volumes/code/remix/my/new_cow/param/NewCowParam.sol



pragma solidity ^0.8.7;



contract NewCowParam is INewCowParam {
    
    using MathX128 for uint;
    
    function sellPrice(uint level) pure external override returns(uint){
        require(level==1,'level must eq 1');
        return 25*10**18;
    }
    
    uint[31] private recoveryPriceList=[uint(0),2000, 2400, 2880,3456,4147,4977,5972,7166,8600,10320,12383,14860,17832,21399,25678,30814,36977,44372,53247,63896
    ,76675,92010,110412,132495,158994,190792,228951,274741,329689,395627];
    
    function recoveryPrice(uint level) view external override returns(uint){
        if(level<recoveryPriceList.length)
            return recoveryPriceList[level]*10**16;
        else
            return 0;
    }
    
    function blindBoxPrice() pure external override returns(uint){
        return 100*10**18;
    }
    
    uint[31] private blindBoxProbability=[uint(0),1937,1535,1225,984,794,643,523,426,348,285,234,192,158,130,107,88,73,60,50,41,34,28,23,19,16,13,11,9,8,6];
    
    function blindBoxLevel(uint probabilityX128) view external override returns(uint){
        uint probability=probabilityX128.toPercentage(2);
        for(uint i=0;i<blindBoxProbability.length;i++){
            if(probability<blindBoxProbability[i]){
                return i;
            }
            probability-=blindBoxProbability[i];
        }
        return 1;
    }
    
    uint[31] private upgradeFailProbability=[uint(0),5,8,11,13,16,19,21,24,27,29,32,35,37,40,43,45,48,51,53,56,59,61,64,67,
    69,72,75,77,80,100];
    
    function upgradeSuccessProbability(uint level) view external override returns(uint){
        require(level<upgradeFailProbability.length);
        uint successProbability=100-upgradeFailProbability[level];
        return successProbability.toX128(0);
    }
    
    uint[31] private upgradePriceList=[uint(0),500,600,720,864,1037,1244,1493,1792,2150,2580,3096,3715,4458,5350,6420,7704,9244,11093,13312,15974,19169,
    23003,27603,33124,39748,47698,57238,68685,82422];
    
    function upgradePrice(uint level) view external override returns(uint){
        require(level<upgradePriceList.length);
        return upgradePriceList[level]*10**16;
    }
    
    uint[31] private powerList=[uint(0),100,123,151,186,229,282,347,427,527,649,801,988,1219,1506,1862,2304,2853,3536,4387,5451,6782,8452,10554,13208,16575,
    20868,26375,33500,42798,55104];
    function power(uint level) view external override returns(uint) {
        require(level<powerList.length);
        return powerList[level];
    }
    
    function incomeFee(uint value,uint lastBlock) view external override returns(uint) {
        uint day=(block.number-lastBlock)/28800;
        uint feeRatePercentage=0;
        if(day<=15)feeRatePercentage=15-day;
        return value*100/feeRatePercentage;
    }
    
    function oneLevelFee(uint amount,uint oneLevelNumber) external override pure returns(uint){
        if(oneLevelNumber==0)return 0;
        if(oneLevelNumber<=10)
            return amount*20/100;
        if(oneLevelNumber<=50)
            return amount*30/100;
        if(oneLevelNumber<=100)
            return amount*40/100;
        if(oneLevelNumber<=500)
            return amount*50/100;
        return amount*70/100;
    }
    
    function twoLevelFee(uint amount,uint twoLevelNumber) external override pure returns(uint) {
        if(twoLevelNumber==0)return 0;
        if(twoLevelNumber<=100)
            return amount*5/100;
        if(twoLevelNumber<=300)
            return amount*8/100;
        if(twoLevelNumber<=800)
            return amount*10/100;
        if(twoLevelNumber<=1500)
            return amount*15/100;
        return amount*20/100;
    }
}