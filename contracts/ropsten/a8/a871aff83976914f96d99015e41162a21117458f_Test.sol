pragma solidity ^0.4.24;

contract Wrapper {

    function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public;
	function tokenFallback(address _from, uint256 _value, bytes _data) public;
	
	function receiveApprovalTest(address _from, uint256 _value, address _token, bytes _data) public;
	function tokenFallbackTest(address _from, uint256 _value, bytes _data) public;
	
	function xxx() public pure returns (uint256) {
	    return 150;
	}
}


contract Test {
    uint256 lastInt;
    
    function xxx(address x) {
        Wrapper receiver = Wrapper(x);
        lastInt = receiver.xxx();
    }
    
}