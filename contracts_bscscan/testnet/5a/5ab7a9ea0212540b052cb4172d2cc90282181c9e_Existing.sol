/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.4.18;
contract Deployed {
    
    function setA(uint) public returns (uint) {}
    
    function a() public pure returns (uint) {}
    
}
contract Existing  {
    
    Deployed dc;
	
	address addr_dc;
    
    function addExisting(address _t) public {
        dc = Deployed(_t);
    }
 
    function getA() public view returns (uint result) {
        return dc.a();
    }
    
    function setA(uint _val) public returns (uint result) {
        dc.setA(_val);
        return _val;
    }	
    
    function ExistingWithoutABI(address _t) public {
        addr_dc = _t;
    }
    
    function setA_Signature(uint _val) public returns(bool success){
        require(addr_dc.call(bytes4(keccak256("setA(uint256)")),_val));
        return true;
    }
	
	function setA_ASM(uint _val) public returns (uint answer) {
        
        bytes4 sig = bytes4(keccak256("setA(uint256)"));
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(
              15000, // gas limit
              sload(addr_dc_slot),  // to addr. append var to _slot to access storage variable
              0, // not transfer any ether
              ptr, // Inputs are stored at location ptr
              0x24, // Inputs are 36 bytes long
              ptr,  //Store output over input
              0x20) //Outputs are 32 bytes long
            
            
            if eq(result, 0) { revert(0, 0) }
            
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }
    
}