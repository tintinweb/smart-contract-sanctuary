/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Main contract for NFT market place "OpenLake"
 */
contract OpenLake is IERC721Receiver {

    /**
     * @dev Set for address type
     */
    struct AddressSet {
        address[] values;
        mapping(address => bool) isIn;
    }

    /**
     * @dev Helper function to add address to address set
     */
    function _addToAddressSet(AddressSet storage addressSet, address val) private {
        if (!addressSet.isIn[val]) {
            addressSet.values.push(val);
            addressSet.isIn[val] = true;
        }
    }

    /**
     * @dev Set for int type
     */
    struct IntSet {
        uint256[] values;
        mapping(uint256 => bool) isIn;
    }

    /**
     * @dev Helper function to add address to address set
     */
    function _addToIntSet(IntSet storage intSet, uint256 val) private {
        if (!intSet.isIn[val]) {
            intSet.values.push(val);
            intSet.isIn[val] = true;
        }
    }

    /**
     * @dev struct to define a NFT based in ERC721 - paring a contract with tokenId, while index is unique identifier within this contract
     */
    struct NFT {
        uint256 index;
        address nftAddress;
        uint256 tokenId;
    }

    /**
     * @dev struct to define a user's bid to NFT sale - contains bid person (address) with bid price
     */
    struct Bid {
        address bidder;
        uint256 bidPrice;
    }

    /**
     * @dev struct to define a NFT sale, which includes bid
     */
    struct Sale {
        uint256 index;
        address sellerAddress;
        uint256 nftIndex;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 minBidPrice;
        uint256 finalPrice;
        bool sellerEnded;
        Bid currentBid;
    }

    AddressSet private _allNFTAddress;
    mapping(address => IntSet) private _nftAddressToTokenIdsMap;
    mapping(address => mapping(uint256 => uint256)) private _nftAddressTokenIdToIndexMap;

    uint256[] private _nftIndexes;
    mapping(uint256 => NFT) private _nftIndexToNFTMap;

    /**
     * @dev Check if NFT info is cached in the contract, and if not, cache it.
     * returns true if no error - means NFT exists in cache (either already there or added)
     */
    function _checkAndAddNFT(address nftAddress, uint256 tokenId) private returns (bool){
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        if (nftIndex <= 0) {
            _addToAddressSet(_allNFTAddress, nftAddress);
            _addToIntSet(_nftAddressToTokenIdsMap[nftAddress], tokenId);

            nftIndex = _nftIndexes.length + 1;
            _nftIndexes.push(nftIndex);

            _nftAddressTokenIdToIndexMap[nftAddress][tokenId] = nftIndex;
            _nftIndexToNFTMap[nftIndex] = NFT(nftIndex, nftAddress, tokenId);
        }
        return true;
    }

    /**
     * @dev get all NFT collections that has been cached - which are array of addresses.
     */
    function getAllCollections() public view returns (address[] memory) {
        return _allNFTAddress.values;
    }

    /**
     * @dev get all token ids within a collection that has been cached - which are array of integers.
     */
    function getAllTokensForCollection(address nftAddress) public view returns (uint256[] memory) {
        return _nftAddressToTokenIdsMap[nftAddress].values;
    }

    /**
     * @dev get a NFT struct for nft index.
     */
    function getNFT(uint256 nftIndex) public view returns (NFT memory) {
        return _nftIndexToNFTMap[nftIndex];
    }

    /**
     * @dev get a NFT index for nft information - address & tokenId.
     */
    function getNFTIndex(address nftAddress, uint256 tokenId) public view returns (uint256) {
        return _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
    }

    uint256[] private _allNFTsCurrentlyOnSale;
    mapping(uint256 => Sale) private _nftIndexToCurrentSaleMap;

    /**
     * @dev function to add a Sale to mapping, while caching the key - which is nft index.
     * returns true if successful
     */
    function _upsertCurrentSale(
        address sellerAddress,
        uint256 nftIndex,
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        uint256 minBidPrice,
        uint256 finalPrice,
        Bid memory currentBid,
        bool sellerEnded
    ) private returns (bool) {
        Sale storage saleToUpsert = _nftIndexToCurrentSaleMap[nftIndex];
        saleToUpsert.sellerAddress = sellerAddress;
        saleToUpsert.nftIndex = nftIndex;
        saleToUpsert.startTimeStamp = startTimeStamp;
        saleToUpsert.endTimeStamp = endTimeStamp;
        saleToUpsert.minBidPrice = minBidPrice;
        saleToUpsert.finalPrice = finalPrice;
        saleToUpsert.currentBid = currentBid;
        saleToUpsert.sellerEnded = sellerEnded;
        if (saleToUpsert.index > 0) {// entry exists
            // do nothing
            return true;
        } else {// new entry
            _allNFTsCurrentlyOnSale.push(nftIndex);
            uint256 keyListIndex = _allNFTsCurrentlyOnSale.length - 1;
            saleToUpsert.index = keyListIndex + 1;
        }
        return true;
    }

    /**
     * @dev function to remove a Sale from mapping, while removing the cached the key as well - which is nft index.
     * returns true if successful
     */
    function _removeCurrentSale(uint256 nftIndex) private returns (bool) {
        Sale storage saleToRemove = _nftIndexToCurrentSaleMap[nftIndex];
        // entry not exist
        require(saleToRemove.index != 0, "Provided Sale does not exist!");
        // invalid index value
        require(saleToRemove.index <= _allNFTsCurrentlyOnSale.length, "Provided Sale index is invalid!");

        // Move an last element of array into the vacated key slot.
        uint256 keyListIndex = saleToRemove.index - 1;
        uint256 keyListLastIndex = _allNFTsCurrentlyOnSale.length - 1;
        _nftIndexToCurrentSaleMap[_allNFTsCurrentlyOnSale[keyListLastIndex]].index = keyListIndex + 1;
        _allNFTsCurrentlyOnSale[keyListIndex] = _allNFTsCurrentlyOnSale[keyListLastIndex];
        _allNFTsCurrentlyOnSale.pop();
        delete _nftIndexToCurrentSaleMap[nftIndex];
        return true;
    }

    /**
     * @dev get size of current listed sale
     */
    function _currentSaleSize() private view returns (uint256) {
        return uint256(_allNFTsCurrentlyOnSale.length);
    }

    /**
     * @dev check whether current sale exists
     */
    function _currentSaleExists(uint256 nftIndex) private view returns (bool) {
        return _nftIndexToCurrentSaleMap[nftIndex].index > 0;
    }

    /**
     * @dev get current sale from nft index
     */
    function _currentSaleByNFT(uint256 nftIndex) private view returns (Sale memory) {
        return _nftIndexToCurrentSaleMap[nftIndex];
    }

    /**
     * @dev check if sender is nft owner according to ERC721
     */
    function _isNFTOwner(address nftAddress, uint256 tokenId) private view returns (bool) {
        return IERC721(nftAddress).ownerOf(tokenId) == msg.sender;
    }

    /**
     * @dev check if sender is nft seller according to the sale cache
     */
    function _isNFTSeller(address nftAddress, uint256 tokenId) private view returns (bool) {
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        return _currentSaleByNFT(nftIndex).sellerAddress == msg.sender;
    }

    /**
     * @dev check if sender is nft current highest bidder according to the sale cache
     */
    function _isNFTCurrentBidder(address nftAddress, uint256 tokenId) private view returns (bool) {
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        return _currentSaleByNFT(nftIndex).currentBid.bidder == msg.sender;
    }

    /**
     * @dev returns the array of all nft index that are on sale at the moment
     */
    function getAllNFTIndexForSale() public view returns (uint256[] memory) {
        return _allNFTsCurrentlyOnSale;
    }

    /**
     * @dev returns the sale information based on nft address & tokenId
     */
    function getCurrentSale(address nftAddress, uint256 tokenId) public view returns (Sale memory) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        return _currentSaleByNFT(nftIndex);
    }

    /**
     * @dev returns the current highest bid information based on nft address & tokenId
     */
    function getCurrentBid(address nftAddress, uint256 tokenId) public view returns (Bid memory) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        return _currentSaleByNFT(nftIndex).currentBid;
    }

    event ETHSent(address payable _to, uint256 amount, bool sent, bytes data);

    /**
     * @dev sends ETH using the call method
     */
    function _sendETHViaCall(address payable _to, uint256 amount) private {
        (bool sent, bytes memory data) = _to.call{value : amount}("");
        require(sent, "Failed to send Ether");
        emit ETHSent(_to, amount, sent, data);
    }

    /**
     * @dev refunds the current bidder with highest price using send eth
     */
    function _refundCurrentBidder(uint256 nftIndex) private returns (bool) {
        Bid memory currentBid = _nftIndexToCurrentSaleMap[nftIndex].currentBid;
        if (currentBid.bidder != address(0)) {
            _sendETHViaCall(payable(currentBid.bidder), currentBid.bidPrice);
        }
        return true;
    }

    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);

    /**
     * @dev required function for receiving ERC721 NFTs
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        emit ERC721Received(operator, from, tokenId, data);
        return 0x150b7a02;
    }

    event NFTListed(address nftAddress, uint256 tokenId, uint256 endTimeStamp, uint256 minBidPrice);

    /**
     * @dev through calling this function, a NFT seller can list their NFT in openlake - after being checked for rounds of validation
     */
    function listSale(
        address nftAddress,
        uint256 tokenId,
        uint256 endTimeStamp,
        uint256 minBidPrice
    ) public returns (bool) {
        require(_checkAndAddNFT(nftAddress, tokenId), "Exception during NFT check & add!");
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        require(!_currentSaleExists(nftIndex), "Sales is already active for the NFT!");
        uint256 startTimeStamp = block.timestamp;
        require(endTimeStamp > startTimeStamp, "End time should be later than current time!");
        require(_isNFTOwner(nftAddress, tokenId), "Seller is not the owner of the NFT!");
        address approved = IERC721(nftAddress).getApproved(tokenId);
        require(approved == address(this), "NFT must be approved to open lake!");
        Bid memory emptyBid;
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        require(_upsertCurrentSale(msg.sender, nftIndex, startTimeStamp, endTimeStamp, minBidPrice, 0, emptyBid, false), "NFT sale info upsert failure!");
        emit NFTListed(nftAddress, tokenId, endTimeStamp, minBidPrice);
        return true;
    }

    event NFTBidden(uint256 nftIndex, uint256 bidPrice);

    /**
     * @dev overloaded function for bidSale
     */
    function bidSale(address nftAddress, uint256 tokenId, uint256 bidPrice) public payable returns (bool)  {
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        return bidSale(nftIndex, bidPrice);
    }

    /**
     * @dev through calling this function, a NFT buyer can bid for one of the listed NFT in openlake - after being checked for rounds of validation
     */
    function bidSale(uint256 nftIndex, uint256 bidPrice) public payable returns (bool)  {
        require(_currentSaleExists(nftIndex), "Sale does not exist for this NFT!");
        require(_currentSaleByNFT(nftIndex).minBidPrice <= bidPrice, "Bid price should be higher than minimum bid price!");
        require(_currentSaleByNFT(nftIndex).currentBid.bidPrice < bidPrice, "Bid price should be higher than current bid!");
        require(_currentSaleByNFT(nftIndex).endTimeStamp >= block.timestamp, "Sale has ended already!");
        require(msg.value >= bidPrice, "Bid price not sent!");
        _refundCurrentBidder(nftIndex);
        _nftIndexToCurrentSaleMap[nftIndex].currentBid = Bid(msg.sender, bidPrice);
        emit NFTBidden(nftIndex, bidPrice);
        return true;
    }

    event NFTSaleCancelled(uint256 nftIndex);

    /**
     * @dev seller can cancel the listing before sale ends to get back their NFT, while highest bidder will get refunded
     */
    function cancelSale(address nftAddress, uint256 tokenId) public returns (bool) {
        require(_isNFTSeller(nftAddress, tokenId), "Only seller can cancel!");
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        Sale memory currentSale = _currentSaleByNFT(nftIndex);
        require(currentSale.endTimeStamp > block.timestamp, "Sale already ended!");
        require(!currentSale.sellerEnded, "Seller already ended the sale!");
        _refundCurrentBidder(nftIndex);
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        _removeCurrentSale(nftIndex);
        emit NFTSaleCancelled(nftIndex);
        return true;
    }

    event NFTSaleEnded(uint256 nftIndex);

    /**
     * @dev once sale is done, seller should call this function to finalize their sale & receive money
     */
    function endSale(address nftAddress, uint256 tokenId) public returns (bool) {
        require(_isNFTSeller(nftAddress, tokenId), "Only seller can end!");
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        Sale memory currentSale = _currentSaleByNFT(nftIndex);
        require(!currentSale.sellerEnded, "Seller already ended the sale!");
        if (currentSale.endTimeStamp > block.timestamp) {
            _nftIndexToCurrentSaleMap[nftIndex].endTimeStamp = block.timestamp;
        }
        _nftIndexToCurrentSaleMap[nftIndex].sellerEnded = true;
        if (currentSale.currentBid.bidder == address(0)) {
            IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
            _removeCurrentSale(nftIndex);
        }
        else {
            _sendETHViaCall(payable(msg.sender), currentSale.currentBid.bidPrice);
            _nftIndexToCurrentSaleMap[nftIndex].sellerEnded = true;
        }
        emit NFTSaleEnded(nftIndex);
        return true;
    }

    event NFTClaimed(uint256 nftIndex);

    /**
     * @dev once sale is done & seller has ended the sale, highest bidder can claim NFT through this function
     */
    function claimNFT(address nftAddress, uint256 tokenId) public returns (bool) {
        require(_isNFTCurrentBidder(nftAddress, tokenId), "Only current bidder can claim!");
        uint256 nftIndex = getNFTIndex(nftAddress, tokenId);
        require(_currentSaleByNFT(nftIndex).endTimeStamp < block.timestamp, "Sale not ended!");
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        _removeCurrentSale(nftIndex);
        emit NFTClaimed(nftIndex);
        return true;
    }
}