/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//Younwoo Noh

pragma solidity 0.8.0;

    contract Likelion_17 {
        
        mapping(uint => uint)number;
        
        uint[] lotteryNum = [1,2,3,4,5,6];
        
        function setNumber(uint a, uint b, uint c, uint d, uint e, uint f) public {
            number[a] = lotteryNum[0];
            number[b] = lotteryNum[1];
            number[c] = lotteryNum[2];
            number[d] = lotteryNum[3];
            number[f] = lotteryNum[4];
            number[e] = lotteryNum[5];
        }
        
        function getNumber(uint a, uint b, uint c, uint d, uint e, uint f) public view returns(uint) {
        
            if(lotteryNum[0] == a) {
                if(lotteryNum[1] == b) {
                    if(lotteryNum[2] == c) {
                        if(lotteryNum[3] == d) {
                            if(lotteryNum[4] == e) {
                                if(lotteryNum[5] == f) {
                                    return 50000;
                                }
                            }
                        }
                    }
                }
            }
        }
    }