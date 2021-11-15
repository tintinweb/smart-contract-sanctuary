//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

contract CRUSHToken is BEP20 ("Crush Coin", "CRUSH") {

  using SafeMath for uint256;
  // Constants
  uint256 constant public MAX_SUPPLY = 30 * 10 ** 24; //30 million tokens are the max Supply
  
  // Variables
  uint256 public tokensBurned = 0;

  constructor() public {}

  function mint(address _benefactor,uint256 _amount) public onlyOwner {
    uint256 draftSupply = _amount.add( totalSupply() );
    uint256 maxSupply = MAX_SUPPLY.sub( tokensBurned );
    require( draftSupply <= maxSupply, "can't mint more than max." );
    _mint(_benefactor, _amount);
  }

  function burn(uint256 _amount) public {
    tokensBurned = tokensBurned.add( _amount ) ;
    _burn( msg.sender, _amount );
  }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "./staking.sol";
import "./HouseBankroll.sol";
import "./LiveWallet.sol";
contract BitcrushBankroll is Ownable {
    
    using SafeMath for uint256;

    uint256 public totalBankroll;
    bool public poolDepleted = false;
    uint256 public negativeBankroll;
    //address of the crush token
    CRUSHToken public crush;
    BitcrushStaking public stakingPool;
    BitcrushLiveWallet public liveWallet;
    address public reserve;
    address public lottery;
    
    uint256 public constant DIVISOR = 10000;
    uint256 public constant BURN_RATE = 100;
    uint256 public profitThreshold = 0;
    
    //consistent 1% burn
    uint256 public profitShare;
    uint256 public houseBankrollShare;
    uint256 public lotteryShare;
    uint256 public reserveShare;
    
    //profit tracking
    uint256 public brSinceCompound;
    uint256 public negativeBrSinceCompound;

    //tracking historical winnings and profits
    uint256 public totalWinnings = 0;
    uint256 public totalProfit = 0;

    constructor(
        CRUSHToken _crush,
        BitcrushStaking _stakingPool,
        address _reserve,
        address _lottery,
        uint256 _profitShare,
        uint256 _houseBankrollShare,
        uint256 _lotteryShare,
        uint256 _reserveShare
    ) public {
        crush = _crush;
        stakingPool = _stakingPool;
        reserve = _reserve;
        lottery = _lottery;
        profitShare = _profitShare;
        houseBankrollShare = _houseBankrollShare;
        lotteryShare = _lotteryShare;
        reserveShare = _reserveShare;

    }

    function setLiveWallet(BitcrushLiveWallet _liveWallet) public {
        liveWallet = _liveWallet;
    }

    

    function addToBankroll(uint256 _amount) public onlyOwner {
        crush.transferFrom(msg.sender, address(this), _amount);
        totalBankroll = totalBankroll.add(_amount);
    }

    function addUserLoss(uint256 _amount) public {
        require(
            msg.sender == address(liveWallet),
            "Caller must be bitcrush live wallet"
        );
        //make game specific
        //check if bankroll is in negative
        //uint is unsigned, keep a bool to track
        //if negative send to staking to replenish
        //otherwise add to bankroll and check for profit
        if (poolDepleted == true) {
            if (_amount >= negativeBankroll) {
                uint256 remainder = _amount.sub(negativeBankroll);
                crush.transferFrom(
                    msg.sender,
                    address(stakingPool),
                    negativeBankroll
                );
                stakingPool.unfreezeStaking(negativeBankroll);
                negativeBankroll = 0;
                poolDepleted = false;
                crush.transferFrom(msg.sender, address(this), remainder);
                totalBankroll = totalBankroll.add(remainder);
                
            } else {
                crush.transferFrom(msg.sender, address(stakingPool), _amount);
                stakingPool.unfreezeStaking(_amount);
                negativeBankroll = negativeBankroll.sub(_amount);
            }
        } else {
            crush.transferFrom(msg.sender, address(this), _amount);
            totalBankroll = totalBankroll.add(_amount);
            
        }
        addToBrSinceCompound(_amount);
    }

    function payOutUserWinning(
        uint256 _amount,
        address _winner
    ) public {
        require(
            msg.sender == address(liveWallet),
            "Caller must be bitcrush live wallet"
        );
        
        
        //check if bankroll has funds available
        //if not dip into staking pool for any remainder
        // update bankroll accordingly
        if (_amount > totalBankroll) {
            uint256 remainder = _amount.sub(totalBankroll);
            poolDepleted = true;
            stakingPool.freezeStaking(remainder, _winner);
            negativeBankroll = negativeBankroll.add(remainder);
            transferWinnings(totalBankroll, _winner);

            totalBankroll = 0;
        } else {
            totalBankroll = totalBankroll.sub(_amount);
            transferWinnings(_amount, _winner);
        }
        removeFromBrSinceCompound(_amount);
        totalWinnings = totalWinnings.add(_amount);
    }

    function transferWinnings(
        uint256 _amount,
        address _winner
    ) internal {
        crush.transfer(address(liveWallet), _amount);
        liveWallet.addToUserWinnings(_amount, _winner);
    }


    function addToBrSinceCompound (uint256 _amount) internal{
        if(negativeBrSinceCompound > 0){
            if(_amount > negativeBrSinceCompound){
                uint256 difference = _amount.sub(negativeBrSinceCompound);
                negativeBrSinceCompound = 0;
                brSinceCompound = brSinceCompound.add(difference);
            }else {
                negativeBrSinceCompound = negativeBrSinceCompound.sub(_amount);
            }
        }else {
            brSinceCompound = brSinceCompound.add(_amount);
        }
    }
    function removeFromBrSinceCompound (uint256 _amount) internal{
        if(negativeBrSinceCompound > 0 ){
            negativeBrSinceCompound = negativeBrSinceCompound.add(_amount);
            
        }else {
            if(_amount > brSinceCompound){
                uint256 difference = _amount.sub(brSinceCompound);
                brSinceCompound = 0;
                negativeBrSinceCompound = negativeBrSinceCompound.add(difference);
            }else {
                negativeBrSinceCompound = negativeBrSinceCompound.add(_amount);
            }
        }
    }

    function transferProfit() public returns (uint256) {
        require(
            msg.sender == address(stakingPool),
            "Caller must be staking pool"
        );
        if (brSinceCompound >= profitThreshold) {

            //-----
            uint256 profit = 0;
            if(profitShare > 0 ){
                uint256 stakingBakrollProfit = brSinceCompound.mul(profitShare).div(DIVISOR);
                profit = profit.add(stakingBakrollProfit);
            }
            if(reserveShare > 0 ){
                uint256 reserveCrush = brSinceCompound.mul(reserveShare).div(DIVISOR);
                crush.transfer(reserve, reserveCrush);
            }
            if(lotteryShare > 0){
                uint256 lotteryCrush = brSinceCompound.mul(lotteryShare).div(DIVISOR);
                crush.transfer(lottery, lotteryCrush);
            }
            
            uint256 burn = brSinceCompound.mul(BURN_RATE).div(DIVISOR);
            crush.burn(burn); 

            if(houseBankrollShare > 0){
                uint256 bankrollShare = brSinceCompound.mul(houseBankrollShare).div(DIVISOR);
                brSinceCompound = brSinceCompound.sub(bankrollShare);
            }

            totalBankroll = totalBankroll.sub(brSinceCompound);
            //-----
            crush.transfer(address(stakingPool), profit);
            totalProfit= totalProfit.add(profit);
            brSinceCompound = 0;
            return profit;
        } else {
            return 0;
        }
    }

    function setProfitThreshold(uint256 _threshold) public onlyOwner {
        profitThreshold = _threshold;
    }

    function setHouseBankrollShare (uint256 _houseBankrollShare) public onlyOwner {
        houseBankrollShare = _houseBankrollShare;
    }

    function setProfitShare (uint256 _profitShare) public onlyOwner {
        profitShare = _profitShare;
    }

    function setLotteryShare (uint256 _lotteryShare) public onlyOwner {
        lotteryShare = _lotteryShare;
    }

    function setReserveShare (uint256 _reserveShare) public onlyOwner {
        reserveShare = _reserveShare;
    }

    function EmergencyWithdrawBankroll () public onlyOwner {
        crush.transfer(msg.sender, totalBankroll);
        totalBankroll = 0;
    }
    function setBitcrushStaking (BitcrushStaking _stakingPool)public onlyOwner{
        stakingPool = _stakingPool;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "./HouseBankroll.sol";
import "./staking.sol";

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
contract BitcrushLiveWallet is Ownable {
    using SafeMath for uint256;
    struct wallet {
        //rename to balance
        uint256 balance;
        uint256 lockTimeStamp;
    }
    
    struct blackList {
        bool blacklisted;
    }
    mapping (address => blackList) public blacklistedUsers;
    //mapping users address with bet amount
    mapping (address => wallet) public betAmounts;
    
    //address of the crush token
    CRUSHToken public crush;
    BitcrushBankroll public bankroll;
    BitcrushStaking public stakingPool;
    
    uint256 public lossBurn = 10;
    uint256 constant public DIVISOR = 10000;
    uint256 public lockPeriod = 10800;
    address public reserveAddress;
    uint256  public earlyWithdrawFee         = 50; // 50/10000 * 100 = 0.5% 
    
    event Withdraw (address indexed _address, uint256 indexed _amount);
    event Deposit (address indexed _address, uint256 indexed _amount);
    event LockPeriodUpdated (uint256 indexed _lockPeriod);

    constructor (CRUSHToken _crush, BitcrushBankroll _bankroll, address _reserveAddress) public{
        crush = _crush;
        bankroll = _bankroll;
        reserveAddress = _reserveAddress;
    }

    function addbet (uint256 _amount) public {
        
        require(_amount > 0, "Bet amount should be greater than 0");
        require(blacklistedUsers[msg.sender].blacklisted == false, "User is black Listed");
        crush.transferFrom(msg.sender, address(this), _amount);
        betAmounts[msg.sender].balance = betAmounts[msg.sender].balance.add(_amount);
        betAmounts[msg.sender].lockTimeStamp = block.timestamp;
        emit Deposit(msg.sender, _amount);
        
    }

    function addbetWithAddress (uint256 _amount, address _user) public {
        require(_amount > 0, "Bet amount should be greater than 0");
        require(blacklistedUsers[_user].blacklisted == false, "User is black Listed");
        crush.transferFrom(msg.sender, address(this), _amount);
        betAmounts[_user].balance = betAmounts[_user].balance.add(_amount);
        
    }

    function balanceOf ( address _user) public view returns (uint256){
        return betAmounts[_user].balance;
    }

    function registerWin (uint256[] memory _wins, address[] memory _users) public onlyOwner {
        require (_wins.length == _users.length, "Parameter lengths should be equal");
        for(uint256 i=0; i < _users.length; i++){
                bankroll.payOutUserWinning(_wins[i], _users[i]);
        }
    }
    
    function registerLoss (uint256[] memory _bets, address[] memory _users) public onlyOwner {
        require (_bets.length == _users.length, "Parameter lengths should be equal");
        for(uint256 i=0; i < _users.length; i++){
            if(_bets[i] > 0){
            transferToBankroll(_bets[i]);
            betAmounts[_users[i]].balance = betAmounts[_users[i]].balance.sub(_bets[i]);
            }
            
        }
    }

    function transferToBankroll (uint256 _amount) internal {
        //uint256 burnShare = _amount.mul(lossBurn).div(DIVISOR);
        //crush.burn(burnShare);
        //uint256 remainingAmount = _amount.sub(burnShare);
        crush.approve(address(bankroll), _amount);
        bankroll.addUserLoss(_amount);       
    }

    function withdrawBet(uint256 _amount) public {
        require(betAmounts[msg.sender].balance >= _amount, "bet less than amount withdraw");
        require(betAmounts[msg.sender].lockTimeStamp == 0 || betAmounts[msg.sender].lockTimeStamp.add(lockPeriod) < block.timestamp, "Bet Amount locked, please try again later");
        betAmounts[msg.sender].balance = betAmounts[msg.sender].balance.sub(_amount);
        crush.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawBetForUser(uint256 _amount, address _user) public onlyOwner {
        require(betAmounts[_user].balance >= _amount, "bet less than amount withdraw");
        betAmounts[_user].balance = betAmounts[_user].balance.sub(_amount);
        emit Withdraw(_user, _amount);
        uint256 withdrawalFee = _amount.mul(earlyWithdrawFee).div(DIVISOR);
        _amount = _amount.sub(withdrawalFee);
        crush.transfer(reserveAddress, withdrawalFee);
        crush.transfer(_user, _amount);
        
        
    }


    function addToUserWinnings (uint256 _amount, address _user) public {
        require(msg.sender == address(bankroll)  || msg.sender == address(stakingPool) ,"Caller must be bankroll");
        betAmounts[_user].balance = betAmounts[_user].balance.add(_amount);

    }
    function updateBetLock (address[] memory _users) public {
        for(uint256 i=0; i < _users.length; i++){
            betAmounts[_users[i]].lockTimeStamp = block.timestamp;
        }
        
    }

    function releaseBetLock (address[] memory _users) public {
        for(uint256 i=0; i < _users.length; i++){
            betAmounts[_users[i]].lockTimeStamp = 0;
        }
    }

    function blacklistUser (address _address) public onlyOwner {
        blacklistedUsers[_address].blacklisted = true;
    }

    function whitelistUser (address _address) public onlyOwner {
        delete blacklistedUsers[_address];
    }

    function blacklistSelf () public  {
        blacklistedUsers[msg.sender].blacklisted = true;
    }

    function setLossBurn(uint256 _lossBurn) public onlyOwner {
        require(_lossBurn > 0, "Loss burn cant be 0");
        lossBurn = _lossBurn;
    }
    function setLockPeriod (uint256 _lockPeriod) public onlyOwner {
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(lockPeriod);
    }

    function setReserveAddress (address _reserveAddress) public onlyOwner {
        reserveAddress = _reserveAddress;
    }

    function setEarlyWithdrawFee (uint256 _earlyWithdrawFee ) public onlyOwner {
        earlyWithdrawFee = _earlyWithdrawFee;
    }
    function setBitcrushBankroll (BitcrushBankroll _bankRoll) public onlyOwner {
        bankroll = _bankRoll;
    }
    function setStakingPool (BitcrushStaking _stakingPool) public onlyOwner {
        stakingPool = _stakingPool;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "./HouseBankroll.sol";
import "./LiveWallet.sol";
contract BitcrushStaking is Ownable {
    using SafeMath for uint256;
    
    uint256 constant MAX_CRUSH_PER_BLOCK = 10;
    uint256 constant MAX_FEE = 1000; // 1000/10000 * 100 = 10%
    uint256 public performanceFeeCompounder = 10; // 10/10000 * 100 = 0.1%
    uint256 public performanceFeeBurn       = 100; // 100/10000 * 100 = 1%
    uint256 constant divisor = 10000;
    
    uint256  public earlyWithdrawFee         = 50; // 50/10000 * 100 = 0.5% 
    uint256  public performanceFeeReserve    = 190; // 190/10000 * 100 = 1.9%
    
    uint256 public profitShare = 10;
    uint256 public blockPerSecond = 3;
    uint256 public earlyWithdrawFeeTime = 72 * 60 * 60 / blockPerSecond;
    
    //address of the crush token
    CRUSHToken public crush;
    BitcrushBankroll public bankroll;
    BitcrushLiveWallet public liveWallet;
    struct staked {
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 profit;
        uint256 lastBlockCompounded;
        uint256 lastBlockStaked;
        uint256 index;
    }
    mapping (address => staked) public stakings;
    address[] public addressIndexes;

    struct profit {
        uint256 total;
        uint256 remaining;
    }
    profit[] public profits;

    uint256 public totalPool;
    uint256 public lastAutoCompoundBlock;
    uint256 public batchStartingIndex = 0;
    
    uint256 public crushPerBlock = 5;
    address public reserveAddress;

    uint256 public totalStaked;
    
    uint256 public totalClaimed;
    uint256 public totalFrozen = 0;
    uint256 public totalProfitDistributed = 0;
    
    uint256 public autoCompoundLimit = 10;

    event RewardPoolUpdated (uint256 indexed _totalPool);
    
    event StakeUpdated (address indexed recipeint, uint256 indexed _amount);
    
    constructor (CRUSHToken _crush, uint256 _crushPerBlock, address _reserveAddress) public{
        crush = _crush;
        crushPerBlock = _crushPerBlock;
        reserveAddress = _reserveAddress;
        lastAutoCompoundBlock = 0;
        
    }

    function setBankroll (BitcrushBankroll _bankroll) public {
        bankroll = _bankroll;
    }
    function setLiveWallet (BitcrushLiveWallet _liveWallet) public{
        liveWallet = _liveWallet;
    }

    /// Adds the provided amount to the totalPool
    /// @param _amount the amount to add
    /// @dev adds the provided amount to `totalPool` state variable
    function addRewardToPool (uint256 _amount) public  {
        require(crush.balanceOf(msg.sender) >= _amount, "Insufficient Crush tokens for transfer");
        totalPool = totalPool.add(_amount);
        crush.transferFrom(msg.sender, address(this), _amount);
        emit RewardPoolUpdated(totalPool);
    }

    
    function setCrushPerBlock (uint256 _amount) public onlyOwner {
        require(_amount >= 0, "Crush per Block can not be negative" );
        require(_amount <= MAX_CRUSH_PER_BLOCK, "Crush Per Block can not be more than 10");
        crushPerBlock = _amount;
    }


    /// Stake the provided amount
    /// @param _amount the amount to stake
    /// @dev stakes the provided amount
    function enterStaking (uint256 _amount) public  {
        require(crush.balanceOf(msg.sender) >= _amount, "Insufficient Crush tokens for transfer");
        require(_amount > 0,"Invalid staking amount");
        require(totalPool > 0, "Reward Pool Exhausted");
        
        crush.transferFrom(msg.sender, address(this), _amount);
        if(totalStaked == 0){
            lastAutoCompoundBlock = block.number;
        }
        if(stakings[msg.sender].stakedAmount == 0){
            stakings[msg.sender].lastBlockCompounded = block.number;
            addressIndexes.push(msg.sender);
            stakings[msg.sender].index = addressIndexes.length-1;
        }
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.add(_amount);
        stakings[msg.sender].lastBlockStaked = block.number;
        totalStaked = totalStaked.add(_amount);
        crush.transfer(msg.sender, getReward(msg.sender));
        stakings[msg.sender].lastBlockCompounded = block.number;
        
       
    }



    /// Leaves staking for a user by the specified amount and transfering staked amount and reward to users address
    /// @param _amount the amount to unstake
    /// @dev leaves staking and deducts total pool by the users reward. early withdrawal fee applied if withdraw is made before earlyWithdrawFeeTime
    function leaveStaking (uint256 _amount, bool _liveWallet) public  {
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalPool = totalPool.sub(reward);
        uint256 availableStaked;
        if(totalFrozen > 0){
            availableStaked = stakings[msg.sender].stakedAmount.sub(totalFrozen.mul(stakings[msg.sender].stakedAmount).div(totalStaked));
        }else {
            availableStaked = stakings[msg.sender].stakedAmount;
        }
        require(availableStaked >= _amount, "Withdraw amount can not be greater than available staked amount");
        totalStaked = totalStaked.sub(_amount);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.sub(_amount);
        if(block.number < stakings[msg.sender].lastBlockStaked.add(earlyWithdrawFeeTime)){
            //apply fee
            uint256 withdrawalFee = _amount.mul(earlyWithdrawFee).div(divisor);
            _amount = _amount.sub(withdrawalFee);
            crush.transfer(reserveAddress, withdrawalFee);
        }
        _amount = _amount.add(reward);
        if(_liveWallet == false){
            crush.transfer(msg.sender, _amount);
        }else {
            crush.approve(address(liveWallet), _amount);
            liveWallet.addbetWithAddress(_amount, msg.sender);
        }
        
        //remove from array
        if(stakings[msg.sender].stakedAmount == 0){
            staked storage staking = stakings[msg.sender];
            if(staking.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[staking.index] = lastAddress;
                stakings[lastAddress].index = staking.index;
                crush.approve( address(this), 0);
            }
            addressIndexes.pop();
            delete stakings[msg.sender];
        }
        emit RewardPoolUpdated(totalPool);
    }


    function getReward(address _address) internal view returns (uint256) {
        if(block.number <=  stakings[_address].lastBlockCompounded){
            return 0;
        }else {
            if(totalPool == 0 || totalStaked ==0 ){
                return 0;
            }else {
                //if the staker reward is greater than total pool => set it to total pool
                uint256 blocks = block.number.sub(stakings[_address].lastBlockCompounded);
                uint256 totalReward = blocks.mul(crushPerBlock);
                uint256 stakerReward = totalReward.mul(stakings[_address].stakedAmount).div(totalStaked);
                if(stakerReward > totalPool){
                    stakerReward = totalPool;
                }
                return stakerReward;
            }
            
        }
    }

    /// Calculates total potential pending rewards
    /// @dev Calculates potential reward based on crush per block
    function totalPendingRewards () public view returns (uint256){
            if(block.number <= lastAutoCompoundBlock){
                return 0;
            }else if(lastAutoCompoundBlock == 0){
                return 0;
            }else if (totalPool == 0){
                return 0;
            }

            uint256 blocks = block.number.sub(lastAutoCompoundBlock);
            uint256 totalReward = blocks.mul(crushPerBlock);

            return totalReward;
    }

    /// Get pending rewards of a user
    /// @param _address the address to calculate the reward for
    /// @dev calculates potential reward for the address provided based on crush per block
    function pendingReward (address _address) public view returns (uint256){
        return getReward(_address);
    }

    /// transfers the rewards of a user to their address
    /// @dev calculates users rewards and transfers it out while deducting reward from totalPool
    function claim (bool _liveWallet) public  {
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].claimedAmount = stakings[msg.sender].claimedAmount.add(reward);
        if(_liveWallet == false){
            crush.transfer(msg.sender, reward);
        }else {
            crush.approve(address(liveWallet), reward);
            liveWallet.addbetWithAddress(reward, msg.sender);
        }
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalClaimed = totalClaimed.add(reward);
        totalPool = totalPool.sub(reward); 
    }




    function claimProfit () public {
        require(stakings[msg.sender].profit > 0, "No Profit to claim");
        crush.transfer(msg.sender, stakings[msg.sender].profit);
        stakings[msg.sender].profit = 0;
    }

    /// compounds the rewards of the caller
    /// @dev compounds the rewards of the caller add adds it into their staked amount
    function singleCompound () public  {
        require(stakings[msg.sender].stakedAmount > 0, "Please Stake Crush to compound");
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.add(reward); 
        totalStaked = totalStaked.add(reward);
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalPool = totalPool.sub(reward);
        emit RewardPoolUpdated(totalPool);
        emit StakeUpdated(msg.sender,reward);
    }

  

    /// compounds the rewards of all users in the pool
    /// @dev compounds the rewards of all users in the pool add adds it into their staked amount while deducting fees
    function compoundAll () public  {
        require(lastAutoCompoundBlock <= block.number, "Compound All not yet applicable.");
        require(totalStaked > 0, "No Staked rewards to claim" );
        uint256 crushToBurn = 0;
        uint256 performanceFee = 0;
        
        uint256 compounderReward = 0;
        uint totalPoolDeducted = 0;
        
        uint256 batchLimit = addressIndexes.length;
        if(addressIndexes.length <= autoCompoundLimit || batchStartingIndex.add(autoCompoundLimit) >= addressIndexes.length){
            batchLimit = addressIndexes.length;
        }else {
            batchLimit = batchStartingIndex.add(autoCompoundLimit);
        }
        uint256 newProfit = bankroll.transferProfit();
            if(newProfit > 0){
                //profit deduction
                profit memory prof = profit(newProfit,newProfit);
                profits.push(prof);
                totalProfitDistributed = totalProfitDistributed.add(newProfit);
            }
        for(uint256 i=batchStartingIndex; i < batchLimit; i++){
            uint256 stakerReward = getReward(addressIndexes[i]);
            
            if(stakerReward > 0){
                totalClaimed = totalClaimed.add(stakerReward);
                totalPoolDeducted = totalPoolDeducted.add(stakerReward);
                if(profits.length > 0){
                    if(profits[0].remaining > 0){
                    uint256 profitShareUser = profits[0].total.mul(stakings[addressIndexes[i]].stakedAmount).div(totalStaked);
                    if(profitShareUser >= profits[0].remaining){
                    profitShareUser = profits[0].remaining;
                    }
                    profits[0].remaining = profits[0].remaining.sub(profitShareUser);
                    stakerReward = stakerReward.add(profitShareUser); 
                    }
                }
            
                uint256 stakerBurn = stakerReward.mul(performanceFeeBurn).div(divisor);
                crushToBurn = crushToBurn.add(stakerBurn);
            
                uint256 cpAllReward = stakerReward.mul(performanceFeeCompounder).div(divisor);
                compounderReward = compounderReward.add(cpAllReward);
            
                uint256 feeReserve = stakerReward.mul(performanceFeeReserve).div(divisor);
                performanceFee = performanceFee.add(feeReserve);

                stakerReward = stakerReward.sub(stakerBurn);
                stakerReward = stakerReward.sub(cpAllReward);
                stakerReward = stakerReward.sub(feeReserve);
            
                totalStaked = totalStaked.add(stakerReward);
                stakings[addressIndexes[i]].stakedAmount = stakings[addressIndexes[i]].stakedAmount.add(stakerReward);
                stakings[addressIndexes[i]].lastBlockCompounded = block.number;
            }
            
                        
        }
        if(batchStartingIndex.add(batchLimit) >= addressIndexes.length){
            if(profits.length > 0){
                if(profits[0].remaining == 0 && profits[0].total > 0){
                //rearrange array
                profits[0] = profits[profits.length - 1];
                profits.pop();
                }
            }
            
            batchStartingIndex = 0;
            
        }
        totalPool = totalPool.sub(totalPoolDeducted);
        lastAutoCompoundBlock = block.number;
        crush.burn(crushToBurn);
        crush.transfer(msg.sender, compounderReward);
        crush.transfer(reserveAddress, performanceFee);
        
    }


    function freezeStaking (uint256 _amount, address _recipient) public {
        //divide amount over users
        //update user mapping to reflect frozen amount
         require(_amount <= totalStaked.sub(totalFrozen), "Freeze amount should be less than or equal to available funds");
         totalFrozen = totalFrozen.add(_amount);
         liveWallet.addToUserWinnings(_amount, _recipient);
         crush.transfer(address(liveWallet), _amount);
    }

    function unfreezeStaking (uint256 _amount) public {
       //divide amount over users
        //update user mapping to reflect deducted frozen amount
         require(_amount <= totalFrozen, "unfreeze amount cant be greater than currently frozen amount");
         totalFrozen = totalFrozen.sub(_amount);
    }


    /// withdraws the staked amount of user in case of emergency.
    /// @dev drains the staked amount and sets the state variable `stakedAmount` of staking mapping to 0
    function emergencyWithdraw() public {
        //add check for frozen amount
        uint256 availableStaked;
        if(totalFrozen > 0){
            availableStaked = stakings[msg.sender].stakedAmount.sub(totalFrozen.mul(stakings[msg.sender].stakedAmount).div(totalStaked));
        }else {
            availableStaked = stakings[msg.sender].stakedAmount;
        }

        crush.transfer( msg.sender, availableStaked);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.sub(availableStaked);
        
        stakings[msg.sender].lastBlockCompounded = block.number;
        if(stakings[msg.sender].stakedAmount == 0) {
            staked storage staking = stakings[msg.sender];
            if(staking.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[staking.index] = lastAddress;
                stakings[lastAddress].index = staking.index;
            }
            addressIndexes.pop();
            crush.approve( address(this), 0);
        }
        
    }

    /// withdraws the total pool in case of emergency.
    /// @dev drains the total pool and sets the state variable `totalPool` to 0
    function emergencyTotalPoolWithdraw () public onlyOwner {
        require(totalPool > 0, "Total Pool need to be greater than 0");
        if(totalFrozen > 0){
            crush.transfer(msg.sender, totalPool.sub(totalFrozen));
            totalPool = totalPool.sub(totalFrozen);
        } else {
            crush.transfer(msg.sender, totalPool);
            totalPool = 0;
        }
        
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeCompounder`
    function setPerformanceFeeCompounder (uint256 _fee) public onlyOwner{
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        performanceFeeCompounder = _fee;
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeBurn`
    function setPerformanceFeeBurn (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        performanceFeeBurn = _fee;
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `earlyWithdrawFee`
    function setEarlyWithdrawFee (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        earlyWithdrawFee = _fee;
    }


    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeReserve`
    function setPerformanceFeeReserve (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee <= MAX_FEE, "Fee must be less than 10%");
        performanceFeeReserve = _fee;
    }

    /// Store `_time`.
    /// @param _time the new value to store
    /// @dev stores the time in the state variable `earlyWithdrawFeeTime`
    function setEarlyWithdrawFeeTime (uint256 _time) public onlyOwner {
        require(_time > 0, "Time must be greater than 0");
        earlyWithdrawFeeTime = _time;
    }

    function setAutoCompoundLimit (uint256 _limit) public onlyOwner {
        require(_limit > 0, "Limit can not be 0");
        autoCompoundLimit = _limit;
    }

    function setProfitShare (uint256 _profitShare) public onlyOwner {
        require(_profitShare > 0, "Profit share can not be 0");
        profitShare = _profitShare;
    }

   
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

