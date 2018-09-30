pragma solidity ^0.4.24;

contract owned {
	address public owner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
}

contract ERC20 {
	function balanceOf(address tokenOwner) public constant returns (uint balance);
	function transfer(address to, uint tokens) public ;
}

contract Deposit is owned {
	event deposit_eth(uint amount);
	event deposit_token(address token, uint amount);

	constructor (address _owner) public {
		owner = _owner;
	}

	function returnTokensAll(address token) public onlyOwner {
		uint256 amount = ERC20(token).balanceOf( address(this) );
		emit deposit_token(token, amount);
		ERC20(token).transfer(owner, amount);
	}
	function () public payable {
		emit deposit_eth(address(this).balance);
		owner.transfer(address(this).balance);
	}
}

contract Parent {

	address public owner;
	address[] public investorlist;

	function createChild(uint num, address _owner) public {
		for(uint i=0;i<num;i++){
			Deposit deposit = new Deposit(_owner);
			investorlist.push(address(deposit)) -1;
		}
	}
}