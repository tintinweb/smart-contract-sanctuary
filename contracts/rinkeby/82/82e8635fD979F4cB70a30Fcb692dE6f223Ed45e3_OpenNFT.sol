//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./NftBase.sol";
import "../auctions/IHub.sol";
import "../registry/Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract OpenNFT is  NftBase, Ownable {
    using SafeMath for uint256;
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage for the registry
    Registry internal registryInstance_;

    // Storage for minter role
    struct Minter {
        bool isMinter; // Is this address a minter
        bool isActive; // Is this address an active minter
        bool isDuplicateBatchMinter; // Is this address able to batch mint duplicates
    }
    // Storage for minters
    mapping(address => Minter) internal minters_;

    // -----------------------------------------------------------------------
    // EVENTS
    // -----------------------------------------------------------------------

    event MinterUpdated(
        address minter,
        bool isDuplicateMinter,
        bool isMinter,
        bool isActiveMinter,
        string userIdentifier
    );

    event NewTokensMinted(
        uint256[] tokenIDs, // ID(s) of token(s).
        uint256 batchID, // ID of batch. 0 if not batch
        address indexed creator, // Address of the royalties receiver
        address indexed minter, // Address that minted the tokens
        address indexed receiver, // Address receiving token(s)
        string identifier, // Content ID within the location
        string location, // Where it is stored i.e IPFS, Arweave
        string contentHash // Checksum hash of the content
    );

    event NewTokenMinted(
        // uint256 batchTokenID == 0
        uint256 tokenID,
        address indexed minter,
        address indexed creator,
        address indexed receiver
    );

    event NewBatchTokenMint(
        // uint256 batchTokenID
        uint256[] tokenIDs,
        address indexed minter,
        address indexed creator,
        address indexed receiver
    );

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    modifier onlyMinter() {
        require(
            minters_[msg.sender].isMinter && minters_[msg.sender].isActive,
            "Not active minter"
        );
        _;
    }

    modifier onlyBatchDuplicateMinter() {
        require(
            minters_[msg.sender].isDuplicateBatchMinter,
            "Not active batch copy minter"
        );
        _;
    }

    modifier onlyAuctions() {
        IHub auctionHubInstance_ = IHub(registryInstance_.getHub());

        uint256 auctionID = auctionHubInstance_.getAuctionID(msg.sender);
        require(
            msg.sender == address(auctionHubInstance_) ||
                auctionHubInstance_.isAuctionActive(auctionID),
            "NFT: Not hub or auction"
        );
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(string memory name,
        string memory symbol) NftBase(name, symbol) Ownable() {

        }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter
     */
    function isMinter(address _minter)
        external
        view
        returns (bool isMinter, bool isActiveMinter)
    {
        isMinter = minters_[_minter].isMinter;
        isActiveMinter = minters_[_minter].isActive;
    }

    function isActive() external view returns (bool) {
        return true;
    }

    function isTokenBatch(uint256 _tokenID) external view returns (uint256) {
        return isBatchToken_[_tokenID];
    }

    function getBatchInfo(uint256 _batchID)
        external
        view
        returns (
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        )
    {
        baseTokenID = batchTokens_[_batchID].baseToken;
        tokenIDs = batchTokens_[_batchID].tokenIDs;
        limitedStock = batchTokens_[_batchID].limitedStock;
        totalMinted = batchTokens_[_batchID].totalMinted;
    }

    // -----------------------------------------------------------------------
    //  ONLY AUCTIONS (hub or spokes) STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _to Address of receiver
     * @param   _tokenID Token to transfer
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function transfer(address _to, uint256 _tokenID) external {
        _transfer(_to, _tokenID);
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(address _to, uint256[] memory _tokenIDs)
        external
        onlyAuctions()
    {
        _batchTransfer(_to, _tokenIDs);
    }

    /**
     * @param   from Address being transferee from
     * @param   to Address to transfer to
     * @param   tokenId ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if
     *          _from is _to address.
     */
    function transferFrom(
        address from, address to, uint256 tokenId
    ) public override {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @param   _from Address being transferee from
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if
     *          _from is _to address.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    ) external onlyAuctions() {
        _batchTransferFrom(_from, _to, _tokenIDs);
    }

    // -----------------------------------------------------------------------
    // ONLY MINTER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenCreator Address of the creator. Address will receive the
     *          royalties from sales of the NFT
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @notice  Only valid active minters will be able to mint new tokens
     */
    function mint(
        address _tokenCreator,
        address _mintTo,
        string calldata identifier,
        string calldata location,
        string calldata contentHash
    ) external onlyMinter() returns (uint256) {
        require(_isValidCreator(_tokenCreator), "NFT: Invalid creator");
        // Minting token
        uint256 tokenID = _mint(_mintTo, _tokenCreator, location);
        // Creating temp array for token ID
        uint256[] memory tempTokenIDs = new uint256[](1);
        tempTokenIDs[0] = tokenID;
        {
            // Emitting event
            emit NewTokensMinted(
                tempTokenIDs,
                0,
                _tokenCreator,
                msg.sender,
                _mintTo,
                identifier,
                location,
                contentHash
            );
        }

        return tokenID;
    }

    /**
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @param   _amount Amount of tokens to mint
     * @param   _baseTokenID ID of the token being duplicated
     * @param   _isLimitedStock Bool for if the batch has a pre-set limit
     */
    function batchDuplicateMint(
        address _mintTo,
        uint256 _amount,
        uint256 _baseTokenID,
        bool _isLimitedStock
    ) external onlyBatchDuplicateMinter() returns (uint256[] memory) {
        require(
            tokens_[_baseTokenID].creator != address(0),
            "Mint token before batch"
        );
        uint256 originalBatchID = isBatchToken_[_baseTokenID];
        uint256 batch;
        // Minting tokens
        uint256[] memory tokenIDs;
        (tokenIDs, batch) = _batchMint(
            _mintTo,
            tokens_[_baseTokenID].creator,
            _amount,
            _baseTokenID,
            originalBatchID
        );

        // If this is the first batch mint of the base token
        if (originalBatchID == 0) {
            // Storing batch against base token
            isBatchToken_[_baseTokenID] = batch;
            // Storing all info as a new object
            batchTokens_[batch] = BatchTokens(
                _baseTokenID,
                tokenIDs,
                _isLimitedStock,
                _amount
            );
        } else {
            batch = isBatchToken_[_baseTokenID];
            batchTokens_[batch].totalMinted += _amount;
        }
        // Wrapping for the stack
        {
            // Emitting event
            emit NewTokensMinted(
                tokenIDs,
                batch,
                tokens_[_baseTokenID].creator,
                msg.sender,
                _mintTo,
                "",
                "",
                ""
            );
        }
        return tokenIDs;
    }

    // -----------------------------------------------------------------------
    // ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _minter Address of the minter
     * @param   _hasMinterPermissions If the address has minter permissions. If
     *          false user will not be able to mint, nor will they be able to be
     *          set as the creator of a token
     * @param   _isActiveMinter If the minter is an active minter. If they do
     *          not have minter permissions they will not be able to be assigned
     *          as the creator of a token
     */
    function updateMinter(
        address _minter,
        bool _hasMinterPermissions,
        bool _isActiveMinter,
        string calldata _userIdentifier
    ) external onlyOwner() {
        minters_[_minter].isMinter = _hasMinterPermissions;
        minters_[_minter].isActive = _isActiveMinter;

        emit MinterUpdated(
            _minter,
            false,
            _hasMinterPermissions,
            _isActiveMinter,
            _userIdentifier
        );
    }

    function setDuplicateMinter(address _minter, bool _isDuplicateMinter)
        external
        onlyOwner()
    {
        minters_[_minter].isDuplicateBatchMinter = _isDuplicateMinter;
        minters_[_minter].isMinter = _isDuplicateMinter;
        minters_[_minter].isActive = _isDuplicateMinter;

        emit MinterUpdated(
            _minter,
            _isDuplicateMinter,
            _isDuplicateMinter,
            _isDuplicateMinter,
            "Auction"
        );
    }

    function setRegistry(address _registry) external onlyOwner() {
        require(_registry != address(0), "NFT: cannot set REG to 0x");
        require(
            address(registryInstance_) != _registry,
            "NFT: Cannot set REG to existing"
        );
        registryInstance_ = Registry(_registry);
        require(registryInstance_.isActive(), "NFT: REG instance invalid");
    }

    fallback() external payable {
        revert();
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _creator Address to check
     * @return  bool If the address to check is a valid creator
     * @notice  Will return true if the user is a minter, or is an active minter
     */
    function _isValidCreator(address _creator) internal view returns (bool) {
        if (minters_[_creator].isMinter) {
            return true;
        } else if (minters_[_creator].isMinter && minters_[_creator].isActive) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

contract NftBase is ERC165, IERC721,IERC721Metadata {
    // Libraries 
    using SafeMath for uint256;

    // -----------------------------------------------------------------------
    // STATE 
    // -----------------------------------------------------------------------

    // Counter for minted tokens
    uint256 private totalMinted_;
    // Accurate count of circulating supply (decremented on burns)
    uint256 private circulatingSupply_;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    struct TokenInfo{
        address creator;
        address currentOwner;
        string uri;
    }
    string _name;
    string _symbol; 

    // token ID => Owner 
    mapping(uint256 => TokenInfo) internal tokens_;
    // Owner => Token IDs => is owner
    mapping(address => mapping(uint256 => bool)) internal owners_;
    // Owner => tokens owned counter
    mapping(address => uint256) internal ownerBalances_;
    // Approvals for token spending | owner => spender => token ID => approved
    mapping(address => mapping(address => mapping (uint256 => bool))) internal approvals_;
    // Counter for batch mints
    uint256 internal batchMintCounter_;
    // Storage for batch minted tokens (where they are duplicates)
    struct BatchTokens {
        uint256 baseToken;
        uint256[] tokenIDs;
        bool limitedStock;
        uint256 totalMinted;
    }
    // Storage of Batch IDs to their batch tokens
    mapping(uint256 => BatchTokens) internal batchTokens_;
    // Token ID => their batch number. 0 if they are not batch tokens
    mapping(uint256 => uint256) internal isBatchToken_;


    // -----------------------------------------------------------------------
    // EVENTS 
    // -----------------------------------------------------------------------

    event ApprovalSet(
        address owner,
        address spender,
        uint256 tokenID,
        bool approval
    );

    event BatchTransfer(
        address from,
        address to,
        uint256[] tokenIDs
    );

    // -----------------------------------------------------------------------
    // CONSTRUCTOR 
    // -----------------------------------------------------------------------

    constructor(string memory name,
        string memory symbol) {
            _name = name;
            _symbol = symbol;
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) public override view returns(address) {
        return tokens_[_tokenID].currentOwner;
    }

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address) {
        return tokens_[_tokenID].creator; 
    }

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) public override view returns(uint256) {
        return ownerBalances_[_owner];
    }

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() public  view returns(uint256) {
        return circulatingSupply_;
    } 

    /**
     * @return  uint256 The total number of unique tokens minted
     */
    function totalMintedTokens() external view returns(uint256) {
        return totalMinted_;
    }
   function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    /**
     * @param   _owner Address of the owner
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @return  bool The approved status of the spender against the owner
     */
    function isApprovedSpenderOf(
        address _owner, 
        address _spender, 
        uint256 _tokenID
    )
        external
        view
        returns(bool)
    {
        return approvals_[_owner][_spender][_tokenID];
    }

    /**
     * @param   _tokenId ID of the token to get the URI of
     * @return  string the token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return tokens_[_tokenId].uri;
    }

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @param   _approvalSpender The status of the spenders approval on the 
     *          owner
     * @notice  Will revert if msg.sender is the spender or if the msg.sender
     *          is not the owner of the token.
     */
    function approveSpender(
        address _spender,
        uint256 _tokenID,
        bool _approvalSpender
    )
        external 
    {
        require(
            msg.sender != _spender, 
            "NFT: cannot approve self"
        );
        require(
            tokens_[_tokenID].currentOwner == msg.sender,
            "NFT: Only owner can approve"
        );
        // Set approval status
        approvals_[msg.sender][_spender][_tokenID] = _approvalSpender;

        emit ApprovalSet(
            msg.sender,
            _spender,
            _tokenID,
            _approvalSpender
        );
    }

    // -----------------------------------------------------------------------
    // ERC721 Functions
    // -----------------------------------------------------------------------

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function transferFrom(address from, address to, uint256 tokenId) virtual external override {
         _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);

        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
    }
    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) virtual external override{
         _transferFrom(from, to, tokenId);

    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) virtual external override{
         _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool _approved) virtual external override{
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param    _oldOwner Address of the old owner losing the token
     * @param   _newOwner Address of the new owner gaining the token
     * @param   _tokenID ID of the token getting transferred
     */
    function _changeOwner(
        address _oldOwner,
        address _newOwner,
        uint256 _tokenID
    )
        internal
    {
        // Changing the tokens owner to the new owner
        tokens_[_tokenID].currentOwner = _newOwner;
        // Removing the token from the old owner
        owners_[_oldOwner][_tokenID] = false;
        // Reducing the old owners token count
        ownerBalances_[_oldOwner] = ownerBalances_[_oldOwner].sub(1);
        // Adding the token to the new owner
        owners_[_newOwner][_tokenID] = true;
        // Increasing the new owners token count
        ownerBalances_[_newOwner] = ownerBalances_[_newOwner].add(1);
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenID Token being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function _transfer(
        address _to,
        uint256 _tokenID
    )
        internal 
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            tokens_[_tokenID].currentOwner == msg.sender,
            "NFT: Only owner can transfer"
        );
        require(
            _to != msg.sender,
            "NFT: Cannot transfer to self"
        );
        // Updating storage to reflect transfer
        _changeOwner(
            msg.sender,
            _to,
            _tokenID
        );
        emit Transfer(
            msg.sender,
            _to,
            _tokenID
        );
    }

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function _batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            _to != msg.sender,
            "NFT: Cannot transfer to self"
        );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                tokens_[_tokenIDs[i]].currentOwner == msg.sender,
                "NFT: Only owner can transfer"
            );
            // Updating storage to reflect transfer
            _changeOwner(
                msg.sender,
                _to,
                _tokenIDs[i]
            );
        }

        emit BatchTransfer(
            msg.sender,
            _to,
            _tokenIDs
        );
    }

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            approvals_[_from][msg.sender][_tokenID],
            "NFT: Caller not approved"
        );
        require(
            tokens_[_tokenID].currentOwner == _from,
            "NFT: From is not token owner"
        );
        require(
            _to != _from,
            "NFT: Cannot transfer to self"
        );
        // Removing spender as approved spender of token on owner
        approvals_[_from][msg.sender][_tokenID] = false;
        // Updating storage to reflect transfer
        _changeOwner(
            _from,
            _to,
            _tokenID
        );

        emit Transfer(
            _from,
            _to,
            _tokenID
        );
    }

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function _batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        internal
    {
        require(_to != address(0), "NFT: Cannot send to zero address");
        require(
            _to != _from,
            "NFT: Cannot transfer to self"
        );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(
                approvals_[_from][msg.sender][_tokenIDs[i]],
                "NFT: Caller not approved"
            );
            // Removing spender as approved spender of token on owner
            approvals_[_from][msg.sender][_tokenIDs[i]] = false;
            require(
                tokens_[_tokenIDs[i]].currentOwner == _from,
                "NFT: From is not token owner"
            );
            // Updating storage to reflect transfer
            _changeOwner(
                _from,
                _to,
                _tokenIDs[i]
            );
        }
        
        emit BatchTransfer(
            _from,
            _to,
            _tokenIDs
        );
    }

    /**
     * @param   _owner Address of the owner of the newly created token
     * @param   _tokenID Token ID of the new token created
     */
    function _createToken(
        address _owner,
        address _creator,
        uint256 _tokenID,
        string memory _uri
    )
        internal
    {
        // Setting the creator
        tokens_[_tokenID].creator = _creator;
        // Adding the tokens owner
        tokens_[_tokenID].currentOwner = _owner;
        // Adding the URI for the token
        tokens_[_tokenID].uri = _uri;
        // Adding the token to the owner
        owners_[_owner][_tokenID] = true;
        // Increasing the owners token count
        ownerBalances_[_owner] = ownerBalances_[_owner].add(1);
    }

    /**
     * @param   _to Address receiving the newly minted token
     * @return  uint256 The ID of the new token created
     * @notice  Will revert if _to is the 0x address
     */
    function _mint(address _to, address _creator, string memory _uri) internal returns(uint256) {
        require(_to != address(0), "NFT: Cannot mint to zero address");
        // Incrementing token trackers
        totalMinted_ = totalMinted_.add(1);
        circulatingSupply_ = circulatingSupply_.add(1);

        uint256 tokenID = totalMinted_;
        // Updating the state with the new token
        _createToken(
            _to,
            _creator,
            tokenID,
            _uri
        );

        emit Transfer(
            address(0),
            _to,
            tokenID
        );

        return tokenID;
    }

     /**
     * @param   _to Address receiving the newly minted tokens
     * @param   _amount The amount of tokens to mint
     * @return  uint256[] The IDs of the new tokens created
     * @notice  Will revert if _to is the 0x address
     */
    function _batchMint(
        address _to, 
        address _creator,
        uint256 _amount,
        uint256 _originalTokenID,
        uint256 _batchID
    ) 
        internal 
        returns(uint256[] memory, uint256) 
    {
        require(_to != address(0), "NFT: Cannot mint to zero address");

        uint256[] memory tokenIDs = new uint256[](_amount);

        string memory uri = this.tokenURI(_originalTokenID);

        uint256 batch;

        if(_batchID == 0) {
            batchMintCounter_ += 1;
            batch = batchMintCounter_;
        }

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, _creator, uri);
            tokenIDs[i] = totalMinted_;
            batchTokens_[batch].tokenIDs.push(totalMinted_);
        }

        emit BatchTransfer(
            address(0),
            _to,
            tokenIDs
        );

        return (tokenIDs, batch);
    }

    /**
     * @param   _owner Address of the owner 
     * @param   _tokenID Token ID of the token being destroyed
     */
    function _destroyToken(
        address _owner,
        uint256 _tokenID
    )
        internal
    {
        // Reducing circulating supply. 
        circulatingSupply_ = circulatingSupply_.sub(1);
        // Removing the tokens owner
        tokens_[_tokenID].currentOwner = address(0);
        // Remove the tokens creator
        tokens_[_tokenID].creator = address(0);
        // Removing the token from the owner
        owners_[_owner][_tokenID] = false;
        // Decreasing the owners token count
        ownerBalances_[_owner] = ownerBalances_[_owner].sub(1);
    }

    /**
     * @param   _from Address that was the last owner of the token
     * @param   _tokenID Token ID of the token being burnt
     */
    function _burn(address _from, uint256 _tokenID) internal {
        require(_from != address(0), "NFT: Cannot burn from zero address");

        _destroyToken(
            _from,
            _tokenID
        );

        emit Transfer(
            _from,
            address(0),
            _tokenID
        );
    }

    /**
     * @param   _from Address that was the last owner of the token
     * @param   _tokenIDs Array of the token IDs being burnt
     */
    function _batchBurn(address _from, uint256[] memory _tokenIDs) internal {
        require(_from != address(0), "NFT: Cannot burn from zero address");

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _destroyToken(
                _from,
                _tokenIDs[i]
            );
        }

        emit BatchTransfer(
            _from,
            address(0),
            _tokenIDs
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokens_[tokenId].currentOwner != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IHub {
    enum LotStatus {
        NO_LOT,
        LOT_REQUESTED,
        LOT_CREATED,
        AUCTION_ACTIVE,
        AUCTION_RESOLVED,
        AUCTION_RESOLVED_AND_CLAIMED,
        AUCTION_CANCELED
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getLotInformation(uint256 _lotID)
        external
        view
        returns (
            address owner,
            uint256 tokenID,
            uint256 auctionID,
            LotStatus status
        );

    function getAuctionInformation(uint256 _auctionID)
        external
        view
        returns (
            bool active,
            string memory auctionName,
            address auctionContract,
            bool onlyPrimarySales
        );

    function getAuctionID(address _auction) external view returns (uint256);

    function isAuctionActive(uint256 _auctionID) external view returns (bool);

    function getAuctionCount() external view returns (uint256);

    function isAuctionHubImplementation() external view returns (bool);

    function isFirstSale(uint256 _tokenID) external view returns (bool);

    function getFirstSaleSplit()
        external
        view
        returns (uint256 creatorSplit, uint256 systemSplit);

    function getSecondarySaleSplits()
        external
        view
        returns (
            uint256 creatorSplit,
            uint256 sellerSplit,
            uint256 systemSplit
        );

    function getScalingFactor() external view returns (uint256);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function requestAuctionLot(uint256 _auctionType, uint256 _tokenID)
        external
        returns (uint256 lotID);

    // -----------------------------------------------------------------------
    // ONLY AUCTIONS STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function firstSaleCompleted(uint256 _tokenID) external;

    function lotCreated(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionStarted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompleted(uint256 _auctionID, uint256 _lotID) external;

    function lotAuctionCompletedAndClaimed(uint256 _auctionID, uint256 _lotID)
        external;

    function cancelLot(uint256 _auctionID, uint256 _lotID) external;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
// Registry managed contracts
import "../auctions/IHub.sol";
import "../royalties/IRoyalties.sol";
import "../nft/INft.sol";

contract Registry is Ownable {
    // -----------------------------------------------------------------------
    // STATE
    // -----------------------------------------------------------------------

    // Storage of current hub instance
    IHub internal hubInstance_;
    // Storage of current royalties instance
    IRoyalties internal royaltiesInstance_;
    // Storage of NFT contract (cannot be changed)
    INft internal nftInstance_;

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _nft) Ownable() {
        require(INft(_nft).isActive(), "REG: Address invalid NFT");
        nftInstance_ = INft(_nft);
    }

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getHub() external view returns (address) {
        return address(hubInstance_);
    }

    function getRoyalties() external view returns (address) {
        return address(royaltiesInstance_);
    }

    function getNft() external view returns (address) {
        return address(nftInstance_);
    }

    function isActive() external view returns (bool) {
        return true;
    }

    // -----------------------------------------------------------------------
    //  ONLY OWNER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function updateHub(address _newHub) external onlyOwner {
        IHub newHub = IHub(_newHub);
        require(_newHub != address(0), "REG: cannot set HUB to 0x");
        require(
            address(hubInstance_) != _newHub,
            "REG: Cannot set HUB to existing"
        );
        require(
            newHub.isAuctionHubImplementation(),
            "REG: HUB implementation error"
        );
        require(IHub(_newHub).init(), "REG: HUB could not be init");
        hubInstance_ = IHub(_newHub);
    }

    function updateRoyalties(address _newRoyalties) external onlyOwner {
        require(_newRoyalties != address(0), "REG: cannot set ROY to 0x");
        require(
            address(royaltiesInstance_) != _newRoyalties,
            "REG: Cannot set ROY to existing"
        );
        require(IRoyalties(_newRoyalties).init(), "REG: ROY could not be init");
        royaltiesInstance_ = IRoyalties(_newRoyalties);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyalties {
    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    function getBalance(address _user) external view returns (uint256);

    function getCollateral() external view returns (address);

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function deposit(address _to, uint256 _amount) external payable;

    function withdraw(uint256 _amount) external payable;

    // -----------------------------------------------------------------------
    // ONLY REGISTRY STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function init() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface INft {

    // -----------------------------------------------------------------------
    // NON-MODIFYING FUNCTIONS (VIEW)
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the owner for this token  
     */
    function ownerOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _tokenID The ID of the token
     * @return  address of the creator of the token
     */
    function creatorOf(uint256 _tokenID) external view returns(address);

    /**
     * @param   _owner The address of the address to check
     * @return  uint256 The number of tokens the user owns
     */
    function balanceOf(address _owner) external view returns(uint256);

    /**
     * @return  uint256 The total number of circulating tokens
     */
    function totalSupply() external view returns(uint256);

    /**
     * @param   _owner Address of the owner
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @return  bool The approved status of the spender against the owner
     */
    function isApprovedSpenderOf(
        address _owner, 
        address _spender, 
        uint256 _tokenID
    )
        external
        view
        returns(bool);

    /**
     * @param   _minter Address of the minter being checked
     * @return  isMinter If the minter has the minter role
     * @return  isActiveMinter If the minter is an active minter 
     */
    function isMinter(
        address _minter
    ) 
        external 
        view 
        returns(
            bool isMinter, 
            bool isActiveMinter
        );

    function isActive() external view returns(bool);

    function isTokenBatch(uint256 _tokenID) external view returns(uint256);

    function getBatchInfo(
        uint256 _batchID
    ) 
        external 
        view
        returns(
            uint256 baseTokenID,
            uint256[] memory tokenIDs,
            bool limitedStock,
            uint256 totalMinted
        );

    // -----------------------------------------------------------------------
    // PUBLIC STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _spender The address of the spender
     * @param   _tokenID ID of the token to check
     * @param   _approvalSpender The status of the spenders approval on the 
     *          owner
     * @notice  Will revert if msg.sender is the spender or if the msg.sender
     *          is not the owner of the token.
     */
    function approveSpender(
        address _spender,
        uint256 _tokenID,
        bool _approvalSpender
    )
        external;

    // -----------------------------------------------------------------------
    //  ONLY AUCTIONS (hub or spokes) STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _to Address of receiver 
     * @param   _tokenID Token to transfer
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function transfer(
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if the 
     *          msg.sender is not the token owner. Will revert if msg.sender is
     *          to to address
     */
    function batchTransfer(
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenID ID of token being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    )
        external;

    /**
     * @param   _from Address being transferee from 
     * @param   _to Address to transfer to
     * @param   _tokenIDs Array of tokens being transferred
     * @notice  Only auctions (hub or spokes) will be able to transfer tokens.
     *          Will revert if to address is the 0x address. Will revert if
     *          msg.sender is not approved spender of token on _from address.
     *          Will revert if the _from is not the token owner. Will revert if 
     *          _from is _to address.
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIDs
    )
        external;

    // -----------------------------------------------------------------------
    // ONLY MINTER STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _tokenCreator Address of the creator. Address will receive the 
     *          royalties from sales of the NFT
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @notice  Only valid active minters will be able to mint new tokens
     */
    function mint(
        address _tokenCreator, 
        address _mintTo,
        string calldata identifier,      
        string calldata location,
        bytes32 contentHash 
    ) external returns(uint256);

    /**
     * @param   _mintTo The address that should receive the token. Note that on
     *          the initial sale this address will not receive the sale 
     *          collateral. Sale collateral will be distributed to creator and
     *          system fees
     * @param   _amount Amount of tokens to mint
     * @param   _baseTokenID ID of the token being duplicated
     * @param   _isLimitedStock Bool for if the batch has a pre-set limit
     */
    function batchDuplicateMint(
        address _mintTo,
        uint256 _amount,
        uint256 _baseTokenID,
        bool _isLimitedStock
    )
        external
        returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}