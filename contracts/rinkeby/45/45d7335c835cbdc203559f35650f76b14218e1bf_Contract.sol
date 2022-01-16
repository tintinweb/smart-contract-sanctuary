// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

contract Contract is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private constant SINGING_DOMAIN = "TEST";
    string private constant SIGNATURE_VERSION = "4";

    constructor() ERC721("Token","T") EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) {}

    function mint(address to, string memory name, bytes memory signature) public {
        require(check(name, signature) == msg.sender, "Voucher Invalid");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function check(string memory name, bytes memory signature) public view returns (address) {
        return _verify( name, signature);
    }

    function _verify(string memory name, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(name);
        return ECDSA.recover(digest, signature);
    }

    function _hash(string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(string name)"),
            keccak256(bytes(name))
        )));
        }
    }