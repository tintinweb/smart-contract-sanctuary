pragma solidity ^0.5.9;

interface IRBAC {
  event RoleCreated(uint256 role);
  event BearerAdded(address indexed account, uint256 role);
  event BearerRemoved(address indexed account, uint256 role);

  function addRootRole(string calldata roleDescription) external returns(uint256);
  function removeBearer(address account, uint256 role) external;
  function addRole(string calldata roleDescription, uint256 admin) external returns(uint256);
  function totalRoles() external view returns(uint256);
  function hasRole(address account, uint256 role) external view returns(bool);
  function addBearer(address account, uint256 role) external;
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _o) internal {
        require(_o != address(0), "Owner cannot be 0");
        _owner = _o;
        emit OwnershipTransferred(address(0), _o);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract vnxAuctionSC is Ownable {

    //-----------------------------------------------------------------------------------
    // Data Structures
    //-----------------------------------------------------------------------------------
    enum StatusName {NEW, FUNDED, CANCELED}

    struct AuctionDetails {
        uint bookingId;
        // name and ticker should remain empty until the closure (with close function) of the auction
        string name;
        string ticker;
        bool isClosed;
    }

    struct BidStatus {
        StatusName status; // 0: New; 1: Paid; 2: Canceled
        address user; // user who initiated a bid
        address userStatusUpdate; // user who updated the status to present state (can be either user or admin)
        uint timeUpdate;
    }

    struct BidList {
        uint[] bids;  // Bid hashes, the key to bidStatuses mapping
        uint timeInit;
    }

    //-----------------------------------------------------------------------------------
    // Variables, Instances, Mappings
    //-----------------------------------------------------------------------------------
    uint constant BULK_LENGTH = 50;
    address[] private users;

    AuctionDetails private auctionDetails;

    /* Bid's uint(Hash) is a param to this mapping */
    mapping(uint => BidStatus) private bidStatuses;
    
    /* User who initiated the bids is a param to this mapping */
    mapping(address => BidList) private userBids;

    IRBAC private _rbacManager;
    /**
     * @dev Throws if called by any account other than the admin
     */
    modifier onlyAdmin() {
      require(isAdmin(), "RBAC: caller is not the admin");
      _;
    }

    /**
     * @dev Returns true if the caller is the admin role
     */
    function isAdmin() public view returns (bool) {
      return _rbacManager.hasRole(msg.sender, 0);
    }

    //-----------------------------------------------------------------------------------
    // Smart contract Constructor
    //-----------------------------------------------------------------------------------
    // name and ticker should remain empty until the closure (with close function) of the auction
    constructor (uint _bookingId, address _manager) public Ownable(_manager) {
        require(_bookingId != 0, "Booking ID should not be zero");
        require(_manager != address(0), "RBAC manager should not be zero");

        _rbacManager = IRBAC(_manager);
        
        auctionDetails.bookingId = _bookingId;
    }

    //-----------------------------------------------------------------------------------
    // View Functions
    //-----------------------------------------------------------------------------------
    function getAuctionDetails() external view returns (uint bookingId, string memory name, string memory ticker, bool isClosed) {
        return (auctionDetails.bookingId, auctionDetails.name, auctionDetails.ticker, auctionDetails.isClosed);
    }

    function getUsersLen() external view returns(uint) {
        return users.length;
    }

    function getUsersItem(uint _ind) external view returns(address) {
        if( _ind >= users.length ) {
            return address(0);
        }
        return users[_ind];
    }

    function getBidListLen(address _user) external view returns(uint) {
        if (userBids[_user].timeInit==0) {
		return 0;
        }

        return userBids[_user].bids.length;
    }

    function getBidListHash(address _user, uint _ind) external view returns(uint) {
        if (userBids[_user].timeInit==0 || _ind >= userBids[_user].bids.length) {
		return 0;
        }

        return userBids[_user].bids[_ind];
    }

    function getBidListItem(address _user, uint _ind) external view returns(uint status, uint timeUpdate) {
        if (userBids[_user].timeInit==0 || _ind >= userBids[_user].bids.length) {
          return (0,0);
        }

        return (uint(bidStatuses[userBids[_user].bids[_ind]].status), bidStatuses[userBids[_user].bids[_ind]].timeUpdate);
    }

    //-----------------------------------------------------------------------------------
    // Transact Functions
    //-----------------------------------------------------------------------------------
    event BidUpdated(uint indexed _hashBid, uint8 _newStatus);

    /**
    * IMPORTANT -- In case of value overflow no event is sent due to THROW (revert) -- this is rollback
    * @dev writes a bid to the blockchain
    * @param _user      The address of a user which has the corrersponding hashBid.
    * @param _hashBid   The hash of bid for the user to see/confirm his/her bid.
    * @param _newStatus The status of the bid.
    */
    function writeBid(address _user, uint _hashBid, StatusName _newStatus) external returns (bool) {
        require(auctionDetails.isClosed == false, "Auction is already closed");
        require(isAdmin() || msg.sender == _user, "Only admin or bid owner can write bids");
        require(_newStatus == StatusName.NEW || _newStatus == StatusName.FUNDED || _newStatus == StatusName.CANCELED, "Wrong status id passed");
        require(_hashBid != 0, "Bid hash cannot be zero");

        return _writeBid(_user, _hashBid, _newStatus);
    }

    function _writeBid(address _user, uint _hashBid, StatusName _newStatus) internal returns (bool) {
        if (bidStatuses[_hashBid].timeUpdate != 0) { // bid already exists, simply update
            if (bidStatuses[_hashBid].status==_newStatus) { // no new actual status applied: simply report success without rewrite
		return true;
            } else {
                // check if _user owns _hashBid
                bool isBidOwner = false;
                for (uint i = 0; i<userBids[_user].bids.length; i++) {
                    if (userBids[_user].bids[i]==_hashBid) {
                        isBidOwner = true;
                    }
                }

                if (!isBidOwner) {
                    return false;
                } else {
                    return _setBidState(_hashBid, _newStatus);
                }
            }
        }

        // Bid not exist yet
        if (userBids[_user].timeInit == 0) { // no such user registered yet
            users.push(_user);
            userBids[_user].timeInit = now;
        }

        userBids[_user].bids.push(_hashBid);
        BidStatus memory bidStatus;
        bidStatus.status = _newStatus;
        bidStatus.user = _user;
        bidStatus.userStatusUpdate = msg.sender;
        bidStatus.timeUpdate = now;
        bidStatuses[_hashBid] = bidStatus;
        emit BidUpdated(_hashBid, uint8(_newStatus));
        return true;
    }

    event BatchBidsUpdated(uint indexed bulkId, uint processedCount);

    /**
    * @dev writes bids in a bulk to the blockchain
    * Bids state changes in the batch must be sorted by the time of their occurence in the system
    *
    * @param _bulkId The unique ID of the bulk which is calculated on the client side (by the admin) as a hash of some bulk bids' data
    * @param _bidUsers The array of addresses of users which have the corrersponding hashBid.
    * @param _hashBids The array of hashes of bids for users to see/confirm their bids.
    * @param _newStatuses The array of statuses of the bids.
    */
    function writeBidsBatch(uint _bulkId, address[] calldata _bidUsers, uint[] calldata _hashBids,
                 StatusName[] calldata _newStatuses) external onlyAdmin returns (bool)
    {
        require(_bidUsers.length == _hashBids.length, "Input arrays should be of the same size");
        require(_bidUsers.length == _newStatuses.length, "Input arrays should be of the same size");
        require(auctionDetails.isClosed == false, "Auction is already closed");
        require(_bidUsers.length <= BULK_LENGTH, "Array length can not be larger than BULK_LENGTH");

        uint _procCount = 0;

        uint[BULK_LENGTH] memory _itemsToSave;
        uint _itemsLength = 0;

	/**
	*  _writeBid behaviour (write new bid or update bid status) depends on all bid write transactions being committed to the blockchain before _writeBid is called 
	*  so it will not work correctly when the batch contains new bid and subsequent status changes of this bid in the same batch
	*  in which case _writeBid will erroneously consider state changes as new bids with the same hashes from the same user
	*
	*  The following loop makes sure that only one (the latest) transaction for each unique bid in the batch will pass through to _writeBid call
	*/
        for (uint j = 0; j<_bidUsers.length; j++) { // run through all input entries
            if (_bidUsers[j] == address(0) || _hashBids[j] == 0 ) {
                revert('Wrong input parameters');
            }

            for (uint k = 0; k < _itemsLength; k++) { // check previously saved entries
                if (_bidUsers[_itemsToSave[k]]==_bidUsers[j]) { // got the same user as current item
                    if (_hashBids[_itemsToSave[k]]==_hashBids[j]) { // got the same bid hash, update status
                        _itemsToSave[k] = j;
                        continue;
                    }
                }
            }
            _itemsToSave[_itemsLength++] = j;
        }

        for (uint k = 0; k < _itemsLength; k++) { // store filtered entries        
            _procCount = _procCount + 1;
            _writeBid(_bidUsers[_itemsToSave[k]], _hashBids[_itemsToSave[k]], _newStatuses[_itemsToSave[k]]);
        }

        emit BatchBidsUpdated(_bulkId, _procCount);
        return true;
    }

    event BidStateChanged(uint indexed _hashBid, StatusName indexed _newStatus);

    function _setBidState( uint _hashBid, StatusName _newStatus ) internal returns (bool) {
        require(bidStatuses[_hashBid].status != StatusName.CANCELED, "Bid status is CANCELLED, no more changes allowed");

        // check allowed statuses transitions
        if (bidStatuses[_hashBid].status == StatusName.FUNDED && _newStatus==StatusName.NEW) {
          revert('Status change not allowed: from FUNDED to NEW');
        }

        bidStatuses[_hashBid].status = _newStatus;
        bidStatuses[_hashBid].userStatusUpdate = msg.sender;
        bidStatuses[_hashBid].timeUpdate = now;
        emit BidStateChanged(_hashBid, _newStatus);
        return true;
    }

    event AuctionClosed();

    // NOT EMITTED -- _err = 3; _errMsqg = "Closing status in blockchain does not correspond to action"
    function closeAuction(string calldata _name, string calldata _ticker) external onlyAdmin returns (bool) {
        require(auctionDetails.isClosed==false, "Auction is already closed");
        auctionDetails.isClosed = true;
        auctionDetails.name = _name;
        auctionDetails.ticker = _ticker;
        emit AuctionClosed();
        return true;
    }
}