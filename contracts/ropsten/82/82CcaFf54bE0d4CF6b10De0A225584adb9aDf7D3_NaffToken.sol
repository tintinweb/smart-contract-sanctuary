// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DelegateContract is Ownable, IERC721Receiver
{
    address public authorizedCaller;
    
    event TransactionCompleted(address _erc20TokenContract, address _erc721TokenContract, address _seller, address _buyer, uint256 _erc20TokenAmount, uint256 _erc721TokenId, uint256 _quantity, PricingType _pricingType);
    event ERC20TransferCompleted(address _erc20TokenContract, address _from, address _to, uint256 _amount);
    event ERC721TransferCompleted(address _erc721TokenContract, address _from, address _to, uint256 _tokenId);
    event ERC1155TransferCompleted(address _erc1155TokenContract, address _from, address _to, uint256 _tokenId, uint256 _quantity, bytes data);
    event BidPlaced(address _erc20TokenAddress, address _nftTokenAddress, address _previousBidder, address _currentBidder, uint256 _previousBid, uint256 _currentBid, uint256 _tokenId, string _userId);
    event OrderCreated(address _erc20TokenAddress, address _nftTokenAddress, uint256 _tokenId, uint256 _quantity, TokenType _tokenType, uint256 _startingBid, address _creator, string _userId, PricingType _paymentMode, uint256 _startTime, uint256 _endTime);
    event OrderClosed(address _nftTokenAddress, uint256 _tokenId, uint256 _quantity, TokenType _tokenType, address _creator, string _userId, PricingType _paymentMode);

    enum TokenType{
        Undefined,
        ERC721,
        ERC1155
    }
    
    enum TransactionType
    {
        Undefined,
        INSTANT_BUY,
        BID
    }
    
    enum PricingType
    {
        Undefined,
        INSTANT_BUY,
        TIMED_AUCTION,
        UNLIMITED_AUCTION
    }
    
    struct Bid { 
        address highestBidder;
        uint256 highestBid;
        bool isOpen;
        uint256 quantity;
        address erc20TokenAddress;
        address creator;
        PricingType pricingType;
        uint256 startDate;
        uint256 endDate;
        uint256 bidsPlaced;
    }

    struct UserBid{
        uint256 PreviousBid;
        uint256 CurrentBid;
        uint256 Quantity;
        
    }
    

    struct SaleItem {
        address seller;
        uint256 price;
        bool isOpen;
        uint256 quantity;
        address erc20TokenAddress;                                                                                                                
    }
    

    mapping(address => mapping(uint256 => Bid)) public bidDetails;
   mapping(address => mapping(uint256 => SaleItem)) public instantBuyDetails;
   mapping(address => mapping(uint256 => mapping(address => Bid))) userBidDetails;
    
   constructor(address _authorizedCaller) {
        authorizedCaller = _authorizedCaller;
    }
    
   modifier onlyAuthorizedCaller()
   {
        require (msg.sender == authorizedCaller, "Only an authorized address can access functions in this contract");
        _;
    }
    
   function instantBuy(address _nftTokenAddress, TokenType _tokenType, uint256 _tokenId, uint256 _quantity, bytes memory _data) public 
   {
       address _buyer =  msg.sender;
       SaleItem memory saleItem = instantBuyDetails[_nftTokenAddress][_tokenId];
       address erc20TokenAddress = saleItem.erc20TokenAddress;
       address seller = saleItem.seller;
       uint256 price = saleItem.price;
       uint256 quantity = saleItem.quantity;
       require(_quantity <= quantity, "The QuantIty to purchase must be less than quantity offered for sale.");
       require(saleItem.isOpen, "Order is not Open. Make sure that the Owner of the token has offered it up for sale");
       transferERC20(erc20TokenAddress, msg.sender, seller, price * _quantity);
       if(_tokenType == TokenType.ERC721){
            IERC721 _erc721Contract = IERC721(_nftTokenAddress);
            _erc721Contract.safeTransferFrom(address(this), msg.sender, _tokenId);
            saleItem = SaleItem(address(0), 0, false, 0, address(0));
            instantBuyDetails[_nftTokenAddress][_tokenId] = saleItem;
            emit TransactionCompleted(erc20TokenAddress, _nftTokenAddress, seller, msg.sender, price, _tokenId, 1, PricingType.INSTANT_BUY);
       }
       else if(_tokenType == TokenType.ERC1155)
       {
            IERC1155 _erc1155Contract = IERC1155(_nftTokenAddress);
            _erc1155Contract.safeTransferFrom(saleItem.seller, msg.sender, _tokenId, saleItem.quantity, _data);
            saleItem.quantity -= _quantity;
            if (saleItem.quantity == 0){
                saleItem = SaleItem(address(0), 0, false, 0, address(0));
                instantBuyDetails[_nftTokenAddress][_tokenId] = saleItem;
            }
   
           emit TransactionCompleted(erc20TokenAddress, _nftTokenAddress, seller, msg.sender, price, _tokenId, _quantity, PricingType.INSTANT_BUY);
       }
       else{
           revert("NFT Token Type must be specified");
       }
   }
   
   function transferERC20(address _erc20TokenContract, address _from, address _to, uint256 _amount) public 
   {
       require(msg.sender == _from || msg.sender == authorizedCaller, "Not authorized");
       IERC20 _erc20Contract = IERC20(_erc20TokenContract);
       _erc20Contract.transferFrom(_from, _to, _amount);
       emit ERC20TransferCompleted(_erc20TokenContract, _from, _to, _amount);
   }
   
   function transferERC721(address _erc721TokenContract, address _from, address _to, uint256 _tokenId) public 
   {
       require(msg.sender == _from || msg.sender == authorizedCaller, "Not authorized");
       IERC721 _erc721Contract = IERC721(_erc721TokenContract);
       _erc721Contract.safeTransferFrom(_from, _to, _tokenId);
       emit ERC721TransferCompleted(_erc721TokenContract, _from, _to, _tokenId);
   }
   
   function transferERC1155(address _erc1155TokenContract, address _from, address _to, uint256 _tokenId, uint256 _quantity, bytes memory _data) public 
   {
       require(msg.sender == _from || msg.sender == authorizedCaller, "Not authorized");
       IERC1155 _erc1155Contract = IERC1155(_erc1155TokenContract);
       _erc1155Contract.safeTransferFrom(_from, _to, _tokenId, _quantity, _data);
       emit ERC1155TransferCompleted(_erc1155TokenContract, _from, _to, _tokenId, _quantity, _data);
   }
   
   function OfferForSale(address _erc20TokenAddress, address _nftTokenAddress, uint256 _tokenId, uint256 _quantity, TokenType _tokenType, uint256 _startingPrice, string memory _userId, PricingType _pricingType, uint256 _startTime, uint256 _endTime) public
   {
       Bid memory bid = bidDetails[_nftTokenAddress][_tokenId];
       SaleItem memory saleItem = instantBuyDetails[_nftTokenAddress][_tokenId];

       require(!bid.isOpen && !saleItem.isOpen, "Bid for the token is currently active");

       if(_tokenType == TokenType.ERC721)
       {
           IERC721 erc721TokenContract = IERC721(_nftTokenAddress);
           require(erc721TokenContract.ownerOf(_tokenId) == msg.sender, "Bid Creator must be Owner of token");
           transferERC721(_nftTokenAddress, msg.sender, address(this), _tokenId);
           bid.quantity = 1;
       }else if(_tokenType == TokenType.ERC1155)
       {
           IERC1155 erc1155TokenContract = IERC1155(_nftTokenAddress);
           require(erc1155TokenContract.balanceOf(msg.sender, _tokenId) >= _quantity, "Quantity of tokens to bid exceeds balance");
           bid.quantity = _quantity;
           
       }else{
           revert("Token type is not valid. Must be ERC721 Or ERC1155");
       }
       
       if(_pricingType == PricingType.UNLIMITED_AUCTION || _pricingType == PricingType.TIMED_AUCTION){
           
           bid.erc20TokenAddress = _erc20TokenAddress;
            bid.creator = msg.sender;
            bid.highestBid = _startingPrice;
            bid.isOpen = true;
            bid.pricingType = _pricingType;
            bid.startDate = _startTime;
            bid.endDate = _endTime;
            bidDetails[_nftTokenAddress][_tokenId] = bid;

       }else if(_pricingType == PricingType.INSTANT_BUY)
       {
           saleItem.price = _startingPrice;
           saleItem.seller = msg.sender;
           saleItem.quantity = _quantity;
           saleItem.erc20TokenAddress = _erc20TokenAddress;
           saleItem.isOpen = true;
           instantBuyDetails[_nftTokenAddress][_tokenId] = saleItem;
       }else
       {
            revert("Pricing type must either be an auction or instant buy.");
       }
      
      emit OrderCreated( _erc20TokenAddress,  _nftTokenAddress,  _tokenId,  _quantity,  _tokenType,  _startingPrice,  msg.sender,  _userId,  _pricingType, _startTime, _endTime);
   }
   
   function placeBid(address _nftTokenAddress, uint256 _currentBid, uint256  _tokenId, uint256 _quantity, string memory _userId) public 
   {
       Bid memory bid = bidDetails[_nftTokenAddress][_tokenId];
       address _previousBidder = bid.highestBidder;
       uint256 _previousBid = bid.highestBid;
        require(_currentBid > bid.highestBid, "current bid must Me more than previous bid");
       
       IERC20 erc20Contract = IERC20(bid.erc20TokenAddress);
       erc20Contract.transferFrom(msg.sender, address(this), _currentBid);

       if(_previousBidder != address(0))
       {
           erc20Contract.transfer(_previousBidder, _previousBid);
       }
       bid.highestBidder = msg.sender;
       bid.highestBid = _currentBid;
       bid.bidsPlaced++;
       bidDetails[_nftTokenAddress][_tokenId] = bid;
       emit BidPlaced(bid.erc20TokenAddress, _nftTokenAddress, _previousBidder, msg.sender, _previousBid, _currentBid, _tokenId, _userId);
   }
   
   function closeBid(address _nftTokenAddress, uint256 _tokenId, TokenType _tokenType, bytes memory _data) public 
   {
      Bid memory bid = bidDetails[_nftTokenAddress][_tokenId];
      require(msg.sender == bid.creator || msg.sender == authorizedCaller, "Not authorized caller");
      IERC20 _erc20Contract = IERC20(bid.erc20TokenAddress);
      _erc20Contract.transfer(bid.creator, bid.highestBid);
      require(bid.pricingType == PricingType.UNLIMITED_AUCTION || bid.pricingType == PricingType.TIMED_AUCTION, "Must be timed or unlimited auction");
      
      if (_tokenType == TokenType.ERC721)
      {
          IERC721 _erc721Contract = IERC721(_nftTokenAddress);
          _erc721Contract.safeTransferFrom(address(this), bid.highestBidder, _tokenId);
      }
      else if (_tokenType == TokenType.ERC1155)
      {
        IERC1155 _erc1155Contract = IERC1155(_nftTokenAddress);
       _erc1155Contract.safeTransferFrom(address(this), bid.highestBidder, _tokenId, bid.quantity, _data);
      }else
      {
          revert("Token type must be specified");
      }
      
      bid = Bid(address(0), 0, false, 0, address(0), address(0), PricingType.Undefined, 0, 0, 0);
      emit TransactionCompleted(bid.erc20TokenAddress, _nftTokenAddress, bid.creator, bid.highestBidder, bid.highestBid, _tokenId, bid.quantity, bid.pricingType);
   }
   
   function closeOrder(address _nftTokenAddress, uint256 _tokenId, TokenType _tokenType, string memory _userId) public
   {
       SaleItem memory saleItem = instantBuyDetails[_nftTokenAddress][_tokenId];
       Bid memory bid = bidDetails[_nftTokenAddress][_tokenId];
       uint256 quantity = 0;
       PricingType pricingType = PricingType.Undefined;

       if(bid.isOpen && bid.bidsPlaced > 0)
       {
           revert("Bids have already been placed");
       }

       if(bid.isOpen){
           quantity = bid.quantity;
           pricingType = bid.pricingType;
       }else if(saleItem.isOpen){
           quantity = saleItem.quantity;
           pricingType = PricingType.INSTANT_BUY;
       }else{
           revert("there is no open transaction for this asset");
       }

       if(_tokenType == TokenType.ERC1155){
           IERC1155 erc1155Contract = IERC1155(_nftTokenAddress);
           erc1155Contract.safeTransferFrom(address(this), msg.sender, _tokenId, quantity, "0x0");
       }else if (_tokenType == TokenType.ERC721){
            IERC721 erc721Contract = IERC721(_nftTokenAddress);
           erc721Contract.safeTransferFrom(address(this), msg.sender, _tokenId);
       }

       instantBuyDetails[_nftTokenAddress][_tokenId] = SaleItem(address(0), 0, false, 0, address(0));
       bidDetails[_nftTokenAddress][_tokenId] =Bid(address(0), 0, false, 0, address(0), address(0), PricingType.Undefined, 0, 0, 0);
        emit OrderClosed(_nftTokenAddress, _tokenId, quantity, _tokenType, msg.sender, _userId, pricingType);
   }
   
   function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) 
   {
       return this.onERC721Received.selector;
   }



  
   
   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




contract NaffToken is ERC20, Ownable {

    uint256 decimal = 18;
    uint256 weiValue = (10**decimal);
    uint256 initialSupply = 10000000000 * weiValue; //10 Billion
    uint256 seedRound = ((4 * weiValue) * initialSupply) / (100 * weiValue); //400 Million (4% of initial Supply)
    uint256 puvlcfirstPresale = ((5 * 100000000000000000) * initialSupply) / (100 * weiValue); //500 Million (5% of initial supply)
    uint256 secondPresale = ((5 * weiValue) * initialSupply) / (100 * weiValue); // 500 Million (5% of initial Supply)
    uint256 publicSaleListingPrice = ((10 * 100000000000000000) * initialSupply) / (100 * weiValue); //100 Million (1% of initial Supply)
    uint256 team = ((25 * weiValue) * initialSupply) / (100 * weiValue); //2.5 Billion (25% of initial supply)
    uint256 advisors = ((20 * weiValue) * initialSupply) / (100 * weiValue); //2 Billion (20% of Initial Supply)
    uint256 ecoSystemFund = ((20 * weiValue) * initialSupply) / (100 * weiValue); //2 Billion (20% of Initial Supply)
    uint256 liquidity = ((10 * weiValue) * initialSupply) / (100 * weiValue); //1 Billion (10% of Initial Supply)
    uint256 community = ((5 * weiValue) * initialSupply) / (100 * weiValue); //500 Million (5% of Initial Supply)
    uint256 reserve = ((5 * weiValue) * initialSupply) / (100 * weiValue); //500 Million (5% of Initial Supply)
    uint256 seedAllocated = 0;

    uint256 seedVestingDuration = 365; //days
    uint256 seedWithdrawalDuration = 1 minutes;

    constructor() public ERC20("NAFF Token", "NAFF") {
        _mint(address(this), initialSupply);
        //_transfer(address(this), msg.sender, initialDistrubtionAmount);
    }

    function withdraw(address _recipient, uint256 _amount) onlyOwner public {
        _transfer(address(this), _recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

