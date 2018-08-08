pragma solidity ^0.4.13;

/*

Aventus Buyer
========================

credit to /u/Cintix

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Buyer {
  // Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  // Bounty for executing buy.
  uint256 public buy_bounty;
  // Bounty for executing withdrawals.
  uint256 public withdraw_bounty;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  // Emergency kill switch in case a critical bug is found.
  bool public kill_switch;

  // SHA3 hash of kill switch password.
  bytes32 password_hash = 0xbeb7247422d4e22a0cf0085c07b37aca88a1958e4da1ca1947e53a5adf5c0499;
  // Earliest time contract is allowed to buy into the crowdsale.
  uint256 public earliest_buy_time = 1505304000;
  // Maximum amount of user ETH contract will accept.  Reduces risk of hard cap related failure.
  uint256 public eth_cap = 5000 ether;
  // The developer address.
  address public developer = 0x53b1606bc4540f90daad2b05110f6cc0b42daefa;
  // The crowdsale address.  Settable by the developer.
  address public sale = 0x8b7B6C61238088593BF75eEC8FBF58D0a615d30c;
  // The token address.  Settable by the developer.
  ERC20 public token = ERC20(0x0d88eD6E74bbFD96B831231638b66C05571e824F);

  // Allows the developer to set the crowdsale and token addresses.
  // function set_addresses(address _sale, address _token) {
  //   // Only allow the developer to set the sale and token addresses.
  //   require(msg.sender == developer);
  //   // Only allow setting the addresses once.
  //   require(sale == 0x0);
  //   // Set the crowdsale and token addresses.
  //   sale = _sale;
  //   token = ERC20(_token);
  // }

  // Allows the developer or anyone with the password to shut down everything except withdrawals in emergencies.
  function activate_kill_switch(string password) {
    // Only activate the kill switch if the sender is the developer or the password is correct.
    require(msg.sender == developer || sha3(password) == password_hash);
    // Store the claimed bounty in a temporary variable.
    // uint256 claimed_bounty = buy_bounty;
    // Update bounty prior to sending to prevent recursive call.
    // buy_bounty = 0;
    // Irreversibly activate the kill switch.
    kill_switch = true;
    // Send the caller their bounty for activating the kill switch.
    // msg.sender.transfer(claimed_bounty);
  }

  // Withdraws all ETH deposited or tokens purchased by the given user and rewards the caller.
  function withdraw(address user){
    // Only allow withdrawals after the contract has had a chance to buy in.
    require(bought_tokens || now > earliest_buy_time + 1 hours);
    // Short circuit to save gas if the user doesn&#39;t have a balance.
    if (balances[user] == 0) return;
    // If the contract failed to buy into the sale, withdraw the user&#39;s ETH.
    if (!bought_tokens) {
      // Store the user&#39;s balance prior to withdrawal in a temporary variable.
      uint256 eth_to_withdraw = balances[user];
      // Update the user&#39;s balance prior to sending ETH to prevent recursive call.
      balances[user] = 0;
      // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
      user.transfer(eth_to_withdraw);
    }
    // Withdraw the user&#39;s tokens if the contract has purchased them.
    else {
      // Retrieve current token balance of contract.
      uint256 contract_token_balance = token.balanceOf(address(this));
      // Disallow token withdrawals if there are no tokens to withdraw.
      require(contract_token_balance != 0);
      // Store the user&#39;s token balance in a temporary variable.
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
      // Update the value of tokens currently held by the contract.
      contract_eth_value -= balances[user];
      // Update the user&#39;s balance prior to sending to prevent recursive call.
      balances[user] = 0;
      // 1% fee if contract successfully bought tokens.
      uint256 fee = tokens_to_withdraw / 200;
      // Send the fee to the developer.
      require(token.transfer(developer, fee));
      // Send the funds.  Throws on failure to prevent loss of funds.
      require(token.transfer(user, tokens_to_withdraw - fee));
    }
    // Each withdraw call earns 1% of the current withdraw bounty.
    // uint256 claimed_bounty = withdraw_bounty / 100;
    // Update the withdraw bounty prior to sending to prevent recursive call.
    // withdraw_bounty -= claimed_bounty;
    // Send the caller their bounty for withdrawing on the user&#39;s behalf.
    // msg.sender.transfer(claimed_bounty);
  }

  // Allows developer to add ETH to the buy execution bounty.
  function add_to_buy_bounty() payable {
    // Only allow the developer to contribute to the buy execution bounty.
    require(msg.sender == developer);
    // Update bounty to include received amount.
    buy_bounty += msg.value;
  }

  // Allows developer to add ETH to the withdraw execution bounty.
  // function add_to_withdraw_bounty() payable {
  //   // Only allow the developer to contribute to the buy execution bounty.
  //   require(msg.sender == developer);
  //   // Update bounty to include received amount.
  //   withdraw_bounty += msg.value;
  // }

  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function claim_bounty(){
    // Short circuit to save gas if the contract has already bought tokens.
    if (bought_tokens) return;
    // Short circuit to save gas if the earliest buy time hasn&#39;t been reached.
    if (now < earliest_buy_time) return;
    // Short circuit to save gas if kill switch is active.
    if (kill_switch) return;
    // Disallow buying in if the developer hasn&#39;t set the sale address yet.
    require(sale != 0x0);
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    // Store the claimed bounty in a temporary variable.
    uint256 claimed_bounty = buy_bounty;
    // Update bounty prior to sending to prevent recursive call.
    buy_bounty = 0;
    // Record the amount of ETH sent as the contract&#39;s current value.
    contract_eth_value = this.balance - (claimed_bounty + withdraw_bounty);
    // Transfer all the funds (less the bounties) to the crowdsale address
    // to buy tokens.  Throws if the crowdsale hasn&#39;t started yet or has
    // already completed, preventing loss of funds.
    require(sale.call.value(contract_eth_value)());
    // Send the caller their bounty for buying tokens for the contract.
    msg.sender.transfer(claimed_bounty);
  }

  // Default function.  Called when a user sends ETH to the contract.
  function () payable {
    // Disallow deposits if kill switch is active.
    require(!kill_switch);
    // Only allow deposits if the contract hasn&#39;t already purchased the tokens.
    require(!bought_tokens);
    // Only allow deposits that won&#39;t exceed the contract&#39;s ETH cap.
    require(this.balance < eth_cap);
    // Update records of deposited ETH to include the received amount.
    balances[msg.sender] += msg.value;
  }
}