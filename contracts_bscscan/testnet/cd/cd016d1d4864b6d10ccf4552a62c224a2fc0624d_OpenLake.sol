/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract OpenLake {

    constructor() {
    }

    struct AddressSet {
        address[] values;
        mapping(address => bool) is_in;
    }

    function _addToAddressSet(AddressSet storage addressSet, address val) private {
        if (!addressSet.is_in[val]) {
            addressSet.values.push(val);
            addressSet.is_in[val] = true;
        }
    }

    struct IntSet {
        uint256[] values;
        mapping(uint256 => bool) is_in;
    }

    function _addToIntSet(IntSet storage intSet, uint256 val) private {
        if (!intSet.is_in[val]) {
            intSet.values.push(val);
            intSet.is_in[val] = true;
        }
    }

    struct NFT {
        uint256 index;
        address nftAddress;
        uint256 tokenId;
    }

    struct Bid {
        address bidder;
        uint256 bidPrice;
    }

    struct Sale {
        uint256 index;
        address sellerAddress;
        uint256 nftIndex;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 minBidPrice;
        uint256 finalPrice;
    }

    AddressSet private _allNFTAddress;
    mapping(address => IntSet) private _nftAddressToTokenIdsMap;
    mapping(address => mapping(uint256 => uint256)) private _nftAddressTokenIdToIndexMap;

    uint256[] private _nftIndexes;
    mapping(uint256 => NFT) private _nftIndexToNFTMap;
    mapping(uint256 => Bid[]) _nftIndexToBidsMap;

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

    uint256[] private _allNFTsCurrentlyOnSale;
    mapping(uint256 => Sale) private _nftIndexToCurrentSaleMap;


    function _upsertCurrentSale(address sellerAddress, uint256 nftIndex, uint256 startTimeStamp,
        uint256 endTimeStamp, uint256 minBidPrice, uint256 finalPrice) private returns (bool) {
        Sale storage saleToUpsert = _nftIndexToCurrentSaleMap[nftIndex];
        saleToUpsert.sellerAddress = sellerAddress;
        saleToUpsert.nftIndex = nftIndex;
        saleToUpsert.startTimeStamp = startTimeStamp;
        saleToUpsert.endTimeStamp = endTimeStamp;
        saleToUpsert.minBidPrice = minBidPrice;
        saleToUpsert.finalPrice = finalPrice;
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

    function _currentSaleSize() private view returns (uint256) {
        return uint256(_allNFTsCurrentlyOnSale.length);
    }

    function _currentSaleExists(uint256 nftIndex) private view returns (bool) {
        return _nftIndexToCurrentSaleMap[nftIndex].index > 0;
    }

    function _currentSaleByNFT(uint256 nftIndex) private view returns (Sale memory) {
        return _nftIndexToCurrentSaleMap[nftIndex];
    }

    function listSale(address nftAddress, uint256 tokenId, uint256 endTimeStamp,
        uint256 minBidPrice) public returns (bool) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        require(!_currentSaleExists(nftIndex), "Sales is already active for the NFT!");
        uint256 startTimeStamp = block.timestamp;
        require(endTimeStamp > startTimeStamp, "End time should be later than current time!");
        address sellerAddress = msg.sender;
        require(_checkAndAddNFT(nftAddress, tokenId), "Exception during NFT check & add!");

        return _upsertCurrentSale(sellerAddress, nftIndex, startTimeStamp, endTimeStamp, minBidPrice, 0);
    }

    function bidSale(address nftAddress, uint256 tokenId, uint256 bidPrice) public returns (bool) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        return bidSale(nftIndex, bidPrice);
    }

    function bidSale(uint256 nftIndex, uint256 bidPrice) public returns (bool) {
        require(_currentSaleExists(nftIndex), "Sale does not exist for this NFT!");
        require(_currentSaleByNFT(nftIndex).minBidPrice <= bidPrice, "Bid price is too low!");
        require(_currentSaleByNFT(nftIndex).endTimeStamp >= block.timestamp, "Sale has ended already!");
        _nftIndexToBidsMap[nftIndex].push(Bid(msg.sender, bidPrice));
        return true;
    }

    function getNftIndex(address nftAddress, uint256 tokenId) public view returns (uint256) {
        return _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
    }

    function getCurrentSale(address nftAddress, uint256 tokenId) public view returns (Sale memory) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        return _currentSaleByNFT(nftIndex);
    }

    function getCurrentBids(address nftAddress, uint256 tokenId) public view returns (Bid[] memory) {
        uint256 nftIndex = _nftAddressTokenIdToIndexMap[nftAddress][tokenId];
        return _nftIndexToBidsMap[nftIndex];
    }


}