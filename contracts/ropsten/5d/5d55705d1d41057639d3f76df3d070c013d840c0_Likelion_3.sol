/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.8.0;

contract Likelion_3 {
    uint[] scores = [70,55,25,15,95,85,90,40,35,90];
    
    function setGrade() public returns(uint,uint,uint,uint,uint,uint,uint,uint){
        uint sum1 = 0;
        uint count1 = 0;
        uint sum2 = 0;
        uint count2 = 0;
        uint sum3 = 0;
        uint count3 = 0;
        uint sum4 = 0;
        uint count4 = 0;
        for (uint i=0; i<scores.length; i++){
            if(scores[i] >=80) {
                sum1+=scores[i];
                count1++;
            } else if(scores[i]>=70){
                sum2+=scores[i];
                count2++;
            } else if(scores[i]>=50){
                sum3+=scores[i];
                count3++;
            } else{
                sum4+=scores[i];
                count4++;
            }
        }
        return (count1,sum1/count1,count2,sum2/count2,count3,sum3/count3,count4,sum4/count4);
    }
    function mean() public returns(uint,uint,uint,uint){
        uint sum1 = 0;
        uint count2 = 0;
        uint sum2 = 0;
        uint count3 = 0;
        uint sum3 = 0;
        uint count4 = 0;
        uint sum4 = 0;
        for (uint i=0; i<scores.length; i++){
            sum1+=scores[i];
            if (scores[i]>=70){
                sum2+=scores[i];
                count2++;
            }else if (scores[i]>40){
                sum3+=scores[i];
                count3++;
            }else if (scores[i]<=40){
                sum4+=scores[i];
                count4++;
            }
        }
        return (sum1/scores.length , sum2/count2 , sum4/count4 , sum3/count3);
    }
}