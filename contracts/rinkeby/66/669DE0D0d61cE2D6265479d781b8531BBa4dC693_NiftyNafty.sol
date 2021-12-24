// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./IERC721Enumerable.sol";


contract NiftyNafty is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    mapping(address => uint256) private _mintedTokens;

    mapping(address => bool) private _whiteList;

    mapping(address => bool) private _isOwner;

    uint256 private _currentTokenId = 1000;

    uint256 private _currentOwnersTokenId = 0;

    uint256 private _maxTotalSupply = 9999;

    address[4] private _owners;

    string private _uri;

    string private _notRevealedUri;

    uint256 private _presalePrice = 50000000000000000;

    uint256 private _mintPrice = 90000000000000000;

    uint256 private _wlMintPrice = 80000000000000000;

    bool private _isRevealed;

    uint256 private _mintStartDate;

    uint256 private _wlMintStartDate;

    uint256 private _presaleStartDate;

    string private _name = "Nifty Nafty";

    string private _symbol = "NN";


   constructor(address[4] memory owners) Ownable(owners[0]) ERC721(_name, _symbol) {
        for (uint i = 0; i< owners.length; i++) {
            require(!_isOwner[owners[i]], "This wallet was already added as owner");
            _owners[i] = owners[i];
            _isOwner[owners[i]] = true;
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!_isRevealed) {
            return _notRevealedUri;
        }

        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }


    function setBaseURI(string memory _newuri) public onlyOwner {
        _uri = _newuri;

    }

    function setNotRevealedURI(string memory _newuri) public onlyOwner {
        _notRevealedUri = _newuri;
    }


    function reveal() public onlyOwner {
        require(!_isRevealed, "Tokens are already revealed");
        _isRevealed = true;
    }


    function getMaxTotalSupply() public view returns(uint256) {
        return _maxTotalSupply;
    }


    function setMaxTotalSupply(uint256 amount) public onlyOwner {
        require(_currentTokenId <= amount, "Max Total supply is lower than currently minted tokens quantity");
        _maxTotalSupply = amount;
    }


    function getPresalePrice() public view returns(uint256) {
        return _presalePrice;
    }


    function setPresalePrice(uint256 price) public onlyOwner {
        _presalePrice = price;
    }


    function getMintPrice() public view returns(uint256) {
        return _mintPrice;
    }


    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }


    function getWLMintPrice() public view returns(uint256) {
        return _wlMintPrice;
    }


    function setWLMintPrice(uint256 price) public onlyOwner {
        _wlMintPrice = price;
    }


    function getMintStartDate() public view returns(uint256) {
        return _mintStartDate;
    }


    function setMintStartDate(uint256 timestamp) public onlyOwner {
        _mintStartDate = timestamp;
    }


    function getPresaleStartDate() public view returns(uint256) {
        return _presaleStartDate;
    }


    function setPresaleStartDate(uint256 timestamp) public onlyOwner {
        _presaleStartDate = timestamp;
    }


    function getWLMintStartDate() public view returns(uint256) {
        return _wlMintStartDate;
    }


    function setWLMintStartDate(uint256 timestamp) public onlyOwner {
        _wlMintStartDate = timestamp;
    }


    function isWhiteListed(address account) public view returns(bool) {
        return _whiteList[account];
    }


    function addToWhiteList(address account) public onlyOwner {
        require(account != address(0), "Zero address prohibited");
        require(!_whiteList[account], "Account is already in white list");
        _whiteList[account] = true;
    }

    function removeFromWhiteList(address account) public onlyOwner {
        require(account != address(0), "Zero address prohibited");
        require(_whiteList[account], "Account is not in white list");
        _whiteList[account] = false;
    }


    function withdrawETH(uint256 amount, uint256[4] memory _p) public onlyOwner {
        require(amount > 0, "Zero amount prohibited");
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, "Insufficient amount on contract balance to withdraw");
        require(_p[0] + _p[1] + _p[2] + _p[3] == 100, "Total sum of percentages must be equal to 100");
        uint[4] memory amounts;
        for (uint i = 0; i < _p.length - 1; i++) {
            amounts[i] = amount * _p[i] / 100;
        }
        amounts[3] = amount - amounts[0]  - amounts[1]  - amounts[2];
        for (uint i = 0; i < _owners.length; i++) {
            (bool sent, ) = payable(_owners[i]).call{value: amounts[i], gas: 100000}("");
            require(sent, "Failed to send Ether");
        }
    }



    function _getNextTokenId() private view returns (uint256) {
            return _currentTokenId + 1;
    }


    function _incrementTokenId() private {
        _currentTokenId += 1;
    }


    function _getNextOwnersTokenId(address account) private view returns (uint256) {
        if (_mintedTokens[account] < 250) {
            return _currentOwnersTokenId + 1;
        }
        return _currentTokenId + 1;
    }


    function _incrementOwnersTokenId(address account) private {
        if (_mintedTokens[account] < 250) {
            _currentOwnersTokenId += 1;
        } else {
            _currentTokenId += 1;
        }
    }


    function isOwner(address account) private view returns (bool) {
        return _isOwner[account];
    }


    function getAllTokensByOwner(address account) public view returns (uint256[] memory) {
        uint256 length = balanceOf(account);
        uint256[] memory result = new uint256[](length);
        for (uint i = 0; i < length; i++)
            result[i] = tokenOfOwnerByIndex(account, i);
        return result;
    }


    function mint() public payable {
        require(!isOwner(_msgSender()), "This function can be called only by ordinary users.");
        require(_mintedTokens[_msgSender()] < 3, "Amount of tokens exceed allowed amount to mint");
        require((_presaleStartDate > 0 && _mintStartDate > 0 && _wlMintStartDate > 0), "Mint is not started yet");
        require(_currentTokenId < _maxTotalSupply, "Max Total Supply reached");
        require(block.timestamp > _presaleStartDate, "Presale is not started yet");
        uint256 change;
        if (block.timestamp < _mintStartDate) {
            require(msg.value >= _presalePrice, "Insufficient ETH amount");
            change = msg.value - _presalePrice;
        } else if (_whiteList[_msgSender()]) {
            if (block.timestamp > _wlMintStartDate) {
                require(msg.value >= _wlMintPrice, "Insufficient ETH amount");
                change = msg.value - _wlMintPrice ;
            } else {
                require(msg.value >= _mintPrice, "Insufficient ETH amount");
                change = msg.value - _mintPrice;
            }

        } else {
            require(msg.value >= _mintPrice, "Insufficient ETH amount");
            change = msg.value - _mintPrice;
        }
        uint256 newTokenId = _getNextTokenId();

        _safeMint(_msgSender(), newTokenId);

        _incrementTokenId();

        _mintedTokens[_msgSender()] += 1;

        if (change > 0) {
            (bool sent, ) = payable(_msgSender()).call{value: change, gas: 100000}("");
            require(sent, "Failed to send Ether");
        }
    }


    function mintOwner(address to) public {
        require(isOwner(_msgSender()), "Unauthorised access");
        require(to != address(0), "Zero address prohibited");
        if (_mintedTokens[_msgSender()] >= 250) {
            require(_currentTokenId < _maxTotalSupply, "Max Total Supply reached");
        }
        uint256 newTokenId = _getNextOwnersTokenId(_msgSender());
        _safeMint(to, newTokenId);
        _incrementOwnersTokenId(_msgSender());
        _mintedTokens[_msgSender()] += 1;
    }

}