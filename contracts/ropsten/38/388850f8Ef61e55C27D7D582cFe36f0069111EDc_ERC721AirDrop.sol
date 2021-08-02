// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ERC721AirDrop {
    address payable owner;
    bytes32 public merkleRoot;
    bool public cancelable;
    bool isInitialized = false;

    // address of contract, having "transfer" function
    // airdrop contract must have ENOUGH TOKENS in its balance to perform transfer
    IERC721 tokenContract;

    // fix already minted addresses
    mapping(address => mapping(uint256 => bool)) public spent;
    event AirdropTransfer(address addr, uint256 num);

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
        tokenContract = IERC721(_tokenContract);
        merkleRoot = _merkleRoot;
        cancelable = _cancelable;

        isInitialized = true;
    }

    function setRoot(bytes32 _merkleRoot) public {
        require(msg.sender == owner);
        merkleRoot = _merkleRoot;
    }

    function contractTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
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

    function leafFromAddressAndTokenId(address _account, uint256 _tokenId)
        internal
        pure
        returns (bytes32)
    {
        string memory prefix = "0x";
        string memory space = " ";

        // file with addresses and tokens have this format: "0x123...DEF 999",
        // where 999 - token id
        // function simply calculates hash of such a string, given the target
        // address and token id

        bytes memory leaf =
            abi.encodePacked(
                prefix,
                addressToAsciiString(_account),
                space,
                uintToStr(_tokenId)
            );

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
        uint256 _tokenId
    ) public returns (bool success) {
        require(spent[_who][_tokenId] == false);
        // require(msg.sender = _who); // makes not possible to mint tokens for somebody, uncomment for more strict version

        if (!checkProof(_proof, leafFromAddressAndTokenId(_who, _tokenId))) {
            // throw if proof check fails, no need to spend gaz
            require(false, "Invalid proof");
            // return false;
        }

        spent[_who][_tokenId] = true;

        tokenContract.safeTransferFrom(owner, _who, _tokenId);
        emit AirdropTransfer(_who, _tokenId);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}