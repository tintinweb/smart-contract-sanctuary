pragma solidity ^0.4.19;

// written by @iamdefinitelyahuman

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface ERC20 {
  function balanceOf(address _owner) external returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
}

interface WhiteList {
   function isPaidUntil (address addr) external view returns (uint);
}


contract PresalePool {

  // SafeMath is a library to ensure that math operations do not have overflow errors
  // https://zeppelin-solidity.readthedocs.io/en/latest/safemath.html
  using SafeMath for uint;
  
  // The contract has 2 stages:
  // 1 - The initial state. The owner is able to add addresses to the whitelist, and any whitelisted addresses can deposit or withdraw eth to the contract.
  // 2 - The eth is sent from the contract to the receiver. Unused eth can be claimed by contributors immediately. Once tokens are sent to the contract,
  //     the owner enables withdrawals and contributors can withdraw their tokens.
  uint8 public contractStage = 1;
  
  // These variables are set at the time of contract creation
  // address that creates the contract
  address public owner;
  uint maxContractBalance;
  // maximum eth amount (in wei) that can be sent by a whitelisted address
  uint contributionCap;
  // the % of tokens kept by the contract owner
  uint public feePct;
  // the address that the pool will be paid out to
  address public receiverAddress;
  
  // These constant variables do not change with each contract deployment
  // minimum eth amount (in wei) that can be sent by a whitelisted address
  uint constant public contributionMin = 100000000000000000;
  // maximum gas price allowed for deposits in stage 1
  uint constant public maxGasPrice = 50000000000;
  // whitelisting contract
  WhiteList constant public whitelistContract = WhiteList(0xf6E386FA4794B58350e7B4Cb32B6f86Fb0F357d4);
  bool whitelistIsActive = true;
  
  // These variables are all initially set to 0 and will be set at some point during the contract
  // epoch time that the next contribution caps become active
  uint public nextCapTime;
  // pending contribution caps
  uint public nextContributionCap;
  // block number of the last change to the receiving address (set if receiving address is changed, stage 1)
  uint public addressChangeBlock;
  // amount of eth (in wei) present in the contract when it was submitted
  uint public finalBalance;
  // array containing eth amounts to be refunded in stage 2
  uint[] public ethRefundAmount;
  // default token contract to be used for withdrawing tokens in stage 2
  address public activeToken;
  
  // data structure for holding the contribution amount, cap, eth refund status, and token withdrawal status for each whitelisted address
  struct Contributor {
    uint ethRefund;
    uint balance;
    uint cap;
    mapping (address => uint) tokensClaimed;
  }
  // mapping that holds the contributor struct for each whitelisted address
  mapping (address => Contributor) whitelist;
  
  // data structure for holding information related to token withdrawals.
  struct TokenAllocation {
    ERC20 token;
    uint[] pct;
    uint balanceRemaining;
  }
  // mapping that holds the token allocation struct for each token address
  mapping (address => TokenAllocation) distributionMap;
  
  
  // modifier for functions that can only be accessed by the contract creator
  modifier onlyOwner () {
    require (msg.sender == owner);
    _;
  }
  
  // modifier to prevent re-entrancy exploits during contract > contract interaction
  bool locked;
  modifier noReentrancy() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }
  
  // Events triggered throughout contract execution
  // These can be watched via geth filters to keep up-to-date with the contract
  event ContributorBalanceChanged (address contributor, uint totalBalance);
  event ReceiverAddressSet ( address _addr);
  event PoolSubmitted (address receiver, uint amount);
  event WithdrawalsOpen (address tokenAddr);
  event TokensWithdrawn (address receiver, address token, uint amount);
  event EthRefundReceived (address sender, uint amount);
  event EthRefunded (address receiver, uint amount);
  event ERC223Received (address token, uint value);
   
  // These are internal functions used for calculating fees, eth and token allocations as %
  // returns a value as a % accurate to 20 decimal points
  function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
    return numerator.mul(10 ** 20) / denominator;
  }
  
  // returns % of any number, where % given was generated with toPct
  function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
    return numerator.mul(pct) / (10 ** 20);
  }
  
  // This function is called at the time of contract creation,
  // it sets the initial variables and whitelists the contract owner.
  function PresalePool (address receiverAddr, uint contractCap, uint cap, uint fee) public {
    require (fee < 100);
    require (contractCap >= cap);
    owner = msg.sender;
    receiverAddress = receiverAddr;
    maxContractBalance = contractCap;
    contributionCap = cap;
    feePct = _toPct(fee,100);
  }
  
  // This function is called whenever eth is sent into the contract.
  // The send will fail unless the contract is in stage one and the sender has been whitelisted.
  // The amount sent is added to the balance in the Contributor struct associated with the sending address.
  function () payable public {
    if (contractStage == 1) {
      _ethDeposit();
    } else _ethRefund();
  }
  
  // Internal function for handling eth deposits during contract stage one.
  function _ethDeposit () internal {
    assert (contractStage == 1);
    require (!whitelistIsActive || whitelistContract.isPaidUntil(msg.sender) > now);
    require (tx.gasprice <= maxGasPrice);
    require (this.balance <= maxContractBalance);
    var c = whitelist[msg.sender];
    uint newBalance = c.balance.add(msg.value);
    require (newBalance >= contributionMin);
    if (nextCapTime > 0 && nextCapTime < now) {
      contributionCap = nextContributionCap;
      nextCapTime = 0;
    }
    if (c.cap > 0) require (newBalance <= c.cap);
    else require (newBalance <= contributionCap);
    c.balance = newBalance;
    ContributorBalanceChanged(msg.sender, newBalance);
  }
  
  // Internal function for handling eth refunds during stage two.
  function _ethRefund () internal {
    assert (contractStage == 2);
    require (msg.sender == owner || msg.sender == receiverAddress);
    require (msg.value >= contributionMin);
    ethRefundAmount.push(msg.value);
    EthRefundReceived(msg.sender, msg.value);
  }
  
  // This function is called to withdraw eth or tokens from the contract.
  // It can only be called by addresses that are whitelisted and show a balance greater than 0.
  // If called during stage one, the full eth balance deposited into the contract is returned and the contributor&#39;s balance reset to 0.
  // If called during stage two, the contributor&#39;s unused eth will be returned, as well as any available tokens.
  // The token address may be provided optionally to withdraw tokens that are not currently the default token (airdrops).
  function withdraw (address tokenAddr) public {
    var c = whitelist[msg.sender];
    require (c.balance > 0);
    if (contractStage == 1) {
      uint amountToTransfer = c.balance;
      c.balance = 0;
      msg.sender.transfer(amountToTransfer);
      ContributorBalanceChanged(msg.sender, 0);
    } else {
      _withdraw(msg.sender,tokenAddr);
    }  
  }
  
  // This function allows the contract owner to force a withdrawal to any contributor.
  function withdrawFor (address contributor, address tokenAddr) public onlyOwner {
    require (contractStage == 2);
    require (whitelist[contributor].balance > 0);
    _withdraw(contributor,tokenAddr);
  }
  
  // This internal function handles withdrawals during stage two.
  // The associated events will fire to notify when a refund or token allocation is claimed.
  function _withdraw (address receiver, address tokenAddr) internal {
    assert (contractStage == 2);
    var c = whitelist[receiver];
    if (tokenAddr == 0x00) {
      tokenAddr = activeToken;
    }
    var d = distributionMap[tokenAddr];
    require ( (ethRefundAmount.length > c.ethRefund) || d.pct.length > c.tokensClaimed[tokenAddr] );
    if (ethRefundAmount.length > c.ethRefund) {
      uint pct = _toPct(c.balance,finalBalance);
      uint ethAmount = 0;
      for (uint i=c.ethRefund; i<ethRefundAmount.length; i++) {
        ethAmount = ethAmount.add(_applyPct(ethRefundAmount[i],pct));
      }
      c.ethRefund = ethRefundAmount.length;
      if (ethAmount > 0) {
        receiver.transfer(ethAmount);
        EthRefunded(receiver,ethAmount);
      }
    }
    if (d.pct.length > c.tokensClaimed[tokenAddr]) {
      uint tokenAmount = 0;
      for (i=c.tokensClaimed[tokenAddr]; i<d.pct.length; i++) {
        tokenAmount = tokenAmount.add(_applyPct(c.balance,d.pct[i]));
      }
      c.tokensClaimed[tokenAddr] = d.pct.length;
      if (tokenAmount > 0) {
        require(d.token.transfer(receiver,tokenAmount));
        d.balanceRemaining = d.balanceRemaining.sub(tokenAmount);
        TokensWithdrawn(receiver,tokenAddr,tokenAmount);
      }  
    }
    
  }
  
  
  // This function is called by the owner to modify the contribution cap of a whitelisted address.
  // If the current contribution balance exceeds the new cap, the excess balance is refunded.
  function modifyIndividualCap (address addr, uint cap) public onlyOwner {
    require (contractStage == 1);
    require (cap <= maxContractBalance);
    var c = whitelist[addr];
    require (cap >= c.balance);
    c.cap = cap;
  }
  
  // This function is called by the owner to modify the cap.
  function modifyCap (uint cap) public onlyOwner {
    require (contractStage == 1);
    require (contributionCap <= cap && maxContractBalance >= cap);
    contributionCap = cap;
    nextCapTime = 0;
  }
  
  // This function is called by the owner to modify the cap at a future time.
  function modifyNextCap (uint time, uint cap) public onlyOwner {
    require (contractStage == 1);
    require (contributionCap <= cap && maxContractBalance >= cap);
    require (time > now);
    nextCapTime = time;
    nextContributionCap = cap;
  }
  
  // This function is called to modify the maximum balance of the contract.
  function modifyMaxContractBalance (uint amount) public onlyOwner {
    require (contractStage == 1);
    require (amount >= contributionMin);
    require (amount >= this.balance);
    maxContractBalance = amount;
    if (amount < contributionCap) contributionCap = amount;
  }
  
  function toggleWhitelist (bool active) public onlyOwner {
    whitelistIsActive = active;
  }
  
  // This callable function returns the total pool cap, current balance and remaining balance to be filled.
  function checkPoolBalance () view public returns (uint poolCap, uint balance, uint remaining) {
    if (contractStage == 1) {
      remaining = maxContractBalance.sub(this.balance);
    } else {
      remaining = 0;
    }
    return (maxContractBalance,this.balance,remaining);
  }
  
  // This callable function returns the balance, contribution cap, and remaining available balance of any contributor.
  function checkContributorBalance (address addr) view public returns (uint balance, uint cap, uint remaining) {
    var c = whitelist[addr];
    if (contractStage == 2) return (c.balance,0,0);
    if (whitelistIsActive && whitelistContract.isPaidUntil(addr) < now) return (c.balance,0,0);
    if (c.cap > 0) cap = c.cap;
    else cap = contributionCap;
    if (cap.sub(c.balance) > maxContractBalance.sub(this.balance)) return (c.balance, cap, maxContractBalance.sub(this.balance));
    return (c.balance, cap, cap.sub(c.balance));
  }
  
  // This callable function returns the token balance that a contributor can currently claim.
  function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint tokenAmount) {
    var c = whitelist[addr];
    var d = distributionMap[tokenAddr];
    for (uint i = c.tokensClaimed[tokenAddr]; i < d.pct.length; i++) {
      tokenAmount = tokenAmount.add(_applyPct(c.balance, d.pct[i]));
    }
    return tokenAmount;
  }
   
  // This function sets the receiving address that the contract will send the pooled eth to.
  // It can only be called by the contract owner if the receiver address has not already been set.
  // After making this call, the contract will be unable to send the pooled eth for 6000 blocks.
  // This limitation is so that if the owner acts maliciously in making the change, all whitelisted
  // addresses have ~24 hours to withdraw their eth from the contract.
  function setReceiverAddress (address addr) public onlyOwner {
    require (contractStage == 1);
    receiverAddress = addr;
    addressChangeBlock = block.number;
    ReceiverAddressSet(addr);
  }

  // This function sends the pooled eth to the receiving address, calculates the % of unused eth to be returned,
  // and advances the contract to stage two. It can only be called by the contract owner during stages one or two.
  // The amount to send (given in wei) must be specified during the call. As this function can only be executed once,
  // it is VERY IMPORTANT not to get the amount wrong.
  function submitPool (uint amountInWei) public onlyOwner noReentrancy {
    require (contractStage == 1);
    require (receiverAddress != 0x00);
    require (block.number >= addressChangeBlock.add(6000));
    if (amountInWei == 0) amountInWei = this.balance;
    require (contributionMin <= amountInWei && amountInWei <= this.balance);
    finalBalance = this.balance;
    require (receiverAddress.call.value(amountInWei).gas(msg.gas.sub(5000))());
    if (this.balance > 0) ethRefundAmount.push(this.balance);
    contractStage = 2;
    PoolSubmitted(receiverAddress, amountInWei);
  }
  
  // This function opens the contract up for token withdrawals.
  // It can only be called by the owner during stage two.  The owner specifies the address of an ERC20 token
  // contract that this contract has a balance in, and optionally a bool to prevent this token from being
  // the default withdrawal (in the event of an airdrop, for example).
  function enableTokenWithdrawals (address tokenAddr, bool notDefault) public onlyOwner noReentrancy {
    require (contractStage == 2);
    if (notDefault) {
      require (activeToken != 0x00);
    } else {
      activeToken = tokenAddr;
    }
    var d = distributionMap[tokenAddr];    
    if (d.pct.length==0) d.token = ERC20(tokenAddr);
    uint amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    require (amount > 0);
    if (feePct > 0) {
      require (d.token.transfer(owner,_applyPct(amount,feePct)));
    }
    amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    d.balanceRemaining = d.token.balanceOf(this);
    d.pct.push(_toPct(amount,finalBalance));
  }
  
  // This is a standard function required for ERC223 compatibility.
  function tokenFallback (address from, uint value, bytes data) public {
    ERC223Received (from, value);
  }
  
}