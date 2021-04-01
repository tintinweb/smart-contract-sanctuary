// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context ,ERC165, IERC721, IERC721Metadata, Ownable, Pausable {

    using Address for address;
                      using Strings for uint256;
                                        using SafeMath for uint256;
                                                           using Counters for Counters.Counter;

                                                                              struct Placement {
                    uint256 tokenId;
                    uint256 cost;
                }

    event TokenPlaced(uint256 indexed tokenId, uint256 cost);
    event TokenUnplaced(uint256 indexed tokenId);
    event TokenSold(uint256 indexed tokenId, address indexed newOwner);


    mapping (uint256 => Placement) private _placements;


    /////////////
    //  Crete  //
    /////////////
    function createToken() public  {
        _safeMint(_msgSender(), totalSupply());
    }


        /////////////
        // Placing //
        /////////////

        function place(uint256 tokenId, uint256 cost) external whenNotPaused  {
            // require(token.getApproved(tokenId) == address(this), "Not approved to transfer.");
            require(cost > 0, "Cost should be greater than zero.");

            address tokenOwner =  ERC721.ownerOf(tokenId);
            require(
                tokenOwner == _msgSender(),
                //|| token.isApprovedForAll(tokenOwner, _msgSender()),
                "Not approved or owner."
            );

            _setPlacement(tokenId, cost);

            emit TokenPlaced(tokenId, cost);
        }

        function placement(uint256 tokenId) external view returns(uint256, uint256) {
            Placement memory _placement = _getPlacement(tokenId);
            return (_placement.tokenId, _placement.cost);
        }

        function unplace(uint256 tokenId) external {
            // require(!(token.getApproved(tokenId) == address(this)), "Approved to transfer.");

            address tokenOwner =  ERC721.ownerOf(tokenId);
            require(tokenOwner == _msgSender(), "Not approved or owner.");
            _setPlacement(tokenId, 0);

            emit TokenUnplaced(tokenId);
        }

        ////////////
        // Buying //
        ////////////

        // With ETH
        function buy(uint256 tokenId) external payable whenNotPaused {
            Placement memory _placement = _getPlacement(tokenId);


            address payable owner = payable(address(uint160(ERC721.ownerOf(tokenId))));

            require(msg.value == _placement.cost, "Transfer amount is not correct.");


            // Transfer token
            safeTransferFrom(owner, _msgSender(), tokenId);

            // Process Payment

            owner.transfer(_placement.cost);

        }

        function _getPlacement(uint256 tokenId) private view returns(Placement memory _placement) {
            _placement = _placements[tokenId];
            require(_placement.cost > 0, "Token not placed.");
        }

        function _setPlacement(uint256 tokenId, uint256 cost) private {
            Placement storage _placement = _placements[tokenId];
            _placement.tokenId = tokenId;
            _placement.cost = cost;
        }



            // Token name
            string private _name='Whales Token';

            // Token symbol
            string private _symbol='WLS';


            // Mapping from token ID to owner address
            mapping (uint256 => address) private _owners;

            // Mapping owner address to token count
            mapping (address => uint256) private _balances;

            // Mapping from token ID to approved address
            mapping (uint256 => address) private _tokenApprovals;

            // Mapping from owner to operator approvals
            mapping (address => mapping (address => bool)) private _operatorApprovals;

            // /**
            //  * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
            //  */
            // constructor (string memory name_, string memory symbol_) {
            //     _name = name_;
            //     _symbol = symbol_;
            // }


            /**
             * @dev See {IERC165-supportsInterface}.
             */
            function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
                return interfaceId == type(IERC721).interfaceId
                    || interfaceId == type(IERC721Metadata).interfaceId
                    || super.supportsInterface(interfaceId);
            }

            /**
             * @dev See {IERC721-balanceOf}.
             */
            function balanceOf(address owner) public view virtual override returns (uint256) {
                require(owner != address(0), "ERC721: balance query for the zero address");
                return _balances[owner];
            }

            /**
             * @dev See {IERC721-ownerOf}.
             */
            function ownerOf(uint256 tokenId) public view virtual override returns (address) {
                address owner = _owners[tokenId];
                require(owner != address(0), "ERC721: owner query for nonexistent token");
                return owner;
            }

            /**
             * @dev See {IERC721Metadata-name}.
             */
            function name() public view virtual override returns (string memory) {
                return _name;
            }

            /**
             * @dev See {IERC721Metadata-symbol}.
             */
            function symbol() public view virtual override returns (string memory) {
                return _symbol;
            }

            /**
             * @dev See {IERC721Metadata-tokenURI}.
             */
            function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
                require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

                string memory baseURI = _baseURI();
                return bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString()))
                    : '';
            }

            /**
             * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
             * in child contracts.
             */
            function _baseURI() internal view virtual returns (string memory) {
                return "https://whalestoken.com/tokenstore/";
            }

            /**
             * @dev See {IERC721-approve}.
             */
            function approve(address to, uint256 tokenId) public virtual override {
                address owner = ERC721.ownerOf(tokenId);
                require(to != owner, "ERC721: approval to current owner");

                require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
                    "ERC721: approve caller is not owner nor approved for all"
                );

                _approve(to, tokenId);
            }

            /**
             * @dev See {IERC721-getApproved}.
             */
            function getApproved(uint256 tokenId) public view virtual override returns (address) {
                require(_exists(tokenId), "ERC721: approved query for nonexistent token");

                return _tokenApprovals[tokenId];
            }

            /**
             * @dev See {IERC721-setApprovalForAll}.
             */
            function setApprovalForAll(address operator, bool approved) public virtual override {
                require(operator != _msgSender(), "ERC721: approve to caller");

                _operatorApprovals[_msgSender()][operator] = approved;
                emit ApprovalForAll(_msgSender(), operator, approved);
            }

            /**
             * @dev See {IERC721-isApprovedForAll}.
             */
            function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
                return _operatorApprovals[owner][operator];
            }

            /**
             * @dev See {IERC721-transferFrom}.
             */
            function transferFrom(address from, address to, uint256 tokenId) public virtual override {
                //solhint-disable-next-line max-line-length

                //TODO hide
                //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

                _transfer(from, to, tokenId);
            }

            /**
             * @dev See {IERC721-safeTransferFrom}.
             */
            function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
                safeTransferFrom(from, to, tokenId, "");
            }

            /**
             * @dev See {IERC721-safeTransferFrom}.
             */
            function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
                //TODO hide
                //  require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
            function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
                _transfer(from, to, tokenId);
                require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
            function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
                require(_exists(tokenId), "ERC721: operator query for nonexistent token");
                address owner = ERC721.ownerOf(tokenId);
                return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
            function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
                _mint(to, tokenId);
                require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
            function _transfer(address from, address to, uint256 tokenId) internal virtual {
                require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
            function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
            {
                if (to.isContract()) {
                    try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                        return retval == IERC721Receiver(to).onERC721Received.selector;
                    } catch (bytes memory reason) {
                        if (reason.length == 0) {
                            revert("ERC721: transfer to non ERC721Receiver implementer");
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





            function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual  {

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

            // Mapping from owner to list of owned token IDs
            mapping(address => uint256[]) private _ownedTokens;

            // Mapping from token ID to index of the owner tokens list
            mapping(uint256 => uint256) private _ownedTokensIndex;

            // Array with all token ids, used for enumeration
            uint256[] private _allTokens;

            // Mapping from token id to position in the allTokens array
            mapping(uint256 => uint256) private _allTokensIndex;


            /**
             * @dev Gets the token ID at a given index of the tokens list of the requested owner.
             * @param owner address owning the tokens list to be accessed
             * @param index uint256 representing the index to be accessed of the requested tokens list
             * @return uint256 token ID at the given index of the tokens list owned by the requested address
             */
            function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
                require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

                return _ownedTokens[owner][index];
            }

            /**
             * @dev Gets the total amount of tokens stored by the contract.
             * @return uint256 representing the total amount of tokens
             */
            function totalSupply() public view returns (uint256) {
                return _allTokens.length;
            }

            /**
             * @dev Gets the token ID at a given index of all the tokens in this contract
             * Reverts if the index is greater or equal to the total number of tokens.
             * @param index uint256 representing the index to be accessed of the tokens list
             * @return uint256 token ID at the given index of the tokens list
             */
            function tokenByIndex(uint256 index) public view returns (uint256) {
                require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");

                return _allTokens[index];
            }



            function tokensOfOwner(address owner) public view returns (uint256[] memory) {
                return _tokensOfOwner(owner);
            }


            /**
             * @dev Gets the list of token IDs of the requested owner.
             * @param owner address owning the tokens
             * @return uint256[] List of token IDs owned by the requested address
             */
            function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
                return _ownedTokens[owner];
            }

            /**
             * @dev Private function to add a token to this extension's ownership-tracking data structures.
             * @param to address representing the new owner of the given token ID
             * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
             */
            function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
                _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
                _ownedTokens[to].push(tokenId);
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
                    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
                        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
                        // then delete the last slot (swap and pop).

                        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
                        uint256 tokenIndex = _ownedTokensIndex[tokenId];

                        // When the token to delete is the last token, the swap operation is unnecessary
                        if (tokenIndex != lastTokenIndex) {
                            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
                            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
                        }

                        // This also deletes the contents at the last position of the array
                        _ownedTokens[from].pop();

                        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
                        // lastTokenId, or just over the end of the array if the token was the last one).
                    }

                        /**
                         * @dev Private function to remove a token from this extension's token tracking data structures.
                         * This has O(1) time complexity, but alters the order of the _allTokens array.
                         * @param tokenId uint256 ID of the token to be removed from the tokens list
                         */
                        function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
                            // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
                            // then delete the last slot (swap and pop).

                            uint256 lastTokenIndex = _allTokens.length.sub(1);
                            uint256 tokenIndex = _allTokensIndex[tokenId];

                            // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
                            // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
                            // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
                            uint256 lastTokenId = _allTokens[lastTokenIndex];

                            _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
                            _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

                            // This also deletes the contents at the last position of the array
                            _allTokens.pop();
                            _allTokensIndex[tokenId] = 0;
                        }

}