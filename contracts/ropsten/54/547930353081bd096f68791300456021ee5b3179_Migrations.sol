pragma solidity 0.4.24;

contract Kkbox {
	uint public count = 0;

	function getCount() external view returns (uint256) {
		return count;
	}
}

contract Migrations is Kkbox {

	address public owner;

	constructor() 		public {
		owner = msg.sender;
	} 

}