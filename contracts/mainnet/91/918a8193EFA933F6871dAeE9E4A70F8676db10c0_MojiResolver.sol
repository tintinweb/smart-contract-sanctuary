// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721Enumerable.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./DNSResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

contract MojiResolver is ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    IERC721Enumerable immutable public token;

    constructor(IERC721Enumerable _token) {
      token = _token;
    }

    function isAuthorised(bytes32 label) internal override view returns(bool) {
        // authorize the registrar or token owner
        return address(token) == msg.sender || token.ownerOf(uint256(label)) == msg.sender;
    }

    function multicall(bytes[] calldata data) external returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) virtual override(ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver) public pure returns(bool) {
        return super.supportsInterface(interfaceID);
    }
}