/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

pragma solidity ^0.4.21;

contract ImplV0 {
    uint256 public someVar = 123;

    function setVar(uint256 _newValue) public {
        someVar = _newValue;
    }
}

contract ImplV1  is ImplV0{
   uint256 public someVarNew;
    function setVar(uint256 _newValue) public {
        someVar = _newValue;
    }
    
    function getVar() public view returns(uint256){
        return someVar;
    }
    
     function setVarNew(uint256 _newValue) public {
        someVarNew = _newValue;
    }
}