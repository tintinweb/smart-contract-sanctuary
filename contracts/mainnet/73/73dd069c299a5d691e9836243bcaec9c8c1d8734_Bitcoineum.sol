pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if (_value != 0) require(allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Transmutable {
  function transmute(address to, uint256 value) returns (bool, uint256);
  event Transmuted(address indexed who, address baseContract, address transmutedContract, uint256 sourceQuantity, uint256 destQuantity);
}

// Contracts that can be transmuted to should implement this
contract TransmutableInterface {
  function transmuted(uint256 _value) returns (bool, uint256);
}



contract ERC20Mineable is StandardToken, ReentrancyGuard  {

   uint256 public constant divisible_units = 10000000;
   uint256 public constant decimals = 8;

   uint256 public constant initial_reward = 100;

   /** totalSupply in StandardToken refers to currently available supply
   * maximumSupply refers to the cap on mining.
   * When mining is finished totalSupply == maximumSupply
   */
   uint256 public maximumSupply;

   // Current mining difficulty in Wei
   uint256 public currentDifficultyWei;

   // Minimum difficulty
   uint256 public minimumDifficultyThresholdWei;

   /** Block creation rate as number of Ethereum blocks per mining cycle
   * 10 minutes at 12 seconds a block would be an internal block
   * generated every 50 Ethereum blocks
   */
   uint256 public blockCreationRate;

   /* difficultyAdjustmentPeriod should be every two weeks, or
   * 2016 internal blocks.
   */
   uint256 public difficultyAdjustmentPeriod;

   /* When was the last time we did a difficulty adjustment.
   * In case mining ceases for indeterminate duration
   */
   uint256 public lastDifficultyAdjustmentEthereumBlock;

   // Scale multiplier limit for difficulty adjustment
   uint256 public constant difficultyScaleMultiplierLimit = 4;

   // Total blocks mined helps us calculate the current reward
   uint256 public totalBlocksMined;

   // Reward adjustment period in Bitcoineum native blocks

   uint256 public rewardAdjustmentPeriod; 

   // Total amount of Wei put into mining during current period
   uint256 public totalWeiCommitted;
   // Total amount of Wei expected for this mining period
   uint256 public totalWeiExpected;

   // Where to burn Ether
   address public burnAddress;

   /** Each block is created on a mining attempt if
   * it does not already exist.
   * this keeps track of the target difficulty at the time of creation
   */

   struct InternalBlock {
      uint256 targetDifficultyWei;
      uint256 blockNumber;
      uint256 totalMiningWei;
      uint256 totalMiningAttempts;
      uint256 currentAttemptOffset;
      bool payed;
      address payee;
      bool isCreated;
   }

   /** Mining attempts are given a projected offset to minimize
   * keyspace overlap to increase fairness by reducing the redemption
   * race condition
   * This does not remove the possibility that two or more miners will
   * be competing for the same award, especially if subsequent increases in
   * wei from a single miner increase overlap
   */
   struct MiningAttempt {
      uint256 projectedOffset;
      uint256 value;
      bool isCreated;
   }

   // Each guess gets assigned to a block
   mapping (uint256 => InternalBlock) public blockData;
   mapping (uint256 => mapping (address => MiningAttempt)) public miningAttempts;

   // Utility related

   function resolve_block_hash(uint256 _blockNum) public constant returns (bytes32) {
       return block.blockhash(_blockNum);
   }

   function current_external_block() public constant returns (uint256) {
       return block.number;
   }

   function external_to_internal_block_number(uint256 _externalBlockNum) public constant returns (uint256) {
      // blockCreationRate is > 0
      return _externalBlockNum / blockCreationRate;
   }

   // For the test harness verification
   function get_internal_block_number() public constant returns (uint256) {
     return external_to_internal_block_number(current_external_block());
   }

   // Initial state related
   /** Dapps need to grab the initial state of the contract
   * in order to properly initialize mining or tracking
   * this is a single atomic function for getting state
   * rather than scattering it across multiple public calls
   * also returns the current blocks parameters
   * or default params if it hasn&#39;t been created yet
   * This is only called externally
   */

   function getContractState() external constant
     returns (uint256,  // currentDifficultyWei
              uint256,  // minimumDifficultyThresholdWei
              uint256,  // blockNumber
              uint256,  // blockCreationRate
              uint256,  // difficultyAdjustmentPeriod
              uint256,  // rewardAdjustmentPeriod
              uint256,  // lastDifficultyAdustmentEthereumBlock
              uint256,  // totalBlocksMined
              uint256,  // totalWeiCommitted
              uint256,  // totalWeiExpected
              uint256,  // b.targetDifficultyWei
              uint256,  // b.totalMiningWei
              uint256  // b.currentAttemptOffset
              ) {
    InternalBlock memory b;
    uint256 _blockNumber = external_to_internal_block_number(current_external_block());
    if (!blockData[_blockNumber].isCreated) {
        b = InternalBlock(
                       {targetDifficultyWei: currentDifficultyWei,
                       blockNumber: _blockNumber,
                       totalMiningWei: 0,
                       totalMiningAttempts: 0,
                       currentAttemptOffset: 0,
                       payed: false,
                       payee: 0,
                       isCreated: true
                       });
    } else {
         b = blockData[_blockNumber];
    }
    return (currentDifficultyWei,
            minimumDifficultyThresholdWei,
            _blockNumber,
            blockCreationRate,
            difficultyAdjustmentPeriod,
            rewardAdjustmentPeriod,
            lastDifficultyAdjustmentEthereumBlock,
            totalBlocksMined,
            totalWeiCommitted,
            totalWeiExpected,
            b.targetDifficultyWei,
            b.totalMiningWei,
            b.currentAttemptOffset);
   }

   function getBlockData(uint256 _blockNum) public constant returns (uint256, uint256, uint256, uint256, uint256, bool, address, bool) {
    InternalBlock memory iBlock = blockData[_blockNum];
    return (iBlock.targetDifficultyWei,
    iBlock.blockNumber,
    iBlock.totalMiningWei,
    iBlock.totalMiningAttempts,
    iBlock.currentAttemptOffset,
    iBlock.payed,
    iBlock.payee,
    iBlock.isCreated);
   }

   function getMiningAttempt(uint256 _blockNum, address _who) public constant returns (uint256, uint256, bool) {
     if (miningAttempts[_blockNum][_who].isCreated) {
        return (miningAttempts[_blockNum][_who].projectedOffset,
        miningAttempts[_blockNum][_who].value,
        miningAttempts[_blockNum][_who].isCreated);
     } else {
        return (0, 0, false);
     }
   }

   // Mining Related

   modifier blockCreated(uint256 _blockNum) {
     require(blockData[_blockNum].isCreated);
     _;
   }

   modifier blockRedeemed(uint256 _blockNum) {
     require(_blockNum != current_external_block());
     /* Should capture if the blockdata is payed
     *  or if it does not exist in the blockData mapping
     */
     require(blockData[_blockNum].isCreated);
     require(!blockData[_blockNum].payed);
     _;
   }

   modifier initBlock(uint256 _blockNum) {
     require(_blockNum != current_external_block());

     if (!blockData[_blockNum].isCreated) {
       // This is a new block, adjust difficulty
       adjust_difficulty();

       // Create new block for tracking
       blockData[_blockNum] = InternalBlock(
                                     {targetDifficultyWei: currentDifficultyWei,
                                      blockNumber: _blockNum,
                                      totalMiningWei: 0,
                                      totalMiningAttempts: 0,
                                      currentAttemptOffset: 0,
                                      payed: false,
                                      payee: 0,
                                      isCreated: true
                                      });
     }
     _;
   }

   modifier isValidAttempt() {
     /* If the Ether for this mining attempt is less than minimum
     * 0.0000001 % of total difficulty
     */
     uint256 minimum_wei = currentDifficultyWei / divisible_units; 
     require (msg.value >= minimum_wei);

     /* Let&#39;s bound the value to guard against potential overflow
     * i.e max int, or an underflow bug
     * This is a single attempt
     */
     require(msg.value <= (1000000 ether));
     _;
   }

   modifier alreadyMined(uint256 blockNumber, address sender) {
     require(blockNumber != current_external_block()); 
    /* We are only going to allow one mining attempt per block per account
    *  This prevents stuffing and make it easier for us to track boundaries
    */
    
    // This user already made a mining attempt for this block
    require(!checkMiningAttempt(blockNumber, sender));
    _;
   }

   function checkMiningActive() public constant returns (bool) {
      return (totalSupply < maximumSupply);
   }

   modifier isMiningActive() {
      require(checkMiningActive());
      _;
   }

   function burn(uint256 value) internal {
      /* We don&#39;t really care if the burn fails for some
      *  weird reason.
      */
      bool ret = burnAddress.send(value);
      /* If we cannot burn this ether, than the contract might
      *  be under some kind of stack attack.
      *  Even though it shouldn&#39;t matter, let&#39;s err on the side of
      *  caution and throw in case there is some invalid state.
      */
      require (ret);
   }

   event MiningAttemptEvent(
       address indexed _from,
       uint256 _value,
       uint256 indexed _blockNumber,
       uint256 _totalMinedWei,
       uint256 _targetDifficultyWei
   );

   event LogEvent(
       string _info
   );

   /**
   * @dev Add a mining attempt for the current internal block
   * Initialize an empty block if not created
   * Invalidate this mining attempt if the block has been paid out
   */

   function mine() external payable 
                           nonReentrant
                           isValidAttempt
                           isMiningActive
                           initBlock(external_to_internal_block_number(current_external_block()))
                           blockRedeemed(external_to_internal_block_number(current_external_block()))
                           alreadyMined(external_to_internal_block_number(current_external_block()), msg.sender) returns (bool) {
      /* Let&#39;s immediately adjust the difficulty
      *  In case an abnormal period of time has elapsed
      *  nobody has been mining etc.
      *  Will let us recover the network even if the
      * difficulty spikes to some absurd amount
      * this should only happen on the first attempt on a block
      */
      uint256 internalBlockNum = external_to_internal_block_number(current_external_block());
      miningAttempts[internalBlockNum][msg.sender] =
                     MiningAttempt({projectedOffset: blockData[internalBlockNum].currentAttemptOffset,
                                    value: msg.value,
                                    isCreated: true});

      // Increment the mining attempts for this block
      blockData[internalBlockNum].totalMiningAttempts += 1;
      blockData[internalBlockNum].totalMiningWei += msg.value;
      totalWeiCommitted += msg.value;

      /* We are trying to stack mining attempts into their relative
      *  positions in the key space.
      */
      blockData[internalBlockNum].currentAttemptOffset += msg.value;
      MiningAttemptEvent(msg.sender,
                         msg.value,
                         internalBlockNum,
                         blockData[internalBlockNum].totalMiningWei,
                         blockData[internalBlockNum].targetDifficultyWei
                         );
      // All mining attempt Ether is burned
      burn(msg.value);
      return true;
   }

   // Redemption Related

   modifier userMineAttempted(uint256 _blockNum, address _user) {
      require(checkMiningAttempt(_blockNum, _user));
      _;
   }
   
   modifier isBlockMature(uint256 _blockNumber) {
      require(_blockNumber != current_external_block());
      require(checkBlockMature(_blockNumber, current_external_block()));
      require(checkRedemptionWindow(_blockNumber, current_external_block()));
      _;
   }

   // Just in case this block falls outside of the available
   // block range, possibly because of a change in network params
   modifier isBlockReadable(uint256 _blockNumber) {
      InternalBlock memory iBlock = blockData[_blockNumber];
      uint256 targetBlockNum = targetBlockNumber(_blockNumber);
      require(resolve_block_hash(targetBlockNum) != 0);
      _;
   }

   function calculate_difficulty_attempt(uint256 targetDifficultyWei,
                                         uint256 totalMiningWei,
                                         uint256 value) public constant returns (uint256) {
      // The total amount of Wei sent for this mining attempt exceeds the difficulty level
      // So the calculation of percentage keyspace should be done on the total wei.
      uint256 selectedDifficultyWei = 0;
      if (totalMiningWei > targetDifficultyWei) {
         selectedDifficultyWei = totalMiningWei;
      } else {
         selectedDifficultyWei = targetDifficultyWei; 
      }

      /* normalize the value against the entire key space
       * Multiply it out because we do not have floating point
       * 10000000 is .0000001 % increments
      */

      uint256 intermediate = ((value * divisible_units) / selectedDifficultyWei);
      uint256 max_int = 0;
      // Underflow to maxint
      max_int = max_int - 1;

      if (intermediate >= divisible_units) {
         return max_int;
      } else {
         return intermediate * (max_int / divisible_units);
      }
   }

   function calculate_range_attempt(uint256 difficulty, uint256 offset) public constant returns (uint256, uint256) {
       /* Both the difficulty and offset should be normalized
       * against the difficulty scale.
       * If they are not we might have an integer overflow
       */
       require(offset + difficulty >= offset);
       return (offset, offset+difficulty);
   }

   // Total allocated reward is proportional to burn contribution to limit incentive for
   // hash grinding attacks
   function calculate_proportional_reward(uint256 _baseReward, uint256 _userContributionWei, uint256 _totalCommittedWei) public constant returns (uint256) {
   require(_userContributionWei <= _totalCommittedWei);
   require(_userContributionWei > 0);
   require(_totalCommittedWei > 0);
      uint256 intermediate = ((_userContributionWei * divisible_units) / _totalCommittedWei);

      if (intermediate >= divisible_units) {
         return _baseReward;
      } else {
         return intermediate * (_baseReward / divisible_units);
      }
   }

   function calculate_base_mining_reward(uint256 _totalBlocksMined) public constant returns (uint256) {
      /* Block rewards starts at initial_reward
      *  Every 10 minutes
      *  Block reward decreases by 50% every 210000 blocks
      */
      uint256 mined_block_period = 0;
      if (_totalBlocksMined < 210000) {
           mined_block_period = 210000;
      } else {
           mined_block_period = _totalBlocksMined;
      }

      // Again we have to do this iteratively because of floating
      // point limitations in solidity.
      uint256 total_reward = initial_reward * (10 ** decimals); 
      uint256 i = 1;
      uint256 rewardperiods = mined_block_period / 210000;
      if (mined_block_period % 210000 > 0) {
         rewardperiods += 1;
      }
      for (i=1; i < rewardperiods; i++) {
          total_reward = total_reward / 2;
      }
      return total_reward;
   }

   // Break out the expected wei calculation
   // for easy external testing
   function calculate_next_expected_wei(uint256 _totalWeiCommitted,
                                        uint256 _totalWeiExpected,
                                        uint256 _minimumDifficultyThresholdWei,
                                        uint256 _difficultyScaleMultiplierLimit) public constant
                                        returns (uint256) {
          
          /* The adjustment window has been fulfilled
          *  The new difficulty should be bounded by the total wei actually spent
          * capped at difficultyScaleMultiplierLimit times
          */
          uint256 lowerBound = _totalWeiExpected / _difficultyScaleMultiplierLimit;
          uint256 upperBound = _totalWeiExpected * _difficultyScaleMultiplierLimit;

          if (_totalWeiCommitted < lowerBound) {
              _totalWeiExpected = lowerBound;
          } else if (_totalWeiCommitted > upperBound) {
              _totalWeiExpected = upperBound;
          } else {
              _totalWeiExpected = _totalWeiCommitted;
          }

          /* If difficulty drops too low lets set it to our minimum.
          *  This may halt coin creation, but obviously does not affect
          *  token transactions.
          */
          if (_totalWeiExpected < _minimumDifficultyThresholdWei) {
              _totalWeiExpected = _minimumDifficultyThresholdWei;
          }

          return _totalWeiExpected;
    }

   function adjust_difficulty() internal {
      /* Total blocks mined might not be increasing if the 
      *  difficulty is too high. So we should instead base the adjustment
      * on the progression of the Ethereum network.
      * So that the difficulty can increase/deflate regardless of sparse
      * mining attempts
      */

      if ((current_external_block() - lastDifficultyAdjustmentEthereumBlock) > (difficultyAdjustmentPeriod * blockCreationRate)) {

          // Get the new total wei expected via static function
          totalWeiExpected = calculate_next_expected_wei(totalWeiCommitted, totalWeiExpected, minimumDifficultyThresholdWei * difficultyAdjustmentPeriod, difficultyScaleMultiplierLimit);

          currentDifficultyWei = totalWeiExpected / difficultyAdjustmentPeriod;

          // Regardless of difficulty adjustment, let us zero totalWeiCommited
          totalWeiCommitted = 0;

          // Lets reset the difficulty adjustment block target
          lastDifficultyAdjustmentEthereumBlock = current_external_block();

      }
   }

   event BlockClaimedEvent(
       address indexed _from,
       address indexed _forCreditTo,
       uint256 _reward,
       uint256 indexed _blockNumber
   );

   modifier onlyWinner(uint256 _blockNumber) {
      require(checkWinning(_blockNumber));
      _;
   }


   // Helper function to avoid stack issues
   function calculate_reward(uint256 _totalBlocksMined, address _sender, uint256 _blockNumber) public constant returns (uint256) {
      return calculate_proportional_reward(calculate_base_mining_reward(_totalBlocksMined), miningAttempts[_blockNumber][_sender].value, blockData[_blockNumber].totalMiningWei); 
   }

   /** 
   * @dev Claim the mining reward for a given block
   * @param _blockNumber The internal block that the user is trying to claim
   * @param forCreditTo When the miner account is different from the account
   * where we want to deliver the redeemed Bitcoineum. I.e Hard wallet.
   */
   function claim(uint256 _blockNumber, address forCreditTo)
                  nonReentrant
                  blockRedeemed(_blockNumber)
                  isBlockMature(_blockNumber)
                  isBlockReadable(_blockNumber)
                  userMineAttempted(_blockNumber, msg.sender)
                  onlyWinner(_blockNumber)
                  external returns (bool) {
      /* If attempt is valid, invalidate redemption
      *  Difficulty is adjusted here
      *  and on bidding, in case bidding stalls out for some
      *  unusual period of time.
      *  Do everything, then adjust supply and balance
      */
      blockData[_blockNumber].payed = true;
      blockData[_blockNumber].payee = msg.sender;
      totalBlocksMined = totalBlocksMined + 1;

      uint256 proportional_reward = calculate_reward(totalBlocksMined, msg.sender, _blockNumber);
      balances[forCreditTo] = balances[forCreditTo].add(proportional_reward);
      totalSupply += proportional_reward;
      BlockClaimedEvent(msg.sender, forCreditTo,
                        proportional_reward,
                        _blockNumber);
      // Mining rewards should show up as ERC20 transfer events
      // So that ERC20 scanners will see token creation.
      Transfer(this, forCreditTo, proportional_reward);
      return true;
   }

   /** 
   * @dev Claim the mining reward for a given block
   * @param _blockNum The internal block that the user is trying to claim
   */
   function isBlockRedeemed(uint256 _blockNum) constant public returns (bool) {
     if (!blockData[_blockNum].isCreated) {
         return false;
     } else {
         return blockData[_blockNum].payed;
     }
   }

   /** 
   * @dev Get the target block in the winning equation 
   * @param _blockNum is the internal block number to get the target block for
   */
   function targetBlockNumber(uint256 _blockNum) constant public returns (uint256) {
      return ((_blockNum + 1) * blockCreationRate);
   }

   /** 
   * @dev Check whether a given block is mature 
   * @param _blockNum is the internal block number to check 
   */
   function checkBlockMature(uint256 _blockNum, uint256 _externalblock) constant public returns (bool) {
     return (_externalblock >= targetBlockNumber(_blockNum));
   }

   /**
   * @dev Check the redemption window for a given block
   * @param _blockNum is the internal block number to check
   */

   function checkRedemptionWindow(uint256 _blockNum, uint256 _externalblock) constant public returns (bool) {
       uint256 _targetblock = targetBlockNumber(_blockNum);
       return _externalblock >= _targetblock && _externalblock < (_targetblock + 256);
   }

   /** 
   * @dev Check whether a mining attempt was made by sender for this block
   * @param _blockNum is the internal block number to check
   */
   function checkMiningAttempt(uint256 _blockNum, address _sender) constant public returns (bool) {
       return miningAttempts[_blockNum][_sender].isCreated;
   }

   /** 
   * @dev Did the user win a specific block and can claim it?
   * @param _blockNum is the internal block number to check
   */
   function checkWinning(uint256 _blockNum) constant public returns (bool) {
     if (checkMiningAttempt(_blockNum, msg.sender) && checkBlockMature(_blockNum, current_external_block())) {

      InternalBlock memory iBlock = blockData[_blockNum];
      uint256 targetBlockNum = targetBlockNumber(iBlock.blockNumber);
      MiningAttempt memory attempt = miningAttempts[_blockNum][msg.sender];

      uint256 difficultyAttempt = calculate_difficulty_attempt(iBlock.targetDifficultyWei, iBlock.totalMiningWei, attempt.value);
      uint256 beginRange;
      uint256 endRange;
      uint256 targetBlockHashInt;

      (beginRange, endRange) = calculate_range_attempt(difficultyAttempt,
          calculate_difficulty_attempt(iBlock.targetDifficultyWei, iBlock.totalMiningWei, attempt.projectedOffset)); 
      targetBlockHashInt = uint256(keccak256(resolve_block_hash(targetBlockNum)));
   
      // This is the winning condition
      if ((beginRange < targetBlockHashInt) && (endRange >= targetBlockHashInt))
      {
        return true;
      }
     
     }

     return false;
     
   }

}



contract Bitcoineum is ERC20Mineable, Transmutable {

 string public constant name = "Bitcoineum";
 string public constant symbol = "BTE";
 uint256 public constant decimals = 8;
 uint256 public constant INITIAL_SUPPLY = 0;

 // 21 Million coins at 8 decimal places
 uint256 public constant MAX_SUPPLY = 21000000 * (10**8);
 
 function Bitcoineum() {

    totalSupply = INITIAL_SUPPLY;
    maximumSupply = MAX_SUPPLY;

    // 0.0001 Ether per block
    // Difficulty is so low because it doesn&#39;t include
    // gas prices for execution
    currentDifficultyWei = 100 szabo;
    minimumDifficultyThresholdWei = 100 szabo;
    
    // Ethereum blocks to internal blocks
    // Roughly 10 minute windows
    blockCreationRate = 50;

    // Adjust difficulty x claimed internal blocks
    difficultyAdjustmentPeriod = 2016;

    // Reward adjustment

    rewardAdjustmentPeriod = 210000;

    // This is the effective block counter, since block windows are discontinuous
    totalBlocksMined = 0;

    totalWeiExpected = difficultyAdjustmentPeriod * currentDifficultyWei;

    // Balance of this address can be used to determine total burned value
    // not including fees spent.
    burnAddress = 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD;

    lastDifficultyAdjustmentEthereumBlock = block.number; 
 }


   /**
   * @dev Bitcoineum can extend proof of burn into convertable units
   * that have token specific properties
   * @param to is the address of the contract that Bitcoineum is converting into
   * @param value is the quantity of Bitcoineum to attempt to convert
   */

  function transmute(address to, uint256 value) nonReentrant returns (bool, uint256) {
    require(value > 0);
    require(balances[msg.sender] >= value);
    require(totalSupply >= value);
    balances[msg.sender] = balances[msg.sender].sub(value);
    totalSupply = totalSupply.sub(value);
    TransmutableInterface target = TransmutableInterface(to);
    bool _result = false;
    uint256 _total = 0;
    (_result, _total) = target.transmuted(value);
    require (_result);
    Transmuted(msg.sender, this, to, value, _total);
    return (_result, _total);
  }

 }