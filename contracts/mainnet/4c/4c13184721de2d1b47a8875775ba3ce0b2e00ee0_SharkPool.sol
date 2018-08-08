pragma solidity ^0.4.13;

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="7200171f111d3240">[email&#160;protected]</span>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

// Minimal Bitcoineum interface for proxy mining
contract BitcoineumInterface {
   function mine() payable;
   function claim(uint256 _blockNumber, address forCreditTo);
   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool);
   function checkWinning(uint256 _blockNum) constant public returns (bool);
   function transfer(address _to, uint256 _value) returns (bool);
   function balanceOf(address _owner) constant returns (uint256 balance);
   function currentDifficultyWei() constant public returns (uint256);
   }

// Sharkpool is a rolling window Bitcoineum miner
// Smart contract based virtual mining
// http://www.bitcoineum.com/

contract SharkPool is Ownable, ReentrancyGuard {

    string constant public pool_name = "SharkPool 200";

    // Percentage of BTE pool takes for operations
    uint256 public pool_percentage = 5;

    // Limiting users because of gas limits
    // I would not increase this value it could make the pool unstable
    uint256 constant public max_users = 100;

    // Track total users to switch to degraded case when contract is full
    uint256 public total_users = 0;

    uint256 public constant divisible_units = 10000000;

    // How long will a payment event mine blocks for you
    uint256 public contract_period = 100;
    uint256 public mined_blocks = 1;
    uint256 public claimed_blocks = 1;
    uint256 public blockCreationRate = 0;

    BitcoineumInterface base_contract;

    struct user {
        uint256 start_block;
        uint256 end_block;
        uint256 proportional_contribution;
    }

    mapping (address => user) public users;
    mapping (uint256 => uint256) public attempts;
    mapping(address => uint256) balances;
    uint8[] slots;
    address[256] public active_users; // Should equal max_users

    function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }

    function set_pool_percentage(uint8 _percentage) external nonReentrant onlyOwner {
       // Just in case owner is compromised
       require(_percentage < 11);
       pool_percentage = _percentage;
    }


    function find_contribution(address _who) constant external returns (uint256, uint256, uint256, uint256, uint256) {
      if (users[_who].start_block > 0) {
         user memory u = users[_who];
         uint256 remaining_period= 0;
         if (u.end_block > mined_blocks) {
            remaining_period = u.end_block - mined_blocks;
            } else {
            remaining_period = 0;
            }
         return (u.start_block, u.end_block,
                 u.proportional_contribution,
                 u.proportional_contribution * contract_period,
                 u.proportional_contribution * remaining_period);
      }
      return (0,0,0,0,0);
    }

    function allocate_slot(address _who) internal {
       if(total_users < max_users) { 
            // Just push into active_users
            active_users[total_users] = _who;
            total_users += 1;
          } else {
            // The maximum users have been reached, can we allocate a free space?
            if (slots.length == 0) {
                // There isn&#39;t any room left
                revert();
            } else {
               uint8 location = slots[slots.length-1];
               active_users[location] = _who;
               delete slots[slots.length-1];
            }
          }
    }

     function external_to_internal_block_number(uint256 _externalBlockNum) public constant returns (uint256) {
        // blockCreationRate is > 0
        return _externalBlockNum / blockCreationRate;
     }

     function available_slots() public constant returns (uint256) {
        if (total_users < max_users) {
            return max_users - total_users;
        } else {
          return slots.length;
        }
     }
  
   event LogEvent(
       uint256 _info
   );

    function get_bitcoineum_contract_address() public constant returns (address) {
       return 0x73dD069c299A5d691E9836243BcaeC9c8C1D8734; // Production
    
       // return 0x7e7a299da34a350d04d204cd80ab51d068ad530f; // Testing
    }

    // iterate over all account holders
    // and balance transfer proportional bte
    // balance should be 0 aftwards in a perfect world
    function distribute_reward(uint256 _totalAttempt, uint256 _balance) internal {
      uint256 remaining_balance = _balance;
      for (uint8 i = 0; i < total_users; i++) {
          address user_address = active_users[i];
          if (user_address > 0 && remaining_balance != 0) {
              uint256 proportion = users[user_address].proportional_contribution;
              uint256 divided_portion = (proportion * divisible_units) / _totalAttempt;
              uint256 payout = (_balance * divided_portion) / divisible_units;
              if (payout > remaining_balance) {
                 payout = remaining_balance;
              }
              balances[user_address] = balances[user_address] + payout;
              remaining_balance = remaining_balance - payout;
          }
      }
    }

    function SharkPool() {
      blockCreationRate = 50; // match bte
      base_contract = BitcoineumInterface(get_bitcoineum_contract_address());
    }

    function current_external_block() public constant returns (uint256) {
        return block.number;
    }


    function calculate_minimum_contribution() public constant returns (uint256)  {
       return base_contract.currentDifficultyWei() / 10000000 * contract_period;
    }

    // A default ether tx without gas specified will fail.
    function () payable {
         require(msg.value >= calculate_minimum_contribution());

         // Did the user already contribute
         user storage current_user = users[msg.sender];

         // Does user exist already
         if (current_user.start_block > 0) {
            if (current_user.end_block > mined_blocks) {
                uint256 periods_left = current_user.end_block - mined_blocks;
                uint256 amount_remaining = current_user.proportional_contribution * periods_left;
                amount_remaining = amount_remaining + msg.value;
                amount_remaining = amount_remaining / contract_period;
                current_user.proportional_contribution = amount_remaining;
            } else {
               current_user.proportional_contribution = msg.value / contract_period;
            }

          // If the user exists and has a balance let&#39;s transfer it to them
          do_redemption();

          } else {
               current_user.proportional_contribution = msg.value / contract_period;
               allocate_slot(msg.sender);
          }
          current_user.start_block = mined_blocks;
          current_user.end_block = mined_blocks + contract_period;
         }

    
    // Proxy mining to token
   function mine() external nonReentrant
   {
     // Did someone already try to mine this block?
     uint256 _blockNum = external_to_internal_block_number(current_external_block());
     require(!base_contract.checkMiningAttempt(_blockNum, this));

     // Alright nobody mined lets iterate over our active_users

     uint256 total_attempt = 0;
     uint8 total_ejected = 0; 

     for (uint8 i=0; i < total_users; i++) {
         address user_address = active_users[i];
         if (user_address > 0) {
             // This user exists
             user memory u = users[user_address];
             if (u.end_block <= mined_blocks) {
                // This user needs to be ejected, no more attempts left
                // but we limit to 20 to prevent gas issues on slot insert
                if (total_ejected < 10) {
                    delete active_users[i];
                    slots.push(i);
                    delete users[active_users[i]];
                    total_ejected = total_ejected + 1;
                }
             } else {
               // This user is still active
               total_attempt = total_attempt + u.proportional_contribution;
             }
         }
     }
     if (total_attempt > 0) {
        // Now we have a total contribution amount
        attempts[_blockNum] = total_attempt;
        base_contract.mine.value(total_attempt)();
        mined_blocks = mined_blocks + 1;
     }
   }

   function claim(uint256 _blockNumber, address forCreditTo)
                  nonReentrant
                  external returns (bool) {
                  
                  // Did we win the block in question
                  require(base_contract.checkWinning(_blockNumber));

                  uint256 initial_balance = base_contract.balanceOf(this);

                  // We won let&#39;s get our reward
                  base_contract.claim(_blockNumber, this);

                  uint256 balance = base_contract.balanceOf(this);
                  uint256 total_attempt = attempts[_blockNumber];

                  distribute_reward(total_attempt, balance - initial_balance);
                  claimed_blocks = claimed_blocks + 1;
                  }

   function do_redemption() internal {
     uint256 balance = balances[msg.sender];
     if (balance > 0) {
        uint256 owner_cut = (balance / 100) * pool_percentage;
        uint256 remainder = balance - owner_cut;
        if (owner_cut > 0) {
            base_contract.transfer(owner, owner_cut);
        }
        base_contract.transfer(msg.sender, remainder);
        balances[msg.sender] = 0;
    }
   }

   function redeem() external nonReentrant
     {
        do_redemption();
     }

   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool) {
      return base_contract.checkMiningAttempt(_blockNum, _sender);
   }
   
   function checkWinning(uint256 _blockNum) constant public returns (bool) {
     return base_contract.checkWinning(_blockNum);
   }

}