// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./Context.sol";


interface Cultists {
	function balanceOf(address _cultist) external view returns (uint256 balance);
}


contract AlphaTorch is ERC20("Torch", "TORCH") {
	/**
	 * @dev Award 10 TORCH daily per Cultist owner
	 */

	address immutable public owner;
	uint256 constant public DAILY_FLAMES = 10 ether;
	uint256 constant public IGNITION_STARTS = 1637481600000;

	mapping(address => uint256) public torches;
	mapping(address => uint256) public ignitionLog;

	event TorchesLit(address indexed _cultist, uint256 _flames);

	Cultists private cultistsContract;

	constructor(address _cultistsAddress) {
		owner = msg.sender;
		cultistsContract = Cultists(_cultistsAddress);
	}

	modifier onlyOwner() {
		/**
		@dev restricts functions to the contract owner
		*/
		require(msg.sender == owner, "Must be contract owner");
		_;
	}

	function earlier(
		uint256 _timeA,
		uint256 _timeB
	) internal pure returns(uint256) {
		/**
		@return uint256 earlier of two UNIX timestamps
		*/
		return (_timeA < _timeB ? _timeA : _timeB);
	}

	function lightTorches(address _cultist) external onlyOwner {
		/**
		 @notice light a number of torches for a Cultist owner
		 */
		uint256 _torchesLit = cultistsContract.balanceOf(_cultist);
		require(_torchesLit > 0, "Address owns no Cultists");
		if (_torchesLit > 0) {
			torches[_cultist] = 0;
			_mint(_cultist, _torchesLit);
			emit TorchesLit(_cultist, _torchesLit);
		}
	}

	function burn(address _from, uint256 _amount) external onlyOwner {
		_burn(_from, _amount);
	}

	function getFuelAllotment(address _cultist) external view returns(uint256) {
		/**
		@notice check total torches available to a Cultist owner (all-time)
		@return uint256 total number of torches available (all-time)
		*/
		uint256 _currently = earlier(block.timestamp, IGNITION_STARTS + (365 * 24 * 60 * 60));
		uint256 _sinceLastFlame = _currently - ignitionLog[_cultist];
		uint256 _cultistsOwned = cultistsContract.balanceOf(_cultist);
		uint256 _remainingFlamesPerCultist = (
			DAILY_FLAMES * _sinceLastFlame / (365 * 24 * 60 * 60)
		);
		uint256 _remainingFlames = _cultistsOwned * _remainingFlamesPerCultist;
		return torches[_cultist] + _remainingFlames;
	}
}