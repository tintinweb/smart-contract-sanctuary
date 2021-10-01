// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Counters.sol";
import "./ERC721.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract TokenPairing is ERC721 {

    using Counters for Counters.Counter;

    // token ID tracker
    Counters.Counter internal _pairId;

    event NewPairCreated(uint pairId, uint tier);


    constructor() ERC721("FightersNFT Pairs", "FYTP") {
        // default ID is 0, so we can't use it as an ID.
        _pairId.increment();
    }

    /**
     * @dev getter function for the amount of pairs (it can be usefull)
     */
    function getPairAmount() external view returns(uint) {
        return _pairId.current() - 1;
    }

    /**
     * @dev getter function for _tokenIdToPairId mapping
     */
    function tokenIdToPairId(uint tokenId) external view returns (uint) {
        require(_tokenIdToPairId[tokenId] != 0, "Token is not in a pair!");
        return _tokenIdToPairId[tokenId];
    }

    /**
     * @dev getter function for _pairIdToTokenIds mapping
     */
    function pairIdToTokenIds(uint pairId) external view returns (uint[] memory) {
        require(_pairIdToTokenIds[pairId].length != 0, "Token Pair does not exist!");
        return _pairIdToTokenIds[pairId];
    }

    /**
     * @dev token pairing
     */
    function pairTokens(uint _tokenOneId, uint _tokenTwoId) public {
        if (_exists(_tokenOneId) && _exists(_tokenTwoId)) { // check if paired
            require(
                ownerOf(_tokenOneId) == msg.sender
                &&
                ownerOf(_tokenTwoId) == msg.sender,
                "Caller must own of both tokens!"
            );
            require(
                _pairIdToTokenIds[_tokenOneId].length
                ==
                _pairIdToTokenIds[_tokenTwoId].length,
                "Cannot pair token pairs of differant tiers!"
            );
            require(
                _pairIdToTokenIds[_tokenOneId][0] / 8
                ==
                _pairIdToTokenIds[_tokenTwoId][0] / 8,
                "Cannot pair token pairs of differant characters!"
            );

            // uint[] memory ids = new uint[](_pairIdToTokenIds[_tokenOneId].length * 2);
            // ids[0] = ;

            for (uint i; (_pairIdToTokenIds[_tokenOneId].length) > i; i++) {
                _tokenIdToPairId[_pairIdToTokenIds[_tokenOneId][i]] = _pairId.current();
                _tokenIdToPairId[_pairIdToTokenIds[_tokenTwoId][i]] = _pairId.current();
                _pairIdToTokenIds[_pairId.current()].push(_pairIdToTokenIds[_tokenOneId][i]);
                _pairIdToTokenIds[_pairId.current()].push(_pairIdToTokenIds[_tokenTwoId][i]);
            }

            delete _pairIdToTokenIds[_tokenOneId];
            delete _pairIdToTokenIds[_tokenTwoId];
            _burn(_tokenOneId);
            _burn(_tokenTwoId);

        } else {
            require(
                fightersTokenContract.ownerOfToken(_tokenOneId) == msg.sender
                &&
                fightersTokenContract.ownerOfToken(_tokenTwoId) == msg.sender,
                "Caller must own of both tokens!"
            );
            require(
                _tokenOneId / 8
                ==
                _tokenTwoId / 8,
                "Cannot pair differant character!"
            );

            _tokenIdToPairId[_tokenOneId] = _pairId.current();
            _tokenIdToPairId[_tokenTwoId] = _pairId.current();

            _pairIdToTokenIds[_pairId.current()].push(_tokenOneId);
            _pairIdToTokenIds[_pairId.current()].push(_tokenTwoId);
        }

        _safeMint(msg.sender, _pairId.current());
        emit NewPairCreated(_pairId.current(), _pairIdToTokenIds[_pairId.current()].length);

        _pairId.increment();
    }

    /**
     * @dev get if the caller owns an NFT
     */
    function isTokenHolder() external view returns(bool) {
        return balanceOf(msg.sender) > 0;
    }

    function unpairTokens(uint _pairTokenId) public {
        // looping through the character token IDs that are connected to the paired token
        for (uint i; _pairIdToTokenIds[_pairTokenId].length > i; i++) {
            delete _tokenIdToPairId[_pairIdToTokenIds[_pairTokenId][i]];
        }
        delete _pairIdToTokenIds[_pairTokenId];
        _burn(_pairTokenId);
    }
}