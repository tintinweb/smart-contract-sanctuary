pragma solidity 0.6;

import "./ERC20.sol";
import "./Secondary.sol";

contract Scarcity is ERC20, Secondary
{
	address behodler;
	modifier onlyBehodler(){
		require(behodler != address(0), "Behodler contract not set.");
		require(msg.sender == behodler, "Only the Behodler contract can invoke this function.");
		_;
	}

	function setBehodler(address b) external onlyPrimary {
		behodler = b;
	}

	function mint(address recipient, uint value) external onlyBehodler{
		_mint(recipient, value);
	}

	function burn (uint value) external {
		_burn(msg.sender,value);
	}

	function transferToBehodler(address holder, uint value) external onlyBehodler returns (bool){
		_transfer(holder, behodler, value);
		return true;
	}

	function name() external pure returns (string memory) {
		return "Scarcity";
	}

	function symbol() external pure returns (string memory) {
		return "SCX";
	}

	function decimals() external pure returns (uint8) {
		return 18;
	}
}