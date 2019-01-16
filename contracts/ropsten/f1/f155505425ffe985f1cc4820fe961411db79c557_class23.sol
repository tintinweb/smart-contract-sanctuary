pragma solidity >=0.4.22 <0.6.0;
contract class23{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
    function func_1(uint a,uint b) public pure returns(uint256){
        return a+2*b;
    }
    
    function func_2(string x) public returns(string){
        string_1 = x;
        emit setNumber(string_1);
        return string_1;
    }
}