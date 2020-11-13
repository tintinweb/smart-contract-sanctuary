pragma solidity ^0.5.9;

contract vnxAuctionSC {

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin security: caller is not the admin");
        _;
    }

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
    address private admin;
    address[] private users;

    AuctionDetails private auctionDetails;

    /* Bid's uint(Hash) is a param to this mapping */
    mapping(uint => BidStatus) private bidStatuses;
    
    /* User who initiated the bids is a param to this mapping */
    mapping(address => BidList) private userBids;

    //-----------------------------------------------------------------------------------
    // Smart contract Constructor
    //-----------------------------------------------------------------------------------
    // name and ticker should remain empty until the closure (with close function) of the auction
    constructor(uint _bookingId) public {
        require(_bookingId != 0, "Booking ID should not be zero");

        admin = msg.sender;
        auctionDetails.bookingId = _bookingId;
    }

    //-----------------------------------------------------------------------------------
    // View Functions
    //-----------------------------------------------------------------------------------
    function getAuctionDetails() public view returns (uint bookingId, string memory name, string memory ticker, bool isClosed){
        return (auctionDetails.bookingId, auctionDetails.name, auctionDetails.ticker, auctionDetails.isClosed);
    }

    function getUsersLen() public view returns(uint) {
        return users.length;
    }

    function getUsersItem(uint _ind) public view returns(address) {
        if( _ind >= users.length ) {
            return address(0);
        }
        return users[_ind];
    }

    function getBidListLen(address _user) public view returns(uint) {
        if (userBids[_user].timeInit==0) {
		return 0;
        }

        return userBids[_user].bids.length;
    }

    function getBidListHash(address _user, uint _ind) public view returns(uint) {
        if (userBids[_user].timeInit==0 || _ind >= userBids[_user].bids.length) {
		return 0;
        }

        return userBids[_user].bids[_ind];
    }

    function getBidListItem(address _user, uint _ind) public view returns(uint status, uint timeUpdate) {
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
    function writeBid(address _user, uint _hashBid, StatusName _newStatus) public returns (bool) {
        require(auctionDetails.isClosed == false, "Auction is already closed");
        require(msg.sender == admin || msg.sender == _user, "Only admin or bid owner can write bids");
        require(_newStatus == StatusName.NEW || _newStatus == StatusName.FUNDED || _newStatus == StatusName.CANCELED, "Wrong status id passed");
        require(_hashBid != 0, "Bid hash cannot be zero");

        return _writeBid(_user, _hashBid, _newStatus);
    }

    function _writeBid(address _user, uint _hashBid, StatusName _newStatus) internal returns (bool) {
        if (bidStatuses[_hashBid].timeUpdate != 0) { // bid already exists, simply update
            return _setBidState(_hashBid, _newStatus);
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
    *    IMPORTANT -- In case of value overflow no event is sent due to THROW (revert) -- this is rollback
    * @dev writes bids in a bulk to the blockchain
	* Bids state changes in the batch must be sorted by the time of their occurence in the system
	*
    * @param _bulkId The unique ID of the bulk which is calculated on the client side (by the admin) as a hash of some bulk bids' data
    * @param _bidUsers The array of addresses of users which have the corrersponding hashBid.
    * @param _hashBids The array of hashes of bids for users to see/confirm their bids.
    * @param _newStatuses The array of statuses of the bids.
    * IMPORTANT -- in evNewBulkBid( _bulkId, _processedNum, _err, _errMsg ) check __processedNum !!
    *    Not all records in the Bulk can be loaded. Check the messing records with evNewBid events
    */
    function writeBidsBatch(uint _bulkId, address[] memory _bidUsers, uint[] memory _hashBids,
                 StatusName[] memory _newStatuses) public onlyAdmin returns (bool)
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

        bidStatuses[_hashBid].status = _newStatus;
        bidStatuses[_hashBid].userStatusUpdate = msg.sender;
        bidStatuses[_hashBid].timeUpdate = now;
        emit BidStateChanged(_hashBid, _newStatus);
        return true;
    }

    event AuctionClosed();

    // NOT EMITTED -- _err = 3; _errMsqg = "Closing status in blockchain does not correspond to action"
    function closeAuction(string memory _name, string memory _ticker) public onlyAdmin returns (bool) {
        require(auctionDetails.isClosed==false, "Auction is already closed");
        auctionDetails.isClosed = true;
        auctionDetails.name = _name;
        auctionDetails.ticker = _ticker;
        emit AuctionClosed();
        return true;
    }
}