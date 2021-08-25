// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

/**
 * @title CryptoGhost
 * People turn into Ghosts haunting on the blockchain after getting REKT in Crypto.
 */
contract CryptoGhost is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    uint256 private _currentTokenId = 0;

    uint256 MAX_SUPPLY = 10000;
    string public baseTokenURI;
    uint256 public airDropTimes;
    uint256 public startTime = 1629979200;
    address public teslaOwner;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function buy(uint256 _num) public payable {
        require(block.timestamp >= startTime, "It's not time yet");
        require(_num > 0 && _num <= 20);
        require(msg.value == _num * 3e16);
        for (uint256 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(msg.sender, newTokenId);
            _incrementTokenId();
        }
    }

    /**
     * @dev Every 1000 primary sales, 10 random Ghost NFT owners will be picked and each will get a Ghost for free!
     */
    function airDrop() external onlyOwner {
        uint256 rand = random() % 100;
        for (uint256 i = 0; i < 10; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(ownerOf(1000 * airDropTimes + 100 * i + rand), newTokenId);
            _incrementTokenId();
        }
        airDropTimes = airDropTimes + 1;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function random() private view returns (uint256) {
        bytes32 txHash = keccak256(
            abi.encode(block.coinbase, block.timestamp, block.difficulty)
        );
        return uint256(txHash);
    }

    /**
     * @dev increments the value of _currentTokenId,When all 9,788 Ghosts are sold out, a random Ghost NFT owner will win a Tesla Model Y. The more NFT owned, the bigger the chance.
     */
    function _incrementTokenId() private {
        if (owner() == _msgSender()) {
            require(_currentTokenId < MAX_SUPPLY);
        } else {
            require(_currentTokenId < MAX_SUPPLY - 212);
        }
        _currentTokenId++;
        if (_currentTokenId == MAX_SUPPLY - 212) {
            uint256 rand = random() % 1000;
            bytes32 txHash = keccak256(
                abi.encode(
                    ownerOf(_currentTokenId - 1000 + rand),
                    ownerOf(_currentTokenId - 2000 + rand),
                    ownerOf(_currentTokenId - 3000 + rand),
                    ownerOf(_currentTokenId - 4000 + rand),
                    ownerOf(_currentTokenId - 5000 + rand),
                    ownerOf(_currentTokenId - 6000 + rand),
                    msg.sender
                )
            );
            teslaOwner = ownerOf((uint256(txHash) % 9788) + 1);
        }
    }

    /**
     * @dev change the baseGhostURI if there are future problems with the API service
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
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