pragma solidity ^0.5.12;
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract KittyContract is IERC721 {
    using SafeMath for uint256;

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
        uint16 cooldownIndex;
    }

    Kitty[] internal kitties;
    string _tokenName = "New York Cat Game";
    string _tokenSymbol = "NYCG";

    bytes4 internal constant MAGIC_ERC721_RECEIVED = bytes4(
        keccak256("onERC721Received(address,address,uint256,bytes)")
    );
    bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 _INTERFACE_ID_ERC721 = 0x80ac58cd;

    mapping(uint256 => address) internal kittyToOwner;
    mapping(address => uint256) internal ownerKittyCount;
    mapping(uint256 => address) public kittyToApproved;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() public {
        kitties.push(
            Kitty({
                genes: 0,
                birthTime: 0,
                cooldownEndTime: 0,
                mumId: 0,
                dadId: 0,
                generation: 0,
                cooldownIndex: 0
            })
        );
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool)
    {
        return (_interfaceId == _INTERFACE_ID_ERC165 ||
            _interfaceId == _INTERFACE_ID_ERC721);
    }

    /// @dev throws if @param _address is the zero address
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// @dev throws if @param _kittyId has not been created
    modifier validKittyId(uint256 _kittyId) {
        require(_kittyId < kitties.length, "invalid kittyId");
        _;
    }

    /// @dev throws if msg.sender does not own @param _kittyId
    modifier onlyKittyOwner(uint256 _kittyId) {
        require(isKittyOwner(_kittyId), "sender not kitty owner");
        _;
    }

    /// @dev throws if msg.sender is not the kitty owner,
    /// approved, or an approved operator
    modifier onlyApproved(uint256 _kittyId) {
        require(
            isKittyOwner(_kittyId) ||
                isApproved(_kittyId) ||
                isApprovedOperatorOf(_kittyId),
            "sender not kitty owner OR approved"
        );
        _;
    }

    /**
     * @dev Returns the Kitty for the given kittyId
     */
    function getKitty(uint256 _kittyId)
        external
        view
        returns (
            uint256 kittyId,
            uint256 genes,
            uint64 birthTime,
            uint64 cooldownEndTime,
            uint32 mumId,
            uint32 dadId,
            uint16 generation,
            uint16 cooldownIndex,
            address owner
        )
    {
        Kitty storage kitty = kitties[_kittyId];
        
        kittyId = _kittyId;
        genes = kitty.genes;
        birthTime = kitty.birthTime;
        cooldownEndTime = kitty.cooldownEndTime;
        mumId = kitty.mumId;
        dadId = kitty.dadId;
        generation = kitty.generation;
        cooldownIndex = kitty.cooldownIndex;
        owner = kittyToOwner[_kittyId];
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return ownerKittyCount[owner];
    }

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total) {
        // is the Unkitty considered part of the supply?
        return kitties.length - 1;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName) {
        return _tokenName;
    }

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol) {
        return _tokenSymbol;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId)
        external
        view
        validKittyId(_tokenId)
        returns (address owner)
    {
        return _ownerOf(_tokenId);
    }

    function _ownerOf(uint256 _tokenId) internal view returns (address owner) {
        return kittyToOwner[_tokenId];
    }

    function isKittyOwner(uint256 _kittyId) public view returns (bool) {
        return msg.sender == _ownerOf(_kittyId);
    }

    /** @dev Transfers `tokenId` token from `msg.sender` to `to`.
     *
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` can not be the contract address.
     * - `tokenId` token must be owned by `msg.sender`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _tokenId)
        external
        onlyApproved(_tokenId)
        notZeroAddress(_to)
    {
        require(_to != address(this), "to contract address");

        _transfer(msg.sender, _to, _tokenId);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        // assign new owner
        kittyToOwner[_tokenId] = _to;

        //update token counts
        ownerKittyCount[_to] = ownerKittyCount[_to].add(1);

        if (_from != address(0)) {
            ownerKittyCount[_from] = ownerKittyCount[_from].sub(1);
        }

        // emit Transfer event
        emit Transfer(_from, _to, _tokenId);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external
        onlyApproved(_tokenId)
    {
        kittyToApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function isApproved(uint256 _kittyId) public view returns (bool) {
        return msg.sender == kittyToApproved[_kittyId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
        external
        view
        validKittyId(_tokenId)
        returns (address)
    {
        return kittyToApproved[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _isApprovedForAll(_owner, _operator);
    }

    function _isApprovedForAll(address _owner, address _operator)
        internal
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    /// @return True if msg.sender is the owner, approved,
    /// or an approved operator for the kitty
    /// @param _kittyId id of the kitty
    function isApprovedOperatorOf(uint256 _kittyId) public view returns (bool) {
        return _isApprovedForAll(kittyToOwner[_kittyId], msg.sender);
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        _transfer(_from, _to, _tokenId);
        require(_checkERC721Support(_from, _to, _tokenId, _data));
    }

    function _checkERC721Support(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }

        //call onERC721Recieved in the _to contract
        bytes4 result = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );

        //check return value
        return result == MAGIC_ERC721_RECEIVED;
    }

    function _isContract(address _to) internal view returns (bool) {
        // wallets will not have any code but contract must have some code
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        return size > 0;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyApproved(_tokenId) notZeroAddress(_to) {
        require(_from == _ownerOf(_tokenId), "from address not kitty owner");
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyApproved(_tokenId) notZeroAddress(_to) {
        require(_from == _ownerOf(_tokenId), "from address not kitty owner");
        _safeTransfer(_from, _to, _tokenId, bytes(""));
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyApproved(_tokenId) notZeroAddress(_to) {
        require(
            _from == kittyToOwner[_tokenId],
            "from address not kitty owner"
        );
        _transfer(_from, _to, _tokenId);
    }
}