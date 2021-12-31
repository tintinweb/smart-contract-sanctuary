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
pragma solidity >=0.6.5;
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "./staking.sol";
import "./HouseBankroll.sol";
import "./LiveWallet.sol";
contract BitcrushBankroll is Ownable {
    
    using SafeMath for uint256;
    using SafeBEP20 for CRUSHToken;
    uint256 public totalBankroll;
    bool public poolDepleted;
    uint256 public negativeBankroll;
    //address of the crush token
    CRUSHToken public immutable crush;
    BitcrushStaking public immutable stakingPool;
    
    address public reserve;
    address public lottery;
    
    uint256 public constant DIVISOR = 10000;
    uint256 public constant BURN_RATE = 100;
    uint256 public profitThreshold ;
    
    //consistent 1% burn
    uint256 public profitShare;
    uint256 public houseBankrollShare;
    uint256 public lotteryShare;
    uint256 public reserveShare;
    
    //profit tracking
    uint256 public brSinceCompound;
    uint256 public negativeBrSinceCompound;

    //tracking historical winnings and profits
    uint256 public totalWinnings;
    uint256 public totalProfit;

    address admin;
    // MODIFIERS
    modifier adminOnly {
        require(  msg.sender == address(admin), 'Access restricted to admin only');
        _;
    }

    //authorized addresses
    mapping (address => bool) public authorizedAddresses;
    event SharesUpdated (uint256  _houseBankrollShare, uint256  _profitShare, uint256  _lotteryShare,  uint256  _reserveShare);
    constructor(
        CRUSHToken _crush,
        BitcrushStaking _stakingPool,
        address _reserve,
        address _lottery,
        uint256 _profitShare,
        uint256 _houseBankrollShare,
        uint256 _lotteryShare,
        uint256 _reserveShare,
        address _admin
    ) public {
        crush = _crush;
        stakingPool = _stakingPool;
        reserve = _reserve;
        lottery = _lottery;
        profitShare = _profitShare;
        houseBankrollShare = _houseBankrollShare;
        lotteryShare = _lotteryShare;
        reserveShare = _reserveShare;
        admin = _admin;
    }

    
    /// authorize address to register wins and losses
    /// @param _address the address to be authorized
    /// @dev updates the authorizedAddresses mapping to true for given address
    function authorizeAddress (address _address) public onlyOwner {
        authorizedAddresses[_address] = true;
    }

    /// remove authorization of an address from register wins and losses
    /// @param _address the address to be removed
    /// @dev updates the authorizedAddresses mapping by deleting entry for given address
    function removeAuthorization (address _address) public onlyOwner {
        delete authorizedAddresses[_address];
    }
    
    /// Add funds to the bankroll
    /// @param _amount the amount to add
    /// @dev adds funds to the bankroll
    function addToBankroll(uint256 _amount) public adminOnly {

        
        if (poolDepleted == true) {
            if (_amount >= negativeBankroll) {
                uint256 remainder = _amount.sub(negativeBankroll);
                crush.safeTransferFrom(
                    msg.sender,
                    address(stakingPool),
                    negativeBankroll
                );
                stakingPool.unfreezeStaking(negativeBankroll);
                negativeBankroll = 0;
                poolDepleted = false;
                crush.safeTransferFrom(msg.sender, address(this), remainder);
                totalBankroll = totalBankroll.add(remainder);
                
            } else {
                crush.safeTransferFrom(msg.sender, address(stakingPool), _amount);
                stakingPool.unfreezeStaking(_amount);
                negativeBankroll = negativeBankroll.sub(_amount);
            }
        } else {
            crush.safeTransferFrom(msg.sender, address(this), _amount);
            totalBankroll = totalBankroll.add(_amount);
            
        }




        
    }

    /// Add users loss to the bankroll
    /// @param _amount the amount to add
    /// @dev adds funds to the bankroll if bankroll is in positive, otherwise its transfered to the staking pool to recover frozen funds
    function addUserLoss(uint256 _amount) public {
        require(
            authorizedAddresses[msg.sender] == true,
            "Caller must be authorized"
        );
        //make game specific
        //check if bankroll is in negative
        //uint is unsigned, keep a bool to track
        //if negative send to staking to replenish
        //otherwise add to bankroll and check for profit
        if (poolDepleted == true) {
            if (_amount >= negativeBankroll) {
                uint256 remainder = _amount.sub(negativeBankroll);
                crush.safeTransferFrom(
                    msg.sender,
                    address(stakingPool),
                    negativeBankroll
                );
                stakingPool.unfreezeStaking(negativeBankroll);
                negativeBankroll = 0;
                poolDepleted = false;
                crush.safeTransferFrom(msg.sender, address(this), remainder);
                totalBankroll = totalBankroll.add(remainder);
                
            } else {
                crush.safeTransferFrom(msg.sender, address(stakingPool), _amount);
                stakingPool.unfreezeStaking(_amount);
                negativeBankroll = negativeBankroll.sub(_amount);
            }
        } else {
            crush.safeTransferFrom(msg.sender, address(this), _amount);
            totalBankroll = totalBankroll.add(_amount);
            
        }
        addToBrSinceCompound(_amount);
    }


    function recoverBankroll (uint256 _amount) public {
        require(
            msg.sender == address(stakingPool),
            "Caller must be staking pool"
        );
        if (_amount >= negativeBankroll) {
                uint256 remainder = _amount.sub(negativeBankroll);
                negativeBankroll = 0;
                poolDepleted = false;
                crush.safeTransferFrom(msg.sender, address(this), remainder);
                totalBankroll = totalBankroll.add(remainder);
                
            } else {
                
                negativeBankroll = negativeBankroll.sub(_amount);
            }
    }


    /// Deduct users win from the bankroll
    /// @param _amount the amount to deduct
    /// @dev deducts funds from the bankroll if bankroll is in positive, otherwise theyre pulled from staking pool and bankroll marked as negative
    function payOutUserWinning(
        uint256 _amount,
        address _winner
    ) public {
        require(
            authorizedAddresses[msg.sender] == true,
            "Caller must be authorized"
        );
        
        
        //check if bankroll has funds available
        //if not dip into staking pool for any remainder
        // update bankroll accordingly
        if (_amount > totalBankroll) {
            uint256 remainder = _amount.sub(totalBankroll);
            poolDepleted = true;
            stakingPool.freezeStaking(remainder, _winner, msg.sender);
            negativeBankroll = negativeBankroll.add(remainder);
            transferWinnings(totalBankroll, _winner, msg.sender);

            totalBankroll = 0;
        } else {
            totalBankroll = totalBankroll.sub(_amount);
            transferWinnings(_amount, _winner, msg.sender);
        }
        removeFromBrSinceCompound(_amount);
        totalWinnings = totalWinnings.add(_amount);
    }

    /// transfer winnings from bankroll contract to live wallet
    /// @param _amount the amount to tranfer
    /// @param _winner the winners address
    /// @dev transfers funds from the bankroll to the live wallet as users winnings
    function transferWinnings(
        uint256 _amount,
        address _winner,
        address _lwAddress
    ) internal {
        crush.safeTransfer(_lwAddress, _amount);
        BitcrushLiveWallet currentLw = BitcrushLiveWallet( _lwAddress);
        currentLw.addToUserWinnings(_amount, _winner);
    }

    /// track funds added since last compound and profit transfer
    /// @param _amount the amount to add
    /// @dev add funds to the variable brSinceCompound
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

    /// track funds remvoed since last compound and profit transfer
    /// @param _amount the amount to remove
    /// @dev deduct funds to the variable brSinceCompound
    function removeFromBrSinceCompound (uint256 _amount) internal{
        if(negativeBrSinceCompound > 0 ){
            negativeBrSinceCompound = negativeBrSinceCompound.add(_amount);
            
        }else {
            if(_amount > brSinceCompound){
                uint256 difference = _amount.sub(brSinceCompound);
                brSinceCompound = 0;
                negativeBrSinceCompound = negativeBrSinceCompound.add(difference);
            }else {
                brSinceCompound = brSinceCompound.sub(_amount);
            }
        }
    }

    /// transfer profits to staking pool to be ditributed to stakers.
    /// @dev transfer profits since last compound to the staking pool while taking out necessary fees.
    function transferProfit() public returns (uint256) {
        require(
            msg.sender == address(stakingPool),
            "Caller must be staking pool"
        );
        if (brSinceCompound >= profitThreshold) {

            //-----
            uint256 profit = 0;
            if(profitShare > 0 ){
                uint256 stakingBankrollProfit = brSinceCompound.mul(profitShare).div(DIVISOR);
                profit = profit.add(stakingBankrollProfit);
            }
            if(reserveShare > 0 ){
                uint256 reserveCrush = brSinceCompound.mul(reserveShare).div(DIVISOR);
                crush.safeTransfer(reserve, reserveCrush);
            }
            if(lotteryShare > 0){
                uint256 lotteryCrush = brSinceCompound.mul(lotteryShare).div(DIVISOR);
                crush.safeTransfer(lottery, lotteryCrush);
            }
            
            uint256 burn = brSinceCompound.mul(BURN_RATE).div(DIVISOR);
            crush.burn(burn); 

            if(houseBankrollShare > 0){
                uint256 bankrollShare = brSinceCompound.mul(houseBankrollShare).div(DIVISOR);
                brSinceCompound = brSinceCompound.sub(bankrollShare);
            }

            totalBankroll = totalBankroll.sub(brSinceCompound);
            //-----
            crush.safeTransfer(address(stakingPool), profit);
            totalProfit= totalProfit.add(profit);
            brSinceCompound = 0;
            return profit;
        } else {
            return 0;
        }
    }

    /// Store `_threshold`.
    /// @param _threshold the new value to store
    /// @dev stores the _threshold address in the state variable `profitThreshold`
    function setProfitThreshold(uint256 _threshold) public adminOnly {
        require(_threshold < 100000000000000000000000, "Max profit threshold cant be greater than 100k Crush");
        profitThreshold = _threshold;
    }

    /// updates all share percentage values
    /// @param _houseBankrollShare the new value to store
    /// @param _profitShare the new value to store
    /// @param _lotteryShare the new value to store
    /// @param _reserveShare the new value to store
    /// @dev stores the _houseBankrollShare address in the state variable `houseBankrollShare`
    function setShares (uint256 _houseBankrollShare, uint256 _profitShare, uint256 _lotteryShare,  uint256 _reserveShare) public onlyOwner {
        require(
            _houseBankrollShare
            .add(_profitShare)
            .add(_lotteryShare)
            .add(_reserveShare)
            .add(BURN_RATE) == DIVISOR,
            "Sum of all shares should add up to 100%"
            );
        houseBankrollShare = _houseBankrollShare;   
        profitShare = _profitShare;
        lotteryShare = _lotteryShare;
        reserveShare = _reserveShare;
        emit SharesUpdated(_houseBankrollShare, _profitShare, _lotteryShare,  _reserveShare);
    }


    ///store new address in reserve address
    /// @param _reserve the new address to store
    /// @dev changes the address which recieves reserve fees
    function setReserveAddress (address _reserve ) public onlyOwner {
        reserve = _reserve;
    }
    

    ///store new address in lottery address
    /// @param _lottery the new address to store
    /// @dev changes the address which recieves lottery fees
    function setLotteryAddress (address _lottery) public onlyOwner {
        lottery = _lottery;
    }
    
    ///store new address in admin address
    /// @param _admin the new address to store
    /// @dev changes the address which is used by the adminOnly modifier
    function setAdmin (address _admin) public onlyOwner {
        admin = _admin;
    }
   

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.5;
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "./HouseBankroll.sol";
import "./staking.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
contract BitcrushLiveWallet is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for CRUSHToken;
    struct wallet {
        //rename to balance
        uint256 balance;
        uint256 lockTimeStamp;
    }
    
    
    mapping (address => bool) public blacklistedUsers;
    //mapping users address with bet amount
    mapping (address => wallet) public betAmounts;
    
    //address of the crush token
    CRUSHToken public immutable crush;
    BitcrushBankroll public immutable bankroll;
    BitcrushStaking public stakingPool;
    
    
    uint256 constant public DIVISOR = 10000;
    uint256 public lockPeriod = 10800;
    address public reserveAddress;
    uint256  public earlyWithdrawFee         = 50; // 50/10000 * 100 = 0.5% 
    
    event Withdraw (address indexed _address, uint256 indexed _amount);
    event Deposit (address indexed _address, uint256 indexed _amount);
    event DepositWin (address indexed _address, uint256 indexed _amount);
    event LockPeriodUpdated (uint256 indexed _lockPeriod);

    constructor (CRUSHToken _crush, BitcrushBankroll _bankroll, address _reserveAddress) public {
        crush = _crush;
        bankroll = _bankroll;
        reserveAddress = _reserveAddress;
    }

    /// add funds to the senders live wallet 
    /// @dev adds funds to the sender user's live wallets
    function addbet (uint256 _amount) public {
        require(_amount > 0, "Bet amount should be greater than 0");
        require(blacklistedUsers[msg.sender] == false, "User is black Listed");
        crush.safeTransferFrom(msg.sender, address(this), _amount);
        betAmounts[msg.sender].balance = betAmounts[msg.sender].balance.add(_amount);
        betAmounts[msg.sender].lockTimeStamp = block.timestamp;
        emit Deposit(msg.sender, _amount);
        
    }

    /// add funds to the provided users live wallet 
    /// @dev adds funds to the specified users live wallets
    function addbetWithAddress (uint256 _amount, address _user) public {
        require(_amount > 0, "Bet amount should be greater than 0");
        require(blacklistedUsers[_user] == false, "User is black Listed");
        crush.safeTransferFrom(msg.sender, address(this), _amount);
        betAmounts[_user].balance = betAmounts[_user].balance.add(_amount);
        betAmounts[_user].lockTimeStamp = block.timestamp;
        emit DepositWin(_user, _amount);
    }

    /// return the current balance of user in the live wallet
    /// @dev return current the balance of provided user addrss in the live wallet
    function balanceOf ( address _user) public view returns (uint256){
        return betAmounts[_user].balance;
    }

    /// register wins for users in game with amounts
    /// @dev register wins for users during gameplay. wins are reported in aggregated form from the game server.
    function registerWin (uint256[] memory _wins, address[] memory _users) public onlyOwner {
        require (_wins.length == _users.length, "Parameter lengths should be equal");
        for(uint256 i=0; i < _users.length; i++){
                bankroll.payOutUserWinning(_wins[i], _users[i]);
        }
    }
    
    /// register loss for users in game with amounts
    /// @dev register loss for users during gameplay. loss is reported in aggregated form from the game server.
    function registerLoss (uint256[] memory _bets, address[] memory _users) public onlyOwner {
        require (_bets.length == _users.length, "Parameter lengths should be equal");
        for(uint256 i=0; i < _users.length; i++){
            if(_bets[i] > 0){
            require(betAmounts[_users[i]].balance >= _bets[i], "Loss bet amount is greater than available balance");    
            transferToBankroll(_bets[i]);
            betAmounts[_users[i]].balance = betAmounts[_users[i]].balance.sub(_bets[i]);
            }
            
        }
    }

    /// transfer funds from live wallet to the bankroll on user loss
    /// @dev transfer funds to the bankroll contract when users lose in game
    function transferToBankroll (uint256 _amount) internal { 
        crush.approve(address(bankroll), _amount);
        bankroll.addUserLoss(_amount);       
    }

    /// withdraw funds from live wallet of the senders address
    /// @dev withdraw amount from users wallet if betlock isnt enabled
    function withdrawBet(uint256 _amount) public {
        require(betAmounts[msg.sender].balance >= _amount, "bet less than amount withdraw");
        require(betAmounts[msg.sender].lockTimeStamp == 0 || betAmounts[msg.sender].lockTimeStamp.add(lockPeriod) < block.timestamp, "Bet Amount locked, please try again later");
        betAmounts[msg.sender].balance = betAmounts[msg.sender].balance.sub(_amount);
        crush.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// owner only function to override timelock and withdraw funds on behalf of user
    /// @dev withdraw preapproved amount from users wallet sidestepping the timelock on withdrawals
    function withdrawBetForUser(uint256 _amount, address _user) public onlyOwner {
        require(betAmounts[_user].balance >= _amount, "bet less than amount withdraw");
        betAmounts[_user].balance = betAmounts[_user].balance.sub(_amount);
        emit Withdraw(_user, _amount);
        uint256 withdrawalFee = _amount.mul(earlyWithdrawFee).div(DIVISOR);
        _amount = _amount.sub(withdrawalFee);
        crush.safeTransfer(reserveAddress, withdrawalFee);
        crush.safeTransfer(_user, _amount);
        
        
    }

    /// add funds to the users live wallet on wins by either the bankroll or the staking pool
    /// @dev add funds to the users live wallet as winnings
    function addToUserWinnings (uint256 _amount, address _user) public {
        require(msg.sender == address(bankroll)  || msg.sender == address(stakingPool) ,"Caller must be bankroll or staking pool");
        betAmounts[_user].balance = betAmounts[_user].balance.add(_amount);

    }
    
    /// update the lockTimeStamp of provided users to current timestamp to prevent withdraws
    /// @dev update bet lock to prevent withdraws during gameplay
    function updateBetLock (address[] memory _users) public onlyOwner {
        for(uint256 i=0; i < _users.length; i++){
            betAmounts[_users[i]].lockTimeStamp = block.timestamp;
        }
        
    }
    /// update the lockTimeStamp of provided users to 0 to allow withdraws
    /// @dev update bet lock to allow withdraws after gameplay
    function releaseBetLock (address[] memory _users) public onlyOwner {
        for(uint256 i=0; i < _users.length; i++){
            betAmounts[_users[i]].lockTimeStamp = 0;
        }
    }

    /// blacklist specified address from adding more funds to the pool
    /// @dev prevent specified address from adding funds to the live wallet
    function blacklistUser (address _address) public onlyOwner {
        blacklistedUsers[_address] = true;
    }

    /// whitelist sender address from adding more funds to the pool
    /// @dev allow previously blacklisted sender address to add funds to the live wallet
    function whitelistUser (address _address) public onlyOwner {
        delete blacklistedUsers[_address];
    }

    /// blacklist sender address from adding more funds to the pool
    /// @dev prevent sender address from adding funds to the live wallet
    function blacklistSelf () public  {
        blacklistedUsers[msg.sender] = true;
    }


    /// Store `_lockPeriod`.
    /// @param _lockPeriod the new value to store
    /// @dev stores the _lockPeriod in the state variable `lockPeriod`
    function setLockPeriod (uint256 _lockPeriod) public onlyOwner {
        require(_lockPeriod <= 604800, "Lock period cannot be greater than 1 week");
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(lockPeriod);
    }

    /// Store `_reserveAddress`.
    /// @param _reserveAddress the new value to store
    /// @dev stores the _reserveAddress in the state variable `reserveAddress`
    function setReserveAddress (address _reserveAddress) public onlyOwner {
        reserveAddress = _reserveAddress;
    }

    /// Store `_earlyWithdrawFee`.
    /// @param _earlyWithdrawFee the new value to store
    /// @dev stores the _earlyWithdrawFee in the state variable `earlyWithdrawFee`
    function setEarlyWithdrawFee (uint256 _earlyWithdrawFee ) public onlyOwner {
        require(_earlyWithdrawFee < 4000, "Early withdraw fee must be less than 40%");
        earlyWithdrawFee = _earlyWithdrawFee;
    }

   

    /// Store `_stakingPool`.
    /// @param _stakingPool the new value to store
    /// @dev stores the _stakingPool address in the state variable `stakingPool`
    function setStakingPool (BitcrushStaking _stakingPool) public onlyOwner {
        require(stakingPool == BitcrushStaking(0x0), "staking pool address already set");
        stakingPool = _stakingPool;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.5;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./CrushCoin.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "./HouseBankroll.sol";
import "./LiveWallet.sol";
contract BitcrushStaking is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for CRUSHToken;
    uint256 public constant MAX_CRUSH_PER_BLOCK = 10000000000000000000;
    uint256 public constant MAX_FEE = 1000; // 1000/10000 * 100 = 10%
    uint256 public performanceFeeCompounder = 10; // 10/10000 * 100 = 0.1%
    uint256 public performanceFeeBurn       = 100; // 100/10000 * 100 = 1%
    uint256 public constant divisor = 10000;
    
    uint256  public earlyWithdrawFee         = 50; // 50/10000 * 100 = 0.5% 
    uint256  public frozenEarlyWithdrawFee   = 1500; // 1500/10000 * 100 = 15% 
    uint256  public performanceFeeReserve    = 190; // 190/10000 * 100 = 1.9%
    
    uint256  public frozenEarlyWithdrawFeeTime   = 10800;

    
    uint256 public blockPerSecond = 3;
    uint256 public earlyWithdrawFeeTime = 72 * 60 * 60 / blockPerSecond;
    uint256 public apyBoost = 2500; //2500/10000 * 100 = 25%
    uint256 public totalShares;

    // Contracts to Interact with
    CRUSHToken public immutable crush;
    BitcrushBankroll public bankroll;
    BitcrushLiveWallet public liveWallet;
    // Team address to maintain funds
    address public reserveAddress;
    
    struct UserStaking {
        uint256 shares;
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 lastBlockCompounded;
        uint256 lastBlockStaked;
        uint256 index;
        uint256 lastFrozenWithdraw;
        uint256 apyBaseline;
        uint256 profitBaseline;
    }
    mapping (address => UserStaking) public stakings;
    address[] public addressIndexes;

    uint256 public lastAutoCompoundBlock;

    uint256 public batchStartingIndex;
    uint256 public crushPerBlock = 5500000000000000000;
    // Pool Accumulated Reward Per Share (APY)
    uint256 public accRewardPerShare;
    uint256 public lastRewardBlock;
    // Profit Accumulated Reward Per Share
    uint256 public accProfitPerShare;
    // Tracking Totals
    uint256 public totalPool; // Reward for Staking
    uint256 public totalStaked;
    uint256 public totalClaimed; // Total Claimed as rewards
    uint256 public totalFrozen;
    uint256 public totalProfitsClaimed;
    uint256 public totalProfitDistributed; // Total Claimed as Profits
    
    uint256 public autoCompoundLimit = 10; // Max Batch Size

    uint256 public deploymentTimeStamp;

    event RewardPoolUpdated (uint256 indexed _totalPool);
    event StakeUpdated (address indexed recipeint, uint256 indexed _amount);
    
    constructor (CRUSHToken _crush, uint256 _crushPerBlock, address _reserveAddress) public{
        crush = _crush;
        if(_crushPerBlock <= MAX_CRUSH_PER_BLOCK){
            crushPerBlock = _crushPerBlock;
        }
        reserveAddress = _reserveAddress;
        deploymentTimeStamp = block.timestamp;
        lastRewardBlock = block.number;
    }
    /// Store `_bankroll`.
    /// @param _bankroll the new value to store
    /// @dev stores the _bankroll address in the state variable `bankroll`
    function setBankroll (BitcrushBankroll _bankroll) public onlyOwner{
        require(bankroll == BitcrushBankroll(0x0), "Bankroll address already set");
        bankroll = _bankroll;
    }

    /// Store `_liveWallet`.
    /// @param _liveWallet the new value to store
    /// @dev stores the _liveWallet address in the state variable `liveWallet`
    function setLiveWallet (BitcrushLiveWallet _liveWallet) public onlyOwner{
        require(liveWallet == BitcrushLiveWallet(0x0), "Live Wallet address already set");
        liveWallet = _liveWallet;
    }

    /// Adds the provided amount to the totalPool
    /// @param _amount the amount to add
    /// @dev adds the provided amount to `totalPool` state variable
    function addRewardToPool (uint256 _amount) public  {
        require(crush.balanceOf(msg.sender) >= _amount, "Insufficient Crush tokens for transfer");
        totalPool = totalPool.add(_amount);
        crush.safeTransferFrom(msg.sender, address(this), _amount);
        emit RewardPoolUpdated(totalPool);
    }

    /// @notice updates accRewardPerShare based on the last block calculated and totalShares
    /// @dev accRewardPerShare is accumulative, meaning it always holds the total historic 
    /// rewardPerShare making apyBaseline necessary to keep rewards fair
    function updateDistribution() public {
        if(block.number <= lastRewardBlock)
            return;
        if(totalStaked == 0){
            lastRewardBlock = block.number;
            return;
        }
        uint256 rewardPerBlock = crushPerBlock;
        if(totalFrozen > 0)
            rewardPerBlock = rewardPerBlock.add(crushPerBlock.mul(apyBoost).div(divisor));
        if(totalPool == 0)
            rewardPerBlock = 0;
        uint256 blocksSinceCalc = block.number.sub(lastRewardBlock);
        uint256 rewardCalc = blocksSinceCalc.mul(rewardPerBlock).mul(1e12).div(totalShares);
        accRewardPerShare = accRewardPerShare.add( rewardCalc );
        lastRewardBlock = block.number;
    }

    /// @notice updates accProfitPerShare based on current Profit available and totalShares
    /// @dev this allows for consistent profit reporting and no change on profits to distribute
    function updateProfits() public {
        if(totalShares == 0)
            return;
        uint256 requestedProfits = bankroll.transferProfit();
        if(requestedProfits == 0)
            return;
        totalProfitDistributed = totalProfitDistributed.add(requestedProfits);
        uint256 profitCalc = requestedProfits.mul(1e12).div(totalShares);
        accProfitPerShare = accProfitPerShare.add( profitCalc );
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
        
        
        updateDistribution();
        updateProfits();
        crush.safeTransferFrom(msg.sender, address(this), _amount);
        if(totalStaked == 0){
            lastAutoCompoundBlock = block.number;
        }
        UserStaking storage user = stakings[msg.sender];

        if(user.stakedAmount == 0) {
            user.lastBlockCompounded = block.number;
            addressIndexes.push(msg.sender);
            user.index = addressIndexes.length-1;
        }
        else {
            uint256 pending = user.shares.mul(accRewardPerShare).div(1e12).sub(user.apyBaseline);
            if( pending > totalPool)
                pending = totalPool;
            totalPool = totalPool.sub(pending);
            uint256 profitPending = user.shares.mul(accProfitPerShare).div(1e12).sub(user.profitBaseline);
            pending = pending.add(profitPending);
            if( pending > 0) {
                crush.safeTransfer(msg.sender, pending);
                user.claimedAmount = user.claimedAmount.add(pending);
                totalClaimed = totalClaimed.add(pending);
                totalProfitsClaimed = totalProfitsClaimed.add(profitPending);
            }
        }
        

        uint256 currentShares = 0;
        if (totalShares != 0)
            currentShares = _amount.mul(totalShares).div(totalStaked);
        else
            currentShares = _amount;

        totalStaked = totalStaked.add(_amount);
        totalShares = totalShares.add(currentShares);
        if( user.shares == 0){
            user.lastBlockCompounded = block.number;
        }
        user.shares = user.shares.add(currentShares);
        user.profitBaseline = accProfitPerShare.mul(user.shares).div(1e12);
        user.apyBaseline = accRewardPerShare.mul(user.shares).div(1e12);
        user.stakedAmount = user.stakedAmount.add(_amount);
        user.lastBlockStaked = block.number;
    }



    /// Leaves staking for a user by the specified amount and transfering staked amount and reward to users address
    /// @param _amount the amount to unstake
    /// @dev leaves staking and deducts total pool by the users reward. early withdrawal fee applied if withdraw is made before earlyWithdrawFeeTime
    function leaveStaking (uint256 _amount, bool _liveWallet) external  {
        
        updateDistribution();
        updateProfits();
        UserStaking storage user = stakings[msg.sender];
        uint256 reward = user.shares.mul(accRewardPerShare).div(1e12).sub(user.apyBaseline);
        uint256 profitShare = user.shares.mul(accProfitPerShare).div(1e12).sub(user.profitBaseline);
        if( reward > totalPool )
            reward = totalPool;
        totalPool = totalPool.sub(reward);
        reward = reward.add(profitShare);
        totalProfitsClaimed = totalProfitsClaimed.add(profitShare);
        user.lastBlockCompounded = block.number;
        
        uint256 availableStaked = user.stakedAmount;
        if(totalFrozen > 0){
            availableStaked = availableStaked.sub(totalFrozen.mul(user.stakedAmount).div(totalStaked));
            require(availableStaked >= _amount, "Frozen Funds: Can't withdraw more than Available funds");
        }else if(user.lastFrozenWithdraw > 0){
            user.lastFrozenWithdraw = 0;
        }
        require(availableStaked >= _amount, "Withdraw amount can not be greater than available staked amount");
        totalStaked = totalStaked.sub(_amount);
        
        uint256 shareReduction = _amount.mul( user.shares ).div( user.stakedAmount );
        user.stakedAmount = user.stakedAmount.sub(_amount);
        user.shares = user.shares.sub( shareReduction );
        totalShares = totalShares.sub( shareReduction );
        user.apyBaseline = user.shares.mul(accRewardPerShare).div(1e12);
        user.profitBaseline = user.shares.mul(accProfitPerShare).div(1e12);
        _amount = _amount.add(reward);
        if(totalFrozen > 0 ){
            if(user.lastFrozenWithdraw > 0 ) 
                require(block.timestamp > user.lastFrozenWithdraw.add(frozenEarlyWithdrawFeeTime),"Only One Withdraw allowed per 3 hours during freeze");
            
            uint256 withdrawalFee = _amount.mul(frozenEarlyWithdrawFee).div(divisor);
            user.lastFrozenWithdraw = block.timestamp;
            _amount = _amount.sub(withdrawalFee);
            
            if(withdrawalFee > totalFrozen){
                uint256 remainder = withdrawalFee.sub(totalFrozen);
                crush.approve(address(bankroll), remainder);
                totalFrozen = 0;
            }else
                totalFrozen = totalFrozen.sub(withdrawalFee);
            
            bankroll.recoverBankroll(withdrawalFee);
            
        }
        else if(block.number < user.lastBlockStaked.add(earlyWithdrawFeeTime)){
            //apply fee
            uint256 withdrawalFee = _amount.mul(earlyWithdrawFee).div(divisor);
            _amount = _amount.sub(withdrawalFee);
            crush.safeTransfer(reserveAddress, withdrawalFee);
        }
        
        if(_liveWallet == false)
            crush.safeTransfer(msg.sender, _amount);
        else  {
            crush.approve(address(liveWallet), _amount);
            liveWallet.addbetWithAddress(_amount, msg.sender);
        }
        user.claimedAmount = user.claimedAmount.add(reward);
        totalClaimed = totalClaimed.add(reward);
        //remove from batchig array
        if(user.stakedAmount == 0){
            if(user.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[user.index] = lastAddress;
                stakings[lastAddress].index = user.index;
            }
            addressIndexes.pop();
        }
        emit RewardPoolUpdated(totalPool);
    }

    /// Get pending rewards of a user for UI
    /// @param _address the address to calculate the reward for
    /// @dev calculates potential reward for the address provided based on crush per block
    function pendingReward (address _address) external view returns (uint256){
        UserStaking storage user = stakings[_address];
        uint256 rewardPerBlock = crushPerBlock;
        if(totalFrozen > 0)
            rewardPerBlock = rewardPerBlock.add(crushPerBlock.mul(apyBoost).div(divisor));
        if(totalPool == 0)
            rewardPerBlock = 0;
        uint256 localAccRewardPerShare = accRewardPerShare;
        if(block.number > lastRewardBlock && totalShares !=0){
            uint256 blocksSinceCalc = block.number.sub(lastRewardBlock);
            uint256 rewardCalc = blocksSinceCalc.mul(rewardPerBlock).mul(1e12).div(totalShares);
            localAccRewardPerShare = accRewardPerShare.add( rewardCalc );
        }
        return user.shares.mul(localAccRewardPerShare).div(1e12).sub(user.apyBaseline);
    }

    /// Get pending Profits to Claim
    /// @param _address the user's wallet address to calculate profits
    /// @return pending Profits to be claimed by this user
    function pendingProfits(address _address) public view returns(uint256) {
        UserStaking storage user = stakings[_address];
        return user.shares.mul(accProfitPerShare).div(1e12).sub(user.profitBaseline);
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

        uint256 batchStart = batchStartingIndex;
        if( batchStartingIndex >= addressIndexes.length )
            batchStart = 0;
        
        uint256 batchLimit = addressIndexes.length;
        if(addressIndexes.length <= autoCompoundLimit || batchStart.add(autoCompoundLimit) >= addressIndexes.length)
            batchLimit = addressIndexes.length;
        else
            batchLimit = batchStart.add(autoCompoundLimit);

        updateProfits();
        updateDistribution();
        for(uint256 i=batchStart; i < batchLimit; i++){
            UserStaking storage currentUser = stakings[addressIndexes[i]];
            uint256 stakerReward = currentUser.shares.mul(accRewardPerShare).div(1e12).sub(currentUser.apyBaseline);
            if(totalPool < totalPoolDeducted.add(stakerReward)){
                stakerReward = totalPool.sub(totalPoolDeducted);
            }
            currentUser.apyBaseline = currentUser.apyBaseline.add(stakerReward);
            if(stakerReward > 0)
                totalPoolDeducted = totalPoolDeducted.add(stakerReward);
            uint256 profitReward = currentUser.shares.mul(accProfitPerShare).div(1e12).sub(currentUser.profitBaseline);
            currentUser.profitBaseline = currentUser.profitBaseline.add(profitReward);
            stakerReward = stakerReward.add(profitReward);
            if(stakerReward > 0){
                totalProfitsClaimed = totalProfitsClaimed.add(profitReward);
                totalClaimed = totalClaimed.add(stakerReward);
                uint256 stakerBurn = stakerReward.mul(performanceFeeBurn).div(divisor);
                crushToBurn = crushToBurn.add(stakerBurn);
            
                uint256 cpAllReward = stakerReward.mul(performanceFeeCompounder).div(divisor);
                compounderReward = compounderReward.add(cpAllReward);
            
                uint256 feeReserve = stakerReward.mul(performanceFeeReserve).div(divisor);
                performanceFee = performanceFee.add(feeReserve);
                stakerReward = stakerReward.sub(stakerBurn);
                stakerReward = stakerReward.sub(cpAllReward);
                stakerReward = stakerReward.sub(feeReserve);
                currentUser.claimedAmount = currentUser.claimedAmount.add(stakerReward);
                currentUser.stakedAmount = currentUser.stakedAmount.add(stakerReward);
                
                totalStaked = totalStaked.add(stakerReward);
            }    
            currentUser.lastBlockCompounded = block.number;
        }
        batchStartingIndex = batchLimit;
        if(batchStartingIndex >= addressIndexes.length){
            batchStartingIndex = 0;
        }
        totalPool = totalPool.sub(totalPoolDeducted);
        lastAutoCompoundBlock = block.number;
        crush.burn(crushToBurn);
        crush.safeTransfer(msg.sender, compounderReward);
        crush.safeTransfer(reserveAddress, performanceFee);
        
    }

    /// freeze certain funds in the staking pool and transfer them to the live wallet address
    /// @dev adds the provided amount to the total frozen variablle
    function freezeStaking (uint256 _amount, address _recipient, address _lwAddress) public  {
        require(msg.sender == address(bankroll), "Callet must be bankroll");
        //divide amount over users
        //update user mapping to reflect frozen amount
         require(_amount <= totalStaked.sub(totalFrozen), "Freeze amount should be less than or equal to available funds");
         totalFrozen = totalFrozen.add(_amount);
         BitcrushLiveWallet currentLw = BitcrushLiveWallet(_lwAddress);
         currentLw.addToUserWinnings(_amount, _recipient);
         crush.safeTransfer(address(_lwAddress), _amount);
         updateDistribution();
         updateProfits();
    }
    
    /// unfreeze previously frozen funds from the staking pool
    /// @dev deducts the provided amount from the total frozen variablle
    function unfreezeStaking (uint256 _amount) public {
        require(msg.sender == address(bankroll), "Caller must be bankroll");
         require(_amount <= totalFrozen, "unfreeze amount cant be greater than currently frozen amount");
         totalFrozen = totalFrozen.sub(_amount);
         updateDistribution();
         updateProfits();
    }



    /// returns the total count of users in the staking pool.
    /// @dev returns the total stakers in the staking pool by reading length of addressIndexes array
    function indexesLength() external view returns(uint256 _addressesLength){
        _addressesLength = addressIndexes.length;
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
    /// Store `_limit`.
    /// @param _limit the new value to store
    /// @dev stores the limit in the state variable `autoCompoundLimit`
    function setAutoCompoundLimit (uint256 _limit) public onlyOwner {
        require(_limit > 0, "Limit can not be 0");
        require(_limit < 30, "Max autocompound limit cannot be greater 30");
        autoCompoundLimit = _limit;
    }


    /// emergency withdraw funds of users
    /// @dev transfer all available funds of users to users wallet
    function emergencyWithdraw () public {
        
        updateDistribution();
        
        UserStaking storage user = stakings[msg.sender];
        user.lastBlockCompounded = block.number;
        
        uint256 availableStaked = user.stakedAmount;
        if(totalFrozen > 0){
            availableStaked = availableStaked.sub(totalFrozen.mul(user.stakedAmount).div(totalStaked));
        }else if(user.lastFrozenWithdraw > 0){
            user.lastFrozenWithdraw = 0;
        }
        
        totalStaked = totalStaked.sub(availableStaked);
        
        uint256 shareReduction = availableStaked.mul( user.shares ).div( user.stakedAmount );
        user.stakedAmount = user.stakedAmount.sub(availableStaked);
        user.shares = user.shares.sub( shareReduction );
        totalShares = totalShares.sub( shareReduction );
        user.apyBaseline = user.shares.mul(accRewardPerShare).div(1e12);
        user.profitBaseline = user.shares.mul(accProfitPerShare).div(1e12);
        
        if(totalFrozen > 0 ){
            if(user.lastFrozenWithdraw > 0 ) 
                require(block.timestamp > user.lastFrozenWithdraw.add(frozenEarlyWithdrawFeeTime),"Only One Withdraw allowed per 3 hours during freeze");
            
            uint256 withdrawalFee = availableStaked.mul(frozenEarlyWithdrawFee).div(divisor);
            user.lastFrozenWithdraw = block.timestamp;
            availableStaked = availableStaked.sub(withdrawalFee);
            
            if(withdrawalFee > totalFrozen){
                uint256 remainder = withdrawalFee.sub(totalFrozen);
                crush.approve(address(bankroll), remainder);
                totalFrozen = 0;
            }else
                totalFrozen = totalFrozen.sub(withdrawalFee);
            
            crush.safeTransfer(reserveAddress, withdrawalFee);

            
        }
        else if(block.number < user.lastBlockStaked.add(earlyWithdrawFeeTime)){
            //apply fee
            uint256 withdrawalFee = availableStaked.mul(earlyWithdrawFee).div(divisor);
            availableStaked = availableStaked.sub(withdrawalFee);
            crush.safeTransfer(reserveAddress, withdrawalFee);
        }
        
        
        crush.safeTransfer(msg.sender, availableStaked);
        
        
        //remove from batchig array
        if(user.stakedAmount == 0){
            if(user.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[user.index] = lastAddress;
                stakings[lastAddress].index = user.index;
            }
            addressIndexes.pop();
        }
        emit RewardPoolUpdated(totalPool);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
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