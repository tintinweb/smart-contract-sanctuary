pragma solidity ^0.4.24;
/**
 * The ContratoDNI contract does this and that...
 */
contract ContratoDNI {
	mapping (address => uint256) addrDNI;
	
	function Setter(uint256 _dni) public{
		addrDNI[msg.sender] = _dni;
	}
	function Getter() public view returns(uint256){
		return(addrDNI[msg.sender]);
	}
}