pragma solidity ^0.4.18;

contract EtherAuction {

  // The address that deploys this auction and volunteers 1 eth as price.
  address public auctioneer;
  uint public auctionedEth = 0;

  uint public highestBid = 0;
  uint public secondHighestBid = 0;

  address public highestBidder;
  address public secondHighestBidder;

  uint public latestBidTime = 0;
  uint public auctionEndTime;

  mapping (address => uint) public balances;

  bool public auctionStarted = false;
  bool public auctionFinalized = false;

  event E_AuctionStarted(address _auctioneer, uint _auctionStart, uint _auctionEnd);
  event E_Bid(address _highestBidder, uint _highestBid);
  event E_AuctionFinished(address _highestBidder,uint _highestBid,address _secondHighestBidder,uint _secondHighestBid,uint _auctionEndTime);

  function EtherAuction(){
    auctioneer = msg.sender;
  }

  // The auctioneer has to call this function while supplying the 1th to start the auction
  function startAuction() public payable{
    require(!auctionStarted);
    require(msg.sender == auctioneer);
    require(msg.value == (1 * 10 ** 18));
    auctionedEth = msg.value;
    auctionStarted = true;
    auctionEndTime = now + (3600 * 24 * 7); // Ends 7 days after the deployment of the contract

    E_AuctionStarted(msg.sender,now, auctionEndTime);
  }

  //Anyone can bid by calling this function and supplying the corresponding eth
  function bid() public payable {
    require(auctionStarted);
    require(now < auctionEndTime);
    require(msg.sender != auctioneer);
    require(highestBidder != msg.sender); //If sender is already the highest bidder, reject it.

    address _newBidder = msg.sender;

    uint previousBid = balances[_newBidder];
    uint _newBid = msg.value + previousBid;

    require (_newBid  == highestBid + (5 * 10 ** 16)); //Each bid has to be 0.05 eth higher

    // The highest bidder is now the second highest bidder
    secondHighestBid = highestBid;
    secondHighestBidder = highestBidder;

    highestBid = _newBid;
    highestBidder = _newBidder;

    latestBidTime = now;
    //Update the bidder&#39;s balance so they can later withdraw any pending balance
    balances[_newBidder] = _newBid;

    //If there&#39;s less than an hour remaining and someone bids, extend end time.
    if(auctionEndTime - now < 3600)
      auctionEndTime += 3600; // Each bid extends the auctionEndTime by 1 hour

    E_Bid(highestBidder, highestBid);
  }

  // Once the auction end has been reached, we distribute the ether.
  function finalizeAuction() public {
    require (now > auctionEndTime);
    require (!auctionFinalized);
    auctionFinalized = true;

    if(highestBidder == address(0)){
      //If no one bid at the auction, auctioneer can withdraw the funds.
      balances[auctioneer] = auctionedEth;
    }else{
      // Second highest bidder gets nothing, his latest bid is lost and sent to the auctioneer
      balances[secondHighestBidder] -= secondHighestBid;
      balances[auctioneer] += secondHighestBid;

      //Auctioneer gets the highest bid from the highest bidder.
      balances[highestBidder] -= highestBid;
      balances[auctioneer] += highestBid;

      //winner gets the 1eth being auctioned.
      balances[highestBidder] += auctionedEth;
      auctionedEth = 0;
    }

    E_AuctionFinished(highestBidder,highestBid,secondHighestBidder,secondHighestBid,auctionEndTime);

  }

 //Once the auction has finished, the bidders can withdraw the eth they put
 //Winner will withdraw the auctionedEth
 //Auctioneer will withdraw the highest bid from the winner
 //Second highest bidder will already have his balance at 0
 //The rest of the bidders get their money back
 function withdrawBalance() public{
   require (auctionFinalized);

   uint ethToWithdraw = balances[msg.sender];
   if(ethToWithdraw > 0){
     balances[msg.sender] = 0;
     msg.sender.transfer(ethToWithdraw);
   }

 }
}