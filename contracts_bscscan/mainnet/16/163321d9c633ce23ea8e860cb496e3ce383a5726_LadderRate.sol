/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract LadderRate {

    mapping(uint => uint) ratesMap;

    uint[] public rateDays;

    address owner;

    uint constant RATE_BASE = 1000;


    constructor(){
        owner = msg.sender;
    }

    modifier isOwner(){
        require(msg.sender == owner,'not owner');
        _;
    }

    function setRate(uint day, uint rate) public isOwner{
        ratesMap[day] = rate;
        rateDays.push(day);
    }

    function getRate(uint day) public view returns(uint){
        return ratesMap[day];
    }

    function removeRate(uint day) public isOwner{
        delete ratesMap[day];
        uint dayIndex = 0;
        while (rateDays[dayIndex] != day) {
            dayIndex++;
        }
        rateDays[dayIndex] = rateDays[rateDays.length-1];
        rateDays.pop();
    }

    /** records 二维数据 传递 充值记录 【time,amount】 时间，金额*/
    function calcRate(uint[2][] memory records,uint totalWithdrawAmount,uint withdrawAmount) public view returns(uint){
        uint totalDeposit = 0;
        if(rateDays.length == 0){
            return 0;
        }
        for(uint i = 0; i < records.length; i ++){
            totalDeposit =  totalDeposit + records[i][1];
        }
        require(totalDeposit >= totalWithdrawAmount + withdrawAmount,"not enought balance");
        uint fee = 0;
        uint[] memory descDays = reverseArray(sortArray(rateDays));
        for(uint i = 0; i < descDays.length; i ++){
            uint day = descDays[i];
            uint rate = ratesMap[day];
            uint reduceAmount = 0;
            for(uint j = 0; j < records.length; j ++){
                uint time = records[j][0];
                uint amount = records[j][1];
                if(block.timestamp >= time + day * 1 days){
                    reduceAmount = reduceAmount + amount;
                }
            }
            if(reduceAmount <= totalWithdrawAmount){
                continue;
            }
            uint bal = reduceAmount - totalWithdrawAmount;
            if(bal >= withdrawAmount){
                fee = fee + withdrawAmount* rate / RATE_BASE;
                break;
            }else{
                fee = fee + bal * rate / RATE_BASE;
                totalWithdrawAmount = totalWithdrawAmount + bal;
                withdrawAmount = withdrawAmount - bal;
            }
        }
        return fee;
    }


    function quickSortArray(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortArray(arr, left, j);
        if (i < right)
            quickSortArray(arr, i, right);
    }

    function sortArray(uint[] memory data) private pure returns (uint[] memory) {
        quickSortArray(data, int(0), int(data.length - 1));
        return data;
    }

    function reverseArray(uint[] memory data) private pure returns (uint[] memory) {
        uint i = 0;
        uint j = data.length-1;
        while(i < j){
            uint temp = data[i];
            data[i] = data[j];
            data[j] = temp;
            i += 1;
            j -= 1;
        }    
        return data;
    }
}