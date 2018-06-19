pragma solidity ^0.4.11;

/*
  Allows owner/seller to deposit ETH in order to participate in
  an ICO on behalf of the contract so that users can buy directly
  from this contract with assurances that they will receive their
  tokens via a user-invoked withdrawal() call once the ICO token
  creator releases tokens for trading.

  This affords users the ability to reserve/claim tokens that they
  were not able to buy in an ICO, before they hit the exchanges.

*/
contract DaoCasinoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BETSale {
  // Store the amount of BET purchased by a buyer
  mapping (address => uint256) public bet_purchased;

  // Store the amount of ETH sent in by a buyer. Good to have this record just in case
  mapping (address => uint256) public eth_sent;

  // Total BET available to sell
  uint256 public total_bet_available;

  // Total BET purchased by all buyers
  uint256 public total_bet_purchased;

  // Total BET withdrawn by all buyers
  uint256 public total_bet_withdrawn;

  // BET per ETH (price)
  uint256 public price_per_eth = 900;

  //  BET token contract address (IOU offering)
  DaoCasinoToken public token = DaoCasinoToken(0x725803315519de78D232265A8f1040f054e70B98);

  // The seller&#39;s address
  address seller = 0xB00Ae1e677B27Eee9955d632FF07a8590210B366;

  // Halt further purchase ability just in case
  bool public halt_purchases;

  /*
    Safety to withdraw all tokens, ONLY if all buyers have already withdrawn their purchases
  */
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    if(total_bet_withdrawn != total_bet_purchased) throw;

    // reset everything
    total_bet_available = 0;
    total_bet_purchased = 0;
    total_bet_withdrawn = 0;

    token.transfer(seller, token.balanceOf(address(this)));
  }

  /*
    Safety to withdraw ETH
  */
  function withdrawETH() {
    if(msg.sender != seller) throw;
    msg.sender.transfer(this.balance);
  }

  /*
    Initiate ICO purchase
  */
  function buyTokens() payable {
    if(msg.sender != seller) throw;
    if(token.totalEthers() < token.CAP()) {
      token.proxyPayment.value(this.balance)(address(this));
    }
  }

  /*
    Update available BET to purchase
  */
  function updateAvailability(uint256 _bet_amount) {
    if(msg.sender != seller) throw;
    total_bet_available += _bet_amount;
  }

  /*
    Update BET price
  */
  function updatePrice(uint256 _price) {
    if(msg.sender != seller) throw;
    price_per_eth = _price;
  }

  /*
    Safety to prevent anymore purchases/sales from occurring in the event of
    unforeseen issue. Buyer token withdrawals still allowed
  */
  function haltPurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = true;
  }

  function resumePurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = false;
  }

  function withdraw() {
    // Dismiss any early or ill attempts at withdrawing
    if(token.balanceOf(address(this)) == 0 || bet_purchased[msg.sender] == 0) throw;

    uint256 bet_to_withdraw = bet_purchased[msg.sender];

    // Clear record of buyer&#39;s BET balance before transferring out
    bet_purchased[msg.sender] = 0;

    total_bet_withdrawn += bet_to_withdraw;

    // Distribute tokens to the buyer
    if(!token.transfer(msg.sender, bet_to_withdraw)) throw;
  }

  function purchase() payable {
    if(halt_purchases) throw;

    // Determine amount of tokens user wants to/can buy
    uint256 bet_to_purchase = price_per_eth * msg.value;

    // Check if we have enough BET left to sell
    if((total_bet_purchased + bet_to_purchase) > total_bet_available) throw;

    // Update the amount of BET purchased by user. Also keep track of the total ETH they sent in
    bet_purchased[msg.sender] += bet_to_purchase;
    eth_sent[msg.sender] += msg.value;

    // Update the total amount of BET purchased by all buyers over all periods of availability
    total_bet_purchased += bet_to_purchase;

    // Tokens are clearly in the contract, therefore we can release ETH to seller&#39;s address
    seller.transfer(msg.value);
  }

  // Fallback function/entry point
  function () payable {
    if(msg.value == 0) {
      withdraw();
    }
    else {
      if(msg.sender == seller) {
        return;
      }
      purchase();
    }
  }
}