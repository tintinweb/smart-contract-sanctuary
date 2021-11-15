// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorWriteRaceOracle {
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

/**
 * @title Heroes
 * @author MirrorXYZ
 * A example of a sybil-resistant fair-mint NFT, using merkle proofs.
 * Inspired by Loot (https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7)
 */
contract Heroes {
    string public constant name = "Heroes";
    string public constant symbol = "HEROES";
    // The address of the $WRITE Race Oracle for identity.
    address immutable oracle;
    mapping(address => bool) public claimed;
    uint256 nextTokenId = 1;
    string[] private firstNames = [
        "Orie",
        "Guadalupe",
        "Nyx",
        "Gertrude",
        "Queenie",
        "Nathaniel",
        "Joyce",
        "Claudine",
        "Olin",
        "Aeneas",
        "Elige",
        "Jackson",
        "Euclid",
        "Myrtie",
        "Turner",
        "Neal",
        "Wilmer",
        "Nat",
        "Euna",
        "Aline",
        "Iris",
        "Sofia",
        "Morpheus",
        "Curtis",
        "Claire",
        "Apinya",
        "Lefteris",
        "Alice",
        "Hector",
        "Malee",
        "Geo",
        "Murry",
        "Anastasia",
        "Kahlil",
        "Paris",
        "Noble",
        "Clara",
        "Besse",
        "Wilhelmina",
        "Napoleon",
        "Phillip",
        "Isaiah",
        "Alexander",
        "Lea",
        "Verner",
        "Verla",
        "Beatrice",
        "Willie",
        "William",
        "Elvira",
        "Mildred",
        "Sula",
        "Dido",
        "Adaline",
        "Jean",
        "Inez",
        "Reta",
        "Isidore",
        "Liza",
        "Rollin",
        "Beverly",
        "Theron",
        "Moses",
        "Abbie",
        "Emanuel",
        "Buck",
        "Alphonso",
        "Everett",
        "Ruth",
        "Easter",
        "Cecil",
        "Ivy",
        "Mariah",
        "Lottie",
        "Barney",
        "Adeline",
        "Hazel",
        "Sterling",
        "Kathrine",
        "Mina",
        "Eva",
        "Francisco",
        "Neva",
        "Myrle",
        "Hector",
        "Velva",
        "Dewey",
        "Manda",
        "Mathilda",
        "Pallas",
        "Zollie",
        "Lella",
        "Hiram",
        "Orval",
        "Marcia",
        "Leda",
        "Patricia",
        "Ellie",
        "Riley",
        "Evie",
        "Zelia",
        "Leota",
        "Camilla",
        "Mat",
        "Jonathan",
        "Helen",
        "Letha",
        "Thomas",
        "Osie",
        "Stella",
        "Bernice",
        "Daisy",
        "Hosea",
        "Frederick",
        "Reese",
        "Adah",
        "Nettie",
        "Wade",
        "Hugo",
        "Sipho",
        "Ollie",
        "Zola",
        "Arlie",
        "Iyana",
        "Webster",
        "Rae",
        "Alden",
        "Juno",
        "Luetta",
        "Raphael",
        "Eura",
        "Cupid",
        "Priam",
        "Kame",
        "Louis",
        "Hana",
        "Lyra",
        "Kholo",
        "Gunnar",
        "Olafur",
        "Anatolia",
        "Lelia",
        "Agatha",
        "Helga",
        "Rossie",
        "Katsu",
        "Toku",
        "Verdie",
        "Nandi",
        "Anna",
        "Maksim",
        "Mihlali",
        "Aloysius",
        "Mittie",
        "Olive",
        "Virgie",
        "Gregory",
        "Leah",
        "Maudie",
        "Fanny",
        "Andres",
        "Mava",
        "Ines",
        "Clovis",
        "Clint",
        "Scarlett",
        "Porter",
        "Isabelle",
        "Mahlon",
        "Elsie",
        "Seth",
        "Irma",
        "Annis",
        "Pearle",
        "Dumo",
        "Lamar",
        "Fay",
        "Olga",
        "Billie",
        "Maybelle",
        "Santiago",
        "Ludie",
        "Salvador",
        "Adem",
        "Emir",
        "Hamza",
        "Emre"
    ];
    string[] private lastNames = [
        "Galway",
        "Wheeler",
        "Hotty",
        "Mae",
        "Beale",
        "Zabu",
        "Robins",
        "Farrell",
        "Goslan",
        "Garnier",
        "Tow",
        "Chai",
        "Seong",
        "Ross",
        "Barbary",
        "Burress",
        "McLean",
        "Kennedy",
        "Murphy",
        "Cortez",
        "Aku",
        "Middlemiss",
        "Saxon",
        "Dupont",
        "Sullivan",
        "Hunter",
        "Gibb",
        "Ali",
        "Holmes",
        "Griffin",
        "Patel",
        "Weston",
        "Kabble",
        "Brown",
        "Guillan",
        "Thompson",
        "Doolan",
        "Brownhill",
        "de la Mancha",
        "Crogan",
        "Fitzgerald",
        "Flaubert",
        "Salander",
        "Park",
        "Singh",
        "Hassan",
        "Peri",
        "Horgan",
        "Tolin",
        "Kim",
        "Beckham",
        "Shackley",
        "Lobb",
        "Yoon",
        "Blanchet",
        "Wang",
        "Ames",
        "Liu",
        "Raghavan",
        "Morgan",
        "Xiao",
        "Mills",
        "Yang",
        "Pabst",
        "Duffey",
        "Monaghan",
        "Bu",
        "Teague",
        "Obi",
        "Abberton",
        "Corbin",
        "Zhang",
        "Kildare",
        "Okoro",
        "Eze",
        "Rovelli",
        "Garcia",
        "Wareham",
        "Sun",
        "Langhorne",
        "Liu",
        "Popov",
        "Howlett"
    ];
    string[] private prefixes = [
        "President",
        "General",
        "Captain",
        "Dr",
        "Professor",
        "Chancellor",
        "The Honourable",
        "Venerable",
        "Barrister",
        "Prophet",
        "Evangelist",
        "Senpai",
        "Senator",
        "Speaker",
        "Sama",
        "Chief",
        "Ambassador",
        "Nari",
        "Lion-hearted",
        "Tireless",
        "Poet",
        "Beloved",
        "Godlike",
        "All-Powerful",
        "Sweet-spoken",
        "Wise Old",
        "Hotheaded",
        "Peerless",
        "Gentle",
        "Swift-footed",
        "Mysterious",
        "Dear",
        "Revered",
        "Adored"
    ];
    string[] private suffixes = [
        "I",
        "II",
        "III",
        "the Thoughtful",
        "of the Sword",
        "the Illustrious",
        "from the North",
        "from the South",
        "the Younger",
        "the Elder",
        "the Wise",
        "the Mighty",
        "the Great",
        "the Hero",
        "the Adventurer",
        "the Beautiful",
        "the Conqueror",
        "the Courageous",
        "the Valiant",
        "the Fair",
        "the Magnificent",
        "the Pious",
        "the Just",
        "the Peaceful",
        "the Rich",
        "the Learned",
        "the Mean",
        "the Bold",
        "the Unavoidable",
        "the Giant",
        "the Deep-minded",
        "the Brilliant",
        "the Joyful",
        "the Famous",
        "the Bard",
        "the Knowing",
        "the Sophisticated",
        "the Enlightened"
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

    // Allows any of the WRITE Race candidates to claim.
    function claim(
        address account,
        uint256 index,
        bytes32[] calldata merkleProof
    ) public {
        // Only one claimed per account.
        require(!claimed[account], "already claimed");
        claimed[account] = true;
        // Prove $WRITE Race Identity.
        require(
            IMirrorWriteRaceOracle(oracle).verify(account, index, merkleProof),
            "must prove place in write race"
        );
        // Check that only one character is claimed per account.
        require(!_exists(index), "already claimed");
        // Mint a character for this account.
        _safeMint(account, nextTokenId);
        // Increment the next token ID.
        nextTokenId += 1;
    }

    // ============ Building Token URI ============

    // Mostly looted from Loot: https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = getFullName(tokenId);
        parts[2] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Hero #',
                        toString(tokenId),
                        '", "description": "Heroes", "image": "data:image/svg+xml;base64,',
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

    function getFullName(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        uint256 randFirst = random(
            string(abi.encodePacked("f", toString(tokenId)))
        );
        uint256 randLast = random(
            string(abi.encodePacked("l", toString(tokenId)))
        );
        uint256 randPrefix = random(
            string(abi.encodePacked("p", toString(tokenId)))
        );
        uint256 randSuffix = random(
            string(abi.encodePacked("s", toString(tokenId)))
        );

        bool hasPrefix = randPrefix % 21 > 13;
        bool hasSuffix = randSuffix % 21 > 13;

        string memory fullName = string(
            abi.encodePacked(
                firstNames[randFirst % firstNames.length],
                " ",
                lastNames[randLast % lastNames.length]
            )
        );

        if (hasPrefix) {
            fullName = string(
                abi.encodePacked(
                    prefixes[randPrefix % prefixes.length],
                    " ",
                    fullName
                )
            );
        }

        if (hasSuffix) {
            fullName = string(
                abi.encodePacked(
                    fullName,
                    " ",
                    suffixes[randSuffix % suffixes.length]
                )
            );
        }

        return fullName;
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

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
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

