/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
interface iCalculator
{
    function addition(int, int) external pure returns(int);
    function multiplication(int, int) external pure returns(int);
}
 
contract ArrayCalculator{
    iCalculator calculator;
    
    constructor(address _adr){
        calculator = iCalculator(_adr);
    }
    
    function sumOfArray(int[] memory data)public view returns(int){
        int sum = 0;
        for(uint i = 0; i < data.length; i++){
            sum = calculator.addition(sum, data[i]);
        }
        return sum;
    }
    
    function multiplicationOfArray(int[] memory data)public view returns(int){
        int mult = 1;
        for(uint i = 0; i < data.length; i++){
            mult = calculator.multiplication(mult, data[i]);
        }
        return mult;
    }
}