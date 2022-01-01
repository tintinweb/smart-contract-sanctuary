/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

//SPDX-License-Identifier: MIT License

pragma solidity ^0.8.0;

contract AccessControl {
    address public owner;
    uint16 public totalStaff = 0;

    mapping(address => bool) public staff;

    modifier onlyOwner() {
        require(msg.sender == owner, 'You are not the owner');
        _;
    }

    modifier onlyStaff() {
        require(
            staff[msg.sender] == true || msg.sender == owner,
            'Only the owner or designated staff may do this'
        );
        _;
    }

    // The owner is the one who deployed the contract
    constructor() {
        owner = msg.sender;
    }

    // The owner may add or remove staff members
    function addStaff(address _newStaff) public onlyOwner {
        if (staff[_newStaff] == false) {
            staff[_newStaff] = true;
            totalStaff += 1;
           }
    }

    function removeStaff(address _oldStaff) public onlyOwner {
        if (staff[_oldStaff] == true) {
            staff[_oldStaff] = false;
            totalStaff -= 1;
        }
    }

    // The owner may also give ownership to someone else
    function changeOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
abstract contract IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);

    function approve(address to, uint256 tokenId) public virtual;

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is IERC721, AccessControl {
    
    uint256 public totalTokens;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string _name = 'My NFT';
    string _symbol = 'NFT';

    // Mapping storing a badge type for each token id
    mapping(uint256 => uint16) public BadgeTypes;
    uint16 public numBadgeTypes = 0;

    // Mapping storing a metadate uri for each badge type
    mapping(uint16 => string) public MetadataAddresses;

    constructor() {}

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'The owner cannot be the 0 address');
        return _ownedTokensCount[owner];
    }

    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), 'The owner cannot be the 0 address');
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, 'Owner cannot approve tokens to itself');
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            'Only the owner of approved addresses can approve'
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return MetadataAddresses[BadgeTypes[tokenId]];
    }

 
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory) {
        return _name;
    }

    function setName(string memory newName) external onlyOwner {
        _name = newName;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function setSymbol(string memory newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }


    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(_exists(tokenId), 'This token id does not exist');
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, 'Cannot approve to yourself');
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'Not approved or owner'
        );

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function addBadgeType(string memory ipfsHash) public onlyStaff {
        MetadataAddresses[numBadgeTypes] = ipfsHash;
        numBadgeTypes += 1;
    }

    function changeBadgeType(string memory ipfsHash, uint16 index) public onlyStaff {
        MetadataAddresses[index] = ipfsHash;
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'Cannot mint to 0 address');
        require(!_exists(tokenId), 'Token Id already exists');

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    // Mint a new token for an owner. 
    // badge type should have been defined previously, this is a link
    // to the metadata uri. 
    function mintToken(
        address owner,
        uint16 badgeType
    ) public onlyStaff {
        BadgeTypes[totalTokens] = badgeType;
        _mint(owner, totalTokens);
        totalTokens = totalTokens + 1;
    }

    /**
     * @dev external function to burn a specific token
     * Reverts if the token does not exist
     * @param tokenId uint256 ID of the token being burned
     * Only the owner can burn their token.
     */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, 'Only the owner can burn');
        _clearApproval(tokenId);
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender] -= 1;
        _tokenOwner[tokenId] = address(0);
        emit Transfer(msg.sender, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, 'Only the owner can burn');

        _clearApproval(tokenId);

        _ownedTokensCount[owner] = _ownedTokensCount[owner] -= 1;
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, 'From must be the token owner');
        require(to != address(0), 'Cannot transfer to 0 address.');

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from] -= 1;
        _ownedTokensCount[to] = _ownedTokensCount[to] += 1;

        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}