/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)
abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	// @dev Initializes the contract setting the deployer as the initial owner.
	constructor() {
		_transferOwnership(_msgSender());
	}

	// @dev Returns the address of the current owner.
	function owner() public view virtual returns (address) {
		return _owner;
	}

	// @dev Throws if called by any account other than the owner.
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	// @dev Leaves the contract without owner. Can only be called by the current owner.
	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	// @dev Transfers ownership of the contract to a new account (`newOwner`).
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	// @dev Transfers ownership of the contract to a new account (`newOwner`).
	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

contract Proxy is Ownable {
	address private _implementation;

	event ImplementationUpgraded(address indexed newImplementation);

	function implementation() public view returns (address) {
		return _implementation;
	}

	function setImplementation(address newImplementation) external onlyOwner {
		uint256 size;
		assembly {
			size := extcodesize(newImplementation)
		}

		require(size > 0, 'Proxy: new implementation is not a contract');
		_implementation = newImplementation;
		emit ImplementationUpgraded(newImplementation);
	}

	function delegate(address singleton) internal {
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), singleton, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())

			if eq(result, 0) {
				revert(0, returndatasize())
			}

			return(0, returndatasize())
		}
	}

	function _fallback() internal {
		delegate(implementation());
	}

	fallback() external payable {
		_fallback();
	}

	receive() external payable {
		_fallback();
	}
}