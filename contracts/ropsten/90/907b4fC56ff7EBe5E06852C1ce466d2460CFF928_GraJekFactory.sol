/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract GraJekFactory{
    // mapping(address => Rider) _riders;
    mapping(address => Rider) _riders;
    Rider[] public riders;

    function createRider(uint _lowestFareAmount, uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal) public {
        // require (_riders[msg.sender] == Rider(0));
        _riders[msg.sender] = new Rider(msg.sender, _lowestFareAmount, _durationMin,  distanceKm,  _startPostal,  _endPostal);
        Rider rider = _riders[msg.sender];
        riders.push(rider);
    }
    
    function auctionEnd(address Passenger) public {
        // require (_counters[msg.sender] != Counter(0));
        Rider(_riders[Passenger]).auctionEnd(msg.sender);
    }
    
    function withdrawal(address Passenger) public {
        // require (_counters[account] != Counter(0));
        Rider(_riders[Passenger]).withdrawal(msg.sender);
        // return (_counters[account].getCount());
    }
    
    function placeBid(address Passenger) public payable {
        Rider(_riders[Passenger]).placeBid();
    }
    
    function getRiders() external view returns(Rider[] memory _rider){
        _rider = new Rider[](riders.length);
        uint count;
        for(uint i=0;i<riders.length; i++){
            if(riders[i].ended()){
                _rider[count] = riders[i];
                count++;
            }
        }
      }  
    
    
    //  Rider[] public riders;
    //  uint disabledCount;

    // event RiderCreated(address riderAddress, uint _lowestFareAmount, uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal);

    //  function createRider(uint _lowestFareAmount, uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal) external{
    //   Rider rider = new Rider( _lowestFareAmount, _durationMin,  distanceKm,  _startPostal,  _endPostal, riders.length);
    //   riders.push(rider);
    //   emit RiderCreated(address(rider), _lowestFareAmount, _durationMin,  distanceKm,  _startPostal,  _endPostal);
    //  }

    //  function getRiders() external view returns(Rider[] memory _riders){
    //   _riders = new Rider[](riders.length- disabledCount);
    //   uint count;
    //   for(uint i=0;i<riders.length; i++){
    //       if(riders[i].isEnabled()){
    //          _riders[count] = riders[i];
    //          count++;
    //       }
    //     }
    //  }  
     
     

    //  function disable(Rider rider) external {
    //     riders[rider.index()].disable();
    //     disabledCount++;
    //  }
 
}


contract Rider {
    
    address payable public passenger;
    uint public auctionEndTime;
    uint public startPostal;
    uint public endPostal;
    
    uint public recommendedFare;
    
    address public driver;
    uint256 public lowestFareAmount;

    bool public ended = false;

    // bool public isEnabled;
    // uint public index;
    
    address private _factory;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns; // works like dictionary
    
    // Events that will be emitted on changes.
    event fareBidAmountDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event locations(uint Postal);
    
    
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is a bid that is lower or matches your bid
    error BidNotLowEnough(uint lowestFareAmount);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();
    /// You can place a bid on your own contract
    error PassengerCannotBid();
    /// You are not authorized to end the Auction
    error YouCannotEndAuction();
    /// Your payment != lowestFareAmount
    error YourPaymentDoesNotMatchLowestBid();
    /// You cannot withdrawal
    error YouCannotWithdraw();


     modifier onlyOwner(address caller) {
        require(caller == passenger, "You're not the owner of the contract");
        _;
    }
    
        modifier onlyFactory() {
        require(msg.sender == _factory, "You need to use the factory");
        _;
    }

    
    constructor (address _passenger, uint _lowestFareAmount,uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal) payable { 
        passenger = payable(_passenger); // this sets the passenger wallet address as a public variable that can be accessed
        // require(passenger==address(0), "Invalid address");
        startPostal = _startPostal; 
        endPostal = _endPostal; 
        auctionEndTime = block.timestamp + _durationMin * 60; // time the passenger is willing to wait (min) 
        recommendedFare = distanceKm * 2;
        lowestFareAmount = _lowestFareAmount;
        pendingReturns[passenger] += _lowestFareAmount;
        
        // isEnabled = true;
        // index = _index;
    }
    
    function placeBid() public payable { 
        
        
        // Revert the call if the bidding
        // period is over.
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
     
        // If the bid is not lower, send the
        // money back (the revert statement
        // will revert all changes in this
        // function execution including
        // it having received the money).
        if (msg.value >= lowestFareAmount)
            revert BidNotLowEnough(lowestFareAmount);
        
        // store the amount into a dictionary so that people can withdraw the amount themselves
        if(lowestFareAmount != 0)
            pendingReturns[driver] += lowestFareAmount;
        
        driver = msg.sender;
        lowestFareAmount = msg.value;
        emit fareBidAmountDecreased(msg.sender, msg.value);
        
    }
    
    function withdrawal(address caller) public returns (bool) {
        uint amount = pendingReturns[caller]; // check the amount they need to receive
        
        if  (!ended && (passenger == caller || driver == caller)) 
            revert YouCannotWithdraw();
        
        if (amount > 0) {
            pendingReturns[caller] = 0;
            
            if (!payable(caller).send(amount)){
                pendingReturns[caller] = amount;
                return false;
            }
            
        }
        return true;
    }
    
   
    
    function auctionEnd(address caller) public onlyFactory onlyOwner(caller){
        if (passenger == caller) {
            pendingReturns[passenger] -= lowestFareAmount;
            pendingReturns[driver] += (2*lowestFareAmount);
            ended = true;
            
            // isEnabled = false;

            emit AuctionEnded(driver, lowestFareAmount);
        }
        else 
            revert YouCannotEndAuction();
    }
    
    
    // function disable() external{
    //     isEnabled = false;
    // }
      
    
}