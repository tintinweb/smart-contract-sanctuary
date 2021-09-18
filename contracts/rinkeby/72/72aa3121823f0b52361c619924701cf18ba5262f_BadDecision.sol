// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract BadDecision is ERC721Enumerable, EIP712, AccessControl {
    using ECDSA for bytes32;
    struct Voucher {
        uint256 drop;
        uint256 product;
        uint256 price;
        uint256[] tokens;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public constant owner =
        address(0x85c8c111AdfF6A98D6d915b0f9c6eE67186CC678); // This must be changed
    uint256[] tokens;
    mapping(uint256 => bool) tokens_mapping;

    constructor() ERC721("Bad Decision", "BD") EIP712("Bad Decision", "1") {
        _setupRole(MINTER_ROLE, owner);
    }

    modifier owner_only() {
        require(msg.sender == address(owner));
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://www.baddecision.co/";
    }

    function mint(Voucher memory voucher, bytes memory signature)
        public
        pure
        returns (address)
    {
        address signer = _verify(voucher, signature);
        return signer;
        // string memory message = concat(
        //     "Signature invalid or unauthorized: ",
        //     string(abi.encodePacked(signer))
        // );
        // string memory vmessage = concat(string(abi.encodePacked(voucher.drop)), string(abi.encodePacked(voucher.product)));
        // string memory amessage = concat(string(abi.encodePacked(voucher.price)), string(abi.encodePacked(voucher.tokens)));
        // message = concat(message, concat(vmessage, amessage));
        // require(hasRole(MINTER_ROLE, signer), message);
        // _mint(msg.sender, tokens.length);
        // tokens.push(tokens.length);
        // tokens_mapping[tokens.length] = true;
        // "".toSlice().concat(
        //         string(abi.encodePacked(signer)).toSlice()
    }

    function concat(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function _verify(Voucher memory voucher, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, signature);
    }

    function _hash(Voucher memory voucher) internal pure returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        voucher.drop,
                        voucher.product,
                        voucher.price,
                        voucher.tokens
                    )
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}