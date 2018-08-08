pragma solidity ^0.4.15;

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Equio {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record the time the contract bought the tokens.
  uint256 public time_bought;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;
  // Record the address of the contract creator
  address public creator;
  // The sale name.
  string name;
  // The sale address.
  address public sale; // = 0xA66d83716c7CFE425B44D0f7ef92dE263468fb3d; // config.get(&#39;saleAddress&#39;);
  // The token address.
  ERC20 public token; // = ERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942); // config.get(&#39;tokenAddress&#39;);
  // SHA3 hash of kill switch password.
  bytes32 password_hash; // = 0x8223cba4d8b54dc1e03c41c059667f6adb1a642a0a07bef5a9d11c18c4f14612; // config.get(&#39;password&#39;);
  // Earliest block contract is allowed to buy into the crowdsale.
  uint256 earliest_buy_block; // = 4170700; // config.get(&#39;block&#39;);
  // Earliest time contract is allowed to buy into the crowdsale. (unix time)
  uint256 earliest_buy_time; // config.get(&#39;block&#39;);

  function Equio(
    string _name,
    address _sale,
    address _token,
    bytes32 _password_hash,
    uint256 _earliest_buy_block,
    uint256 _earliest_buy_time
  ) payable {
      creator = msg.sender;
      name = _name;
      sale = _sale;
      token = ERC20(_token);
      password_hash = _password_hash;
      earliest_buy_block = _earliest_buy_block;
      earliest_buy_time = _earliest_buy_time;
  }

  // Withdraws all ETH deposited or tokens purchased by the user.
  // "internal" means this function is not externally callable.
  function withdraw(address user) internal {
    // If called before the ICO, cancel user&#39;s participation in the sale.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_to_withdraw = balances[user];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[user] = 0;
      // Return the user&#39;s funds. Throws on failure to prevent loss of funds.
      user.transfer(eth_to_withdraw);
    } else { // Withdraw the user&#39;s tokens if the contract has already purchased them.
      // Retrieve current token balance of contract.
      uint256 contract_token_balance = token.balanceOf(address(this));
      // Disallow token withdrawals if there are no tokens to withdraw.
      require(contract_token_balance > 0);
      // Store the user&#39;s token balance in a temporary variable.
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
      // Update the value of tokens currently held by the contract.
      contract_eth_value -= balances[user];
      // Update the user&#39;s balance prior to sending to prevent recursive call.
      balances[user] = 0;
      // Send the funds. Throws on failure to prevent loss of funds.
      // Use require here because this is doing ERC20.transfer [not <address>.transfer] which returns bool
      require(token.transfer(user, tokens_to_withdraw));
    }
  }

  // Withdraws for a given users. Callable by anyone
  // TODO: Do we want this?
  function auto_withdraw(address user){
    // TODO: why wait 1 hour
    // Only allow automatic withdrawals after users have had a chance to manually withdraw.
    require (bought_tokens && now > time_bought + 1 hours);
    // Withdraw the user&#39;s funds for them.
    withdraw(user);
  }

  // Buys tokens in the sale and rewards the caller, callable by anyone.
  function buy_sale(){
    // Short circuit to save gas if the contract has already bought tokens.
    require(bought_tokens);
    // Short circuit to save gas if the earliest buy time and block hasn&#39;t been reached.
    require(block.number < earliest_buy_block);
    require(now < earliest_buy_time);
    // Short circuit to save gas if kill switch is active.
    require(!kill_switch);
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Record the time the contract bought the tokens.
    time_bought = now;
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance;
    // Transfer all the funds to the crowdsale address
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    // TODO: is this always the correct way to send ETH to a sale? (It should be!)
    // This calls the sale contracts fallback function.
    require(sale.call.value(contract_eth_value)());
  }

  // Allows anyone with the password to shut down everything except withdrawals in emergencies.
  function activate_kill_switch(string password) {
    // Only activate the kill switch if the password is correct.
    require(sha3(password) == password_hash);
    // Irreversibly activate the kill switch.
    kill_switch = true;
  }

  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
    // Treat near-zero ETH transactions as withdrawal requests.
    if (msg.value <= 1 finney) {
      withdraw(msg.sender);
    } else { // Deposit the user&#39;s funds for use in purchasing tokens.
      // Disallow deposits if kill switch is active.
      require (!kill_switch);
      // TODO: do we care about this? Why not allow running investment?
      // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
      require (!bought_tokens);
      // Update records of deposited ETH to include the received amount.
      balances[msg.sender] += msg.value;
    }
  }

  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // TODO: How to handle sale contract refunding ETH?
    // Prevent sale contract from refunding ETH to avoid partial fulfillment.
    require(msg.sender != address(sale));
    // Delegate to the helper function.
    default_helper();
  }
}

contract EquioGenesis {

  /// Create a Equio conteact with `_name`, sale address `_sale`, token address `_token`,
  /// password hash `_password_hash`, earliest buy block `earliest_buy_block`,
  /// earliest buy time `_earliest_buy_time`.
  function generate (
    string _name,
    address _sale,
    address _token,
    bytes32 _password_hash,
    uint256 _earliest_buy_block,
    uint256 _earliest_buy_time
  ) returns (Equio equioAddess) {
    return new Equio(
      _name,
      _sale,
      _token,
      _password_hash,
      _earliest_buy_block,
      _earliest_buy_time
    );
  }
}