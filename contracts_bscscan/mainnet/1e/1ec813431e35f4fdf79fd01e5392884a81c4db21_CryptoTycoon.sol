/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// CryptoKitties Source code
// Copied from: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code

pragma solidity ^0.8.4;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <[email protected]> (https://github.com/dete)
abstract contract ERC721 {
    // Required methods
    function totalSupply() public view virtual returns (uint256 total);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view virtual returns (address owner);
    function approve(address _to, uint256 _tokenId) virtual external;
    function transfer(address _to, uint256 _tokenId) virtual external;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual external;
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) virtual external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view virtual returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract Ownable {
    address public owner;
    address public inheritor = address(0x14E9C26570651b4bEEd4D657189dcCb0501eA932);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function transferInheritor(address newInheritor)
    public onlyOwner {
        if (newInheritor != address(0)) {
            inheritor = newInheritor;
        }
    }
}

contract CryptoTycoon is Ownable, ERC721{

    struct CatBase {
        string name;
        string parity;
        string platform;
        uint64 totalCount;
        uint64 count;
        uint8 version;
    }

    struct Cat {
        uint8 catType;
        uint64 indexOfType;
        uint64 birth;
    }

    Cat[] cats;
    CatBase[] catBases;

    mapping (uint256 => address) public indexToOwner;
    mapping (uint256 => address) public indexToApproved;
    mapping (address => uint256) ownershipTokenCount;
    mapping (string => uint8) typeToIndex;
    mapping (uint8 => string) public indexToType;
    mapping (uint8 => mapping(uint64 => uint256)) tokenIdOfTypeIndex;
    mapping (address => mapping (address => bool)) _operatorApprovals;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of kittens is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        indexToOwner[_tokenId] = _to;
        // When creating new kittens _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete indexToApproved[_tokenId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return indexToOwner[_tokenId] == _claimant;
    }

    function balanceOf(address _owner) public view override returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns(bool) {
        return indexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        indexToApproved[_tokenId]=_approved;
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
    external override
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any horses (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of horses
        // through the allow + transferFrom flow.

        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        require(_to != address(0));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function getApproved(uint256 tokenId) public view  returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return indexToApproved[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public{
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[ msg.sender][operator] = approved;
        emit ApprovalForAll( msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return (_owns(spender, tokenId) || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }



    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }



    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        uint256 totalcats = totalSupply();
        require(index < totalcats, "ERC721Enumerable: owner index out of bounds");
        uint256 resultCount;
        uint256 catId;
        for (catId = 1; catId <= totalcats; catId++) {
            if (indexToOwner[catId] == owner) {
                if (resultCount == index) {
                    return catId;
                }
                resultCount++;
            }
        }
        return catId;
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _createCat(uint8 _catType, uint64 _indexOfType, address _to) internal
    returns (uint)
    {
        Cat memory _cat =Cat({
        catType: _catType,
        indexOfType: _indexOfType,
        birth: uint64(block.timestamp)
        });

        uint256 newIndex = cats.length;
        cats.push(_cat);
        _transfer(address(0), _to, newIndex);
        tokenIdOfTypeIndex[_catType][_indexOfType] = newIndex;
        return newIndex;
    }

    function createCat(string memory _cid)
    external
    returns(uint)
    {
        uint8 index = typeToIndex[_cid];
        require(index != 0);
        CatBase memory _base = catBases[index];
        require(_base.count<_base.totalCount);
        _base.count++;
        catBases[index] = _base;
        uint _index = _createCat(index, _base.count, inheritor);
        return _index;
    }

    function addCatType(string memory _cid, uint64 _count, string memory _name, uint256 _version, string memory _parity, string memory _plat)
    external
    onlyOwner returns(uint256) {
        require(bytes(_cid).length != 0);
        require(typeToIndex[_cid] == 0);
        CatBase memory _base;
        _base.name = _name;
        _base.parity = _parity;
        _base.totalCount=_count;
        _base.version = uint8(_version);
        _base.platform = _plat;
        uint256 index = catBases.length;
        catBases.push(_base);
        typeToIndex[_cid] = uint8(index);
        indexToType[uint8(index)] = _cid;
        return index;
    }

    string public constant name = "CRYPTOTYCOON NFT";
    string public constant symbol = "CTT";
    string public constant baseURI = "https://ipfs.io/ipfs/";

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == _INTERFACE_ID_ERC721_ENUMERABLE)  || (_interfaceID == _INTERFACE_ID_ERC721)  || (_interfaceID == _INTERFACE_ID_ERC721_METADATA));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI(uint256 _tokenId) external view override
    returns (string memory){
        Cat storage cat =cats[_tokenId];
        // CatBase storage _base=catBases[cat.catType];
        string memory cid = indexToType[cat.catType];
        // bytes memory b = new bytes(8);
        // assembly { mstore(add(b, 8), cat.indexOfType) }
        return string(abi.encodePacked(baseURI, cid, "/", toString(uint256(cat.indexOfType)), ".json"));
    }


    function totalSupply() public view override
    returns (uint) {
        return cats.length - 1;
    }

    function ownerOf(uint256 _tokenId)
    external
    view override
    returns (address owner)
    {
        owner = indexToOwner[_tokenId];

        require(owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) external override {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        emit Approval(msg.sender, _to, _tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalcats = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 catId;

            for (catId = 1; catId <= totalcats; catId++) {
                if (indexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return indexToOwner[tokenId] != address(0);
    }

    function _initCats() internal {
        _initCatBase("Ragdoll", 500, "QmRFPfpjFxKhL5bHJLp6CbSpsEcU8jGSyyC35fJQvhPyvL", "SSR");
        _initCatBase("American Shorthair", 4500, "QmdGYVdRBJZzLmVXRLx41N9uuRtvLf6RcknjRu28J4owaC", "SR");
         _initCatBase("British Shorthair", 4500, "QmQHpeJZXzfdz2eKWUWRbjVSGntYBW6ttgjjr9yxtg513M", "SR");
         _initCatBase("Soccer Cat", 500, "QmfLkCbCWv9YndNkXVVcBUBQmmL7jJB4fU29fdnwis8qVK", "R");
         _initCatBase("Legendary Rod", 5, "QmWpr6FBZiCQ7gySBDqUUEUnkWXaw7eWDHHk7CoRvWCPBH", "SSR");
         _initCatBase("Precious Rod", 20, "QmWbjyYwebeQZfyM834MjAZUjWXiaHkHHoC9aKd5s1CcQQ", "SR");
    }

    function _initCatBase(string memory _name, uint64 _count, string memory _cid, string memory _parity) internal{
        CatBase memory _base = CatBase({
        count: 0,
        version:1,
        parity:_parity,
        platform:"CryptoTycoon",
        totalCount:_count,
        name: _name
        });
        uint256 index = catBases.length;
        catBases.push(_base);
        typeToIndex[_cid] = uint8(index);
        indexToType[uint8(index)] = _cid;
    }

    function createMultiCats(string memory _cid, uint256 _count)
    external
    onlyOwner {
        uint8 index = typeToIndex[_cid];
        require(index != 0);
        CatBase memory _base = catBases[index];
        require(_base.count+_count<=_base.totalCount);
        uint64 _initCount = _base.count;
        _base.count =_initCount+uint64(_count);
        catBases[index] = _base;
        for( uint64 i=0; i<_count; i++) {
            _createCat(uint8(index), uint64(_initCount+i+1),inheritor);
        }
    }

    constructor () public {
        indexToType[0]="";
        typeToIndex[""]=0;
        CatBase memory _base;
        _base.count=1;
        _base.totalCount =1;
        // uint256 index = catBases.push(_base)-1;
        catBases.push(_base);
        _createCat(0, 1, address(0));
        _initCats();
    }

    function getCat(uint256 _id)
    external
    view
    returns(string memory cid, uint256 indexOfType, uint256 birth, string memory parity, string memory _name, uint8 version, string memory platform)
    {
        Cat storage cat =cats[_id];
        CatBase storage _base=catBases[cat.catType];
        cid = indexToType[cat.catType];
        birth = uint256(cat.birth);
        _name = _base.name;
        parity = _base.parity;
        version = _base.version;
        platform = _base.platform;
        indexOfType= cat.indexOfType;
    }

    function getCatByTypeIndex(string memory _cid, uint64 _indexOfType)
    external
    view
    returns(uint256 _tokenId, uint256 birth, string memory parity, string memory _name, uint8 version, string memory platform){
        uint8 _type= typeToIndex[_cid];
        _tokenId = tokenIdOfTypeIndex[_type][_indexOfType];
        Cat storage cat =cats[_tokenId];
        CatBase storage _base =catBases[cat.catType];
        birth = uint256(cat.birth);
        _name = _base.name;
        parity = _base.parity;
        version = _base.version;
        platform = _base.platform;
    }

    function getCatTypeInfo(string memory _cid)
    external
    view
    returns(string memory parity, string memory _name, uint8 version, string memory platform, uint256 count, uint256 totalCount){
        uint8 _index = typeToIndex[_cid];
        require(_index < catBases.length);
        CatBase storage _base=catBases[_index];
        _name = _base.name;
        parity = _base.parity;
        version = _base.version;
        platform = _base.platform;
        count = _base.count;
        totalCount = _base.totalCount;
    }

    function getCatTypeCount()
    public view
    returns(uint256){
        return cats.length - 1;
    }
}