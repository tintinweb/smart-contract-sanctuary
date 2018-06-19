pragma solidity ^0.4.13;

/*

Lottery
========================

Allows users to participate in a game-theoretically sound lottery.
Author: /u/Cintix

*/

contract Lottery {
  // The Ticket struct encodes an address&#39; range of winning numbers.
  struct Ticket {
    // Offset from 0 of the Ticket&#39;s range of winning numbers.
    uint128 offset;
    // The value of the Ticket in Wei and the size of the range of winning numbers.
    uint128 value;
  }
  // Store the Ticket corresponding to each user&#39;s address.
  mapping (address => Ticket) public tickets;
  // Store the commited hash of each host.
  mapping (address => bytes32) public commits;
  // Store the number of hosts securing the lottery&#39;s RNG.
  uint256 public num_hosts;
  // Store the number of hosts that have revealed their secret random number.
  uint256 public num_hosts_revealed;
  // Store the host-generated random number that determines the lottery winner.
  uint256 public rng;
  // Boolean indicating whether the lottery has been cancelled.
  bool public cancelled;
  // Store total ETH spent by users on tickets.
  uint256 public total_user_eth;
  // Maximum total ETH users may spend on tickets.
  uint256 public total_user_eth_cap = 100 ether;
  // Cut of the winnings used to incentivize host participation.
  uint256 public host_percentage = 10;
  // Store end time of the ticket buying phase.
  uint256 public buy_end_time = 1503829813;
  // Store end time of the host commit phase.
  uint256 public commit_end_time = buy_end_time + 1 days;
  // Store end time of the host reveal phase.
  uint256 public reveal_end_time = commit_end_time + 1 days;
  
  // Cancel the lottery if the host quorum isn&#39;t met or a host failed to reveal in time.
  function cancel_lottery() {
    // Only allow canceling the lottery after the commit phase has ended.
    require(now > commit_end_time);
    // Determine whether there are enough hosts for trustless RNG.
    bool quorum_met = num_hosts >= 2;
    // Determine whether all hosts have revealed their secret random numbers.
    bool all_hosts_revealed = num_hosts == num_hosts_revealed;
    // Determine whether the reveal phase has ended.
    bool reveal_phase_ended = now > reveal_end_time;
    // Only allow canceling the lottery if the quorum hasn&#39;t been met or not all hosts revealed.
    require(!quorum_met || (!all_hosts_revealed && reveal_phase_ended));
    // Irreversibly cancel the lottery.
    cancelled = true;
  }
  
  // Adds a host to the lottery, increasing the security of the lottery&#39;s random number generation.
  function host_lottery(bytes32 commit) payable {
    // Hosts must guarantee their hashed secret random number up to the value of the lottery.
    require(msg.value == total_user_eth);
    // Only allow new hosts to join during the lottery&#39;s commit phase.
    require((now > buy_end_time) && (now <= commit_end_time));
    // Sanity check hashed secret and only allow each host to join once.
    require((commit != 0) && (commits[msg.sender] == 0));
    // Store the host&#39;s hashed secret random number.
    commits[msg.sender] = commit;
    // Increment the host counter to account for the new host.
    num_hosts += 1;
  }
  
  // Allows anyone to steal a host&#39;s committed ETH if their secret random number isn&#39;t random or isn&#39;t secret.
  function steal_reveal(address host, uint256 secret_random_number) {
    // Only allow stealing during the lottery&#39;s commit phase to prevent higher-gas-tx-sniping host reveals.
    require((now > buy_end_time) && (now <= commit_end_time));
    // Verify the secret random number matches the committed hash.
    require(commits[host] == keccak256(secret_random_number));
    // Irreversibly cancel the lottery, as rng is compromised.
    cancelled = true;
    // Update commitment prior to sending ETH to prevent recursive call.
    commits[host] = 0;
    // Send the thief the host&#39;s committed ETH.
    msg.sender.transfer(total_user_eth);
  }
  
  // Allow hosts to reveal their secret random number during the lottery&#39;s reveal phase.
  function host_reveal(uint256 secret_random_number) {
    // Only allow revealing during the lottery&#39;s reveal phase.
    require((now > commit_end_time) && (now <= reveal_end_time));
    // Verify the secret random number matches the committed hash.
    require(commits[msg.sender] == keccak256(secret_random_number));
    // Update commitment prior to sending ETH to prevent recursive call.
    commits[msg.sender] = 0;
    // Update random number by XORing with host&#39;s revealed secret random number.
    rng ^= secret_random_number;
    // Increment the counter of hosts that have revealed their secret number.
    num_hosts_revealed += 1;
    // Send the host back their committed ETH.
    msg.sender.transfer(total_user_eth);
  }
  
  // Allow hosts to claim their earnings from a successful lottery.
  function host_claim_earnings(address host) {
    // Only allow claims if the lottery hasn&#39;t been cancelled.
    require(!cancelled);
    // Only allow claims if there were enough hosts for trustless RNG.
    require(num_hosts >= 2);
    // Only allow claims if all hosts have revealed their secret random numbers.
    require(num_hosts == num_hosts_revealed);
    // Send the host their earnings (i.e. an even cut of 10% of ETH spent on tickets).
    host.transfer(total_user_eth * host_percentage / (num_hosts * 100));
  }
  
  // Allow anyone to send the winner their winnings.
  function claim_winnings(address winner) {
    // Only allow winning if the lottery hasn&#39;t been cancelled.
    require(!cancelled);
    // Only allow winning if there were enough hosts for trustless RNG.
    require(num_hosts >= 2);
    // Only allow winning if all hosts have revealed their secret random numbers.
    require(num_hosts == num_hosts_revealed);
    // Calculate the winning number.
    uint256 winning_number = rng % total_user_eth;
    // Require the winning number to fall within the winning Ticket&#39;s range of winning numbers.
    require((winning_number >= tickets[winner].offset) && (winning_number < tickets[winner].offset + tickets[winner].value));
    // Send the winner their winnings (i.e. 90% of ETH spent on tickets).
    winner.transfer(total_user_eth * (100 - host_percentage) / 100);
  }
  
  // Withdraw a user&#39;s ETH for them in the event the lottery is cancelled.
  function withdraw(address user) {
    // Only allow withdrawals if the lottery has been cancelled.
    require(cancelled);
    // Only allow withdrawals for users who have funds in the contract.
    require(tickets[user].value != 0);
    // Store the user&#39;s balance prior to withdrawal in a temporary variable.
    uint256 eth_to_withdraw = tickets[user].value;
    // Update the user&#39;s stored funds prior to transfer to prevent recursive call.
    tickets[user].value = 0;
    // Return the user&#39;s funds.  Throws on failure to prevent loss of funds.
    user.transfer(eth_to_withdraw);
  }
  
  // Default function, called when a user sends ETH to the contract.  Buys Tickets.
  function () payable {
    // Only allow Tickets to be purchased during the ticket buying phase.
    require(now <= buy_end_time);
    // Only allow one lottery Ticket per account.
    require(tickets[msg.sender].value == 0);
    // Set winning numbers offset to the first numbers not owned by anyone else.
    tickets[msg.sender].offset = uint128(total_user_eth);
    // Set the ticket value and range of winning numbers to the amount of ETH sent.
    tickets[msg.sender].value = uint128(msg.value);
    // Update the total amount of ETH spent on tickets.
    total_user_eth += msg.value;
    // Only allow tickets to be purchased up to the lottery&#39;s ETH cap.
    require(total_user_eth <= total_user_eth_cap);
  }
}