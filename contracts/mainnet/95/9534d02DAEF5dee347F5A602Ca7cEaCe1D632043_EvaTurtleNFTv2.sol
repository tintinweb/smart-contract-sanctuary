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
import "./Proxy.sol";
import "./EvaverseNFTv2.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension.
 */
contract EvaTurtleNFTv2 is ProxyTarget, Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable, Pausable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _tokenName;

    // Token symbol
    string private _tokenSymbol;
    
    // Base URI
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

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;
    
    address         private _evaverseNFT;
    uint256         private _tokenCount;
    uint256         private _maxTokens;
    bool            private _initialized;
    bool            private _isPromotionRunning;
    
    mapping (uint256 => bool) private _claimedEvaNFTs;
    
    uint256         private _tokenPrice;
    bool            private _purchaseEnabled;
    
    // can't depend on a constructor because we have an upgradable proxy, have to initialize instead.
    function Initialize(address evaverseAddress) onlyOwner external {
        require(!_initialized, "Contract instance has already been initialized");

        _tokenName          = "Eva Turtle";
        _tokenSymbol        = "TRTL";
        _baseURI            = "https://evaverse.com/api/turtle.php?id=";
        _evaverseNFT        = evaverseAddress;
        _maxTokens          = 5000;
        _initialized        = true;
        _isPromotionRunning = true;
        
        // Added in v2, so this will never be called. Added for popsterity in case we use this contract for another Pet in the future.
        _tokenPrice         = 50000000000000000; //0.05 ETH
        _purchaseEnabled    = true;
    }

    function IsInitialized() external view returns (bool) {
        return _initialized;
    }
    
    function IsEvaTokenClaimable(uint256 evaTokenId) external view returns(bool) {
        if (!_isPromotionRunning)
            return false;
                
        if (evaTokenId < 1 || evaTokenId > EvaverseNFTv2(_evaverseNFT).totalSupply())
            return false;

        return !_claimedEvaNFTs[evaTokenId];
    }
    
    function ClaimPets(uint256[] memory evaTokens) external whenNotPaused {
        require(_isPromotionRunning);
        require(evaTokens.length <= 30, "Can't claim that many at once, sorry.");
        uint claimableTokens = 0;
        uint remainingTokens = _maxTokens - _tokenCount;
        
        EvaverseNFTv2 evaContract = EvaverseNFTv2(_evaverseNFT);
        
        for(uint ii = 0; ii < evaTokens.length; ii++) {
            uint256 evaTokenId = evaTokens[ii];
            
            if (claimableTokens >= remainingTokens)
                break;

            require(evaContract.ownerOf(evaTokenId) == _msgSender());
            if (!_claimedEvaNFTs[evaTokenId]) {
                claimableTokens++;
                _claimedEvaNFTs[evaTokenId] = true;
            }
        }
        
        require(claimableTokens > 0, "Sorry, no tokens Evaverse to claim.");
        _batchMint(_msgSender(), claimableTokens);
    }

    function MintEvaAndPet(address to, uint count) payable external {
        MintInernal(to, count);
    }
        
    function MintEvaAndPet(uint count) payable external {
        MintInernal(_msgSender(), count);
    }
    
    function MintInernal(address to, uint count) internal whenNotPaused {
        require(_evaverseNFT != address(0));
        require(count > 0, "You cant buy 0.");
        require(count <= 30, "Can't claim that many at once, sorry.");
        
        EvaverseNFTv2 evaContract = EvaverseNFTv2(_evaverseNFT);

        uint256 evaTokenId = evaContract.totalSupply();
        evaContract.MintNFT{value:msg.value}(to, count);
        
        if(_isPromotionRunning) {
            uint256 endTokenId = evaContract.totalSupply();
            if (endTokenId > _maxTokens) {
                endTokenId = _maxTokens;
            }
                
            if (endTokenId > evaTokenId) {
                for(uint id = evaTokenId + 1; id <= endTokenId; id++) {
                    _claimedEvaNFTs[id] = true;
                }
                
                _batchMint(to, endTokenId - evaTokenId);
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
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override whenNotPaused {
        address owner = EvaTurtleNFTv2.ownerOf(tokenId);
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
    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        address owner = EvaTurtleNFTv2.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _batchMint(address to, uint count) internal {
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 tokenId = _tokenCount + 1;
        uint256 endToken = _tokenCount + count;
        
        require(_checkOnERC721Received(address(0), to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
        
        for(; tokenId <= endToken; tokenId++) {
            _beforeTokenTransfer(address(0), to, tokenId);
            _owners[tokenId] = to;
            _balances[to]++; // don't try and optimize this to only add once, _beforeTokenTransfer needs this to be updated each time.
        }

        tokenId = _tokenCount + 1;
        _tokenCount += count;

        for(; tokenId <= endToken; tokenId++) {
            emit Transfer(address(0), to, tokenId);
        }
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
    function _safeMint(address to) internal virtual {
        _tokenCount++;
        _mint(to, _tokenCount);
        require(
            _checkOnERC721Received(address(0), to, _tokenCount, ""),
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
        require(EvaTurtleNFTv2.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
    function _approve(address to, uint256 tokenId) internal virtual whenNotPaused {
        _tokenApprovals[tokenId] = to;
        emit Approval(EvaTurtleNFTv2.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
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

    
    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < EvaTurtleNFTv2.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < EvaTurtleNFTv2.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
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
        uint256 length = EvaTurtleNFTv2.balanceOf(to);
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = EvaTurtleNFTv2.balanceOf(from) - 1;
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

    
    function GetBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function SendGiftToWinners(address[] memory winners) external onlyOwner {
        require(_tokenCount + winners.length < _maxTokens, "Not enough tokens remaining.");
        for(uint ii = 0; ii < winners.length; ii++) {
            _safeMint(winners[ii]);
        }
    }
    
    // Should only be used if all free tokens get claimed and we decide to air drop extra free gifts on the same contract.
    function SetMaxTokenCount(uint256 newMaxCount) external onlyOwner {
        require(_tokenCount < newMaxCount, "New Maximum Token Count must be greater than the amount of tokens already existing on the contract");
        _maxTokens = newMaxCount;
    }
    
    function GetMaxTokenCount() external view returns (uint256) {
        return _maxTokens;
    }
    
    function SetPromotionState(bool enabled) external onlyOwner {
        _isPromotionRunning = enabled;
    }
    
    function IsPromotionEnabled() external view returns (bool) {
        return _isPromotionRunning;
    }
    
    function GetEvaContract() external view returns (address) {
        return _evaverseNFT;
    }
    
    // Not sure if we'll ever use this, but because we're doing a contract upgrade, Damos thought it would be a good idea to have this available to us in case we want to open it up later.
    function AdoptTurtle(address to, uint count) payable external whenNotPaused {
        require(_purchaseEnabled, "Purchasing is not enabled.");
        require(count > 0, "Count must be greater than 0.");
        require(count <= 30, "Count can't be that large, sorry.");
        require(_tokenCount < _maxTokens, "No tokens left to purchase.");
        require(msg.value == count * _tokenPrice, "Amount of ETH is not right.");

        // pro-rate any purchase that would have put us over the cap of total NFTs
        uint refundCount = 0;
        if (_tokenCount + count > _maxTokens) {
            refundCount = count - (_maxTokens - _tokenCount);
            count = _maxTokens - _tokenCount;
        }
        
        // Mint all our NFTs!
        _batchMint(to, count);
        
        // Refund any Ether for NFTs that couldn't be minted.
        if (refundCount > 0) {
            address payable receiver = payable(to);
            receiver.transfer(refundCount * _tokenPrice);
        }
    }
    
    function SetPrice(uint256 newPrice) external onlyOwner {
        _tokenPrice = newPrice;
    }
    
    function GetPrice() external view returns (uint) {
        return _tokenPrice;
    }
    
    function SetPurchasable(bool isPurchasable) external onlyOwner {
        _purchaseEnabled = isPurchasable;
    }
    
    function IsPurchasable() external view returns (bool) {
        return _purchaseEnabled;
    }
}