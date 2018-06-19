pragma solidity ^0.4.11;

/*

Status Buyer
========================

Buys Status tokens from the crowdsale on your behalf.
Author: /u/Cintix

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

// Interface to Status ICO Contract
contract StatusContribution {
  uint256 public maxGasPrice;
  uint256 public startBlock;
  uint256 public totalNormalCollected;
  uint256 public finalizedBlock;
  function proxyPayment(address _th) payable returns (bool);
}

// Interface to Status Cap Determination Contract
contract DynamicCeiling {
  function curves(uint currentIndex) returns (bytes32 hash, 
                                              uint256 limit, 
                                              uint256 slopeFactor, 
                                              uint256 collectMinimum);
  uint256 public currentIndex;
  uint256 public revealedCurves;
}

contract StatusBuyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public deposits;
  // Track how much SNT each account would have been able to purchase on their own.
  mapping (address => uint256) public simulated_snt;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought tokens yet.
  bool public bought_tokens;
  
  // The Status Token Sale address.
  StatusContribution public sale = StatusContribution(0x55d34b686aa8C04921397c5807DB9ECEdba00a4c);
  // The Status DynamicCeiling Contract address.
  DynamicCeiling public dynamic = DynamicCeiling(0xc636e73Ff29fAEbCABA9E0C3f6833EaD179FFd5c);
  // Status Network Token (SNT) Contract address.
  ERC20 public token = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
  // The developer address.
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
  // Withdraws all ETH/SNT owned by the user in the ratio currently owned by the contract.
  function withdraw() {
    // Store the user&#39;s deposit prior to withdrawal in a temporary variable.
    uint256 user_deposit = deposits[msg.sender];
    // Update the user&#39;s deposit prior to sending ETH to prevent recursive call.
    deposits[msg.sender] = 0;
    // Retrieve current ETH balance of contract (less the bounty).
    uint256 contract_eth_balance = this.balance - bounty;
    // Retrieve current SNT balance of contract.
    uint256 contract_snt_balance = token.balanceOf(address(this));
    // Calculate total SNT value of ETH and SNT owned by the contract.
    // 1 ETH Wei -> 10000 SNT Wei
    uint256 contract_value = (contract_eth_balance * 10000) + contract_snt_balance;
    // Calculate amount of ETH to withdraw.
    uint256 eth_amount = (user_deposit * contract_eth_balance * 10000) / contract_value;
    // Calculate amount of SNT to withdraw.
    uint256 snt_amount = 10000 * ((user_deposit * contract_snt_balance) / contract_value);
    // No fee for withdrawing if user would have made it into the crowdsale alone.
    uint256 fee = 0;
    // 1% fee on portion of tokens user would not have been able to buy alone.
    if (simulated_snt[msg.sender] < snt_amount) {
      fee = (snt_amount - simulated_snt[msg.sender]) / 100;
    }
    // Send the funds.  Throws on failure to prevent loss of funds.
    if(!token.transfer(msg.sender, snt_amount - fee)) throw;
    if(!token.transfer(developer, fee)) throw;
    msg.sender.transfer(eth_amount);
  }
  
  // Allow anyone to contribute to the buy execution bounty.
  function add_to_bounty() payable {
    // Disallow adding to the bounty if contract has already bought the tokens.
    if (bought_tokens) throw;
    // Update bounty to include received amount.
    bounty += msg.value;
  }
  
  // Allow users to simulate entering the crowdsale to avoid the fee.  Callable by anyone.
  function simulate_ico() {
    // Limit maximum gas price to the same value as the Status ICO (50 GWei).
    if (tx.gasprice > sale.maxGasPrice()) throw;
    // Restrict until after the ICO has started.
    if (block.number < sale.startBlock()) throw;
    if (dynamic.revealedCurves() == 0) throw;
    // Extract the buy limit and rate-limiting slope factor of the current curve/cap.
    uint256 limit;
    uint256 slopeFactor;
    (,limit,slopeFactor,) = dynamic.curves(dynamic.currentIndex());
    // Retrieve amount of ETH the ICO has collected so far.
    uint256 totalNormalCollected = sale.totalNormalCollected();
    // Verify the ICO is not currently at a cap, waiting for a reveal.
    if (limit <= totalNormalCollected) throw;
    // Add the maximum contributable amount to the user&#39;s simulated SNT balance.
    simulated_snt[msg.sender] += ((limit - totalNormalCollected) / slopeFactor);
  }
  
  // Buys tokens in the crowdsale and rewards the sender.  Callable by anyone.
  function buy() {
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Record that the contract has bought tokens first to prevent recursive call.
    bought_tokens = true;
    // Transfer all the funds (less the bounty) to the Status ICO contract 
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has 
    // already completed, preventing loss of funds.
    sale.proxyPayment.value(this.balance - bounty)(address(this));
    // Send the user their bounty for buying tokens for the contract.
    msg.sender.transfer(bounty);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
    if (!bought_tokens) {
      // Update records of deposited ETH to include the received amount.
      deposits[msg.sender] += msg.value;
      // Block each user from contributing more than 30 ETH.  No whales!  >:C
      if (deposits[msg.sender] > 30 ether) throw;
    }
    else {
      // Reject ETH sent after the contract has already purchased tokens.
      if (msg.value != 0) throw;
      // If the ICO isn&#39;t over yet, simulate entering the crowdsale.
      if (sale.finalizedBlock() == 0) {
        simulate_ico();
      }
      else {
        // Withdraw user&#39;s funds if they sent 0 ETH to the contract after the ICO.
        withdraw();
      }
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Avoid recursively buying tokens when the sale contract refunds ETH.
    if (msg.sender == address(sale)) return;
    // Delegate to the helper function.
    default_helper();
  }
}