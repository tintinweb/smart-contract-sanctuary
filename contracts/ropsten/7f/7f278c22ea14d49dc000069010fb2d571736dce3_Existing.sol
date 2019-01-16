pragma solidity ^0.4.18;
contract Deployed {
    
    function setA(string) public returns (string) {}
    
    function a() public pure returns (string) {}
    
}
contract Existing  {
    
    Deployed dc;
    
    function Existing(address _t) public {
        dc = Deployed(_t);
    }
 
    function getA() public view returns (string result) {
        return dc.a();
    }
    
    function setA(string _val) public returns (string result) {
        dc.setA(_val);
        return _val;
    }
    
}