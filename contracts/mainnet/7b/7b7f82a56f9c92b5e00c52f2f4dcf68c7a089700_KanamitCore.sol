/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract IERC721 {
    // Required methods
    function totalSupply() public view virtual returns (uint256 total);

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);

    function ownerOf(uint256 _tokenId)
        external
        view
        virtual
        returns (address owner);

    function approve(address _to, uint256 _tokenId) external virtual;

    function transfer(address _to, uint256 _tokenId) external virtual;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        virtual
        returns (bool);
}

contract KanamitCore is IERC721, Ownable {
    /*** EVENTS ***/
    event Create(address owner, uint256 AssetId, uint256 hashUri, string uri);
    event Transfer(address from, address to, uint256 tokenId);

    struct Asset {
        uint256 hashUri;
    }

    /*** STORAGE ***/
    Asset[] assets;
    mapping(uint256 => address) private AssetIndexToOwner; // map<assetId , addrOwner>
    mapping(address => uint256) private OwnerAssetCount; // map<addrOwner, uintCount>
    mapping(address => mapping(uint256 => uint256)) private OwnerAssets; // map<addrOwner, map<hashUri, assetId> >
    mapping(uint256 => address) private AssetIndexToApproved; //map<assetId, addrApproved>
    mapping(uint256 => uint256) private mapUriAssetId; //map<hashUri, AssetId>

    constructor() public {
        //初始化第一个元素；addressOwner 为address(0)， uri为空字符""，对应的AssetId为0；
        uint256 hashUri = uint256(keccak256(abi.encodePacked("")));
        Asset memory currAsset = Asset({hashUri: hashUri});
        assets.push(currAsset);
    }

    /// @dev Assigns ownership of a specific Asset to an address.
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        uint256 hashUri = assets[_tokenId].hashUri;
        // Since the number of Assets is capped to 2^32 we can't overflow this
        OwnerAssetCount[_to]++;
        OwnerAssets[_to][hashUri] = _tokenId;
        mapUriAssetId[hashUri] = _tokenId;
        // transfer ownership
        AssetIndexToOwner[_tokenId] = _to;
        // When creating new Assets _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            OwnerAssetCount[_from]--;
            delete OwnerAssets[_from][hashUri];
            // clear any previously approved ownership exchange
            delete AssetIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    function createAsset(address _owner, string memory _uri)
        public
        onlyOwner()
        returns (uint256)
    {
        uint256 hashUri = uint256(keccak256(abi.encodePacked(_uri)));
        uint256 assetId = getAssetId(_uri);
        address currOwner = getUriOwner(_uri);

        require(currOwner == address(0), 'asset already mint, found by owner');
        require(assetId == 0, 'asset already mint, found by assetId');

        Asset memory currAsset = Asset({hashUri: hashUri});
        assets.push(currAsset);
        uint256 newAssetId = assets.length - 1;

        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newAssetId == uint256(uint32(newAssetId)));

        // emit the create event
        Create(_owner, newAssetId, hashUri, _uri);

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), _owner, newAssetId);

        return newAssetId;
    }

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
            bytes4(keccak256("symbol()")) ^
            bytes4(keccak256("totalSupply()")) ^
            bytes4(keccak256("balanceOf(address)")) ^
            bytes4(keccak256("ownerOf(uint256)")) ^
            bytes4(keccak256("approve(address,uint256)")) ^
            bytes4(keccak256("transfer(address,uint256)")) ^
            bytes4(keccak256("transferFrom(address,address,uint256)")) ^
            bytes4(keccak256("tokensOfOwner(address)")) ^
            bytes4(keccak256("tokenMetadata(uint256,string)"));

    function totalSupply() public view virtual override returns (uint256) {
        return assets.length;
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256 count)
    {
        return OwnerAssetCount[_owner];
    }

    function getAssetId(string memory uri)
        public
        view
        returns (uint256 assetId)
    {
        uint256 hashUri = uint256(keccak256(abi.encodePacked(uri)));
        assetId = mapUriAssetId[hashUri];
    }

    function getUriOwner(string memory uri)
        public
        view
        returns (address addressOwner)
    {
        uint256 hashUri = uint256(keccak256(abi.encodePacked(uri)));
        uint256 assetId = mapUriAssetId[hashUri];

        if (assetId == 0) return address(0);

        return AssetIndexToOwner[assetId];
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        virtual
        override
        returns (address owner)
    {
        owner = AssetIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) external virtual override {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) external virtual override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));

        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId), 'only owner can transfer');

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual override {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return AssetIndexToOwner[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        AssetIndexToApproved[_tokenId] = _approved;
    }

    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return AssetIndexToApproved[_tokenId] == _claimant;
    }

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        virtual
        override
        returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) ||
            (_interfaceID == InterfaceSignature_ERC721));
    }

    function getAssetById(uint256 _id) external view returns (uint256 hashUri) {
        Asset storage asset = assets[_id];

        hashUri = asset.hashUri;
    }

    function getAsset(address owner, uint256 hashUri)
        external
        view
        returns (uint256 assetId)
    {
        assetId = OwnerAssets[owner][hashUri];
    }
}