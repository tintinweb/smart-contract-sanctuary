/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IWriteRaceOracle {
    function verify(
        address account,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/*
 * An example of sybil-resistant NFT drops, using merkle proofs.
 * Disclaimer: Only intended for learning.
 *
 * Author: g.mirror.xyz (@strangechances)
 */
contract SortesVirgilianae {
    string public constant name = "Sortes Virgilianea";
    string public constant symbol = "VIRGIL";

    // The address of the $WRITE Race Oracle for identity.
    address immutable oracle;
    // The accounts that have already claimed their character.
    mapping(bytes32 => bool) public claimed;
    // Keep track of the number of claimed tokens.
    uint256 private numClaimed;
    // How many characters are there going to be?
    uint256 constant MAX_CLAIMABLE = 91;
    // A list of characters from the Aeneid by Virgil.
    string[] public characters = [
        "Dares Phrygius",
        "Evander of Pallantium",
        "Aeneads",
        "Juturna",
        "Venulus",
        "Aeolus",
        "Ajax the Lesser",
        "Aeolus",
        "Lavinia",
        "Elymus",
        "Lausus",
        "Thymoetes",
        "Automedon",
        "Achaemenides",
        "Palinurus",
        "Panthous",
        "Mezentius",
        "Latinus",
        "Coroebus",
        "Diomedes",
        "Pandarus",
        "Caieta",
        "Sinon",
        "Sergestus",
        "Anna Perenna",
        "Actor",
        "Eumelus",
        "Aletes",
        "Ascanius",
        "Erulus",
        "Messapus",
        "Priam",
        "Androgeus",
        "Dardanus",
        "Antiphates",
        "Numanus Remulus",
        "Butes",
        "Aventinus",
        "Neoptolemus",
        "Pallas",
        "Metabus",
        "Picus",
        "Andromache",
        "Euryalus",
        "Cassandra",
        "Ufens",
        "Nisus",
        "Abaris",
        "Eurytion",
        "Iarbas",
        "Catillus",
        "Mnestheus",
        "Hector",
        "Hippocoon",
        "Anchises",
        "Paris",
        "Rutuli",
        "Macar",
        "Entellus",
        "Creusa of Troy",
        "Iopas",
        "Amata",
        "Helenus",
        "Cydonians",
        "Lycus",
        "Ornytus",
        "Clytius",
        "Euryalus",
        "Camilla",
        "Acestes",
        "Thoas",
        "Clonius",
        "Acmon",
        "Achates",
        "Turnus",
        "Achates",
        "Polites of Troy",
        "Lynceus",
        "Ripheus",
        "Theano",
        "Ucalegon",
        "Ilioneus",
        "Halaesus",
        "Aeneas",
        "Cydon",
        "Capys",
        "Acoetes",
        "Salius",
        "Mimas",
        "Halius",
        "Misenus"
    ];

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(address oracle_) {
        oracle = oracle_;
    }

    // Allows any of the top 9k WRITE Race candidates to claim.
    function claim(
        uint256 tokenId,
        uint256 index,
        bytes32[] calldata merkleProof
    ) public {
        // Check if there are characters available to claim.
        require(numClaimed < MAX_CLAIMABLE, "all characters are claimed");
        // Prove $WRITE Race Identity.
        require(
            index < 9000 &&
                IWriteRaceOracle(oracle).verify(msg.sender, index, merkleProof),
            "must prove top 9k place in write race"
        );
        // Check that only one character is claimed per account.
        require(!isClaimed(index, msg.sender), "already claimed");
        // Mark it as claimed.
        setClaimed(index, msg.sender);
        // Increment the number of claimed characters.
        numClaimed += 1;
        // Mint a character for this account.
        _safeMint(msg.sender, tokenId);
    }

    // Mostly looted from Loot: https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: "Garamond"; font-size: 22px; }</style><rect width="100%" height="100%" fill="#b6454c" /><text x="50%" y ="50%"  dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[1] = characters[tokenId];
        parts[2] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Aeneid Character #',
                        toString(tokenId),
                        '", "description": "Characters from Virgil", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function isClaimed(uint256 index, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(index, account)];
    }

    function setClaimed(uint256 index, address account) private {
        claimed[getClaimHash(index, account)] = true;
    }

    function getClaimHash(uint256 index, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account));
    }

    // ============ NFT Methods ============

    function balanceOf(address owner_) public view returns (uint256) {
        require(
            owner_ != address(0),
            "ERC721: balance query for the zero address"
        );

        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address _owner = _owners[tokenId];

        require(
            _owner != address(0),
            "ERC721: owner query for nonexistent token"
        );

        return _owner;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner_] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner_, address(0), tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address approver, bool approved) public virtual {
        require(approver != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][approver] = approved;
        emit ApprovalForAll(msg.sender, approver, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
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
        bytes memory _data
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(
            to != address(0),
            "ERC721: transfer to the zero address (use burn instead)"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}