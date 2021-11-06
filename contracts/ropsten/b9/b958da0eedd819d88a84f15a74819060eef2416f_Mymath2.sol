/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Mymath2{
    
    uint value =0;

    event Ncr (uint n, uint r);
    event Npr (uint n, uint r);

    function factorial(uint _n , uint _k) public returns(uint) {
        require(_n >= _k , 'n must be greater than or equal to k');
        uint a = 1;
        for(uint i = _k ; i <= _n ; i++){
            a *= i;
        }
            return a;
        }

    function seeresult() view public returns(uint){
        return value;
        }  
        
    function combination(uint _n, uint _r) public returns(uint){
            emit Ncr(_n,_r);
            value = factorial(_n,_n - _r + 1) / factorial(_r,1);
            seeresult();
            }
            
    function permutation(uint _n, uint _r) public returns(uint){
        emit Npr(_n,_r);
        value = factorial(_n,1) / factorial(_n - _r,1);
        seeresult();
        }
        
    fallback() external{}
}