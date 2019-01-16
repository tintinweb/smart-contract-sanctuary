pragma solidity ^0.4.24;

contract Calculator {
    int global_var_1;
    int global_var_2;
    function set(int _value1 , int _value2 ) public{
        global_var_1=_value1;
        global_var_2=_value2;
    }
    
    function add() public view returns (int _addition_result)
    {
        _addition_result = global_var_1 + global_var_2;
    }
    function division() public view returns (int _div_result){
        _div_result = global_var_1/global_var_2;
    }
    
    function multi() public view returns (int _mul_result){
          _mul_result = global_var_1*global_var_2;
    }
    
    function sub() public view returns (int _sub_result){
        _sub_result = global_var_1-global_var_2;
    }
    
    
 }