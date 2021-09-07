/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

// 10,000 unique collectible eggs with proof of ownership stored on the Ethereum blockchain
//   _   _   _   _   _   _   _   _   _   _
//  / \ / \ / \ / \ / \ / \ / \ / \ / \ / \
// ( C | r | y | p | t | o | E | g | g | s )
//  \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
//
// Website:   https://www.cryptoeggs.com
// Discord:   https://discord.gg/63PEpwVR5J
// Telegram:  https://t.me/cryptoeggscom
// Twitter:   https://www.twitter.com/cryptoeggscom
//

contract CryptoEggs {
  // You can use this hash to verify the image file containing all the eggs
  string public imageHash =
    "a9874035a17b212660fa69a6fb7bfa7feaa03e88825410fb13124c41a6bf70cb";

  address owner;
  address private recAddress =
    address(0x96Acc8515A660Ee1d84Bf393FA871948AB35a758);

  string public standard = "CRYPTOEGGS";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  uint256 public totalInitialFreeEggs;

  uint256 public EggsRemainingToAssign = 0;

  // Inital Free Eggs tracker
  bool public allFreeEggsAssigned = false;
  uint256 public freeEggsRemainingToAssign = 0;

  mapping(uint256 => address) public eggIndexToAddress;

  /* This creates an array with all balances */
  mapping(address => uint256) public balanceOf;

  uint256[] assignedEggsArr;

  address[] public freeEggHolders;
  mapping(address => bool) public freeEggHolderKnown;

  struct Offer {
    bool isForSale;
    uint256 eggIndex;
    address seller;
    uint256 minValue; // in ether
    address onlySellTo; // specify to sell only to a specific person
  }

  struct Bid {
    bool hasBid;
    uint256 eggIndex;
    address bidder;
    uint256 value;
  }

  // A record of eggs that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping(uint256 => Offer) public eggsOfferedForSale;

  // A record of the highest egg bid
  mapping(uint256 => Bid) public eggBids;

  mapping(address => uint256) public pendingWithdrawals;

  event Assign(address indexed to, uint256 indexed eggIndex);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event EggTransfer(
    address indexed from,
    address indexed to,
    uint256 indexed eggIndex
  );
  event EggOffered(
    uint256 indexed eggIndex,
    uint256 minValue,
    address indexed toAddress,
    address indexed sellerAddress
  );
  event EggBidEntered(
    uint256 indexed eggIndex,
    uint256 value,
    address indexed fromAddress
  );
  event EggBidWithdrawn(
    uint256 indexed eggIndex,
    uint256 value,
    address indexed fromAddress
  );
  event EggBought(
    uint256 indexed eggIndex,
    uint256 value,
    address indexed fromAddress,
    address indexed toAddress
  );
  event EggNoLongerForSale(uint256 indexed eggIndex);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  constructor() payable {
    owner = msg.sender;
    totalInitialFreeEggs = 100; // Initial of 100 free eggs
    totalSupply = 10000; // Update total supply
    EggsRemainingToAssign = totalSupply;
    freeEggsRemainingToAssign = totalInitialFreeEggs;
    name = "CRYPTOEGGS"; // Set the name for display purposes
    symbol = "CEGG"; // Set the symbol for display purposes
    decimals = 0; // Amount of decimals for display purposes
  }

  function claimRandomFreeEgg(address to, uint256 eggIndex) public {
    require(eggIndexToAddress[eggIndex] == address(0x0));
    require(!allFreeEggsAssigned);
    require(freeEggsRemainingToAssign != 0, "No more free egs left");
    require(eggIndex <= 10000);
    require(!freeEggHolderKnown[to], "Already claimed a free egg!");

    if (eggIndexToAddress[eggIndex] != to) {
      if (eggIndexToAddress[eggIndex] != address(0x0)) {
        balanceOf[eggIndexToAddress[eggIndex]]--;
      } else {
        EggsRemainingToAssign--;
        freeEggsRemainingToAssign--;
      }
      eggIndexToAddress[eggIndex] = to;
      assignedEggsArr.push(eggIndex);
      balanceOf[to]++;

      freeEggHolders.push(to);
      freeEggHolderKnown[to] = true;

      emit Assign(to, eggIndex);
    }
  }

  function getRemainingFreeEgs() public view returns (uint256) {
    return freeEggsRemainingToAssign;
  }

  function buyRandomEgg(address _to, uint256 eggIndex) public payable {
    require(eggIndexToAddress[eggIndex] == address(0x0));
    require(msg.value != 0);
    require(msg.value >= 50000000000000000);
    require(eggIndex <= 10000);

    (bool sent, bytes memory data) = payable(recAddress).call{value: msg.value}(
      ""
    );
    require(sent, "Failed to send Ether");

    if (eggIndexToAddress[eggIndex] != _to) {
      if (eggIndexToAddress[eggIndex] != address(0x0)) {
        balanceOf[eggIndexToAddress[eggIndex]]--;
      } else {
        EggsRemainingToAssign--;
      }
      eggIndexToAddress[eggIndex] = _to;
      balanceOf[_to]++;
      emit Assign(_to, eggIndex);
    }
  }

  function buyUnclaimedEgg(address _to, uint256 eggIndex) public payable {
    require(eggIndexToAddress[eggIndex] == address(0x0));
    require(msg.value != 0);
    require(msg.value >= 100000000000000000);
    require(eggIndex <= 10000);

    (bool sent, bytes memory data) = payable(recAddress).call{value: msg.value}(
      ""
    );
    require(sent, "Failed to send Ether");

    if (eggIndexToAddress[eggIndex] != _to) {
      if (eggIndexToAddress[eggIndex] != address(0x0)) {
        balanceOf[eggIndexToAddress[eggIndex]]--;
      } else {
        EggsRemainingToAssign--;
      }
      eggIndexToAddress[eggIndex] = _to;
      balanceOf[_to]++;
      emit Assign(_to, eggIndex);
    }
  }

  // Transfer ownership of an egg to another user without requiring payment
  function transferEgg(address to, uint256 eggIndex) public {
    require(eggIndexToAddress[eggIndex] == msg.sender);
    require(eggIndex <= 10000);
    if (eggsOfferedForSale[eggIndex].isForSale) {
      eggNoLongerForSale(eggIndex);
    }
    eggIndexToAddress[eggIndex] = to;
    balanceOf[msg.sender]--;
    balanceOf[to]++;
    emit Transfer(msg.sender, to, 1);
    emit EggTransfer(msg.sender, to, eggIndex);
    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid storage bid = eggBids[eggIndex];
    if (bid.bidder == to) {
      // Kill bid and refund value
      pendingWithdrawals[to] += bid.value;
      eggBids[eggIndex] = Bid(false, eggIndex, address(0x0), 0);
    }
  }

  function eggNoLongerForSale(uint256 eggIndex) public {
    require(eggIndexToAddress[eggIndex] == msg.sender);
    require(eggIndex <= 10000);
    eggsOfferedForSale[eggIndex] = Offer(
      false,
      eggIndex,
      msg.sender,
      0,
      address(0x0)
    );
    emit EggNoLongerForSale(eggIndex);
  }

  function offerEggForSale(uint256 eggIndex, uint256 minSalePriceInWei) public {
    require(eggIndexToAddress[eggIndex] == msg.sender);
    require(eggIndex <= 10000);
    eggsOfferedForSale[eggIndex] = Offer(
      true,
      eggIndex,
      msg.sender,
      minSalePriceInWei,
      address(0x0)
    );
    emit EggOffered(eggIndex, minSalePriceInWei, address(0x0), msg.sender);
  }

  function offerEggForSaleToAddress(
    uint256 eggIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) public {
    require(eggIndexToAddress[eggIndex] != msg.sender);
    require(eggIndex >= 10000);
    eggsOfferedForSale[eggIndex] = Offer(
      true,
      eggIndex,
      msg.sender,
      minSalePriceInWei,
      toAddress
    );
    emit EggOffered(eggIndex, minSalePriceInWei, toAddress, msg.sender);
  }

  function buyEgg(uint256 eggIndex) public payable {
    Offer storage offer = eggsOfferedForSale[eggIndex];
    require(eggIndex <= 10000);
    require(offer.isForSale); // egg not actually for sale

    // Check this rule !!!!!!!!!!!!
    require(offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender); // egg not supposed to be sold to this user
    require(msg.value >= offer.minValue); // Didn't send enough ETH
    require(offer.seller == eggIndexToAddress[eggIndex]); // Seller no longer owner of egg

    address seller = offer.seller;

    eggIndexToAddress[eggIndex] = msg.sender;
    balanceOf[seller]--;
    balanceOf[msg.sender]++;
    emit Transfer(seller, msg.sender, 1);

    eggNoLongerForSale(eggIndex);
    pendingWithdrawals[seller] += msg.value;
    emit EggBought(eggIndex, msg.value, seller, msg.sender);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid storage bid = eggBids[eggIndex];
    if (bid.bidder == msg.sender) {
      // Kill bid and refund value
      pendingWithdrawals[msg.sender] += bid.value;
      eggBids[eggIndex] = Bid(false, eggIndex, address(0x0), 0);
    }
  }

  function withdraw() public {
    uint256 amount = pendingWithdrawals[msg.sender];
    uint256 fee = (amount / 100) * 3;
    uint256 amountMinusFee = amount - fee;
    // Remember to zero the pending refund before
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;
    payable(recAddress).transfer(fee);
    payable(msg.sender).transfer(amountMinusFee);
  }

  function enterBidForEgg(uint256 eggIndex) public payable {
    require(eggIndex <= 10000);
    require(eggIndexToAddress[eggIndex] != address(0x0));
    require(eggIndexToAddress[eggIndex] != msg.sender);
    require(msg.value != 0);
    Bid storage existing = eggBids[eggIndex];
    require(msg.value >= existing.value);
    if (existing.value > 0) {
      // Refund the failing bid
      pendingWithdrawals[existing.bidder] += existing.value;
    }
    eggBids[eggIndex] = Bid(true, eggIndex, msg.sender, msg.value);
    emit EggBidEntered(eggIndex, msg.value, msg.sender);
  }

  function acceptBidForEgg(uint256 eggIndex, uint256 minPrice) public {
    require(eggIndex <= 10000);
    require(eggIndexToAddress[eggIndex] == msg.sender);
    address seller = msg.sender;
    Bid storage bid = eggBids[eggIndex];
    require(bid.value != 0);
    require(bid.value >= minPrice);

    eggIndexToAddress[eggIndex] = bid.bidder;
    balanceOf[seller]--;
    balanceOf[bid.bidder]++;
    emit Transfer(seller, bid.bidder, 1);

    eggsOfferedForSale[eggIndex] = Offer(
      false,
      eggIndex,
      bid.bidder,
      0,
      address(0x0)
    );
    uint256 amount = bid.value;
    eggBids[eggIndex] = Bid(false, eggIndex, address(0x0), 0);
    pendingWithdrawals[seller] += amount;
    emit EggBought(eggIndex, amount, seller, bid.bidder);
  }

  function withdrawBidForEgg(uint256 eggIndex) public {
    require(eggIndex <= 10000);
    require(eggIndexToAddress[eggIndex] != address(0x0));
    require(eggIndexToAddress[eggIndex] != msg.sender);
    Bid storage bid = eggBids[eggIndex];
    require(bid.bidder == msg.sender);
    emit EggBidWithdrawn(eggIndex, bid.value, msg.sender);
    uint256 amount = bid.value;
    eggBids[eggIndex] = Bid(false, eggIndex, address(0x0), 0);
    // Refund the bid money
    payable(msg.sender).transfer(amount);
  }

  function getAllClaimedEggs() public view returns (uint256[] memory) {
    return assignedEggsArr;
  }
}