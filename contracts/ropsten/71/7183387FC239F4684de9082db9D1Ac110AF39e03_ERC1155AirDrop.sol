// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract ERC1155AirDrop {
    address payable owner;
    bytes32 public merkleRoot;
    bool public cancelable;
    bool isInitialized = false;

    // address of contract, having "transfer" function
    // airdrop contract must have ENOUGH TOKENS in its balance to perform transfer
    IERC1155 tokenContract;

    // fix already minted addresses
    mapping(address => mapping(uint256 => bool)) public spent;
    event AirdropTransfer(address addr, uint256 id, uint256 num);

    modifier isCancelable() {
        require(cancelable, "forbidden action");
        _;
    }

    function initialize(
        address _owner,
        address _tokenContract,
        bytes32 _merkleRoot,
        bool _cancelable
    ) public {
        require(!isInitialized, "Airdrop already initialized!");

        owner = payable(_owner);
        tokenContract = IERC1155(_tokenContract);
        merkleRoot = _merkleRoot;
        cancelable = _cancelable;

        isInitialized = true;
    }

    function setRoot(bytes32 _merkleRoot) public {
        require(msg.sender == owner);
        merkleRoot = _merkleRoot;
    }

    function contractTokenBalance(uint256 id) public view returns (uint256) {
        return tokenContract.balanceOf(address(this), id);
    }

    function selfDestruct() public isCancelable returns (bool) {
        // only owner
        require(msg.sender == owner);
        selfdestruct(owner);
        return true;
    }

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        uint256 x_int = uint256(uint160(address(x)));

        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(x_int / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uintToStr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            bstr[(k--) - 1] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }

    function leafFromAddressTokenIdsAndAmount(
        address _account,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) internal pure returns (bytes32) {
        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts length mismatch"
        );

        bytes memory leaf = "";
        string memory prefix = "0x";
        string memory space = " ";
        string memory comma = ",";

        // file with addresses and tokens have this format: "0x123...DEF 999 666",
        // where 999 - token id and 666 - num tokens
        // function simply calculates hash of such a string, given the target
        // address, token ids and num tokens

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            leaf = abi.encodePacked(
                leaf,
                leaf.length > 2 ? comma : "",
                prefix,
                addressToAsciiString(_account),
                space,
                uintToStr(_tokenIds[i]),
                space,
                uintToStr(_amounts[i])
            );
        }

        return bytes32(sha256(leaf));
    }

    // function bytes32ToString(bytes32 _bytes32)
    //     public
    //     pure
    //     returns (string memory)
    // {
    //     uint8 i = 0;
    //     while (i < 32 && _bytes32[i] != 0) {
    //         i++;
    //     }
    //     bytes memory bytesArray = new bytes(i);
    //     for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
    //         bytesArray[i] = _bytes32[i];
    //     }
    //     return string(bytesArray);
    // }

    function getTokensByMerkleProof(
        bytes32[] memory _proof,
        address _who,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) public returns (bool success) {
        require(
            _tokenIds.length == _amounts.length,
            "tokenIds and amounts length mismatch"
        );
        // require(msg.sender = _who); // makes not possible to mint tokens for somebody, uncomment for more strict version

        if (
            !checkProof(
                _proof,
                leafFromAddressTokenIdsAndAmount(_who, _tokenIds, _amounts)
            )
        ) {
            // throw if proof check fails, no need to spend gaz
            require(false, "Invalid proof");
            // return false;
        }

        tokenContract.safeBatchTransferFrom(
            owner,
            _who,
            _tokenIds,
            _amounts,
            ""
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(spent[_who][_tokenIds[i]] == false);
            spent[_who][_tokenIds[i]] = true;
            emit AirdropTransfer(_who, _tokenIds[i], _amounts[i]);
        }
        return true;
    }

    function checkProof(bytes32[] memory proof, bytes32 hash)
        internal
        view
        returns (bool)
    {
        bytes32 el;
        bytes32 h = hash;

        for (
            uint256 i = 0;
            proof.length != 0 && i <= proof.length - 1;
            i += 1
        ) {
            el = proof[i];

            if (h < el) {
                h = sha256(abi.encodePacked(h, el));
            } else {
                h = sha256(abi.encodePacked(el, h));
            }
        }

        return h == merkleRoot;
    }
}

