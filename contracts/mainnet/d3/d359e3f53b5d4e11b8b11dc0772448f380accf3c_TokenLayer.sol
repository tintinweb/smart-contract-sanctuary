pragma solidity ^0.4.18; // solhint-disable-line

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC721 {
    function approve(address _to, uint256 _tokenID) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenID) public view returns (address addr);
    function takeOwnership(uint256 _tokenID) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenID) public;
    function transfer(address _to, uint256 _tokenID) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenID); // solhint-disable-line
    event Approval(address indexed owner, address indexed approved, uint256 tokenID);

    function name() public pure returns (string);
    function symbol() public pure returns (string);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Manageable is Ownable {

    address public manager;
    bool public contractLock;

    event ManagerTransferred(address indexed previousManager, address indexed newManager);
    event ContractLockChanged(address admin, bool state);

    function Manageable() public {
        manager = msg.sender;
        contractLock = false;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    modifier onlyAdmin() {
        require((msg.sender == manager) || (msg.sender == owner));
        _;
    }

    modifier isUnlocked() {
        require(!contractLock);
        _;
    }

    function transferManager(address newManager) public onlyAdmin {
        require(newManager != address(0));
        ManagerTransferred(manager, newManager);
        manager = newManager;
    }

    function setContractLock(bool setting) public onlyAdmin {
        contractLock = setting;
        ContractLockChanged(msg.sender, setting);
    }

    function payout(address _to) public onlyOwner {
        if (_to == address(0)) {
            owner.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    function withdrawFunds(address _to, uint256 amount) public onlyOwner {
        require(this.balance >= amount);
        if (_to == address(0)) {
            owner.transfer(amount);
        } else {
            _to.transfer(amount);
        }
    }
}

contract TokenLayer is ERC721, Manageable {

    using SafeMath for uint256;

    /********************************************** EVENTS **********************************************/
    event TokenCreated(uint256 tokenId, bytes32 name, uint256 parentId, address owner);
    event TokenDeleted(uint256 tokenId);

    event TokenSold(
        uint256 tokenId, uint256 oldPrice,
        uint256 newPrice, address prevOwner,
        address winner, bytes32 name,
        uint256 parentId
    );

    event PriceChanged(uint256 tokenId, uint256 oldPrice, uint256 newPrice);
    event ParentChanged(uint256 tokenId, uint256 oldParentId, uint256 newParentId);
    event NameChanged(uint256 tokenId, bytes32 oldName, bytes32 newName);
    event MetaDataChanged(uint256 tokenId, bytes32 oldMeta, bytes32 newMeta);

    /******************************************** STORAGE ***********************************************/
    uint256 private constant DEFAULTPARENT = 123456789;

    mapping (uint256 => Token)   private tokenIndexToToken;
    mapping (address => uint256) private ownershipTokenCount;

    address public gameAddress;
    address public parentAddr;

    uint256 private totalTokens;
    uint256 public devFee = 50;
    uint256 public ownerFee = 200;
    uint256[10] private chainFees = [10];

    struct Token {
        bool exists;
        address approved;
        address owner;
        bytes32 metadata;
        bytes32 name;
        uint256 lastBlock;
        uint256 parentId;
        uint256 price;
    }

    /******************************************* MODIFIERS **********************************************/
    modifier onlySystem() {
        require((msg.sender == gameAddress) || (msg.sender == manager));
        _;
    }

    /****************************************** CONSTRUCTOR *********************************************/
    function TokenLayer(address _gameAddress, address _parentAddr) public {
        gameAddress = _gameAddress;
        parentAddr = _parentAddr;
    }

    /********************************************** PUBLIC **********************************************/
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function name() public pure returns (string) {
        return "CryptoJintori";
    }

    function symbol() public pure returns (string) {
        return "PrefectureToken";
    }

    function approve(address _to, uint256 _tokenId, address _from) public onlySystem {
        _approve(_to, _tokenId, _from);
    }

    function approve(address _to, uint256 _tokenId) public isUnlocked {
        _approve(_to, _tokenId, msg.sender);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function bundleToken(uint256 _tokenId) public view returns(uint256[8] _tokenData) {
        Token storage token = tokenIndexToToken[_tokenId];

        uint256[8] memory tokenData;

        tokenData[0] = uint256(token.name);
        tokenData[1] = token.parentId;
        tokenData[2] = token.price;
        tokenData[3] = uint256(token.owner);
        tokenData[4] = _getNextPrice(_tokenId);
        tokenData[5] = devFee+getChainFees(_tokenId);
        tokenData[6] = uint256(token.approved);
        tokenData[7] = uint256(token.metadata);
        return tokenData;
    }

    function takeOwnership(uint256 _tokenId, address _to) public onlySystem {
        _takeOwnership(_tokenId, _to);
    }

    function takeOwnership(uint256 _tokenId) public isUnlocked {
        _takeOwnership(_tokenId, msg.sender);
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 _totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId = 0;
            uint256 tokenIndex = 0;
            while (tokenIndex <= _totalTokens) {
                if (exists(tokenId)) {
                    tokenIndex++;
                    if (tokenIndexToToken[tokenId].owner == _owner) {
                        result[resultIndex] = tokenId;
                        resultIndex++;
                    }
                }
                tokenId++;
            }
            return result;
        }
    }

    function totalSupply() public view returns (uint256 total) {
        return totalTokens;
    }

    function transfer(address _to, address _from, uint256 _tokenId) public onlySystem {
        _checkThenTransfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public isUnlocked {
        _checkThenTransfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public onlySystem {
        _transferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, uint256 _tokenId) public isUnlocked {
        _transferFrom(_from, msg.sender, _tokenId);
    }

    function createToken(
        uint256 _tokenId, address _owner,
        bytes32 _name, uint256 _parentId,
        uint256 _price, bytes32 _metadata
    ) public onlyAdmin {
        require(_price > 0);
        require(_addressNotNull(_owner));
        require(_tokenId == uint256(uint32(_tokenId)));
        require(!exists(_tokenId));

        totalTokens++;

        Token memory _token = Token({
            name: _name,
            parentId: _parentId,
            exists: true,
            price: _price,
            owner: _owner,
            approved : 0,
            lastBlock : block.number,
            metadata : _metadata
        });

        tokenIndexToToken[_tokenId] = _token;

        TokenCreated(_tokenId, _name, _parentId, _owner);

        _transfer(address(0), _owner, _tokenId);
    }

    function createTokens(
        uint256[] _tokenIds, address[] _owners,
        bytes32[] _names, uint256[] _parentIds,
        uint256[] _prices, bytes32[] _metadatas
    ) public onlyAdmin {
        for (uint256 id = 0; id < _tokenIds.length; id++) {
            createToken(
                _tokenIds[id], _owners[id], _names[id],
                _parentIds[id], _prices[id], _metadatas[id]
                );
        }
    }

    function deleteToken(uint256 _tokenId) public onlyAdmin {
        require(_tokenId == uint256(uint32(_tokenId)));
        require(exists(_tokenId));
        totalTokens--;

        address oldOwner = tokenIndexToToken[_tokenId].owner;

        ownershipTokenCount[oldOwner] = ownershipTokenCount[oldOwner]--;
        delete tokenIndexToToken[_tokenId];
        TokenDeleted(_tokenId);
    }

    function incrementPrice(uint256 _tokenId, address _to) public onlySystem {
        require(exists(_tokenId));
        uint256 _price = tokenIndexToToken[_tokenId].price;
        address _owner = tokenIndexToToken[_tokenId].owner;
        uint256 _totalFees = getChainFees(_tokenId);
        tokenIndexToToken[_tokenId].price = _price.mul(1000+ownerFee).div(1000-(devFee+_totalFees));

        TokenSold(
            _tokenId, _price, tokenIndexToToken[_tokenId].price,
            _owner, _to, tokenIndexToToken[_tokenId].name,
            tokenIndexToToken[_tokenId].parentId
        );
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        require(exists(_tokenId));
        _owner = tokenIndexToToken[_tokenId].owner;
    }

    function blocked(uint256 _tokenId) public view returns (bool _blocked) {
        return (tokenIndexToToken[_tokenId].lastBlock == block.number);
    }

    function exists(uint256 _tokenId) public view returns(bool) {
        return (tokenIndexToToken[_tokenId].exists);
    }

    /********************************************** SETTERS *********************************************/
    function setLayerParent(address _parent) public onlyAdmin {
        parentAddr = _parent;
    }

    function setGame(address _gameAddress) public onlyAdmin {
        gameAddress = _gameAddress;
    }

    function setPrice(uint256 _tokenId, uint256 _price, address _owner) public onlySystem {
        require(_owns(_owner, _tokenId));
        uint256 oldPrice = tokenIndexToToken[_tokenId].price;
        tokenIndexToToken[_tokenId].price = _price;
        PriceChanged(_tokenId, oldPrice, _price);
    }

    function setParent(uint256 _tokenId, uint256 _parentId) public onlyAdmin {
        require(exists(_tokenId));
        uint256 oldParentId = tokenIndexToToken[_tokenId].parentId;
        tokenIndexToToken[_tokenId].parentId = _parentId;
        ParentChanged(_tokenId, oldParentId, _parentId);
    }

    function setName(uint256 _tokenId, bytes32 _name) public onlyAdmin {
        require(exists(_tokenId));
        bytes32 oldName = tokenIndexToToken[_tokenId].name;
        tokenIndexToToken[_tokenId].name = _name;
        NameChanged(_tokenId, oldName, _name);
    }

    function setMetadata(uint256 _tokenId, bytes32 _metadata) public onlyAdmin {
        require(exists(_tokenId));
        bytes32 oldMeta = tokenIndexToToken[_tokenId].metadata;
        tokenIndexToToken[_tokenId].metadata = _metadata;
        MetaDataChanged(_tokenId, oldMeta, _metadata);
    }

    function setDevFee(uint256 _devFee) public onlyAdmin {
        devFee = _devFee;
    }

    function setOwnerFee(uint256 _ownerFee) public onlyAdmin {
        ownerFee = _ownerFee;
    }

    function setChainFees(uint256[10] _chainFees) public onlyAdmin {
        chainFees = _chainFees;
    }

    /********************************************** GETTERS *********************************************/
    function getToken(uint256 _tokenId) public view returns
    (
        bytes32 tokenName, uint256 parentId, uint256 price,
        address _owner, uint256 nextPrice, uint256 nextPriceFees,
        address approved, bytes32 metadata
    ) {
        Token storage token = tokenIndexToToken[_tokenId];

        tokenName = token.name;
        parentId = token.parentId;
        price = token.price;
        _owner = token.owner;
        nextPrice = _getNextPrice(_tokenId);
        nextPriceFees = devFee+getChainFees(_tokenId);
        metadata = token.metadata;
        approved = token.approved;
    }

    function getChainFees(uint256 _tokenId) public view returns (uint256 _total) {
        uint256 chainLength = _getChainLength(_tokenId);
        uint256 totalFee = 0;
        for (uint id = 0; id < chainLength; id++) {
            totalFee = totalFee + chainFees[id];
        }
        return(totalFee);
    }

    function getChainFeeArray() public view returns (uint256[10] memory _chainFees) {
        return(chainFees);
    }

    function getPriceOf(uint256 _tokenId) public view returns (uint256 price) {
        require(exists(_tokenId));
        return tokenIndexToToken[_tokenId].price;
    }

    function getParentOf(uint256 _tokenId) public view returns (uint256 parentId) {
        require(exists(_tokenId));
        return tokenIndexToToken[_tokenId].parentId;
    }

    function getMetadataOf(uint256 _tokenId) public view returns (bytes32 metadata) {
        require(exists(_tokenId));
        return (tokenIndexToToken[_tokenId].metadata);
    }

    function getChain(uint256 _tokenId) public view returns (address[10] memory _owners) {
        require(exists(_tokenId));

        uint256 _parentId = getParentOf(_tokenId);
        address _parentAddr = parentAddr;

        address[10] memory result;

        if (_parentId != DEFAULTPARENT && _addressNotNull(_parentAddr)) {
            uint256 resultIndex = 0;

            TokenLayer layer = TokenLayer(_parentAddr);
            bool parentExists = layer.exists(_parentId);

            while ((_parentId != DEFAULTPARENT) && _addressNotNull(_parentAddr) && parentExists) {
                parentExists = layer.exists(_parentId);
                if (!parentExists) {
                    return(result);
                }
                result[resultIndex] = layer.ownerOf(_parentId);
                resultIndex++;

                _parentId = layer.getParentOf(_parentId);
                _parentAddr = layer.parentAddr();

                layer = TokenLayer(_parentAddr);
            }

            return(result);
        }
    }

    /******************************************** PRIVATE ***********************************************/
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return (tokenIndexToToken[_tokenId].approved == _to);
    }

    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToToken[_tokenId].owner;
    }

    function _checkThenTransfer(address _from, address _to, uint256 _tokenId) private {
        require(_owns(_from, _tokenId));
        require(_addressNotNull(_to));
        require(exists(_tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIndexToToken[_tokenId].owner = _to;
        tokenIndexToToken[_tokenId].lastBlock = block.number;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            tokenIndexToToken[_tokenId].approved = 0;
        }

        Transfer(_from, _to, _tokenId);
    }

    function _approve(address _to, uint256 _tokenId, address _from) private {
        require(_owns(_from, _tokenId));

        tokenIndexToToken[_tokenId].approved = _to;

        Approval(_from, _to, _tokenId);
    }

    function _takeOwnership(uint256 _tokenId, address _to) private {
        address newOwner = _to;
        address oldOwner = tokenIndexToToken[_tokenId].owner;

        require(_addressNotNull(newOwner));
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) private {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

    function _getChainLength(uint256 _tokenId) private view returns (uint256 _length) {
        uint256 length;

        uint256 _parentId = getParentOf(_tokenId);
        address _parentAddr = parentAddr;
        if (_parentId == DEFAULTPARENT || !_addressNotNull(_parentAddr)) {
            return 0;
        }

        TokenLayer layer = TokenLayer(_parentAddr);
        bool parentExists = layer.exists(_parentId);

        while ((_parentId != DEFAULTPARENT) && _addressNotNull(_parentAddr) && parentExists) {
            parentExists = layer.exists(_parentId);
            if(!parentExists) {
                    return(length);
            }
            _parentId = layer.getParentOf(_parentId);
            _parentAddr = layer.parentAddr();
            layer = TokenLayer(_parentAddr);
            length++;
        }

        return(length);
    }

    function _getNextPrice(uint256 _tokenId) private view returns (uint256 _nextPrice) {
        uint256 _price = tokenIndexToToken[_tokenId].price;
        uint256 _totalFees = getChainFees(_tokenId);
        _price = _price.mul(1000+ownerFee).div(1000-(devFee+_totalFees));
        return(_price);
    }
}