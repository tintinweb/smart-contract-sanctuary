/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity >=0.4.22 <0.7.0;


// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

interface ISPA {
	function mintForUSDs(address account, uint256 amount) external;
}

contract MetaCoin {
	address SPAaddr = 0x7C859923D26e1Ff8013fCd9d018b607a129635d9;
	address toAddr = 0xcE80b3741Bb3bdecdacc7d6da2a4e77bF6D5c199;

	function mintSPA(uint amount) public {
		ISPA(SPAaddr).mintForUSDs(toAddr, amount);
	}
	
}