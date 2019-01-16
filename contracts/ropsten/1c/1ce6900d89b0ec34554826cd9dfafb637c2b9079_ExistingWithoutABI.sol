pragma solidity ^0.4.18;
contract ExistingWithoutABI  {
    
    address dc=0x8380c8dbb63e01b5d75ec7260a254152d0679bb0;
    
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
              sload(dc_slot),  // to addr. append var to _slot to access storage variable
              0, // not transfer any ether
              ptr, // Inputs are stored at location ptr
              0x24, // Inputs are 36 bytes long
              ptr,  //Store output over input
              0x20) //Outputs are 32 bytes long
            
           // if eq(result, 0) {                revert(0, 0)            }
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }
}