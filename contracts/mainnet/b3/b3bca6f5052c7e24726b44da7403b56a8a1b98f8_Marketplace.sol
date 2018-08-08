pragma solidity 0.4.21;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/marketplace/Marketplace.sol

/**
 * @title Interface for contracts conforming to ERC-20
 */
contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
    function ownerOf(uint256 assetId) public view returns (address);
    function safeTransferFrom(address from, address to, uint256 assetId) public;
    function isAuthorized(address operator, uint256 assetId) public view returns (bool);
}

contract Marketplace is Ownable, Pausable, Destructible {
    using SafeMath for uint256;

    ERC20Interface public acceptedToken;
    ERC721Interface public nonFungibleRegistry;

    struct Auction {
        // Auction ID
        bytes32 id;
        // Owner of the NFT
        address seller;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
    }

    mapping (uint256 => Auction) public auctionByAssetId;

    uint256 public ownerCutPercentage;
    uint256 public publicationFeeInWei;

    /* EVENTS */
    event AuctionCreated(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller, 
        uint256 priceInWei, 
        uint256 expiresAt
    );
    event AuctionSuccessful(
        bytes32 id,
        uint256 indexed assetId, 
        address indexed seller, 
        uint256 totalPrice, 
        address indexed winner
    );
    event AuctionCancelled(
        bytes32 id,
        uint256 indexed assetId, 
        address indexed seller
    );

    event ChangedPublicationFee(uint256 publicationFee);
    event ChangedOwnerCut(uint256 ownerCut);


    /**
     * @dev Constructor for this contract.
     * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
     * @param _nonFungibleRegistry - Address of the ERC721 registry contract.
     */
    function Marketplace(address _acceptedToken, address _nonFungibleRegistry) public {
        acceptedToken = ERC20Interface(_acceptedToken);
        nonFungibleRegistry = ERC721Interface(_nonFungibleRegistry);
    }

    /**
     * @dev Sets the publication fee that&#39;s charged to users to publish items
     * @param publicationFee - Fee amount in wei this contract charges to publish an item
     */
    function setPublicationFee(uint256 publicationFee) onlyOwner public {
        publicationFeeInWei = publicationFee;

        ChangedPublicationFee(publicationFeeInWei);
    }

    /**
     * @dev Sets the share cut for the owner of the contract that&#39;s
     *  charged to the seller on a successful sale.
     * @param ownerCut - Share amount, from 0 to 100
     */
    function setOwnerCut(uint8 ownerCut) onlyOwner public {
        require(ownerCut < 100);

        ownerCutPercentage = ownerCut;

        ChangedOwnerCut(ownerCutPercentage);
    }

    /**
     * @dev Cancel an already published order
     * @param assetId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin.
     * @param expiresAt - Duration of the auction (in hours)
     */
    function createOrder(uint256 assetId, uint256 priceInWei, uint256 expiresAt) public whenNotPaused {
        address assetOwner = nonFungibleRegistry.ownerOf(assetId);
        require(msg.sender == assetOwner);
        require(nonFungibleRegistry.isAuthorized(address(this), assetId));
        require(priceInWei > 0);
        require(expiresAt > now.add(1 minutes));

        bytes32 auctionId = keccak256(
            block.timestamp, 
            assetOwner,
            assetId, 
            priceInWei
        );

        auctionByAssetId[assetId] = Auction({
            id: auctionId,
            seller: assetOwner,
            price: priceInWei,
            expiresAt: expiresAt
        });

        // Check if there&#39;s a publication fee and
        // transfer the amount to marketplace owner.
        if (publicationFeeInWei > 0) {
            require(acceptedToken.transferFrom(
                msg.sender,
                owner,
                publicationFeeInWei
            ));
        }

        AuctionCreated(
            auctionId,
            assetId, 
            assetOwner,
            priceInWei, 
            expiresAt
        );
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner.
     * @param assetId - ID of the published NFT
     */
    function cancelOrder(uint256 assetId) public whenNotPaused {
        require(auctionByAssetId[assetId].seller == msg.sender || msg.sender == owner);

        bytes32 auctionId = auctionByAssetId[assetId].id;
        address auctionSeller = auctionByAssetId[assetId].seller;
        delete auctionByAssetId[assetId];

        AuctionCancelled(auctionId, assetId, auctionSeller);
    }

    /**
     * @dev Executes the sale for a published NTF
     * @param assetId - ID of the published NFT
     */
    function executeOrder(uint256 assetId, uint256 price) public whenNotPaused {
        address seller = auctionByAssetId[assetId].seller;

        require(seller != address(0));
        require(seller != msg.sender);
        require(auctionByAssetId[assetId].price == price);
        require(now < auctionByAssetId[assetId].expiresAt);

        require(seller == nonFungibleRegistry.ownerOf(assetId));

        uint saleShareAmount = 0;

        if (ownerCutPercentage > 0) {

            // Calculate sale share
            saleShareAmount = price.mul(ownerCutPercentage).div(100);

            // Transfer share amount for marketplace Owner.
            acceptedToken.transferFrom(
                msg.sender,
                owner,
                saleShareAmount
            );
        }

        // Transfer sale amount to seller
        acceptedToken.transferFrom(
            msg.sender,
            seller,
            price.sub(saleShareAmount)
        );

        // Transfer asset owner
        nonFungibleRegistry.safeTransferFrom(
            seller,
            msg.sender,
            assetId
        );


        bytes32 auctionId = auctionByAssetId[assetId].id;
        delete auctionByAssetId[assetId];

        AuctionSuccessful(auctionId, assetId, seller, price, msg.sender);
    }
 }