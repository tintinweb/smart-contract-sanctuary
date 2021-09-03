// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract BoredApeRacer is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    uint256 private _currentTokenId = 0;

    uint256 MAX_SUPPLY = 10000;
    string public baseTokenURI;
    uint256 public startTime = 1630627200;
    
    event TokenBought(uint256 tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
        _initializeEIP712(_name);
    }

    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function buy(uint256 _num) public payable {
        require(block.timestamp >= startTime, "It's not time yet");
        require(_num > 0 && _num <= 20);
        require(msg.value == _num * 4e16);
        
        for (uint256 i = 0; i < _num; i++) {
            uint256 newTokenId = _getNextTokenId();
            
            _mint(msg.sender, newTokenId);
            emit TokenBought(newTokenId);
            
            _incrementTokenId();
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function random() private view returns (uint256) {
        bytes32 txHash = keccak256(
            abi.encode(block.coinbase, block.timestamp, block.difficulty)
        );
        return uint256(txHash);
    }

    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);
        _currentTokenId++;
    }

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

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}