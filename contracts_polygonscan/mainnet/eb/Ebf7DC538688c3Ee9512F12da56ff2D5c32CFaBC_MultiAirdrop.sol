/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IClonesNeverDieV2 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function mint(address to) external;

	function totalSupply() external view returns (uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function ownerOf(uint256 tokenId) external view returns (address owner);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function approve(address to, uint256 tokenId) external;

	function getApproved(uint256 tokenId) external view returns (address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function massTransferFrom(
		address from,
		address to,
		uint256[] memory _myTokensId
	) external;
}

pragma solidity ^0.8.4;

contract MultiAirdrop {
	IClonesNeverDieV2 public V2;
	address public owner;

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	constructor(address _v2) {
		V2 = IClonesNeverDieV2(_v2);
		owner = msg.sender;
	}

	function listAirdrip(
		address from,
		address[] memory user,
		uint256[] memory tokenId
	) public onlyOwner {
		for (uint256 i = 0; i < user.length; i++) {
			address reciever = user[i];
			V2.transferFrom(from, reciever, tokenId[i]);
		}
	}
}