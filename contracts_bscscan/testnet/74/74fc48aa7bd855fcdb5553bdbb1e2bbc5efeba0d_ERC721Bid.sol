/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.4.24;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.4.24;


contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.4.24;

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// File: contracts/bid/ERC721BidStorage.sol

pragma solidity ^0.4.24;


/**
 * @title Interface for contracts conforming to ERC-20
 */
contract ERC20Interface {
    function balanceOf(address from) public view returns (uint256);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}


/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function supportsInterface(bytes4) public view returns (bool);
}


contract ERC721Verifiable is ERC721Interface {
    function verifyFingerprint(uint256, bytes memory) public view returns (bool);
}


contract ERC721BidStorage {
    // 182 days - 26 weeks - 6 months
    uint256 public constant MAX_BID_DURATION = 182 days;
    uint256 public constant MIN_BID_DURATION = 1 minutes;
    uint256 public constant ONE_MILLION = 1000000;
    bytes4 public constant ERC721_Interface = 0x80ac58cd;
    bytes4 public constant ERC721_Received = 0x150b7a02;
    bytes4 public constant ERC721Composable_ValidateFingerprint = 0x8f9f4b63;
    
    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address 
        address bidder;
        // ERC721 address
        address tokenAddress;
        // ERC721 token id
        uint256 tokenId;
        // Price for the bid in wei 
        uint256 price;
        // Time when this bid ends 
        uint256 expiresAt;
        // Fingerprint for composable
        bytes fingerprint;
    }

    // MANA token
    ERC20Interface public manaToken;

    // Bid by token address => token id => bid index => bid
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) internal bidsByToken;
    // Bid count by token address => token id => bid counts
    mapping(address => mapping(uint256 => uint256)) public bidCounterByToken;
    // Index of the bid at bidsByToken mapping by bid id => bid index
    mapping(bytes32 => uint256) public bidIndexByBidId;
    // Bid id by token address => token id => bidder address => bidId
    mapping(address => mapping(uint256 => mapping(address => bytes32))) 
    public 
    bidIdByTokenAndBidder;


    uint256 public ownerCutPerMillion;

    // EVENTS
    event BidCreated(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      address indexed _bidder,
      uint256 _price,
      uint256 _expiresAt,
      bytes _fingerprint
    );
    
    event BidAccepted(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      address _bidder,
      address indexed _seller,
      uint256 _price,
      uint256 _fee
    );

    event BidCancelled(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      address indexed _bidder
    );

    event ChangedOwnerCutPerMillion(uint256 _ownerCutPerMillion);
}

// File: contracts/bid/ERC721Bid.sol

pragma solidity ^0.4.24;


contract ERC721Bid is Ownable, Pausable, ERC721BidStorage {
    using SafeMath for uint256;
    using Address for address;

    /**
    * @dev Constructor of the contract.
    * @param _manaToken - address of the mana token
    * @param _owner - address of the owner for the contract
    */
    constructor(address _manaToken, address _owner) Ownable() Pausable() public {
        manaToken = ERC20Interface(_manaToken);
        // Set owner
        transferOwnership(_owner);
    }
    
     // EVENTS
    event BidCreateds(
      bytes32 id,
      address indexed tokenAddress,
      uint256 indexed tokenId,
      address indexed bidder,
      uint256 price,
      uint256 _expiresAt,
      bytes fingerprint
    );
    
    event BidAccepteds(
      bytes32 id,
      address indexed tokenAddress,
      uint256 indexed tokenId,
      address bidder,
      address indexed seller,
      uint256 price,
      uint256 fee
    );

    event BidCancelleds(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      address indexed _bidder
    );

    /**
    * @dev Place a bid for an ERC721 token.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    */
    function placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration
    )
        public
    {
        _placeBid(
            _tokenAddress, 
            _tokenId,
            _price,
            _duration,
            ""
        );
    }

    /**
    * @dev Place a bid for an ERC721 token with fingerprint.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    * @param _fingerprint - bytes of ERC721 token fingerprint 
    */
    function placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes _fingerprint
    )
        public
    {
        _placeBid(
            _tokenAddress, 
            _tokenId,
            _price,
            _duration,
            _fingerprint 
        );
    }

    /**
    * @dev Place a bid for an ERC721 token with fingerprint.
    * @notice Tokens can have multiple bids by different users.
    * Users can have only one bid per token.
    * If the user places a bid and has an active bid for that token,
    * the older one will be replaced with the new one.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    * @param _fingerprint - bytes of ERC721 token fingerprint 
    */
    function _placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes memory _fingerprint
    )
        private
        whenNotPaused()
    {
        _requireERC721(_tokenAddress);
        _requireComposableERC721(_tokenAddress, _tokenId, _fingerprint);

        require(_price > 0, "Price should be bigger than 0");

        _requireBidderBalance(msg.sender, _price);       

        require(
            _duration >= MIN_BID_DURATION, 
            "The bid should be last longer than a minute"
        );

        require(
            _duration <= MAX_BID_DURATION, 
            "The bid can not last longer than 6 months"
        );

        ERC721Interface token = ERC721Interface(_tokenAddress);
        address tokenOwner = token.ownerOf(_tokenId);
        require(
            tokenOwner != address(0) && tokenOwner != msg.sender,
            "The token should have an owner different from the sender"
        );

        uint256 expiresAt = block.timestamp.add(_duration);

        bytes32 bidId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _tokenAddress,
                _tokenId,
                _price,
                _duration,
                _fingerprint
            )
        );

        uint256 bidIndex;

        if (_bidderHasABid(_tokenAddress, _tokenId, msg.sender)) {
            bytes32 oldBidId;
            (bidIndex, oldBidId,,,) = getBidByBidder(_tokenAddress, _tokenId, msg.sender);
            
            // Delete old bid reference
            delete bidIndexByBidId[oldBidId];
        } else {
            // Use the bid counter to assign the index if there is not an active bid. 
            bidIndex = bidCounterByToken[_tokenAddress][_tokenId];  
            // Increase bid counter 
            bidCounterByToken[_tokenAddress][_tokenId]++;
        }

        // Set bid references
        bidIdByTokenAndBidder[_tokenAddress][_tokenId][msg.sender] = bidId;
        bidIndexByBidId[bidId] = bidIndex;

        // Save Bid
        bidsByToken[_tokenAddress][_tokenId][bidIndex] = Bid({
            id: bidId,
            bidder: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            price: _price,
            expiresAt: expiresAt,
            fingerprint: _fingerprint
        });

        emit BidCreated(
            bidId,
            _tokenAddress,
            _tokenId,
            msg.sender,
            _price,
            expiresAt,
            _fingerprint     
        );
        emit BidCreateds(
            bidId,
            _tokenAddress,
            _tokenId,
            msg.sender,
            _price,
            expiresAt,
            _fingerprint     
        );
    }

    /**
    * @dev Used as the only way to accept a bid. 
    * The token owner should send the token to this contract using safeTransferFrom.
    * The last parameter (bytes) should be the bid id.
    * @notice  The ERC721 smart contract calls this function on the recipient
    * after a `safetransfer`. This function MAY throw to revert and reject the
    * transfer. Return of other than the magic value MUST result in the
    * transaction being reverted.
    * Note: 
    * Contract address is always the message sender.
    * This method should be seen as 'acceptBid'.
    * It validates that the bid id matches an active bid for the bid token.
    * @param _from The address which previously owned the token
    * @param _tokenId The NFT identifier which is being transferred
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address _from,
        address /*_to*/,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        whenNotPaused()
        returns (bytes4)
    {
        bytes32 bidId = _bytesToBytes32(_data);
        uint256 bidIndex = bidIndexByBidId[bidId];

        Bid memory bid = _getBid(msg.sender, _tokenId, bidIndex);

        // Check if the bid is valid.
        require(
            // solium-disable-next-line operator-whitespace
            bid.id == bidId &&
            bid.expiresAt >= block.timestamp, 
            "Invalid bid"
        );

        address bidder = bid.bidder;
        uint256 price = bid.price;
        
        // Check fingerprint if necessary
        _requireComposableERC721(msg.sender, _tokenId, bid.fingerprint);

        // Check if bidder has funds
        _requireBidderBalance(bidder, price);

        // Delete bid references from contract storage
        delete bidsByToken[msg.sender][_tokenId][bidIndex];
        delete bidIndexByBidId[bidId];
        delete bidIdByTokenAndBidder[msg.sender][_tokenId][bidder];

        // Reset bid counter to invalidate other bids placed for the token
        delete bidCounterByToken[msg.sender][_tokenId];
        
        // Transfer token to bidder
        ERC721Interface(msg.sender).transferFrom(address(this), bidder, _tokenId);

        uint256 saleShareAmount = 0;
        if (ownerCutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = price.mul(ownerCutPerMillion).div(ONE_MILLION);
            // Transfer share amount to the bid conctract Owner
            require(
                manaToken.transferFrom(bidder, owner(), saleShareAmount),
                "Transfering the cut to the bid contract owner failed"
            );
        }

        // Transfer MANA from bidder to seller
        require(
            manaToken.transferFrom(bidder, _from, price.sub(saleShareAmount)),
            "Transfering MANA to owner failed"
        );
       
        emit BidAccepted(
            bidId,
            msg.sender,
            _tokenId,
            bidder,
            _from,
            price,
            saleShareAmount
        );
        emit BidAccepteds(
            bidId,
            msg.sender,
            _tokenId,
            bidder,
            _from,
            price,
            saleShareAmount
        );

        return ERC721_Received;
    }

    /**
    * @dev Remove expired bids
    * @param _tokenAddresses - address[] of the ERC721 tokens
    * @param _tokenIds - uint256[] of the token ids
    * @param _bidders - address[] of the bidders
    */
    function removeExpiredBids(address[] _tokenAddresses, uint256[] _tokenIds, address[] _bidders)
    public 
    {
        uint256 loopLength = _tokenAddresses.length;

        require(loopLength == _tokenIds.length, "Parameter arrays should have the same length");
        require(loopLength == _bidders.length, "Parameter arrays should have the same length");

        for (uint256 i = 0; i < loopLength; i++) {
            _removeExpiredBid(_tokenAddresses[i], _tokenIds[i], _bidders[i]);
        }
    }
    
    /**
    * @dev Remove expired bid
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    */
    function _removeExpiredBid(address _tokenAddress, uint256 _tokenId, address _bidder)
    internal 
    {
        (uint256 bidIndex, bytes32 bidId,,,uint256 expiresAt) = getBidByBidder(
            _tokenAddress, 
            _tokenId,
            _bidder
        );
        
        require(expiresAt < block.timestamp, "The bid to remove should be expired");

        _cancelBid(
            bidIndex, 
            bidId, 
            _tokenAddress, 
            _tokenId, 
            _bidder
        );
    }

    /**
    * @dev Cancel a bid for an ERC721 token
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    */
    function cancelBid(address _tokenAddress, uint256 _tokenId) public whenNotPaused() {
        // Get active bid
        (uint256 bidIndex, bytes32 bidId,,,) = getBidByBidder(
            _tokenAddress, 
            _tokenId,
            msg.sender
        );

        _cancelBid(
            bidIndex, 
            bidId, 
            _tokenAddress, 
            _tokenId, 
            msg.sender
        );
    }

    /**
    * @dev Cancel a bid for an ERC721 token
    * @param _bidIndex - uint256 of the index of the bid
    * @param _bidId - bytes32 of the bid id
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    */
    function _cancelBid(
        uint256 _bidIndex,
        bytes32 _bidId, 
        address _tokenAddress,
        uint256 _tokenId, 
        address _bidder
    ) 
        internal 
    {
        // Delete bid references
        delete bidIndexByBidId[_bidId];
        delete bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        
        // Check if the bid is at the end of the mapping
        uint256 lastBidIndex = bidCounterByToken[_tokenAddress][_tokenId].sub(1);
        if (lastBidIndex != _bidIndex) {
            // Move last bid to the removed place
            Bid storage lastBid = bidsByToken[_tokenAddress][_tokenId][lastBidIndex];
            bidsByToken[_tokenAddress][_tokenId][_bidIndex] = lastBid;
            bidIndexByBidId[lastBid.id] = _bidIndex;
        }
        
        // Delete empty index
        delete bidsByToken[_tokenAddress][_tokenId][lastBidIndex];

        // Decrease bids counter
        bidCounterByToken[_tokenAddress][_tokenId]--;

        // emit BidCancelled event
        emit BidCancelled(
            _bidId,
            _tokenAddress,
            _tokenId,
            _bidder
        );
        
         emit BidCancelleds(
            _bidId,
            _tokenAddress,
            _tokenId,
            _bidder
        );
    }

     /**
    * @dev Check if the bidder has a bid for an specific token.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    * @return bool whether the bidder has an active bid
    */
    function _bidderHasABid(address _tokenAddress, uint256 _tokenId, address _bidder) 
        internal
        view 
        returns (bool)
    {
        bytes32 bidId = bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        uint256 bidIndex = bidIndexByBidId[bidId];
        // Bid index should be inside bounds
        if (bidIndex < bidCounterByToken[_tokenAddress][_tokenId]) {
            Bid memory bid = bidsByToken[_tokenAddress][_tokenId][bidIndex];
            return bid.bidder == _bidder;
        }
        return false;
    }

    /**
    * @dev Get the active bid id and index by a bidder and an specific token. 
    * @notice If the bidder has not a valid bid, the transaction will be reverted.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    * @return uint256 of the bid index to be used within bidsByToken mapping
    * @return bytes32 of the bid id
    * @return address of the bidder address
    * @return uint256 of the bid price
    * @return uint256 of the expiration time
    */
    function getBidByBidder(address _tokenAddress, uint256 _tokenId, address _bidder) 
        public
        view 
        returns (
            uint256 bidIndex, 
            bytes32 bidId, 
            address bidder, 
            uint256 price, 
            uint256 expiresAt
        ) 
    {
        bidId = bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        bidIndex = bidIndexByBidId[bidId];
        (bidId, bidder, price, expiresAt) = getBidByToken(_tokenAddress, _tokenId, bidIndex);
        if (_bidder != bidder) {
            revert("Bidder has not an active bid for this token");
        }
    }

    /**
    * @dev Get an ERC721 token bid by index
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _index - uint256 of the index
    * @return uint256 of the bid index to be used within bidsByToken mapping
    * @return bytes32 of the bid id
    * @return address of the bidder address
    * @return uint256 of the bid price
    * @return uint256 of the expiration time
    */
    function getBidByToken(address _tokenAddress, uint256 _tokenId, uint256 _index) 
        public 
        view
        returns (bytes32, address, uint256, uint256) 
    {
        
        Bid memory bid = _getBid(_tokenAddress, _tokenId, _index);
        return (
            bid.id,
            bid.bidder,
            bid.price,
            bid.expiresAt
        );
    }

    /**
    * @dev Get the active bid id and index by a bidder and an specific token. 
    * @notice If the index is not valid, it will revert.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the index
    * @param _index - uint256 of the index
    * @return Bid
    */
    function _getBid(address _tokenAddress, uint256 _tokenId, uint256 _index) 
        internal 
        view 
        returns (Bid memory)
    {
        require(_index < bidCounterByToken[_tokenAddress][_tokenId], "Invalid index");
        return bidsByToken[_tokenAddress][_tokenId][_index];
    }

    /**
    * @dev Sets the share cut for the owner of the contract that's
    * charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
        require(_ownerCutPerMillion < ONE_MILLION, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }

    /**
    * @dev Convert bytes to bytes32
    * @param _data - bytes
    * @return bytes32
    */
    function _bytesToBytes32(bytes memory _data) internal pure returns (bytes32) {
        require(_data.length == 32, "The data should be 32 bytes length");

        bytes32 bidId;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            bidId := mload(add(_data, 0x20))
        }
        return bidId;
    }

    /**
    * @dev Check if the token has a valid ERC721 implementation
    * @param _tokenAddress - address of the token
    */
    function _requireERC721(address _tokenAddress) internal view {
        require(_tokenAddress.isContract(), "Token should be a contract");

        ERC721Interface token = ERC721Interface(_tokenAddress);
        require(
            token.supportsInterface(ERC721_Interface),
            "Token has an invalid ERC721 implementation"
        );
    }

    /**
    * @dev Check if the token has a valid Composable ERC721 implementation
    * And its fingerprint is valid
    * @param _tokenAddress - address of the token
    * @param _tokenId - uint256 of the index
    * @param _fingerprint - bytes of the fingerprint
    */
    function _requireComposableERC721(
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory _fingerprint
    )
        internal
        view
    {
        ERC721Verifiable composableToken = ERC721Verifiable(_tokenAddress);
        if (composableToken.supportsInterface(ERC721Composable_ValidateFingerprint)) {
            require(
                composableToken.verifyFingerprint(_tokenId, _fingerprint),
                "Token fingerprint is not valid"
            );
        }
    }

    /**
    * @dev Check if the bidder has balance and the contract has enough allowance
    * to use bidder MANA on his belhalf
    * @param _bidder - address of bidder
    * @param _amount - uint256 of amount
    */
    function _requireBidderBalance(address _bidder, uint256 _amount) internal view {
        require(
            manaToken.balanceOf(_bidder) >= _amount,
            "Insufficient funds"
        );
        require(
            manaToken.allowance(_bidder, address(this)) >= _amount,
            "The contract is not authorized to use MANA on bidder behalf"
        );        
    }
}