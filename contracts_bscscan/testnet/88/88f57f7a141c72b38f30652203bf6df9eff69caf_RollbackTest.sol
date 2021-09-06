/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.4.18;

contract Complainer {

    function doRevert() public pure returns(bool success) {
        revert(); // because let's fail
        return true;
    }

}

contract Existing  {

	function addExisting(address) public pure {} 
		
	function getA() public pure returns (uint) {}

	function setA(uint) public pure returns (uint) {}
	
	function ExistingWithoutABI(address) public pure {}
	
	function setA_Signature(uint) public pure returns(bool){}
	
	function setA_ASM(uint) public pure returns (uint) {}
}


contract RollbackTest  {

	Existing exContract;
	Complainer c;
	
	event LogResult(address sender, string operateFunction, uint operateRes);
	event LogSucceeded(address sender, bool succeeded);
	
	function init(address _t) public {
		exContract = Existing(_t);
	}	
	
	function getStatus() public returns (uint){
		uint res = exContract.getA(); 
		LogResult(msg.sender, "getStatus", res);
		return res;
	}	
	function setStatus_setA(uint _val) public {
		exContract.setA(_val); 		
		LogResult(msg.sender, "setStatus_setA", 0);		
	}
	function setStatus_setA_Signature(uint _val) public {
		exContract.setA_Signature(_val); 
		LogResult(msg.sender, "setStatus_setA_Signature", 0);
	}
	function setStatus_setA_ASM(uint _val) public  returns(uint){
		uint res = exContract.setA_ASM(_val); 
		LogResult(msg.sender, "setStatus_setA_ASM", res);
		return res;
	}
	
	function test1() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA(res_getA);
		LogResult(msg.sender, "test1", res_getA);
		bool cResponse = c.doRevert(); 		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	function test1_1() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA(res_getA);
		LogResult(msg.sender, "test1_1", res_getA);
		
		bool cResponse = c.call(bytes4(keccak256("doRevert()"))); // this will revert and return false
		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	
	function test2() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA_Signature(res_getA);
		LogResult(msg.sender, "test2", res_getA);
		
		bool cResponse = c.doRevert(); 
		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	
	function test2_1() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA_Signature(res_getA);
		LogResult(msg.sender, "test2_1", res_getA);
		
		bool cResponse = c.call(bytes4(keccak256("doRevert()"))); // this will revert and return false
		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	
	function test3() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA_ASM(res_getA);
		LogResult(msg.sender, "test3", res_getA);
		
		bool cResponse = c.doRevert(); 
		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	
	function test3_1() public returns(bool success) {
		uint res_getA = getStatus() + 1;
		setStatus_setA_ASM(res_getA);
		LogResult(msg.sender, "test3_1", res_getA);
		
		bool cResponse = c.call(bytes4(keccak256("doRevert()"))); // this will revert and return false
		
		LogSucceeded(msg.sender,cResponse);
		return true;
	
	}
	
	

}