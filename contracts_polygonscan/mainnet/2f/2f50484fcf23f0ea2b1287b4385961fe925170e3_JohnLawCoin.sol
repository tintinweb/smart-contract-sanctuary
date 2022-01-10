// SPDX-License-Identifier: MIT
//
// Copyright (c) 2021 Kentaro Hara
//
// This software is released under the MIT License.
// http://opensource.org/licenses/mit-license.php

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

//------------------------------------------------------------------------------
// [Overview]
//
// JohnLawCoin is a non-collateralized stablecoin realized by an Algorithmic
// Central Bank (ACB). The system is fully decentralized and there is truly
// no gatekeeper. No gatekeeper means there is no entity to be regulated.
//
// JohnLawCoin is a real-world experiment to verify one assumption: There is
// a way to stabilize the currency price with algorithmically defined monetary
// policies without holding any collateral like USD.
//
// If JohnLawCoin is successful and proves the assumption is correct, it will
// provide interesting insights for both non-fiat cryptocurrencies and fiat
// currencies; i.e., 1) non-fiat cryptocurrencies can use the algorithm to
// implement a stablecoin without having any gatekeeper that holds collateral,
// and 2) real-world central banks of developing countries can use the
// algorithm to implement a fixed exchange rate system for their fiat
// currencies without holding adequate USD reserves. This will upgrade
// human's understanding about money.
//
// JohnLawCoin has the following important properties:
//
// - There is truly no gatekeeper. The ACB is fully automated and no one
//   (including the author of the smart contracts) has the privilege of
//   influencing the monetary policies of the ACB. This can be verified by the
//   fact that the smart contracts have no operations that need privileged
//   permissions.
// - The smart contracts are self-contained. There are no dependencies on other
//   smart contracts and external services.
// - All operations are guaranteed to terminate with the time complexity of
//   O(1). The time complexity of each operation is determined solely by the
//   input size of the operation and not affected by the state of the smart
//   contracts.
//
// See the whitepaper for more details
// (https://github.com/xharaken/john-law-coin/blob/main/docs/whitepaper.pdf).
//
// If you have any questions, file GitHub issues
// (https://github.com/xharaken/john-law-coin).
//
// Note: When the smart contracts are deployed on Polygon networks, "ETH" in the
// following contracts means MATIC on the Polygon networks.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// [JohnLawCoin contract]
//
// JohnLawCoin is implemented as ERC20 tokens.
//
// Permission: Except public getters, only the ACB can call the methods.
// Coin holders can transfer their coins using the ERC20 token APIs.
//------------------------------------------------------------------------------
contract JohnLawCoin is ERC20PausableUpgradeable, OwnableUpgradeable {
  // Constants.

  // Name of the ERC20 token.
  string public constant NAME = "JohnLawCoin";
  
  // Symbol of the ERC20 token.
  string public constant SYMBOL = "JLC";

  // The initial coin supply.
  uint public constant INITIAL_COIN_SUPPLY = 10000000;

  // The tax rate.
  uint public constant TAX_RATE = 1;
  
  // Attributes.
  
  // The account to which the tax is sent.
  address public tax_account_;

  // Events.
  event TransferEvent(address indexed sender, address receiver,
                      uint amount, uint tax);

  // Initializer.
  function initialize()
      public initializer {
    __ERC20Pausable_init();
    __ERC20_init(NAME, SYMBOL);
    __Ownable_init();
    
    tax_account_ = address(uint160(uint(keccak256(abi.encode(
        "tax", block.number)))));

    // Mint the initial coins to the genesis account.
    _mint(msg.sender, INITIAL_COIN_SUPPLY);
  }

  // Mint coins to one account.
  //
  // Parameters
  // ----------------
  // |account|: The account to which the coins are minted.
  // |amount|: The amount to be minted.
  //
  // Returns
  // ----------------
  // None.
  function mint(address account, uint amount)
      public onlyOwner {
    _mint(account, amount);
  }

  // Burn coins from one account.
  //
  // Parameters
  // ----------------
  // |account|: The account from which the coins are burned.
  // |amount|: The amount to be burned.
  //
  // Returns
  // ----------------
  // None.
  function burn(address account, uint amount)
      public onlyOwner {
    _burn(account, amount);
  }

  // Move coins from one account to another account. Coin holders should use
  // ERC20's transfer method instead.
  //
  // Parameters
  // ----------------
  // |sender|: The sender account.
  // |receiver|: The receiver account.
  // |amount|: The amount to be moved.
  //
  // Returns
  // ----------------
  // None.
  function move(address sender, address receiver, uint amount)
      public onlyOwner {
    _transfer(sender, receiver, amount);
  }

  // Pause the contract.
  function pause()
      public onlyOwner {
    if (!paused()) {
      _pause();
    }
  }
  
  // Unpause the contract.
  function unpause()
      public onlyOwner {
    if (paused()) {
      _unpause();
    }
  }

  // Override decimals.
  function decimals()
      public pure override returns (uint8) {
    return 0;
  }

  // Reset the tax account.
  function resetTaxAccount()
      public onlyOwner {
    address old_tax_account = tax_account_;
    tax_account_ = address(uint160(uint(keccak256(abi.encode(
        "tax", block.number)))));
    move(old_tax_account, tax_account_, balanceOf(old_tax_account));
  }

  // Override ERC20's transfer method to impose a tax set by the ACB.
  //
  // Parameters
  // ----------------
  // |account|: The receiver account.
  // |amount|: The amount to be transferred.
  //
  // Returns
  // ----------------
  // None.
  function transfer(address account, uint amount)
      public override returns (bool) {
    uint tax = amount * TAX_RATE / 100;
    _transfer(_msgSender(), tax_account_, tax);
    _transfer(_msgSender(), account, amount - tax);
    emit TransferEvent(_msgSender(), account, amount - tax, tax);
    return true;
  }
}

//------------------------------------------------------------------------------
// [JohnLawBond contract]
//
// JohnLawBond is an implementation of the bonds to increase / decrease the
// total coin supply. The bonds are not transferable.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract JohnLawBond is OwnableUpgradeable {
  using EnumerableSet for EnumerableSet.UintSet;

  // Attributes.
  
  // _bonds[account][redemption_epoch] stores the number of the bonds
  // owned by the |account| that become redeemable at |redemption_epoch|.
  mapping (address => mapping (uint => uint)) private _bonds;

  // _redemption_epochs[account] is a set of the redemption epochs of the
  // bonds owned by the |account|.
  mapping (address => EnumerableSet.UintSet) private _redemption_epochs;

  // _bond_count[account] is the number of the bonds owned by the |account|.
  mapping (address => uint) private _bond_count;

  // _bond_supply[redemption_epoch] is the total number of the bonds that become
  // redeemable at |redemption_epoch|.
  mapping (uint => uint) private _bond_supply;
  
  // The total bond supply.
  uint private _total_supply;

  // Events.
  event MintEvent(address indexed account, uint redemption_epoch, uint amount);
  event BurnEvent(address indexed account, uint redemption_epoch, uint amount);

  // Initializer.
  function initialize()
      public initializer {
    __Ownable_init();
    
    _total_supply = 0;
  }
  
  // Mint bonds to one account.
  //
  // Parameters
  // ----------------
  // |account|: The account to which the bonds are minted.
  // |redemption_epoch|: The redemption epoch of the bonds.
  // |amount|: The amount to be minted.
  //
  // Returns
  // ----------------
  // None.
  function mint(address account, uint redemption_epoch, uint amount)
      public onlyOwner {
    _bonds[account][redemption_epoch] += amount;
    _total_supply += amount;
    _bond_count[account] += amount;
    _bond_supply[redemption_epoch] += amount;
    if (_bonds[account][redemption_epoch] > 0) {
      _redemption_epochs[account].add(redemption_epoch);
    }
    emit MintEvent(account, redemption_epoch, amount);
  }

  // Burn bonds from one account.
  //
  // Parameters
  // ----------------
  // |account|: The account from which the bonds are burned.
  // |redemption_epoch|: The redemption epoch of the bonds.
  // |amount|: The amount to be burned.
  //
  // Returns
  // ----------------
  // None.
  function burn(address account, uint redemption_epoch, uint amount)
      public onlyOwner {
    _bonds[account][redemption_epoch] -= amount;
    _total_supply -= amount;
    _bond_count[account] -= amount;
    _bond_supply[redemption_epoch] -= amount;
    if (_bonds[account][redemption_epoch] == 0) {
      _redemption_epochs[account].remove(redemption_epoch);
    }
    emit BurnEvent(account, redemption_epoch, amount);
  }

  // Public getter: Return the number of the bonds owned by the |account|.
  function numberOfBondsOwnedBy(address account)
      public view returns (uint) {
    return _bond_count[account];
  }

  // Public getter: Return the number of redemption epochs of the bonds
  // owned by the |account|.
  function numberOfRedemptionEpochsOwnedBy(address account)
      public view returns (uint) {
    return _redemption_epochs[account].length();
  }

  // Public getter: Return the |index|-th redemption epoch of the bonds
  // owned by the |account|. |index| must be smaller than the value returned by
  // numberOfRedemptionEpochsOwnedBy(account).
  function getRedemptionEpochOwnedBy(address account, uint index)
      public view returns (uint) {
    return _redemption_epochs[account].at(index);
  }

  // Public getter: Return the number of the bonds owned by the |account| that
  // become redeemable at |redemption_epoch|.
  function balanceOf(address account, uint redemption_epoch)
      public view returns (uint) {
    return _bonds[account][redemption_epoch];
  }

  // Public getter: Return the total bond supply.
  function totalSupply()
      public view returns (uint) {
    return _total_supply;
  }

  // Public getter: Return the number of the bonds that become redeemable at
  // |redemption_epoch|.
  function bondSupplyAt(uint redemption_epoch)
      public view returns (uint) {
    return _bond_supply[redemption_epoch];
  }
}

//------------------------------------------------------------------------------
// [Oracle contract]
//
// The oracle is a decentralized mechanism to determine one "truth" level
// from 0, 1, 2, ..., LEVEL_MAX - 1. The oracle uses the commit-reveal-reclaim
// voting scheme.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract Oracle is OwnableUpgradeable {
  // Constants. The values are defined in initialize(). The values never change
  // during the contract execution but use 'public' (instead of 'constant')
  // because tests want to override the values.
  uint public LEVEL_MAX;
  uint public RECLAIM_THRESHOLD;
  uint public PROPORTIONAL_REWARD_RATE;

  // The valid phase transition is: COMMIT => REVEAL => RECLAIM.
  enum Phase {
    COMMIT, REVEAL, RECLAIM
  }

  // Commit is a struct to manage one commit entry in the commit-reveal-reclaim
  // scheme.
  struct Commit {
    // The committed hash (filled in the commit phase).
    bytes32 hash;
    // The amount of deposited coins (filled in the commit phase).
    uint deposit;
    // The oracle level (filled in the reveal phase).
    uint oracle_level;
    // The phase of this commit entry.
    Phase phase;
    // The epoch ID when this commit entry is created.
    uint epoch_id;
  }

  // Vote is a struct to aggregate voting statistics for each oracle level.
  // The data is aggregated during the reveal phase and finalized at the end
  // of the reveal phase.
  struct Vote {
    // The total amount of the coins deposited by the voters who voted for this
    // oracle level.
    uint deposit;
    // The number of the voters.
    uint count;
    // Set to true when the voters for this oracle level are eligible to
    // reclaim the coins they deposited.
    bool should_reclaim;
    // Set to true when the voters for this oracle level are eligible to
    // receive a reward.
    bool should_reward;
  }

  // Epoch is a struct to keep track of the states in the commit-reveal-reclaim
  // scheme. The oracle creates three Epoch objects and uses them in a
  // round-robin manner. For example, when the first Epoch object is in use for
  // the commit phase, the second Epoch object is in use for the reveal phase,
  // and the third Epoch object is in use for the reclaim phase.
  struct Epoch {
    // The commit entries.
    mapping (address => Commit) commits;
    // The voting statistics for all the oracle levels. This uses a mapping
    // (instead of an array) to make the Vote struct upgradeable.
    mapping (uint => Vote) votes;
    // An account to store coins deposited by the voters.
    address deposit_account;
    // An account to store the reward.
    address reward_account;
    // The total amount of the reward.
    uint reward_total;
    // The current phase of this Epoch.
    Phase phase;
  }

  // Attributes. See the comment in initialize().
  // This uses a mapping (instead of an array) to make the Epoch struct
  // upgradeable.
  mapping (uint => Epoch) public epochs_;
  uint public epoch_id_;

  // Events.
  event CommitEvent(address indexed sender, uint indexed epoch_id,
                    bytes32 hash, uint deposited);
  event RevealEvent(address indexed sender, uint indexed epoch_id,
                    uint oracle_level, uint salt);
  event ReclaimEvent(address indexed sender, uint indexed epoch_id,
                     uint reclaimed, uint rewarded);
  event AdvancePhaseEvent(uint indexed epoch_id, uint tax, uint burned);

  // Initializer.
  function initialize()
      public initializer {
    __Ownable_init();

    // Constants.
    
    // The number of the oracle levels.
    LEVEL_MAX = 9;
    
    // If the "truth" level is 4 and RECLAIM_THRESHOLD is 1, the voters who
    // voted for 3, 4 and 5 can reclaim their deposited coins. Other voters
    // lose their deposited coins.
    RECLAIM_THRESHOLD = 1;
    
    // The lost coins and the collected tax are distributed to the voters who
    // voted for the "truth" level as a reward. The PROPORTIONAL_REWARD_RATE
    // of the reward is distributed to the voters in proportion to the coins
    // they deposited. The rest of the reward is distributed to the voters
    // evenly.
    PROPORTIONAL_REWARD_RATE = 90; // 90%

    // Attributes.

    // The oracle creates three Epoch objects and uses them in a round-robin
    // manner (commit => reveal => reclaim).
    for (uint epoch_index = 0; epoch_index < 3; epoch_index++) {
      for (uint level = 0; level < LEVEL_MAX; level++) {
        epochs_[epoch_index].votes[level] = Vote(0, 0, false, false);
      }
      epochs_[epoch_index].deposit_account =
          address(uint160(uint(keccak256(abi.encode(
              "deposit", epoch_index, block.number)))));
      epochs_[epoch_index].reward_account =
          address(uint160(uint(keccak256(abi.encode(
              "reward", epoch_index, block.number)))));
      epochs_[epoch_index].reward_total = 0;
    }
    epochs_[0].phase = Phase.COMMIT;
    epochs_[1].phase = Phase.RECLAIM;
    epochs_[2].phase = Phase.REVEAL;

    // |epoch_id_| is a monotonically increasing ID (3, 4, 5, ...).
    // The Epoch object at |epoch_id_ % 3| is in the commit phase.
    // The Epoch object at |(epoch_id_ - 1) % 3| is in the reveal phase.
    // The Epoch object at |(epoch_id_ - 2) % 3| is in the reclaim phase.
    // The epoch ID starts with 3 because 0 in the commit entry is not
    // distinguishable from an uninitialized commit entry in Solidity.
    epoch_id_ = 3;
  }

  // Do commit.
  //
  // Parameters
  // ----------------
  // |sender|: The voter's account.
  // |hash|: The committed hash.
  // |deposit|: The amount of the deposited coins.
  // |coin|: The JohnLawCoin contract. The ownership needs to be transferred to
  // this contract.
  //
  // Returns
  // ----------------
  // True if the commit succeeded. False otherwise.
  function commit(address sender, bytes32 hash, uint deposit, JohnLawCoin coin)
      public onlyOwner returns (bool) {
    Epoch storage epoch = epochs_[epoch_id_ % 3];
    require(epoch.phase == Phase.COMMIT, "co1");
    if (coin.balanceOf(sender) < deposit) {
      return false;
    }
    
    // One voter can commit only once per phase.
    if (epoch.commits[sender].epoch_id == epoch_id_) {
      return false;
    }

    // Create a commit entry.
    epoch.commits[sender] = Commit(
        hash, deposit, LEVEL_MAX, Phase.COMMIT, epoch_id_);
    require(epoch.commits[sender].phase == Phase.COMMIT, "co2");

    // Move the deposited coins to the deposit account.
    coin.move(sender, epoch.deposit_account, deposit);
    emit CommitEvent(sender, epoch_id_, hash, deposit);
    return true;
  }

  // Do reveal.
  //
  // Parameters
  // ----------------
  // |sender|: The voter's account.
  // |oracle_level|: The oracle level revealed by the voter.
  // |salt|: The salt revealed by the voter.
  //
  // Returns
  // ----------------
  // True if the reveal succeeded. False otherwise.
  function reveal(address sender, uint oracle_level, uint salt)
      public onlyOwner returns (bool) {
    Epoch storage epoch = epochs_[(epoch_id_ - 1) % 3];
    require(epoch.phase == Phase.REVEAL, "rv1");
    if (LEVEL_MAX <= oracle_level) {
      return false;
    }
    if (epoch.commits[sender].epoch_id != epoch_id_ - 1) {
      // The corresponding commit was not found.
      return false;
    }
    
    // One voter can reveal only once per phase.
    if (epoch.commits[sender].phase != Phase.COMMIT) {
      return false;
    }
    epoch.commits[sender].phase = Phase.REVEAL;

    // Check if the committed hash matches the revealed level and the salt.
    bytes32 reveal_hash = encrypt(sender, oracle_level, salt);
    bytes32 hash = epoch.commits[sender].hash;
    if (hash != reveal_hash) {
      return false;
    }

    // Update the commit entry with the revealed level.
    epoch.commits[sender].oracle_level = oracle_level;

    // Count up the vote.
    epoch.votes[oracle_level].deposit += epoch.commits[sender].deposit;
    epoch.votes[oracle_level].count += 1;
    emit RevealEvent(sender, epoch_id_, oracle_level, salt);
    return true;
  }

  // Do reclaim.
  //
  // Parameters
  // ----------------
  // |sender|: The voter's account.
  // |coin|: The JohnLawCoin contract. The ownership needs to be transferred to
  // this contract.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  //  - uint: The amount of the reclaimed coins. This becomes a positive value
  //    when the voter is eligible to reclaim their deposited coins.
  //  - uint: The amount of the reward. This becomes a positive value when the
  //    voter voted for the "truth" oracle level.
  function reclaim(address sender, JohnLawCoin coin)
      public onlyOwner returns (uint, uint) {
    Epoch storage epoch = epochs_[(epoch_id_ - 2) % 3];
    require(epoch.phase == Phase.RECLAIM, "rc1");
    if (epoch.commits[sender].epoch_id != epoch_id_ - 2){
      // The corresponding commit was not found.
      return (0, 0);
    }
    
    // One voter can reclaim only once per phase.
    if (epoch.commits[sender].phase != Phase.REVEAL) {
      return (0, 0);
    }

    epoch.commits[sender].phase = Phase.RECLAIM;
    uint deposit = epoch.commits[sender].deposit;
    uint oracle_level = epoch.commits[sender].oracle_level;
    if (oracle_level == LEVEL_MAX) {
      return (0, 0);
    }
    require(0 <= oracle_level && oracle_level < LEVEL_MAX, "rc2");

    if (!epoch.votes[oracle_level].should_reclaim) {
      return (0, 0);
    }
    require(epoch.votes[oracle_level].count > 0, "rc3");
    
    // Reclaim the deposited coins.
    coin.move(epoch.deposit_account, sender, deposit);

    uint reward = 0;
    if (epoch.votes[oracle_level].should_reward) {
      // The voter who voted for the "truth" level can receive the reward.
      //
      // The PROPORTIONAL_REWARD_RATE of the reward is distributed to the
      // voters in proportion to the coins they deposited. This incentivizes
      // voters who have more coins (and thus have more power on determining
      // the "truth" level) to join the oracle.
      //
      // The rest of the reward is distributed to the voters evenly. This
      // incentivizes more voters (including new voters) to join the oracle.
      if (epoch.votes[oracle_level].deposit > 0) {
        reward += (uint(PROPORTIONAL_REWARD_RATE) * epoch.reward_total *
                   deposit) / (uint(100) * epoch.votes[oracle_level].deposit);
      }
      reward += ((uint(100) - PROPORTIONAL_REWARD_RATE) * epoch.reward_total) /
                (uint(100) * epoch.votes[oracle_level].count);
      coin.move(epoch.reward_account, sender, reward);
    }
    emit ReclaimEvent(sender, epoch_id_, deposit, reward);
    return (deposit, reward);
  }

  // Advance to the next phase. COMMIT => REVEAL, REVEAL => RECLAIM,
  // RECLAIM => COMMIT.
  //
  // Parameters
  // ----------------
  // |coin|: The JohnLawCoin contract. The ownership needs to be transferred to
  // this contract.
  //
  // Returns
  // ----------------
  // None.
  function advance(JohnLawCoin coin)
      public onlyOwner returns (uint) {
    // Advance the phase.
    epoch_id_ += 1;

    // Step 1: Move the commit phase to the reveal phase.
    Epoch storage epoch = epochs_[(epoch_id_ - 1) % 3];
    require(epoch.phase == Phase.COMMIT, "ad1");
    epoch.phase = Phase.REVEAL;

    // Step 2: Move the reveal phase to the reclaim phase.
    epoch = epochs_[(epoch_id_ - 2) % 3];
    require(epoch.phase == Phase.REVEAL, "ad2");
    epoch.phase = Phase.RECLAIM;

    // The "truth" level is set to the mode of the weighted majority votes.
    uint mode_level = getModeLevel();
    if (0 <= mode_level && mode_level < LEVEL_MAX) {
      uint deposit_revealed = 0;
      uint deposit_to_reclaim = 0;
      for (uint level = 0; level < LEVEL_MAX; level++) {
        require(epoch.votes[level].should_reclaim == false, "ad3");
        require(epoch.votes[level].should_reward == false, "ad4");
        deposit_revealed += epoch.votes[level].deposit;
        if ((mode_level < RECLAIM_THRESHOLD ||
             mode_level - RECLAIM_THRESHOLD <= level) &&
            level <= mode_level + RECLAIM_THRESHOLD) {
          // Voters who voted for the oracle levels in [mode_level -
          // reclaim_threshold, mode_level + reclaim_threshold] are eligible
          // to reclaim their deposited coins. Other voters lose their deposited
          // coins.
          epoch.votes[level].should_reclaim = true;
          deposit_to_reclaim += epoch.votes[level].deposit;
        }
      }

      // Voters who voted for the "truth" level are eligible to receive the
      // reward.
      epoch.votes[mode_level].should_reward = true;

      // Note: |deposit_revealed| is equal to |balanceOf(epoch.deposit_account)|
      // only when all the voters who voted in the commit phase revealed
      // their votes correctly in the reveal phase.
      require(deposit_revealed <= coin.balanceOf(epoch.deposit_account), "ad5");
      require(
          deposit_to_reclaim <= coin.balanceOf(epoch.deposit_account), "ad6");

      // The lost coins are moved to the reward account.
      coin.move(epoch.deposit_account, epoch.reward_account,
                coin.balanceOf(epoch.deposit_account) - deposit_to_reclaim);
    }

    // Move the collected tax to the reward account.
    address tax_account = coin.tax_account_();
    uint tax = coin.balanceOf(tax_account);
    coin.move(tax_account, epoch.reward_account, tax);

    // Set the total amount of the reward.
    epoch.reward_total = coin.balanceOf(epoch.reward_account);

    // Step 3: Move the reclaim phase to the commit phase.
    uint epoch_index = epoch_id_ % 3;
    epoch = epochs_[epoch_index];
    require(epoch.phase == Phase.RECLAIM, "ad7");

    uint burned = coin.balanceOf(epoch.deposit_account) +
                  coin.balanceOf(epoch.reward_account);
    // Burn the remaining deposited coins.
    coin.burn(epoch.deposit_account, coin.balanceOf(epoch.deposit_account));
    // Burn the remaining reward.
    coin.burn(epoch.reward_account, coin.balanceOf(epoch.reward_account));

    // Initialize the Epoch object for the next commit phase.
    //
    // |epoch.commits_| cannot be cleared due to the restriction of Solidity.
    // |epoch_id_| ensures the stale commit entries are not misused.
    for (uint level = 0; level < LEVEL_MAX; level++) {
      epoch.votes[level] = Vote(0, 0, false, false);
    }
    // Regenerate the account addresses just in case.
    require(coin.balanceOf(epoch.deposit_account) == 0, "ad8");
    require(coin.balanceOf(epoch.reward_account) == 0, "ad9");
    epoch.deposit_account =
        address(uint160(uint(keccak256(abi.encode(
            "deposit", epoch_index, block.number)))));
    epoch.reward_account =
        address(uint160(uint(keccak256(abi.encode(
            "reward", epoch_index, block.number)))));
    epoch.reward_total = 0;
    epoch.phase = Phase.COMMIT;

    emit AdvancePhaseEvent(epoch_id_, tax, burned);
    return burned;
  }

  // Return the oracle level that got the largest amount of deposited coins.
  // In other words, return the mode of the votes weighted by the deposited
  // coins.
  //
  // Parameters
  // ----------------
  // None.
  //
  // Returns
  // ----------------
  // If there are multiple modes, return the mode that has the largest votes.
  // If there are multiple modes that have the largest votes, return the
  // smallest mode. If there are no votes, return LEVEL_MAX.
  function getModeLevel()
      public onlyOwner view returns (uint) {
    Epoch storage epoch = epochs_[(epoch_id_ - 2) % 3];
    require(epoch.phase == Phase.RECLAIM, "gm1");
    uint mode_level = LEVEL_MAX;
    uint max_deposit = 0;
    uint max_count = 0;
    for (uint level = 0; level < LEVEL_MAX; level++) {
      if (epoch.votes[level].count > 0 &&
          (mode_level == LEVEL_MAX ||
           max_deposit < epoch.votes[level].deposit ||
           (max_deposit == epoch.votes[level].deposit &&
            max_count < epoch.votes[level].count))){
        max_deposit = epoch.votes[level].deposit;
        max_count = epoch.votes[level].count;
        mode_level = level;
      }
    }
    return mode_level;
  }

  // Return the ownership of the JohnLawCoin contract to the ACB.
  //
  // Parameters
  // ----------------
  // |coin|: The JohnLawCoin contract.
  //
  // Returns
  // ----------------
  // None.
  function revokeOwnership(JohnLawCoin coin)
      public onlyOwner {
    coin.transferOwnership(msg.sender);
  }

  // Public getter: Return the Vote object at |epoch_index| and |level|.
  function getVote(uint epoch_index, uint level)
      public view returns (uint, uint, bool, bool) {
    require(0 <= epoch_index && epoch_index <= 2, "gv1");
    require(0 <= level && level < LEVEL_MAX, "gv2");
    Vote memory vote = epochs_[epoch_index].votes[level];
    return (vote.deposit, vote.count, vote.should_reclaim, vote.should_reward);
  }

  // Public getter: Return the Commit object at |epoch_index| and |account|.
  function getCommit(uint epoch_index, address account)
      public view returns (bytes32, uint, uint, Phase, uint) {
    require(0 <= epoch_index && epoch_index <= 2, "gc1");
    Commit memory entry = epochs_[epoch_index].commits[account];
    return (entry.hash, entry.deposit, entry.oracle_level,
            entry.phase, entry.epoch_id);
  }

  // Public getter: Return the Epoch object at |epoch_index|.
  function getEpoch(uint epoch_index)
      public view returns (address, address, uint, Phase) {
    require(0 <= epoch_index && epoch_index <= 2, "ge1");
    return (epochs_[epoch_index].deposit_account,
            epochs_[epoch_index].reward_account,
            epochs_[epoch_index].reward_total,
            epochs_[epoch_index].phase);
  }
  
  // Calculate a hash to be committed. Voters are expected to use this function
  // to create a hash used in the commit phase.
  //
  // Parameters
  // ----------------
  // |sender|: The voter's account.
  // |level|: The oracle level to vote.
  // |salt|: The voter's salt.
  //
  // Returns
  // ----------------
  // The calculated hash value.
  function encrypt(address sender, uint level, uint salt)
      public pure returns (bytes32) {
    return keccak256(abi.encode(sender, level, salt));
  }
}

//------------------------------------------------------------------------------
// [Logging contract]
//
// The Logging contract records various metrics for analysis purpose.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract Logging is OwnableUpgradeable {
  using SafeCast for uint;
  using SafeCast for int;

  // A struct to record metrics about voting.
  struct VoteLog {
    uint commit_succeeded;
    uint commit_failed;
    uint reveal_succeeded;
    uint reveal_failed;
    uint reclaim_succeeded;
    uint reward_succeeded;
    uint deposited;
    uint reclaimed;
    uint rewarded;
  }

  // A struct to record metrics about Epoch.
  struct EpochLog {
    uint minted_coins;
    uint burned_coins;
    int coin_supply_delta;
    uint total_coin_supply;
    uint oracle_level;
    uint current_epoch_start;
    uint tax;
  }

  // A struct to record metrics about BondOperation.
  struct BondOperationLog {
    int bond_budget;
    uint total_bond_supply;
    uint valid_bond_supply;
    uint purchased_bonds;
    uint redeemed_bonds;
    uint expired_bonds;
  }

  // A struct to record metrics about OpenMarketOperation.
  struct OpenMarketOperationLog {
    int coin_budget;
    int exchanged_coins;
    int exchanged_eth;
    uint eth_balance;
    uint latest_price;
  }
  
  // Attributes.

  // Logs about voting.
  mapping (uint => VoteLog) public vote_logs_;
  
  // Logs about Epoch.
  mapping (uint => EpochLog) public epoch_logs_;

  // Logs about BondOperation.
  mapping (uint => BondOperationLog) public bond_operation_logs_;

  // Logs about OpenMarketOperation.
  mapping (uint => OpenMarketOperationLog) public open_market_operation_logs_;

  // Initializer.
  function initialize()
      public initializer {
    __Ownable_init();
  }

  // Public getter: Return the VoteLog of |epoch_id|.
  function getVoteLog(uint epoch_id)
      public view returns (
          uint, uint, uint, uint, uint, uint, uint, uint, uint) {
    VoteLog memory log = vote_logs_[epoch_id];
    return (log.commit_succeeded, log.commit_failed, log.reveal_succeeded,
            log.reveal_failed, log.reclaim_succeeded, log.reward_succeeded,
            log.deposited, log.reclaimed, log.rewarded);
  }

  // Public getter: Return the EpochLog of |epoch_id|.
  function getEpochLog(uint epoch_id)
      public view returns (uint, uint, int, uint, uint, uint, uint) {
    EpochLog memory log = epoch_logs_[epoch_id];
    return (log.minted_coins, log.burned_coins, log.coin_supply_delta,
            log.total_coin_supply, log.oracle_level, log.current_epoch_start,
            log.tax);
  }

  // Public getter: Return the BondOperationLog of |epoch_id|.
  function getBondOperationLog(uint epoch_id)
      public view returns (int, uint, uint, uint, uint, uint) {
    BondOperationLog memory log = bond_operation_logs_[epoch_id];
    return (log.bond_budget, log.total_bond_supply, log.valid_bond_supply,
            log.purchased_bonds, log.redeemed_bonds, log.expired_bonds);
  }

  // Public getter: Return the OpenMarketOperationLog of |epoch_id|.
  function getOpenMarketOperationLog(uint epoch_id)
      public view returns (int, int, int, uint, uint) {
    OpenMarketOperationLog memory log = open_market_operation_logs_[epoch_id];
    return (log.coin_budget, log.exchanged_coins, log.exchanged_eth,
            log.eth_balance, log.latest_price);
  }

  // Called when the epoch is updated.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |minted|: The amount of the minted coins.
  // |burned|: The amount of the burned coins.
  // |delta|: The delta of the total coin supply.
  // |total_coin_supply|: The total coin supply.
  // |oracle_level|: ACB.oracle_level_.
  // |current_epoch_start|: ACB.current_epoch_start_.
  // |tax|: The amount of the tax collected in the previous epoch.
  //
  // Returns
  // ----------------
  // None.
  function updateEpoch(uint epoch_id, uint minted, uint burned, int delta,
                       uint total_coin_supply, uint oracle_level,
                       uint current_epoch_start, uint tax)
      public onlyOwner {
    epoch_logs_[epoch_id].minted_coins = minted;
    epoch_logs_[epoch_id].burned_coins = burned;
    epoch_logs_[epoch_id].coin_supply_delta = delta;
    epoch_logs_[epoch_id].total_coin_supply = total_coin_supply;
    epoch_logs_[epoch_id].oracle_level = oracle_level;
    epoch_logs_[epoch_id].current_epoch_start = current_epoch_start;
    epoch_logs_[epoch_id].tax = tax;
  }

  // Called when BondOperation's bond budget is updated at the beginning of
  // the epoch.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |bond_budget|: The bond budget.
  // |total_bond_supply|: The total bond supply.
  // |valid_bond_supply|: The valid bond supply.
  //
  // Returns
  // ----------------
  // None.
  function updateBondBudget(uint epoch_id, int bond_budget,
                            uint total_bond_supply, uint valid_bond_supply)
      public onlyOwner {
    bond_operation_logs_[epoch_id].bond_budget = bond_budget;
    bond_operation_logs_[epoch_id].total_bond_supply = total_bond_supply;
    bond_operation_logs_[epoch_id].valid_bond_supply = valid_bond_supply;
    bond_operation_logs_[epoch_id].purchased_bonds = 0;
    bond_operation_logs_[epoch_id].redeemed_bonds = 0;
    bond_operation_logs_[epoch_id].expired_bonds = 0;
  }

  // Called when OpenMarketOperation's coin budget is updated at the beginning
  // of the epoch.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |coin_budget|: The coin budget.
  // |eth_balance|: The ETH balance in the EthPool.
  // |latest_price|: The latest ETH / JLC price.
  //
  // Returns
  // ----------------
  // None.
  function updateCoinBudget(uint epoch_id, int coin_budget,
                            uint eth_balance, uint latest_price)
      public onlyOwner {
    open_market_operation_logs_[epoch_id].coin_budget = coin_budget;
    open_market_operation_logs_[epoch_id].exchanged_coins = 0;
    open_market_operation_logs_[epoch_id].exchanged_eth = 0;
    open_market_operation_logs_[epoch_id].eth_balance = eth_balance;
    open_market_operation_logs_[epoch_id].latest_price = latest_price;
  }

  // Called when ACB.vote is called.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |commit_result|: Whether the commit succeeded or not.
  // |reveal_result|: Whether the reveal succeeded or not.
  // |deposited|: The amount of the deposited coins.
  // |reclaimed|: The amount of the reclaimed coins.
  // |rewarded|: The amount of the reward.
  //
  // Returns
  // ----------------
  // None.
  function vote(uint epoch_id, bool commit_result, bool reveal_result,
                uint deposited, uint reclaimed, uint rewarded)
      public onlyOwner {
    if (commit_result) {
      vote_logs_[epoch_id].commit_succeeded += 1;
    } else {
      vote_logs_[epoch_id].commit_failed += 1;
    }
    if (reveal_result) {
      vote_logs_[epoch_id].reveal_succeeded += 1;
    } else {
      vote_logs_[epoch_id].reveal_failed += 1;
    }
    if (reclaimed > 0) {
      vote_logs_[epoch_id].reclaim_succeeded += 1;
    }
    if (rewarded > 0) {
      vote_logs_[epoch_id].reward_succeeded += 1;
    }
    vote_logs_[epoch_id].deposited += deposited;
    vote_logs_[epoch_id].reclaimed += reclaimed;
    vote_logs_[epoch_id].rewarded += rewarded;
  }

  // Called when ACB.purchaseBonds is called.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |purchased_bonds|: The number of purchased bonds.
  //
  // Returns
  // ----------------
  // None.
  function purchaseBonds(uint epoch_id, uint purchased_bonds)
      public onlyOwner {
    bond_operation_logs_[epoch_id].purchased_bonds += purchased_bonds;
  }

  // Called when ACB.redeemBonds is called.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |redeemed_bonds|: The number of redeemded bonds.
  // |expired_bonds|: The number of expired bonds.
  //
  // Returns
  // ----------------
  // None.
  function redeemBonds(uint epoch_id, uint redeemed_bonds, uint expired_bonds)
      public onlyOwner {
    bond_operation_logs_[epoch_id].redeemed_bonds += redeemed_bonds;
    bond_operation_logs_[epoch_id].expired_bonds += expired_bonds;
  }

  // Called when ACB.purchaseCoins is called.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |eth_amount|: The amount of ETH exchanged.
  // |coin_amount|: The amount of JLC exchanged.
  //
  // Returns
  // ----------------
  // None.
  function purchaseCoins(uint epoch_id, uint eth_amount, uint coin_amount)
      public onlyOwner {
    open_market_operation_logs_[epoch_id].exchanged_eth +=
        eth_amount.toInt256();
    open_market_operation_logs_[epoch_id].exchanged_coins +=
        coin_amount.toInt256();
  }

  // Called when ACB.sellCoins is called.
  //
  // Parameters
  // ----------------
  // |epoch_id|: The epoch ID.
  // |eth_amount|: The amount of ETH exchanged.
  // |coin_amount|: The amount of JLC exchanged.
  //
  // Returns
  // ----------------
  // None.
  function sellCoins(uint epoch_id, uint eth_amount, uint coin_amount)
      public onlyOwner {
    open_market_operation_logs_[epoch_id].exchanged_eth -=
        eth_amount.toInt256();
    open_market_operation_logs_[epoch_id].exchanged_coins -=
        coin_amount.toInt256();
  }
}

//------------------------------------------------------------------------------
// [BondOperation contract]
//
// The BondOperation contract increases / decreases the total coin supply by
// redeeming / issuing bonds. The bond budget is updated by the ACB every epoch.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract BondOperation is OwnableUpgradeable {
  using SafeCast for uint;
  using SafeCast for int;

  // Constants. The values are defined in initialize(). The values never change
  // during the contract execution but use 'public' (instead of 'constant')
  // because tests want to override the values.
  uint public BOND_PRICE;
  uint public BOND_REDEMPTION_PRICE;
  uint public BOND_REDEMPTION_PERIOD;
  uint public BOND_REDEEMABLE_PERIOD;

  // Attributes. See the comment in initialize().
  JohnLawBond public bond_;
  int public bond_budget_;

  // Events.
  event IncreaseBondSupplyEvent(address indexed sender, uint indexed epoch_id,
                                uint issued_bonds, uint redemption_epoch);
  event DecreaseBondSupplyEvent(address indexed sender, uint indexed epoch_id,
                                uint redeemed_bonds, uint expired_bonds);
  event UpdateBondBudgetEvent(uint indexed epoch_id, int delta,
                              int bond_budget, uint mint);

  // Initializer.
  //
  // Parameters
  // ----------------
  // |bond|: The JohnLawBond contract. The ownership needs to be transferred to
  // this contract.
  function initialize(JohnLawBond bond)
      public initializer {
    __Ownable_init();
    
    // Constants.
    
    // The bond structure.
    //
    // |<---BOND_REDEMPTION_PERIOD--->|<---BOND_REDEEMABLE_PERIOD--->|
    // ^                              ^                              ^
    // Issued                         Becomes redeemable             Expired
    //
    // During BOND_REDEMPTION_PERIOD, the bonds are redeemable as long as the
    // bond budget is negative. During BOND_REDEEMABLE_PERIOD, the bonds are
    // redeemable regardless of the bond budget. After BOND_REDEEMABLE_PERIOD,
    // the bonds are expired.
    BOND_PRICE = 996; // One bond is sold for 996 coins.
    BOND_REDEMPTION_PRICE = 1000; // One bond is redeemed for 1000 coins.
    BOND_REDEMPTION_PERIOD = 12; // 12 epochs.
    BOND_REDEEMABLE_PERIOD = 2; // 2 epochs.

    // The JohnLawBond contract.
    bond_ = bond;
    
    // If |bond_budget_| is positive, it indicates the number of bonds the ACB
    // can issue to decrease the total coin supply. If |bond_budget_| is
    // negative, it indicates the number of bonds the ACB can redeem to
    // increase the total coin supply.
    bond_budget_ = 0;
  }

  // Deprecate the contract.
  function deprecate()
      public onlyOwner {
    bond_.transferOwnership(msg.sender);
  }

  // Increase the total bond supply by issuing bonds.
  //
  // Parameters
  // ----------------
  // |sender|: The sender account.
  // |count|: The number of bonds to be issued.
  // |epoch_id|: The current epoch ID.
  // |coin|: The JohnLawCoin contract. The ownership needs to be transferred to
  // this contract.
  //
  // Returns
  // ----------------
  // The redemption epoch of the issued bonds if it succeeds. 0 otherwise.
  function increaseBondSupply(address sender, uint count,
                              uint epoch_id, JohnLawCoin coin)
      public onlyOwner returns (uint) {
    require(count > 0, "BondOperation: You must purchase at least one bond.");
    require(bond_budget_ >= count.toInt256(),
            "BondOperation: The bond budget is not enough.");

    uint amount = BOND_PRICE * count;
    require(coin.balanceOf(sender) >= amount,
            "BondOperation: Your coin balance is not enough.");

    // Set the redemption epoch of the bonds.
    uint redemption_epoch = epoch_id + BOND_REDEMPTION_PERIOD;

    // Issue new bonds.
    bond_.mint(sender, redemption_epoch, count);
    bond_budget_ -= count.toInt256();
    require(bond_budget_ >= 0, "pb1");
    require(bond_.balanceOf(sender, redemption_epoch) > 0, "pb2");

    // Burn the corresponding coins.
    coin.burn(sender, amount);
    emit IncreaseBondSupplyEvent(sender, epoch_id, count, redemption_epoch);
    return redemption_epoch;
  }
  
  // Decrease the total bond supply by redeeming bonds.
  //
  // Parameters
  // ----------------
  // |sender|: The sender account.
  // |redemption_epochs|: An array of bonds to be redeemed. The bonds are
  // identified by their redemption epochs.
  // |epoch_id|: The current epoch ID.
  // |coin|: The JohnLawCoin contract. The ownership needs to be transferred to
  // this contract.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  // - The number of redeemed bonds.
  // - The number of expired bonds.
  function decreaseBondSupply(address sender, uint[] memory redemption_epochs,
                              uint epoch_id, JohnLawCoin coin)
      public onlyOwner returns (uint, uint) {
    uint redeemed_bonds = 0;
    uint expired_bonds = 0;
    for (uint i = 0; i < redemption_epochs.length; i++) {
      uint redemption_epoch = redemption_epochs[i];
      uint count = bond_.balanceOf(sender, redemption_epoch);
      if (epoch_id < redemption_epoch) {
        // If the bonds have not yet hit their redemption epoch, the
        // BondOperation accepts the redemption as long as |bond_budget_| is
        // negative.
        if (bond_budget_ >= 0) {
          continue;
        }
        if (count > (-bond_budget_).toUint256()) {
          count = (-bond_budget_).toUint256();
        }
        bond_budget_ += count.toInt256();
      }
      if (epoch_id < redemption_epoch + BOND_REDEEMABLE_PERIOD) {
        // If the bonds are not expired, mint the corresponding coins to the
        // sender account.
        uint amount = count * BOND_REDEMPTION_PRICE;
        coin.mint(sender, amount);
        redeemed_bonds += count;
      } else {
        expired_bonds += count;
      }
      // Burn the redeemed / expired bonds.
      bond_.burn(sender, redemption_epoch, count);
    }
    emit DecreaseBondSupplyEvent(sender, epoch_id,
                                 redeemed_bonds, expired_bonds);
    return (redeemed_bonds, expired_bonds);
  }

  // Update the bond budget to increase or decrease the total coin supply.
  //
  // Parameters
  // ----------------
  // |delta|: The target increase or decrease of the total coin supply.
  // |epoch_id|: The current epoch ID.
  //
  // Returns
  // ----------------
  // The amount of coins that cannot be increased by adjusting the bond budget
  // and thus need to be newly minted.
  function updateBondBudget(int delta, uint epoch_id)
      public onlyOwner returns (uint) {
    uint mint = 0;
    uint bond_supply = validBondSupply(epoch_id);
    if (delta == 0) {
      // No change in the total coin supply.
      bond_budget_ = 0;
    } else if (delta > 0) {
      // Increase the total coin supply.
      uint count = delta.toUint256() / BOND_REDEMPTION_PRICE;
      if (count <= bond_supply) {
        // If there are sufficient bonds to redeem, increase the total coin
        // supply by redeeming the bonds.
        bond_budget_ = -count.toInt256();
      } else {
        // Otherwise, redeem all the issued bonds.
        bond_budget_ = -bond_supply.toInt256();
        // The remaining coins need to be newly minted.
        mint = (count - bond_supply) * BOND_REDEMPTION_PRICE;
      }
      require(bond_budget_ <= 0, "cs1");
    } else {
      // Issue new bonds to decrease the total coin supply.
      bond_budget_ = -delta / BOND_PRICE.toInt256();
      require(bond_budget_ >= 0, "cs2");
    }

    require(bond_supply.toInt256() + bond_budget_ >= 0, "cs3");
    emit UpdateBondBudgetEvent(epoch_id, delta, bond_budget_, mint);
    return mint;
  }

  // Public getter: Return the valid bond supply; i.e., the total supply of
  // not-yet-expired bonds.
  function validBondSupply(uint epoch_id)
      public view returns (uint) {
    uint count = 0;
    for (uint redemption_epoch =
             (epoch_id > BOND_REDEEMABLE_PERIOD ?
              epoch_id - BOND_REDEEMABLE_PERIOD + 1 : 0);
         redemption_epoch <= epoch_id + BOND_REDEMPTION_PERIOD;
         redemption_epoch++) {
      count += bond_.bondSupplyAt(redemption_epoch);
    }
    return count;
  }
  
  // Return the ownership of the JohnLawCoin contract to the ACB.
  //
  // Parameters
  // ----------------
  // |coin|: The JohnLawCoin contract.
  //
  // Returns
  // ----------------
  // None.
  function revokeOwnership(JohnLawCoin coin)
      public onlyOwner {
    coin.transferOwnership(msg.sender);
  }
}

//------------------------------------------------------------------------------
// [OpenMarketOperation contract]
//
// The OpenMarketOperation contract increases / decreases the total coin supply
// by purchasing / selling ETH from the open market. The price between JLC and
// ETH is determined by a Dutch auction.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract OpenMarketOperation is OwnableUpgradeable {
  using SafeCast for uint;
  using SafeCast for int;

  // Constants. The values are defined in initialize(). The values never change
  // during the contract execution but use 'public' (instead of 'constant')
  // because tests want to override the values.
  uint public PRICE_CHANGE_INTERVAL;
  uint public PRICE_CHANGE_PERCENTAGE;
  uint public PRICE_CHANGE_MAX;
  uint public PRICE_MULTIPLIER;

  // Attributes. See the comment in initialize().
  uint public latest_price_;
  bool public latest_price_updated_;
  uint public start_price_;
  int public coin_budget_;

  // Events.
  event IncreaseCoinSupplyEvent(uint requested_eth_amount, uint elapsed_time,
                                uint eth_amount, uint coin_amount);
  event DecreaseCoinSupplyEvent(uint requested_coin_amount, uint elapsed_time,
                                uint eth_balance, uint eth_amount,
                                uint coin_amount);
  event UpdateCoinBudgetEvent(int coin_budget);
  
  // Initializer.
  function initialize()
      public initializer {
    __Ownable_init();
    
    // Constants.

    // The price auction is implemented as a Dutch auction as follows:
    //
    // Let P be the latest price at which the open market operation exchanged
    // JLC with ETH. The price is measured by ETH wei / JLC. When the price is
    // P, it means 1 JLC is exchanged with P ETH wei.
    //
    // At the beginning of each epoch, the ACB sets the coin budget; i.e., the
    // amount of JLC to be purchased / sold by the open market operation.
    //
    // When the open market operation increases the total coin supply,
    // the auction starts with the price of P * PRICE_MULTIPLIER.
    // Then the price is decreased by PRICE_CHANGE_PERCENTAGE % every
    // PRICE_CHANGE_INTERVAL seconds. JLC and ETH are exchanged at the
    // given price (the open market operation sells JLC and purchases ETH).
    // The auction stops when the open market operation finished selling JLC
    // in the coin budget.
    //
    // When the open market operation decreases the total coin supply,
    // the auction starts with the price of P / PRICE_MULTIPLIER.
    // Then the price is increased by PRICE_CHANGE_PERCENTAGE % every
    // PRICE_CHANGE_INTERVAL seconds. JLC and ETH are exchanged at the
    // given price (the open market operation sells ETH and purchases JLC).
    // The auction stops when the open market operation finished purchasing JLC
    // in the coin budget.
    //
    // To avoid the price from increasing / decreasing too much, the price
    // is allowed to increase / decrease up to PRICE_CHANGE_MAX times.
    //
    // TODO: Set the value to 8 * 60 * 60 for the mainnet and 60 for the
    // testnet.
    PRICE_CHANGE_INTERVAL = 8 * 60 * 60; // 8 hours
    PRICE_CHANGE_PERCENTAGE = 15; // 15%
    PRICE_CHANGE_MAX = 25;
    PRICE_MULTIPLIER = 3;
    
    // Attributes.

    // The latest price at which the open market operation exchanged JLC with
    // ETH.
    // TODO: Set a reasonable value before launching to the mainnet.
    latest_price_ = 1000000000000000;

    // Whether the latest price was updated in the current epoch.
    latest_price_updated_ = false;
    
    // The start price is updated at the beginning of each epoch.
    start_price_ = 0;
    
    // The current coin budget.
    coin_budget_ = 0;
  }
  
  // Increase the total coin supply by purchasing ETH from the sender account.
  // This method returns the amount of JLC and ETH to be exchanged. The actual
  // change to the total coin supply and the ETH pool is made by the ACB.
  //
  // Parameters
  // ----------------
  // |requested_eth_amount|: The amount of ETH the sender is willing to pay.
  // |elapsed_time|: The elapsed seconds from the current epoch start.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  // - The amount of ETH to be exchanged. This can be smaller than
  // |requested_eth_amount| when the open market operation does not have
  // enough coin budget.
  // - The amount of JLC to be exchanged.
  function increaseCoinSupply(uint requested_eth_amount, uint elapsed_time)
      public onlyOwner returns (uint, uint) {
    require(coin_budget_ > 0,
            "OpenMarketOperation: The coin budget must be positive.");
        
    // Calculate the amount of JLC and ETH to be exchanged.
    uint price = getCurrentPrice(elapsed_time);
    uint coin_amount = requested_eth_amount / price;
    if (coin_amount > coin_budget_.toUint256()) {
      coin_amount = coin_budget_.toUint256();
    }
    uint eth_amount = coin_amount * price;
        
    if (coin_amount > 0) {
      latest_price_ = price;
      latest_price_updated_ = true;
    }
    coin_budget_ -= coin_amount.toInt256();
    require(coin_budget_ >= 0, "ic1");
    require(eth_amount <= requested_eth_amount, "ic2");

    emit IncreaseCoinSupplyEvent(requested_eth_amount, elapsed_time,
                                 eth_amount, coin_amount);
    return (eth_amount, coin_amount);
  }

  // Decrease the total coin supply by selling ETH to the sender account.
  // This method returns the amount of JLC and ETH to be exchanged. The actual
  // change to the total coin supply and the ETH pool is made by the ACB.
  //
  // Parameters
  // ----------------
  // |requested_coin_amount|: The amount of JLC the sender is willing to pay.
  // |elapsed_time|: The elapsed seconds from the current epoch start.
  // |eth_balance|: The ETH balance in the EthPool.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  // - The amount of ETH to be exchanged.
  // - The amount of JLC to be exchanged. This can be smaller than
  // |requested_coin_amount| when the open market operation does not have
  // enough ETH in the pool.
  function decreaseCoinSupply(uint requested_coin_amount, uint elapsed_time,
                              uint eth_balance)
      public onlyOwner returns (uint, uint) {
    require(coin_budget_ < 0,
            "OpenMarketOperation: The coin budget must be negative.");
        
    // Calculate the amount of JLC and ETH to be exchanged.
    uint price = getCurrentPrice(elapsed_time);
    uint coin_amount = requested_coin_amount;
    if (coin_amount >= (-coin_budget_).toUint256()) {
      coin_amount = (-coin_budget_).toUint256();
    }
    uint eth_amount = coin_amount * price;
    if (eth_amount >= eth_balance) {
      eth_amount = eth_balance;
    }
    coin_amount = eth_amount / price;
        
    if (coin_amount > 0) {
      latest_price_ = price;
      latest_price_updated_ = true;
    }
    coin_budget_ += coin_amount.toInt256();
    require(coin_budget_ <= 0, "dc1");
    require(coin_amount <= requested_coin_amount, "dc2");

    emit DecreaseCoinSupplyEvent(requested_coin_amount, elapsed_time,
                                 eth_balance, eth_amount, coin_amount);
    return (eth_amount, coin_amount);
  }

  // Return the current price in the Dutch auction.
  //
  // Parameters
  // ----------------
  // |elapsed_time|: The elapsed seconds from the current epoch start.
  //
  // Returns
  // ----------------
  // The current price.
  function getCurrentPrice(uint elapsed_time)
      public view returns (uint) {
    if (coin_budget_ > 0) {
      uint price = start_price_;
      for (uint i = 0;
           i < elapsed_time / PRICE_CHANGE_INTERVAL && i < PRICE_CHANGE_MAX;
           i++) {
        price = price * (100 - PRICE_CHANGE_PERCENTAGE) / 100;
      }
      if (price == 0) {
        price = 1;
      }
      return price;
    } else if (coin_budget_ < 0) {
      uint price = start_price_;
      for (uint i = 0;
           i < elapsed_time / PRICE_CHANGE_INTERVAL && i < PRICE_CHANGE_MAX;
           i++) {
        price = price * (100 + PRICE_CHANGE_PERCENTAGE) / 100;
      }
      return price;
    }
    return 0;
  }
  
  // Update the coin budget. The coin budget indicates how many coins should
  // be added to / removed from the total coin supply; i.e., the amount of JLC
  // to be sold / purchased by the open market operation. The ACB calls the
  // method at the beginning of each epoch.
  //
  // Parameters
  // ----------------
  // |coin_budget|: The coin budget.
  //
  // Returns
  // ----------------
  // None.
  function updateCoinBudget(int coin_budget)
      public onlyOwner {
    if (latest_price_updated_ == false) {
      if (coin_budget_ > 0) {
        // If no exchange was observed in the previous epoch, the price setting
        // was too high. Lower the price.
        latest_price_ = latest_price_ / PRICE_MULTIPLIER + 1;
      } else if (coin_budget_ < 0) {
        // If no exchange was observed in the previous epoch, the price setting
        // was too low. Raise the price.
        latest_price_ = latest_price_ * PRICE_MULTIPLIER;
      }
    }
    
    coin_budget_ = coin_budget;
    latest_price_updated_ = false;
    require(latest_price_ > 0, "uc1");
    
    if (coin_budget_ > 0) {
      start_price_ = latest_price_ * PRICE_MULTIPLIER;
    } else if (coin_budget_ == 0) {
      start_price_ = 0;
    } else {
      start_price_ = latest_price_ / PRICE_MULTIPLIER + 1;
    }
    emit UpdateCoinBudgetEvent(coin_budget_);
  }
}

//------------------------------------------------------------------------------
// [EthPool contract]
//
// The EthPool contract stores ETH for the open market operation.
//
// Permission: Except public getters, only the ACB can call the methods.
//------------------------------------------------------------------------------
contract EthPool is OwnableUpgradeable {
  // Initializer.
  function initialize()
      public initializer {
    __Ownable_init();
  }
  
  // Increase ETH.
  function increaseEth()
      public onlyOwner payable {
  }

  // Decrease |eth_amount| ETH and send it to the |receiver|.
  function decreaseEth(address receiver, uint eth_amount)
      public onlyOwner {
    require(address(this).balance >= eth_amount, "de1");
    (bool success,) =
        payable(receiver).call{value: eth_amount}("");
    require(success, "de2");
  }
}

//------------------------------------------------------------------------------
// [ACB contract]
//
// The ACB stabilizes the USD / JLC exchange rate to 1.0 with algorithmically
// defined monetary policies:
//
// 1. The ACB obtains the exchange rate from the oracle.
// 2. If the exchange rate is 1.0, the ACB does nothing.
// 3. If the exchange rate is higher than 1.0, the ACB increases the total coin
//    supply by redeeming issued bonds (regardless of their redemption dates).
//    If that is not enough to supply sufficient coins, the ACB performs an open
//    market operation to sell JLC and purchase ETH to increase the total coin
//    supply.
// 4. If the exchange rate is lower than 1.0, the ACB decreases the total coin
//    supply by issuing new bonds. If the exchange rate drops down to 0.6, the
//    ACB performs an open market operation to sell ETH and purchase JLC to
//    decrease the total coin supply.
//
// Permission: All the methods are public. No one (including the genesis
// account) is privileged to influence the monetary policies of the ACB. The ACB
// is fully decentralized and there is truly no gatekeeper. The only exceptions
// are a few methods the genesis account may use to upgrade the smart contracts
// to fix bugs during a development phase.
//------------------------------------------------------------------------------
contract ACB is OwnableUpgradeable, PausableUpgradeable {
  using SafeCast for uint;
  using SafeCast for int;
  bytes32 public constant NULL_HASH = 0;

  // Constants. The values are defined in initialize(). The values never change
  // during the contract execution but use 'public' (instead of 'constant')
  // because tests want to override the values.
  uint[] public LEVEL_TO_EXCHANGE_RATE;
  uint public EXCHANGE_RATE_DIVISOR;
  uint public EPOCH_DURATION;
  uint public DEPOSIT_RATE;
  uint public DAMPING_FACTOR;

  // Used only in testing. This cannot be put in a derived contract due to
  // a restriction of @openzeppelin/truffle-upgrades.
  uint public _timestamp_for_testing;

  // Attributes. See the comment in initialize().
  JohnLawCoin public coin_;
  Oracle public oracle_;
  BondOperation public bond_operation_;
  OpenMarketOperation public open_market_operation_;
  EthPool public eth_pool_;
  Logging public logging_;
  uint public oracle_level_;
  uint public current_epoch_start_;

  // Events.
  event PayableEvent(address indexed sender, uint value);
  event UpdateEpochEvent(uint epoch_id, uint current_epoch_start, uint tax,
                         uint burned, int delta, uint mint);
  event VoteEvent(address indexed sender, uint indexed epoch_id,
                  bytes32 hash, uint oracle_level, uint salt,
                  bool commit_result, bool reveal_result,
                  uint deposited, uint reclaimed, uint rewarded,
                  bool epoch_updated);
  event PurchaseBondsEvent(address indexed sender, uint indexed epoch_id,
                           uint purchased_bonds, uint redemption_epoch);
  event RedeemBondsEvent(address indexed sender, uint indexed epoch_id,
                         uint redeemed_bonds, uint expired_bonds);
  event PurchaseCoinsEvent(address indexed sender, uint requested_eth_amount,
                           uint eth_amount, uint coin_amount);
  event SellCoinsEvent(address indexed sender, uint requested_coin_amount,
                       uint eth_amount, uint coin_amount);

  // Initializer. The ownership of the contracts needs to be transferred to the
  // ACB just after the initializer is invoked.
  //
  // Parameters
  // ----------------
  // |coin|: The JohnLawCoin contract.
  // |oracle|: The Oracle contract.
  // |bond_operation|: The BondOperation contract.
  // |open_market_operation|: The OpenMarketOperation contract.
  // |eth_pool|: The EthPool contract.
  // |logging|: The Logging contract.
  function initialize(JohnLawCoin coin, Oracle oracle,
                      BondOperation bond_operation,
                      OpenMarketOperation open_market_operation,
                      EthPool eth_pool,
                      Logging logging)
      public initializer {
    __Ownable_init();
    __Pausable_init();

    // Constants.

    // The following table shows the mapping from the oracle level to the
    // exchange rate. Voters can vote for one of the oracle levels.
    //
    // ----------------------------------
    // | oracle level | exchange rate   |
    // ----------------------------------
    // |            0 | 1 JLC = 0.6 USD |
    // |            1 | 1 JLC = 0.7 USD |
    // |            2 | 1 JLC = 0.8 USD |
    // |            3 | 1 JLC = 0.9 USD |
    // |            4 | 1 JLC = 1.0 USD |
    // |            5 | 1 JLC = 1.1 USD |
    // |            6 | 1 JLC = 1.2 USD |
    // |            7 | 1 JLC = 1.3 USD |
    // |            8 | 1 JLC = 1.4 USD |
    // ----------------------------------
    //
    // Voters are expected to look up the current exchange rate using
    // real-world currency exchangers and vote for the oracle level that is
    // closest to the current exchange rate. Strictly speaking, the current
    // exchange rate is defined as the exchange rate at the point when the
    // current epoch started (i.e., current_epoch_start_).
    //
    // In the bootstrap phase where no currency exchanger supports JLC <->
    // USD conversion, voters are expected to vote for the oracle level 5
    // (i.e., 1 JLC = 1.1 USD). This helps increase the total coin supply
    // gradually and incentivize early adopters in the bootstrap phase. Once
    // a currency exchanger supports the conversion, voters are expected to
    // vote for the oracle level that is closest to the real-world exchange
    // rate.
    //
    // Note that 10000000 coins (corresponding to 10 M USD) are given to the
    // genesis account initially. This is important to make sure that the
    // genesis account has power to determine the exchange rate until the
    // ecosystem stabilizes. Once a real-world currency exchanger supports
    // the conversion and the oracle gets a sufficient number of honest voters
    // to agree on the real-world exchange rate consistently, the genesis
    // account can lose its power by decreasing its coin balance, moving the
    // oracle to a fully decentralized system. This mechanism is mandatory
    // to stabilize the exchange rate and bootstrap the ecosystem successfully.

    // LEVEL_TO_EXCHANGE_RATE is the mapping from the oracle levels to the
    // exchange rates. The real exchange rate is obtained by dividing the values
    // by EXCHANGE_RATE_DIVISOR. For example, 11 corresponds to the exchange
    // rate of 1.1. This translation is needed to avoid using float numbers in
    // Solidity.
    LEVEL_TO_EXCHANGE_RATE = [6, 7, 8, 9, 10, 11, 12, 13, 14];
    EXCHANGE_RATE_DIVISOR = 10;

    // The duration of the epoch. The ACB adjusts the total coin supply once
    // per epoch. Voters can vote once per epoch.
    //
    // TODO: Set the value to 7 * 24 * 60 * 60 for the mainnet and 60 for the
    // testnet.
    EPOCH_DURATION = 7 * 24 * 60 * 60; // 1 week.

    // The percentage of the coin balance voters need to deposit.
    DEPOSIT_RATE = 10; // 10%.

    // A damping factor to avoid minting or burning too many coins in one epoch.
    DAMPING_FACTOR = 10; // 10%.

    // Attributes.

    // The JohnLawCoin contract.
    coin_ = coin;
    
    // The Oracle contract.
    oracle_ = oracle;

    // The BondOperation contract.
    bond_operation_ = bond_operation;

    // The OpenMarketOperation contract.
    open_market_operation_ = open_market_operation;

    // The EthPool contract.
    eth_pool_ = eth_pool;

    // The Logging contract.
    logging_ = logging;

    // The current oracle level.
    oracle_level_ = oracle.LEVEL_MAX();

    // The timestamp when the current epoch started.
    current_epoch_start_ = getTimestamp();

    require(LEVEL_TO_EXCHANGE_RATE.length == oracle.LEVEL_MAX(), "AC1");
  }

  // Deprecate the ACB. Only the genesis account can call this method.
  function deprecate()
      public onlyOwner {
    coin_.transferOwnership(msg.sender);
    oracle_.transferOwnership(msg.sender);
    bond_operation_.transferOwnership(msg.sender);
    open_market_operation_.transferOwnership(msg.sender);
    eth_pool_.transferOwnership(msg.sender);
    logging_.transferOwnership(msg.sender);
  }

  // Pause the ACB in emergency cases. Only the genesis account can call this
  // method.
  function pause()
      public onlyOwner {
    if (!paused()) {
      _pause();
    }
    coin_.pause();
  }

  // Unpause the ACB. Only the genesis account can call this method.
  function unpause()
      public onlyOwner {
    if (paused()) {
      _unpause();
    }
    coin_.unpause();
  }

  // Payable fallback to receive and store ETH. Give us tips :D
  fallback() external payable {
    require(msg.data.length == 0, "fb1");
    emit PayableEvent(msg.sender, msg.value);
  }
  receive() external payable {
    emit PayableEvent(msg.sender, msg.value);
  }

  // Withdraw the tips. Only the genesis account can call this method.
  function withdrawTips()
      public whenNotPaused onlyOwner {
    (bool success,) =
        payable(msg.sender).call{value: address(this).balance}("");
    require(success, "wt1");
  }

  // A struct to pack local variables. This is needed to avoid a stack-too-deep
  // error in Solidity.
  struct VoteResult {
    uint epoch_id;
    bool epoch_updated;
    bool reveal_result;
    bool commit_result;
    uint deposited;
    uint reclaimed;
    uint rewarded;
  }

  // Vote for the exchange rate. The voter can commit a vote to the current
  // epoch N, reveal their vote in the epoch N-1, and reclaim the deposited
  // coins and get a reward for their vote in the epoch N-2 at the same time.
  //
  // Parameters
  // ----------------
  // |hash|: The hash to be committed in the current epoch N. Specify
  // ACB.NULL_HASH if you do not want to commit and only want to reveal and
  // reclaim previous votes.
  // |oracle_level|: The oracle level you voted for in the epoch N-1.
  // |salt|: The salt you used in the epoch N-1.
  //
  // Returns
  // ----------------
  // A tuple of six values:
  //  - boolean: Whether the commit succeeded or not.
  //  - boolean: Whether the reveal succeeded or not.
  //  - uint: The amount of the deposited coins.
  //  - uint: The amount of the reclaimed coins.
  //  - uint: The amount of the reward.
  //  - boolean: Whether this vote updated the epoch.
  function vote(bytes32 hash, uint oracle_level, uint salt)
      public whenNotPaused returns (bool, bool, uint, uint, uint, bool) {
    VoteResult memory result;

    result.epoch_id = oracle_.epoch_id_();
    result.epoch_updated = false;
    if (getTimestamp() >= current_epoch_start_ + EPOCH_DURATION) {
      // Start a new epoch.
      result.epoch_updated = true;
      result.epoch_id += 1;
      current_epoch_start_ = getTimestamp();
      
      // Advance to the next epoch. Provide the |tax| coins to the oracle
      // as a reward.
      uint tax = coin_.balanceOf(coin_.tax_account_());
      coin_.transferOwnership(address(oracle_));
      uint burned = oracle_.advance(coin_);
      oracle_.revokeOwnership(coin_);
      
      // Reset the tax account address just in case.
      coin_.resetTaxAccount();
      require(coin_.balanceOf(coin_.tax_account_()) == 0, "vo1");
      
      int delta = 0;
      oracle_level_ = oracle_.getModeLevel();
      if (oracle_level_ != oracle_.LEVEL_MAX()) {
        require(0 <= oracle_level_ && oracle_level_ < oracle_.LEVEL_MAX(),
                "vo2");
        // Translate the oracle level to the exchange rate.
        uint exchange_rate = LEVEL_TO_EXCHANGE_RATE[oracle_level_];

        // Calculate the amount of coins to be minted or burned based on the
        // Quantity Theory of Money. If the exchange rate is 1.1 (i.e., 1 JLC
        // = 1.1 USD), the total coin supply is increased by 10%. If the
        // exchange rate is 0.8 (i.e., 1 JLC = 0.8 USD), the total coin supply
        // is decreased by 20%.
        delta = coin_.totalSupply().toInt256() *
                (int(exchange_rate) - int(EXCHANGE_RATE_DIVISOR)) /
                int(EXCHANGE_RATE_DIVISOR);

        // To avoid increasing or decreasing too many coins in one epoch,
        // multiply the damping factor.
        delta = delta * int(DAMPING_FACTOR) / 100;
      }

      // Update the bond budget.
      uint mint = bond_operation_.updateBondBudget(delta, result.epoch_id);

      // Update the coin budget.
      if (oracle_level_ == 0 && delta < 0) {
        require(mint == 0, "vo3");
        open_market_operation_.updateCoinBudget(delta);
      } else {
        open_market_operation_.updateCoinBudget(mint.toInt256());
      }

      logging_.updateEpoch(
          result.epoch_id, mint, burned, delta, coin_.totalSupply(),
          oracle_level_, current_epoch_start_, tax);
      logging_.updateBondBudget(
          result.epoch_id, bond_operation_.bond_budget_(),
          bond_operation_.bond_().totalSupply(),
          bond_operation_.validBondSupply(result.epoch_id));
      logging_.updateCoinBudget(
          result.epoch_id, open_market_operation_.coin_budget_(),
          address(eth_pool_).balance,
          open_market_operation_.latest_price_());
      emit UpdateEpochEvent(result.epoch_id, current_epoch_start_, tax,
                            burned, delta, mint);
    }

    coin_.transferOwnership(address(oracle_));
    
    // Commit.
    //
    // The voter needs to deposit the DEPOSIT_RATE percentage of their coin
    // balance.
    result.deposited = coin_.balanceOf(msg.sender) * DEPOSIT_RATE / 100;
    if (hash == NULL_HASH) {
      result.deposited = 0;
    }
    result.commit_result = oracle_.commit(
        msg.sender, hash, result.deposited, coin_);
    if (!result.commit_result) {
      result.deposited = 0;
    }

    // Reveal.
    result.reveal_result = oracle_.reveal(msg.sender, oracle_level, salt);
    
    // Reclaim.
    (result.reclaimed, result.rewarded) = oracle_.reclaim(msg.sender, coin_);

    oracle_.revokeOwnership(coin_);

    logging_.vote(result.epoch_id, result.commit_result,
                  result.reveal_result, result.deposited,
                  result.reclaimed, result.rewarded);
    emit VoteEvent(
        msg.sender, result.epoch_id, hash, oracle_level, salt,
        result.commit_result, result.reveal_result, result.deposited,
        result.reclaimed, result.rewarded, result.epoch_updated);
    return (result.commit_result, result.reveal_result, result.deposited,
            result.reclaimed, result.rewarded, result.epoch_updated);
  }

  // Purchase bonds.
  //
  // Parameters
  // ----------------
  // |count|: The number of bonds to purchase.
  //
  // Returns
  // ----------------
  // The redemption epoch of the purchased bonds.
  function purchaseBonds(uint count)
      public whenNotPaused returns (uint) {
    uint epoch_id = oracle_.epoch_id_();
    
    coin_.transferOwnership(address(bond_operation_));
    uint redemption_epoch =
        bond_operation_.increaseBondSupply(address(msg.sender), count,
                                           epoch_id, coin_);
    bond_operation_.revokeOwnership(coin_);
    
    logging_.purchaseBonds(epoch_id, count);
    emit PurchaseBondsEvent(address(msg.sender), epoch_id,
                            count, redemption_epoch);
    return redemption_epoch;
  }
  
  // Redeem bonds.
  //
  // Parameters
  // ----------------
  // |redemption_epochs|: An array of bonds to be redeemed. The bonds are
  // identified by their redemption epochs.
  //
  // Returns
  // ----------------
  // The number of successfully redeemed bonds.
  function redeemBonds(uint[] memory redemption_epochs)
      public whenNotPaused returns (uint) {
    uint epoch_id = oracle_.epoch_id_();
    
    coin_.transferOwnership(address(bond_operation_));
    (uint redeemed_bonds, uint expired_bonds) =
        bond_operation_.decreaseBondSupply(
            address(msg.sender), redemption_epochs, epoch_id, coin_);
    bond_operation_.revokeOwnership(coin_);
    
    logging_.redeemBonds(epoch_id, redeemed_bonds, expired_bonds);
    emit RedeemBondsEvent(address(msg.sender), epoch_id,
                          redeemed_bonds, expired_bonds);
    return redeemed_bonds;
  }

  // Pay ETH and purchase JLC from the open market operation.
  //
  // Parameters
  // ----------------
  // The sender needs to pay |requested_eth_amount| ETH.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  // - The amount of ETH the sender paid. This value can be smaller than
  // |requested_eth_amount| when the open market operation does not have enough
  // coin budget. The remaining ETH is returned to the sender's wallet.
  // - The amount of JLC the sender purchased.
  function purchaseCoins()
      public whenNotPaused payable returns (uint, uint) {
    uint requested_eth_amount = msg.value;
    uint elapsed_time = getTimestamp() - current_epoch_start_;
    
    // Calculate the amount of ETH and JLC to be exchanged.
    (uint eth_amount, uint coin_amount) =
        open_market_operation_.increaseCoinSupply(
            requested_eth_amount, elapsed_time);
    
    coin_.mint(msg.sender, coin_amount);
    
    require(address(this).balance >= requested_eth_amount, "pc1");
    bool success;
    (success,) =
        payable(address(eth_pool_)).call{value: eth_amount}(
            abi.encodeWithSignature("increaseEth()"));
    require(success, "pc2");
    
    logging_.purchaseCoins(oracle_.epoch_id_(), eth_amount, coin_amount);
    
    // Pay back the remaining ETH to the sender. This may trigger any arbitrary
    // operations in an external smart contract. This must be called at the very
    // end of purchaseCoins().
    (success,) =
        payable(msg.sender).call{value: requested_eth_amount - eth_amount}("");
    require(success, "pc3");

    emit PurchaseCoinsEvent(msg.sender, requested_eth_amount,
                            eth_amount, coin_amount);
    return (eth_amount, coin_amount);
  }
  
  // Pay JLC and purchase ETH from the open market operation.
  //
  // Parameters
  // ----------------
  // |requested_coin_amount|: The amount of JLC the sender is willing to pay.
  //
  // Returns
  // ----------------
  // A tuple of two values:
  // - The amount of ETH the sender purchased.
  // - The amount of JLC the sender paid. This value can be smaller than
  // |requested_coin_amount| when the open market operation does not have
  // enough ETH in the pool.
  function sellCoins(uint requested_coin_amount)
      public whenNotPaused returns (uint, uint) {
    // The sender does not have enough coins.
    require(coin_.balanceOf(msg.sender) >= requested_coin_amount,
            "OpenMarketOperation: Your coin balance is not enough.");
        
    // Calculate the amount of ETH and JLC to be exchanged.
    uint elapsed_time = getTimestamp() - current_epoch_start_;
    (uint eth_amount, uint coin_amount) =
        open_market_operation_.decreaseCoinSupply(
            requested_coin_amount, elapsed_time, address(eth_pool_).balance);

    coin_.burn(msg.sender, coin_amount);
    
    logging_.sellCoins(oracle_.epoch_id_(), eth_amount, coin_amount);
    
    // Send ETH to the sender. This may trigger any arbitrary operations in an
    // external smart contract. This must be called at the very end of
    // sellCoins().
    eth_pool_.decreaseEth(msg.sender, eth_amount);
    
    emit SellCoinsEvent(msg.sender, requested_coin_amount,
                        eth_amount, coin_amount);
    return (eth_amount, coin_amount);
  }

  // Calculate a hash to be committed to the oracle. Voters are expected to call
  // this function to create the hash.
  //
  // Parameters
  // ----------------
  // |level|: The oracle level to vote.
  // |salt|: The voter's salt.
  //
  // Returns
  // ----------------
  // The calculated hash value.
  function encrypt(uint level, uint salt)
      public view returns (bytes32) {
    address sender = msg.sender;
    return oracle_.encrypt(sender, level, salt);
  }

  // Public getter: Return the current timestamp in seconds.
  function getTimestamp()
      public virtual view returns (uint) {
    // block.timestamp is better than block.number because the granularity of
    // the epoch update is EPOCH_DURATION (1 week).
    return block.timestamp;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}