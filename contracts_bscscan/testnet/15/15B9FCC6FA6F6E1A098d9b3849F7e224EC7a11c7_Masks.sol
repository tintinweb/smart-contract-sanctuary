// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;

import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IMasks.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";

/**
 * @title Hashmasks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Masks is Context, Ownable, ERC165, IMasks, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Public variables

    // This is the provenance record of all Hashmasks artwork in existence
    string public constant HASHMASKS_PROVENANCE = "df760c771ad006eace0d705383b74158967e78c6e980b35f670249b5822c42e1";

    uint256 public constant SALE_START_TIMESTAMP = 1614175200;

    // Time after which hash masks are randomized and allotted
    uint256 public constant REVEAL_TIMESTAMP = 1614175200;

    uint256 public constant NAME_CHANGE_PRICE = 0.05 ether;

    address public constant _oldContract = 0xA3A2Dc3cD182F8c86fa6e64cAa7182703e9ff1Dd;

    uint256 public _mintPrice = 0.25 ether;


    bool public _oldOwnersPayableMinting;

    uint256 public constant MAX_NFT_SUPPLY = 16384;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    // Mapping from token ID to whether the Hashmask was minted before reveal
    mapping (uint256 => bool) private _mintedBeforeReveal;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    string public _baseURI;


    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;


    bool tradingEnabled = false;

    struct Offer {
        bool isForSale;
        uint maskIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint maskIndex;
        address bidder;
        uint value;
    }

    // A record of masks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public maskOfferedForSale;

    // A record of the highest mask bid
    mapping (uint => Bid) public maskBids;

    mapping (address => uint) public pendingWithdrawals;

    // Events
    event NameChange (uint256 indexed maskIndex, string newName);
    event MaskTransfer(address indexed from, address indexed to, uint256 maskIndex);
    event MaskOffered(uint indexed maskIndex, uint minValue, address indexed toAddress);
    event MaskBidEntered(uint indexed maskIndex, uint value, address indexed fromAddress);
    event MaskBidWithdrawn(uint indexed maskIndex, uint value, address indexed fromAddress);
    event MaskBought(uint indexed maskIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event MaskNoLongerForSale(uint indexed maskIndex);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol, address cOwner, string memory _uri) Ownable(cOwner) {
        _name = name;
        _symbol = symbol;
        _baseURI = _uri;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }


    function setMintPrice(uint256 newprice) public onlyOwner {
        _mintPrice = newprice;
    }


    function setBaseUri(string memory _newuri) public onlyOwner {
        _baseURI = _newuri;
    }

    function setOldMinting() public onlyOwner {
        if (_oldOwnersPayableMinting) {
            _oldOwnersPayableMinting = false;
        } else {
            _oldOwnersPayableMinting = true;
        }
    }



    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }



    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0));

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Returns if the NFT has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }


    function checkOldOwner(uint256 tokenId) internal view returns (address account, bool success) {
        try IERC721(_oldContract).ownerOf(tokenId) returns (address v) {
            return (v, true);
        } catch Error(string memory /*reason*/) {
            return (address(0), false);
        } catch (bytes memory /*lowLevelData*/) {
            return (address(0), false);
        }
    }


    /**
    * @dev Mints Masks
    */
    function mintNFT(uint256 _id) public payable {
        require(!_exists(_id), "Token is already minted");
        require(_id <= MAX_NFT_SUPPLY);
        (address oldOwner, bool result) = checkOldOwner(_id);
        if (result == true) {
            require((oldOwner == _msgSender() ||
                     oldOwner == 0x24CFfAB280b4758bd5c4F32f5044d24799D1FC3E ||
                     oldOwner == 0xb28043641e00bC54457f92838E53CE6b34f68574), "You cannot mint this token");
            if (oldOwner != _msgSender() || _oldOwnersPayableMinting) {
                require(_mintPrice == msg.value, "Insufficient amount to mint token");
            }
        } else {
            require(_mintPrice == msg.value, "Insufficient amount to mint token");
        }
        _safeMint(_msgSender(), _id);

        if (block.timestamp < REVEAL_TIMESTAMP) {
            _mintedBeforeReveal[_id] = true;
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
        if (msg.value > 0) {
            payable(owner()).transfer(msg.value);
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0);
        require(startingIndexBlock != 0);

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Changes the name for Hashmask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public payable {
        address tokenOwner = ownerOf(tokenId);
        require(msg.value == NAME_CHANGE_PRICE, "Invalid amount sent.");
        require(_msgSender() == tokenOwner);
        require(validateName(newName) == true);
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])));
        require(isNameReserved(newName) == false);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
        payable(owner()).transfer(msg.value);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdrawOwner() onlyOwner public {
        require(tradingEnabled == false);
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
        if(totalSupply() == MAX_NFT_SUPPLY){
            tradingEnabled = true;
        }
    }



    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner);

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()));

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId));

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender());

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));

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
        require(_isApprovedOrOwner(_msgSender(), tokenId));
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
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId));
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
        require(_checkOnERC721Received(address(0), to, tokenId, _data));
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
        require(to != address(0));
        require(!_exists(tokenId));

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    // MARKETPLACE
    function maskNoLongerForSale(uint maskIndex) public{
        require(tradingEnabled);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) == msg.sender);
        require(maskIndex < MAX_NFT_SUPPLY);

        maskOfferedForSale[maskIndex] = Offer(false, maskIndex, msg.sender, 0, address(0x0));
        MaskNoLongerForSale(maskIndex);
    }

    function offerMaskForSale(uint maskIndex, uint minSalePriceInWei) public {
        require(tradingEnabled);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) == msg.sender);
        require(maskIndex < MAX_NFT_SUPPLY);

        maskOfferedForSale[maskIndex] = Offer(true, maskIndex, msg.sender, minSalePriceInWei, address(0x0));
        MaskOffered(maskIndex, minSalePriceInWei, address(0x0));
    }
    function offerMaskForSaleToAddress(uint maskIndex, uint minSalePriceInWei, address toAddress) public {
        require(tradingEnabled);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) == msg.sender);
        require(maskIndex < MAX_NFT_SUPPLY);

        maskOfferedForSale[maskIndex] = Offer(true, maskIndex, msg.sender, minSalePriceInWei, toAddress);
        MaskOffered(maskIndex, minSalePriceInWei, toAddress);
    }

    function withdraw() public {
        require(tradingEnabled);
        require(totalSupply() == MAX_NFT_SUPPLY);

        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForMask(uint maskIndex) public payable {
        require(tradingEnabled);
        require(maskIndex < MAX_NFT_SUPPLY);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) != address(0x0));
        require(ownerOf(maskIndex) != msg.sender);

        require(msg.value != 0);
        Bid memory existing = maskBids[maskIndex];
        require(msg.value > existing.value);

        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        maskBids[maskIndex] = Bid(true, maskIndex, msg.sender, msg.value);
        MaskBidEntered(maskIndex, msg.value, msg.sender);
    }


    function acceptBidForMask(uint maskIndex, uint minPrice) public{
        require(tradingEnabled);
        require(maskIndex < MAX_NFT_SUPPLY);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) == msg.sender);

        address seller = msg.sender;
        Bid memory bid = maskBids[maskIndex];
        require(bid.value != 0);
        require(bid.value >= minPrice);


        safeTransferFrom(seller, bid.bidder, maskIndex);

        maskOfferedForSale[maskIndex] = Offer(false, maskIndex, bid.bidder, 0, address(0x0));
        uint amount = bid.value;
        maskBids[maskIndex] = Bid(false, maskIndex, address(0x0), 0);
        pendingWithdrawals[seller] += amount;
        MaskBought(maskIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForMask(uint maskIndex) public {
        require(tradingEnabled);
        require(maskIndex < MAX_NFT_SUPPLY);
        require(totalSupply() == MAX_NFT_SUPPLY);
        require(ownerOf(maskIndex) != address(0x0));
        require(ownerOf(maskIndex) != msg.sender);


        Bid memory bid = maskBids[maskIndex];

        require(bid.bidder == msg.sender);

        MaskBidWithdrawn(maskIndex, bid.value, msg.sender);
        uint amount = bid.value;
        maskBids[maskIndex] = Bid(false, maskIndex, address(0x0), 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }


}