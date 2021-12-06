/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Bridge {
	function depositFor(address _user, address _rootToken, bytes calldata _depositData) external;
}

interface ERC20 {
	function balanceOf(address) external view returns (uint256);
	function approve(address, uint256) external returns (bool);
	function transfer(address, uint256) external returns (bool);
}

contract AutoBridge {

	address constant private POLYGON_ERC20_BRIDGE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

	struct Info {
		bool isBridged;
		Bridge bridge;
		address bridgeDestination;
		address owner;
	}
	Info private info;


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.isBridged = true;
		info.bridge = Bridge(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
		info.bridgeDestination = address(0x0);
		info.owner = msg.sender;
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setIsBridged(bool _isBridged) external _onlyOwner {
		info.isBridged = _isBridged;
	}

	function setBridgeDestination(address _destination) external _onlyOwner {
		info.bridgeDestination = _destination;
	}

	function enableTokenBridging(ERC20 _token) external _onlyOwner {
		_token.approve(POLYGON_ERC20_BRIDGE, type(uint256).max);
	}

	function disableTokenBridging(ERC20 _token) external _onlyOwner {
		_token.approve(POLYGON_ERC20_BRIDGE, 0);
	}


	function bridge(ERC20 _token) external {
		address _destination = bridgeDestination();
		uint256 _amount = _token.balanceOf(address(this));
		if (_destination != address(0x0) && _amount > 0) {
			if (isBridged()) {
				info.bridge.depositFor(_destination, address(_token), abi.encodePacked(_amount));
			} else {
				_token.transfer(_destination, _amount);
			}
		}
	}
	
	
	function owner() public view returns (address) {
		return info.owner;
	}
	
	function isBridged() public view returns (bool) {
		return info.isBridged;
	}
	
	function bridgeDestination() public view returns (address) {
		return info.bridgeDestination;
	}
}