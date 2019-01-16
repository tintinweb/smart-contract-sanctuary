pragma solidity ^0.4.18;
contract ExistingWithoutABI  {
    
    address dc=0x8380c8dbb63e01b5d75ec7260a254152d0679bb0;
    
   // function ExistingWithoutABI(address _t) public {
     //   dc = _t;    }
    
    function setA_Signature(uint _val) public returns(bool success){
        require(dc.call(bytes4(keccak256("setA(uint256)")),_val));
        return true;
    }
}