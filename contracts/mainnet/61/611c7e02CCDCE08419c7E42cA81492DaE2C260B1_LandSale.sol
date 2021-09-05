// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


interface ILand {
  function totalSupply() external view returns (uint256);
  function maximumSupply() external view returns (uint256);
  function mintToken(address account, uint256 count) external;
  function burnLastToken(address account) external;
}

contract LandSale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  struct Purchase {
    uint256 count;
    uint256 price;
  }

  // Land-DAO token contract interface
  ILand public tokenContract;

  // Stores the allowed minting count and token price for each whitelisted address
  mapping (address => Purchase) private _allowances;
  // Stores the list of purchases along with the pricing
  mapping (address => Purchase[]) private _purchases;

  // Indicates the number of fund addresses (including treasury)
  uint8 constant _fundsAddressCount = 5;
  // Stores the total amount of owed (unlocked) funds for the founders
  uint256 public unlockedFunds;
  // Stores the total amount of owed (locked) funds for the founders
  uint256 public lockedFunds;
  // Stores the total amount of owed funds for the treasury
  uint256 public reserveFunds;
  // Stores the list of addresses owned by the reserve (at 0-index) and founders
  address[] public fundsAddresses;
  // Stores the timestamp on which the locked funds can be withdrawn
  uint256 public fundsUnlockTimestamp;

  constructor() {
    // By default, all founder addresses are set to the owner
    for (uint8 i = 0; i < _fundsAddressCount; i++) {
      fundsAddresses.push(msg.sender);
    }
  }

  // Add this modifier to all functions which are only accessible by the finance related addresses
  modifier onlyFinance() {
    require(msg.sender == fundsAddresses[0] ||
    msg.sender == fundsAddresses[1] ||
    msg.sender == fundsAddresses[2] ||
    msg.sender == fundsAddresses[3] ||
    msg.sender == fundsAddresses[4], "Unauthorized Access");
    _;
  }


  function setTokenContract(address _newTokenContract) external onlyOwner {
    require(_newTokenContract != address(0), "Invalid Address");
    tokenContract = ILand(_newTokenContract);
  }

  function setFundsAddress(uint8 _index, address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    require(_index >= 0 && _index < _fundsAddressCount, "Invalid Index");
    fundsAddresses[_index] = _address;
  }

  // Set the allowance for the specified address
  function setAllowance(address _address, uint256 _count, uint256 _price) public onlyOwner {
    require(_address != address(0), "Invalid Address");
    _allowances[_address] = Purchase(_count, _price);
  }

  // Set the allowance for the specified address
  function batchSetAllowances(
    address[] calldata _addresses,
    uint256[] calldata _counts,
    uint256[] calldata _prices
  ) external onlyOwner {
    uint256 count = _addresses.length;

    for (uint8 i = 0; i < count; i++) {
      setAllowance(_addresses[i], _counts[i], _prices[i]);
    }
  }

  // Get the allowance for the specified address
  function allowance(address _address) public view returns (
    uint256 count,
    uint256 price
  ) {
    Purchase memory _allowance = _allowances[_address];
    count = _allowance.count;
    price = _allowance.price;
  }

  // Set the UNIX timestamp for the funds unlock time
  function setFundsUnlockTimestamp(uint256 _unlock) external onlyOwner {     
    fundsUnlockTimestamp = _unlock;
  }

  // Handles token purchases
  receive() external payable nonReentrant {
    // Check if tokens are still available for sale
    uint256 remainingTokenCount = tokenContract.maximumSupply() - tokenContract.totalSupply();
    require(remainingTokenCount > 0, "Sold Out");

    // Check if sufficient funds are sent, and that the address is whitelisted (has valid allowance)
    // with enough funds to purchase at least 1 token
    uint256 accountLimit;
    uint256 tokenPrice;
    (accountLimit, tokenPrice) = allowance(msg.sender);
    require(accountLimit > 0, "Not Whitelisted For The Sale Or Insufficient Allowance");
    require(msg.value >= tokenPrice, "Insufficient Funds");

    // Calculate the actual amount of tokens to be minted, which must be within the set limits
    uint256 specifiedAmount = (tokenPrice == 0 ? accountLimit : msg.value.div(tokenPrice));
    uint256 actualAmount = (specifiedAmount > accountLimit ? accountLimit : specifiedAmount);
    actualAmount = (remainingTokenCount < actualAmount ? remainingTokenCount : actualAmount);
    _allowances[msg.sender].count -= actualAmount;
    tokenContract.mintToken(msg.sender, actualAmount);

    uint256 totalSpent = actualAmount.mul(tokenPrice);
    if (totalSpent > 0) {
      // Update the total received funds for the founders' share (95%)
      // Half of which are locked for 30 days after the end of the sale
      uint256 totalFounderShare = totalSpent.mul(95).div(100);
      uint256 lockedShare = totalFounderShare.div(2);
      uint256 unlockedShare = totalFounderShare.sub(lockedShare);
      lockedFunds = lockedFunds.add(lockedShare);
      unlockedFunds = unlockedFunds.add(unlockedShare);

      // 0-index is reserved for the treasury (5%) fully unlocked
      reserveFunds = reserveFunds.add(totalSpent.sub(totalFounderShare));

      _purchases[msg.sender].push(Purchase(actualAmount, tokenPrice));
    }

    // Calculate any excess/unspent funds and transfer it back to the buyer
    uint256 unspent = msg.value.sub(totalSpent);
    if (unspent > 0) {
      payable(msg.sender).transfer(unspent);
    }
  }

  // Handles refund requests which would send back 50% of the price at the time of purchase
  // and also subsequently burn the last token minted for the address
  function refund() external nonReentrant {
    require(_purchases[msg.sender].length > 0, "No Refund Available");
    Purchase memory purchase = _purchases[msg.sender][_purchases[msg.sender].length - 1];
    uint256 refundAmount = purchase.price.div(2);
    require(refundAmount <= lockedFunds, "Insufficient Funds Available");

    // Update the purchase records and burn the token
    if (purchase.count > 1) {
      _purchases[msg.sender][_purchases[msg.sender].length - 1].count -= 1;
    } else {
      _purchases[msg.sender].pop();
    }

    // Deduct from the locked funds
    lockedFunds = lockedFunds.sub(refundAmount);

    tokenContract.burnLastToken(msg.sender);

    payable(msg.sender).transfer(refundAmount);
  }

  // Used by the fund addresses to withdraw any owed funds
  function withdraw() external onlyFinance {
    // Calculate total owed funds based on the timing of the withdrawal
    uint256 totalOwed;
    if (block.timestamp >= fundsUnlockTimestamp) {
      totalOwed = unlockedFunds.add(lockedFunds);
      unlockedFunds = 0;
      lockedFunds = 0;
    } else {
      totalOwed = unlockedFunds;
      unlockedFunds = 0;
    }

    require(totalOwed > 0, "Withdrawal Not Available");

    // Starting from 1, as 0 is for the treasury
    uint256 individualShare = totalOwed.div(_fundsAddressCount - 1);
    for (uint8 i = 1; i < _fundsAddressCount; i++) {
      payable(fundsAddresses[i]).transfer(individualShare);
    }

    // Doing the same for the treasury
    if (reserveFunds > 0) {
      uint256 owed = reserveFunds;
      reserveFunds = 0;
      payable(fundsAddresses[0]).transfer(owed);
    }
  }
}