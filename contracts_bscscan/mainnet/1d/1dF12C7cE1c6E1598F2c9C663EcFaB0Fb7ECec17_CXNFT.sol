// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

/* 
    Contributors: Nitish Devadiga, CX
*/

contract CXNFT is ERC1155Upgradeable {
    address payable public contractOwner;

    modifier onlyContractOwner {
        require(address(contractOwner) == msg.sender, "UNAUTHORIZED");
        _;
    }

    // enum for different types of listings possible. none = not listed
    enum LISTING_TYPE {
        NONE,
        FIXED_PRICE, 
        AUCTION 
    }

    // CX's commission on every trade of NFT
    uint public commissionPercentage = 200; // = 2%; 100% = 10000

    // do not apply commission to excluded addresses
    mapping (address => bool) public commissionExclusionAddresses;

    // minter and royalty percentage only gets set when minted
    mapping (uint256 => uint) private _royaltyPercentage; // basis points (10000ths, instead of 100ths); 1% = 100; 100% = 10000
    mapping (uint256 => address) private _minter;

    struct Listing {
        bool exists; // just a check field
        LISTING_TYPE listingType;
        uint listedQuantity; // max quantity that others can purchase (0 <= listedQuantity <= tokenBalance)
        uint price; // price per asset
        uint cxUser; // cryptoxpress user id
        bool isReserved; // specific to auction. do not return price of asset if reserved and listed as auction
        uint endTime; // auction endtime
        address approvedBidder; // approved address who could buy the token in an auction listing
    }

    mapping (uint256 => mapping(address => Listing)) private _listings;
    
    // Using the below struct to avoid Stack too deep error in Mint Function (used as parameter)
    struct MintData {
        uint256 tokenId;
        address toAddress;
        uint quantity;
        bytes data;
        uint price;
        LISTING_TYPE listingType;
        uint listQuantity;
        uint royaltyPc;
        uint endTime;
        bool isReserved;
        uint cxUser;
    }
    
    struct BuyData {
        uint tokenId;
        uint quantity;
        address fromAddress;
        uint cxUser;
    }

    // Using the below struct to avoid Stack too deep error
    struct TradeInfo {
        address payable _buyer;
        address payable _owner;
        address payable _minterPayable;
        uint _amount;
        uint _totalPrice;
        uint _royalty;
        uint _commission;
        uint pricePayable;
    }

    uint256 totalMinted; // number of unique tokens minted

    // All events will include cxUser id, which indicates the user (from cx server) who initiated the transaction

    event Purchase(address indexed from, address indexed to, uint totalPrice, uint royalty, uint commission, uint quantity, uint nftId, string uri, uint cxUser);

    event Minted(address indexed minter, uint price, uint nftId, uint quantity, string uri, uint cxUser);

    // only emitted when updating FIXED_PRICE listing
    event PriceUpdate(address indexed owner, uint oldPrice, uint newPrice, uint nftId, uint cxUser);

    // only emitted when updating FIXED_PRICE listing
    event ListedQuantityUpdate(address indexed owner, uint oldQuantity, uint newQuantity, uint nftId, uint cxUser);

    // only emitted when updating/removing bidder and bid in AUCTION listing. When bidder updated, type will be 'ADDED', when removed type will be 'REMOVED'
    // contains event only bidId which is the Id of bid placed in client
    event BidderUpdate(address indexed owner, uint bidId, address indexed bidder, uint bid, uint nftId, string updateType, uint cxUser);

    event NftListStatus(address indexed owner, uint nftId, LISTING_TYPE listingType, uint listedQuantity, uint price, uint endTime, bool isReserved, uint cxUser);

    function initialize() public initializer {
        __ERC1155_init("https://nft.cryptoxpress.com/{id}");
        contractOwner = payable(msg.sender);
        totalMinted = 0;
    }
    
    /**
     * Overriding ERC1155Upgradable Function
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
       // create to listing
       _listings[id][to].exists = true;
       emit Purchase(from, to, 0, 0, 0, amount, id, uri(id), 0);
       // update from listing
        if (_listings[id][from].listingType == LISTING_TYPE.FIXED_PRICE) {
            uint remainingQuantity = _listings[id][from].listedQuantity - amount;
            if (remainingQuantity > 0) {
                uint oldQuantity = _listings[id][from].listedQuantity;
                _listings[id][from].listedQuantity = remainingQuantity;
                emit ListedQuantityUpdate(from, oldQuantity, remainingQuantity, id, 0);
            }else{
                clearListing(id, from, 0);
            }
        } else{
            clearListing(id, from, 0);
        }
    }

    /**
     * Overriding ERC1155Upgradable Function
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        // clear listings for all assets
        uint arrayLength = ids.length;
        for (uint i=0; i<arrayLength; i++) {
          clearListing(ids[i], from, 0);
        }
    }

    function updateCommission(uint _commission) public onlyContractOwner returns (bool) {
        commissionPercentage = _commission;
        return true;
    }

    function addToCommissionExclusion(address _address) public onlyContractOwner returns (bool) {
        commissionExclusionAddresses[_address] = true;
        return true;
    }

    function removeFromCommissionExclusion(address _address) public onlyContractOwner returns (bool) {
        commissionExclusionAddresses[_address] = false;
        return true;
    }

    // return minter of the token
    function minterOf(uint256 _tokenId) public view returns (address) {
        address minter = _minter[_tokenId];
        require(minter != address(0), "NONEXISTENT TOKEN");
        return minter;
    }

    // returns false if listing type is none, else true
    function addresssHasTokenListed(address _owner, uint256 _tokenId) public view returns (bool) {
        require(_listings[_tokenId][_owner].exists, "NOT OWNER");
        return _listings[_tokenId][_owner].listingType != LISTING_TYPE.NONE;
    }

    // Check if tokenId exists
    function tokenExists(uint256 tokenId) public view virtual returns (bool) {
        return _minter[tokenId] != address(0);
    }

    function _validateExistingListing(uint _tokenId,address _address) internal view {
        require(_listings[_tokenId][_address].exists, "NOT OWNER");
        require(_listings[_tokenId][_address].listingType != LISTING_TYPE.NONE, "NOT FOR SALE");
    }

    function _validateBidder(uint _tokenId,address _address) internal view {
        require(_listings[_tokenId][_address].exists, "NOT OWNER");
        require(_listings[_tokenId][_address].listingType == LISTING_TYPE.AUCTION, "MUST BE AUCTION");
    }

    function list(uint _tokenId, uint _price, uint _listQuantity, LISTING_TYPE _listingType, uint _endTime, bool _isReserved, uint _cxUser) public returns (bool) {
        // check if user has token and make it exist in this contract if was not already
        if (balanceOf(msg.sender, _tokenId) > 0) {
            _listings[_tokenId][msg.sender].exists = true;
        }
        require(_listings[_tokenId][msg.sender].exists, "NOT OWNER");
        require(_listingType == LISTING_TYPE.FIXED_PRICE || _listingType  == LISTING_TYPE.AUCTION, "INVALID LISTING TYPE");
        require(_price > 0 && _listQuantity > 0, "Price and List Quantity must be greater than 0");
        // balance must be >= than amount to be listed
        require(balanceOf(msg.sender, _tokenId) >= _listQuantity, "INSUFFICIENT QTY");
        // Modify listing properties
        _listings[_tokenId][msg.sender].listingType = _listingType;
        _listings[_tokenId][msg.sender].listedQuantity = _listQuantity;
        _listings[_tokenId][msg.sender].price = _price;
        _listings[_tokenId][msg.sender].endTime = _endTime;
        _listings[_tokenId][msg.sender].isReserved = _isReserved;
        _listings[_tokenId][msg.sender].cxUser = _cxUser;
        delete _listings[_tokenId][msg.sender].approvedBidder;
        emit NftListStatus(msg.sender, _tokenId, _listingType, _listQuantity, _price, _endTime, _isReserved, _cxUser);
        return true;
    }

    function clearListing(uint _tokenId, address _address, uint _cxUser) internal returns (bool) {
        // Delete listing properties, and set listing type to None
        _listings[_tokenId][_address].listingType = LISTING_TYPE.NONE;
        delete _listings[_tokenId][_address].listedQuantity;
        delete _listings[_tokenId][_address].price;
        delete _listings[_tokenId][_address].isReserved;
        delete _listings[_tokenId][_address].endTime;
        delete _listings[_tokenId][_address].approvedBidder;
        emit NftListStatus(_address, _tokenId, LISTING_TYPE.NONE, 0, 0, 0, false, _cxUser);
        return true;
    }

    function delist(uint _tokenId, uint _cxUser) public returns (bool) {
        _validateExistingListing(_tokenId, msg.sender);
        require(balanceOf(msg.sender, _tokenId) > 0, "NONE LISTED");
        return clearListing(_tokenId, msg.sender, _cxUser);
    }
    
    function getListingDetails(uint _tokenId, address _address) public view returns (Listing memory) {
        return _listings[_tokenId][_address];
    }

    // Approve a bidder and update price to match their bid
    // bid is price per asset and not on the entire listed quantity
    function updateApprovedBidder(uint _tokenId, address _bidder, uint _bid, uint _bidId, uint _cxUser) public returns (bool) {
        _validateBidder(_tokenId, msg.sender);
        require(msg.sender != _bidder, "CANNOT SELF APPROVE");
        require(_listings[_tokenId][msg.sender].approvedBidder != _bidder, "ALREADY APPROVED");
        _listings[_tokenId][msg.sender].approvedBidder = _bidder;
        _listings[_tokenId][msg.sender].price = _bid;
        emit BidderUpdate(msg.sender, _bidId, _bidder, _bid, _tokenId, "ADDED", _cxUser);
        return true;
    }

    function removeApprovedBidder(uint _tokenId, uint _bidId, uint _cxUser) public returns (bool) {
        _validateBidder(_tokenId, msg.sender);
        address _bidder =  _listings[_tokenId][msg.sender].approvedBidder;
        uint _bid =  _listings[_tokenId][msg.sender].price;
        delete _listings[_tokenId][msg.sender].approvedBidder;
        emit BidderUpdate(msg.sender, _bidId, _bidder, _bid, _tokenId, "REMOVED", _cxUser);
        return true;
    }

    function getTokenPrice(address _owner, uint _tokenId) public view returns (uint) {
        return _listings[_tokenId][_owner].price;
    }

    // Mint token and create a listing
    function mint(MintData memory _data) public returns (uint) {
        require(!tokenExists(_data.tokenId), "TokenID already exists");
        _mint(_data.toAddress, _data.tokenId, _data.quantity, _data.data); // ERC1155 method
        totalMinted += 1;
        _minter[_data.tokenId] = _data.toAddress;
        _royaltyPercentage[_data.tokenId] = _data.royaltyPc;
        emit Minted(_data.toAddress, _data.price, _data.tokenId, _data.quantity, uri(_data.tokenId), _data.cxUser);
        // create listing
        _listings[_data.tokenId][_data.toAddress].exists = true;
        _listings[_data.tokenId][_data.toAddress].listingType = LISTING_TYPE.NONE;
        _listings[_data.tokenId][_data.toAddress].cxUser = _data.cxUser;
        if (_data.toAddress == msg.sender) {
            // update listing according to params if sender is the minter
            if (_data.listingType == LISTING_TYPE.FIXED_PRICE || _data.listingType == LISTING_TYPE.AUCTION) {
                list(_data.tokenId, _data.price, _data.listQuantity, _data.listingType, _data.endTime, _data.isReserved, _data.cxUser);
            }
        }
        return _data.tokenId;
    }

    function buy(BuyData memory _data) external payable {
        // --- Validations ---
        require(msg.sender != _data.fromAddress, "CANNOT PURCHASE FROM SELF");
        _validateExistingListing(_data.tokenId, _data.fromAddress);
        // double check owner's balance
        require(balanceOf(_data.fromAddress, _data.tokenId) >= _data.quantity, "SELLER HAS INSUFFICIENT TOKENS");
        if (_listings[_data.tokenId][_data.fromAddress].listingType == LISTING_TYPE.AUCTION) {
            // check approval
            require(_listings[_data.tokenId][_data.fromAddress].approvedBidder == msg.sender, "BUYER NOT APPROVED");
            require(_listings[_data.tokenId][_data.fromAddress].listedQuantity <= _data.quantity, "FRACTIONAL AUCTION NOT SUPPORTED");
        } else {
            require(_listings[_data.tokenId][_data.fromAddress].listedQuantity >= _data.quantity, "INSUFFICIENT QTY");
        }
        // --- End of Validations ---
        trade(_data.tokenId, _data.quantity, _data.fromAddress, _data.cxUser);
    }

    function trade(uint _tokenId, uint _quantity, address _from, uint _cxUser) internal {
        TradeInfo memory tradeInfo;
        tradeInfo._owner = payable(_from);
        tradeInfo._buyer = payable(msg.sender);
        tradeInfo._minterPayable = payable(_minter[_tokenId]);
        if (_listings[_tokenId][_from].listingType == LISTING_TYPE.AUCTION) {
            // all listed quantity should be sold
            require(_quantity == _listings[_tokenId][_from].listedQuantity, "INSUFFICIENT QTY");
        } 
        tradeInfo._amount = _quantity;
        // get total price from listed price
        tradeInfo._totalPrice = _listings[_tokenId][_from].price * tradeInfo._amount;
         // check if sufficient funds were sent with the transaction
        if (msg.value < tradeInfo._totalPrice){
            revert("INSUFFICIENT FUNDS");
        }
        // Transfer the token
        _safeTransferFrom(tradeInfo._owner, tradeInfo._buyer, _tokenId, tradeInfo._amount, "");
        tradeInfo._royalty = 0;
        // get royalty if neither buyer nor seller is the minter 
        if (_minter[_tokenId] != _from && _minter[_tokenId] != msg.sender) {
            tradeInfo._royalty = tradeInfo._totalPrice * _royaltyPercentage[_tokenId] / 10000;
        }
        tradeInfo._commission = 0;
        // get commission if buyer not excluded
        if (commissionExclusionAddresses[msg.sender] != true) {
            tradeInfo._commission = tradeInfo._totalPrice * commissionPercentage / 10000;
        }
        tradeInfo.pricePayable = tradeInfo._totalPrice - tradeInfo._royalty - tradeInfo._commission;
        // Transfer funds to seller
        tradeInfo._owner.transfer(tradeInfo.pricePayable);
        if (tradeInfo._royalty > 0) {
            // Transfer royalty to minter
            tradeInfo._minterPayable.transfer(tradeInfo._royalty);
        }
        if (tradeInfo._commission > 0) {
             // Transfer commission to CX
            contractOwner.transfer(tradeInfo._commission);
        }
        
        emit Purchase(_from, msg.sender, tradeInfo._totalPrice, tradeInfo._royalty, tradeInfo._commission, tradeInfo._amount, _tokenId, uri(_tokenId), _cxUser);
        if (msg.value > tradeInfo._totalPrice) {
             // Revert the extra amount sent in transaction back to buyer
            tradeInfo._buyer.transfer(msg.value - tradeInfo._totalPrice);
        }

        // --- Post Purchase Modifications ---
        // create a listing for buyer
        _listings[_tokenId][msg.sender].exists = true;
        _listings[_tokenId][msg.sender].cxUser = _cxUser;
        // update seller listing
        if (_listings[_tokenId][_from].listingType == LISTING_TYPE.FIXED_PRICE) {
            uint remainingQuantity = _listings[_tokenId][_from].listedQuantity - tradeInfo._amount;
            if (remainingQuantity > 0) {
                uint oldQuantity = _listings[_tokenId][_from].listedQuantity;
                _listings[_tokenId][_from].listedQuantity = remainingQuantity;
                emit ListedQuantityUpdate(_from, oldQuantity, remainingQuantity, _tokenId, 0);
            }else{
                clearListing(_tokenId, _from, 0);
            }
        }else{
            clearListing(_tokenId, _from, 0);
        }
         // --- End of Post Purchase Modifications ---
    }

    // Update Price per asset and/or Listed Quantity if listing is FIXED_PRICE
    function updateListing(uint _tokenId, uint _price, uint _listQuantity, uint _cxUser) public returns (bool) {
        require(balanceOf(msg.sender, _tokenId) > 0, "NO TOKENS OWNED");
        _validateExistingListing(_tokenId, msg.sender);
        require(_price > 0 && _listQuantity > 0, "Price and List Quantity must be greater than 0");
        // balance must be >= than amount to be listed
        require(balanceOf(msg.sender, _tokenId) >= _listQuantity, "INSUFFICIENT QTY");
        if (_listings[_tokenId][msg.sender].listingType == LISTING_TYPE.AUCTION) {
            revert("DELIST TO CHANGE PRICE");
        }
        if (_listings[_tokenId][msg.sender].listingType == LISTING_TYPE.FIXED_PRICE) {
            // Only allow price and list quantity update here
            uint oldPrice = _listings[_tokenId][msg.sender].price;
            uint oldQuantity = _listings[_tokenId][msg.sender].listedQuantity;
            _listings[_tokenId][msg.sender].price = _price;
            emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId, _cxUser);
            _listings[_tokenId][msg.sender].listedQuantity = _listQuantity;
            emit ListedQuantityUpdate(msg.sender, oldQuantity, _listQuantity, _tokenId, _cxUser);
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
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