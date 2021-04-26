/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.26;

contract Caller {
    address debloyedB;
    
    function setAddressB(address _debloyedB) public {
        debloyedB = _debloyedB;
    }
    
    function computeAdd() public view returns(int88) {
        Callee b = Callee(debloyedB);
        return b.addition();
    }
    
    function computeSub() public view returns(int88) {
        Callee b = Callee(debloyedB);
        return b.subtraction();
    }
    
    function computeMul() public view returns(int88) {
        Callee b = Callee(debloyedB);
        return b.multiplication();
    }
    
    function callSetAB(int88 _a, int88 _b) public {
        Callee b = Callee(debloyedB);
        b.setAB(_a, _b);
    }
}

contract Callee {
    int88 a;
    int88 b;
    
    function setAB(int88 _a, int88 _b) public {
        a = _a;
        b = _b;
    }
    
    function addition() public view returns(int88) {
        return a+b;
    }
    
    function subtraction() public view returns(int88) {
        return a-b;
    }
    
    function multiplication() public view returns(int88) {
        return a*b;
    }
}