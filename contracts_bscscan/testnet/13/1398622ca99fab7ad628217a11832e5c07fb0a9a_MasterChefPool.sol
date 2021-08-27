/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//import "@openzeppelin/contracts/access/Ownable.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
//import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//import "hardhat/console.sol";
//import "./interfaces/IBEP20.sol";
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
//import "./interfaces/IEgoToken.sol";
interface IEgoToken is IBEP20{
    
}
contract IMasterChef {
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCakePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PoolInfo[] public poolInfo;
    function enterStaking(uint256 _amount) virtual external{

    }
    function leaveStaking(uint256 _amount) virtual external{

    }
}
//import "./interfaces/IMasterChef.sol";

//import "./Vault.sol";
contract Vault {
    
    uint256 MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(address token){
        IBEP20(token).approve(msg.sender, MAX_INT);
    }
}
//import "./BasePool.sol";


//import "hardhat/console.sol";
//import "./interfaces/IPriceProvider.sol";
interface IPriceProvider {

    // return price with 18 decimals precision
    function getPriceBase()
        view
        external
        returns (uint256);

}
//import "./interfaces/IBEP20.sol";
//import "./interfaces/IEgoToken.sol";
//import "./Vault.sol";

abstract contract BasePool is Ownable {

    struct StakerInfo {
        BalanceInfo assetBalanceInfo;
        BalanceInfo egoBalanceInfoOriginal;
        BalanceInfo egoBalanceInfoShare;
        uint256 celebrityRewardPercent;
        bool stake;
    }

    struct CelebrityInfo {
        BalanceInfo assetBalanceInfo;
        BalanceInfo egoBalanceInfo;
    }

    struct BalanceInfo {
        uint256 amount;
        uint256 vBalance;
    }

    struct ClaimAmount {
        uint256 claimAmount;
        uint256 vClaimAmount;
    }

    event Stake(address sender, address celebrity);
    event UnStake(address sender, address celebrity);
    event Claim(address sender, address celebrity);
    event ClaimCelebrity(address celebrity);

    uint256 constant MAX_INT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant SECONDS_IN_YEAR = 365 days;

    uint256 PLATFORM_FEE = 200000;
    uint256 constant DEFAULT_BASE = 1000000;
    uint256 constant DEFAULT_OFFSET = 1005000;
    uint256 constant DROP_FACTOR = 1 * DEFAULT_BASE;
    uint256 public MAXapr = 3 * DEFAULT_BASE;

    address public _platformFeeAddress;
    IBEP20 internal _assetToken;
    IEgoToken private _egoToken;

    uint256 private _lastAPRChangeTime;
     // vEGO Rate
    uint256 public CurrentRate;
    uint256 public TotalStaked;
    Vault public RewardVault;
    uint256 public DecimalAdjustment;
    bool public Lock;
    // In pool assets
    uint256 public _totalVEGOInCirculation;
    IPriceProvider public AssetPriceProvider;
    //staker->celebrity->stake
    mapping(address => mapping(address => StakerInfo)) public StakersInfo;

    //celebrity->stake
    mapping(address => CelebrityInfo) public CelerbrityInfo;

    constructor(
        IBEP20 assetToken,
        IEgoToken egoToken,
        uint256 initialVEGORate,
        uint256 decimalAdjustment,
        address platformFeeAddress,
        IPriceProvider assetPriceProvider
    ) {
        _platformFeeAddress = platformFeeAddress;
        _assetToken = assetToken;
        _egoToken = egoToken;
        _lastAPRChangeTime = block.timestamp;
        AssetPriceProvider = assetPriceProvider;
        CurrentRate = initialVEGORate * DEFAULT_BASE;
        DecimalAdjustment = decimalAdjustment * DEFAULT_BASE;
    }

    // Sets helper Asset/EGO price provider contract
    function setAssetPriceProvider(IPriceProvider assetPriceProvider) external onlyOwner {
        AssetPriceProvider = assetPriceProvider;
    }
    
    // Sets decimal adjustment variable, e.g. 18 - <asset token decimals>
    function setDecimalAdjustment(uint256 decimalAdjustment) external onlyOwner {
        DecimalAdjustment = decimalAdjustment;
    }
    // Deploys reward vault. Can be called only once.
    function deployRewardVault() external {
        require(address(RewardVault) == address(0));
        RewardVault = new Vault(address(_egoToken));
    }
    // staker stakes funds for the celebrity
    // celebrityRewardPercent specifies percentage of the EGO rewards that should go to the celebrity.
    // celebrityRewardPercent can be set only for the initial stake of a Staker on the Celebrity. Consequent stakes will use the first submitted value.
    // this function transfers funds from Staker account to the contract for staking
    function stake(
        uint256 assetStakeAmount,
        uint256 celebrityRewardPercent,
        address celebrity
    ) external {
        require(!Lock, 'Locked');
        StakerInfo memory stakerInfo = StakersInfo[msg.sender][celebrity];
        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        require(celebrityRewardPercent<=DEFAULT_BASE, "stake: wrong percent");
        require(!stakerInfo.stake || stakerInfo.celebrityRewardPercent == celebrityRewardPercent,
            "stake: reward not equal to exist stakeInfo"
        );

        _updateRate();

        //----------------- transfers --------------- 
        //get tokens
       
        _stakeAsset(celebrity, assetStakeAmount, stakerInfo, celebrityInfo);
        uint256 egoAmount = assetStakeAmount * AssetPriceProvider.getPriceBase() * DecimalAdjustment / DEFAULT_BASE / 1e18;
        uint256 vEgoAdded = egoAmount / CurrentRate * DEFAULT_BASE;
        //ego
        stakerInfo.egoBalanceInfoOriginal.amount += egoAmount;
        stakerInfo.egoBalanceInfoOriginal.vBalance += vEgoAdded;

        stakerInfo.egoBalanceInfoShare.amount += egoAmount * (DEFAULT_BASE - celebrityRewardPercent) / DEFAULT_BASE; // Staker's share of EGO rewards
        stakerInfo.egoBalanceInfoShare.vBalance += egoAmount  * (DEFAULT_BASE - celebrityRewardPercent) / CurrentRate ;
        
        celebrityInfo.egoBalanceInfo.amount += egoAmount * celebrityRewardPercent / DEFAULT_BASE;
        celebrityInfo.egoBalanceInfo.vBalance += vEgoAdded * celebrityRewardPercent / DEFAULT_BASE;

        TotalStaked += assetStakeAmount;
        _totalVEGOInCirculation += vEgoAdded;
        //----------------- calc --------------- 


        //----------------- store --------------- 
        stakerInfo.stake = true;
        stakerInfo.celebrityRewardPercent = celebrityRewardPercent;

        StakersInfo[msg.sender][celebrity] = stakerInfo;
        CelerbrityInfo[celebrity] = celebrityInfo;
        //----------------- store --------------- 

        emit Stake(msg.sender, celebrity);
    }
    // Staker claims EGO reward
    function stakerClaim(address owner, address celebrity) public {
        
        _updateRate();

        ClaimAmount  memory claim = calculateStakerEgoClaimAmount(owner, celebrity);
        uint256 rewardBalance = _egoToken.balanceOf(address(RewardVault));
        if(rewardBalance < claim.claimAmount)
            claim.claimAmount = rewardBalance;

        if (claim.claimAmount > 0)
        {
            StakerInfo memory stakerInfo = StakersInfo[owner][celebrity];
            if( stakerInfo.egoBalanceInfoShare.vBalance > claim.vClaimAmount)
                stakerInfo.egoBalanceInfoShare.vBalance -= claim.vClaimAmount;
            else {
                stakerInfo.egoBalanceInfoShare.vBalance = 0;
                claim.vClaimAmount =  stakerInfo.egoBalanceInfoShare.vBalance;
            }

            if(claim.claimAmount  > 0)
            {
                    require(
                        _egoToken.transferFrom(
                            address(RewardVault),
                            owner,
                            claim.claimAmount
                        )
                    );
            }
            
            if(_totalVEGOInCirculation > claim.vClaimAmount)
                _totalVEGOInCirculation -= claim.vClaimAmount;
            else
                _totalVEGOInCirculation = 0;

            StakersInfo[owner][celebrity] = stakerInfo;
        }
        emit Claim(msg.sender, celebrity);
    }
    // Staker claims EGO and Asset reward
    // Asset is split between the Celebrity and Platform fee
    function celebrityClaim(address celebrity) public {
        
        _updateRate();

        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        
        _celebrityClaimAsset(celebrity, celebrityInfo);

        ClaimAmount memory egoClaim = calculateCelebrityEgoClaimAmount(celebrity);
        if (egoClaim.claimAmount > 0) {
            if(celebrityInfo.egoBalanceInfo.vBalance < egoClaim.vClaimAmount) { 
                egoClaim.vClaimAmount = celebrityInfo.egoBalanceInfo.vBalance;
            }
            celebrityInfo.egoBalanceInfo.vBalance = celebrityInfo.egoBalanceInfo.amount * DEFAULT_BASE /CurrentRate;
            if(egoClaim.claimAmount  > 0)
                require(
                    _egoToken.transferFrom(
                        address(RewardVault),
                        celebrity,
                        egoClaim.claimAmount
                    )
                );
            if(_totalVEGOInCirculation > egoClaim.vClaimAmount)
                _totalVEGOInCirculation -= egoClaim.vClaimAmount;
            else {
                _totalVEGOInCirculation = 0;
            }
        }

        CelerbrityInfo[celebrity] = celebrityInfo;

        emit ClaimCelebrity(celebrity);
    }

    // calculates amount of EGO available for the Celebrity to claim
    function calculateCelebrityEgoClaimAmount(address celebrity) view public returns (ClaimAmount memory result){
        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        return _calculateClaimAmount(celebrityInfo.egoBalanceInfo, CalculatePoolRate(), DEFAULT_BASE);
    }
    
    // calculates amount of EGO available for the Staker to claim
    function calculateStakerEgoClaimAmount(address owner, address celebrity) view public returns (ClaimAmount memory result) {
        StakerInfo memory stakerInfo = StakersInfo[owner][celebrity];
        return _calculateClaimAmount(stakerInfo.egoBalanceInfoShare, CalculatePoolRate(), DEFAULT_BASE);
    }

    // calculates amount available for the claim
    function _calculateClaimAmount(BalanceInfo memory currentBalanceInfo, uint256 currentRate,uint256 rateBase) pure public returns (ClaimAmount memory result){
        uint256 total = currentBalanceInfo.vBalance * currentRate / rateBase;
        if (total > currentBalanceInfo.amount)
        {
            result.claimAmount = total - currentBalanceInfo.amount;
            result.vClaimAmount = result.claimAmount * rateBase / currentRate ;
        }
    }

    // calculates amount of Asset available for the Celebrity to claim with Platform fee deducted
    function calculateCelebrityNetAssetReward(address celebrity) view public returns (ClaimAmount memory result){
        result = calculateCelebrityAssetClaimAmount(celebrity);
        result.claimAmount = result.claimAmount * (DEFAULT_BASE - PLATFORM_FEE) / DEFAULT_BASE;
        return result;
    }

    // calculates amount of Asset available for the Celebrity and Platform to claim (Platform fee NOT deducted))
    function calculateCelebrityAssetClaimAmount(address celebrity) view virtual public returns (ClaimAmount memory result){
        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        return _calculateClaimAmount(celebrityInfo.assetBalanceInfo, _getRate(), 1e18);
    }

    // Staker unstakes; fully or partially
    function unstake(address celebrity, uint256 assetStakeAmount) public {
        StakerInfo memory stakerInfo = StakersInfo[msg.sender][celebrity];
        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        require(stakerInfo.stake, "unstake: not staked");

        if(assetStakeAmount > stakerInfo.assetBalanceInfo.amount) {
            assetStakeAmount = stakerInfo.assetBalanceInfo.amount;
        }

        // update rate inside
        stakerClaim(msg.sender, celebrity);
        _unstakeAsset(celebrity, stakerInfo, celebrityInfo, assetStakeAmount);

        uint256 egoAmount = stakerInfo.egoBalanceInfoOriginal.amount;
        stakerInfo.egoBalanceInfoOriginal.amount = stakerInfo.assetBalanceInfo.amount * AssetPriceProvider.getPriceBase() * DecimalAdjustment / DEFAULT_BASE / 1e18;
        uint256 egoChange = egoAmount;
        if(egoAmount > stakerInfo.egoBalanceInfoOriginal.amount)
            egoChange = egoAmount - stakerInfo.egoBalanceInfoOriginal.amount;

        uint256 vChange = egoChange * DEFAULT_BASE / CurrentRate;
        if(vChange < stakerInfo.egoBalanceInfoOriginal.vBalance)
            stakerInfo.egoBalanceInfoOriginal.vBalance -= vChange;
        else 
            stakerInfo.egoBalanceInfoOriginal.vBalance  = 0;

        uint256 stakerEgoChange = egoChange * (DEFAULT_BASE - stakerInfo.celebrityRewardPercent) / DEFAULT_BASE;

        if(stakerInfo.egoBalanceInfoShare.amount > stakerEgoChange )
            stakerInfo.egoBalanceInfoShare.amount -= stakerEgoChange; // Staker's share of EGO rewards
        else {
            stakerInfo.egoBalanceInfoShare.amount = 0;
        }

        stakerInfo.egoBalanceInfoShare.vBalance = stakerInfo.egoBalanceInfoShare.amount * DEFAULT_BASE / CurrentRate ;
        uint256 celebrityChange = egoChange * stakerInfo.celebrityRewardPercent / DEFAULT_BASE;
        if(celebrityInfo.egoBalanceInfo.amount > celebrityChange)
            celebrityInfo.egoBalanceInfo.amount -= celebrityChange;
        else
            celebrityInfo.egoBalanceInfo.amount = 0;
        

        uint256 celebrityVChange =  vChange * stakerInfo.celebrityRewardPercent / DEFAULT_BASE;

        if(celebrityInfo.egoBalanceInfo.vBalance > celebrityVChange)
            celebrityInfo.egoBalanceInfo.vBalance -= celebrityVChange;
        else
            celebrityInfo.egoBalanceInfo.vBalance = 0;
        
        if(TotalStaked > assetStakeAmount)
            TotalStaked -= assetStakeAmount;
        else
            TotalStaked = 0;

        
        if(_totalVEGOInCirculation > vChange)
            _totalVEGOInCirculation -= vChange;
        else
            _totalVEGOInCirculation = 0;

        //-----------ego  calc---------------

        if( stakerInfo.assetBalanceInfo.amount == 0)
            stakerInfo.stake = false;
        StakersInfo[msg.sender][celebrity] = stakerInfo;
        CelerbrityInfo[celebrity] = celebrityInfo;
        
        emit UnStake(msg.sender, celebrity);
    }
    // Updates internal EGO/vEGO rate for the pool and sets update time
    function _updateRate() private {
        CurrentRate = CalculatePoolRate();
        _lastAPRChangeTime = block.timestamp;
    }

    // Calculates internal EGO/vEGO rate for the pool
    function CalculatePoolRate() public view returns (uint256) {
        uint256 currentApr = calculateAPR();
        uint256 rate =
        (CurrentRate * (DEFAULT_BASE + (currentApr * (block.timestamp - _lastAPRChangeTime)) / SECONDS_IN_YEAR)) / DEFAULT_BASE;

        return rate;
    }

    // Calculates APY, see formulas in the documentation
    // should return % in base
    function calculateAPR() public view returns (uint256) {
        if (TotalStaked == 0)
            return MAXapr;
        uint256 totalStakedEgo = TotalStaked * AssetPriceProvider.getPriceBase() * DecimalAdjustment / DEFAULT_BASE / 1e18;
        uint256 currentDebtInEGO = _totalVEGOInCirculation * CurrentRate / DEFAULT_BASE;
        uint256 netRewardBalanceEgo = 0;
        uint256 rewardBalance = _egoToken.balanceOf(address(RewardVault));

        if (currentDebtInEGO < (rewardBalance + totalStakedEgo))
            netRewardBalanceEgo = rewardBalance + totalStakedEgo - currentDebtInEGO;

        uint256 result = netRewardBalanceEgo * DROP_FACTOR / totalStakedEgo;
        if (result > MAXapr) return MAXapr;
        return result;
    }
    // Pool-specific asset staking functionality
    function _stakeAsset(address celebrity, uint256 assetStakeAmount, StakerInfo memory stakerInfo,   CelebrityInfo memory celebrityInfo) internal virtual;
    // Pool-specific celebrity claiming functionality
    function _celebrityClaimAsset(address celebrity, CelebrityInfo memory celebrityInfo)  internal virtual;
    // Pool-specific asset unstaking functionality
    function _unstakeAsset(address celebrity, StakerInfo memory stakerInfo, CelebrityInfo memory celebrityInfo, uint256 amount)  internal virtual;
    // Pool-specific asset v-token rate calculation functionality
    function _getRate() view internal virtual returns(uint256);
    // Used for contract decommissioning. Lock will prevent Stakers from adding more funds. Unstake  and claim should still work.
    function setLock(bool lock) external onlyOwner{
        Lock = lock;
    }
    // Emergency Unstake by the contract owner. Calling this methods will result in return of funds staked to staker.
    function emergencyUnstake(address celebrity, uint256 assetStakeAmount) external onlyOwner{
        unstake(celebrity, assetStakeAmount);
    }
    // Emergency Claim by the contract owner. Calling this methods will result in claimed profits and distribution to Stakers.
    function emergencyClaim(address celebrity) external onlyOwner{
        celebrityClaim(celebrity);
    }
    // Sets platform fee percentasge
    function setPlatformFee(uint256 fee) external onlyOwner{
        require(fee<=DEFAULT_BASE);
        PLATFORM_FEE = fee;
    }

    //sets max apr
    function setMAXapr(uint256 apr) external onlyOwner {
        MAXapr = apr;
    }

    // sets address to transfer platform fees to
    function setPlatformFeeAddress(address platformFeeAddress) external onlyOwner{
        _platformFeeAddress = platformFeeAddress;
    }
    // Withdraw funds from the Reward Vault
    function withrawalRewards(address to, uint256 amount) external onlyOwner{
        _egoToken.transferFrom(
                address(RewardVault),
                to,
                amount
            );
    }
}

contract MasterChefPool is BasePool {
    //pending rewards by celebrity (celebrity->cakes)
    mapping(address => uint) public pendingRewardCelebrity;

    IMasterChef private _masterChef;
    constructor( IBEP20 assetToken,
        IMasterChef masterChef,
        IEgoToken egoToken,
        uint256 initialVEGORate,
        address platformFeeAddress,
        IPriceProvider priceProvider) 
            BasePool(assetToken,
                egoToken,
                initialVEGORate,
                1,//different in dec numbers
                platformFeeAddress,
                priceProvider)
    {
        _masterChef = masterChef;
        assetToken.approve(address(masterChef), MAX_INT);
    }
    
    function _stakeAsset(address celebrity, uint256 assetStakeAmount, StakerInfo memory stakerInfo, CelebrityInfo memory celebrityInfo) internal virtual override{
        if(assetStakeAmount  > 0)
            require(_assetToken.transferFrom(msg.sender, address(this), assetStakeAmount));

        _masterChef.enterStaking(assetStakeAmount);

        (,,,uint256 accCakePerShare) = _masterChef.poolInfo(0);
        // On enterStaking/leaveStaking we get reward from master chef. We store this reward for the celebrity 
        // On MasterChef: uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        pendingRewardCelebrity[celebrity] += celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12 - celebrityInfo.assetBalanceInfo.vBalance;        

        // increase staked balance for celebrity
        celebrityInfo.assetBalanceInfo.amount += assetStakeAmount;
        
        // For this pool vBalance is rewardDebt from MasterChef
        // Recalculate rewardDebt for celebrity
        celebrityInfo.assetBalanceInfo.vBalance = celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12;

        // Update staker amount
        stakerInfo.assetBalanceInfo.amount += assetStakeAmount;
    }
    
    // This function also is used in the calculateCelebrityNetAssetReward of the parent contract
    function calculateCelebrityAssetClaimAmount(address celebrity) view override public returns (ClaimAmount memory result){
        CelebrityInfo memory celebrityInfo = CelerbrityInfo[celebrity];
        (,,,uint256 accCakePerShare) = _masterChef.poolInfo(0);

        // On MasterChef: reward = celebrityInfo.assetBalanceInfo.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt)        
        // Calculate reward from master chef
        result.claimAmount = celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12 - celebrityInfo.assetBalanceInfo.vBalance;
        
        // Add celebrity reward which we recieve on additional stake and partial unstake
        result.claimAmount += pendingRewardCelebrity[celebrity];
    }

    function _celebrityClaimAsset(address celebrity, CelebrityInfo memory celebrityInfo)  internal virtual override {
        ClaimAmount memory claimAmount = calculateCelebrityAssetClaimAmount(celebrity);
        if (claimAmount.claimAmount > 0)
        {
            //prepare balance for claim reward
            _prepareBalance(claimAmount.claimAmount);
            
            uint256 systemReward = claimAmount.claimAmount * PLATFORM_FEE / DEFAULT_BASE;
            if(systemReward > 0)
                require(_assetToken.transfer(_platformFeeAddress, systemReward));
            if(claimAmount.claimAmount > systemReward)
                require(_assetToken.transfer(celebrity, claimAmount.claimAmount - systemReward));
            
            (,,,uint256 accCakePerShare) = _masterChef.poolInfo(0);
            //user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
            //update celebrity debt
            celebrityInfo.assetBalanceInfo.vBalance =  celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12;
            
            //reset pending celebrity reward
            pendingRewardCelebrity[celebrity] = 0;
        }
    }

    // Unstake amount of cake if required for the payout to the celebrity
    function _prepareBalance(uint256 amount) private {
        uint256 balance = _assetToken.balanceOf(address(this));
        if(balance > amount) //cake was already transfered to our contract
            return;
        amount -= balance;
        (,,,uint256 accCakePerShare) = _masterChef.poolInfo(0);
        (uint256 totalAmount, uint256 rewardDebt) = _getMasterChefBalance();
       
        // Calculte pending reward from masterchef
        uint256 pending = totalAmount * accCakePerShare / 1e12 - rewardDebt;
        
        if(amount < pending)
            amount = 0; // If amount is less than peding reward then just take the reward
        else
            amount -= pending; // Withdraw just an amount required to pay reward to Celebrity
        _masterChef.leaveStaking(amount); 
    }

    function _unstakeAsset(address celebrity, StakerInfo memory stakerInfo, CelebrityInfo memory celebrityInfo, uint256 amount) internal virtual override {
        //-------------cake unstake--------------
        _prepareBalance(amount);
        (,,,uint256 accCakePerShare) = _masterChef.poolInfo(0);

        //return funds in asset to the staker
        if(amount > 0)
            require(_assetToken.transfer(msg.sender, amount));
        //-------------cake unstake--------------

        //-----------cake calc---------------
        stakerInfo.assetBalanceInfo.amount -= amount;
        
        //On MasterChef: rewardDebt  = user.amount.mul(pool.accCakePerShare).div(1e12);
        pendingRewardCelebrity[celebrity] += celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12 - celebrityInfo.assetBalanceInfo.vBalance; // vBalance is RewardDebt on the MasterChef contract

        celebrityInfo.assetBalanceInfo.amount -= amount;

        //update debt for celebrity
        celebrityInfo.assetBalanceInfo.vBalance = celebrityInfo.assetBalanceInfo.amount * accCakePerShare / 1e12;
        //-----------cake  calc---------------
    }
    

    function _getRate() view internal virtual override returns(uint256){
        require(false);
        return  1;
    }

    //get current contract balance and debt for masterchef
    function _getMasterChefBalance() view internal virtual returns(uint256 amount, uint256 rewardDebt){
        (amount, rewardDebt) = _masterChef.userInfo(0, address(this));
    }
}