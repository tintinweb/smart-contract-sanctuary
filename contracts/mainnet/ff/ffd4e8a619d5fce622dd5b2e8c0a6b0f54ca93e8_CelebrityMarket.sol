pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
   OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


/// @title CryptoCelebritiesMarket
/// @dev Contains models, variables, and internal methods for sales.
contract CelebrityMarket is Pausable{

    ERC721 ccContract;

    // Represents a sale item on an NFT
    struct Sale {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of a sale item
        uint256 salePrice;
        // Time when sale started
        // NOTE: 0 if this sale has been concluded
        uint64 startedAt;
    }

    // Owner of this contract
    address public owner;

    // Map from token ID to their corresponding sale.
    mapping (uint256 => Sale) tokenIdToSale;

    event SaleCreated(address seller,uint256 tokenId, uint256 salePrice, uint256 startedAt);
    event SaleSuccessful(address seller, uint256 tokenId, uint256 totalPrice, address winner);
    event SaleCancelled(address seller, uint256 tokenId);
    event SaleUpdated(address seller, uint256 tokenId, uint256 oldPrice, uint256 newPrice);
    
    /// @dev Constructor registers the nft address (CCAddress)
    /// @param _ccAddress - Address of the CryptoCelebrities contract
    function CelebrityMarket(address _ccAddress) public {
        ccContract = ERC721(_ccAddress);
        owner = msg.sender;
    }

    /// @dev DON&#39;T give me your money.
    function() external {}


    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        require(
            msg.sender == owner
        );
        msg.sender.transfer(address(this).balance);
    }

    /// @dev Creates and begins a new sale.
    /// @param _tokenId - ID of token to sell, sender must be owner.
    /// @param _salePrice - Sale Price of item (in wei).
    function createSale(
        uint256 _tokenId,
        uint256 _salePrice
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(_tokenId);
        Sale memory sale = Sale(
            msg.sender,
            _salePrice,
            uint64(now)
        );
        _addSale(_tokenId, sale);
    }

    /// @dev Update sale price of a sale item that hasn&#39;t been completed yet.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on sale
    /// @param _newPrice - new sale price
    function updateSalePrice(uint256 _tokenId, uint256 _newPrice)
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _updateSalePrice(_tokenId, _newPrice, seller);
    }

    /// @dev Allows to buy a sale item, completing the sale and transferring
    /// ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to buy.
    function buy(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _buy(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /// @dev Cancels a sale that hasn&#39;t been completed yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on sale
    function cancelSale(uint256 _tokenId)
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

    /// @dev Cancels a sale when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on sale to cancel.
    function cancelSaleWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        _cancelSale(_tokenId, sale.seller);
    }

    /// @dev Returns sale info for an NFT on sale.
    /// @param _tokenId - ID of NFT on sale.
    function getSale(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 salePrice,
        uint256 startedAt
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.salePrice,
            sale.startedAt
        );
    }

    /// @dev Returns the current price of a sale item.
    /// @param _tokenId - ID of the token price we are checking.
    function getSalePrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return sale.salePrice;
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (ccContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the CCToken, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(uint256 _tokenId) internal {
        // it will throw if transfer fails
        ccContract.takeOwnership(_tokenId);
    }

    /// @dev Transfers a CCToken owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        ccContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds a sale to the list of open sales. Also fires the
    ///  SaleCreated event.
    /// @param _tokenId The ID of the token to be put on sale.
    /// @param _sale Sale to add.
    function _addSale(uint256 _tokenId, Sale _sale) internal {

        tokenIdToSale[_tokenId] = _sale;
        
        SaleCreated(
            address(_sale.seller),
            uint256(_tokenId),
            uint256(_sale.salePrice),
            uint256(_sale.startedAt)
        );
    }

    /// @dev Cancels a sale unconditionally.
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        SaleCancelled(_seller, _tokenId);
    }

    /// @dev updates sale price of item
    function _updateSalePrice(uint256 _tokenId, uint256 _newPrice, address _seller) internal {
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSale[_tokenId];
        uint256 oldPrice = sale.salePrice;
        sale.salePrice = _newPrice;
        SaleUpdated(_seller, _tokenId, oldPrice, _newPrice);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _buy(uint256 _tokenId, uint256 _amount)
        internal
        returns (uint256)
    {
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSale[_tokenId];

        // Explicitly check that this sale is currently live.
        // (Because of how Ethereum mappings work, we can&#39;t just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an sale object that is all zeros.)
        require(_isOnSale(sale));

        // Check that the incoming bid is higher than the current
        // price
        uint256 price = sale.salePrice;

        require(_amount >= price);

        // Grab a reference to the seller before the sale struct
        // gets deleted.
        address seller = sale.seller;

        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeSale(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            //  Calculate the market owner&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can&#39;t go negative.)
            uint256 ownerCut = _computeCut(price);
            uint256 sellerProceeds = price - ownerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the sale item
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it&#39;s an
            // accident, they can call cancelSale(). )
            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 amountExcess = _amount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the sale is
        // removed before any transfers occur.
        msg.sender.transfer(amountExcess);

        // Tell the world!
        SaleSuccessful(seller, _tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes a sale item from the list of open sales.
    /// @param _tokenId - ID of NFT on sale.
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /// @dev Returns true if the NFT is on sale.
    /// @param _sale - Sale to check.
    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }

    /// @dev Computes owner&#39;s cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal pure returns (uint256) {
        return uint256(SafeMath.div(SafeMath.mul(_price, 6), 100));
    }

}