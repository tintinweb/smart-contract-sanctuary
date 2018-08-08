pragma solidity ^0.4.13;

/*

  Ziber.io Contract
  ========================
  Buys ZBR tokens from the DAO crowdsale on your behalf.
  Author: /u/Leo

*/


// Interface to ZBR ICO Contract
contract DaoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
}

contract ZiberToken {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Store whether or not each account would have made it into the crowdsale.
  mapping (address => bool) public checked_in;
  // Bounty for executing buy.
  uint256 public bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint256 public time_bought;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;
  
  /* Public variables of the token */
  string public name;
  string public symbol;
  uint8 public decimals;
  
  // Ratio of ZBR tokens received to ETH contributed
  // 1.000.000 BGP = 80.000.000 ZBR
  // 1ETH = 218 BGP (03.07.2017: https://www.coingecko.com/en/price_charts/ethereum/gbp)
  // 1 ETH = 17440 ZBR
  uint256 ZBR_per_eth = 17440;
  //Total ZBR Tokens Reserve
  uint256 ZBR_total_reserve = 100000000;
  // ZBR Tokens for Developers
  uint256 ZBR_dev_reserved = 10000000;
  // ZBR Tokens for Selling over ICO
  uint256 ZBR_for_selling = 80000000;
  // ZBR Tokens for Bounty
  uint256 ZBR_for_bounty= 10000000;
  // ETH for activate kill-switch in contract
  uint256 ETH_to_end = 50000 ether;
  uint registredTo;
  uint256 loadedRefund;
  uint256 _supply;
  string _name;
  string _symbol;
  uint8 _decimals;

  // The ZBR Token address and sale address are the same.
  DaoToken public token = DaoToken(0xa9d585CE3B227d69985c3F7A866fE7d0e510da50);
  // The developer address.
  address developer_address = 0x650887B33BFA423240ED7Bc4BD26c66075E3bEaf;


  /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ZiberToken() {
        /* if supply not given then generate 100 million of the smallest unit of the token */
        _supply = 10000000000;
        
        /* Unless you add other functions these variables will never change */
        balanceOf[msg.sender] = _supply;
        name = "ZIBER CW Tokens";     
        symbol = "ZBR";
        
        /* If you want a divisible token then add the amount of decimals the base unit has  */
        decimals = 2;
    }


    /// SafeMath contract - math operations with safety checks
    /// @author <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6703021127140a061513040809131506041302060a4904080a">[email&#160;protected]</a>
    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }

    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }


    /**
    * Allow load refunds back on the contract for the refunding.
    *
    * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
    */
    function loadRefund() payable {
      if(msg.value == 0) throw;
      loadedRefund = safeAdd(loadedRefund, msg.value);
    }

    /**
    * Investors can claim refund.
    */
    function refund() private  {
      uint256 weiValue = this.balance;
      if (weiValue == 0) throw;
      uint256 weiRefunded;
      weiRefunded = safeAdd(weiRefunded, weiValue);
      refund();
      if (!msg.sender.send(weiValue)) throw;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        /* if the sender doenst have enough balance then stop */
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        /* Notifiy anyone listening that this transfer took place */
        Transfer(msg.sender, _to, _value);
    }
  
  // Allows the developer to shut down everything except withdrawals in emergencies.
  function activate_kill_switch() {
    // Only allow the developer to activate the kill switch.
    if (msg.sender != developer_address) throw;
    // Irreversibly activate the kill switch.
    kill_switch = true;
  }
  
  // Withdraws all ETH deposited or ZBR purchased by the sender.
  function withdraw(){
    // If called before the ICO, cancel caller&#39;s participation in the sale.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_amount = balances[msg.sender];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[msg.sender] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      msg.sender.transfer(eth_amount);
    }
    // Withdraw the sender&#39;s tokens if the contract has already purchased them.
    else {
      // Store the user&#39;s ZBR balance in a temporary variable (1 ETHWei -> 2000 ZBRWei).
      uint256 ZBR_amount = balances[msg.sender] * ZBR_per_eth;
      // Update the user&#39;s balance prior to sending ZBR to prevent recursive call.
      balances[msg.sender] = 0;
      // No fee for withdrawing if the user would have made it into the crowdsale alone.
      uint256 fee = 0;
      // 1% fee if the user didn&#39;t check in during the crowdsale.
      if (!checked_in[msg.sender]) {
        fee = ZBR_amount / 100;
        // Send any non-zero fees to developer.
        if(!token.transfer(developer_address, fee)) throw;
      }
      // Send the user their tokens.  Throws if the crowdsale isn&#39;t over.
      if(!token.transfer(msg.sender, ZBR_amount - fee)) throw;
    }
  }
  
  // Allow developer to add ETH to the buy execution bounty.
  function add_to_bounty() payable {
    // Only allow the developer to contribute to the buy execution bounty.
    if (msg.sender != developer_address) throw;
    // Disallow adding to bounty if kill switch is active.
    if (kill_switch) throw;
    // Disallow adding to the bounty if contract has already bought the tokens.
    if (bought_tokens) throw;
    // Update bounty to include received amount.
    bounty += msg.value;
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function claim_bounty(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Disallow buying into the crowdsale if kill switch is active.
    if (kill_switch) throw;
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now + 1 days;
    // Transfer all the funds (less the bounty) to the ZBR crowdsale contract
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    token.proxyPayment.value(this.balance - bounty)(address(this));
    // Send the caller their bounty for buying tokens for the contract.
    if(this.balance > ETH_to_end)
    {
        msg.sender.transfer(bounty);
    }
    else {
        time_bought = now +  1 days * 9;
        if(this.balance > ETH_to_end) {
          msg.sender.transfer(bounty);
        }
      }
  }

    //Check is msg_sender is contract dev
  modifier onlyOwner() {
    if (msg.sender != developer_address) {
      throw;
    }
    _;
  }
  
  // Send fund when ico end
  function withdrawEth() onlyOwner {        
        msg.sender.transfer(this.balance);
  }
  
  //Kill contract
  function kill() onlyOwner {        
        selfdestruct(developer_address);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Check if ICO Started: 27.07.2017 12:00 GMT to get ETH
    if (now != 1500399644) throw;
    else {
      // Treat near-zero ETH transactions as check ins and withdrawal requests.
      if (msg.value <= 1 finney) {
        // Check in during the crowdsale.
        if (bought_tokens) {
          // Only allow checking in before the crowdsale has reached the cap.
          if (token.totalEthers() >= token.CAP()) throw;
          // Mark user as checked in, meaning they would have been able to enter alone.
          checked_in[msg.sender] = true;
        }
        // Withdraw funds if the crowdsale hasn&#39;t begun yet or is already over.
        else {
          withdraw();
        }
      }
      // Deposit the user&#39;s funds for use in purchasing tokens.
      else {
        // Disallow deposits if kill switch is active.
        if (kill_switch) throw;
        // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
        if (bought_tokens) throw;
        // Update records of deposited ETH to include the received amount.
        balances[msg.sender] += msg.value;
      }
    }
  }
  
  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Delegate to the helper function.
    default_helper();
  }
  
}