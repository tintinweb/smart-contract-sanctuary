/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// Root file: contracts/ChfryImplementations.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
	function master() external view returns (address);
}

contract Setup {
	address public defaultImplementation;

	mapping(bytes4 => address) internal sigImplementations;

	mapping(address => bytes4[]) internal implementationSigs;
}

contract Implementations is Setup {
	event LogSetDefaultImplementation(address indexed oldImplementation, address indexed newImplementation);
	event LogAddImplementation(address indexed implementation, bytes4[] sigs);
	event LogRemoveImplementation(address indexed implementation, bytes4[] sigs);

	IndexInterface public chfryIndex;

	modifier isMaster() {
		require(msg.sender == chfryIndex.master(), 'Implementations: not-master');
		_;
	}

	function setDefaultImplementation(address _defaultImplementation) external isMaster {
		require(_defaultImplementation != address(0), 'Implementations: _defaultImplementation address not valid');
		require(
			_defaultImplementation != defaultImplementation,
			'Implementations: _defaultImplementation cannot be same'
		);
		emit LogSetDefaultImplementation(defaultImplementation, _defaultImplementation);
		defaultImplementation = _defaultImplementation;
	}

	function addImplementation(address _implementation, bytes4[] calldata _sigs) external isMaster {
		require(_implementation != address(0), 'Implementations: _implementation not valid.');
		require(implementationSigs[_implementation].length == 0, 'Implementations: _implementation already added.');
		for (uint256 i = 0; i < _sigs.length; i++) {
			bytes4 _sig = _sigs[i];
			require(sigImplementations[_sig] == address(0), 'Implementations: _sig already added');
			sigImplementations[_sig] = _implementation;
		}
		implementationSigs[_implementation] = _sigs;
		emit LogAddImplementation(_implementation, _sigs);
	}

	function removeImplementation(address _implementation) external isMaster {
		require(_implementation != address(0), 'Implementations: _implementation not valid.');
		require(implementationSigs[_implementation].length != 0, 'Implementations: _implementation not found.');
		bytes4[] memory sigs = implementationSigs[_implementation];
		for (uint256 i = 0; i < sigs.length; i++) {
			bytes4 sig = sigs[i];
			delete sigImplementations[sig];
		}
		delete implementationSigs[_implementation];
		emit LogRemoveImplementation(_implementation, sigs);
	}
}

contract ChfryImplementations is Implementations {
	constructor(address _chfryIndex) {
		chfryIndex = IndexInterface(_chfryIndex);
	}

	function getImplementation(bytes4 _sig) external view returns (address) {
		address _implementation = sigImplementations[_sig];
		return _implementation == address(0) ? defaultImplementation : _implementation;
	}

	function getImplementationSigs(address _impl) external view returns (bytes4[] memory) {
		return implementationSigs[_impl];
	}

	function getSigImplementation(bytes4 _sig) external view returns (address) {
		return sigImplementations[_sig];
	}
}