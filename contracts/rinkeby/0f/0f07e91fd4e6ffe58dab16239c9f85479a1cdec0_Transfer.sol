/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.4.23;

contract Transfer {
    event TransferLog(address indexed ToAccount, address indexed FromAccount, uint value);
    
	function Transfer() public {
	}
    function createTransfer(address a, address b, uint value) public payable {
        TransferLog(a, b, value);
    }
    
}