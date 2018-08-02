pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
} 

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address _oldOwner,
        uint256 _tokenId,
        bytes   _userData
    ) external returns (bytes4);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }
}

contract ERC721Base {
    using SafeMath for uint256;

    uint256 private _count;

    mapping(uint256 => address) private _holderOf;
    mapping(address => uint256[]) private _assetsOf;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(uint256 => address) private _approval;
    mapping(uint256 => uint256) private _indexOfAsset;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //
    // Global Getters
    //

    /**
     * @dev Gets the total amount of assets stored by the contract
     * @return uint256 representing the total amount of assets
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }
    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

    //
    // Asset-centric getter functions
    //

    /**
     * @dev Queries what address owns an asset. This method does not throw.
     * In order to check if the asset exists, use the `exists` function or check if the
     * return value of this call is `0`.
     * @return uint256 the assetId
     */
    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }
    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

    function assetsOf(address owner) external view returns (uint256[]) {
        return _assetsOf[owner];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        return _assetsOf[_owner][_index];
    }

    //
    // Holder-centric getter functions
    //
    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }
    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

    //
    // Authorization getters
    //

    /**
     * @dev Query whether an address has been authorized to move any assets on behalf of someone else
     * @param operator the address that might be authorized
     * @param assetHolder the address that provided the authorization
     * @return bool true if the operator has been authorized to move any assets
     */
    function isApprovedForAll(address operator, address assetHolder)
        external view returns (bool)
    {
        return _isApprovedForAll(operator, assetHolder);
    }
    function _isApprovedForAll(address operator, address assetHolder)
        internal view returns (bool)
    {
        return _operators[assetHolder][operator];
    }

    /**
     * @dev Query what address has been particularly authorized to move an asset
     * @param assetId the asset to be queried for
     * @return bool true if the asset has been approved by the holder
     */
    function getApprovedAddress(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }
    function _getApprovedAddress(uint256 assetId) internal view returns (address) {
        return _approval[assetId];
    }

    /**
     * @dev Query if an operator can move an asset.
     * @param operator the address that might be authorized
     * @param assetId the asset that has been `approved` for transfer
     * @return bool true if the asset has been approved by the holder
     */
    function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
        return _isAuthorized(operator, assetId);
    }
    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool){
        require(operator != 0);
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return _isApprovedForAll(operator, owner) || _getApprovedAddress(assetId) == operator;
    }

    //
    // Authorization
    //

    /**
     * @dev Authorize a third party operator to manage (send) msg.sender&#39;s asset
     * @param operator address to be approved
     * @param authorized bool set to true to authorize, false to withdraw authorization
     */
    function setApprovalForAll(address operator, bool authorized) external returns (bool) {
        return _setApprovalForAll(operator, authorized);
    }

    function _setApprovalForAll(address operator, bool authorized) internal returns (bool) {
        if (authorized) {
            require(!_isApprovedForAll(operator, msg.sender));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(operator, msg.sender));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(operator, msg.sender, authorized);
        return true;
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    /**
     * @dev Authorize a third party operator to manage one particular asset
     * @param operator address to be approved
     * @param assetId asset to approve
     */
    function approve(address operator, uint256 assetId) external returns (bool) {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder));
        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
        return true;
    }

    //
    // Internal Operations
    //

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

        // Insert the last asset into the position previously occupied by the asset to be removed
        _assetsOf[from][assetIndex] = lastAssetId;

        // Resize the array
        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

        // Remove the array if no more assets are owned to prevent pollution
        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

        // Update the index of positions for the asset
        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }

    //
    // Supply-altering functions
    //

    function _generate(uint256 assetId, address beneficiary) internal {
        require(_holderOf[assetId] == 0);

        _addAssetTo(beneficiary, assetId);

        emit Transfer(0x0, beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != 0);

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, 0x0, assetId);
    }

    //
    // Transaction related operations
    //

    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender);
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId));
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from);
        _;
    }

    /**
     * @dev Alias of `safeTransferFrom(from, to, assetId, &#39;&#39;)`
     *
     * @param from address that currently owns an asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 assetId) external returns (bool) {
        return _doTransferFrom(from, to, assetId, &quot;&quot;, true);
    }

    /**
     * @dev Securely transfers the ownership of a given asset from one address to
     * another address, calling the method `onNFTReceived` on the target address if
     * there&#39;s code associated with it
     *
     * @param from address that currently owns an asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     * @param userData bytes arbitrary user information to attach to this transfer
     */
    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external returns (bool) {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

    /**
     * @dev Transfers the ownership of a given asset from one address to another address
     * Warning! This function does not attempt to verify that the target address can send
     * tokens.
     *
     * @param from address sending the asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     */
    function transferFrom(address from, address to, uint256 assetId) external returns (bool) {
        return _doTransferFrom(from, to, assetId, &quot;&quot;, false);
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        onlyAuthorized(assetId)
        internal
        returns (bool)
    {
        _moveToken(from, to, assetId, userData, doCheck);
        return true;
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        isCurrentOwner(from, assetId)
        internal
    {
        address holder = _holderOf[assetId];
        _removeAssetFrom(holder, assetId);
        _clearApproval(holder, assetId);
        _addAssetTo(to, assetId);

        if (doCheck && _isContract(to)) {
            // Equals to bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))
            bytes4 ERC721_RECEIVED = bytes4(0xf0b9e5ba);
            require(
                IERC721Receiver(to).onERC721Received(
                    holder, assetId, userData
                ) == ERC721_RECEIVED
            );
        }

        emit Transfer(holder, to, assetId);
    }

    /**
     * Internal function that moves an asset from one holder to another
     */

    /**
     * @dev Returns `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
     * @param    _interfaceID The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {

        if (_interfaceID == 0xffffffff) {
            return false;
        }
        return _interfaceID == 0x01ffc9a7 || _interfaceID == 0x80ac58cd;
    }

    //
    // Utilities
    //

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


interface ERC721 {
    function transferFrom(address from, address to, uint256 id) external;
    function ownerOf(uint256 id) external view returns (address);
}

contract Bundle is ERC721Base, BytesUtils {
    uint256 private constant MAX_UINT256 = uint256(0) - uint256(1);

    Package[] private packages;

    event Created(address owner, uint256 id);
    event Deposit(address sender, uint256 bundle, address token, uint256 id);
    event Withdraw(address retriever, uint256 bundle, address token, uint256 id);

    struct Package {
        address[] tokens;
        uint256[] ids;
        mapping(address => mapping(uint256 => uint256)) order;
    }

    constructor() public {
        packages.length++;
    }

    modifier canWithdraw(uint256 packageId) {
        require(_isAuthorized(msg.sender, packageId), &quot;Not authorized for withdraw&quot;);
        _;
    }

    function canDeposit(uint256 packageId) public view returns (bool) {
        return _isAuthorized(msg.sender, packageId);
    }

    /**
        @notice Get the content of a package
    */
    function content(uint256 id) external view returns (address[] tokens, uint256[] ids) {
        Package memory package = packages[id];
        tokens = package.tokens;
        ids = package.ids;
    }

    // create package
    /**
    @notice Create a empty Package in packages array
    */
    function create() public returns (uint256 id) {
        id = packages.length;
        packages.length++;
        emit Created(msg.sender, id);
        _generate(id, msg.sender);
    }

    /**
        @notice Deposit a non fungible token on a package

        @param _packageId Index of package in packages array
        @param token Token address (ERC721)
        @param tokenId Token identifier

        @return true If the operation was executed
    */
    function deposit(
        uint256 _packageId,
        ERC721 token,
        uint256 tokenId
    ) external returns (bool) {
        uint256 packageId = _packageId == 0 ? create() : _packageId;
        require(canDeposit(packageId), &quot;Not authorized for deposit&quot;);
        return _deposit(packageId, token, tokenId);
    }

    /**
        @notice Deposit a batch of non fungible tokens on a package

        @dev The length of tokens and ids should be equal

        @param _packageId Index of package in packages array
        @param tokens Token addresses (ERC721) array
        @param ids Token identifiers array

        @return true If the operation was executed
    */
    function depositBatch(
        uint256 _packageId,
        ERC721[] tokens,
        uint256[] ids
    ) external returns (bool) {
        uint256 packageId = _packageId == 0 ? create() : _packageId;
        require(canDeposit(packageId), &quot;Not authorized for deposit&quot;);

        require(tokens.length == ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(_deposit(packageId, tokens[i], ids[i]));
        }

        return true;
    }

    /**
        @notice Withdraw a non fungible token from a packag

        @param packageId Index of package in packages array
        @param token Token address (ERC721)
        @param tokenId Token identifier
        @param to address beneficiary

        @return true If the operation was executed
    */
    function withdraw(
        uint256 packageId,
        ERC721 token,
        uint256 tokenId,
        address to
    ) public canWithdraw(packageId) returns (bool) {
        return _withdraw(packageId, token, tokenId, to);
    }

    /**
        @notice Withdraw a batch of non fungible tokens from a package

        @dev The length of tokens and ids should be equal

        @param packageId Index of package in packages array
        @param tokens Token addresses (ERC721) array
        @param ids Token identifiers array
        @param to address beneficiary

        @return true If the operation was executed
    */
    function withdrawBatch(
        uint256 packageId,
        ERC721[] tokens,
        uint256[] ids,
        address to
    ) external canWithdraw(packageId) returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(_withdraw(packageId, tokens[i], ids[i], to));
        }

        return true;
    }

    /**
        @notice Withdraw all non fungible tokens from a package

        @param packageId Index of package in packages array
        @param to address beneficiary

        @return true If the operation was executed
    */
    function withdrawAll(
        uint256 packageId,
        address to
    ) external canWithdraw(packageId) returns (bool) {
        Package storage package = packages[packageId];
        uint256 i = package.ids.length - 1;

        for (;i != MAX_UINT256; i--) {
            require(_withdraw(packageId, ERC721(package.tokens[i]), package.ids[i], to));
        }

        return true;
    }

    //
    // Internal functions
    //

    function _deposit(
        uint256 packageId,
        ERC721 token,
        uint256 tokenId
    ) internal returns (bool) {
        token.transferFrom(msg.sender, address(this), tokenId);
        require(token.ownerOf(tokenId) == address(this), &quot;ERC721 transfer failed&quot;);

        Package storage package = packages[packageId];
        _add(package, token, tokenId);

        emit Deposit(msg.sender, packageId, token, tokenId);

        return true;
    }

    function _withdraw(
        uint256 packageId,
        ERC721 token,
        uint256 tokenId,
        address to
    ) internal returns (bool) {
        Package storage package = packages[packageId];
        _remove(package, token, tokenId);
        emit Withdraw(msg.sender, packageId, token, tokenId);

        token.transferFrom(this, to, tokenId);
        require(token.ownerOf(tokenId) == to, &quot;ERC721 transfer failed&quot;);

        return true;
    }

    function _add(
        Package storage package,
        ERC721 token,
        uint256 id
    ) internal {
        uint256 position = package.order[token][id];
        require(!_isAsset(package, position, token, id), &quot;Already exist&quot;);
        position = package.tokens.length;
        package.tokens.push(token);
        package.ids.push(id);
        package.order[token][id] = position;
    }

    function _remove(
        Package storage package,
        ERC721 token,
        uint256 id
    ) internal {
        uint256 delPosition = package.order[token][id];
        require(_isAsset(package, delPosition, token, id), &quot;The token does not exist inside the package&quot;);

        // Replace item to remove with last item
        // (make the item to remove the last one)
        uint256 lastPosition = package.tokens.length - 1;
        if (lastPosition != delPosition) {
            address lastToken = package.tokens[lastPosition];
            uint256 lastId = package.ids[lastPosition];
            package.tokens[delPosition] = lastToken;
            package.ids[delPosition] = lastId;
            package.order[lastToken][lastId] = delPosition;
        }

        // Remove last position
        package.tokens.length--;
        package.ids.length--;
        delete package.order[token][id];
    }

    function _isAsset(
        Package memory package,
        uint256 position,
        address token,
        uint256 id
    ) internal pure returns (bool) {
        return position != 0 ||
            (package.ids.length != 0 && package.tokens[position] == token && package.ids[position] == id);
    }
}