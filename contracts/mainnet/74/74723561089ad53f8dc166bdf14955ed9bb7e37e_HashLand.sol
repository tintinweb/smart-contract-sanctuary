pragma solidity ^0.4.21;

library AddressUtils {

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // solium-disable-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

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
        return a / b;
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

contract ERC721Receiver {
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

contract ERC721BasicToken {

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    using SafeMath for uint256;
    using AddressUtils for address;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721TokenReceiver =
        bytes4(keccak256(&#39;onERC721Received(address,uint256,bytes)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;)) ^
        bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
        bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
        bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;));

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        require(
            tokenOwner[_tokenId] == msg.sender
            || tokenApprovals[_tokenId] == msg.sender
            || operatorApprovals[tokenOwner[_tokenId]][msg.sender]
        );
        _;
    }

    //  We implement ERC721 here
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool)
    {
        return (
          (_interfaceID == InterfaceSignature_ERC165)
          || (_interfaceID == InterfaceSignature_ERC721)
        );
    }

    function balanceOf(address _owner) public view returns (uint256) {
        //require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        //require(owner != address(0));
        return owner;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        canTransfer(_tokenId)
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function approve(address _approved, uint256 _tokenId) external {
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _to, bool _approved) external {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll
    (
        address _owner,
        address _operator
    )
        public view returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == InterfaceSignature_ERC721TokenReceiver);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }
}

contract ERC721Token is ERC721BasicToken{

    string internal name_;
    string internal symbol_;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    bytes4 constant InterfaceSignature_ERC721Metadata =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;tokenURI(uint256)&#39;));

    bytes4 constant InterfaceSignature_ERC721Enumerable =
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokenOfOwnerByIndex(address, uint256)&#39;));

    function ERC721Token(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

    //  We implement ERC721Metadata(optional) and ERC721Enumerable(optional).
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool)
    {
        return (
            super.supportsInterface(_interfaceID)
            || (_interfaceID == InterfaceSignature_ERC721Metadata)
            || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        );
    }

    function name() external view returns (string) {
        return name_;
    }

    function symbol() external view returns (string) {
        return symbol_;
    }

    function tokenURI(uint256 _tokenId) external view returns (string) {
        return tokenURIs[_tokenId];
    }

    function totalSupply() external view returns (uint256) {
        return allTokens.length;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < allTokens.length);
        return allTokens[_index];
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external view returns (uint256)
    {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);

        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length = ownedTokens[_from].length.sub(1);
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(ownerOf(_tokenId) != address(0));
        tokenURIs[_tokenId] = _uri;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

        // Clear metadata (if any)
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }

        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length = allTokens.length.sub(1);
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract HashLand is ERC721Token, owned{

    function HashLand() ERC721Token("HashLand", "HSL") public {}

    struct LandInfo {
        // Unique key for a land, derived from longitude and latitude
        bytes8 landKey;
        string landName;

        string ownerNick;
        string landSlogan;

        bool forSale;
        uint256 sellPrice;
    }

    mapping(uint256 => bytes8) landKeyOfId;
    mapping(bytes8 => uint256) landIdOfKey;
    mapping(uint256 => LandInfo) landInfoOfId;

    mapping (address => uint256) pendingWithdrawals;

    function mintLand(
        address _to,
        bytes8 _landKey,
        string _landName,
        string _ownerNick,
        string _landSlogan,
        string _landURI     // keccak256(landKey)
    )
        public onlyOwner
    {
        require(landIdOfKey[_landKey] == 0);
        uint256 _landId = allTokens.length.add(1);

        landKeyOfId[_landId] = _landKey;
        landIdOfKey[_landKey] = _landId;
        landInfoOfId[_landId] = LandInfo(
            _landKey, _landName,
            _ownerNick, _landSlogan,
            false, 0
        );

        _mint(_to, _landId);
        _setTokenURI(_landId, _landURI);
    }

    function officialTransfer(
        address _to,
        bytes8 _landKey,
        string _landName,
        string _ownerNick,
        string _landSlogan,
        string _landURI     // keccak256(landKey)
    )
        public
    {
        uint256 _landId = landIdOfKey[_landKey];
        if (_landId == 0) {
            require(msg.sender == owner);
            _landId = allTokens.length.add(1);

            landKeyOfId[_landId] = _landKey;
            landIdOfKey[_landKey] = _landId;
            landInfoOfId[_landId] = LandInfo(
                _landKey, _landName,
                _ownerNick, _landSlogan,
                false, 0
            );

            _mint(_to, _landId);
            _setTokenURI(_landId, _landURI);
        }
        else {
            require(tokenOwner[_landId] == msg.sender);
            require(_to != address(0));

            landInfoOfId[_landId].forSale = false;
            landInfoOfId[_landId].sellPrice = 0;
            landInfoOfId[_landId].ownerNick = _ownerNick;
            landInfoOfId[_landId].landSlogan = _landSlogan;

            clearApproval(msg.sender, _landId);
            removeTokenFrom(msg.sender, _landId);
            addTokenTo(_to, _landId);

            emit Transfer(msg.sender, _to, _landId);
        }
    }


    function burnLand(uint256 _landId) public onlyOwnerOf(_landId){
        bytes8 _landKey = landKeyOfId[_landId];
        require(_landKey != 0);
        landKeyOfId[_landId] = 0x0;
        landIdOfKey[_landKey] = 0;
        delete landInfoOfId[_landId];

        _burn(msg.sender, _landId);
    }

    function getLandIdByKey(bytes8 _landKey)
        external view
        returns (uint256)
    {
        return landIdOfKey[_landKey];
    }

    function getLandInfo(uint256 _landId)
        external view
        returns (bytes8, bool, uint256, string, string, string)
    {
        bytes8 _landKey = landKeyOfId[_landId];
        require(_landKey != 0);
        return (
            _landKey,
            landInfoOfId[_landId].forSale, landInfoOfId[_landId].sellPrice,
            landInfoOfId[_landId].landName,
            landInfoOfId[_landId].ownerNick, landInfoOfId[_landId].landSlogan
        );
    }

    function setOwnerNick(
        uint256 _landId,
        string _ownerNick
    )
        public
        onlyOwnerOf(_landId)
    {
        landInfoOfId[_landId].ownerNick = _ownerNick;
    }

    function setLandSlogan(
        uint256 _landId,
        string _landSlogan
    )
        public
        onlyOwnerOf(_landId)
    {
        landInfoOfId[_landId].landSlogan = _landSlogan;
    }

    function setForSale(
        uint256 _landId,
        bool _forSale,
        uint256 _sellPrice
    )
        public
        onlyOwnerOf(_landId)
    {
        landInfoOfId[_landId].forSale = _forSale;
        landInfoOfId[_landId].sellPrice = _sellPrice;
    }

    function buyLand(uint256 _landId) payable public {
        bytes8 _landKey = landKeyOfId[_landId];
        require(_landKey != 0);

        require(landInfoOfId[_landId].forSale == true);
        require(msg.value >= landInfoOfId[_landId].sellPrice);

        address origin_owner = tokenOwner[_landId];

        clearApproval(origin_owner, _landId);
        removeTokenFrom(origin_owner, _landId);
        addTokenTo(msg.sender, _landId);

        landInfoOfId[_landId].forSale = false;
        emit Transfer(origin_owner, msg.sender, _landId);

        uint256 price = landInfoOfId[_landId].sellPrice;
        uint256 priviousBalance = pendingWithdrawals[origin_owner];
        pendingWithdrawals[origin_owner] = priviousBalance.add(price);
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}