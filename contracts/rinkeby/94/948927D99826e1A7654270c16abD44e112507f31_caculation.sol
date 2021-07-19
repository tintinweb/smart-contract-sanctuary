/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract caculation{
    
    int256 private total;
    string private _name;
    string private _symbol;

    event ADD_DEAL(int256 a,int256 b);
    constructor(string memory name,string memory symbol){
        _name = name;
        _symbol = symbol;
    }
    
    function name()external view returns(string memory){
        return _name;
    }
    function symbol()external view returns(string memory){
        return _symbol;
    }

    function add(int256 a,int256 b) external returns(int256) {
        total = a + b;
        return total;
        emit ADD_DEAL(a,b);
    }
    
    function sub(int256 a,int256 b) public {
        
        total = a - b;
    }
    
    function mul(int256 a,int256 b) public {
        
        total = a * b;
    }
    
     function div(int256 a,int256 b) public {
        
        require(
            b != 0,
            "b is !0"
        );
     
        total = a / b;
    }
    
    function getResult() public view returns(int256){
        return total;
    }
}