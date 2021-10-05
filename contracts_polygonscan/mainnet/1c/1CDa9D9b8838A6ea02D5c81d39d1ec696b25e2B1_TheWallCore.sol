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

import "SafeMath.sol";
import "SignedSafeMath.sol";
import "Address.sol";
import "Strings.sol";
import "thewallusers.sol";


contract TheWallCore is TheWallUsers
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Address for address;
    using Address for address payable;
    using Strings for uint256;

    event SizeChanged(int256 wallWidth, int256 wallHeight);
    event AreaCostChanged(uint256 costWei);
    event FeeChanged(uint256 feePercents);
    event FundsReceiverChanged(address fundsReceiver);
    event SecretCommited(uint256 secret, bytes32 hashOfSecret);
    event SecretUpdated(bytes32 hashOfNewSecret);

    enum Status
    {
        None,
        ForSale,
        ForRent,
        Rented
    }

    enum TokenType
    {
        Unknown,
        Area,
        Cluster
    }

    struct Token
    {
        TokenType  tt;
        Status     status;
        string     link;
        string     tags;
        string     title;
        uint256    cost;
        uint256    rentDuration;
        address    tenant;
        bytes      content;
    }
    
    struct Area
    {
        int256     x;
        int256     y;
        bool       premium;
        uint256    cluster;
        bytes      image;
        bytes32    hashOfSecret;
        uint256    nonce;
    }

    struct Cluster
    {
        uint256[]  areas;
        mapping (uint256 => uint256) areaToIndex;
        uint256    revision;
    }

    // x => y => area erc-721
    mapping (int256 => mapping (int256 => uint256)) private _areasOnTheWall;

    // erc-721 => Token, Area or Cluster
    mapping (uint256 => Token) private _tokens;
    mapping (uint256 => Area) private _areas;
    mapping (uint256 => Cluster) private _clusters;

    mapping (bytes32 => uint256) private _secrets;
    bytes32 private _hashOfSecret;
    bytes32 private _hashOfSecretToCommit;

    int256  public  _wallWidth;
    int256  public  _wallHeight;
    uint256 public  _costWei;
    uint256 public  _feePercents;
    address payable private _fundsReceiver;
    address private _thewall;

    constructor (address coupons) TheWallUsers(coupons)
    {
        _wallWidth = 500;
        _wallHeight = 500;
        _costWei = 1 ether / 10;
        _feePercents = 30;
        _fundsReceiver = payable(_msgSender());
        emit SizeChanged(_wallWidth, _wallHeight);
        emit AreaCostChanged(_costWei);
        emit FeeChanged(_feePercents);
        emit FundsReceiverChanged(_fundsReceiver);
    }

    function setTheWall(address thewall) public
    {
        require(thewall != address(0) && _thewall == address(0));
        _thewall = thewall;
    }

    modifier onlyTheWall()
    {
        require(_msgSender() == _thewall);
        _;
    }
    
    function setWallSize(int256 wallWidth, int256 wallHeight) public onlyOwner
    {
        require(_wallWidth <= wallWidth && _wallHeight <= wallHeight);
        _wallWidth = wallWidth;
        _wallHeight = wallHeight;
        emit SizeChanged(wallWidth, wallHeight);
    }

    function setCostWei(uint256 costWei) public onlyOwner
    {
        _costWei = costWei;
        emit AreaCostChanged(costWei);
    }

    function setFee(uint256 feePercents) public onlyOwner
    {
        _feePercents = feePercents;
        emit FeeChanged(feePercents);
    }

    function setFundsReceiver(address payable fundsReceiver) public onlyOwner
    {
        require(fundsReceiver != address(0));
        _fundsReceiver = fundsReceiver;
        emit FundsReceiverChanged(fundsReceiver);
    }

    function commitSecret(uint256 secret) public onlyOwner
    {
        require(_hashOfSecretToCommit == keccak256(abi.encodePacked(secret)));
        _secrets[_hashOfSecretToCommit] = secret;
        emit SecretCommited(secret, _hashOfSecretToCommit);
        delete _hashOfSecretToCommit;
    }

    function updateSecret(bytes32 hashOfNewSecret) public onlyOwner
    {
        _hashOfSecretToCommit = _hashOfSecret;
        _hashOfSecret = hashOfNewSecret;
        emit SecretUpdated(hashOfNewSecret);
    }

    function _canBeTransferred(uint256 tokenId) public view returns(TokenType)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No such token found");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Can't transfer rented item");
        if (token.tt == TokenType.Area)
        {
            Area memory area = _areas[tokenId];
            require(area.cluster == uint256(0), "TheWallCore: Can't transfer area owned by cluster");
        }
        else
        {
            Cluster storage cluster = _clusters[tokenId];
            require(cluster.areas.length > 0, "TheWallCore: Can't transfer empty cluster");
        }
        return token.tt;
    }

    function _isOrdinaryArea(uint256 areaId) public view
    {
        Token storage token = _tokens[areaId];
        require(token.tt == TokenType.Area, "TheWallCore: Token is not area");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Unordinary status");
        Area memory area = _areas[areaId];
        require(area.cluster == uint256(0), "TheWallCore: Area is owned by cluster");
    }

    function _areasInCluster(uint256 clusterId) public view returns(uint256[] memory)
    {
        return _clusters[clusterId].areas;
    }

    function _forSale(uint256 tokenId, uint256 priceWei) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForSale;
    }

    function _forRent(uint256 tokenId, uint256 priceWei, uint256 durationSeconds) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForRent;
        token.rentDuration = durationSeconds;
    }

    function _createCluster(uint256 tokenId, bytes memory content) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Cluster;
        token.status = Status.None;
        token.content = content;

        Cluster storage cluster = _clusters[tokenId];
        cluster.revision = 1;
    }

    function _removeCluster(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt == TokenType.Cluster, "TheWallCore: no cluster found for remove");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: can't remove rented cluster");

        Cluster storage cluster = _clusters[tokenId];
        for(uint i=0; i<cluster.areas.length; ++i)
        {
            uint256 areaId = cluster.areas[i];
            
            Token storage areaToken = _tokens[areaId];
            areaToken.status = token.status;
            areaToken.link = token.link;
            areaToken.tags = token.tags;
            areaToken.title = token.title;

            Area storage area = _areas[areaId];
            area.cluster = 0;
        }
        delete _clusters[tokenId];
        delete _tokens[tokenId];
    }
    
    function _abs(int256 v) pure public returns (int256)
    {
        if (v < 0)
        {
            v = -v;
        }
        return v;
    }

    function _create(uint256 tokenId, int256 x, int256 y, uint256 clusterId, uint256 nonce, bytes memory content) onlyTheWall public returns (uint256 revision, bytes32 hashOfSecret)
    {
        _areasOnTheWall[x][y] = tokenId;

        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Area;
        token.status = Status.None;
        token.content = content;

        Area storage area = _areas[tokenId];
        area.x = x;
        area.y = y;
        if (_abs(x) <= 100 && _abs(y) <= 100)
        {
            area.premium = true;
        }
        else
        {
            area.nonce = nonce;
            area.hashOfSecret = _hashOfSecret;
        }

        revision = 0;
        if (clusterId !=0)
        {
            area.cluster = clusterId;
        
            Cluster storage cluster = _clusters[clusterId];
            cluster.revision += 1;
            revision = cluster.revision;
            cluster.areas.push(tokenId);
            cluster.areaToIndex[tokenId] = cluster.areas.length - 1;
        }
        
        return (revision, area.hashOfSecret);
    }

    function _areaOnTheWall(int256 x, int256 y) public view returns(uint256)
    {
        return _areasOnTheWall[x][y];
    }

    function _buy(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForSale, "TheWallCore: Item is not for sale");
        require(weiAmount == token.cost, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", weiAmount.toString(), "/", token.cost.toString())));

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be sold");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWallCore: Incorrect cluster's revision");
        }
        
        token.status = Status.None;

        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(_feePercents).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));
    }
    
    function _rent(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public returns(uint256 rentDuration)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent, "TheWallCore: Item is not for rent");
        require(weiAmount == token.cost, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", weiAmount.toString(), "/", token.cost.toString())));

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be rented");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWall: Incorrect cluster's revision");
        }

        rentDuration = block.timestamp.add(token.rentDuration);
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = me;
        
        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(_feePercents).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));

        return rentDuration;
    }

    function _isPremium(Area storage area, uint256 tokenId) internal returns(bool)
    {
        if (area.hashOfSecret != bytes32(0))
        {
            uint256 secret = _secrets[area.hashOfSecret];
            if (secret != 0)
            {
                uint256 factor = uint256(keccak256(abi.encodePacked(secret, tokenId, area.nonce)));
                area.premium = ((factor % 1000) == 1);
                area.hashOfSecret = bytes32(0);
            }
        }
        return area.premium;
    }

    function _rentTo(uint256 tokenId, address tenant, uint256 durationSeconds) onlyTheWall public returns(uint256 rentDuration)
    {
        _canBeTransferred(tokenId);
        rentDuration = block.timestamp.add(durationSeconds);
        Token storage token = _tokens[tokenId];
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = tenant;
        return rentDuration;
    }

    function _cancel(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent || token.status == Status.ForSale, "TheWallCore: item is not for rent or for sale");
        token.cost = 0;
        token.status = Status.None;
        token.rentDuration = 0;
    }
    
    function _finishRent(address who, uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.tenant == who, "TheWall: Only tenant can finish rent");
        require(token.status == Status.Rented && token.rentDuration > block.timestamp, "TheWallCore: item is not rented");
        token.status = Status.None;
        token.rentDuration = 0;
        token.cost = 0;
        token.tenant = address(0);
    }
    
    function _addToCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(areaToken.status != Status.Rented || areaToken.rentDuration < block.timestamp, "TheWallCore: Area is rented");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == 0, "TheWallCore: Area already in cluster");
        area.cluster = clusterId;
        
        areaToken.status = Status.None;
        areaToken.rentDuration = 0;
        areaToken.cost = 0;
        
        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        cluster.areas.push(areaId);
        cluster.areaToIndex[areaId] = cluster.areas.length - 1;
        return cluster.revision;
    }

    function _removeFromCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == clusterId, "TheWallCore: Area is not in cluster");
        area.cluster = 0;

        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        uint index = cluster.areaToIndex[areaId];
        if (index != cluster.areas.length - 1)
        {
            uint256 movedAreaId = cluster.areas[cluster.areas.length - 1];
            cluster.areaToIndex[movedAreaId] = index;
            cluster.areas[index] = movedAreaId;
        }
        delete cluster.areaToIndex[areaId];
        cluster.areas.pop();
        return cluster.revision;
    }

    function _canBeManaged(address who, address owner, uint256 tokenId) internal view returns (TokenType t)
    {
        Token storage token = _tokens[tokenId];
        t = token.tt;
        require(t != TokenType.Unknown, "TheWallCore: No token found");
        if (t == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            if (area.cluster != uint256(0))
            {
                token = _tokens[area.cluster];
                require(token.tt == TokenType.Cluster, "TheWallCore: No cluster token found");
            }
        }
        
        if (token.status == Status.Rented && token.rentDuration > block.timestamp)
        {
            require(who == token.tenant, "TheWallCore: Rented token can be managed by tenant only");
        }
        else
        {
            require(who == owner, "TheWallCore: Only owner can manager token");
        }
    }

    function _setContent(address who, address owner, uint256 tokenId, bytes memory content) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.content = content;
    }

    function _setAttributesComplete(address who, address owner, uint256 tokenId, bytes memory image, string memory link, string memory tags, string memory title) onlyTheWall public
    {
        TokenType tt = _canBeManaged(who, owner, tokenId);
        require(tt == TokenType.Area, "TheWallCore: Image can be set to area only");
        Area storage area = _areas[tokenId];
        area.image = image;
        Token storage token = _tokens[tokenId];
        token.link = link;
        token.tags = tags;
        token.title = title;
        delete token.content;
    }

    function _setAttributes(address who, address owner, uint256 tokenId, string memory link, string memory tags, string memory title) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.link = link;
        token.tags = tags;
        token.title = title;
        delete token.content;
    }

    function _setImage(address who, address owner, uint256 tokenId, bytes memory image) onlyTheWall public
    {
        TokenType tt = _canBeManaged(who, owner, tokenId);
        require(tt == TokenType.Area, "TheWallCore: Image can be set to area only");
        Area storage area = _areas[tokenId];
        area.image = image;
        delete _tokens[tokenId].content;
    }

    function _setLink(address who, address owner, uint256 tokenId, string memory link) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.link = link;
        delete token.content;
    }

    function _setTags(address who, address owner, uint256 tokenId, string memory tags) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.tags = tags;
        delete token.content;
    }

    function _setTitle(address who, address owner, uint256 tokenId, string memory title) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.title = title;
        delete token.content;
    }

    function tokenInfo(uint256 tokenId) public view returns(bytes memory, string memory, string memory, string memory, bytes memory)
    {
        Token memory token = _tokens[tokenId];
        bytes memory image;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            image = area.image;
        }
        return (image, token.link, token.tags, token.title, token.content);
    }

    function _canBeCreated(int256 x, int256 y) view public
    {
        require(_abs(x) < _wallWidth && _abs(y) < _wallHeight, "TheWallCore: Out of wall");
        require(_areaOnTheWall(x, y) == uint256(0), "TheWallCore: Area is busy");
    }

    function _processPaymentCreate(address me, uint256 weiAmount, uint256 areasNum, address payable referrerCandidate) onlyTheWall public payable returns(uint256)
    {
        uint256 usedCoupons = _useCoupons(me, areasNum);
        areasNum -= usedCoupons;
        return _processPayment(me, weiAmount, areasNum, referrerCandidate);
    }
    
    function _processPayment(address me, uint256 weiAmount, uint256 itemsAmount, address payable referrerCandidate) internal returns (uint256)
    {
        uint256 payValue = _costWei.mul(itemsAmount);
        require(payValue <= weiAmount, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", payValue.toString(), "/", weiAmount.toString())));
        if (weiAmount > payValue)
        {
            payable(me).sendValue(weiAmount.sub(payValue));
        }
        if (payValue > 0)
        {
            uint256 alreadyPayed = _processRef(me, referrerCandidate, payValue);
            _fundsReceiver.sendValue(payValue.sub(alreadyPayed));
        }
        return payValue;
    }

    function _canBeCreatedMulti(int256 x, int256 y, int256 width, int256 height) view public
    {
        require(_abs(x) < _wallWidth &&
                _abs(y) < _wallHeight &&
                _abs(x.add(width)) < _wallWidth &&
                _abs(y.add(height)) < _wallHeight,                
                "TheWallCpre: Out of wall");
        require(width > 0 && height > 0, "TheWallCore: dimensions must be greater than zero");
    }

    function _buyCoupons(address me, uint256 weiAmount, address payable referrerCandidate) public payable onlyTheWall returns (uint256)
    {
        uint256 couponsAmount = weiAmount.div(_costWei);
        uint payValue = _processPayment(me, weiAmount, couponsAmount, referrerCandidate);
        if (payValue > 0)
        {
            _giveCoupons(me, couponsAmount);
        }
        return payValue;
    }
    
    function _clusterOf(uint256 tokenId) view public returns (uint256)
    {
        return _areas[tokenId].cluster;
    }
}