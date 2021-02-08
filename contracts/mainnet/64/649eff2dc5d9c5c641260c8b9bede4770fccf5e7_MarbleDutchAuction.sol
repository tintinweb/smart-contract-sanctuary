/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// File: @0xcert/ethereum-erc721/contracts/tokens/ERC721.sol

pragma solidity ^0.4.24;

/**
 * @dev ERC-721 non-fungible token standard. See https://goo.gl/pc9yoS.
 */
interface ERC721 {

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received`
   * on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-utils/contracts/utils/ERC165.sol

pragma solidity ^0.4.24;

/**
 * @dev A standard for detecting smart contract interfaces. See https://goo.gl/cxQCse.
 */
interface ERC165 {

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * @notice This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-utils/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param _a Factor number.
   * @param _b Factor number.
   */
  function mul(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   * @param _a Dividend number.
   * @param _b Divisor number.
   */
  function div(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a / _b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _a Minuend number.
   * @param _b Subtrahend number.
   */
  function sub(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   * @param _a Number.
   * @param _b Number.
   */
  function add(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/SupportsInterface.sol

pragma solidity ^0.4.24;


/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces.
   * @notice You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
    public
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/AddressUtils.sol

pragma solidity ^0.4.24;

/**
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils {

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool)
  {
    uint256 size;

    /**
     * XXX Currently there is no better way to check if there is a contract in an address than to
     * check the size of the code at that address.
     * See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
     * TODO: Check this again before the Serenity release, because all addresses will be
     * contracts then.
     */
    assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/DutchAuctionBase.sol

pragma solidity ^0.4.24;





/**
 * @title Dutch Auction Base
 * @dev Contains model defining Auction, public variables as reference to nftContract. It is expected that auctioneer is owner of the contract. Dutch auction by wiki - https://en.wikipedia.org/wiki/Dutch_auction. Contract is inspired by https://github.com/nedodn/NFT-Auction and https://github.com/dapperlabs/cryptokitties-bounty/tree/master/contracts/Auction/
 * @notice Contract omits a fallback function to prevent accidental eth transfers.
 */
contract DutchAuctionBase is
  SupportsInterface
{

  using SafeMath for uint128;
  using SafeMath for uint256;
  using AddressUtils for address;

  // Model of NFt auction
  struct Auction {
      // Address of person who placed NFT to auction
      address seller;

      // Price (in wei) at beginning of auction
      uint128 startingPrice;

      // Price (in wei) at end of auction
      uint128 endingPrice;

      // Duration (in seconds) of auction when price is moving, lets say, it determines dynamic part of auction price creation.
      uint64 duration;

      // Time when auction started, yep 256, we consider ours NFTs almost immortal!!! :)
      uint256 startedAt;

      // Determine if seller can cancel auction before dynamic part of auction ends!  Let have some hard core sellers!!!
      bool delayedCancel;

  }

  // Owner of the contract is considered as Auctioneer, so it supposed to have some share from successful sale.
  // Value in between 0-10000 (1% is equal to 100)
  uint16 public auctioneerCut;

  // Cut representing auctioneers earnings from auction with delayed cancel
  // Value in between 0-10000 (1% is equal to 100)
  uint16 public auctioneerDelayedCancelCut;

  // Reference to contract tracking NFT ownership
  ERC721 public nftContract;

  // Maps Token ID with Auction
  mapping (uint256 => Auction) public tokenIdToAuction;

  event AuctionCreated(uint256 tokenId, address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, bool delayedCancel);
  event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
  event AuctionCancelled(uint256 tokenId);

  /**
   * @dev Adds new auction and fires AuctionCreated event.
   * @param _tokenId NFT ID
   * @param _auction Auction to add.
   */
  function _addAuction(uint256 _tokenId, Auction _auction) internal {
    // Dynamic part of acution hast to be at least 1 minute
    require(_auction.duration >= 1 minutes);

    tokenIdToAuction[_tokenId] = _auction;

    emit AuctionCreated(
        _tokenId,
        _auction.seller,
        uint256(_auction.startingPrice),
        uint256(_auction.endingPrice),
        uint256(_auction.duration),
        _auction.delayedCancel
    );
  }

  /**
   * @dev Cancels auction and transfer token to provided address
   * @param _tokenId ID of NFT
   */
  function _cancelAuction(uint256 _tokenId) internal {
    Auction storage auction = tokenIdToAuction[_tokenId];
    address _seller = auction.seller;
    _removeAuction(_tokenId);

    // return Token to seller
    nftContract.transferFrom(address(this), _seller, _tokenId);
    emit AuctionCancelled(_tokenId);
  }

  /**
   * @dev Handles bid placemant. If bid is valid then calculates auctioneers cut and sellers revenue.
   * @param _tokenId ID of NFT
   * @param _offer value in wei representing what buyer is willing to pay for NFT
   */
  function _bid(uint256 _tokenId, uint256 _offer)
      internal
  {
      // Get a reference to the auction struct
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(_isOnAuction(auction), "Can not place bid. NFT is not on auction!");

      // Check that the bid is greater than or equal to the current price
      uint256 price = _currentPrice(auction);
      require(_offer >= price, "Bid amount has to be higher or equal than current price!");

      // Put seller address before auction is deleted.
      address seller = auction.seller;

      // Keep auction type even after auction is deleted.
      bool isCancelDelayed = auction.delayedCancel;

      // Remove the auction before sending the fees to the sender so we can't have a reentrancy attack.
      _removeAuction(_tokenId);

      // Transfer revenue to seller
      if (price > 0) {
          // Calculate the auctioneer's cut.
          uint256 computedCut = _computeCut(price, isCancelDelayed);
          uint256 sellerRevenue = price.sub(computedCut);

          /**
           * NOTE: !! Doing a transfer() in the middle of a complex method is dangerous!!!
           * because of reentrancy attacks and DoS attacks if the seller is a contract with an invalid fallback function. We explicitly
           * guard against reentrancy attacks by removing the auction before calling transfer(),
           * and the only thing the seller can DoS is the sale of their own asset! (And if it's an accident, they can call cancelAuction(). )
           */
          seller.transfer(sellerRevenue);
      }

      // Calculate any excess funds included with the bid. Excess should be transfered back to bidder.
      uint256 bidExcess = _offer.sub(price);

      // Return additional funds. This is not susceptible to a re-entry attack because the auction is removed before any transfers occur.
      msg.sender.transfer(bidExcess);

      emit AuctionSuccessful(_tokenId, price, msg.sender);
  }

  /**
   * @dev Returns true if the NFT is on auction.
   * @param _auction - Auction to check.
   */
  function _isOnAuction(Auction storage _auction)
    internal
    view
    returns (bool)
  {
      return (_auction.seller != address(0));
  }

  /**
   * @dev Returns true if auction price is dynamic
   * @param _auction Auction to check.
   */
  function _durationIsOver(Auction storage _auction)
    internal
    view
    returns (bool)
  {
      uint256 secondsPassed = 0;
      secondsPassed = now.sub(_auction.startedAt);

      // TODO - what about 30 seconds of tolerated difference of miners clocks??
      return (secondsPassed >= _auction.duration);
  }

  /**
   * @dev Returns current price of auction.
   * @param _auction Auction to check current price
   */
  function _currentPrice(Auction storage _auction)
    internal
    view
    returns (uint256)
  {
    uint256 secondsPassed = 0;

    if (now > _auction.startedAt) {
        secondsPassed = now.sub(_auction.startedAt);
    }

    if (secondsPassed >= _auction.duration) {
        // End of dynamic part of auction.
        return _auction.endingPrice;
    } else {
        // Note - working with int256 not with uint256!! Delta can be negative.
        int256 totalPriceChange = int256(_auction.endingPrice) - int256(_auction.startingPrice);
        int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(_auction.duration);
        int256 currentPrice = int256(_auction.startingPrice) + currentPriceChange;

        return uint256(currentPrice);
    }
  }

  /**
   * @dev Computes auctioneer's cut of a sale.
   * @param _price - Sale price of NFT.
   * @param _isCancelDelayed - Determines what kind of cut is used for calculation
   */
  function _computeCut(uint256 _price, bool _isCancelDelayed)
    internal
    view
    returns (uint256)
  {

      if (_isCancelDelayed) {
        return _price * auctioneerDelayedCancelCut / 10000;
      }

      return _price * auctioneerCut / 10000;
  }

  /*
   * @dev Removes auction from auction list
   * @param _tokenId NFT on auction
   */
   function _removeAuction(uint256 _tokenId)
     internal
   {
     delete tokenIdToAuction[_tokenId];
   }
}

// File: contracts/DutchAuctionEnumerable.sol

pragma solidity ^0.4.24;


/**
 * @title Extension of Auction Base (core). Allows to enumarate auctions.
 * @dev It's highly inspired by https://github.com/0xcert/ethereum-erc721/blob/master/contracts/tokens/NFTokenEnumerable.sol
 */
contract DutchAuctionEnumerable
  is DutchAuctionBase
{

  // array of tokens in auction
  uint256[] public tokens;

  /**
   * @dev Mapping from token ID its index in global tokens array.
   */
  mapping(uint256 => uint256) public tokenToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs in this auction.
   */
  mapping(address => uint256[]) public sellerToTokens;

  /**
   * @dev Mapping from NFT ID to its index in the seller tokens list.
   */
  mapping(uint256 => uint256) public tokenToSellerIndex;

  /**
   * @dev Adds an auction to the list of open auctions. Also fires the
   *  AuctionCreated event.
   * @param _token The ID of the token to be put on auction.
   * @param _auction Auction to add.
   */
  function _addAuction(uint256 _token, Auction _auction)
    internal
  {
    super._addAuction(_token, _auction);

    uint256 length = tokens.push(_token);
    tokenToIndex[_token] = length - 1;

    length = sellerToTokens[_auction.seller].push(_token);
    tokenToSellerIndex[_token] = length - 1;
  }

  /*
   * @dev Removes an auction from the list of open auctions.
   * @param _token - ID of NFT on auction.
   */
  function _removeAuction(uint256 _token)
    internal
  {
    assert(tokens.length > 0);

    Auction memory auction = tokenIdToAuction[_token];
    // auction has to be defined
    assert(auction.seller != address(0));
    assert(sellerToTokens[auction.seller].length > 0);

    uint256 sellersIndexOfTokenToRemove = tokenToSellerIndex[_token];

    uint256 lastSellersTokenIndex = sellerToTokens[auction.seller].length - 1;
    uint256 lastSellerToken = sellerToTokens[auction.seller][lastSellersTokenIndex];

    sellerToTokens[auction.seller][sellersIndexOfTokenToRemove] = lastSellerToken;
    sellerToTokens[auction.seller].length--;

    tokenToSellerIndex[lastSellerToken] = sellersIndexOfTokenToRemove;
    tokenToSellerIndex[_token] = 0;

    uint256 tokenIndex = tokenToIndex[_token];
    assert(tokens[tokenIndex] == _token);

    // Sanity check. This could be removed in the future.
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;
    tokens.length--;

    // nullify token index reference
    tokenToIndex[lastToken] = tokenIndex;
    tokenToIndex[_token] = 0;

    super._removeAuction(_token);
  }


  /**
   * @dev Returns the count of all existing auctions.
   */
  function totalAuctions()
    external
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   */
  function tokenInAuctionByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < tokens.length);
    // Sanity check. This could be removed in the future.
    assert(tokenToIndex[tokens[_index]] == _index);
    return tokens[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _seller Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   */
  function tokenOfSellerByIndex(
    address _seller,
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < sellerToTokens[_seller].length);
    return sellerToTokens[_seller][_index];
  }

  /**
   * @dev Returns the count of all existing auctions.
   */
  function totalAuctionsBySeller(
    address _seller
  )
    external
    view
    returns (uint256)
  {
    return sellerToTokens[_seller].length;
  }
}

// File: contracts/MarbleNFTInterface.sol

pragma solidity ^0.4.24;

/**
 * @title Marble NFT Interface
 * @dev Defines Marbles unique extension of NFT.
 * ...It contains methodes returning core properties what describe Marble NFTs and provides management options to create,
 * burn NFT or change approvals of it.
 */
interface MarbleNFTInterface {

  /**
   * @dev Mints Marble NFT.
   * @notice This is a external function which should be called just by the owner of contract or any other user who has priviladge of being resposible
   * of creating valid Marble NFT. Valid token contains all neccessary information to be able recreate marble card image.
   * @param _tokenId The ID of new NFT.
   * @param _owner Address of the NFT owner.
   * @param _uri Unique URI proccessed by Marble services to be sure it is valid NFTs DNA. Most likely it is URL pointing to some website address.
   * @param _metadataUri URI pointing to "ERC721 Metadata JSON Schema"
   * @param _tokenId ID of the NFT to be burned.
   */
  function mint(
    uint256 _tokenId,
    address _owner,
    address _creator,
    string _uri,
    string _metadataUri,
    uint256 _created
  )
    external;

  /**
   * @dev Burns Marble NFT. Should be fired only by address with proper authority as contract owner or etc.
   * @param _tokenId ID of the NFT to be burned.
   */
  function burn(
    uint256 _tokenId
  )
    external;

  /**
   * @dev Allowes to change approval for change of ownership even when sender is not NFT holder. Sender has to have special role granted by contract to use this tool.
   * @notice Careful with this!!!! :))
   * @param _tokenId ID of the NFT to be updated.
   * @param _approved ETH address what supposed to gain approval to take ownership of NFT.
   */
  function forceApproval(
    uint256 _tokenId,
    address _approved
  )
    external;

  /**
   * @dev Returns properties used for generating NFT metadata image (a.k.a. card).
   * @param _tokenId ID of the NFT.
   */
  function tokenSource(uint256 _tokenId)
    external
    view
    returns (
      string uri,
      address creator,
      uint256 created
    );

  /**
   * @dev Returns ID of NFT what matches provided source URI.
   * @param _uri URI of source website.
   */
  function tokenBySourceUri(string _uri)
    external
    view
    returns (uint256 tokenId);

  /**
   * @dev Returns all properties of Marble NFT. Lets call it Marble NFT Model with properties described below:
   * @param _tokenId ID  of NFT
   * Returned model:
   * uint256 id ID of NFT
   * string uri  URI of source website. Website is used to mine data to crate NFT metadata image.
   * string metadataUri URI to NFT metadata assets. In our case to our websevice providing JSON with additional information based on "ERC721 Metadata JSON Schema".
   * address owner NFT owner address.
   * address creator Address of creator of this NFT. It means that this addres placed sourceURI to candidate contract.
   * uint256 created Date and time of creation of NFT candidate.
   *
   * (id, uri, metadataUri, owner, creator, created)
   */
  function getNFT(uint256 _tokenId)
    external
    view
    returns(
      uint256 id,
      string uri,
      string metadataUri,
      address owner,
      address creator,
      uint256 created
    );


    /**
     * @dev Transforms URI to hash.
     * @param _uri URI to be transformed to hash.
     */
    function getSourceUriHash(string _uri)
      external
      view
      returns(uint256 hash);
}

// File: @0xcert/ethereum-utils/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Claimable.sol

pragma solidity ^0.4.24;


/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at goo.gl/CfEAkv and upgrades Ownable contracts with additional claim step which makes ownership
 * transfers less prone to errors.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Allows the current owner to give new owner ability to claim the ownership of the contract.
   * This differs from the Owner's function in that it allows setting pedingOwner address to 0x0,
   * which effectively cancels an active claim.
   * @param _newOwner The address which can claim ownership of the contract.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    pendingOwner = _newOwner;
  }

  /**
   * @dev Allows the current pending owner to claim the ownership of the contract. It emits
   * OwnershipTransferred event and resets pending owner to 0.
   */
  function claimOwnership()
    public
  {
    require(msg.sender == pendingOwner);
    address previousOwner = owner;
    owner = pendingOwner;
    pendingOwner = 0;
    emit OwnershipTransferred(previousOwner, owner);
  }
}

// File: contracts/Adminable.sol

pragma solidity ^0.4.24;


/**
 * @title Adminable
 * @dev Allows to manage privilages to special contract functionality.
 */
contract Adminable is Claimable {
  mapping(address => uint) public adminsMap;
  address[] public adminList;

  /**
   * @dev Returns true, if provided address has special privilages, otherwise false
   * @param adminAddress - address to check
   */
  function isAdmin(address adminAddress)
    public
    view
    returns(bool isIndeed)
  {
    if (adminAddress == owner) return true;

    if (adminList.length == 0) return false;
    return (adminList[adminsMap[adminAddress]] == adminAddress);
  }

  /**
   * @dev Grants special rights for address holder
   * @param adminAddress - address of future admin
   */
  function addAdmin(address adminAddress)
    public
    onlyOwner
    returns(uint index)
  {
    require(!isAdmin(adminAddress), "Address already has admin rights!");

    adminsMap[adminAddress] = adminList.push(adminAddress)-1;

    return adminList.length-1;
  }

  /**
   * @dev Removes special rights for provided address
   * @param adminAddress - address of current admin
   */
  function removeAdmin(address adminAddress)
    public
    onlyOwner
    returns(uint index)
  {
    // we can not remove owner from admin role
    require(owner != adminAddress, "Owner can not be removed from admin role!");
    require(isAdmin(adminAddress), "Provided address is not admin.");

    uint rowToDelete = adminsMap[adminAddress];
    address keyToMove = adminList[adminList.length-1];
    adminList[rowToDelete] = keyToMove;
    adminsMap[keyToMove] = rowToDelete;
    adminList.length--;

    return rowToDelete;
  }

  /**
   * @dev modifier Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Can be executed only by admin accounts!");
    _;
  }
}

// File: contracts/Priceable.sol

pragma solidity ^0.4.24;



/**
 * @title Priceable
 * @dev Contracts allows to handle ETH resources of the contract.
 */
contract Priceable is Claimable {

  using SafeMath for uint256;

  /**
   * @dev Emits when owner take ETH out of contract
   * @param balance - amount of ETh sent out from contract
   */
  event Withdraw(uint256 balance);

  /**
   * @dev modifier Checks minimal amount, what was sent to function call.
   * @param _minimalAmount - minimal amount neccessary to  continue function call
   */
  modifier minimalPrice(uint256 _minimalAmount) {
    require(msg.value >= _minimalAmount, "Not enough Ether provided.");
    _;
  }

  /**
   * @dev modifier Associete fee with a function call. If the caller sent too much, then is refunded, but only after the function body.
   * This was dangerous before Solidity version 0.4.0, where it was possible to skip the part after `_;`.
   * @param _amount - ether needed to call the function
   */
  modifier price(uint256 _amount) {
    require(msg.value >= _amount, "Not enough Ether provided.");
    _;
    if (msg.value > _amount) {
      msg.sender.transfer(msg.value.sub(_amount));
    }
  }

  /*
   * @dev Remove all Ether from the contract, and transfer it to account of owner
   */
  function withdrawBalance()
    external
    onlyOwner
  {
    uint256 balance = address(this).balance;
    msg.sender.transfer(balance);

    // Tell everyone !!!!!!!!!!!!!!!!!!!!!!
    emit Withdraw(balance);
  }

  // fallback function that allows contract to accept ETH
  function () public payable {}
}

// File: contracts/Pausable.sol

pragma solidity ^0.4.24;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism for mainenance purposes
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause()
    external
    onlyOwner
    whenNotPaused
    returns (bool)
  {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause()
    external
    onlyOwner
    whenPaused
    returns (bool)
  {
    paused = false;
    emit Unpause();
    return true;
  }
}

// File: contracts/MarbleDutchAuctionInterface.sol

pragma solidity ^0.4.24;

/**
 * @title Marble Dutch Auction Interface
 * @dev describes all externaly accessible functions neccessery to run Marble Auctions
 */
interface MarbleDutchAuctionInterface {

  /**
   * @dev Sets new auctioneer cut, in case we are to cheap :))
   * @param _cut - percent cut the auctioneer takes on each auction, must be between 0-100. Values 0-10,000 map to 0%-100%.
   */
  function setAuctioneerCut(
    uint256 _cut
  )
   external;

  /**
  * @dev Sets new auctioneer delayed cut, in case we are not earning much during creating NFTs initial auctions!
  * @param _cut Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
  */
  function setAuctioneerDelayedCancelCut(
    uint256 _cut
  )
   external;

  /**
   * @dev Sets an addresses of ERC 721 contract owned/admined by same entity.
   * @param _nftAddress Address of ERC 721 contract
   */
  function setNFTContract(address _nftAddress)
    external;


  /**
   * @dev Creates new auction without special logic. It allows user to sell owned Marble NFTs
   * @param _tokenId ID of token to auction, sender must be owner.
   * @param _startingPrice Price of item (in wei) at beginning of auction.
   * @param _endingPrice Price of item (in wei) at end of auction.
   * @param _duration Length of time to move between starting price and ending price (in seconds) - it determines dynamic state of auction
   */
  function createAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration
  )
    external;

  /**
   * @dev Creates and begins a new minting auction. Minitng auction is initial auction allowing to challenge newly Minted Marble NFT.
   * If no-one buy NFT during dynamic state of auction, then seller (original creator of NFT) will be allowed to become owner of NFT. It means during dynamic (duration)
   * state of auction, it won't be possible to use cancelAuction function by seller!
   * @param _tokenId - ID of token to auction, sender must be owner.
   * @param _startingPrice - Price of item (in wei) at beginning of auction.
   * @param _endingPrice - Price of item (in wei) at end of auction.
   * @param _duration - Length of time to move between starting price and ending price (in seconds).
   * @param _seller - Seller, if not the message sender
   */
  function createMintingAuction(
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _duration,
    address _seller
  )
    external;

  /**
   * @dev It allows seller to cancel auction and get back Marble NFT.
   * @param _tokenId ID of token on auction
   */
  function cancelAuction(
    uint256 _tokenId
  )
    external;

  /**
   * @dev It allows seller to cancel auction and get back Marble NFT.
   * @param _tokenId ID of token on auction
   */
  function cancelAuctionWhenPaused(
    uint256 _tokenId
  )
    external;

  /**
   * @dev Bids on an open auction, completing the auction and transferring ownership of the NFT if enough Ether is supplied.
   * @param _tokenId ID of token to bid on.
   */
  function bid(
    uint256 _tokenId
  )
    external
    payable;

  /**
   * @dev Returns the current price of an auction.
   * @param _tokenId ID of the token price we are checking.
   */
  function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the count of all existing auctions.
   */
  function totalAuctions()
    external
    view
    returns (uint256);

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   */
  function tokenInAuctionByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the n-th NFT ID from a list of owner's tokens.
   * @param _seller Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   */
  function tokenOfSellerByIndex(
    address _seller,
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the count of all existing auctions.
   */
  function totalAuctionsBySeller(
    address _seller
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns true if the NFT is on auction.
   * @param _tokenId ID of the token to be checked.
   */
  function isOnAuction(uint256 _tokenId)
    external
    view
    returns (bool isIndeed);

  /**
   * @dev Returns auction info for an NFT on auction.
   * @param _tokenId ID of NFT placed in auction
   */
  function getAuction(uint256 _tokenId)
    external
    view
    returns
  (
    address seller,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 startedAt,
    bool canBeCanceled
  );

  /**
   * @dev remove NFT reference from auction conrtact, should be use only when NFT is being burned
   * @param _tokenId ID of token on auction
   */
  function removeAuction(
    uint256 _tokenId
  )
    external;
}

// File: contracts/MarbleDutchAuction.sol

pragma solidity ^0.4.24;









/**
 * @title Dutch auction for non-fungible tokens created by Marble.Cards.
 */
contract MarbleDutchAuction is
  MarbleDutchAuctionInterface,
  Priceable,
  Adminable,
  Pausable,
  DutchAuctionEnumerable
{

  /**
   * @dev The ERC-165 interface signature for ERC-721.
   *  Ref: https://github.com/ethereum/EIPs/issues/165
   *  Ref: https://github.com/ethereum/EIPs/issues/721
   */
  bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;

  /**
   * @dev Reports change of auctioneer cut.
   * @param _auctioneerCut Number between 0-10000 (1% is equal to 100)
   */
  event AuctioneerCutChanged(uint256 _auctioneerCut);

  /**
   * @dev Reports change of auctioneer delayed cut.
   * @param _auctioneerDelayedCancelCut Number between 0-10000 (1% is equal to 100)
   */
  event AuctioneerDelayedCancelCutChanged(uint256 _auctioneerDelayedCancelCut);

  /**
   * @dev Reports removal of NFT from auction cotnract
   * @param _tokenId ID of token to auction, sender must be owner.
   */
  event AuctionRemoved(uint256 _tokenId);

  /**
   * @dev Creates new auction.
   * NOTE: !! Doing a dangerous stuff here!!! changing owner of NFT, be careful where u call this one !!!
   * TODO: in case of replacing forceApproval we can add our contracts as operators, but there is problem in possiblity of changing auction contract and we will be unable to transfer kards to new one
   * @param _tokenId ID of token to auction, sender must be owner.
   * @param _startingPrice Price of item (in wei) at beginning of auction.
   * @param _endingPrice Price of item (in wei) at end of auction.
   * @param _duration Length of time to move between starting
   * @param _delayedCancel If false seller can cancel auction any time, otherwise only after times up
   * @param _seller Seller, if not the message sender
   */
  function _createAuction(
      uint256 _tokenId,
      uint256 _startingPrice,
      uint256 _endingPrice,
      uint256 _duration,
      bool _delayedCancel,
      address _seller
  )
      internal
      whenNotPaused
  {
      MarbleNFTInterface marbleNFT = MarbleNFTInterface(address(nftContract));

      // Sanity check that no inputs overflow how many bits we've allocated
      // to store them as auction model.
      require(_startingPrice == uint256(uint128(_startingPrice)), "Starting price is too high!");
      require(_endingPrice == uint256(uint128(_endingPrice)), "Ending price is too high!");
      require(_duration == uint256(uint64(_duration)), "Duration exceeds allowed limit!");

      /**
       * NOTE: !! Doing a dangerous stuff here !!
       * before calling this should be clear that seller is owner of NFT
       */
      marbleNFT.forceApproval(_tokenId, address(this));

      // lets auctioneer to own NFT for purposes of auction
      nftContract.transferFrom(_seller, address(this), _tokenId);

      Auction memory auction = Auction(
        _seller,
        uint128(_startingPrice),
        uint128(_endingPrice),
        uint64(_duration),
        uint256(now),
        bool(_delayedCancel)
      );

      _addAuction(_tokenId, auction);
  }

  /**
   * @dev Sets new auctioneer cut, in case we are to cheap :))
   * @param _cut Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
   */
  function setAuctioneerCut(uint256 _cut)
    external
    onlyAdmin
  {
    require(_cut <= 10000, "Cut should be in interval of 0-10000");
    auctioneerCut = uint16(_cut);

    emit AuctioneerCutChanged(auctioneerCut);
  }

  /**
   * @dev Sets new auctioneer delayed cut, in case we are not earning much during creating NFTs initial auctions!
   * @param _cut Percent cut the auctioneer takes on each auction, must be between 0-10000. Values 0-10,000 map to 0%-100%.
   */
  function setAuctioneerDelayedCancelCut(uint256 _cut)
    external
    onlyAdmin
  {
    require(_cut <= 10000, "Delayed cut should be in interval of 0-10000");
    auctioneerDelayedCancelCut = uint16(_cut);

    emit AuctioneerDelayedCancelCutChanged(auctioneerDelayedCancelCut);
  }

  /**
   * @dev Sets an addresses of ERC 721 contract owned/admined by same entity.
   * @param _nftAddress Address of ERC 721 contract
   */
  function setNFTContract(address _nftAddress)
    external
    onlyAdmin
  {
    ERC165 nftContractToCheck = ERC165(_nftAddress);
    require(nftContractToCheck.supportsInterface(InterfaceSignature_ERC721)); // ERC721 == 0x80ac58cd
    nftContract = ERC721(_nftAddress);
  }

  /**
   * @dev Creates and begins a new minting auction. Minitng auction is initial auction allowing to challenge newly Minted Marble NFT.
   * If no-one buy NFT during its dynamic state, then seller (original creator of NFT) will be allowed to become owner of NFT. It means during dynamic (duration)
   * state of auction, it won't be possible to use cancelAuction function by seller!
   * @param _tokenId ID of token to auction, sender must be owner.
   * @param _startingPrice Price of item (in wei) at beginning of auction.
   * @param _endingPrice Price of item (in wei) at end of auction.
   * @param _duration Length of time to move between starting price and ending price (in seconds).
   * @param _seller Seller, if not the message sender
   */
  function createMintingAuction(
      uint256 _tokenId,
      uint256 _startingPrice,
      uint256 _endingPrice,
      uint256 _duration,
      address _seller
  )
      external
      whenNotPaused
      onlyAdmin
  {
      // TODO minitingPrice vs mintintgFee require(_endingPrice > _mintingFee, "Ending price of minitng auction has to be bigger than minting fee!");

      // Sale auction throws if inputs are invalid and clears
      _createAuction(
        _tokenId,
        _startingPrice,
        _endingPrice,
        _duration,
        true, // seller can NOT cancel auction only after time is up! and bidders can be just over duration
        _seller
      );
  }

  /**
   * @dev Creates new auction without special logic.
   * @param _tokenId ID of token to auction, sender must be owner.
   * @param _startingPrice Price of item (in wei) at beginning of auction.
   * @param _endingPrice Price of item (in wei) at end of auction.
   * @param _duration Length of time to move between starting price and ending price (in seconds) - it determines dynamic state of auction
   */
  function createAuction(
      uint256 _tokenId,
      uint256 _startingPrice,
      uint256 _endingPrice,
      uint256 _duration
  )
      external
      whenNotPaused
  {
      require(nftContract.ownerOf(_tokenId) == msg.sender, "Only owner of the token can create auction!");
      // Sale auction throws if inputs are invalid and clears
      _createAuction(
        _tokenId,
        _startingPrice,
        _endingPrice,
        _duration,
        false, // seller can cancel auction any time
        msg.sender
      );
  }

  /**
   * @dev Bids on an open auction, completing the auction and transferring ownership of the NFT if enough Ether is supplied.
   * NOTE: Bid can be placed on normal auction any time,
   * but in case of "minting" auction (_delayedCancel == true) it can be placed only when call of _isTimeUp(auction) returns false
   * @param _tokenId ID of token to bid on.
   */
  function bid(uint256 _tokenId)
      external
      payable
      whenNotPaused
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    require(_isOnAuction(auction), "NFT is not on this auction!");
    require(!auction.delayedCancel || !_durationIsOver(auction), "You can not bid on this auction, because it has delayed cancel policy actived and after times up it belongs once again to seller!");

    // _bid will throw if the bid or funds transfer fails
    _bid(_tokenId, msg.value);

    // change the ownership of NFT
    nftContract.transferFrom(address(this), msg.sender, _tokenId);
  }

  /**
   * @dev It allows seller to cancel auction and get back Marble NFT, but it works only when delayedCancel property is false or when auction duratian time is up.
   * @param _tokenId ID of token on auction
   */
  function cancelAuction(uint256 _tokenId)
    external
    whenNotPaused
  {
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(_isOnAuction(auction), "NFT is not auctioned over our contract!");
      require((!auction.delayedCancel || _durationIsOver(auction)) && msg.sender == auction.seller, "You have no rights to cancel this auction!");

      _cancelAuction(_tokenId);
  }

  /**
   * @dev Cancels an auction when the contract is paused.
   *  Only the admin may do this, and NFTs are returned to the seller. This should only be used in emergencies like moving to another auction contract.
   * @param _tokenId ID of the NFT on auction to cancel.
   */
  function cancelAuctionWhenPaused(uint256 _tokenId)
    external
    whenPaused
    onlyAdmin
  {
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(_isOnAuction(auction), "NFT is not auctioned over our contract!");
      _cancelAuction(_tokenId);
  }

  /**
   * @dev Returns true if NFT is placed as auction over this contract, otherwise false.
   * @param _tokenId ID of NFT to check.
   */
  function isOnAuction(uint256 _tokenId)
    external
    view
    returns (bool isIndeed)
  {
    Auction storage auction = tokenIdToAuction[_tokenId];
    return _isOnAuction(auction);
  }

  /**
   * @dev Returns auction info for an NFT on auction.
   * @param _tokenId ID of NFT placed in auction
   */
  function getAuction(uint256 _tokenId)
    external
    view
    returns
  (
    address seller,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 duration,
    uint256 startedAt,
    bool delayedCancel
  ) {
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(_isOnAuction(auction), "NFT is not auctioned over our contract!");

      return (
          auction.seller,
          auction.startingPrice,
          auction.endingPrice,
          auction.duration,
          auction.startedAt,
          auction.delayedCancel
      );
  }

  /**
   * @dev Returns the current price of an auction.
   * @param _tokenId ID of the token price we are checking.
   */
  function getCurrentPrice(uint256 _tokenId)
      external
      view
      returns (uint256)
  {
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(_isOnAuction(auction), "NFT is not auctioned over our contract!");
      return _currentPrice(auction);

  }

  /**
   * @dev remove NFT reference from auction conrtact, should be use only when NFT is being burned
   * @param _tokenId ID of token on auction
   */
  function removeAuction(
    uint256 _tokenId
  )
    external
    whenPaused
    onlyAdmin
  {
    _removeAuction(_tokenId);

    emit AuctionRemoved(_tokenId);
  }
}