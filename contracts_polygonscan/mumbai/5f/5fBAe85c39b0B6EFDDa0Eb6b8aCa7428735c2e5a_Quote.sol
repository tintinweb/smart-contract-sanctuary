/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Quote {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct MetaTransaction {
	    uint256 nonce;
	    address from;
    }

    mapping(address => uint256) public nonces;

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from)"));
    bytes32 internal DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
		keccak256(bytes("Quote")),
		keccak256(bytes("1")),
		80001, // Matic Mumbai
		address(this)
    ));

    string public name = "Quote";
    string public quote;
    address public owner;

    function getQuote() public view returns (string memory currentQuote, address currentOwner) {
        currentQuote = quote;
        currentOwner = owner;
    }

    function setQuote(string memory _quote) public {
        quote = _quote;
        owner = msg.sender;
    }

    function setQuoteMeta(address _address, string memory _quote, bytes32 _r, bytes32 _s, uint8 _v) public {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[_address],
            from: _address
        });

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from))
            )
        );

        require(_address != address(0), "invalid-address-0");
        require(_address == ecrecover(digest, _v, _r, _s), "invalid-signatures");

        quote = _quote;
        owner = _address;
        nonces[_address]++;
    }
}