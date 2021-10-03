/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

//                        ,                                                      
//                        *%#%.                                                    
//                        %%(#%%                                                   
//                       (%((((%%     ..*****..                                    
//                       %%((((((%%********************.                           
//                       %%((((((((%%%**********************,                      
//                   ,***%%(((((((((((#%%%#**********************                  
//                .******%%((((((((((((((((#%%%*********************               
//              **********(%%((((((((((((((((((#%%*********************            
//            ***************%%(((((((((((((((((((%%**********************         
//          ******************#%((((((((((((((((((((%%**********************       
//        .********************%%((((((((((((((((((((#%#*********************,     
//       **********************/%#(((((((((((((((((((((%%**********************    
//      ***********************(%#((((((((((((((((((((((%%**********************.  
//     ************************%%((((((((((((((((((((((((#%**********************  
//    ************************/%#(((((((((((((((((((((((((%%********************** 
//   *************************%%(((((((((((((((((((((((((((%#**********************
//  *************************%%((((((((((((((((((((((((((((#%%*********************
//  ************************%%((((((((((((((((((((((((((((((((%#*******************
// ************************%%(((((((((((((((((((((((((((((((((%%*******************
// ***********************%%(((((((((((#%%%%%%%%%%((((((((((((%%*******************
// **********************#%(((((((((%%#*,,,,,,,,,,#%#(((((((((%%*******************
// **********************#%%(((((##%%**,,,,,,,,,,,,,%%(((((((((%%******************
//  *******************(%#(#%%%/,,,,%(*,,,,,,,,,,,,,%(/###(*,,*#%%/*************** 
//  ******************(%#%%/,,,,,,,,*%%***,,,,,,,/%%/,,,,,,,,,,*%****************, 
//   ******************(/(,,,,,,,,,,,,,/%%%%%%%%(,,,,,,,,,,,,,,*%/***************  
//    *******************#%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/%/**************   
//     *******************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%%*************.    
//      ******************/%/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%#************      
//        *****************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%%************       
//         *****************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(%***********         
//            **************/%**%%,,,,,,,,,,,,,,,,,,,,,,*%%%%%/********            
//              ,************%%%#%%,,,,,,,,,,,,,,,,,,,,%%***%********              
//                  **********#/**%%,,,,,,,,,,,,,,,,,/%#*********                  
//                       **********%%*%%,,,,,,,(#,,,%%******,                      
//                               .**%%%(%*,,,#%/(%#%%.                             
//                                      %%/,(%    %,                               
//                                       (%#%(                                     
// TG: https://t.me/GnomeArmy
// WWW: https://gnome.army
// @
// A hyper-deflationary BEP20 staking rewards contract
// Stake GNOME to earn BNB
//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function totalSupply() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}
pragma solidity >=0.6.8;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "This is only for people ");
        _;
    }
}

contract gnomeStake is Owned, ReentrancyGuard {
    // initializing safe computations
    using SafeMath for uint256;

    // gnome contract address
    address public gnome;
    // total amount of staked gnome
    uint256 public totalStaked;
    // tax rate for staking in percentage
    uint256 public stakingTaxRate; //10 = 1%
    // tax amount for registration
    uint256 public registrationTax;
    // daily return of investment in percentage
    // 14.2% daily ROI = 1428
    uint256 public dailyROI; 
    // tax rate for unstaking in percentage
    //10 = 1%
    uint256 public unstakingTaxRate; 
    // minimum stakeable gnome
    uint256 public minimumStakeValue;
    // the maximum percent of BNB pool relative to users staked token that they can claim without referrals
    //900 = 90%
    uint256 public basePoolShare; 
    // maximum number of referrals a user can recieve rewards for
    // initially set to 10
    uint256 public maxReferrals;
    // penalty rate for unstaking
    // 100 = 1%, 5000 = 50%
    uint256 public unStakePenaltyRate;
    // pause mechanism
    bool public active = true;
    // what unit time do we accrue rewards in seconds - 86400 = 24 hours
    uint256 public UNIT_TIME = 86400;
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    // index of last processed
    uint256 public lastProcessedIndex;
    // array of token holders for iterating through later
    address[] public userAddresses;

    // mapping of stakeholder's addresses to data
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public stakeRewards;
    mapping(address => uint256) public lastClock;
    mapping(address => bool) public registered;

    // Events
    event OnWithdrawal(address sender, uint256 amount);
    event OnBNBWithdrawal(address sender, uint256 amount);
    event OnStake(address sender, uint256 amount, uint256 tax);
    event OnUnstake(address sender, uint256 amount, uint256 tax);
    event OnRegisterAndStake(
        address stakeholder,
        uint256 amount,
        uint256 totalTax,
        address _referrer
    );
    event basePoolShareUpdated(uint256 basePoolShare);
    event dailyROIUpdated(uint256 dROI);
    event maxReferralsUpdated(uint256 refs);
    event stakingTaxUpdated(uint256 stakingTax);
    event unstakingTaxUpdated(uint256 unStakingTax);
    event registrationTaxUpdated(uint256 registrationTax);
    event minimumStakeUpdated(uint256 minimumStake);
    event GnomeVaultOpenedOrClosed(bool Opened);
    event TimetoRewardsUpdated(uint256 UNIT_TIME);
    event MaxReferralsUpdated(uint256 maxRefs);
    event Processed(uint256 iterations, uint256 lastProcessedIndex);
    event manualProcessed(uint256 gas);
    event EmergencyWithdrawal(uint256 amount);

    // to receive BNB from GnomeToken
    receive() external payable {}

    /**
     * @dev Sets the initial values
     */
    constructor(
        address _token,
        uint256 _stakingTaxRate,
        uint256 _unstakingTaxRate,
        uint256 _dailyROI,
        uint256 _registrationTax,
        uint256 _minimumStakeValue,
        uint256 _basePoolShare,
        uint256 _maxReferrals,
        uint256 _unStakePenaltyRate
    ) public {
        // set initial state variables
        gnome = _token;
        stakingTaxRate = _stakingTaxRate;
        unstakingTaxRate = _unstakingTaxRate;
        dailyROI = _dailyROI;
        registrationTax = _registrationTax;
        minimumStakeValue = _minimumStakeValue;
        basePoolShare = _basePoolShare;
        maxReferrals = _maxReferrals;
        unStakePenaltyRate = _unStakePenaltyRate;
    }

    // exclusive access for registered address
    modifier onlyRegistered() {
        require(registered[msg.sender] == true, "GnomeStaking: Gnome must be registered");
        _;
    }

    // exclusive access for unregistered address
    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "GnomeStaking: Gnome is already registered");
        _;
    }

    // make sure contract is active
    modifier whenActive() {
        require(active == true, "GnomeStaking: GnomeStaking is curently inactive");
        _;
    }

    // adds address to array (called on registerandstake)
    function includeAddress(address _address) private {
        userAddresses.push(_address);
    }

    // removes address from array (called on unregister)
    function removeAddress(address _address) private {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _address) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
    }

    function NumberOfStakers() public view returns (uint256) {
        return userAddresses.length;
    }

    // loops through address array updating claims
    function process(uint256 gas) private returns (uint256, uint256) {
        uint256 numberOfTokenHolders = userAddresses.length;

        if (numberOfTokenHolders == 0) {
            return (0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= userAddresses.length) {
                _lastProcessedIndex = 0;
            }

            address account = userAddresses[_lastProcessedIndex];
            // Do not change existing stake rewards, but add uncalculated earnings 
            stakeRewards[account] = (stakeRewards[account]).add(
                calculateEarnings(account)
            );
            // Recalculate referral rewards, if the user has claimed and referrer count has been reset it will return 0
            referralRewards[account] = (calculateReferralRewards(account)).mul(
                referralCount[account]
            );
            // When did we process the claim calculation
            uint256 remainder = (now.sub(lastClock[account])).mod(UNIT_TIME);
            lastClock[account] = now.sub(remainder);

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;
        emit Processed(iterations, lastProcessedIndex);
        return (iterations, lastProcessedIndex);
    }
    // Manually process claims, use to fine tune gasForProcessing when needed
    function manualProcess(uint256 gas) external onlyOwner whenActive {
        gas == 0 ? gas = gasForProcessing : gas;
        process(gas);
        emit manualProcessed(gas);
    }

    //  1. Registers the user into array to be processed
    //  2. Checks if the user has a referrer and that it is not a self-referral
    //  2a. Increases the referrers count, if less than maxReferrals and adds referral reward
    //  3. Deducts registration tax and staking tax
    //  4. Takes GNOME and adds into staked pool
    //  5. Process other stakeholders 
    function registerAndStake(uint256 _amount, address _referrer)
        external
        onlyUnregistered
        whenActive
    {
        // ensure user is not the referrer
        require(msg.sender != _referrer, "GnomeStaking: Cannot refer self");
        // ensure referrer is registered
        require(
            registered[_referrer] || address(0x0) == _referrer,
            "GnomeStaking: Referrer must be registered"
        );
        // ensure user has enough
        require(
            IERC20(gnome).balanceOf(msg.sender) >= _amount,
            "GnomeStaking: Must have enough balance to stake"
        );
        // ensure amount is more than the registration fee and the minimum deposit
        require(
            _amount >= registrationTax.add(minimumStakeValue),
            "GnomeStaking: Must send at least enough gnome to pay registration fee."
        );
        // ensure smart contract transfers gnome from user
        require(
            IERC20(gnome).transferFrom(msg.sender, address(this), _amount),
            "GnomeStaking: Stake failed due to failed amount transfer."
        );
        // calculates final amount after deducting registration tax
        uint256 finalAmount = _amount.sub(registrationTax);
        // calculates staking tax on final calculated amount
        uint256 stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        // if user registers with referrer and has less than max referrals
        if (
            _referrer != address(0x0) &&
            referralCount[_referrer] <= maxReferrals
        ) {
            // increase referral count of referrer
            referralCount[_referrer]++;
            // add referral bonus to referrer
            referralRewards[_referrer] = (referralRewards[_referrer]).add(
                calculateReferralRewards(_referrer)
            );
        }
        // register user
        registered[msg.sender] = true;
        // include user for processing
        includeAddress(msg.sender);
        // mark the transaction date
        lastClock[msg.sender] = now;
        // update the total staked gnome amount in the pool
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        // update the user's stakes deducting the staking tax
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(
            stakingTax
        );
        // emit event
        emit OnRegisterAndStake(
            msg.sender,
            _amount,
            registrationTax.add(stakingTax),
            _referrer
        );
        // process other stakeholders
        process(gasForProcessing);
    }

    // 1. Get the number of days (or unit time) between last payout and now
    // 2. Get the amount of BNB the user is entitled to 
    // 3. Multiply amount of BNB by the number of active days and ROI
    // 4. Safety: if the users earnings are more than the entitled amount, set earnings to the entitled amount
    function calculateEarnings(address _stakeholder)
        public
        view
        returns (uint256)
    {
        // records the number of days between the last payout time and now
        uint256 activeDays = (now.sub(lastClock[_stakeholder])).div(UNIT_TIME);
        // check there is a stakeholder active in order to begin calculations
        uint256 BNBAfterBase = GetBNBAfterBasePool(_stakeholder);
        // returns earnings based on daily ROI and active days
        uint256 earnings = ((BNBAfterBase).mul(dailyROI).mul(activeDays)).div(
            10000
        );
        // check to ensure user cannot earn more than their pool ratio dictates
        if (earnings >= GetBNBAfterBasePool(_stakeholder)) {
            earnings = GetBNBAfterBasePool(_stakeholder);
        }
        return earnings;
    }
    // Determine how much each referral is worth for each user
    function calculateReferralRewards(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 referralRewardBNB = GetBNBPerReferral(_stakeholder);
        return referralRewardBNB;
    }

    // Used for calculating the % staked per user with precision
    function percent(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) private pure returns (uint256 quotient) {
        uint256 _numerator = numerator.mul(10**(precision + 1));
        // with rounding of last digit
        uint256 _quotient = ((_numerator.div(denominator)).add(5)).div(10);
        return (_quotient);
    }

    // returns ratio of staked GNOME to the total staking pool
    function GetPoolPercent(address _stakeholder)
        public
        view
        returns (uint256)
    {
        // the proportion of user staked gnome compared to the total amount of gnome staked
        // first check if the stakeholder has any stakes and there are stakes in the pool
        if (stakes[_stakeholder] == 0 || totalStaked == 0) {
            return 0;
        }
        uint256 PoolRatio = percent(stakes[_stakeholder], totalStaked, 15);
        return PoolRatio;
    }

    // returns the users share of the BNB pool
    function GetBNBOfPoolRatio(address _stakeholder)
        public
        view
        returns (uint256)
    {
        // the proportion of user staked gnome compared to the total amount of gnome staked
        uint256 PoolRatio = GetPoolPercent(_stakeholder);
        // user ownership of pool compared to BNB balance of the contract
        uint256 OfTotalBNBPool = ((PoolRatio).mul(address(this).balance)).div(
            10**15
        );
        // returns amount user is entitled to just on their stake alone
        return OfTotalBNBPool;
    }

    // returns the users share of the BNB pool after basePoolShare
    function GetBNBAfterBasePool(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 OfTotalBNBPool = GetBNBOfPoolRatio(_stakeholder);
        // calculates basepool share of total BNB rewards
        uint256 BNBAfterBase = (basePoolShare.mul(OfTotalBNBPool)).div(1000);
        return BNBAfterBase;
    }

    // returns the maximum amount a user can earn from referrals
    // the % that isn't allocated for staking reward for the user is used for referrals
    function GetTotalReferralBNB(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 OfTotalBNBPool = GetBNBOfPoolRatio(_stakeholder);
        uint256 BNBAfterBase = GetBNBAfterBasePool(_stakeholder);
        uint256 MaxRefBNB = (OfTotalBNBPool).sub(BNBAfterBase);
        return MaxRefBNB;
    }
    // Determine BNB per referral by dividing the available BNB for that user by the maximum referrals
    function GetBNBPerReferral(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 TotalBNBPerReferral = GetTotalReferralBNB(_stakeholder);
        uint256 BNBPerReferral = (TotalBNBPerReferral).div(maxReferrals);
        return BNBPerReferral;
    }

    // returns the contract BNB balance
    function whatbal() public view returns (uint256) {
        return address(this).balance;
    }

    //  1. Checks the user is already registered
    //  2. Deduct the staking, but not registration tax
    //  3. Takes GNOME and adds into staked pool
    //  4. Process other stakeholders 
    function stake(uint256 _amount) external onlyRegistered whenActive {
        // makes sure stakeholder does not stake below the minimum
        require(
            _amount >= minimumStakeValue,
            "GnomeStaking: Amount is below minimum stake value."
        );
        // makes sure stakeholder has enough balance
        require(
            IERC20(gnome).balanceOf(msg.sender) >= _amount,
            "GnomeStaking: Must have enough balance to stake"
        );
        // makes sure smart contract transfers gnome from user
        require(
            IERC20(gnome).transferFrom(msg.sender, address(this), _amount),
            "GnomeStaking: Stake failed due to failed amount transfer."
        );
        // calculates staking tax on amount
        uint256 stakingTax = (stakingTaxRate.mul(_amount)).div(1000);
        // calculates amount after tax
        uint256 afterTax = _amount.sub(stakingTax);
        // update the total staked gnome amount in the pool
        totalStaked = totalStaked.add(afterTax);
        // adds earnings current earnings to stakeRewards
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(
            calculateEarnings(msg.sender)
        );
        // calculates unpaid period
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(UNIT_TIME);
        // mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        // updates stakeholder's stakes
        stakes[msg.sender] = (stakes[msg.sender]).add(afterTax);
        // emit event
        emit OnStake(msg.sender, afterTax, stakingTax);
        // process
        process(gasForProcessing);
    }

    //  1. Applies the unstaking tax to _amount
    //  2. Removes amount after tax from the users total staked amount
    //  3. Applies the unstaking penalty to the users stakeRewards
    //  4. If the user has no stakes remaining, the user is unregistered
    //  5. Transfers the amount after tax to the user
    function unstake(uint256 _amount) external onlyRegistered nonReentrant {
        // makes sure _amount is not more than stake balance
        require(
            _amount <= stakes[msg.sender] && _amount > 0,
            "GnomeStaking: Insufficient balance to unstake"
        );
        // calculates unstaking tax
        uint256 unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        // calculates amount after tax
        uint256 afterTax = _amount.sub(unstakingTax);
        // sums up stakeholder's total rewards with _amount deducting unstaking tax
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(
            calculateEarnings(msg.sender)
        );
        // updates stakes
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        // calculates unpaid period
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(UNIT_TIME);
        // mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        // update the total staked gnome amount in the pool
        totalStaked = totalStaked.sub(_amount);
        // conditional statement if stakeholder has no stake left
        if (stakes[msg.sender] == 0) {
            // deregister stakeholder
            registered[msg.sender] = false;
            // remove from processing
            removeAddress(msg.sender);
        }
        // apply the unstaking penalty rate
        stakeRewards[msg.sender] = (
            (stakeRewards[msg.sender]).mul(unStakePenaltyRate)
        ).div(10000);
        // emit event
        IERC20(gnome).transfer(msg.sender, afterTax);
        emit OnUnstake(msg.sender, _amount, unstakingTax);
        // process others
        process(gasForProcessing);
    }

    // 1. Users can withdraw earnings if registered or not, and even if the contract is paused
    // 2. Add up the total rewards (existing stake rewards, unpaid rewards, and referral rewards)
    // 3. Check total reward is available
    // 4. Reset the the users data before transfer and set lastClock
    // 5. Send BNB to the user, emit event on success
    // 6. Process other users
    function withdrawEarnings() external nonReentrant returns (bool success) {
        // calculates the total redeemable rewards
        uint256 totalReward = (referralRewards[msg.sender])
            .add(stakeRewards[msg.sender])
            .add(calculateEarnings(msg.sender));
        // makes sure user has rewards to withdraw before execution
        require(totalReward > 0, "GnomeStaking: No reward to withdraw");
        // makes sure totalReward is not more than required balance
        require(
            (address(this).balance) >= totalReward,
            "GnomeStaking: Insufficient BNB balance in pool"
        );
        // initializes stake rewards
        stakeRewards[msg.sender] = 0;
        // initializes referal rewards
        referralRewards[msg.sender] = 0;
        // initializes referral count
        referralCount[msg.sender] = 0;
        // update the clock
        uint256 remainder = (now.sub(lastClock[msg.sender])).mod(UNIT_TIME);
        // mark transaction date with remainder
        lastClock[msg.sender] = now.sub(remainder);
        // send BNB reward
        // address payable receiver = payable(msg.sender);
        (bool txsuccess, ) = (msg.sender).call{value: totalReward}("");
        require(txsuccess, "GnomeStaking: Transfer failed.");
        // emit event
        emit OnBNBWithdrawal(msg.sender, totalReward);
        // process others
        process(gasForProcessing);
        return true;
    }

    // The amount of GNOME available to be collected from taxes
    // This GNOME will be used for buybacks
    function Taxes() external view onlyOwner returns (uint256 claimable) {
        return (IERC20(gnome).balanceOf(address(this))).sub(totalStaked);
    }

    // Prevents new stakers, does not halt reward withdrawal
    function toggleActiveStatus() external onlyOwner {
        if (active) {
            active = false;
            emit GnomeVaultOpenedOrClosed(false);
        } else {
            active = true;
            GnomeVaultOpenedOrClosed(true);
        }
    }

    // sets the staking rate
    function setStakingTaxRate(uint256 _stakingTaxRate) external onlyOwner {
        require(_stakingTaxRate <= 100, "GnomeStaking: Must be less than 10%");
        stakingTaxRate = _stakingTaxRate;
        emit stakingTaxUpdated(stakingTaxRate);
    }

    // sets the unstaking rate
    function setUnstakingTaxRate(uint256 _unstakingTaxRate) external onlyOwner {
        require(_unstakingTaxRate <= 200, "GnomeStaking: Must be less than 20%");
        unstakingTaxRate = _unstakingTaxRate;
        emit unstakingTaxUpdated(unstakingTaxRate);
    }

    // sets the daily ROI
    function setDailyROI(uint256 _dailyROI) external onlyOwner {
        require(_dailyROI <= 3000, "GnomeStaking: ROI must be less than or equal to 30%");
        require(_dailyROI >= 1000, "GnomeStaking: ROI must be greater than or equal to 10%");
        dailyROI = _dailyROI;
        emit dailyROIUpdated(dailyROI);
    }

    // sets the registration tax
    function setRegistrationTax(uint256 _registrationTax) external onlyOwner {
        require(_registrationTax <= 10000000, "GnomeStaking: Registration tax cannot be more than 1% of supply");
        registrationTax = _registrationTax.mul(10**9);
        emit registrationTaxUpdated(registrationTax);
    }

    // sets the minimum stake value
    function setMinimumStakeValue(uint256 _minimumStakeValue)
        external
        onlyOwner
    {
        require(_minimumStakeValue <= 1000000, "GnomeStaking: Minimum stake cannot be more than 0.1% of supply");
        minimumStakeValue = _minimumStakeValue.mul(10**9);
        emit minimumStakeUpdated(minimumStakeValue);
    }

    // sets the base pool share
    function setBasePoolShareValue(uint256 _basePoolShareValue)
        external
        onlyOwner
    {
        require(_basePoolShareValue < 1000, "GnomeStaking: Base Pool Share must be less than 100%");
        require(_basePoolShareValue >= 500, "GnomeStaking: Base Pool Share must more than or equal to 50%");
        basePoolShare = _basePoolShareValue;
        emit basePoolShareUpdated(basePoolShare);
    }

    // updates the frequency that rewards accrue
    function setUnitTime(uint256 _unitTime) external onlyOwner {
        //5 minutes minimum
        require(_unitTime >= 300, "GnomeStaking: Unit time cannot be less than 5 minutes.");
        require(_unitTime <= 604800, "GnomeStaking: Unit time cannot be greater than 1 week.");
        UNIT_TIME = _unitTime;
        emit TimetoRewardsUpdated(UNIT_TIME);
    }

    // updates the maximum referrals users can make
    function setMaxReferrals(uint256 _maxReferrals) external onlyOwner {
        require(_maxReferrals >= 1, "GnomeStaking: Users must be able to referr.");
        require(_maxReferrals <= 50, "GnomeStaking: Users may not referr more than 50 people.");
        maxReferrals = _maxReferrals;
        emit MaxReferralsUpdated(maxReferrals);
    }

    // withdraws GNOME which has been taken in tax fees but does not take staked GNOME or BNB
    // send the tokens only to the GNOME contract
    function CollectTaxes(uint256 _amount)
        external
        onlyOwner
        returns (bool success)
    {
        //makes sure _amount is not more than required balance
        require(
            (IERC20(gnome).balanceOf(address(this))).sub(totalStaked) >=
                _amount,
            "GnomeStaking: Insufficient gnome balance"
        );
        //transfers _amount to _address
        IERC20(gnome).transfer(gnome, _amount);
        //emit event
        emit OnWithdrawal(gnome, _amount);
        return true;
    }
    // To be used in an emergency only!
    // Sends the users total staked amount (after tax) to them
    // Resets all the users info
    function EmergencyWithdraw() external onlyRegistered {
        require(stakes[msg.sender] > 0, "GnomeStaking: Nothing to withdraw!");
        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        referralCount[msg.sender] = 0;
        lastClock[msg.sender] = now;
        registered[msg.sender] = false;
        removeAddress(msg.sender);
        uint256 unstakingTax = (unstakingTaxRate.mul(stakes[msg.sender])).div(
            1000
        );
        uint256 afterTax = stakes[msg.sender].sub(unstakingTax);
        require(
            IERC20(gnome).balanceOf(address(this)) > afterTax,
            "GnomeStaking: Not enough GNOME to withdraw!"
        );
        stakes[msg.sender] = 0;
        totalStaked = totalStaked.sub(afterTax);
        IERC20(gnome).transfer(msg.sender, afterTax);
        emit EmergencyWithdrawal(afterTax);
    }
}