/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IRegistry {

	function getProvenance () external view returns (address);
	function getAsset () external view returns (address);
	function getProvenanceSource () external view returns (address);
	function getIdentitySource () external view returns (address);
	function getAssetSource () external view returns (address);
	function getCollectionSource () external view returns (address);
	function getAssetSigner () external view returns (address);
	function getCustomSource (string memory name) external view returns (address);

}

contract CxipProvenanceProxy {

	fallback () payable external {
		address _target = IRegistry (0x3d0Ac6CDcd6252684Fa459E7A03Dd1ceaCc01Ade).getProvenanceSource ();
		assembly {
			calldatacopy (0, 0, calldatasize ())
			let result := delegatecall (gas (), _target, 0, calldatasize (), 0, 0)
			returndatacopy (0, 0, returndatasize ())
			switch result
				case 0 {
					revert (0, returndatasize ())
				}
				default {
					return (0, returndatasize ())
				}
		}
	}

}