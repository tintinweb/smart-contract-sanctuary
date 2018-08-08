pragma solidity ^0.4.11;

contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

contract IOU {
  // Store the amount of IOUs purchased by a buyer
  mapping (address => uint256) public iou_purchased;

  // Store the amount of ETH sent in by a buyer
  mapping (address => uint256) public eth_sent;

  // Total IOUs available to sell
  uint256 public total_iou_available = 20000000000000000000;

  // Total IOUs purchased by all buyers
  uint256 public total_iou_purchased;

  //  BAT token contract address (IOU offering)
  ERC20 public token = ERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);

  // The seller&#39;s address (to receive ETH upon distribution, and for auth withdrawTokens())
  address seller = 0x00203F5b27CB688a402fBDBdd2EaF8542ffF72B6;

  // Safety to withdraw all tokens back to seller in the event any get stranded
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    token.transfer(seller, token.balanceOf(address(this)));
  }

  function withdrawEth() {
    if(msg.sender != seller) throw;
    msg.sender.transfer(this.balance);
  }

  function killya() {
    if(msg.sender != seller) throw;
    selfdestruct(seller);
  }

  function withdraw() payable {
    /*
      Main mechanism to ensure a buyer&#39;s purchase/ETH/IOU is safe.

      Refund the buyer&#39;s ETH if we&#39;re beyond the date of our distribution
      promise AND if the contract doesn&#39;t have an adequate amount of tokens
      to distribute to the buyer. If we&#39;re beyond the given date, yet there
      is an adequate amount of tokens in the contract&#39;s balance, then the
      buyer can withdraw accordingly. This allows buyers to withdraw well
      into the future if they need to. It also allows us to extend the sale.
      Time-sensitive ETH protection is only applicable if the contract
      doesn&#39;t have adequate tokens for the buyer.

      The "adequacy" check prevents the seller and/or third party attacker
      from locking down buyers&#39; ETH. i.e. The attacker sends 1 token into our
      contract to falsely signal that the contract has been filled and is ready
      for token distribution. If we simply check for a >0 token balance, we risk
      distribution errors AND stranding/locking the buyer&#39;s ETH.

      TODO: confirm there are no logical errors that will allow a buyer/attacker to
            withdraw ETH early/unauthorized/doubly/etc
    */
    if(block.number > 3943365 && iou_purchased[msg.sender] > token.balanceOf(address(this))) {
      // We didn&#39;t fulfill our promise to have adequate tokens withdrawable at xx time.
      // Refund the buyer&#39;s ETH automatically instead.
      uint256 eth_to_refund = eth_sent[msg.sender];

      // If the user doesn&#39;t have any ETH or tokens to withdraw, get out ASAP
      if(eth_to_refund == 0 || iou_purchased[msg.sender] == 0) throw;

      // Adjust total accurately in the event we allow purchases in the future
      total_iou_purchased -= iou_purchased[msg.sender];

      // Clear record of buyer&#39;s ETH and IOU balance before refunding
      eth_sent[msg.sender] = 0;
      iou_purchased[msg.sender] = 0;

      msg.sender.transfer(eth_to_refund);
      return; // ?
    }

    /*
      At this point, we are still before our distribution date promise.
      Check if there is an adequate amount of tokens in the contract yet
      and allow buyer&#39;s token withdrawal and seller&#39;s ETH distribution if so.

      TODO: confirm there are no logical errors that will allow a buyer/attacker to
            withdraw IOU tokens early/unauthorized/doubly/etc
    */
    if(token.balanceOf(address(this)) == 0 || iou_purchased[msg.sender] > token.balanceOf(address(this))) throw;

    uint256 iou_to_withdraw = iou_purchased[msg.sender];
    uint256 eth_to_release = eth_sent[msg.sender];

    // If the user doesn&#39;t have any IOUs or ETH to withdraw/release, get out ASAP
    if(iou_to_withdraw == 0 || eth_to_release == 0) throw;

    // Clear record of buyer&#39;s IOU and ETH balance before transferring out
    iou_purchased[msg.sender] = 0;
    eth_sent[msg.sender] = 0;

    // Distribute tokens to the buyer
    token.transfer(msg.sender, iou_to_withdraw);

    // Release buyer&#39;s ETH to the seller
    seller.transfer(eth_to_release);
  }

  function purchase() payable {
    // Check for pre-determined sale start time
    //if(block.number < 3960990) throw;
    // Check if sale window is still open or not (date of promised distribution - grace?)
    //if(block.number > 3990990) throw;

    // Determine amount of tokens user wants to/can buy
    uint256 iou_to_purchase = 8600 * msg.value; // price is 8600 per ETH

    // Check if we have enough IOUs left to sell
    if((total_iou_purchased + iou_to_purchase) > total_iou_available) throw;

    // Update the amount of IOUs purchased by user. Also keep track of the total ETH they sent in
    iou_purchased[msg.sender] += iou_to_purchase;
    eth_sent[msg.sender] += msg.value;

    // Update the total amount of IOUs purchased by all buyers
    total_iou_purchased += iou_to_purchase;
  }

  // Fallback function/entry point
  function () payable {
    if(msg.value == 0) { // If the user sent a 0 ETH transaction, withdraw()
      withdraw();
    }
    else { // If the user sent ETH, purchase IOU
      purchase();
    }
  }
}