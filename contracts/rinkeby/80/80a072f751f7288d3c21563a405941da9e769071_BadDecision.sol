// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract BadDecision is ERC721Enumerable, EIP712, AccessControl {
    using ECDSA for bytes32;
    struct Voucher {
        uint256 product;
        uint256 count;
        uint256 price;
        uint256 starttime;
        uint256 endtime;
        bool auction;
    }
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    mapping(uint256 => uint256) tokens;

    constructor() ERC721("Bad Decision", "BD") EIP712("Bad Decision", "1") {
        _setupRole(
            OWNER_ROLE,
            address(0x85c8c111AdfF6A98D6d915b0f9c6eE67186CC678)
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://www.baddecision.co/api/token/info/";
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

    function addOwner(address someone) public onlyRole(OWNER_ROLE) {
        _setupRole(OWNER_ROLE, someone);
    }

    function delOwner(address someone) public onlyRole(OWNER_ROLE) {
        revokeRole(OWNER_ROLE, someone);
    }

    function changeOwner(address someone) public onlyRole(OWNER_ROLE) {
        addOwner(someone);
        delOwner(msg.sender);
    }

    function count(uint256 product) public view returns (uint256) {
        return tokens[product];
    }

    function redeem(Voucher memory voucher, bytes calldata signature)
        public
        payable
    {
        check(voucher, signature);
        mint(voucher);
    }

    function check(Voucher memory voucher, bytes calldata signature) private {
        require(
            hasRole(OWNER_ROLE, _verify(_hash(voucher), signature)),
            "Signiture is not valid."
        );
        if (voucher.starttime != 0)
            require(
                voucher.starttime < block.timestamp,
                "start date has not been arrived."
            );
        if (voucher.endtime != 0)
            require(
                voucher.endtime > block.timestamp,
                "Deadline has already been passed."
            );
        require(
            tokens[voucher.product] < voucher.count,
            "All tokens of this product sold out"
        );
        require(msg.value >= voucher.price, "Invalid amount of eth");
        // if (voucher.auction) {
        //     require(
        //         address(voucher.winner) == msg.sender,
        //         "You are not the winner of the auction"
        //     );
        // }
    }

    function mint(Voucher memory voucher) private {
        tokens[voucher.product]++;
        uint256 i = totalSupply();
        _safeMint(msg.sender, i);
    }

    function _hash(Voucher memory voucher) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 product,uint256 count,uint256 price,uint256 starttime,uint256 endtime,bool auction)"
                        ),
                        voucher.product,
                        voucher.count,
                        voucher.price,
                        voucher.starttime,
                        voucher.endtime,
                        voucher.auction
                        // ,
                        // voucher.winner
                    )
                )
            );
    }
    function _verify(bytes32 digest, bytes memory signature)
        private
        pure
        returns (address)
    {
        return ECDSA.recover(digest, signature);
    }
}