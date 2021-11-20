// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

/**
 * @title PowerSurgeNFT
 */
contract PowerSurge is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    string public baseTokenURI;
    uint256 private _currentTokenId = 0;
    uint256 MAX_SUPPLY = 9999;
    uint256 public totalMint = 0;

    uint256 public awakeningTime = 1699999999;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
    }

    /**
     * @dev Airdrop vampires to several addresses.
     * @param _recipients addresss of the future owner of the token
     */
    function mintTo(address[] memory _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(_recipients[i], newTokenId);
            _incrementTokenId();
        }
        totalMint += _recipients.length;
    }

    /**
     * @dev Mint to msg.sender.
     * @param _num addresss of the future owner of the token
     */
    function mint(uint8 _num) external payable {
        require(
            block.timestamp >= awakeningTime,
            "Mint time has not yet arrived!"
        );
        require(
            totalMint + uint256(_num) <= MAX_SUPPLY,
            "Sorry, all nfts are sold out."
        );
        require(
            _num <= 5,
            "Up to 5 PowerSurge can be minted in a tx."
        );
        require(
            msg.value == uint256(_num) * 6e16, // extract price
            "You need to pay the exact price."
        );
        _mintList(_num);
        totalMint += uint256(_num);
    }


    function _mintList(uint8 _num) private {
        for (uint8 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(msg.sender, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

    /**
     * @dev change the baseTokenURI only by Admin
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    /**
     * @dev set the sale time only by Admin
     */
    function setAwakeningTime(uint256 _time) external onlyOwner {
        awakeningTime = _time;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

}