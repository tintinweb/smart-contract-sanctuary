// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Badge.sol";
import "./IBadgeFactory.sol";

contract ReputationBadge is Badge {
    IBadgeFactory internal badgeFactory;

    struct TokenParameters {
        address owner;
        bytes32 tokenId;
    }

    constructor(string memory badgeName_, string memory badgeSymbol_)
        Badge(badgeName_, badgeSymbol_)
    {
        badgeFactory = IBadgeFactory(msg.sender);
    }

    function exists(bytes32 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, bytes32 tokenId) external {
        require(msg.sender == badgeFactory.getBackendAddress(), "Unauthorized");
        _mint(to, tokenId);
    }

    function batchMint(TokenParameters[] memory tokensToMint) external {
        require(msg.sender == badgeFactory.getBackendAddress(), "Unauthorized");

        for (uint256 i = 0; i < tokensToMint.length; i++) {
            _mint(tokensToMint[i].owner, tokensToMint[i].tokenId);
        }
    }

    function burn(bytes32 tokenId) external {
        require(
            msg.sender == badgeFactory.getBackendAddress() ||
                msg.sender == ownerOf(tokenId),
            "Unauthorized"
        );
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBadge.sol";

contract Badge is IBadge {
    // Badge's name
    string private _name;

    // Badge's symbol
    string private _symbol;

    // Mapping from token ID to owner's address
    mapping(bytes32 => address) private _owners;

    // Mapping from owner's address to token ID
    mapping(address => bytes32) private _tokens;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // Returns the badge's name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // Returns the badge's symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Returns the token ID owned by `owner`, if it exists, and 0 otherwise
    function tokenOf(address owner)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        require(owner != address(0), "Invalid owner at zero address");

        return _tokens[owner];
    }

    // Returns the owner of a given token ID, reverts if the token does not exist
    function ownerOf(bytes32 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(tokenId != 0, "Invalid tokenId value");

        address owner = _owners[tokenId];

        require(owner != address(0), "Invalid owner at zero address");

        return owner;
    }

    // Checks if a token ID exists
    function _exists(bytes32 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Minted} event.
     */
    function _mint(address to, bytes32 tokenId) internal virtual {
        require(to != address(0), "Invalid owner at zero address");
        require(tokenId != 0, "Token ID cannot be zero");
        require(!_exists(tokenId), "Token already minted");
        require(tokenOf(to) == 0, "Owner already has a token");

        _tokens[to] = tokenId;
        _owners[tokenId] = to;

        emit Minted(to, tokenId, block.timestamp);
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Burned} event.
     */
    function _burn(bytes32 tokenId) internal virtual {
        address owner = Badge.ownerOf(tokenId);

        delete _tokens[owner];
        delete _owners[tokenId];

        emit Burned(owner, tokenId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBadgeFactory {
    function getBackendAddress() external view returns (address);

    function deployBadge(string memory badgeName, string memory badgeSymbol)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBadge {
    /**
     * @dev Emitted when `tokenId` token is minted to `to`.
     * @param to The address that received the token
     * @param tokenId The id of the token that was minted
     * @param timestamp Block timestamp from when the token was minted
     */
    event Minted(
        address indexed to,
        bytes32 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Emitted when `tokenId` token is burned.
     * @param owner The address that used to own the token
     * @param tokenId The id of the token that was burned
     * @param timestamp Block timestamp from when the token was burned
     */
    event Burned(
        address indexed owner,
        bytes32 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Returns the badge's name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the badge's symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the ID of the token owned by `owner`, if it owns one, and 0 otherwise
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     */
    function tokenOf(address owner) external view returns (bytes32);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(bytes32 tokenId) external view returns (address);
}

