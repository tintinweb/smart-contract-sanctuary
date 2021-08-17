/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity >=0.6.0;
contract LoopTest {
	uint public count;
	
	constructor() public {
        count = 0;        
    }
	
	function getCount() external returns (uint){
		return count;
	}
	function DoLoop(uint value) external payable returns (uint) {
		for (uint i=0; i<value; i++) {
			count++;
		}
		return count;
	} 
}