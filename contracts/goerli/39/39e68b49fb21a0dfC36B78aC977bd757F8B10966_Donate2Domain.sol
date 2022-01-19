/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENS {
	function resolver(bytes32 node) public virtual view returns (ENSResolver);
}

abstract contract ENSResolver {
	function addr(bytes32 node) public virtual view returns (address);
}

contract Donate2Domain {

	mapping(bytes32 => uint256) public balances;

	event Donated(address indexed from, bytes32 indexed node, uint256 amount);
	event Collected(address indexed by, bytes32 indexed node, uint256 amount);

	ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

	function donate(bytes32 node) public payable {
		balances[node] += msg.value;
		emit Donated(msg.sender, node, msg.value);
	}

	function collect(bytes32 node) public {
		uint256 amount = balances[node];
		balances[node] = 0;
		address recipient = payable(resolve(node));
		(bool success, ) = recipient.call{value: amount}("");
		require(success, "Unable to send to collection address");
		emit Collected(msg.sender, node, amount);
	}

	function resolve(bytes32 node) public view returns(address) {
		ENSResolver resolver = ens.resolver(node);
		address resolved_address = resolver.addr(node);
		require(resolved_address != address(0), "Resolved to burn address");
		return resolved_address;
	}

}