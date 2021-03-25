/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/ObjectOwnershipAuthorityV4.sol
pragma solidity >=0.6.7 <0.7.0;

////// src/ObjectOwnershipAuthorityV4.sol
/* pragma solidity ^0.6.7; */

/**
 * @title ObjectOwnershipAuthority
 * @dev ObjectOwnershipAuthority is authority that manage ObjectOwnership.
 * difference between ObjectOwnershipAuthority whiteList:
[$LANDBASE_PROXY,$APOSTLEBASE_PROXY,$ERC721BRIDGE_PROXY,$DRILLBASE_PROXY] ==> 
[$LANDBASE_PROXY,$APOSTLEBASE_PROXY,$ERC721BRIDGE_PROXY,$DRILLBASE_PROXY,$ITEMBASE_PROXY]
 */

contract ObjectOwnershipAuthorityV4 {
	mapping(address => bool) public whiteList;

	constructor(address[] memory _whitelists) public {
		for (uint256 i = 0; i < _whitelists.length; i++) {
			whiteList[_whitelists[i]] = true;
		}
	}

	function canCall(
		address _src,
		address, /* _dst */
		bytes4 _sig
	) public view returns (bool) {
		return
			(whiteList[_src] &&
				_sig == bytes4(keccak256("mintObject(address,uint128)"))) ||
			(whiteList[_src] &&
				_sig == bytes4(keccak256("burnObject(address,uint128)"))) ||
			(whiteList[_src] &&
				_sig == bytes4(keccak256("mint(address,uint256)"))) ||
			(whiteList[_src] &&
				_sig == bytes4(keccak256("burn(address,uint256)")));
	}
}