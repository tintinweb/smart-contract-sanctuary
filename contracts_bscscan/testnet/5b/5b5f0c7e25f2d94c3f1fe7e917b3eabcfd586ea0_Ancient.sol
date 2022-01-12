/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.8.7;

interface IERC721 {
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

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721 {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
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

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_isContract(to)) {
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
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

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

interface IERC20 {
    function decimals() external view returns (uint8);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
}

contract Ancient is ERC721Enumerable {
    uint256 public next_hero;
    uint256 constant DAY = 1 days;

    constructor() ERC721("Ancient Continent Test1", "AC1") {}

    enum Attrs {
        Strength,
        Agile,
        Intelligence
    }

    enum Races {
        Undead,
        Naga,
        Humanity,
        Elves,
        Demon,
        Beast
    }

    enum Jobs {
        Hunter,
        Warrior,
        Mage,
        Assassin,
        Knight,
        Warlock
    }

    IERC20 META1Token =
        IERC20(address(0x1Af9ba79BD8d18854C860f2eD7498825cd40F544));
    IERC20 META2Token =
        IERC20(address(0x6Bd28Bc970fF3FdB29214Cc89A29C27f3d4978b3));

    mapping(uint256 => uint256) private mintType;
    mapping(uint256 => uint256) private attrType;
    mapping(uint256 => uint256) private canDie;
    mapping(uint256 => uint256) private star;
    mapping(uint256 => uint256) private heroType;
    mapping(uint256 => uint256) private race;
    mapping(uint256 => uint256) private job;
    mapping(uint256 => uint256) private level;
    mapping(uint256 => uint256) private character;
    mapping(uint256 => uint256) private skill1Level;
    mapping(uint256 => uint256) private skill2Level;
    mapping(uint256 => uint256) private skill3Level;
    mapping(uint256 => uint256) private skill4Level;
    mapping(uint256 => uint256) private skill1Id;
    mapping(uint256 => uint256) private skill2Id;
    mapping(uint256 => uint256) private skill3Id;
    mapping(uint256 => uint256) private skill4Id;
    mapping(uint256 => uint256) private strength;
    mapping(uint256 => uint256) private intelligence;
    mapping(uint256 => uint256) private agile;
    mapping(uint256 => uint256) private constitution;
    mapping(uint256 => uint256) public adventurers_log;
    mapping(uint256 => uint256) public adventurers_times;

    event summoned(address indexed owner, uint256 hero);
    event leveledUp(address indexed owner, uint256 hero);

    function hero(uint256 _hero)
        external
        view
        returns (
            uint256 _mintType,
            uint256 _canDie,
            uint256 _star,
            uint256 _heroType,
            uint256 _attrType,
            uint256 _level,
            uint256 _character,
            uint256 _strength,
            uint256 _intelligence,
            uint256 _agile,
            uint256 _constitution
        )
    {
        _mintType = mintType[_hero];
        _canDie = canDie[_hero];
        _star = star[_hero];
        _heroType = heroType[_hero];
        _attrType = attrType[_hero];
        _level = level[_hero];
        _character = character[_hero];
        _strength = strength[_hero];
        _intelligence = intelligence[_hero];
        _agile = agile[_hero];
        _constitution = constitution[_hero];
    }

    function skill(uint256 _hero)
        external
        view
        returns (
            uint256 _race,
            uint256 _job,
            uint256 _skill1Level,
            uint256 _skill2Level,
            uint256 _skill3Level,
            uint256 _skill4Level,
            uint256 _skill1Id,
            uint256 _skill2Id,
            uint256 _skill3Id,
            uint256 _skill4Id
        )
    {
        _race = race[_hero];
        _job = job[_hero];
        _skill1Level = skill1Level[_hero];
        _skill2Level = skill2Level[_hero];
        _skill3Level = skill3Level[_hero];
        _skill4Level = skill4Level[_hero];
        _skill1Id = skill1Id[_hero];
        _skill2Id = skill2Id[_hero];
        _skill3Id = skill3Id[_hero];
        _skill4Id = skill4Id[_hero];
    }

    function mint() external {
        require(
            balanceOf(msg.sender) < 30,
            "Each account can only mint 30 heroes."
        );
        require(
            META1Token.transferFrom(
                msg.sender,
                address(this),
                10 * (10**META1Token.decimals())
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
        uint256 _next_hero = next_hero;
        uint256 recruit = dnNum2Num(_next_hero, 1, 100, 0);
        uint256 _star = dnNum2Num(_next_hero, 1, 100, recruit);
        if (recruit <= 5) {
            mintType[_next_hero] = 0;
            canDie[_next_hero] = 0;
            if (_star <= 5) {
                star[_next_hero] = 6;
            } else if (_star <= 25 && _star > 5) {
                star[_next_hero] = 5;
            } else if (_star <= 55 && _star > 25) {
                star[_next_hero] = 4;
            } else if (_star > 55) {
                star[_next_hero] = 3;
            }
        } else {
            mintType[_next_hero] = 1;
            canDie[_next_hero] = 1;
            if (_star <= 3) {
                star[_next_hero] = 4;
            } else if (_star <= 15 && _star > 3) {
                star[_next_hero] = 3;
            } else if (_star <= 50 && _star > 15) {
                star[_next_hero] = 2;
            } else if (_star > 50) {
                star[_next_hero] = 1;
            }
        }
        heroType[_next_hero] = dn(_next_hero, 6, _star);
        if (heroType[_next_hero] == 1) {
            attrType[_next_hero] = uint256(Attrs.Agile);
            race[_next_hero] = uint256(Races.Undead);
            job[_next_hero] = uint256(Jobs.Hunter);
        } else if (heroType[_next_hero] == 2) {
            attrType[_next_hero] = uint256(Attrs.Strength);
            race[_next_hero] = uint256(Races.Naga);
            job[_next_hero] = uint256(Jobs.Warrior);
        } else if (heroType[_next_hero] == 3) {
            attrType[_next_hero] = uint256(Attrs.Intelligence);
            race[_next_hero] = uint256(Races.Humanity);
            job[_next_hero] = uint256(Jobs.Mage);
        } else if (heroType[_next_hero] == 4) {
            attrType[_next_hero] = uint256(Attrs.Agile);
            race[_next_hero] = uint256(Races.Elves);
            job[_next_hero] = uint256(Jobs.Assassin);
        } else if (heroType[_next_hero] == 5) {
            attrType[_next_hero] = uint256(Attrs.Strength);
            race[_next_hero] = uint256(Races.Demon);
            job[_next_hero] = uint256(Jobs.Knight);
        } else if (heroType[_next_hero] == 6) {
            attrType[_next_hero] = uint256(Attrs.Intelligence);
            race[_next_hero] = uint256(Races.Beast);
            job[_next_hero] = uint256(Jobs.Warlock);
        }
        level[_next_hero] = 1;
        character[_next_hero] = dn(_next_hero, 7, heroType[_next_hero]);
        skill1Level[_next_hero] = dn(_next_hero, 3, 0);
        skill2Level[_next_hero] = dn(_next_hero, 3, 1);
        skill3Level[_next_hero] = dn(_next_hero, 3, 2);
        skill4Level[_next_hero] = dn(_next_hero, 3, 3);
        skill1Id[_next_hero] = dn(_next_hero, 20, 0);
        skill2Id[_next_hero] = dn(_next_hero, 20, 1);
        skill3Id[_next_hero] = dn(_next_hero, 20, 2);
        skill4Id[_next_hero] = dn(_next_hero, 20, 3);

        setAttr(attrType[_next_hero], _next_hero);

        _safeMint(msg.sender, _next_hero);
        emit summoned(msg.sender, _next_hero);
        next_hero++;
    }

    function caclAttr(
        uint256 min,
        uint256 max,
        uint256 _star,
        uint256 _hero,
        uint256 _last
    ) private view returns (uint256) {
        uint256 _min = min + ((_star - 1) * 25);
        uint256 _max = max + ((_star - 1) * 25);
        return dnNum2Num(_hero, _min, _max, _last);
    }

    function setAttr(uint256 _attrType, uint256 _hero) private {
        if (_attrType == 0) {
            strength[_hero] = caclAttr(70, 100, star[_hero], _hero, 0);
            agile[_hero] = caclAttr(35, 100, star[_hero], _hero, 1);
            intelligence[_hero] = caclAttr(35, 100, star[_hero], _hero, 2);
            constitution[_hero] = caclAttr(60, 100, star[_hero], _hero, 3);
        } else if (_attrType == 1) {
            strength[_hero] = caclAttr(35, 100, star[_hero], _hero, 0);
            agile[_hero] = caclAttr(70, 100, star[_hero], _hero, 1);
            intelligence[_hero] = caclAttr(35, 100, star[_hero], _hero, 2);
            constitution[_hero] = caclAttr(60, 100, star[_hero], _hero, 3);
        } else if (_attrType == 2) {
            strength[_hero] = caclAttr(35, 100, star[_hero], _hero, 0);
            agile[_hero] = caclAttr(35, 100, star[_hero], _hero, 1);
            intelligence[_hero] = caclAttr(70, 100, star[_hero], _hero, 2);
            constitution[_hero] = caclAttr(60, 100, star[_hero], _hero, 3);
        }
    }

    function levelup(uint256 _hero) external {
        require(_isApprovedOrOwner(msg.sender, _hero));
        require(
            META2Token.transferFrom(
                msg.sender,
                address(this),
                100 * (10**META2Token.decimals())
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
        require(level[_hero] < 50, "Hero is already at max level");
        strength[_hero] += 1;
        agile[_hero] += 1;
        intelligence[_hero] += 1;
        constitution[_hero] += 1;
        if (attrType[_hero] == 0) {
            strength[_hero] += 1;
        } else if (attrType[_hero] == 1) {
            agile[_hero] += 1;
        } else if (attrType[_hero] == 2) {
            intelligence[_hero] += 1;
        }
        level[_hero] += 1;
        emit leveledUp(msg.sender, _hero);
    }

    function adventure(uint256 _hero) external {
        require(_isApprovedOrOwner(msg.sender, _hero));
        require(
            META2Token.transferFrom(
                msg.sender,
                address(this),
                50 * (10**META2Token.decimals())
            ) == true,
            "Could not transfer tokens from your address to this contract"
        );
        require(block.timestamp > adventurers_log[_hero]);
        if (adventurers_times[_hero] < 3) {
            adventurers_times[_hero] += 1;
        }
        if (adventurers_times[_hero] == 3) {
            adventurers_log[_hero] = block.timestamp + DAY;
            adventurers_times[_hero] = 0;
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function dnNum2Num(
        uint256 _hero,
        uint256 _number1,
        uint256 _number2,
        uint256 _last
    ) public view returns (uint256) {
        return (_seed(_hero, _last) % (_number2 - _number1 + 1)) + _number1;
    }

    function dn(
        uint256 _hero,
        uint256 _number,
        uint256 _last
    ) public view returns (uint256) {
        return (_seed(_hero, _last) % _number) + 1;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint256 _hero, uint256 _last)
        internal
        view
        returns (uint256 rand)
    {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _hero,
                    _last,
                    msg.sender
                )
            )
        );
    }
}