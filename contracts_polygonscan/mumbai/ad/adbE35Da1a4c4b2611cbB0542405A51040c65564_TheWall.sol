/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "thewallcore_.sol";


contract TheWall is ERC721, Ownable, IERC721Receiver
{
    using SafeMath for uint256;

    event Payment(address indexed sender, uint256 amountWei);

    event AreaCreated(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, uint256 nonce, bytes32 hashOfSecret, bytes content);
    event ClusterCreated(uint256 indexed tokenId, address indexed owner, bytes content);
    event ClusterRemoved(uint256 indexed tokenId);

    event AreaAddedToCluster(uint256 indexed areaTokenId, uint256 indexed clusterTokenId, uint256 revision);
    event AreaRemovedFromCluster(uint256 indexed areaTokenId, uint256 indexed clusterTokenId, uint256 revision);

    event AreaImageChanged(uint256 indexed tokenId, bytes image);
    event ItemLinkChanged(uint256 indexed tokenId, string link);
    event ItemTagsChanged(uint256 indexed tokenId, string tags);
    event ItemTitleChanged(uint256 indexed tokenId, string title);
    event ItemContentChanged(uint256 indexed tokenId, bytes content);

    event ItemTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event ItemForRent(uint256 indexed tokenId, uint256 priceWei, uint256 durationSeconds);
    event ItemForSale(uint256 indexed tokenId, uint256 priceWei);
    event ItemRented(uint256 indexed tokenId, address indexed tenant, uint256 finishTime);
    event ItemBought(uint256 indexed tokenId, address indexed buyer);
    event ItemReset(uint256 indexed tokenId);
    event ItemRentFinished(uint256 indexed tokenId);
    
    event ReceivedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, address indexed owner, string tokenURI);
    event WithdrawExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, address indexed to);
    event AttachedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, uint256 areaId);
    event DetachedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress);

    TheWallCore private _core;
    uint256     private _minterCounter;
    uint256     private _externalTokensCounter;
    string      private _base;

    struct ExternalToken
    {
        address contractAddress;
        uint256 externalTokenId;
        address owner;
        uint256 attachedAreaId;
    }

    // internalId => ExternalToken
    mapping (uint256 => ExternalToken) private _externalTokens;

    // contractAddress => externalTokenId => internalId
    mapping (address => mapping (uint256 => uint256)) private _externalTokensId;
    
    // area => internalId
    mapping (uint256 => uint256) private _attachedExternalTokens;

    constructor(address core) ERC721("TheWall", "TWG")
    {
        _core = TheWallCore(core);
        _core.setTheWall(address(this));
        setBaseURI("https://thewall.global/erc721/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._canBeTransferred(tokenId);
        _transfer(from, to, tokenId);
        emit ItemTransferred(tokenId, from, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._canBeTransferred(tokenId);
        _safeTransfer(from, to, tokenId, data);
        emit ItemTransferred(tokenId, from, to);
    }

    function forSale(uint256 tokenId, uint256 priceWei) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._forSale(tokenId, priceWei);
        emit ItemForSale(tokenId, priceWei);
    }

    function forRent(uint256 tokenId, uint256 priceWei, uint256 durationSeconds) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._forRent(tokenId, priceWei, durationSeconds);
        emit ItemForRent(tokenId, priceWei, durationSeconds);
    }

    function createCluster(bytes memory content) public returns (uint256)
    {
        address me = _msgSender();

        _minterCounter = _minterCounter.add(1);
        uint256 tokenId = _minterCounter;
        _safeMint(me, tokenId);
        _core._createCluster(tokenId, content);

        emit ClusterCreated(tokenId, me, content);
        return tokenId;
    }

    function removeCluster(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        uint256[] memory tokens = _core._areasInCluster(tokenId);
        address clusterOwner = ownerOf(tokenId);
        for(uint i = 0; i < tokens.length; ++i)
        {
            address oldOwner = ownerOf(tokens[i]);
            if (oldOwner != clusterOwner)
            {
                uint256 token = tokens[i];
                _safeTransfer(oldOwner, clusterOwner, token, "");
            }
        }
        _core._removeCluster(tokenId);
        _burn(tokenId);
        emit ClusterRemoved(tokenId);
    }
    
    function _create(address owner, int256 x, int256 y, uint256 clusterId, uint256 nonce, bytes memory content) internal returns (uint256)
    {
        _minterCounter = _minterCounter.add(1);
        uint256 tokenId = _minterCounter;
        _safeMint(owner, tokenId);
        
        uint256 revision;
        bytes32 hashOfSecret;
        (revision, hashOfSecret) = _core._create(tokenId, x, y, clusterId, nonce, content);
        
        emit AreaCreated(tokenId, owner, x, y, nonce, hashOfSecret, content);
        if (clusterId != 0)
        {
            emit AreaAddedToCluster(tokenId, clusterId, revision);
        }
        
        return tokenId;
    }

    function create(int256 x, int256 y, uint256 clusterId, address payable referrerCandidate, uint256 nonce, bytes memory content) public payable returns (uint256)
    {
        address me = _msgSender();
        _core._canBeCreated(x, y);
        uint256 area = _create(me, x, y, clusterId, nonce, content);
        
        uint256 payValue = _core._processPaymentCreate{value: msg.value}(me, msg.value, 1, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }

        return area;
    }

    function createMulti(int256 x, int256 y, int256 width, int256 height, address payable referrerCandidate, uint256 nonce) public payable returns (uint256)
    {
        bytes memory emptyContent;
        uint256 cluster =  createCluster(emptyContent);
        _createMulti(x, y, width, height, cluster, referrerCandidate, nonce);
        return cluster;
    }

    function createMultiNoCluster(int256 x, int256 y, int256 width, int256 height, address payable referrerCandidate, uint256 nonce) public payable
    {
        _createMulti(x, y, width, height, 0, referrerCandidate, nonce);
    }

    function _createMulti(int256 x, int256 y, int256 width, int256 height, uint256 cluster, address payable referrerCandidate, uint256 nonce) internal
    {
        address me = _msgSender();
        _core._canBeCreatedMulti(x, y, width, height);

        uint256 areasNum = 0;
        int256 i;
        int256 j;
        bytes memory emptyContent;
        for(i = 0; i < width; ++i)
        {
            for(j = 0; j < height; ++j)
            {
                if (_core._areaOnTheWall(x + i, y + j) == uint256(0))
                {
                    areasNum = areasNum.add(1);
                    _create(me, x + i, y + j, cluster, nonce, emptyContent);
                }
            }
        }

        uint256 payValue = _core._processPaymentCreate{value: msg.value}(me, msg.value, areasNum, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }
    }

    function buy(uint256 tokenId, uint256 revision, address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        address payable tokenOwner = payable(actualOwnerOf(tokenId));
        _core._buy{value: msg.value}(tokenOwner, tokenId, me, msg.value, revision, referrerCandidate);
        emit Payment(me, msg.value);
        _safeTransfer(tokenOwner, me, tokenId, "");
        emit ItemBought(tokenId, me);
        emit ItemTransferred(tokenId, tokenOwner, me);
        emit ItemReset(tokenId);
    }

    function rent(uint256 tokenId, uint256 revision, address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        address payable tokenOwner = payable(actualOwnerOf(tokenId));
        uint256 rentDuration;
        rentDuration = _core._rent{value: msg.value}(tokenOwner, tokenId, me, msg.value, revision, referrerCandidate);
        emit Payment(me, msg.value);
        emit ItemRented(tokenId, me, rentDuration);
    }
    
    function rentTo(uint256 tokenId, address tenant, uint256 durationSeconds) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        uint256 rentDuration;
        rentDuration = _core._rentTo(tokenId, tenant, durationSeconds);
        emit ItemRented(tokenId, tenant, rentDuration);
    }
    
    function cancel(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._cancel(tokenId);
        emit ItemReset(tokenId);
    }
    
    function finishRent(uint256 tokenId) public
    {
        _core._finishRent(_msgSender(), tokenId);
        emit ItemRentFinished(tokenId);
    }
    
    function addToCluster(uint256 areaId, uint256 clusterId) public
    {
        uint256 revision = _core._addToCluster(_msgSender(), actualOwnerOf(areaId), ownerOf(clusterId), areaId, clusterId);
        emit AreaAddedToCluster(areaId, clusterId, revision);
    }

    function removeFromCluster(uint256 areaId, uint256 clusterId) public
    {
        address me = _msgSender();
        uint256 revision = _core._removeFromCluster(me, actualOwnerOf(areaId), ownerOf(clusterId), areaId, clusterId);
        if (ownerOf(areaId) != me)
        {
            _safeTransfer(ownerOf(areaId), me, areaId, "");
        }
        emit AreaRemovedFromCluster(areaId, clusterId, revision);
    }

    function setAttributesComplete(uint256 tokenId, bytes memory image, string memory link, string memory tags, string memory title) public
    {
        _core._setAttributesComplete(_msgSender(), actualOwnerOf(tokenId), tokenId, image, link, tags, title);
        emit AreaImageChanged(tokenId, image);
        emit ItemLinkChanged(tokenId, link);
        emit ItemTagsChanged(tokenId, tags);
        emit ItemTitleChanged(tokenId, title);
    }

    function setAttributes(uint256 tokenId, string memory link, string memory tags, string memory title) public
    {
        _core._setAttributes(_msgSender(), actualOwnerOf(tokenId), tokenId, link, tags, title);
        emit ItemLinkChanged(tokenId, link);
        emit ItemTagsChanged(tokenId, tags);
        emit ItemTitleChanged(tokenId, title);
    }

    function setImage(uint256 tokenId, bytes memory image) public
    {
        _core._setImage(_msgSender(), actualOwnerOf(tokenId), tokenId, image);
        emit AreaImageChanged(tokenId, image);
    }

    function setLink(uint256 tokenId, string memory link) public
    {
        _core._setLink(_msgSender(), actualOwnerOf(tokenId), tokenId, link);
        emit ItemLinkChanged(tokenId, link);
    }

    function setTags(uint256 tokenId, string memory tags) public
    {
        _core._setTags(_msgSender(), actualOwnerOf(tokenId), tokenId, tags);
        emit ItemTagsChanged(tokenId, tags);
    }

    function setTitle(uint256 tokenId, string memory title) public
    {
        _core._setTitle(_msgSender(), actualOwnerOf(tokenId), tokenId, title);
        emit ItemTitleChanged(tokenId, title);
    }

    function setContent(uint256 tokenId, bytes memory content) public
    {
        _core._setContent(_msgSender(), actualOwnerOf(tokenId), tokenId, content);
        emit ItemContentChanged(tokenId, content);
    }

    function setContentMulti(uint256[] memory tokens, bytes[] memory contents) public
    {
        require(tokens.length == contents.length, "TheWall: length must be equal");
        for(uint i = 0; i < tokens.length; ++i)
        {
            uint256 tokenId = tokens[i];
            bytes memory content = contents[i];
            _core._setContent(_msgSender(), actualOwnerOf(tokenId), tokenId, content);
            emit ItemContentChanged(tokenId, content);
        }
    }
    
    function buyCoupons(address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        uint256 payValue = _core._buyCoupons{value: msg.value}(me, msg.value, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }
    }
    
    receive () payable external
    {
        buyCoupons(payable(address(0)));
    }
    
    function actualOwnerOf(uint256 tokenId) public view returns (address)
    {
        uint256 clusterId = _core._clusterOf(tokenId);
        if (clusterId != 0)
        {
            tokenId = clusterId;
        }
        return ownerOf(tokenId);
    }
    
    function onERC721Received(address operator, address /*from*/, uint256 tokenId, bytes calldata /*data*/) public override returns (bytes4)
    {
        ExternalToken memory nft;
        nft.contractAddress = _msgSender();
        nft.owner = operator;
        nft.externalTokenId = tokenId;
        nft.attachedAreaId = 0;
        
        require(_externalTokensId[nft.contractAddress][tokenId] == 0, "TheWall: External NFT already exists");

        _externalTokensCounter = _externalTokensCounter.add(1);
        uint256 internalId = _externalTokensCounter;
        _externalTokens[internalId] = nft;
        _externalTokensId[nft.contractAddress][tokenId] = internalId;

        string memory uri = "";
        if (IERC165(nft.contractAddress).supportsInterface(type(IERC721Metadata).interfaceId))
        {
            uri = IERC721Metadata(nft.contractAddress).tokenURI(tokenId);
        }
        emit ReceivedExternalNFT(tokenId, nft.contractAddress, nft.owner, uri);
        return this.onERC721Received.selector;
    }
    
    function withdrawExternalNFT(uint256 externalTokenId, address contractAddress, address to) public
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        if (nft.attachedAreaId != 0)
        {
            _core._isOrdinaryArea(nft.attachedAreaId);
            require(actualOwnerOf(nft.attachedAreaId) == _msgSender(), "TheWall: Permission denied");
            delete _attachedExternalTokens[nft.attachedAreaId];
        }
        else
        {
            require(nft.owner == _msgSender(), "TheWall: Permission denied");
        }
        delete _externalTokens[internalId];
        delete _externalTokensId[contractAddress][externalTokenId];
        IERC721(contractAddress).safeTransferFrom(address(this), to, externalTokenId);
        emit WithdrawExternalNFT(externalTokenId, contractAddress, to);
    }
    
    function ownerWithdrawExternalNFT(uint256 externalTokenId, address contractAddress, address to) public onlyOwner
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId == 0 || _externalTokens[internalId].owner == address(this), "TheWall: External token has owner");
        IERC721(contractAddress).safeTransferFrom(address(this), to, externalTokenId);
    }

    function attachExternalNFT(uint256 externalTokenId, address contractAddress, uint256 areaId) public
    {
        _core._isOrdinaryArea(areaId);
        uint256 internalId = _attachedExternalTokens[areaId];
        if (internalId != 0)
        {
            ExternalToken storage pnft = _externalTokens[internalId];
            pnft.owner = actualOwnerOf(pnft.attachedAreaId);
            delete pnft.attachedAreaId;
            emit DetachedExternalNFT(pnft.externalTokenId, pnft.contractAddress);
        }
        internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        require(nft.attachedAreaId == 0, "TheWall: Already attached");
        require(nft.owner == _msgSender(), "TheWall: Permission denied");
        require(actualOwnerOf(areaId) == _msgSender(), "TheWall: Not owner of area");
        _attachedExternalTokens[areaId] = internalId;
        nft.attachedAreaId = areaId;
        emit AttachedExternalNFT(externalTokenId, contractAddress, areaId);
    }

    function detachExternalNFT(uint256 externalTokenId, address contractAddress) public
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        require(nft.attachedAreaId != 0, "TheWall: No attached area");
        nft.owner = actualOwnerOf(nft.attachedAreaId);
        require(nft.owner == _msgSender(), "TheWall: Permission denied");
        _core._isOrdinaryArea(nft.attachedAreaId);
        delete _attachedExternalTokens[nft.attachedAreaId];
        delete nft.attachedAreaId;
        emit DetachedExternalNFT(externalTokenId, contractAddress);
    }
}