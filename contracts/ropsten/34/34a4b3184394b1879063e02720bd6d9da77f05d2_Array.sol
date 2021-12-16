/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

interface iCalc{
    function mul(uint, uint) external pure returns(uint);
    function sum(uint, uint) external pure returns(uint);
}

contract Array{
    iCalc immutable calculator;
    constructor(address _calc){
        calculator = iCalc(_calc);
    }

    function sumAll(uint[] calldata _arr)public view returns(uint){
        require(_arr.length > 0);
        uint sum=_arr[0];
        for(uint i=1;i<_arr.length;i++){
            sum = calculator.sum(sum, _arr[i]);
        }
        return sum;
    }
    function mulAll(uint[] calldata _arr)public view returns(uint){
        require(_arr.length > 0);
        uint mul=_arr[0];
        for(uint i=1;i<_arr.length;i++){
            mul = calculator.mul(mul, _arr[i]);
        }
        return mul;
    }
}