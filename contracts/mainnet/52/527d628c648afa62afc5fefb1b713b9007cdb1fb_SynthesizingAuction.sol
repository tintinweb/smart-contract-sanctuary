pragma solidity ^0.4.24;

contract ERC165Interface {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     *  uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     *  `interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC165 is ERC165Interface {
    /**
     * @dev a mapping of interface id to whether or not it&#39;s supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

// Every ERC-721 compliant contract must implement the ERC721 and ERC165 interfaces.
/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
contract ERC721Basic is ERC165 {
    // Below is MUST

    /**
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) public view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`&#39;s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) public view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    // Below is OPTIONAL

    // ERC721Metadata
    // The metadata extension is OPTIONAL for ERC-721 smart contracts (see "caveats", below). This allows your smart contract to be interrogated for its name and for details about the assets which your NFTs represent.
    
    /**
     * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
     * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
     */

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string);

    // ERC721Enumerable
    // The enumeration extension is OPTIONAL for ERC-721 smart contracts (see "caveats", below). This allows your contract to publish its full list of NFTs and make them discoverable.

    /**
     * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
     * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     *  Note: the ERC-165 identifier for this interface is 0x780e9d63.
     */

    /**
     * @notice Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() public view returns (uint256);
}

/**
 * @notice This is MUST to be implemented.
 *  A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers.
 * @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
 */
contract ERC721TokenReceiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `transfer`. This function MAY throw to revert and reject the
     *  transfer. Return of other than the magic value MUST result in the
     *  transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns (bytes4);
}

contract ERC721Holder is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Base auction contract of the Dyverse
 * @author VREX Lab Co., Ltd
 * @dev Contains necessary functions and variables for the auction.
 *  Inherits `ERC721Holder` contract which is the implementation of the `ERC721TokenReceiver`.
 *  This is to accept safe transfers.
 */
contract AuctionBase is ERC721Holder {
    using SafeMath for uint256;

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) of NFT
        uint128 price;
        // Time when the auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721Basic public nonFungibleContract;

    // The amount owner takes from the sale, (in basis points, which are 1/100 of a percent).
    uint256 public ownerCut;

    // Maps token ID to it&#39;s corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 price);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address bidder);
    event AuctionCanceled(uint256 tokenId);

    /// @dev Disables sending funds to this contract.
    function() external {}

    /// @dev A modifier to check if the given value can fit in 64-bits.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= (2**64 - 1));
        _;
    }

    /// @dev A modifier to check if the given value can fit in 128-bits.
    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value <= (2**128 - 1));
        _;
    }

    /**
     * @dev Returns true if the claimant owns the token.
     * @param _claimant An address which to query the ownership of the token.
     * @param _tokenId ID of the token to query the owner of.
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev Escrows the NFT. Grants the ownership of the NFT to this contract safely.
     *  Throws if the escrow fails.
     * @param _owner Current owner of the token.
     * @param _tokenId ID of the token to escrow.
     */
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

    /**
     * @dev Transfers an NFT owned by this contract to another address safely.
     * @param _receiver The receiving address of NFT.
     * @param _tokenId ID of the token to transfer.
     */
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(this, _receiver, _tokenId);
    }

    /**
     * @dev Adds an auction to the list of open auctions. 
     * @param _tokenId ID of the token to be put on auction.
     * @param _auction Auction information of this token to open.
     */
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price)
        );
    }

    /// @dev Cancels the auction which the _seller wants.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCanceled(_tokenId);
    }

    /**
     * @dev Computes the price and sends it to the seller.
     *  Note that this does NOT transfer the ownership of the token.
     */
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Gets a reference of the token from auction storage.
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Checks that this auction is currently open
        require(_isOnAuction(auction));

        // Checks that the bid is greater than or equal to the current token price.
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Gets a reference of the seller before the auction gets deleted.
        address seller = auction.seller;

        // Removes the auction before sending the proceeds to the sender
        _removeAuction(_tokenId);

        // Transfers proceeds to the seller.
        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price.sub(auctioneerCut);

            seller.transfer(sellerProceeds);
        }

        // Computes the excess funds included with the bid and transfers it back to bidder. 
        uint256 bidExcess = _bidAmount - price;

        // Returns the exceeded funds.
        msg.sender.transfer(bidExcess);

        // Emits the AuctionSuccessful event.
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /**
     * @dev Removes an auction from the list of open auctions.
     * @param _tokenId ID of the NFT on auction to be removed.
     */
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Returns true if the NFT is on auction.
     * @param _auction An auction to check if it exists.
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns the current price of an NFT on auction.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        return _auction.price;
    }

    /**
     * @dev Computes the owner&#39;s receiving amount from the sale.
     * @param _price Sale price of the NFT.
     */
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Auction for NFT.
 * @author VREX Lab Co., Ltd
 */
contract Auction is Pausable, AuctionBase {

    /**
     * @dev Removes all Ether from the contract to the NFT contract.
     */
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

    /**
     * @dev Creates and begins a new auction.
     * @param _tokenId ID of the token to creat an auction, caller must be it&#39;s owner.
     * @param _price Price of the token (in wei).
     * @param _seller Seller of this token.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
        canBeStoredWith128Bits(_price)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Bids on an open auction, completing the auction and transferring
     *  ownership of the NFT if enough Ether is supplied.
     * @param _tokenId - ID of token to bid on.
     */
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /**
     * @dev Cancels an auction and returns the NFT to the current owner.
     * @param _tokenId ID of the token on auction to cancel.
     * @param _seller The seller&#39;s address.
     */
    function cancelAuction(uint256 _tokenId, address _seller)
        external
    {
        // Requires that this function should only be called from the
        // `cancelSaleAuction()` of NFT ownership contract. This function gets
        // the _seller directly from it&#39;s arguments, so if this check doesn&#39;t
        // exist, then anyone can cancel the auction! OMG!
        require(msg.sender == address(nonFungibleContract));
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(_seller == seller);
        _cancelAuction(_tokenId, seller);
    }

    /**
     * @dev Cancels an auction when the contract is paused.
     * Only the owner may do this, and NFTs are returned to the seller. 
     * @param _tokenId ID of the token on auction to cancel.
     */
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /**
     * @dev Returns the auction information for an NFT
     * @param _tokenId ID of the NFT on auction
     */
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 price,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.price,
            auction.startedAt
        );
    }

    /**
     * @dev Returns the current price of the token on auction.
     * @param _tokenId ID of the token
     */
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

/**
 * @title  Auction for synthesizing
 * @author VREX Lab Co., Ltd
 * @notice Reset fallback function to prevent accidental fund sending to this contract.
 */
contract SynthesizingAuction is Auction {

    /**
     * @dev Sanity check that allows us to ensure that we are pointing to the
     *  right auction in our `setSynthesizingAuctionAddress()` call.
     */
    bool public isSynthesizingAuction = true;

    /**
     * @dev Creates a reference to the NFT ownership contract and checks the owner cut is valid
     * @param _nftAddress Address of a deployed NFT interface contract
     * @param _cut Percent cut which the owner takes on each auction, between 0-10,000.
     */
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    /**
     * @dev Creates and begins a new auction. Since this function is wrapped,
     *  requires the caller to be KydyCore contract.
     * @param _tokenId ID of token to auction, sender must be it&#39;s owner.
     * @param _price Price of the token (in wei).
     * @param _seller Seller of this token.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Places a bid for synthesizing. Requires the caller
     *  is the KydyCore contract because all bid functions
     *  should be wrapped. Also returns the Kydy to the
     *  seller rather than the bidder.
     */
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid() checks that the token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
        // Transfers the Kydy back to the seller, and the bidder will get
        // the baby Kydy.
        _transfer(seller, _tokenId);
    }
}