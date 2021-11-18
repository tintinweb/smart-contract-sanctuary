// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./FarbeArtV3Upgradeable.sol";
import "./FixedPriceV3Upgradeable.sol";
import "./OpenOffersV3Upgradeable.sol";
import "./AuctionV3Upgradeable.sol";


contract FarbeMarketplaceV3Upgradeable is FixedPriceSaleV3Upgradeable, AuctionSaleV3Upgradeable, OpenOffersSaleV3Upgradeable, PausableUpgradeable {
    bool public isFarbeMarketplace;

    // Add the library methods
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    
    mapping(address => EnumerableMap.UintToAddressMap) institutionToTokenCollection;
    
    struct tokenDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isInstitution;
    }

    event AssignedToInstitution(address institutionAddress, uint256 tokenId, address owner);
    event TakeBackFromInstitution(uint256 tokenId, address institution,address owner);

    // platform cut on primary sales in %age * 10
    uint16 public platformCutOnPrimarySales;
    
    function initialize(address _nftAddress, address _platformAddress, uint16 _platformCut) public initializer {
        // check NFT contract supports ERC721 interface
        FarbeArtSaleV3Upgradeable candidateContract = FarbeArtSaleV3Upgradeable(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __PullPayment_init();
        __Pausable_init();
        NFTContract = candidateContract;
        platformCutOnPrimarySales = _platformCut;
        platformWalletAddress = _platformAddress;
    }

    /**
     * @dev Puclic function(only admin authorized) to pause the contract
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Puclic function(only admin authorized) to unpause the contract
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev This function is reponsible to set platformCut
     * @param _platformCut cut to set
     */
    function setPlatformCut(uint16 _platformCut) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformCutOnPrimarySales = _platformCut;
    }

    /**
     * @dev Make sure the starting time is not greater than 60 days
     * @param _startingTime starting time of the sale in UNIX timestamp
     */
    modifier onlyValidStartingTime(uint64 _startingTime) {
        if(_startingTime > block.timestamp) {
            require(_startingTime - block.timestamp <= 60 days, "Start time too far");
        }
        _;
    }
    
    modifier onlyFarbeContract() {
        // check the caller is the FarbeNFT contract
        require(msg.sender == address(NFTContract), "Caller is not the Farbe contract");
        _;
    }

    /**
     * @dev External function to be called to transfer token to Institution for sale
     * @param _institutionAddress address of institution
     * @param _tokenId ID of token to be transfered 
     */
    function assignToInstitution(address _institutionAddress, uint256 _tokenId) external {
        require(NFTContract.ownerOf(_tokenId) == msg.sender, "Sender is not the owner");
        NFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        institutionToTokenCollection[_institutionAddress].set(_tokenId, msg.sender);
        
        emit AssignedToInstitution(_institutionAddress, _tokenId, msg.sender);
    }

    /**
     * @dev External function (but only called by Farbe Contract while minting) to be called to transfer token to Institution for sale
     * @param _institutionAddress address of institution
     * @param _tokenId ID of token to be transfered
     * @param _owner Owner of the token
     */
    function assignToInstitution(address _institutionAddress, uint256 _tokenId, address _owner) external onlyFarbeContract {
        NFTContract.safeTransferFrom(NFTContract.ownerOf(_tokenId), address(this), _tokenId);
        institutionToTokenCollection[_institutionAddress].set(_tokenId, _owner);
        
        emit AssignedToInstitution(_institutionAddress, _tokenId, _owner);
    }

    /**
     * @dev External function to take back token from institution
     * @param _tokenId ID of token
     * @param _institution address of institution
     */
    function takeBackFromInstitution(uint256 _tokenId, address _institution) external {
        address tokenOwner;
        tokenOwner = institutionToTokenCollection[_institution].get(_tokenId);
        require(tokenOwner == msg.sender, "Not original owner");
        
        institutionToTokenCollection[_institution].remove(_tokenId);
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit TakeBackFromInstitution(_tokenId, _institution, tokenOwner);
    }

    function preSaleChecks(uint256 _tokenId, uint16 _galleryCut) internal returns (address, address, address, uint16) {
        address owner = NFTContract.ownerOf(_tokenId);

        if(owner == address(this)){
            require(institutionToTokenCollection[msg.sender].contains(_tokenId), "Not approved institution");
        }
        else {
            require(owner == msg.sender, "Not owner or institution");
        }

        // using struct to avoid 'stack too deep' error
        tokenDetails memory _details = tokenDetails(
            NFTContract.getTokenCreatorAddress(_tokenId),
            NFTContract.getTokenCreatorCut(_tokenId),
            owner != msg.sender // true if sale is from an institution
        );

        if(getSecondarySale(_tokenId)){
            require(_details.creatorCut + _galleryCut + 25 < 1000, "Cuts greater than 100%");
        } else {
            require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");
        }

        // get reference to owner before transfer
        address _seller = _details.isInstitution ? institutionToTokenCollection[msg.sender].get(_tokenId) : msg.sender;

        if(_details.isInstitution){
            institutionToTokenCollection[msg.sender].remove(_tokenId);
        }

        // determine gallery address (0 if called by owner)
        address _galleryAddress = _details.isInstitution ? msg.sender : address(0);

        // escrow the token into the auction smart contract
        if(!_details.isInstitution) {
            NFTContract.safeTransferFrom(owner, address(this), _tokenId);
        }
        
        return (_details.tokenCreator, _seller, _galleryAddress, _details.creatorCut);

    }
    
    
    /**
     * @dev Creates the sale auction for the token by calling the external auction contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingPrice Starting price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _duration The duration in seconds for the auction
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleAuction(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        uint16 _galleryCut
    )
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the auction
        createAuctionSale(
            _tokenId,
            _startingPrice,
            _startingTime,
            _duration,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the sale auction for a bulk of tokens by calling the internal createSaleAuction for each one. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _startingPrice Starting prices of the auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _duration The durations in seconds for the auction
     * @param _galleryCut The cuts for the gallery, will be 0 if gallery is not involved
     */
    function createBulkSaleAuction(
        uint256[] memory _tokenId,
        uint128[] memory _startingPrice,
        uint64[] memory _startingTime,
        uint64[] memory _duration,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_startingPrice.length == _numberOfTokens, "starting prices incorrect");
        require(_startingTime.length == _numberOfTokens, "starting times incorrect");
        require(_duration.length == _numberOfTokens, "durations incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleAuction(_tokenId[i], _startingPrice[i], _startingTime[i], _duration[i], _galleryCut);
        }
    }

    /**
     * @dev Creates the fixed price sale for the token by calling the external fixed sale contract. Can only be called by owner.
     * Individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _fixedPrice Fixed price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    
    function createSaleFixedPrice(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the FixedPrice
        createFixedPriceSale(
            _tokenId,
            _fixedPrice,
            _startingTime,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the fixed price sale for a bulk of tokens by calling the internal createSaleFixedPrice funtion. Can only be called by owner.
     * Individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _fixedPrice Fixed prices of the auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    
    function createBulkSaleFixedPrice(
        uint256[] memory _tokenId,
        uint128[] memory _fixedPrice,
        uint64[] memory _startingTime,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_fixedPrice.length == _numberOfTokens, "fixed prices incorrect");
        require(_startingTime.length == _numberOfTokens, "starting times incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleFixedPrice(_tokenId[i], _fixedPrice[i], _startingTime[i], _galleryCut);
        }
    }

    /**
     * @dev Creates the open offer sale for the token by calling the external open offers contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleOpenOffer(
        uint256 _tokenId,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    public
    onlyValidStartingTime(_startingTime)
    whenNotPaused()
    {
        address _creatorAddress;
        address _seller;
        address _galleryAddress;
        uint16 _creatorCut;
        
        (_creatorAddress, _seller, _galleryAddress, _creatorCut) = preSaleChecks(_tokenId, _galleryCut);

        // call the external contract function to create the openOffer
        createOppenOfferSale(
            _tokenId,
            _startingTime,
            _creatorAddress,
            _seller,
            _galleryAddress,
            _creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the open offer sale for a bulk of tokens by calling the internal createSaleOpenOffer function. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId IDs of the tokens to put on auction
     * @param _startingTime Starting times of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createBulkSaleOpenOffer(
        uint256[] memory _tokenId,
        uint64[] memory _startingTime,
        uint16 _galleryCut
    )
    external
    whenNotPaused()
    {
        uint _numberOfTokens = _tokenId.length;

        require(_startingTime.length == _numberOfTokens, "starting times incorrect");

        for(uint i = 0; i < _numberOfTokens; i++){
            createSaleOpenOffer(_tokenId[i], _startingTime[i], _galleryCut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../v1/Auction.sol";
import "../../v1/FixedPrice.sol";
import "../../v1/OpenOffers.sol";

interface IFarbeMarketplace {
    function assignToInstitution(address _institutionAddress, uint256 _tokenId, address _owner) external;
    function getIsFarbeMarketplace() external view returns (bool);
}


/**
 * @title ERC721 contract implementation
 * @dev Implements the ERC721 interface for the Farbe artworks
 */
contract FarbeArtV3Upgradeable is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    // counter for tracking token IDs
    CountersUpgradeable.Counter internal _tokenIdCounter;

    // details of the artwork
    struct artworkDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isSecondarySale;
    }

    // mapping of token id to original creator
    mapping(uint256 => artworkDetails) public tokenIdToDetails;

    // not using this here anymore, it has been moved to the farbe marketplace contract
    // platform cut on primary sales in %age * 10
    uint16 public platformCutOnPrimarySales;

    // constant for defining the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // reference to auction contract
    AuctionSale public auctionSale;
    // reference to fixed price contract
    FixedPriceSale public fixedPriceSale;
    // reference to open offer contract
    OpenOffersSale public openOffersSale;

    event TokenUriChanged(uint256 tokenId, string uri);
    
    /**
     * @dev Initializer for the ERC721 contract
     */
    function initialize() public initializer {
        __ERC721_init("FarbeArt", "FBA");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Implementation of ERC721Enumerable
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Destroy (burn) the NFT
     * @param tokenId The ID of the token to burn
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the token
     * @param tokenId ID of the token to return URI of
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) public view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Implementation of the ERC165 interface
     * @param interfaceId The Id of the interface to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;

}


/**
 * @title Farbe NFT sale contract
 * @dev Extension of the FarbeArt contract to add sale functionality
 */
contract FarbeArtSaleV3Upgradeable is FarbeArtV3Upgradeable {
    /**
     * @dev Only allow owner to execute if no one (gallery) has been approved
     * @param _tokenId Id of the token to check approval and ownership of
     */
    modifier onlyOwnerOrApproved(uint256 _tokenId) {
        if(getApproved(_tokenId) == address(0)){
            require(ownerOf(_tokenId) == msg.sender, "Not owner or approved");
        } else {
            require(getApproved(_tokenId) == msg.sender, "Only approved can list, revoke approval to list yourself");
        }
        _;
    }

    /**
     * @dev Make sure the starting time is not greater than 60 days
     * @param _startingTime starting time of the sale in UNIX timestamp
     */
    modifier onlyValidStartingTime(uint64 _startingTime) {
        if(_startingTime > block.timestamp) {
            require(_startingTime - block.timestamp <= 60 days, "Start time too far");
        }
        _;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @dev Function to mint an artwork as NFT. If no gallery is approved, the parameter is zero
     * @param _to The address to send the minted NFT
     * @param _creatorCut The cut that the original creator will take on secondary sales
     */
    function safeMint(
        address _to,
        address _galleryAddress,
        uint8 _numberOfCopies,
        uint16 _creatorCut,
        string[] memory _tokenURI
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "does not have minter role");

        require(_tokenURI.length == _numberOfCopies, "Metadata URIs not equal to editions");

        for(uint i = 0; i < _numberOfCopies; i++){
            // mint the token
            _safeMint(_to, _tokenIdCounter.current());
            // approve the gallery (0 if no gallery authorized)
            setApprovalForAll(farbeMarketplace, true);
            // set the token URI
            _setTokenURI(_tokenIdCounter.current(), _tokenURI[i]);
            // track token creator
            tokenIdToDetails[_tokenIdCounter.current()].tokenCreator = _to;
            // track creator's cut
            tokenIdToDetails[_tokenIdCounter.current()].creatorCut = _creatorCut;

            if(_galleryAddress != address(0)){
                IFarbeMarketplace(farbeMarketplace).assignToInstitution(_galleryAddress, _tokenIdCounter.current(), msg.sender);
            }
            // increment tokenId
            _tokenIdCounter.increment();
        }
    }

    
    /**
     * @dev Initializer for the FarbeArtSale contract
     * name for initializer changed from "initialize" to "farbeInitialze" as it was causing override error with the initializer of NFT contract 
     */
    function farbeInitialize() public initializer {
        FarbeArtV3Upgradeable.initialize();
    }

    function burn(uint256 tokenId) external {
        // must be owner
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

    /**
     * @dev Change the tokenUri of the token. Can only be changed when the creator is the owner
     * @param _tokenURI New Uri of the token
     * @param _tokenId Id of the token to change Uri of
     */
    function changeTokenUri(string memory _tokenURI, uint256 _tokenId) external {
        // must be owner and creator
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(tokenIdToDetails[_tokenId].tokenCreator == msg.sender, "Not creator");

        _setTokenURI(_tokenId, _tokenURI);

        emit TokenUriChanged(
            uint256(_tokenId),
            string(_tokenURI)
        );
    }
    
    function setFarbeMarketplaceAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        farbeMarketplace = _address;
    }
    
    function getTokenCreatorAddress(uint256 _tokenId) public view returns(address) {
        return tokenIdToDetails[_tokenId].tokenCreator;
    }
    
    function getTokenCreatorCut(uint256 _tokenId) public view returns(uint16) {
        return tokenIdToDetails[_tokenId].creatorCut;
    }

    uint256[1000] private __gap;
    // #sbt upgrades-plugin does not support __gaps for now
    // so including the new variable here
    address public farbeMarketplace;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SaleBaseV3Upgradeable.sol";

/**
 * @title Base fixed price contract
 * @dev This is the base fixed price contract which implements the internal functionality
 */
contract FixedPriceBaseV3Upgradeable is SaleBaseV3Upgradeable {
    using AddressUpgradeable for address payable;

    // fixed price sale struct to keep track of the sales
    struct FixedPrice {
        address seller;
        address creator;
        address gallery;
        uint128 fixedPrice;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => FixedPrice) tokenIdToSale;

    event FixedSaleCreated(uint256 tokenId, uint128 fixedPrice, uint64 startingTime, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event FixedSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address creator, address seller, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event FixedSaleFinished(uint256 tokenId, address gallery, address seller);

    /**
     * @dev Add the sale to the mapping and emit the FixedSaleCreated event
     * @param _tokenId ID of the token to sell
     * @param _fixedSale Reference to the sale struct to add to the mapping
     */
    function _addSale(uint256 _tokenId, FixedPrice memory _fixedSale) internal {
        // update mapping
        tokenIdToSale[_tokenId] = _fixedSale;

        // emit event for FixedSaleCreated
        emit FixedSaleCreated(
            _tokenId,
            _fixedSale.fixedPrice,
            _fixedSale.startedAt,
            _fixedSale.creator,
            _fixedSale.seller,
            _fixedSale.gallery,
            _fixedSale.creatorCut,
            _fixedSale.platformCut,
            _fixedSale.galleryCut
        );
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeFixedPriceSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /**
     * @dev Internal function to check if a sale started. By default startedAt is at 0
     * @param _fixedSale Reference to the sale struct to check
     * @return bool Weather the sale has started
     */
    function _isOnSale(FixedPrice storage _fixedSale) internal view returns (bool) {
        return (_fixedSale.startedAt > 0 && _fixedSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to buy a token on sale
     * @param _tokenId Id of the token to buy
     * @param _amount The amount in wei
     */
    function _buy(uint256 _tokenId, uint256 _amount) internal {
        // get reference to the fixed price sale struct
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(fixedSale), "Item is not on sale");

        // check if sent amount is equal or greater than the set price
        require(_amount >= fixedSale.fixedPrice, "Not enough amount sent");

        // using struct to avoid stack too deep error
        FixedPrice memory referenceFixedSale = fixedSale;

        // delete the sale
        _removeFixedPriceSale(_tokenId);
        
        // pay the seller, and distribute cuts
        _payout(
            payable(referenceFixedSale.seller),
            payable(referenceFixedSale.creator),
            payable(referenceFixedSale.gallery),
            referenceFixedSale.creatorCut,
            referenceFixedSale.platformCut,
            referenceFixedSale.galleryCut,
            _amount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(msg.sender, _tokenId);

        emit FixedSaleSuccessful(
            _tokenId, 
            _amount, 
            msg.sender, 
            referenceFixedSale.creator,
            referenceFixedSale.seller, 
            referenceFixedSale.creatorCut, 
            referenceFixedSale.platformCut, 
            referenceFixedSale.galleryCut
        );
    }

    /**
     * @dev Function to finish the sale. Can be called manually if no one bought the NFT. If
     * a gallery put the artwork on sale, only it can call this function. The super admin can
     * also call the function, this is implemented as a safety mechanism for the seller in case
     * the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishFixedPriceSale(uint256 _tokenId) internal {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // only the gallery can finish the sale if it was the one to put it on auction
        if(fixedSale.gallery != address(0)) {
            require(fixedSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(fixedSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(fixedSale), "Item is not on sale");

        address seller = fixedSale.seller;

        emit FixedSaleFinished(
            _tokenId,
            fixedSale.gallery,
            fixedSale.seller
            );

        // delete the sale
        _removeFixedPriceSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }

    uint256[1000] private __gap;
}

/**
 * @title Fixed Price sale contract that provides external functions
 * @dev Implements the external and public functions of the Fixed price implementation
 */
contract FixedPriceSaleV3Upgradeable is FixedPriceBaseV3Upgradeable {
    // sanity check for the nft contract
    bool public isFarbeFixedSale;


    /**
     * @dev External function to create fixed sale. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create sale for
     * @param _fixedPrice Starting price of the sale in wei
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this sale, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createFixedPriceSale(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    internal
    {
        // create and add the sale
        FixedPrice memory fixedSale = FixedPrice(
            _seller,
            _creator,
            _gallery,
            _fixedPrice,
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut
        );
        _addSale(_tokenId, fixedSale);
    }

    /**
     * @dev External payable function to buy the artwork
     * @param _tokenId Id of the token to buy
     */
    function buy(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to buy their own artwork
        require(tokenIdToSale[_tokenId].seller != msg.sender && tokenIdToSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _buy(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishFixedPriceSale(uint256 _tokenId) external {
        _finishFixedPriceSale(_tokenId);
    }

    /**
     * @dev External view function to get the details of a sale
     * @param _tokenId ID of the token to get the sale information of
     * @return seller Address of the seller
     * @return fixedPrice Fixed Price of the sale in wei
     * @return startedAt Unix timestamp for when the sale started
     */
    function getFixedSale(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 fixedPrice,
        uint256 startedAt
    ) {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];
        require(_isOnSale(fixedSale), "Item is not on sale");
        return (
        fixedSale.seller,
        fixedSale.fixedPrice,
        fixedSale.startedAt
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./SaleBaseV3Upgradeable.sol";
import "../../EnumerableMap.sol";

/**
 * @title Base open offers contract
 * @dev This is the base contract which implements the open offers functionality
 */
contract OpenOffersBaseV3Upgradeable is PullPaymentUpgradeable, ReentrancyGuardUpgradeable, SaleBaseV3Upgradeable {
    using AddressUpgradeable for address payable;

    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct OpenOffers {
        address seller;
        address creator;
        address gallery;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
        EnumerableMap.AddressToUintMap offers;
    }

    // this struct is only used for referencing in memory. The OpenOffers struct can not
    // be used because it is only valid in storage since it contains a nested mapping
    struct OffersReference {
        address seller;
        address creator;
        address gallery;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => OpenOffers) tokenIdToOpenOfferSale;

    event OpenOffersSaleCreated(uint256 tokenId, uint64 startingTime, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event OpenOffersSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event makeOpenOffer(uint256 tokenId, uint256 totalPrice, address winner, address creator, address seller, address gallery);
    event rejectOpenOffer(uint256 tokenId, uint256 totalPrice, address loser, address creator, address seller, address gallery);
    event OpenOffersSaleFinished(uint256 tokenId, address creator, address seller, address gallery);

    /**
     * @dev Internal function to check if the sale started, by default startedAt will be 0
     *
     */
    function _isOnSale(OpenOffers storage _openSale) internal view returns (bool) {
        return (_openSale.startedAt > 0 && _openSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToOpenOfferSale[_tokenId];
    }

    /**
     * @dev Internal that updates the mapping when a new offer is made for a token on sale
     * @param _tokenId Id of the token to make offer on
     * @param _bidAmount The offer in wei
     */
    function _makeOffer(uint _tokenId, uint _bidAmount) internal {
        // get reference to the open offer struct
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(openSale), "Item is not on sale");

        uint256 returnAmount;
        bool offerExists;

        // get reference to the amount to return
        (offerExists, returnAmount) = openSale.offers.tryGet(msg.sender);

        // if there was a previous offer from this address, return the previous offer amount
        if(offerExists){
            _cancelOffer(_tokenId, msg.sender);
        }

        // update the mapping with the new offer
        openSale.offers.set(msg.sender, _bidAmount);

        // emit event
        emit makeOpenOffer(
            _tokenId,
            _bidAmount,
            msg.sender,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );
    }

    /**
     * @dev Internal function to accept the offer of an address. Once an offer is accepted, all existing offers
     * for the token are moved into the PullPayment contract and the mapping is deleted. Only gallery can accept
     * offers if the sale involves a gallery
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer The address of the buyer to accept offer from
     */
    function _acceptOffer(uint256 _tokenId, address _buyer) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // only the gallery can accept the offer if it was the one to put it on open offers
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender);
        } else {
            require(openSale.seller == msg.sender);
        }

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        // check if the offer from the buyer exists
        require(openSale.offers.contains(_buyer));

        // get reference to the offer
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        address returnAddress;
        uint256 returnAmount;

        // put the returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // remove the offer from the enumerable mapping
            openSale.offers.remove(returnAddress);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);

            // emit event
            emit rejectOpenOffer(
                _tokenId,
                returnAmount,
                returnAddress,
                openSale.creator,
                openSale.seller,
                openSale.gallery
                );
        }

        // using struct to avoid stack too deep error
        OffersReference memory openSaleReference = OffersReference(
            openSale.seller,
            openSale.creator,
            openSale.gallery,
            openSale.creatorCut,
            openSale.platformCut,
            openSale.galleryCut
        );

        // delete the sale
        _removeSale(_tokenId);

        // pay the seller and distribute the cuts
        _payout(
            payable(openSaleReference.seller),
            payable(openSaleReference.creator),
            payable(openSaleReference.gallery),
            openSaleReference.creatorCut,
            openSaleReference.platformCut,
            openSaleReference.galleryCut,
            _payoutAmount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(_buyer, _tokenId);

        // emit event
        emit OpenOffersSaleSuccessful(
                _tokenId,
                _payoutAmount,
                _buyer,
                openSaleReference.creator,
                openSaleReference.seller,
                openSaleReference.gallery,
                openSaleReference.creatorCut,
                openSaleReference.platformCut,
                openSaleReference.galleryCut
            );
    }

    /**
     * @dev Internal function to cancel an offer. This is used for both rejecting and revoking offers
     * @param _tokenId Id of the token to cancel offer of
     * @param _buyer The address to cancel bid of
     */
    function _cancelOffer(uint256 _tokenId, address _buyer) internal {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        // get reference to the offer, will fail if mapping doesn't exist
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        // return the ether
        payable(_buyer).sendValue(_payoutAmount);

        // emit event
        emit rejectOpenOffer(
            _tokenId,
            _payoutAmount,
            _buyer,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );
    }

    /**
     * @dev Function to finish the sale. Can be called manually if there was no suitable offer
     * for the NFT. If a gallery put the artwork on sale, only it can call this function.
     * The super admin can also call the function, this is implemented as a safety mechanism for
     * the seller in case the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishOpenOfferSale(uint256 _tokenId) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // only the gallery or admin can finish the sale if it was the one to put it on auction
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(openSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        address seller = openSale.seller;

        address returnAddress;
        uint256 returnAmount;

        // put all pending returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // remove the offer from the enumerable mapping
            openSale.offers.remove(returnAddress);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);

            // emit event
            emit rejectOpenOffer(
                _tokenId,
                returnAmount,
                returnAddress,
                openSale.creator,
                openSale.seller,
                openSale.gallery
                );
        }
        
        // emit event
        emit OpenOffersSaleFinished(
            _tokenId,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );

        // delete the sale
        _removeSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }

    uint256[1000] private __gap;
}

/**
 * @title Open Offers sale contract that provides external functions
 * @dev Implements the external and public functions of the open offers implementation
 */
contract OpenOffersSaleV3Upgradeable is OpenOffersBaseV3Upgradeable {
    bool public isFarbeOpenOffersSale;

    /**
     * External function to create an Open Offers sale. Can only be called by the Farbe NFT contract
     * @param _tokenId Id of the token to create sale for
     * @param _startingTime Starting time of the sale
     * @param _creator Address of  the original creator of the artwork
     * @param _seller Address of the owner of the artwork
     * @param _gallery Address of the gallery of the artwork, 0 address if gallery is not involved
     * @param _creatorCut Cut of the creator in %age * 10
     * @param _galleryCut Cut of the gallery in %age * 10
     * @param _platformCut Cut of the platform on primary sales in %age * 10
     */
    function createOppenOfferSale(
        uint256 _tokenId,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    internal
    {
        OpenOffers storage openOffers = tokenIdToOpenOfferSale[_tokenId];

        openOffers.seller = _seller;
        openOffers.creator = _creator;
        openOffers.gallery = _gallery;
        openOffers.startedAt = _startingTime;
        openOffers.creatorCut = _creatorCut;
        openOffers.platformCut = _platformCut;
        openOffers.galleryCut = _galleryCut;

        // emit event
        emit OpenOffersSaleCreated(
            _tokenId,
            openOffers.startedAt,
            openOffers.creator,
            openOffers.seller,
            openOffers.gallery,
            openOffers.creatorCut,
            openOffers.platformCut,
            openOffers.galleryCut
        );
    }

    /**
     * @dev External function that allows others to make offers for an artwork
     * @param _tokenId Id of the token to make offer for
     */
    function makeOffer(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to make offers on their own artwork
        require(tokenIdToOpenOfferSale[_tokenId].seller != msg.sender && tokenIdToOpenOfferSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _makeOffer(_tokenId, msg.value);
    }

    /**
     * @dev External function to allow a gallery or a seller to accept an offer
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer Address of the buyer to accept offer of
     */
    function acceptOffer(uint256 _tokenId, address _buyer) external {
        _acceptOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to reject a particular offer and return the ether
     * @param _tokenId Id of the token to reject offer of
     * @param _buyer Address of the buyer to reject offer of
     */
    function rejectOffer(uint256 _tokenId, address _buyer) external {
    // only the gallery can accept the offer if it was the one to put it on open offers
        if(tokenIdToOpenOfferSale[_tokenId].gallery != address(0)) {
            require(tokenIdToOpenOfferSale[_tokenId].gallery == msg.sender);
        } else {
            require(tokenIdToOpenOfferSale[_tokenId].seller == msg.sender);
        }        _cancelOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to allow buyers to revoke their offers
     * @param _tokenId Id of the token to revoke offer of
     */
    function revokeOffer(uint256 _tokenId) external {
        _cancelOffer(_tokenId, msg.sender);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishSale(uint256 _tokenId) external {
        _finishOpenOfferSale(_tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FarbeArtV3Upgradeable.sol";
import "./SaleBaseV3Upgradeable.sol";


/**
 * @title Base auction contract
 * @dev This is the base auction contract which implements the auction functionality
 */
contract AuctionBaseV3Upgradeable is SaleBaseV3Upgradeable {
    using AddressUpgradeable for address payable;

    // auction struct to keep track of the auctions
    struct Auction {
        address seller;
        address creator;
        address gallery;
        address buyer;
        uint128 currentPrice;
        uint64 duration;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
        uint128 startPrice;
    }

    // mapping for tokenId to its auction
    mapping(uint256 => Auction) tokenIdToAuction;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint64 startingTime, uint256 duration, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, uint256 duration, address winner, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event BidCreated(uint256 tokenId, uint256 totalPrice, uint256 duration, address winner, address creator, address seller, address gallery);

    /**
     * @dev Add the auction to the mapping and emit the AuctionCreated event, duration must meet the requirements
     * @param _tokenId ID of the token to auction
     * @param _auction Reference to the auction struct to add to the mapping
     */
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        // check minimum and maximum time requirements
        require(_auction.duration >= 1 hours && _auction.duration <= 30 days, "time requirement failed");

        // update mapping
        tokenIdToAuction[_tokenId] = _auction;

        // emit event
        emit AuctionCreated(
            _tokenId,
            _auction.currentPrice,
            _auction.startedAt,
            _auction.duration,
            _auction.creator,
            _auction.seller,
            _auction.gallery,
            _auction.creatorCut,
            _auction.platformCut,
            _auction.galleryCut
        );
    }

    /**
     * @dev Remove the auction from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove auction of
     */
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Internal function to check the current price of the auction
     * @param auction Reference to the auction to check price of
     * @return uint128 The current price of the auction
     */
    function _currentPrice(Auction storage auction) internal view returns (uint128) {
        return (auction.currentPrice);
    }

    /**
     * @dev Internal function to return the bid to the previous bidder if there was one
     * @param _destination Address of the previous bidder
     * @param _amount Amount to return to the previous bidder
     */
    function _returnBid(address payable _destination, uint256 _amount) private {
        // zero address means there was no previous bidder
        if (_destination != address(0)) {
            _destination.sendValue(_amount);
        }
    }

    /**
     * @dev Internal function to check if an auction started. By default startedAt is at 0
     * @param _auction Reference to the auction struct to check
     * @return bool Weather the auction has started
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to implement the bid functionality
     * @param _tokenId ID of the token to bid upon
     * @param _bidAmount Amount to bid
     */
    function _bid(uint _tokenId, uint _bidAmount) internal {
        // get reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if the item is on auction
        require(_isOnAuction(auction), "Item is not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed <= auction.duration, "Auction time has ended");

        // check if bid is higher than the previous one
        uint256 price = auction.currentPrice;
        require(_bidAmount > price, "Bid is too low");
        
        if(price == auction.startPrice) {
            require(_bidAmount >= price);
        } else {
            require(_bidAmount >= (price + ((price * minBidIncrementPercentage) / 1000)), "increment not met");
        }

        // return the previous bidder's bid amount
        _returnBid(payable(auction.buyer), auction.currentPrice);

        // update the current bid amount and the bidder address
        auction.currentPrice = uint128(_bidAmount);
        auction.buyer = msg.sender;

        // if the bid is made in the last 15 minutes, increase the duration of the
        // auction so that the timer resets to 15 minutes
        uint256 timeRemaining = auction.duration - secondsPassed;
        if (timeRemaining <= 15 minutes) {
            uint256 timeToAdd = 15 minutes - timeRemaining;
            auction.duration += uint64(timeToAdd);
        }
        
        emit BidCreated(
            _tokenId,
            auction.currentPrice,
            auction.duration,
            auction.buyer,
            auction.creator,
            auction.seller,
            auction.gallery
            );
    }

    /**
     * @dev Internal function to finish the auction after the auction time has ended
     * @param _tokenId ID of the token to finish auction of
     */
    function _finishAuction(uint256 _tokenId) internal {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // if there was no successful bid, return token to the seller
        if (referenceAuction.buyer == address(0)) {
            _transfer(referenceAuction.seller, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                0,
                referenceAuction.duration,
                referenceAuction.seller,
                referenceAuction.creator,
                referenceAuction.seller,
                referenceAuction.gallery,
                referenceAuction.creatorCut,
                referenceAuction.platformCut,
                referenceAuction.galleryCut
            );
        }
        // if there was a successful bid, pay the seller and transfer the token to the buyer
        else {
        
            _payout(
                payable(referenceAuction.seller),
                payable(referenceAuction.creator),
                payable(referenceAuction.gallery),
                referenceAuction.creatorCut,
                referenceAuction.platformCut,
                referenceAuction.galleryCut,
                referenceAuction.currentPrice,
                _tokenId
            );
            _transfer(referenceAuction.buyer, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                referenceAuction.currentPrice,
                referenceAuction.duration,
                referenceAuction.buyer,
                referenceAuction.creator,
                referenceAuction.seller,
                referenceAuction.gallery,
                referenceAuction.creatorCut,
                referenceAuction.platformCut,
                referenceAuction.galleryCut
            );
        }
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period of 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function _forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    internal
    {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // check if its been more than 7 days since auction ended
        require(secondsPassed - auction.duration >= 7 days);

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // transfer ether to the beneficiary
        payable(_paymentBeneficiary).sendValue(referenceAuction.currentPrice);

        // transfer nft to the nft beneficiary
        _transfer(_nftBeneficiary, _tokenId);

        emit AuctionSuccessful(
            _tokenId,
            0,
            referenceAuction.duration,
            _nftBeneficiary,
            referenceAuction.creator,
            _paymentBeneficiary,
            referenceAuction.gallery,
            referenceAuction.creatorCut,
            referenceAuction.platformCut,
            referenceAuction.galleryCut
        );
    }

    uint256[1000] private __gap;
}


/**
 * @title Auction sale contract that provides external functions
 * @dev Implements the external and public functions of the auction implementation
 */
contract AuctionSaleV3Upgradeable is AuctionBaseV3Upgradeable {
    // sanity check for the nft contract
    bool public isFarbeSaleAuction;

    /**
     * @dev External function to create auction. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create auction for
     * @param _startingPrice Starting price of the auction in wei
     * @param _duration Duration of the auction in seconds
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this auction, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createAuctionSale(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    internal
    {
        // create and add the auction
        Auction memory auction = Auction(
            _seller,
            _creator,
            _gallery,
            address(0),
            uint128(_startingPrice),
            uint64(_duration),
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut,
            uint128(_startingPrice)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev External payable bid function. Sellers can not bid on their own artworks
     * @param _tokenId ID of the token to bid on
     */
    function bid(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to bid on their own artwork
        require(tokenIdToAuction[_tokenId].seller != msg.sender && tokenIdToAuction[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _bid(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the auction. Currently can be called by anyone TODO restrict access?
     * @param _tokenId ID of the token to finish auction of
     */
    function finishAuction(uint256 _tokenId) external {
        _finishAuction(_tokenId);
    }

    /**
     * @dev External view function to get the details of an auction
     * @param _tokenId ID of the token to get the auction information of
     * @return seller Address of the seller
     * @return buyer Address of the buyer
     * @return currentPrice Current Price of the auction in wei
     * @return duration Duration of the auction in seconds
     * @return startedAt Unix timestamp for when the auction started
     */
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        address buyer,
        uint256 currentPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.buyer,
        auction.currentPrice,
        auction.duration,
        auction.startedAt
        );
    }

    /**
     * @dev External view function to get the current price of an auction
     * @param _tokenId ID of the token to get the current price of
     * @return uint128 Current price of the auction in wei
     */
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint128)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period f 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _forceFinishAuction(_tokenId, _nftBeneficiary, _paymentBeneficiary);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./FarbeArt.sol";
import "./SaleBase.sol";


/**
 * @title Base auction contract
 * @dev This is the base auction contract which implements the auction functionality
 */
contract AuctionBase is SaleBase {
    using Address for address payable;

    // auction struct to keep track of the auctions
    struct Auction {
        address seller;
        address creator;
        address gallery;
        address buyer;
        uint128 currentPrice;
        uint64 duration;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its auction
    mapping(uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /**
     * @dev Add the auction to the mapping and emit the AuctionCreated event, duration must meet the requirements
     * @param _tokenId ID of the token to auction
     * @param _auction Reference to the auction struct to add to the mapping
     */
    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        // check minimum and maximum time requirements
        require(_auction.duration >= 1 hours && _auction.duration <= 30 days, "time requirement failed");

        // update mapping
        tokenIdToAuction[_tokenId] = _auction;

        // emit event
        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.currentPrice),
            uint256(_auction.duration)
        );
    }

    /**
     * @dev Remove the auction from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove auction of
     */
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Internal function to check the current price of the auction
     * @param auction Reference to the auction to check price of
     * @return uint128 The current price of the auction
     */
    function _currentPrice(Auction storage auction) internal view returns (uint128) {
        return (auction.currentPrice);
    }

    /**
     * @dev Internal function to return the bid to the previous bidder if there was one
     * @param _destination Address of the previous bidder
     * @param _amount Amount to return to the previous bidder
     */
    function _returnBid(address payable _destination, uint256 _amount) private {
        // zero address means there was no previous bidder
        if (_destination != address(0)) {
            _destination.sendValue(_amount);
        }
    }

    /**
     * @dev Internal function to check if an auction started. By default startedAt is at 0
     * @param _auction Reference to the auction struct to check
     * @return bool Weather the auction has started
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to implement the bid functionality
     * @param _tokenId ID of the token to bid upon
     * @param _bidAmount Amount to bid
     */
    function _bid(uint _tokenId, uint _bidAmount) internal {
        // get reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if the item is on auction
        require(_isOnAuction(auction), "Item is not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed <= auction.duration, "Auction time has ended");

        // check if bid is higher than the previous one
        uint256 price = auction.currentPrice;
        require(_bidAmount > price, "Bid is too low");

        // return the previous bidder's bid amount
        _returnBid(payable(auction.buyer), auction.currentPrice);

        // update the current bid amount and the bidder address
        auction.currentPrice = uint128(_bidAmount);
        auction.buyer = msg.sender;

        // if the bid is made in the last 15 minutes, increase the duration of the
        // auction so that the timer resets to 15 minutes
        uint256 timeRemaining = auction.duration - secondsPassed;
        if (timeRemaining <= 15 minutes) {
            uint256 timeToAdd = 15 minutes - timeRemaining;
            auction.duration += uint64(timeToAdd);
        }
    }

    /**
     * @dev Internal function to finish the auction after the auction time has ended
     * @param _tokenId ID of the token to finish auction of
     */
    function _finishAuction(uint256 _tokenId) internal {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // if there was no successful bid, return token to the seller
        if (referenceAuction.buyer == address(0)) {
            _transfer(referenceAuction.seller, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                0,
                referenceAuction.seller
            );
        }
        // if there was a successful bid, pay the seller and transfer the token to the buyer
        else {
            _payout(
                payable(referenceAuction.seller),
                payable(referenceAuction.creator),
                payable(referenceAuction.gallery),
                referenceAuction.creatorCut,
                referenceAuction.platformCut,
                referenceAuction.galleryCut,
                referenceAuction.currentPrice,
                _tokenId
            );
            _transfer(referenceAuction.buyer, _tokenId);

            emit AuctionSuccessful(
                _tokenId,
                referenceAuction.currentPrice,
                referenceAuction.buyer
            );
        }
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period f 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function _forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    internal
    {
        // using storage for _isOnAuction
        Auction storage auction = tokenIdToAuction[_tokenId];

        // check if token was on auction
        require(_isOnAuction(auction), "Token was not on auction");

        // check if auction time has ended
        uint256 secondsPassed = block.timestamp - auction.startedAt;
        require(secondsPassed > auction.duration, "Auction hasn't ended");

        // check if its been more than 7 days since auction ended
        require(secondsPassed - auction.duration >= 7 days);

        // using struct to avoid stack too deep error
        Auction memory referenceAuction = auction;

        // delete the auction
        _removeAuction(_tokenId);

        // transfer ether to the beneficiary
        payable(_paymentBeneficiary).sendValue(referenceAuction.currentPrice);

        // transfer nft to the nft beneficiary
        _transfer(_nftBeneficiary, _tokenId);
    }
}


/**
 * @title Auction sale contract that provides external functions
 * @dev Implements the external and public functions of the auction implementation
 */
contract AuctionSale is AuctionBase {
    // sanity check for the nft contract
    bool public isFarbeSaleAuction = true;

    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    constructor(address _nftAddress, address _platformAddress) {
        // check NFT contract supports ERC721 interface
        FarbeArtSale candidateContract = FarbeArtSale(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        platformWalletAddress = _platformAddress;

        NFTContract = candidateContract;
    }

    /**
     * @dev External function to create auction. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create auction for
     * @param _startingPrice Starting price of the auction in wei
     * @param _duration Duration of the auction in seconds
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this auction, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createSale(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    external
    onlyFarbeContract
    {
        // create and add the auction
        Auction memory auction = Auction(
            _seller,
            _creator,
            _gallery,
            address(0),
            uint128(_startingPrice),
            uint64(_duration),
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev External payable bid function. Sellers can not bid on their own artworks
     * @param _tokenId ID of the token to bid on
     */
    function bid(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to bid on their own artwork
        require(tokenIdToAuction[_tokenId].seller != msg.sender && tokenIdToAuction[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _bid(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the auction. Currently can be called by anyone TODO restrict access?
     * @param _tokenId ID of the token to finish auction of
     */
    function finishAuction(uint256 _tokenId) external {
        _finishAuction(_tokenId);
    }

    /**
     * @dev External view function to get the details of an auction
     * @param _tokenId ID of the token to get the auction information of
     * @return seller Address of the seller
     * @return buyer Address of the buyer
     * @return currentPrice Current Price of the auction in wei
     * @return duration Duration of the auction in seconds
     * @return startedAt Unix timestamp for when the auction started
     */
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        address buyer,
        uint256 currentPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.buyer,
        auction.currentPrice,
        auction.duration,
        auction.startedAt
        );
    }

    /**
     * @dev External view function to get the current price of an auction
     * @param _tokenId ID of the token to get the current price of
     * @return uint128 Current price of the auction in wei
     */
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint128)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    /**
     * @dev Helper function for testing with timers TODO Remove this before deploying live
     * @param _tokenId ID of the token to get timers of
     */
    function getTimers(uint256 _tokenId)
    external
    view returns (
        uint256 saleStart,
        uint256 blockTimestamp,
        uint256 duration
    ) {
        Auction memory auction = tokenIdToAuction[_tokenId];
        return (auction.startedAt, block.timestamp, auction.duration);
    }

    /**
     * @dev This is an internal function to end auction meant to only be used as a safety
     * mechanism if an NFT got locked within the contract. Can only be called by the super admin
     * after a period f 7 days has passed since the auction ended
     * @param _tokenId Id of the token to end auction of
     * @param _nftBeneficiary Address to send the NFT to
     * @param _paymentBeneficiary Address to send the payment to
     */
    function forceFinishAuction(
        uint256 _tokenId,
        address _nftBeneficiary,
        address _paymentBeneficiary
    )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _forceFinishAuction(_tokenId, _nftBeneficiary, _paymentBeneficiary);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SaleBase.sol";

/**
 * @title Base fixed price contract
 * @dev This is the base fixed price contract which implements the internal functionality
 */
contract FixedPriceBase is SaleBase {
    using Address for address payable;

    // fixed price sale struct to keep track of the sales
    struct FixedPrice {
        address seller;
        address creator;
        address gallery;
        uint128 fixedPrice;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => FixedPrice) tokenIdToSale;

    event FixedSaleCreated(uint256 tokenId, uint256 fixedPrice);
    event FixedSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /**
     * @dev Add the sale to the mapping and emit the FixedSaleCreated event
     * @param _tokenId ID of the token to sell
     * @param _fixedSale Reference to the sale struct to add to the mapping
     */
    function _addSale(uint256 _tokenId, FixedPrice memory _fixedSale) internal {
        // update mapping
        tokenIdToSale[_tokenId] = _fixedSale;

        // emit event
        emit FixedSaleCreated(
            uint256(_tokenId),
            uint256(_fixedSale.fixedPrice)
        );
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /**
     * @dev Internal function to check if a sale started. By default startedAt is at 0
     * @param _fixedSale Reference to the sale struct to check
     * @return bool Weather the sale has started
     */
    function _isOnSale(FixedPrice storage _fixedSale) internal view returns (bool) {
        return (_fixedSale.startedAt > 0 && _fixedSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to buy a token on sale
     * @param _tokenId Id of the token to buy
     * @param _amount The amount in wei
     */
    function _buy(uint256 _tokenId, uint256 _amount) internal {
        // get reference to the fixed price sale struct
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(fixedSale), "Item is not on sale");

        // check if sent amount is equal or greater than the set price
        require(_amount >= fixedSale.fixedPrice, "Amount sent is not enough to buy the token");

        // using struct to avoid stack too deep error
        FixedPrice memory referenceFixedSale = fixedSale;

        // delete the sale
        _removeSale(_tokenId);

        // pay the seller, and distribute cuts
        _payout(
            payable(referenceFixedSale.seller),
            payable(referenceFixedSale.creator),
            payable(referenceFixedSale.gallery),
            referenceFixedSale.creatorCut,
            referenceFixedSale.platformCut,
            referenceFixedSale.galleryCut,
            _amount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(msg.sender, _tokenId);

        emit FixedSaleSuccessful(_tokenId, referenceFixedSale.fixedPrice, msg.sender);
    }

    /**
     * @dev Function to finish the sale. Can be called manually if no one bought the NFT. If
     * a gallery put the artwork on sale, only it can call this function. The super admin can
     * also call the function, this is implemented as a safety mechanism for the seller in case
     * the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishSale(uint256 _tokenId) internal {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // only the gallery can finish the sale if it was the one to put it on auction
        if(fixedSale.gallery != address(0)) {
            require(fixedSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(fixedSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(fixedSale));

        address seller = fixedSale.seller;

        // delete the sale
        _removeSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }
}

/**
 * @title Fixed Price sale contract that provides external functions
 * @dev Implements the external and public functions of the Fixed price implementation
 */
contract FixedPriceSale is FixedPriceBase {
    // sanity check for the nft contract
    bool public isFarbeFixedSale = true;

    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    constructor(address _nftAddress, address _platformAddress) {
        // check NFT contract supports ERC721 interface
        FarbeArtSale candidateContract = FarbeArtSale(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        platformWalletAddress = _platformAddress;

        NFTContract = candidateContract;
    }

    /**
     * @dev External function to create fixed sale. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create sale for
     * @param _fixedPrice Starting price of the sale in wei
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this sale, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createSale(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    external
    onlyFarbeContract
    {
        // create and add the sale
        FixedPrice memory fixedSale = FixedPrice(
            _seller,
            _creator,
            _gallery,
            _fixedPrice,
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut
        );
        _addSale(_tokenId, fixedSale);
    }

    /**
     * @dev External payable function to buy the artwork
     * @param _tokenId Id of the token to buy
     */
    function buy(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to buy their own artwork
        require(tokenIdToSale[_tokenId].seller != msg.sender && tokenIdToSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _buy(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishSale(uint256 _tokenId) external {
        _finishSale(_tokenId);
    }

    /**
     * @dev External view function to get the details of a sale
     * @param _tokenId ID of the token to get the sale information of
     * @return seller Address of the seller
     * @return fixedPrice Fixed Price of the sale in wei
     * @return startedAt Unix timestamp for when the sale started
     */
    function getFixedSale(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 fixedPrice,
        uint256 startedAt
    ) {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];
        require(_isOnSale(fixedSale), "Item is not on sale");
        return (
        fixedSale.seller,
        fixedSale.fixedPrice,
        fixedSale.startedAt
        );
    }

    /**
     * @dev Helper function for testing with timers TODO Remove this before deploying live
     * @param _tokenId ID of the token to get timers of
     */
    function getTimers(uint256 _tokenId)
    external
    view returns (
        uint256 saleStart,
        uint256 blockTimestamp
    ) {
        FixedPrice memory fixedSale = tokenIdToSale[_tokenId];
        return (fixedSale.startedAt, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SaleBase.sol";
import "../EnumerableMap.sol";

/**
 * @title Base open offers contract
 * @dev This is the base contract which implements the open offers functionality
 */
contract OpenOffersBase is PullPayment, ReentrancyGuard, SaleBase {
    using Address for address payable;

    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct OpenOffers {
        address seller;
        address creator;
        address gallery;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
        EnumerableMap.AddressToUintMap offers;
    }

    // this struct is only used for referencing in memory. The OpenOffers struct can not
    // be used because it is only valid in storage since it contains a nested mapping
    struct OffersReference {
        address seller;
        address creator;
        address gallery;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => OpenOffers) tokenIdToSale;

    event OpenOffersSaleCreated(uint256 tokenId);
    event OpenOffersSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /**
     * @dev Internal function to check if the sale started, by default startedAt will be 0
     *
     */
    function _isOnSale(OpenOffers storage _openSale) internal view returns (bool) {
        return (_openSale.startedAt > 0 && _openSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /**
     * @dev Internal that updates the mapping when a new offer is made for a token on sale
     * @param _tokenId Id of the token to make offer on
     * @param _bidAmount The offer in wei
     */
    function _makeOffer(uint _tokenId, uint _bidAmount) internal {
        // get reference to the open offer struct
        OpenOffers storage openSale = tokenIdToSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(openSale));

        uint256 returnAmount;
        bool offerExists;

        // get reference to the amount to return
        (offerExists, returnAmount) = openSale.offers.tryGet(msg.sender);

        // update the mapping with the new offer
        openSale.offers.set(msg.sender, _bidAmount);

        // if there was a previous offer from this address, return the previous offer amount
        if(offerExists){
            payable(msg.sender).sendValue(returnAmount);
        }
    }

    /**
     * @dev Internal function to accept the offer of an address. Once an offer is accepted, all existing offers
     * for the token are moved into the PullPayment contract and the mapping is deleted. Only gallery can accept
     * offers if the sale involves a gallery
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer The address of the buyer to accept offer from
     */
    function _acceptOffer(uint256 _tokenId, address _buyer) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToSale[_tokenId];

        // only the gallery can accept the offer if it was the one to put it on auction
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender);
        } else {
            require(openSale.seller == msg.sender);
        }

        // check if token was on sale
        require(_isOnSale(openSale));

        // check if the offer from the buyer exists
        require(openSale.offers.contains(_buyer));

        // get reference to the offer
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        address returnAddress;
        uint256 returnAmount;

        // put the returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);
        }

        // using struct to avoid stack too deep error
        OffersReference memory openSaleReference = OffersReference(
            openSale.seller,
            openSale.creator,
            openSale.gallery,
            openSale.creatorCut,
            openSale.platformCut,
            openSale.galleryCut
        );

        // delete the sale
        _removeSale(_tokenId);

        // pay the seller and distribute the cuts
        _payout(
            payable(openSaleReference.seller),
            payable(openSaleReference.creator),
            payable(openSaleReference.gallery),
            openSaleReference.creatorCut,
            openSaleReference.platformCut,
            openSaleReference.galleryCut,
            _payoutAmount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(_buyer, _tokenId);
    }

    /**
     * @dev Internal function to cancel an offer. This is used for both rejecting and revoking offers
     * @param _tokenId Id of the token to cancel offer of
     * @param _buyer The address to cancel bid of
     */
    function _cancelOffer(uint256 _tokenId, address _buyer) internal {
        OpenOffers storage openSale = tokenIdToSale[_tokenId];

        // check if token was on sale
        require(_isOnSale(openSale));

        // get reference to the offer, will fail if mapping doesn't exist
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        // return the ether
        payable(_buyer).sendValue(_payoutAmount);
    }

    /**
     * @dev Function to finish the sale. Can be called manually if there was no suitable offer
     * for the NFT. If a gallery put the artwork on sale, only it can call this function.
     * The super admin can also call the function, this is implemented as a safety mechanism for
     * the seller in case the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishSale(uint256 _tokenId) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToSale[_tokenId];

        // only the gallery or admin can finish the sale if it was the one to put it on auction
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(openSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(openSale));

        address seller = openSale.seller;

        address returnAddress;
        uint256 returnAmount;

        // put all pending returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);
        }

        // delete the sale
        _removeSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }
}

/**
 * @title Open Offers sale contract that provides external functions
 * @dev Implements the external and public functions of the open offers implementation
 */
contract OpenOffersSale is OpenOffersBase {
    bool public isFarbeOpenOffersSale = true;

    /**
     * External function to create an Open Offers sale. Can only be called by the Farbe NFT contract
     * @param _tokenId Id of the token to create sale for
     * @param _startingTime Starting time of the sale
     * @param _creator Address of  the original creator of the artwork
     * @param _seller Address of the owner of the artwork
     * @param _gallery Address of the gallery of the artwork, 0 address if gallery is not involved
     * @param _creatorCut Cut of the creator in %age * 10
     * @param _galleryCut Cut of the gallery in %age * 10
     * @param _platformCut Cut of the platform on primary sales in %age * 10
     */
    function createSale(
        uint256 _tokenId,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    external
    onlyFarbeContract
    {
        OpenOffers storage openOffers = tokenIdToSale[_tokenId];

        openOffers.seller = _seller;
        openOffers.creator = _creator;
        openOffers.gallery = _gallery;
        openOffers.startedAt = _startingTime;
        openOffers.creatorCut = _creatorCut;
        openOffers.platformCut = _platformCut;
        openOffers.galleryCut = _galleryCut;
    }

    /**
     * @dev External function that allows others to make offers for an artwork
     * @param _tokenId Id of the token to make offer for
     */
    function makeOffer(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to make offers on their own artwork
        require(tokenIdToSale[_tokenId].seller != msg.sender && tokenIdToSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _makeOffer(_tokenId, msg.value);
    }

    /**
     * @dev External function to allow a gallery or a seller to accept an offer
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer Address of the buyer to accept offer of
     */
    function acceptOffer(uint256 _tokenId, address _buyer) external {
        _acceptOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to reject a particular offer and return the ether
     * @param _tokenId Id of the token to reject offer of
     * @param _buyer Address of the buyer to reject offer of
     */
    function rejectOffer(uint256 _tokenId, address _buyer) external {
        // only owner or gallery can reject an offer
        require(tokenIdToSale[_tokenId].seller == msg.sender || tokenIdToSale[_tokenId].gallery == msg.sender);
        _cancelOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to allow buyers to revoke their offers
     * @param _tokenId Id of the token to revoke offer of
     */
    function revokeOffer(uint256 _tokenId) external {
        _cancelOffer(_tokenId, msg.sender);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishSale(uint256 _tokenId) external {
        _finishSale(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OpenOffers.sol";
import "./Auction.sol";
import "./FixedPrice.sol";


/**
 * @title ERC721 contract implementation
 * @dev Implements the ERC721 interface for the Farbe artworks
 */
contract FarbeArt is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    // counter for tracking token IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // details of the artwork
    struct artworkDetails {
        address tokenCreator;
        uint16 creatorCut;
        bool isSecondarySale;
    }

    // mapping of token id to original creator
    mapping(uint256 => artworkDetails) tokenIdToDetails;

    // platform cut on primary sales in %age * 10
    uint16 public platformCutOnPrimarySales;

    // constant for defining the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // reference to auction contract
    AuctionSale public auctionSale;
    // reference to fixed price contract
    FixedPriceSale public fixedPriceSale;
    // reference to open offer contract
    OpenOffersSale public openOffersSale;

    event TokenUriChanged(uint256 tokenId, string uri);

    /**
     * @dev Constructor for the ERC721 contract
     */
    constructor() ERC721("FarbeArt", "FBA") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Function to mint an artwork as NFT. If no gallery is approved, the parameter is zero
     * @param _to The address to send the minted NFT
     * @param _creatorCut The cut that the original creator will take on secondary sales
     */
    function safeMint(
        address _to,
        address _galleryAddress,
        uint8 _numberOfCopies,
        uint16 _creatorCut,
        string[] memory _tokenURI
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "does not have minter role");

        require(_tokenURI.length == _numberOfCopies, "Metadata URIs not equal to editions");

        for(uint i = 0; i < _numberOfCopies; i++){
            // mint the token
            _safeMint(_to, _tokenIdCounter.current());
            // approve the gallery (0 if no gallery authorized)
            approve(_galleryAddress, _tokenIdCounter.current());
            // set the token URI
            _setTokenURI(_tokenIdCounter.current(), _tokenURI[i]);
            // track token creator
            tokenIdToDetails[_tokenIdCounter.current()].tokenCreator = _to;
            // track creator's cut
            tokenIdToDetails[_tokenIdCounter.current()].creatorCut = _creatorCut;
            // increment tokenId
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev Implementation of ERC721Enumerable
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Destroy (burn) the NFT
     * @param tokenId The ID of the token to burn
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the token
     * @param tokenId ID of the token to return URI of
     * @return URI for the token
     */
    function tokenURI(uint256 tokenId) public view
    override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Implementation of the ERC165 interface
     * @param interfaceId The Id of the interface to check support for
     */
    function supportsInterface(bytes4 interfaceId) public view
    override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}


/**
 * @title Farbe NFT sale contract
 * @dev Extension of the FarbeArt contract to add sale functionality
 */
contract FarbeArtSale is FarbeArt {
    /**
     * @dev Only allow owner to execute if no one (gallery) has been approved
     * @param _tokenId Id of the token to check approval and ownership of
     */
    modifier onlyOwnerOrApproved(uint256 _tokenId) {
        if(getApproved(_tokenId) == address(0)){
            require(ownerOf(_tokenId) == msg.sender, "Not owner or approved");
        } else {
            require(getApproved(_tokenId) == msg.sender, "Only approved can list, revoke approval to list yourself");
        }
        _;
    }

    /**
     * @dev Make sure the starting time is not greater than 60 days
     * @param _startingTime starting time of the sale in UNIX timestamp
     */
    modifier onlyValidStartingTime(uint64 _startingTime) {
        if(_startingTime > block.timestamp) {
            require(_startingTime - block.timestamp <= 60 days, "Start time too far");
        }
        _;
    }

    /**
     * @dev Set the primary platform cut on deployment
     * @param _platformCut Cut that the platform will take on primary sales
     */
    constructor(uint16 _platformCut) {
        platformCutOnPrimarySales = _platformCut;
    }

    function burn(uint256 tokenId) external {
        // must be owner
        require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

    /**
     * @dev Change the tokenUri of the token. Can only be changed when the creator is the owner
     * @param _tokenURI New Uri of the token
     * @param _tokenId Id of the token to change Uri of
     */
    function changeTokenUri(string memory _tokenURI, uint256 _tokenId) external {
        // must be owner and creator
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(tokenIdToDetails[_tokenId].tokenCreator == msg.sender, "Not creator");

        _setTokenURI(_tokenId, _tokenURI);

        emit TokenUriChanged(
            uint256(_tokenId),
            string(_tokenURI)
        );
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setAuctionContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AuctionSale auction = AuctionSale(_address);

        require(auction.isFarbeSaleAuction());

        auctionSale = auction;
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setFixedSaleContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FixedPriceSale fixedSale = FixedPriceSale(_address);

        require(fixedSale.isFarbeFixedSale());

        fixedPriceSale = fixedSale;
    }

    /**
     * @dev Set the address for the external auction contract. Can only be set by the admin
     * @param _address Address of the external contract
     */
    function setOpenOffersContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        OpenOffersSale openOffers = OpenOffersSale(_address);

        require(openOffers.isFarbeOpenOffersSale());

        openOffersSale = openOffers;
    }

    /**
     * @dev Set the percentage cut that the platform will take on all primary sales
     * @param _platformCut The cut that the platform will take on primary sales as %age * 10 for values < 1%
     */
    function setPlatformCut(uint16 _platformCut) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformCutOnPrimarySales = _platformCut;
    }

    /**
     * @dev Track artwork as sold before by updating the mapping. Can only be called by the sales contracts
     * @param _tokenId The id of the token which was sold
     */
    function setSecondarySale(uint256 _tokenId) external {
        require(msg.sender != address(0));
        require(msg.sender == address(auctionSale) || msg.sender == address(fixedPriceSale)
            || msg.sender == address(openOffersSale), "Caller is not a farbe sale contract");
        tokenIdToDetails[_tokenId].isSecondarySale = true;
    }

    /**
     * @dev Checks from the mapping if the token has been sold before
     * @param _tokenId ID of the token to check
     * @return bool Weather this is a secondary sale (token has been sold before)
     */
    function getSecondarySale(uint256 _tokenId) public view returns (bool) {
        return tokenIdToDetails[_tokenId].isSecondarySale;
    }

    /**
     * @dev Creates the sale auction for the token by calling the external auction contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingPrice Starting price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _duration The duration in seconds for the auction
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleAuction(
        uint256 _tokenId,
        uint128 _startingPrice,
        uint64 _startingTime,
        uint64 _duration,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // escrow the token into the auction smart contract
        safeTransferFrom(_seller, address(auctionSale), _tokenId);

        // call the external contract function to create the auction
        auctionSale.createSale(
            _tokenId,
            _startingPrice,
            _startingTime,
            _duration,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the fixed price sale for the token by calling the external fixed sale contract. Can only be called by owner.
     * Individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _fixedPrice Fixed price of the auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleFixedPrice(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // escrow the token into the auction smart contract
        safeTransferFrom(ownerOf(_tokenId), address(fixedPriceSale), _tokenId);

        // call the external contract function to create the auction
        fixedPriceSale.createSale(
            _tokenId,
            _fixedPrice,
            _startingTime,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }

    /**
     * @dev Creates the open offer sale for the token by calling the external open offers contract. Can only be called by owner,
     * individual external contract calls are expensive so a single function is used to pass all parameters
     * @param _tokenId ID of the token to put on auction
     * @param _startingTime Starting time of the auction in UNIX timestamp
     * @param _galleryCut The cut for the gallery, will be 0 if gallery is not involved
     */
    function createSaleOpenOffer(
        uint256 _tokenId,
        uint64 _startingTime,
        uint16 _galleryCut
    )
    external
    onlyOwnerOrApproved(_tokenId)
    onlyValidStartingTime(_startingTime)
    {
        // using struct to avoid 'stack too deep' error
        artworkDetails memory _details = artworkDetails(
            tokenIdToDetails[_tokenId].tokenCreator,
            tokenIdToDetails[_tokenId].creatorCut,
            false
        );

        require(_details.creatorCut + _galleryCut + platformCutOnPrimarySales < 1000, "Cuts greater than 100%");

        // get reference to owner before transfer
        address _seller = ownerOf(_tokenId);

        // determine gallery address (0 if called by owner)
        address _galleryAddress = ownerOf(_tokenId) == msg.sender ? address(0) : msg.sender;

        // escrow the token into the auction smart contract
        safeTransferFrom(ownerOf(_tokenId), address(openOffersSale), _tokenId);

        // call the external contract function to create the auction
        openOffersSale.createSale(
            _tokenId,
            _startingTime,
            _details.tokenCreator,
            _seller,
            _galleryAddress,
            _details.creatorCut,
            _galleryCut,
            platformCutOnPrimarySales
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FarbeArt.sol";

contract SaleBase is IERC721Receiver, AccessControl {
    using Address for address payable;

    // reference to the NFT contract
    FarbeArtSale public NFTContract;

    // address of the platform wallet to which the platform cut will be sent
    address internal platformWalletAddress;

    modifier onlyFarbeContract() {
        // check the caller is the FarbeNFT contract
        require(msg.sender == address(NFTContract), "Caller is not the Farbe contract");
        _;
    }

    /**
     * @dev Implementation of ERC721Receiver
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override virtual returns (bytes4) {
        // This will fail if the received token is not a FarbeArt token
        // _owns calls NFTContract
        require(_owns(address(this), _tokenId), "owner is not the sender");

        return this.onERC721Received.selector;
    }

    /**
     * @dev Internal function to check if address owns a token
     * @param _claimant The address to check
     * @param _tokenId ID of the token to check for ownership
     * @return bool Weather the _claimant owns the _tokenId
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (NFTContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev Internal function to transfer the NFT from this contract to another address
     * @param _receiver The address to send the NFT to
     * @param _tokenId ID of the token to transfer
     */
    function _transfer(address _receiver, uint256 _tokenId) internal {
        NFTContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @dev Internal function that calculates the cuts of all parties and distributes the payment among them
     * @param _seller Address of the seller
     * @param _creator Address of the original creator
     * @param _gallery Address of the gallery, 0 address if gallery is not involved
     * @param _creatorCut The cut of the original creator
     * @param _platformCut The cut that goes to the Farbe platform
     * @param _galleryCut The cut that goes to the gallery
     * @param _amount The total amount to be split
     * @param _tokenId The ID of the token that was sold
     */
    function _payout(
        address payable _seller,
        address payable _creator,
        address payable _gallery,
        uint16 _creatorCut,
        uint16 _platformCut,
        uint16 _galleryCut,
        uint256 _amount,
        uint256 _tokenId
    ) internal {
        // if this is a secondary sale
        if (NFTContract.getSecondarySale(_tokenId)) {
            // initialize amount to send to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale, wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)){
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // platform gets 2.5% on secondary sales (hard-coded)
            uint256 platformAmount = (25 * _amount) / 1000;
            // calculate amount to send to creator
            uint256 creatorAmount = (_creatorCut * _amount) / 1000;
            // calculate amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + creatorAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            payable(platformWalletAddress).sendValue(platformAmount);
            _creator.sendValue(creatorAmount);
            _seller.sendValue(sellerAmount);
        }
        // if this is a primary sale
        else {
            require(_seller == _creator, "Seller is not the creator");

            // dividing by 1000 because percentages are multiplied by 10 for values < 1%
            uint256 platformAmount = (_platformCut * _amount) / 1000;
            // initialize amount to be sent to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)) {
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // calculate the amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            _seller.sendValue(sellerAmount);
            payable(platformWalletAddress).sendValue(platformAmount);

            // set secondary sale to true
            NFTContract.setSecondarySale(_tokenId);
        }
    }

    /**
     * @dev External function to allow admin to change the address of the platform wallet
     * @param _address Address of the new wallet
     */
    function setPlatformWalletAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformWalletAddress = _address;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

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

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow immutable private _escrow;

    constructor () {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{ value: amount }(dest);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.AddressToUintMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.AddressToUintMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `address -> uint256` (`AddressToUintMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
    
    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

 /**
  * @title Escrow
  * @dev Base escrow contract, holds funds designated for a payee until they
  * withdraw them.
  *
  * Intended usage: This contract (and derived escrow contracts) should be a
  * standalone contract, that only interacts with the contract that instantiated
  * it. That way, it is guaranteed that all Ether will be handled according to
  * the `Escrow` rules, and there is no need to check for payable functions or
  * transfers in the inheritance tree. The contract that uses the escrow as its
  * payment method should be its owner, and provide public methods redirecting
  * to the escrow's deposit and withdraw.
  */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee] + amount;

        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./FarbeArtV3Upgradeable.sol";

contract SaleBaseV3Upgradeable is Initializable, IERC721ReceiverUpgradeable, AccessControlUpgradeable {
    using AddressUpgradeable for address payable;

    // reference to the NFT contract
    FarbeArtSaleV3Upgradeable public NFTContract;
    // struct for secondary sale
    struct saleDetail {
        bool isSecondarySale;
    }

    // mappings of tokenId against saleDetails struct
    mapping(uint256 => saleDetail) public tokenIdToSaleDetails;
    
    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    // address of the platform wallet to which the platform cut will be sent
    address internal platformWalletAddress;

    /**
     * @dev Implementation of ERC721Receiver
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override virtual returns (bytes4) {
        // This will fail if the received token is not a FarbeArt token
        // _owns calls NFTContract
        require(_owns(address(this), _tokenId), "owner is not the sender");

        return this.onERC721Received.selector;
    }

    /**
     * @dev Internal function to check if address owns a token
     * @param _claimant The address to check
     * @param _tokenId ID of the token to check for ownership
     * @return bool Weather the _claimant owns the _tokenId
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (NFTContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev Internal function to transfer the NFT from this contract to another address
     * @param _receiver The address to send the NFT to
     * @param _tokenId ID of the token to transfer
     */
    function _transfer(address _receiver, uint256 _tokenId) internal {
        NFTContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @dev Internal function that calculates the cuts of all parties and distributes the payment among them
     * @param _seller Address of the seller
     * @param _creator Address of the original creator
     * @param _gallery Address of the gallery, 0 address if gallery is not involved
     * @param _creatorCut The cut of the original creator
     * @param _platformCut The cut that goes to the Farbe platform
     * @param _galleryCut The cut that goes to the gallery
     * @param _amount The total amount to be split
     * @param _tokenId The ID of the token that was sold
     */
    function _payout(
        address payable _seller,
        address payable _creator,
        address payable _gallery,
        uint16 _creatorCut,
        uint16 _platformCut,
        uint16 _galleryCut,
        uint256 _amount,
        uint256 _tokenId
    ) internal {
        // if this is a secondary sale
        if (getSecondarySale(_tokenId)) {
            // initialize amount to send to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale, wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)){
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // platform gets 2.5% on secondary sales (hard-coded)
            uint256 platformAmount = (25 * _amount) / 1000;
            // calculate amount to send to creator
            uint256 creatorAmount = (_creatorCut * _amount) / 1000;
            // calculate amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + creatorAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            payable(platformWalletAddress).sendValue(platformAmount);
            _creator.sendValue(creatorAmount);
            _seller.sendValue(sellerAmount);
        }
        // if this is a primary sale
        else {
            require(_seller == _creator, "Seller is not the creator");

            // dividing by 1000 because percentages are multiplied by 10 for values < 1%
            uint256 platformAmount = (_platformCut * _amount) / 1000;
            // initialize amount to be sent to gallery, defaults to 0
            uint256 galleryAmount;
            // calculate gallery cut if this is a gallery sale wrapped in an if statement in case owner
            // accidentally sets a gallery cut
            if(_gallery != address(0)) {
                galleryAmount = (_galleryCut * _amount) / 1000;
            }
            // calculate the amount to send to the seller
            uint256 sellerAmount = _amount - (platformAmount + galleryAmount);

            // repeating if statement to follow check-effect-interaction pattern
            if(_gallery != address(0)) {
                _gallery.sendValue(galleryAmount);
            }
            _seller.sendValue(sellerAmount);
            payable(platformWalletAddress).sendValue(platformAmount);

            // set secondary sale to true
            setSecondarySale(_tokenId);
        }
    }

    /**
     * @dev External function to allow admin to change the address of the platform wallet
     * @param _address Address of the new wallet
    */
    function setPlatformWalletAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformWalletAddress = _address;
    }
    /**
     * @dev Internal function to update sale struct if sale is secondary sale
     * @param _tokenId ID of the token to check
    */
    function setSecondarySale(uint256 _tokenId) internal {
        require(msg.sender != address(0));
        tokenIdToSaleDetails[_tokenId].isSecondarySale = true;
    }

    /**
     * @dev Checks from the mapping if the token has been sold before
     * @param _tokenId ID of the token to check
     * @return bool Weather this is a secondary sale (token has been sold before)
    */
    function getSecondarySale(uint256 _tokenId) public view returns (bool) {
        return tokenIdToSaleDetails[_tokenId].isSecondarySale;
    }
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/escrow/EscrowUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPaymentUpgradeable is Initializable {
    EscrowUpgradeable private _escrow;

    function __PullPayment_init() internal initializer {
        __PullPayment_init_unchained();
    }

    function __PullPayment_init_unchained() internal initializer {
        _escrow = new EscrowUpgradeable();
        _escrow.initialize();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/OwnableUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract EscrowUpgradeable is Initializable, OwnableUpgradeable {
    function initialize() public virtual initializer {
        __Escrow_init();
    }
    function __Escrow_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Escrow_init_unchained();
    }

    function __Escrow_init_unchained() internal initializer {
    }
    using AddressUpgradeable for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}