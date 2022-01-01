/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* NNNNNNNN        NNNNNNNN       OOOOOOOOO       XXXXXXX       XXXXXXX *
* N:::::::N       N::::::N     OO:::::::::OO     X:::::X       X:::::X *
* N::::::::N      N::::::N   OO:::::::::::::OO   X:::::X       X:::::X *
* N:::::::::N     N::::::N  O:::::::OOO:::::::O  X::::::X     X::::::X *
* N::::::::::N    N::::::N  O::::::O   O::::::O  XXX:::::X   X:::::XXX *
* N:::::::::::N   N::::::N  O:::::O     O:::::O     X:::::X X:::::X    *
* N:::::::N::::N  N::::::N  O:::::O     O:::::O      X:::::X:::::X     *
* N::::::N N::::N N::::::N  O:::::O     O:::::O       X:::::::::X      *
* N::::::N  N::::N:::::::N  O:::::O     O:::::O       X:::::::::X      *
* N::::::N   N:::::::::::N  O:::::O     O:::::O      X:::::X:::::X     *
* N::::::N    N::::::::::N  O:::::O     O:::::O     X:::::X X:::::X    *
* N::::::N     N:::::::::N  O::::::O   O::::::O  XXX:::::X   X:::::XXX *
* N::::::N      N::::::::N  O:::::::OOO:::::::O  X::::::X     X::::::X *
* N::::::N       N:::::::N   OO:::::::::::::OO   X:::::X       X:::::X *
* N::::::N        N::::::N     OO:::::::::OO     X:::::X       X:::::X *
* NNNNNNNN         NNNNNNN       OOOOOOOOO       XXXXXXX       XXXXXXX *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * /

/*
Project Name:   EquiNOX
Ticker:         Nox
Decimals:       18
Token type:     Certificate of deposit

Website: https://nox-token.com
Telegram: https://t.me/nox_token


NOX has everything a good staking token should have:
- NOX is immutable
- NOX has no owner
- NOX has daily auctions
- NOX has daily rewards for auction participants
- NOX has an Automated Market Maker built in
- NOX has a stable supply and liquidity growth
- NOX has a 1.8% daily inflation that slowly decays over time
- NOX has shares that go up when stakes are ended 
- NOX has penalties for ending stakes early
- NOX has 10% rewards for referrals 
- NOX has a sticky referral system
- NOX has flexible splitting and merging of stakes
- NOX allows transferring stakes to different accounts
- NOX has no end date for stakes

Also, NOX is the first certificate of deposit aligned with the seasons:
- Every season change has a predictable impact on how NOX behaves
- Harvest season is the most important season for NOX
- It's when old holders leave, new ones join, and diamond hands are rewarded
- Stakes can only be created outside harvest season
- Stakes can only be ended without penalty during harvest season
- Stakes that survive harvest get more valuable and earn more interest
*/

pragma solidity ^0.8.10;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IToken {

    function getCurrentTokenDay() external view returns (uint32);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function mintSupply(address addr, uint256 amount) external;
    
    function getPoolAvg() external view returns (uint256 amountToken, uint256 amountBusd);
    
    function registerPoolRatio() external;
    
    function getDefaultTokenBusdRatio() external pure returns (uint256);
    
    function hasPoolBeenCreated() external view returns (bool);
    
    function createPool() external;

    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(  
        address tokenA,  
        address tokenB,  
        uint amountADesired,  
        uint amountBDesired,  
        uint amountAMin,  
        uint amountBMin,  
        address to,  
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

/**
 * @dev Abstract contract that contains all auction events.
 */
abstract contract Events {

    event liquidityAdded(
        uint256 indexed tokenDay,
        uint256 tokenAmount,
        uint256 busdAmount
    );
    
    event donationReceived(
        uint256 indexed tokenDay,
        address donatorAddress,
        uint256 amountDonated
    );
    
    event auctionDayUpdated(
        uint256 indexed tokenDay
    );
    
    event tokensClaimed(
        uint256 indexed tokenDay,
        uint256 tokenAmount,
        address claimerAddress
    );
    
    event busdClaimed(
        uint256 indexed tokenDay,
        uint256 busdAmount,
        address claimerAddress
    );
}


/**
 * @dev Abstract contract that contains all main constants, global variables, mappings, and data structures.
 */
abstract contract Data is Events {
    IToken public TOKEN_CONTRACT;
    IBEP20 public BUSD_CONTRACT;
    
    address internal M_ADDRESS1;
    address internal M_ADDRESS2;
    
    uint256 constant DAILY_SUPPLY = 1E25;  // 10M tokens per day 10000000x1E18
    
    uint256 constant MIN_DONATE = 1E18; //1 BUSD
    uint256 constant MAX_DONATE = 25000E18; //25K BUSD
    uint256 constant MAX_DONATION_DAYS = 365;
    uint256 constant MAX_NUM_PARTICIPANTS = 1000;
    
    uint256 public CurrentAuctionDay = 1;
    uint256 constant LAST_CONTRACT_DAY = 400;
    
    uint256 REF_NUMERATOR = 1;
    uint256 REF_DENOMINATOR = 10;

    uint256 POOL_NUMERATOR = 4;
    uint256 POOL_DENOMINATOR = 10;
    
    uint256 BPD_NUMERATOR = 5;
    uint256 BPD_DENOMINATOR = 10;
    
    uint256 M_NUMERATOR = 1;
    uint256 M_DENOMINATOR = 20;
    
    
    struct AuctionResult {
        uint256 auctionDay;
        uint256 totalDonatedBusd;
        uint256 donatedBusdByUser;
        uint256 numberOfParticipants;
    }
    
    struct DailyDistributionRatio {
        uint256 numerator;
        uint256 denominator;
        uint256 tokenDay;
    }
    
    uint256 public BusdForPoolAccounting = 0;
    uint256 public TotalBusdSentToPool = 0;
    
    uint256 public BusdForBPDAccounting = 0;
    uint256 public TotalBusdSentToBPD = 0;
    uint256 public TotalBusdClaimedFromBPDs = 0;
    uint256 public TotalBusdSentToAuctions = 0;
    
    uint256 public TotalTokensClaimedFromDonations = 0;
    
    uint256 public TotalTokensMintedToReferrals = 0;
    
    
    mapping(address => uint256) public donatorBusdCredit;

    mapping(address => uint32) public claimedUntilDate;
    mapping(address => mapping(uint256 => uint256)) public donatorBusdDailyDonations;
    mapping(address => uint256) public donatorTotalClaimedTokens;

    mapping(uint256 => mapping(uint256 => address)) public donatorAccounts;
    
    mapping(uint256 => uint256) public donatorAccountCount;
    mapping(uint256 => uint256) public dailyBusdDonations;
    mapping(address => address) public referrals;
    mapping(address => uint256) public tokensMintedToReferrals;
    mapping(uint256 => DailyDistributionRatio) public dailyRatio;
    
    
    mapping(address => uint256) public donatorClaimedBusdFromBPDs;
    mapping(address => uint256) public donatorClaimableBusdFromBPDs;
}


/**
 * @dev Abstract contract that contains helper functions.
 */
abstract contract Helper is Data {
    
    function _notContract(address _addr) internal view returns (bool) {
        uint32 size; assembly { size := extcodesize(_addr) } return (size == 0); }
}


/**
 * @dev Abstract contract that contains all functions related to interacting with the NOX-BUSD pool.
 */
abstract contract PoolMgmt is Helper {
    
    using SafeMath for uint256;
    
    IUniswapV2Router02 public UNISWAP_ROUTER;
    address public FACTORY;
    
    //can be called externally by a benefactor
    function fillLiquidityPool() public {
        (uint256 poolTokenAvg, uint256 poolBusdAvg) = TOKEN_CONTRACT.getPoolAvg();
        _fillLiquidityPool(poolTokenAvg, poolBusdAvg);
    }
    
    /**
     * @dev Internal function to fill the liquidity NOX-BUSD pool when enough busd has been gathered.
     * This function is an adaptation of the _fillLiquidityPool on the token contract.
     */
    function _fillLiquidityPool(uint256 poolTokenAvg, uint256 poolBusdAvg) internal {
        
        uint256 tokenAmount = 0;
        
        if(BusdForPoolAccounting < 1E18) return;
        
        if(!TOKEN_CONTRACT.hasPoolBeenCreated()) {
            TOKEN_CONTRACT.createPool();
            
            tokenAmount = BusdForPoolAccounting.mul(TOKEN_CONTRACT.getDefaultTokenBusdRatio());
        }
        else {
            tokenAmount = BusdForPoolAccounting.mul(poolTokenAvg).div(poolBusdAvg);
        }

        //the auction contract may have some remaining NOX tokens that it wasn't able to transfer to the pool
        uint256 heldTokens = TOKEN_CONTRACT.balanceOf(address(this));
        
        //if the quantity of held tokens is inferior to what needs to be minted, mint the difference
        if(heldTokens < tokenAmount) {
            //mint the tokens for the pool
            TOKEN_CONTRACT.mintSupply(address(this), tokenAmount.sub(heldTokens));
        }
        //otherwise, the contract holds enough NOX to fill the pool at the current rate
        
        //allow the transfer of tokens to uniswap router
        TOKEN_CONTRACT.approve(address(UNISWAP_ROUTER), tokenAmount);
        BUSD_CONTRACT.approve(address(UNISWAP_ROUTER), BusdForPoolAccounting);
        
        
        (,uint256 busdSentToPool,) = UNISWAP_ROUTER.addLiquidity(
            address(TOKEN_CONTRACT),
            address(BUSD_CONTRACT),
            tokenAmount,
            BusdForPoolAccounting,
            0,
            0,
            address(0x0), //burn liquidity tokens
            block.timestamp.add(2 hours)
        );
    
        TotalBusdSentToPool = TotalBusdSentToPool.add(busdSentToPool);
        BusdForPoolAccounting = BusdForPoolAccounting.sub(busdSentToPool);

        emit liquidityAdded(CurrentAuctionDay, tokenAmount, BusdForPoolAccounting);
    }
}

/**
 * @dev Abstract contract that contains all functions related to updating a day, generating random busd rewards, and functions for claiming purchased NOX and rewarded BUSD.
 */
abstract contract DistributionMgmt is PoolMgmt {
    using SafeMath for uint256;
    
    modifier updateDayTrigger() {
        _updateDay();
        _;
    }
    
    //can be called by an external benefactor
    function updateDay() external { _updateDay(); }
    

    /**
     * @dev Internal function to update the day. Advances the auction day until it reaches the CurrentTokenDay on the NOX contract.
     */
    function _updateDay() internal {
        
        uint256 currentTokenDay = TOKEN_CONTRACT.getCurrentTokenDay();
        //in theory CurrentAuctionDay should never be bigger than currentTokenDay, but for safety let's leave it here
        if(CurrentAuctionDay >= currentTokenDay) {
            //nothing to do
            return;
        }

        //if we've reached the last day of the contract, do nothing
        if(CurrentAuctionDay > MAX_DONATION_DAYS) {
            return;
        }

        //try to register the pool ratio
        TOKEN_CONTRACT.registerPoolRatio();

        //try to fill the liquidity pool
        fillLiquidityPool();
        
        while(CurrentAuctionDay < currentTokenDay) {
            _registerDistributionRatio(CurrentAuctionDay);
            //create a random reward
            _createRandomDailyReward(CurrentAuctionDay);
            //update the day
            CurrentAuctionDay += 1;
            
            emit auctionDayUpdated(CurrentAuctionDay);
        }
    }
    
    
    /**
     * @dev Private function to register the daily distribution ratio of NOX to BUSD.
     */
    function _registerDistributionRatio(uint256 day) private {
        DailyDistributionRatio memory ratio;
        
        if(dailyBusdDonations[day] == 0) {
            //if no one donated, set the ratio to 0/1
            ratio.numerator = 0;
            ratio.denominator = 1;
        }
        else {
            ratio.numerator = DAILY_SUPPLY;
            ratio.denominator = dailyBusdDonations[day]; 
        }
        ratio.tokenDay = day;
        
        
        dailyRatio[day] = ratio;
    }
    

    /**
     * @dev External function for claiming tokens from daily auctions. Allows user to claim all tokens he hasn't claimed yet from all the auctions he participated in.
     */
    function claimTokensFromAuctions() external updateDayTrigger {
        
        uint256 currentTokenDay = CurrentAuctionDay;
        require(currentTokenDay > 1, 'Too early.');
        require(currentTokenDay < LAST_CONTRACT_DAY, 'Too late.');
       
        uint256 claimUntilDate = currentTokenDay < MAX_DONATION_DAYS + 1 ? currentTokenDay : MAX_DONATION_DAYS + 1; 
        
        uint256 payout = 0;
        
        //start at the day after the current claimedUntilDate
        uint32 claimedUntil = claimedUntilDate[msg.sender]+1;
        
        
        for( ;claimedUntil < claimUntilDate; claimedUntil++) {
            payout += donatorBusdDailyDonations[msg.sender][claimedUntil].mul(dailyRatio[claimedUntil].numerator).div(dailyRatio[claimedUntil].denominator);
            claimedUntilDate[msg.sender] = claimedUntil;
        }

        //if there are tokens to claim
        if (payout > 0) {
            donatorTotalClaimedTokens[msg.sender] = donatorTotalClaimedTokens[msg.sender].add(payout);
            TotalTokensClaimedFromDonations = TotalTokensClaimedFromDonations.add(payout);
            TOKEN_CONTRACT.mintSupply(msg.sender, payout);
            
            emit tokensClaimed(CurrentAuctionDay, payout, msg.sender);
        }
    }
    
    /**
     * @dev External function for claiming BUSD from daily rewards. Allows user to claim all BUSD he hasn't claimed yet from all the daily awards he got.
     */
    function claimBusdFromBPDs() external updateDayTrigger
    {
        uint256 currentTokenDay = CurrentAuctionDay;
        require(currentTokenDay > 1, 'Too early.');
        require(currentTokenDay < LAST_CONTRACT_DAY, 'Too late.');

        require(donatorClaimableBusdFromBPDs[msg.sender] > 0, 'No BUSD to claim.');
        uint256 claimed = donatorClaimableBusdFromBPDs[msg.sender];
        donatorClaimableBusdFromBPDs[msg.sender] = 0;
        
        donatorClaimedBusdFromBPDs[msg.sender] = donatorClaimedBusdFromBPDs[msg.sender].add(claimed); 
        TotalBusdClaimedFromBPDs = TotalBusdClaimedFromBPDs.add(claimed); // add to total claimed
        
        //transfer the BEP-20 BUSD to claimer
        BUSD_CONTRACT.transfer(msg.sender, claimed);
        
        emit busdClaimed(CurrentAuctionDay, claimed, msg.sender);
    }
    
    /**
     * @dev Private function for creating random daily rewards.
     */
    function _createRandomDailyReward(uint256 tokenDay) private {
        
        //if nothing was donated do nothing
        if(BusdForBPDAccounting == 0) return;

        uint256 numParticipants = donatorAccountCount[tokenDay];

        //if no one donated, do nothing
        if(numParticipants == 0) return;
        
         uint256[] memory participants = new uint256[](numParticipants);
         
         for(uint256 i = 0; i < numParticipants; i++) { participants[i]=i; }
         
         
         // shuffle the list of donators if more than one participated
        if (numParticipants > 1)
        {
            for(uint256 i = 0; i < numParticipants; i++)
            {
                uint256 n = i + _getRandomNumber(numParticipants) % (numParticipants - i);
                uint256 temp = participants[n];
                participants[n] = participants[i];
                participants[i] = temp;
            }
        }
        
        //go through the list and check for each donator if there is still enough BUSD to give bacK
        //read from storage at the start of the loop
        uint256 currentBusdAccounting = BusdForBPDAccounting;

        for(uint256 i = 0; i < numParticipants; i++) {
            
            address winner = donatorAccounts[tokenDay][participants[i]];
            uint256 donatedAmount = donatorBusdDailyDonations[winner][tokenDay];
            
            //check if there's still enough busd to give back
            if(currentBusdAccounting >= donatedAmount) {
                donatorClaimableBusdFromBPDs[winner] = donatorClaimableBusdFromBPDs[winner].add(donatedAmount);
                currentBusdAccounting = currentBusdAccounting.sub(donatedAmount);
            }
        }


        TotalBusdSentToBPD = TotalBusdSentToBPD.add(BusdForBPDAccounting.sub(currentBusdAccounting));
        //write to storage only at the end of the loop
        BusdForBPDAccounting = currentBusdAccounting;
         
    }

    /**
     * @dev Private function for generating a random number.
     */
    function _getRandomNumber(uint256 ceiling) private view returns (uint256) {
        if (ceiling > 0)
        {
            uint256 val = uint256(blockhash(block.number - 1)) % uint256(block.timestamp) + (block.difficulty);
            val = val % uint(ceiling);
            return val;
        }
        else return 0;
    }
}

/**
 * @dev Abstract contract that contains all functions related to managing auction donations.
 */
abstract contract DonationMgmt is DistributionMgmt {
    using SafeMath for uint256;


    /**
     * @dev External function for checking how much BUSD as credit the user has from his auction donations.
     */
    function checkDonatorBusdCredit(address account) external view returns (uint256) {
        return donatorBusdCredit[account];
    }
    
    /**
     * @dev External function that can only be called from the NOX contract to deduct BUSD credit.
     */
    function deductDonatorBusdCredit(address account, uint256 quantity) external {
        require(msg.sender == address(TOKEN_CONTRACT), "Not authorized");
        require(donatorBusdCredit[account] >= quantity, "Quantity to deduct from busd credit is higher than available credit");
        donatorBusdCredit[account] = donatorBusdCredit[account].sub(quantity);
    }

    /**
     * @dev External function to donate busd for an auction day. Users can donate BUSD multiple times and as such get a greater stake of the NOX to distribute.
     * For an auction day, participants are limited to a maximum of 1000.
     */
    function donateBusd(uint256 amountToDonateBusd, address referral) external updateDayTrigger {
        require(amountToDonateBusd >= MIN_DONATE, "Donation below minimum");
        uint256 currentTokenDay = CurrentAuctionDay;
        //check if this donation exceeds the maximum daily amount
        require(donatorBusdDailyDonations[msg.sender][currentTokenDay].add(amountToDonateBusd) <= MAX_DONATE, "Donation above maximum for today");
        require(currentTokenDay >= 1, "Too early");
        require(currentTokenDay <= MAX_DONATION_DAYS, "Too late");
        require(_notContract(referral), "Referral address cannot be a contract");


        //if the donator hasn't donated today, registed it and increase today's donation count
        if (donatorBusdDailyDonations[msg.sender][currentTokenDay] == 0) {
            //if this is a new donator check if he has surpassed the maximum number of donators for today
            require(donatorAccountCount[currentTokenDay] < MAX_NUM_PARTICIPANTS, "Maximum number of auction participants reached for today");

            donatorAccounts[currentTokenDay][donatorAccountCount[currentTokenDay]] = msg.sender;
            donatorAccountCount[currentTokenDay]++;
        }
        
        
        _processDonatedBusd(msg.sender, currentTokenDay, amountToDonateBusd, referral);
        
        //try to register the pool ratio
        TOKEN_CONTRACT.registerPoolRatio();
    }
    
    
    /**
     * @dev Private function to process the donated BUSD.
     */
    function _processDonatedBusd(address sender, uint256 tokenDay, uint256 amountToDonateBusd, address referral) private {
        //check if user has enough busd to donate    
        require(BUSD_CONTRACT.balanceOf(sender) >= amountToDonateBusd, "Account does not have enough BUSD");
        require(BUSD_CONTRACT.allowance(sender, address(this)) >= amountToDonateBusd, "Not enough BUSD allowed");
        require(BUSD_CONTRACT.transferFrom(sender, address(this), amountToDonateBusd), "Unable to transfer required BUSD");
        
        
        //check if referral was provided and if so update it
        if(referral != address(0x0) && referral != sender) {
            referrals[sender] = referral;
        }
        
        //if there is an address to work with, otherwise do nothing
        if(referrals[sender] != address(0x0)) {
            //get the current pool ratio
            (uint256 poolTokenAvg, uint256 poolBusdAvg) = TOKEN_CONTRACT.getPoolAvg();
            
            uint256 tokensToMintForReferral = amountToDonateBusd.mul(poolTokenAvg).div(poolBusdAvg).mul(REF_NUMERATOR).div(REF_DENOMINATOR);
            TOKEN_CONTRACT.mintSupply(referrals[sender], tokensToMintForReferral);
            tokensMintedToReferrals[referrals[sender]] = tokensMintedToReferrals[referrals[sender]].add(tokensToMintForReferral);
            TotalTokensMintedToReferrals = TotalTokensMintedToReferrals.add(tokensToMintForReferral);
        }
        
         
        uint256 busd = amountToDonateBusd.mul(M_NUMERATOR).div(M_DENOMINATOR);
        
        BUSD_CONTRACT.transfer(M_ADDRESS1, busd);
        BUSD_CONTRACT.transfer(M_ADDRESS2, busd);
        
        
        //update the balance of the donator for today
        donatorBusdDailyDonations[sender][tokenDay] = donatorBusdDailyDonations[sender][tokenDay].add(amountToDonateBusd);
        
        //increase the busd credit of the donatorBusdDailyDonations
        donatorBusdCredit[sender] = donatorBusdCredit[sender].add(amountToDonateBusd);
        
        //update the balance of total donated for today
        dailyBusdDonations[tokenDay] = dailyBusdDonations[tokenDay].add(amountToDonateBusd);
        
        //update the total of busd ever sent to auction
        TotalBusdSentToAuctions = TotalBusdSentToAuctions.add(amountToDonateBusd);
        
        //update the ratio to go to the Pool
        BusdForPoolAccounting = BusdForPoolAccounting.add(amountToDonateBusd.mul(POOL_NUMERATOR).div(POOL_DENOMINATOR));

        //update the ratio to go to BPD
        BusdForBPDAccounting = BusdForBPDAccounting.add(amountToDonateBusd.mul(BPD_NUMERATOR).div(BPD_DENOMINATOR));
        
        emit donationReceived(CurrentAuctionDay, sender, amountToDonateBusd);

    }
}

/**
 * @dev Abstract contract that contains all functions for reading data related to the current state of auctions.
 */
abstract contract ContractStateReader is DonationMgmt {
    using SafeMath for uint256;
    
    /**
     * @dev External function to read how many NOX a user can claim
     */
    function claimableTokensFromAuctions(address account) external view returns (uint256) {
        uint256 currentTokenDay = CurrentAuctionDay;
        
        if(currentTokenDay < 2 || currentTokenDay > LAST_CONTRACT_DAY) return 0;
       
        uint256 claimUntilDate = currentTokenDay < MAX_DONATION_DAYS + 1 ? currentTokenDay : MAX_DONATION_DAYS + 1; 
        
        uint256 payout = 0;
        
        //start at the day after the current claimedUntilDate
        uint32 claimedUntil = claimedUntilDate[account]+1;
        //can claim tokens for auctions that happened from day 2 to MA 
        for( ;claimedUntil < claimUntilDate; claimedUntil++) {
            payout += donatorBusdDailyDonations[account][claimedUntil].mul(dailyRatio[claimedUntil].numerator).div(dailyRatio[claimedUntil].denominator);
        }
        
        return payout;
    }

    /**
     * @dev External function to read how many BUSD a user can claim from rewards he has won.
     */
    function claimableBusdFromBPDs(address account) external view returns (uint256) {
        if(CurrentAuctionDay < 2 || CurrentAuctionDay > LAST_CONTRACT_DAY) return 0;
        return donatorClaimableBusdFromBPDs[account];
    }


    /**
     * @dev External function to read how much BUSD a user has donated for a specific day.
     */
    function userDonationOnDay(address account, uint256 tokenDay) external view returns (uint256) {
        return donatorBusdDailyDonations[account][tokenDay];
    }

    /**
     * @dev External function to read how much BUSD a user has donated in total.
     */
    function userdonationsOnAllDays(address account) external view returns (uint256[366] memory allDays) {
        for(uint32 i = 1; i <= MAX_DONATION_DAYS; i++) {
            allDays[i] = donatorBusdDailyDonations[account][i];
        }
    }
    
    
    /**
     * @dev External function to provide pagination of auction days.
     */
    function auctionsPagination(address account, uint256 offset, uint256 length) public view returns (AuctionResult[] memory auctions) {
        //if offset has exceeded the available elements return an empty array
        if(offset > CurrentAuctionDay - 1) {
            auctions = new AuctionResult[](0);
            return auctions;
        }
        
        if(offset + length > CurrentAuctionDay - 1) {
            length = (CurrentAuctionDay - 1) - offset;
        }
        
        auctions = new AuctionResult[](length);
        
        uint256 end = offset + length;
        
        for(uint256 i = 0; offset < end; offset++) {
            
            auctions[i].auctionDay = offset+1;
            auctions[i].totalDonatedBusd = dailyBusdDonations[offset+1];
            auctions[i].donatedBusdByUser = donatorBusdDailyDonations[account][offset+1];
            auctions[i].numberOfParticipants = donatorAccountCount[offset+1];
            
            i++;
        }
    }
}

/**
 * @dev Auctions contract that inherits from all abstract contracts.
 */
contract NoxAuctions is ContractStateReader {
    address public TOKEN_DEFINER;

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'Wrong sender.'
        );
        _;
    }
    
    /**
     * @dev External function accessible only by the token definer to forever deny special access for the token definer. This operation is irreversible.
     */
    function revokeAccess() external onlyTokenDefiner {
        TOKEN_DEFINER = address(0x0);
    }


    receive() external payable { revert(); }
    fallback() external payable { revert(); }


    /**
     * @dev External function accessible only by the token definer to set external addresses and contracts.
     */
    function setContracts(address tokenContract, address mAddress1, address mAddress2) external onlyTokenDefiner {
        TOKEN_CONTRACT = IToken(tokenContract);
        M_ADDRESS1 = mAddress1;
        M_ADDRESS2 = mAddress2;
    }

    /**
     * @dev Auctions contract constructor.
     */
    constructor() {
        
        TOKEN_DEFINER = msg.sender;
        
        BUSD_CONTRACT = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        UNISWAP_ROUTER = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
    }
}