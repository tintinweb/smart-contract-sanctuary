// SPDX-License-Identifier: AGPL-3.0-only
import {Trust} from "Trust.sol";
import {SolmateERC721} from "SolmateERC721.sol";

pragma solidity >=0.8.0;

contract BASPC is SolmateERC721, Trust {
    uint256 immutable PRICE = 0.05e18;
    uint256 immutable MAX_SUPPLY = 10000;

    constructor(
        string memory _baseURI
    ) SolmateERC721("Bored Ape Seed Phrase Club", "BASPC", _baseURI) Trust(msg.sender) {
        return;
    }

    function mint(uint256 numMint) public payable {
        require(msg.value >= numMint * PRICE, "BASPC: Insufficient Funds");
        require(numMint + totalSupply <= MAX_SUPPLY, "BASPC: Out of Stock");
        for (uint256 i = 0; i < numMint; i += 1) {
            _mint(msg.sender, totalSupply);
        }
    }

    function setBaseURI(string memory newBaseURI) public requiresTrust {
        baseURI = newBaseURI;
    }

    function withdrawAll() public requiresTrust {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author Inspired by Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/auth.sol)
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted)
        public
        virtual
        requiresTrust
    {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
abstract contract SolmateERC721 {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    string public baseURI;

    /*///////////////////////////////////////////////////////////////
                            ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );

    bytes32 public constant PERMIT_ALL_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;

    mapping(address => uint256) public noncesForAll;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 tokenId)
        public
        virtual
        returns (bool success)
    {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

        // Cannot overflow because because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[msg.sender]--;

            balanceOf[to]++;
        }

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(msg.sender, to, tokenId);

        success = true;
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool supported)
    {
        supported =
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f ||
            interfaceId == 0x01ffc9a7;
    }

    function approve(address spender, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_APPROVED"
        );

        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(from == ownerOf[tokenId], "NOT_OWNER");

        require(
            msg.sender == from ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[from][msg.sender],
            "NOT_APPROVED"
        );

        // this is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed 'type(uint256).max'
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);

        if (to.code.length > 0) {
            // selector = "onERC721Received(address,address,uint256,bytes)".
            (, bytes memory returned) = to.staticcall(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            );

            bytes4 selector = abi.decode(returned, (bytes4));

            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, toString(tokenId)));
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");

        address owner = ownerOf[tokenId];

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            nonces[tokenId]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0), "INVALID_PERMIT_SIGNATURE");

            require(
                recoveredAddress == owner ||
                    isApprovedForAll[owner][recoveredAddress],
                "INVALID_SIGNER"
            );
        }

        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }

    function permitAll(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= deadline, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_ALL_TYPEHASH,
                            owner,
                            operator,
                            noncesForAll[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                (recoveredAddress != address(0) && recoveredAddress == owner) ||
                    isApprovedForAll[owner][recoveredAddress],
                "INVALID_PERMIT_SIGNATURE"
            );
        }

        isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    function DOMAIN_SEPARATOR()
        public
        view
        virtual
        returns (bytes32 domainSeparator)
    {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID
            ? INITIAL_DOMAIN_SEPARATOR
            : computeDomainSeparator();
    }

    function computeDomainSeparator()
        internal
        view
        virtual
        returns (bytes32 domainSeparator)
    {
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 tokenId) internal virtual {
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        // Cannot realistically overflow from incrementing total supply beyond
        // the max uint256 value, and because the sum of all user balances
        // can't exceed the max uint256 value.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf[tokenId];

        require(ownerOf[tokenId] != address(0), "NOT_MINTED");

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}