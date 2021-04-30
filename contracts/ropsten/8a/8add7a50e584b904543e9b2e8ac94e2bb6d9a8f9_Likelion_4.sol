/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_4 {
    uint[] students = [70,55,25,15,95,85,90,40,35,90];
    function MakeGroup() public view  returns(uint, uint, uint,uint) {
        uint group1_sum = 0;
        uint group2_sum = 0;
        uint group3_sum = 0;
        uint group4_sum = 0;
        uint cnt2 = 0;
        uint cnt3 = 0;
        uint cnt4 = 0;
        for(uint i=0; i<students.length; i++){
            group1_sum += students[i];
            if(students[i] >= 70) {
                group2_sum += students[i];
                cnt2++;
            }else if(students[i] <= 40) {
                group3_sum += students[i];
                cnt3++;
            }else  {
                group4_sum += students[i];
                cnt4++;
            }
        }
        
        return (group1_sum/students.length, group2_sum/cnt2, group3_sum/cnt3, group4_sum/cnt4);
    }
    
        function MakeGroup2() public view returns(uint, uint, uint,uint, uint, uint, uint,uint) {
        uint group1_sum = 0;
        uint group2_sum = 0;
        uint group3_sum = 0;
        uint group4_sum = 0;
        uint cnt1 =0;
        uint cnt2 =0;
        uint cnt3 =0;
        uint cnt4 =0;
        
        for(uint i=0; i<students.length; i++){
            if(students[i] >= 80) {
                group1_sum += students[i];
                cnt1++;
            }else if(students[i] >= 70 && students[i] < 80) {
                group2_sum += students[i];
                cnt2++;
            }else if(students[i] >= 50 && students[i] < 70) {
                group3_sum += students[i];
                cnt3++;
            }else {
                group4_sum += students[i];
                cnt4++;
            }
        }
        
        return (group1_sum/students.length, cnt1, group2_sum/cnt2, cnt2,  group3_sum/cnt3, cnt3,  group4_sum/cnt4, cnt4);
    }
}