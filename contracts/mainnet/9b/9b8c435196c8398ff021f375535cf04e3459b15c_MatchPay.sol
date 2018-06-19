pragma solidity ^0.4.11;

// Minimum version requirement



contract MPY {

  function getSupply() constant returns (uint256);

  /// Return address balance of tokens
  function balanceOf(address _owner) constant returns (uint256);

}



contract MatchPay {
    /* @title Master contract. MatchPay
       @param msg.sender owner address
    */

    struct dividend_right {
      uint _total_owed;
      uint _period;
    }

    uint genesis_date;
    uint current_period;

    address master;
    MPY token;

    bool is_payday ;
    uint dividends;
    mapping (address => dividend_right) dividends_redeemed;

    // -------------------------------------------------------------------------------------------

    // Only owner modifier
    modifier only_owner_once(address _who) { require(_who == master && token == address(0)); _; }

    // Is window open (first month after each genesis anniversary)
    modifier is_window_open() { require( (now - genesis_date) % 31536000 <= 2592000); _; }

    // Is window close
    modifier is_window_close() { require( (now - genesis_date) % 31536000 > 2592000); _; }

    // -------------------------------------------------------------------------------------------

    event Created(address indexed _who, address indexed _to_whom, address indexed _contract_address);

    // -------------------------------------------------------------------------------------------


    function MatchPay() {
      master = msg.sender;
      genesis_date = now;
      current_period = 0;
      is_payday = false;
    }


    // Sets token address (MPY)
    function setTokenAddress(address _MPYAddress) only_owner_once(msg.sender) returns (bool) {
      token = MPY(_MPYAddress);

      return true;
    }


    // Redeem dividends
    function redeem(uint _amount) is_window_open() returns (bool) {
      // If payday isn&#39;t flagged, flag it and freeze the dividends
      if (!is_payday) {
        is_payday = true;
        dividends = this.balance;
      }

      // Check balance of sender and total balance
      uint256 tokenBalance = token.balanceOf(msg.sender);
      if (tokenBalance == 0) return false;
      uint256 tokenSupply = token.getSupply();

      // Reset amount owed if necessary
      if (dividends_redeemed[msg.sender]._period != current_period) {
        dividends_redeemed[msg.sender]._total_owed = 0;
        dividends_redeemed[msg.sender]._period = current_period;
      }

      // Add _amount to total owed
      dividends_redeemed[msg.sender]._total_owed += _amount;

      // If proposed amount is viable, then give it to the owner
      if (dividends_redeemed[msg.sender]._total_owed * tokenSupply <= dividends * tokenBalance) {
        if (!msg.sender.send(_amount)) {
          dividends_redeemed[msg.sender]._total_owed -= _amount;
          return false;
        }
      }

      return true;
    }


    // Redeem dividends
    function switch_period() is_window_close() returns (bool) {
      // If payday is flagged, unflag it and reset the dividends
      if (is_payday) {
        is_payday = false;
        dividends = 0;
        current_period += 1;
        return true;
      } else {
        return false;
      }
    }


    // Collect fees
    function() payable {}
}