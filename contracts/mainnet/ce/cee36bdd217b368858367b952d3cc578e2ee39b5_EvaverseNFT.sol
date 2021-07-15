// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC721/ERC721.sol
// and merged with: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Proxy.sol";

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2309.md
interface IERC2309 {
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract EvaverseNFT is ProxyTarget, Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable, IERC2309, Pausable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    
    string private _tokenName;
    string private _tokenSymbol;
    string private _baseURI;
    
    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    
    uint256         private _tokenCount;
    uint256         private _giveawayTokens;
    uint256         private _maxTokens;
    uint256         private _tokenPrice;
    address payable private _bankAddress;
    bool            private _bankIsContract;
    bool            private _initialized;
    
    // can't depend on a constructor because we have an upgradable proxy, have to initialize instead.
    function Initialize() onlyOwner external {
        require(!_initialized, "Contract instance has already been initialized");

        _tokenName      = "Evaverse";
        _tokenSymbol    = "EVA";
        _baseURI        = "https://evaverse.com/api/creatures.php?id=";
        
        _giveawayTokens = 500;
        _maxTokens      = 10000;
        _tokenPrice     = 100000000000000000; //0.1 ETH
        _initialized    = true;
        _batchMint(Ownable.owner(), _giveawayTokens);
    }

    function IsInitialized() external view returns (bool) {
        return _initialized;
    }

    // Hopefully never need this. Leaving it as an option if we have unsold tokens, if we want to do another giveaway or something.
    function DevMint(address to, uint count) external onlyOwner {
        require(_tokenCount + count < _maxTokens, "EvaNFT: Not enough tokens remaining.");
        _batchMint(to, count);
    }

    function MintNFT(uint count) payable external whenNotPaused nonReentrant {
        require(_initialized, "EvaNFT: Contract is not initialized.");
        require(count > 0, "EvaNFT: Count must be greater than 0.");
        require(count <= 400, "EvaNFT: Count can't be that large, sorry.");
        require(_tokenCount < _maxTokens, "EvaNFT: No tokens left to purchase.");
        require(msg.value == count * _tokenPrice, "EvaNFT: Amount of ETH is not right.");

        // pro-rate any purchase that would have put us over the cap of total NFTs
        uint refundCount = 0;
        if (_tokenCount + count > _maxTokens) {
            refundCount = count - (_maxTokens - _tokenCount);
            count = _maxTokens - _tokenCount;
        }
        
        // Mint all our NFTs!
        _batchMint(_msgSender(), count);
        
        // Refund any Ether for NFTs that couldn't be minted.
        if (refundCount > 0) {
            address payable receiver = payable(_msgSender());
            receiver.transfer(refundCount * _tokenPrice);
        }
        
        // Store funds in a wallet or other smart contract.
        if (_bankAddress != address(0)) {
            if (_bankIsContract) {
                // This is the only way I could get funds to receive in Gnosis Safe.
                (bool sent, ) = _bankAddress.call{value: msg.value}("");
                require(sent, "Failed to send Ether");
            }
            else {
                _bankAddress.transfer(msg.value);
            }
        }
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "EvaNFT: balance query for the zero address");
        return owner == Ownable.owner() ? 0 : _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "EvaNFT: owner query for nonexistent token");
        address owner = _owners[tokenId];
        return owner != address(0) ? owner : Ownable.owner();
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "EvaNFT: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
    
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURI = uri;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override whenNotPaused {
        address owner = EvaverseNFT.ownerOf(tokenId);
        require(to != owner, "EvaNFT: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "EvaNFT: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "EvaNFT: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
        require(operator != _msgSender(), "EvaNFT: approve to caller");

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EvaNFT: transfer caller is not owner nor approved");

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EvaNFT: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "EvaNFT: transfer to non ERC721Receiver implementer");
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
        return tokenId > 0 && tokenId <= _tokenCount;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "EvaNFT: operator query for nonexistent token");
        address owner = EvaverseNFT.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _batchMint(address to, uint count) internal {
        require(to != address(0), "EvaNFT: mint to the zero address");
        
        uint256 tokenId = _tokenCount + 1;
        uint256 startToken = tokenId;
        uint256 endToken = tokenId + count;

        // Don't need to run this code on the owner, those tokens are... virtual?
        if (to != Ownable.owner()) {
            for(; tokenId < endToken; tokenId++) {
                _owners[tokenId] = to;
            }
        }
        
        _balances[to] += count;
        _tokenCount += count;
        
        emit ConsecutiveTransfer(startToken, endToken, address(0), to);
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
        require(EvaverseNFT.ownerOf(tokenId) == from, "EvaNFT: transfer of token that is not own");
        require(to != address(0), "EvaNFT: transfer to the zero address");

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
    function _approve(address to, uint256 tokenId) internal virtual whenNotPaused {
        _tokenApprovals[tokenId] = to;
        emit Approval(EvaverseNFT.ownerOf(tokenId), to, tokenId);
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
                    revert("EvaNFT: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < EvaverseNFT.balanceOf(owner), "EvaNFT: owner index out of bounds");
        require(owner != Ownable.owner(), "EvaNFT: contract owner tokenOfOwnerByIndex not supported");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenCount;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < EvaverseNFT.totalSupply(), "EvaNFT: global index out of bounds");
        return index + 1;
    }

    /**
     * @dev Hook that is called before any token transfer.
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
        if (from == address(0)) {
            // this would only ever be called single single minting, which we don't care about
            //_addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            // this is only ever used in burning, which we don't care about.
            //_removeTokenFromAllTokensEnumeration(tokenId);
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
        if (to == Ownable.owner())
            return;

        uint256 length = EvaverseNFT.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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
        if (from == Ownable.owner())
            return;
            
        uint256 lastTokenIndex = EvaverseNFT.balanceOf(from) - 1;
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
    
    function SetPause(bool pause) external onlyOwner {
        if (pause)
            _pause();
        else
            _unpause();
    }
    
    function WithdrawBalance(address payTo, uint256 amount) external onlyOwner {
        address thisAddr = address(this);
        require(thisAddr.balance > 0);
        address payable receiver = payable(payTo);
        receiver.transfer(amount);
    }

    function SendGiftToWinners(uint256 startTokenId, address[] memory winners) external onlyOwner {
        for(uint ii = 0; ii < winners.length; ii++) {
            uint256 tokenId = startTokenId + ii;
            require(tokenId <= _giveawayTokens, "We can't give away that many."); // we must also be the owner, but that require check is already inside safeTransferFrom
            safeTransferFrom(Ownable.owner(), winners[ii], tokenId);
        }
    }
    
    function GetBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function GetMaxTokenCount() external view returns (uint256) {
        return _maxTokens;
    }
    
    function SetBank(address bank, bool isContract) external onlyOwner {
        _bankAddress = payable(bank);
        _bankIsContract = isContract;
    }
    
    function GetBank() external view onlyOwner returns (address) {
        return _bankAddress;
    }
    
    function SetPrice(uint256 newPrice) external onlyOwner {
        _tokenPrice = newPrice;
    }
    
    function GetPrice() external view returns (uint) {
        return _tokenPrice;
    }
}