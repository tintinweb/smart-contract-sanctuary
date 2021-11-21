// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;


import "./VcgBase.sol";


contract ExchangeVcgAuction is Ownable {
    using Strings for string;
    using Address for address;    
    using SafeMath for uint256;
    enum State {Started, Pending, Ended, Cancelled}

    struct auctionInfo {
        address  _nftContractAddress;
        uint256  _nftId;
        address  _beneficiaryAddress;
        uint256  _initialPrice;
        uint256  _bidIncrement;
        uint  _startTime;
        uint  _stopTime;
        address  highestBidder;
        mapping(address => uint256) fundsByBidder;   
        State  _state;
        uint256 _totalBalance;
        bool isUsed;
    }

    mapping(uint256 => auctionInfo) private _auctionInfos;

    // Interface to halt all auctions.
    bool public IsHalted;

    // Admin withdrawal
    event WithDrawal(uint256 auctionid,address bidder,uint256 amount);
    // Pause and resume
    event Pause();
    event Resume();
    // New Bidding Event
    event NewBid(uint256 auctionid, uint256 price, address bidder);
    // Auction Finish Event
    event AuctionMade(uint256 auctionid, address oper ,State s);
    

    // Halt transactions
    function halt() public onlyOwner {
        //require(_privilleged_operators[msg.sender] == true, "Operator only");
        IsHalted = true;
        emit Pause();
    }
    
    // Resume transactions
    function resume() public onlyOwner {
        IsHalted = false;
        emit Resume();
    }

    modifier onlyAuctionExist(uint256 auctionID) {
        require(_auctionInfos[auctionID].isUsed,"auctionID not existed...");
        _;
    }

    modifier onlyOwnerOrBeneficiary(uint256 auctionID) {
        require(msg.sender == owner() ||
           msg.sender == _auctionInfos[auctionID]._beneficiaryAddress,
           "only Owner Or Beneficiary allow to do this.");
        _;
    }

    modifier notBeneficiary(uint256 auctionID, address bider) {
        //if (bider == _auctionInfos[auctionid].beneficiaryAddress) throw;
        require(bider != _auctionInfos[auctionID]._beneficiaryAddress, "Bider Must not the beneficiary");
        _;
    }

    modifier onlyAfterStart(uint256 auctionID) {
        require(block.timestamp > _auctionInfos[auctionID]._startTime, "only After Start");
        _;
    }

    modifier onlyBeforeEnd(uint256 auctionID) {
        require(block.timestamp < _auctionInfos[auctionID]._stopTime, "only Before End");
        _;
    }

    modifier onlyEndedOrCanceled(uint256 auctionID) {
        require(_auctionInfos[auctionID]._state == State.Ended || 
            _auctionInfos[auctionID]._state == State.Cancelled, 
            "The nft is still on auction, pls claim it or wait for finish");
        _;
    }

    function hasRightToAuction(address nftContractaddr,uint256 tokenId) public view returns(bool) {
        return (IERC721(nftContractaddr).getApproved(tokenId) == address(this));
    }

    function isTokenOwner(address nftContractaddr,address targetAddr, uint256 tokenId) internal view returns(bool) {  
        return (targetAddr == IERC721(nftContractaddr).ownerOf(tokenId) );   
    }

    function isOnAuction(uint256 auctionID) public view returns(bool) {
        require(_auctionInfos[auctionID].isUsed,"auctionID not existed...");
        return (block.timestamp > _auctionInfos[auctionID]._startTime
            && block.timestamp < _auctionInfos[auctionID]._stopTime);
    }   

    function createAuction(uint256 auctionID, 
        address  nftContractAddress,
        uint256  nftId,
        uint256  initialPrice,
        uint256  bidIncrement,
        uint  startTime,
        uint  stopTime) public {
        require(!_auctionInfos[auctionID].isUsed,"auctionID existed...");

        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        require(startTime <  stopTime, "stopTime must greater than startTime");
        require(stopTime > block.timestamp + 600 , "stopTime must greater than current Time after 10 min");

        require(isTokenOwner(nftContractAddress, msg.sender, nftId),
        "the sender isn't the owner of the token id nft!");

        require(hasRightToAuction(nftContractAddress,nftId),
            "the exchange contracct is not the approved of the token.");
        
        require(initialPrice > 0 && initialPrice >= bidIncrement ,"need a vaild initial price");

        auctionInfo storage ainfo = _auctionInfos[auctionID];
        ainfo._nftContractAddress=nftContractAddress;
        ainfo._nftId=nftId;
        ainfo._beneficiaryAddress=msg.sender;
        ainfo._initialPrice=initialPrice;
        ainfo._bidIncrement=bidIncrement;
        ainfo._totalBalance = 0;
        ainfo._startTime=startTime;
        ainfo._stopTime=stopTime;  
        ainfo._state=State.Pending;
        ainfo.isUsed=true;

        emit AuctionMade(auctionID, address(this) ,State.Pending);
    }

    function getAuctionInfo(uint256 auctionID) external 
        view
        returns (address,uint256,address,uint256,uint256,
        uint,uint,address,State,uint256){
        auctionInfo storage info = _auctionInfos[auctionID];
        return (
            info._nftContractAddress,
            info._nftId,
            info._beneficiaryAddress,
            info._initialPrice,
            info._bidIncrement,
            info._startTime,
            info._stopTime,
            info.highestBidder,
            info._state,
            info._totalBalance
        );
    }

    function clearAuctionInfo(uint256 auctionID) internal
        onlyAuctionExist(auctionID) {
        require(_auctionInfos[auctionID]._totalBalance == 0 ,
            "only zero balance to be claered.");
        /*
        auctionInfo storage ainfo = _auctionInfos[auctionID];
        
        ainfo._nftContractAddress=address(0);
        ainfo._nftId=0;
        ainfo._beneficiaryAddress=address(0);
        ainfo._initialPrice=0;
        ainfo._bidIncrement=0;
        ainfo._totalBalance = 0;
        ainfo._startTime=0;
        ainfo._stopTime=0;  
        ainfo._state=State.Pending;
        ainfo.highestBidder=address(0);
        ainfo.isUsed=false;
        */
        delete _auctionInfos[auctionID];
    }

    function cancelAuction(uint256 auctionID) public 
        onlyAuctionExist(auctionID) onlyOwnerOrBeneficiary(auctionID){
        _auctionInfos[auctionID]._state = State.Cancelled;
    }
    
    function getHighestBid(uint256 auctionID) public
        view
        returns (address,uint256)
    {
        require(_auctionInfos[auctionID].isUsed,"auctionID not existed...");
        if(_auctionInfos[auctionID].highestBidder == address(0))
        {
            return (address(0),0);
        }
        return (_auctionInfos[auctionID].highestBidder,
            _auctionInfos[auctionID].fundsByBidder[
                _auctionInfos[auctionID].highestBidder]);
    }
    

    function placeBid(uint256 auctionID) public payable 
            onlyAuctionExist(auctionID)
            notBeneficiary(auctionID,msg.sender) onlyAfterStart(auctionID) onlyBeforeEnd(auctionID) {
        // to place a bid auction should be running
        require(_auctionInfos[auctionID]._state == State.Pending ||
            _auctionInfos[auctionID]._state == State.Started);
        // minimum value allowed to be sent
        require(msg.value >= _auctionInfos[auctionID]._bidIncrement,
        "bid should be greater bid Increment");
        
        uint256 currentBid = _auctionInfos[auctionID].fundsByBidder[msg.sender] + msg.value;
        
        // the currentBid should be greater than the highestBid. 
        // Otherwise there's nothing to do.
        require((address(0) == _auctionInfos[auctionID].highestBidder &&
               currentBid >= _auctionInfos[auctionID]._initialPrice)//first bid
            || 
            (currentBid > _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder]));
        
        //set state to started,when first vaild bid
        if (_auctionInfos[auctionID]._state == State.Pending)
        {
            _auctionInfos[auctionID]._state = State.Started;
            emit AuctionMade(auctionID, msg.sender ,State.Started);
        }

        // updating the mapping variable
        _auctionInfos[auctionID].fundsByBidder[msg.sender] = currentBid;
        _auctionInfos[auctionID]._totalBalance = 
        _auctionInfos[auctionID]._totalBalance.add(msg.value);

        if (_auctionInfos[auctionID].highestBidder != msg.sender){ // highestBidder is another bidder
             _auctionInfos[auctionID].highestBidder = payable(msg.sender);
        }
        emit NewBid(auctionID, currentBid, msg.sender);
    }  
    
    function finalizeAuction(uint256 auctionID) public
        onlyAuctionExist(auctionID) onlyOwner {
        
       // the auction has been Cancelled or Ended
       require((_auctionInfos[auctionID]._state == State.Cancelled 
        || _auctionInfos[auctionID]._state == State.Started
        || _auctionInfos[auctionID]._state == State.Pending)
        &&
        block.timestamp > _auctionInfos[auctionID]._stopTime); 
       
       if(_auctionInfos[auctionID]._state == State.Started)
       {
            address payable recipient;
            uint value;
            recipient = payable(_auctionInfos[auctionID]._beneficiaryAddress);
            value = _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder];
            
            // resetting the bids of the recipient to avoid multiple transfers to the same recipient
            _auctionInfos[auctionID].fundsByBidder[
            _auctionInfos[auctionID].highestBidder] = 0;
            _auctionInfos[auctionID]._totalBalance = 
                _auctionInfos[auctionID]._totalBalance.sub(value);
            //
            IERC721(_auctionInfos[auctionID]._nftContractAddress).safeTransferFrom(
                _auctionInfos[auctionID]._beneficiaryAddress,
                _auctionInfos[auctionID].highestBidder,
                _auctionInfos[auctionID]._nftId
            );
            //sends value to the recipient
            recipient.transfer(value);
        }
        _auctionInfos[auctionID]._state = State.Ended;
        emit AuctionMade(auctionID, msg.sender ,State.Ended);
        if(_auctionInfos[auctionID]._totalBalance == 0){
            clearAuctionInfo(auctionID);
        }
    }

    function withdraw(uint256 auctionID) public
        onlyAuctionExist(auctionID) onlyEndedOrCanceled(auctionID)
        returns (bool success)
    {
        address payable withdrawalAccount;
        uint withdrawalAmount;

        if (_auctionInfos[auctionID]._state == State.Cancelled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];

        } else {
            require(msg.sender != _auctionInfos[auctionID].highestBidder ,
                "highestBidder does not allow to withdraw.");
            // anyone who participated but did not win the auction should be allowed to withdraw
            // the full amount of their funds
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];
        }

        if (withdrawalAmount == 0) {
            revert();
        }
        delete _auctionInfos[auctionID].fundsByBidder[withdrawalAccount];
        /*
        _auctionInfos[auctionID].fundsByBidder[withdrawalAccount] = 
        _auctionInfos[auctionID].fundsByBidder[withdrawalAccount].sub(withdrawalAmount);
        */
        // send the funds
        if (!withdrawalAccount.send(withdrawalAmount)){
            revert();
        }
        
        _auctionInfos[auctionID]._totalBalance = 
                _auctionInfos[auctionID]._totalBalance.sub(withdrawalAmount);
        if(_auctionInfos[auctionID]._totalBalance == 0){
            clearAuctionInfo(auctionID);
        }

        emit WithDrawal(auctionID,withdrawalAccount,withdrawalAmount);
        return true;
    }

}