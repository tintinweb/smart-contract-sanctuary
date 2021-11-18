//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor()  { 
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


interface IBUSDDistributor{
    function claimBUSDShare(address user ) external;
    function pendingBUSD() external view returns(uint256);
    function transferBUSDToUser(address recipient, uint256 amount) external;

    function getBUSDDrip() external  returns(uint256);

}

interface IPRVNFTInterface {


  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function diamondSupply (  ) external view returns ( uint256 );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function goldSupply (  ) external view returns ( uint256 );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenTypes ( uint256 ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function withdraw (  ) external;
  function flipSaleState (  ) external;
  function withdrawAllFunds (  ) external;
  function withdrawToken ( address _token ) external;
}



 import "./PRV2Referral.sol";

 contract PRVV2MasterChef is Ownable, IERC721Receiver,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IBUSDDistributor public BUSDDistributor;

    IPRVNFTInterface public _privacyNFT;


    uint256 public constant MAX_EMISSION_RATE = 80*10**18; //80 tokens perblock
    uint256 public constant SILVER_NFT_EXTRA = 100; //10%   
    uint256 public constant GOLD_NFT_EXTRA= 200; //20%
    uint256 public constant DIAMOND_NFT_EXTRA = 500;//50%

    uint256 public totalBUSDCollected = 0;

    uint256 public accDepositBUSDRewardPerShare = 0;


    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 stakedNFTId;      
        uint256 busdRewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PRVs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPrvPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPrvPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PRVs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PRVs distribution occurs.
        uint256 accPrvPerShare;   // Accumulated PRVs per share, times 1e18. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 totalTokensLocked; // totalTokensLocked in pool

        bool isNFTStakingEnabled;
    }


    mapping(address => uint256) public customDepositReferralComission;
    mapping(address => bool) public customDepositReferral;

    mapping(address => bool) public poolsList;
    address public operator;
    IBEP20 public prv2;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // PRV tokens created per block.
    uint256 public prvPerBlock;
    // Bonus muliplier for early prv makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PRV mining starts.
    uint256 public startBlock;

    // Prv referral contract address.
    PRV2Referral public prvReferral;
  
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event onBUSDDistributorUpdated(address previous,address updated);

    event onPRVNFTSet(address previousPRVNFT,address newPRVNFT);
    event onNFTReceived( address operator, address from, uint256 tokenId, bytes  data);
    event onNFTStaked(uint256 pid,uint256 nftID);
    event onNFTUnstaked(uint256 pid,uint256 nftID);



    event onPoolAdded(uint256 _allocPoint, IBEP20 _lpToken, bool isNFTStakingEnabled, uint16 _depositFeeBP,  bool _withUpdate);
    event onPoolSet(uint256 _pid, uint256 _allocPoint,bool isNFTStakingEnabled, uint16 _depositFeeBP,  bool _withUpdate);
    event onBUSDRewardPaid(address user,uint256 amount);
    event onRewardPaid(address user,uint256 amount);


    event onChangeDevAddress(address previousAddress,address newAddress);
    event onChangeFeeAddress(address previousAddress,address newAddress);
    event onChangePRVReferralAddress(address previousAddress,address newAddress);
    event onChangeOperatorAddress(address previousAddress,address newAddress);
    event onEnableCustomDepositReferral(address addr,uint256 rate);

    
    constructor(
        IBEP20 _prv2,
        uint256 _startBlock,
        uint256 _prvPerBlock
    )  {
        prv2 = _prv2;
        startBlock = _startBlock;
        prvPerBlock = _prvPerBlock;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        operator = msg.sender;
        add( 1000, prv2,  true,  0,  false);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


  function setBUSDDistributor(address _BUSDDistributor) public onlyOwner{
        emit onBUSDDistributorUpdated(address(BUSDDistributor),_BUSDDistributor);
        //sanity check
        IBUSDDistributor(_BUSDDistributor).pendingBUSD();
        BUSDDistributor = IBUSDDistributor(_BUSDDistributor);
    }

  

    function setPRVNft(IPRVNFTInterface privacyNFT) public onlyOwner{
        emit onPRVNFTSet(address(_privacyNFT),address(privacyNFT));
        if(address(_privacyNFT) != address(0)){
            require(_privacyNFT.balanceOf(address(this)) == 0, "Staked in MC");
        }
        _privacyNFT = privacyNFT;
    }




    function stakeNFT(uint256 _pid,uint256 nftID) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0),"Invalid Pool");
        require(pool.isNFTStakingEnabled,"Can't Stake in this Pool");
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >0,"Can't Stake NFT without staking Token");
        require(user.stakedNFTId == 0,"NFT already staked");
        updatePool(_pid);
        payPendingReward(_pid);
        _privacyNFT.safeTransferFrom(msg.sender,address(this),nftID);
        user.stakedNFTId = nftID;
        user.rewardDebt = user.amount.mul(pool.accPrvPerShare).div(1e18);
        emit onNFTStaked(_pid,nftID);
    }



    function getExtraReward(address addr,uint256 _pid,uint256 normalReward) public view returns(uint256){
        if(normalReward >0){
            UserInfo storage user = userInfo[_pid][addr];
            if(user.stakedNFTId != 0){
                uint256 nftType = _privacyNFT.tokenTypes(user.stakedNFTId);
                if(nftType == 1){ //SILVER
                    return normalReward.mul(SILVER_NFT_EXTRA).div(1000);
                }else  if(nftType == 2){ //GOLD
                    return normalReward.mul(GOLD_NFT_EXTRA).div(1000);

                }else  if(nftType == 3){ //DIAMOND
                    return normalReward.mul(DIAMOND_NFT_EXTRA).div(1000);

                }
            }
        }
        
        return 0;
    }

   

function unstakeNFT(uint256 _pid) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.lpToken) != address(0),"Invalid Pool");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.stakedNFTId != 0,"No NFT Staked");
        updatePool(_pid);
        payPendingReward(_pid);
        uint256 nftId = user.stakedNFTId;
        user.stakedNFTId = 0;
        user.rewardDebt = user.amount.mul(pool.accPrvPerShare).div(1e18);
        _privacyNFT.safeTransferFrom(address(this),msg.sender,nftId);
        emit onNFTUnstaked(_pid,nftId);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool isNFTStakingEnabled, uint16 _depositFeeBP,  bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        require(poolsList[address(_lpToken)] == false,"Pool Already Added");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPrvPerShare: 0,
            isNFTStakingEnabled:isNFTStakingEnabled,
            totalTokensLocked:0,
            depositFeeBP: _depositFeeBP
        }));
        poolsList[address(_lpToken)] = true;
        emit onPoolAdded(_allocPoint,_lpToken,isNFTStakingEnabled,_depositFeeBP,_withUpdate);

    }

    // Update the given pool's PRV allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint,bool isNFTStakingEnabled, uint16 _depositFeeBP,  bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].isNFTStakingEnabled= isNFTStakingEnabled;
        emit onPoolSet(_pid,_allocPoint,isNFTStakingEnabled,_depositFeeBP,_withUpdate);

    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }


    function getBonusMultiplier(uint256 _pid,address _user) public view returns(uint256){

    }

    // View function to see pending PRVs on frontend.
    function pendingPrv2(uint256 _pid, address _user) external view returns (uint256,uint256,uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPrvPerShare = pool.accPrvPerShare;
        uint256 lpSupply = pool.totalTokensLocked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 prvReward = multiplier.mul(prvPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPrvPerShare = accPrvPerShare.add(prvReward.mul(1e18).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accPrvPerShare).div(1e18).sub(user.rewardDebt);
        
        uint256 extraReward = 0;
        if(pending>0){
            extraReward = getExtraReward(_user,_pid,pending);
        }
        // address addr,uint256 _pid,uint256 normalReward
        return (pending,extraReward,extraReward.add(pending));    }



 

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }



        uint256 lpSupply = pool.totalTokensLocked;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        if (_pid == 0 && poolInfo[_pid].totalTokensLocked > 0 && address(BUSDDistributor) != address(0)) {
            
            uint256 busdRelease = BUSDDistributor.getBUSDDrip();

            accDepositBUSDRewardPerShare = accDepositBUSDRewardPerShare.add( (busdRelease.mul(1e18)).div(poolInfo[0].totalTokensLocked));
            totalBUSDCollected = totalBUSDCollected.add(busdRelease);
       
        }


        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 prvReward = multiplier.mul(prvPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        if (prv2.totalSupply().add(prvReward)  <= prv2.MAX_SUPPLY()) {
                //  mint as normal as not at maxSupply
                prv2.mint(address(this), prvReward);
        } else {
            // mint the difference only to MC, update prvReward
            prvReward = prv2.MAX_SUPPLY().sub(prv2.totalSupply());
            prv2.mint(address(this), prvReward );
        }
        if (prvReward  != 0) {
                pool.accPrvPerShare =pool.accPrvPerShare.add(prvReward.mul(1e18).div(lpSupply)); 
        }
        pool.lastRewardBlock = block.number;  
    } 

    // Deposit LP tokens to MasterChef for PRV allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public  nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(prvReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            prvReferral.recordReferral(msg.sender, _referrer);
        }

        if (_pid == 0){
            payPendingBUSDReward();
        }
            

        payPendingReward(_pid);
        if (_amount > 0) {
            uint256 preAmount = pool.lpToken.balanceOf(address(this)); // deflationary check
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(preAmount);
            uint256 refComission =  payComissionOnDeposit(pool.lpToken,_amount,msg.sender);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                pool.totalTokensLocked = pool.totalTokensLocked.add(_amount).sub(depositFee).sub(refComission);

                user.amount = user.amount.add(_amount).sub(depositFee).sub(refComission);
            } else {
                pool.totalTokensLocked = pool.totalTokensLocked.add(_amount).sub(refComission);
                user.amount = user.amount.add(_amount).sub(refComission);
            }
        }

     
        user.rewardDebt = user.amount.mul(pool.accPrvPerShare).div(1e18);
        if (_pid == 0){
            user.busdRewardDebt = user.amount.mul(accDepositBUSDRewardPerShare).div(1e18);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

      // View function to see pending BUSDs on frontend.
    function pendingBUSD(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[0][_user];

        return user.amount.mul(accDepositBUSDRewardPerShare.div(1e18)).sub(user.busdRewardDebt);
    }

    // Withdraw LP tokens from .
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payPendingReward(_pid);
        if (_pid == 0){
             payPendingBUSDReward();
        }
           
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalTokensLocked = pool.totalTokensLocked.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);

        }
         if (_pid == 0){
            user.busdRewardDebt = (user.amount.mul(accDepositBUSDRewardPerShare)).div(1e18);
         }

        user.rewardDebt = user.amount.mul(pool.accPrvPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public  nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.busdRewardDebt = 0;

        pool.totalTokensLocked = pool.totalTokensLocked.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }


   function payPendingBUSDReward() internal {
        UserInfo storage user = userInfo[0][msg.sender];

        uint256 busdPending = (user.amount.mul(accDepositBUSDRewardPerShare).div(1e18)).sub(user.busdRewardDebt);

        if (busdPending > 0 && address(BUSDDistributor) != address(0)) {
            // send rewards
            BUSDDistributor.transferBUSDToUser(msg.sender, busdPending);
            emit onBUSDRewardPaid(msg.sender,busdPending);
        }

    }
    function payPendingReward(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

       uint256 pending = user.amount.mul(pool.accPrvPerShare).div(1e18).sub(user.rewardDebt);
       if (pending > 0 ) {
            uint256 totalRewards = pending;
            if(pool.isNFTStakingEnabled){
                uint256 extraReward = getExtraReward(msg.sender,_pid,totalRewards);
                prv2.mint(address(this),extraReward);
                totalRewards = totalRewards.add(extraReward);
            }


            // send rewards
            uint256 commissions =  prvReferral.payReferralComission(msg.sender, totalRewards,true);
            safePrvTransfer(msg.sender, totalRewards.sub(commissions));
            safePrvTransfer(address(prvReferral), commissions);
            emit onRewardPaid(msg.sender,totalRewards.sub(commissions));

        }
    }

    // Safe prv transfer function, just in case if rounding error causes pool to not have enough PRVs.
    function safePrvTransfer(address _to, uint256 _amount) internal {
        uint256 prvBal = prv2.balanceOf(address(this));
        if (_amount > prvBal) {
            prv2.transfer(_to, prvBal);
        } else {
            prv2.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        emit onChangeDevAddress(devAddress,_devAddress);
        devAddress = _devAddress;

    }


    function onERC721Received(address _operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        emit onNFTReceived( _operator,  from,  tokenId,  data);
        return 0x150b7a02;
    }
       
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        emit onChangeFeeAddress(feeAddress,_feeAddress);
        feeAddress = _feeAddress;
    }

   
    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _newprvPerBlock) public onlyOwner {
        require(_newprvPerBlock <= MAX_EMISSION_RATE,"Too high");
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, prvPerBlock, _newprvPerBlock);
        prvPerBlock = _newprvPerBlock;
    }

   
    // Update the prv referral contract address by the owner
    function setPrvReferral(PRV2Referral _prvReferral) public onlyOwner {
        emit onChangePRVReferralAddress(address(prvReferral),address(_prvReferral));
        // sanity test
        _prvReferral.getReferrer(address(this));
        prvReferral = _prvReferral;
    }


    
    function changeOperator(address addr) public {
        require(msg.sender == operator ,"Not Authotized");
        emit onChangeOperatorAddress(operator,addr);
        operator = addr;
    }
  




    function enableCustomDepositReferral(address addr,uint256 rate) public{
        require(msg.sender == operator,"Not Authorized");
        require(rate<=1500,"Invalid Comission");
        emit onEnableCustomDepositReferral(addr,rate);
        customDepositReferral[addr] = true;
        customDepositReferralComission[addr] = rate;
    }






    function payComissionOnDeposit(IBEP20 token,uint256 amount,address user) internal returns(uint256){
        address refererer = prvReferral.getReferrer(user);
        uint256 commissionAmount = 0;
        if(refererer != address(0) && customDepositReferral[refererer] == true && customDepositReferralComission[refererer] >0){
            commissionAmount = amount.mul(customDepositReferralComission[refererer]).div(10000);
            token.safeTransfer(refererer,commissionAmount);
        }

        return commissionAmount;
    }








    
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



interface IPRV2Referral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}



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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}




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
            "SafeBEP20: approve from non-zero to non-zero allowance"
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
            "SafeBEP20: decreased allowance below zero"
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

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}



interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    

    function MAX_SUPPLY() external view returns (uint256);

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

    function mint( address user, uint256 amount ) external;

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






contract PRV2Referral is IPRV2Referral, Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralPRV2Commissions;
    mapping(address => uint256) public totalReferralPRVGCommissions; 


    IBEP20 immutable public prv2;
    IBEP20 immutable public prvg;

    uint256 public defaultReferralComission = 10; //1%

    uint256  public specialReferralTier1 =  80; //8%
    uint256  public specialReferralTier2 =  30; //3%
    uint256  public specialReferralTier3 =  10; //1%

    mapping(address => bool) public specialUsers;

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission,bool isPRV2);
    event OperatorUpdated(address indexed operator, bool indexed status);



    event onReferralComissionUpdated(uint256 _specialReferralTier1,
        uint256 _specialReferralTier2,
        uint256 _specialReferralTier3);

    event onDefaultReferralComissionUpdated(uint256 oldRate,
        uint256 newRate);



    event onManageSpecialUsers(address  operator, bool  isAdd);


    constructor(IBEP20 _prv2,IBEP20 _prvg) {
        prv2 = _prv2;
        prvg = _prvg;
    }


    function setDefaultReferralComission(uint256 newComission) public onlyOwner{
        require(newComission <=80,"Invalid Comission");
        emit onDefaultReferralComissionUpdated(defaultReferralComission,newComission);
        defaultReferralComission = newComission;

    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }


    function manageSpecialUsers(address addr, bool isAdd) public onlyOwner{
        specialUsers[addr] = isAdd;
        emit onManageSpecialUsers(addr,isAdd);
        
    }

    function setComissions(uint256 _specialReferralTier1,
    uint256 _specialReferralTier2,
    uint256 _specialReferralTier3) public onlyOwner{

        require(_specialReferralTier1 <=150,"Invalid Comission for tier1");
        require(_specialReferralTier2 <=50,"Invalid Comission for tier2");
        require(_specialReferralTier3 <=50,"Invalid Comission for tier3");

        specialReferralTier1 = _specialReferralTier1;
        specialReferralTier2= _specialReferralTier2;
        specialReferralTier3 = _specialReferralTier3;
        emit onReferralComissionUpdated(specialReferralTier1,specialReferralTier2,specialReferralTier3);
    }

    function recordReferral(address _user, address _referrer) external override onlyOperator {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] = referralsCount[_referrer].add(1);
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission,bool isPRV2) internal   {
        if(isPRV2){
            totalReferralPRV2Commissions[_referrer] = totalReferralPRV2Commissions[_referrer].add(_commission);
        }else{
            totalReferralPRVGCommissions[_referrer] = totalReferralPRVGCommissions[_referrer].add(_commission);
        }
        emit ReferralCommissionRecorded(_referrer, _commission,isPRV2);
       
    }


    function payReferralComission(address user,uint256 amount,bool isPRV2) external  onlyOperator returns(uint256){
        address firstLevelReferrer = referrers[user];
        address secondLevelReferrer = referrers[firstLevelReferrer];
        address thirdLevelReferrer = referrers[secondLevelReferrer];

        uint256 totalComission = 0;
        uint256 comission = 0;
        if(firstLevelReferrer != address(0)){
           
            if(specialUsers[firstLevelReferrer]){
                comission = amount.mul(specialReferralTier1).div(1000);
            }else{
                comission = amount.mul(defaultReferralComission).div(1000);
            }

            if(comission>0){
               
                if(isPRV2){
                    payRewards(prv2,firstLevelReferrer,comission);
                }else{
                    payRewards(prvg,firstLevelReferrer,comission);
                }
                recordReferralCommission(firstLevelReferrer,comission,isPRV2);

            }

            totalComission = totalComission.add(comission);
       
        }

        if(secondLevelReferrer != address(0)){
          
            if(specialUsers[secondLevelReferrer]){
                comission = amount.mul(specialReferralTier2).div(1000);
                if(comission>0){
                   
                    if(isPRV2){
                        payRewards(prv2,secondLevelReferrer,comission);
                    }else{
                        payRewards(prvg,secondLevelReferrer,comission);
                    }
                }
                totalComission = totalComission.add(comission);
                recordReferralCommission(secondLevelReferrer,comission,isPRV2);

            }

           

        }

        if(thirdLevelReferrer != address(0)){
             if(specialUsers[thirdLevelReferrer]){
                comission = amount.mul(specialReferralTier3).div(1000);
                if(comission>0){
                    if(isPRV2){
                        payRewards(prv2,thirdLevelReferrer,comission);
                    }else{
                        payRewards(prvg,thirdLevelReferrer,comission);
                    }
                }
                totalComission = totalComission.add(comission);
                recordReferralCommission(thirdLevelReferrer,comission,isPRV2);

            }
        }

        return totalComission;
    }




    function payRewards(IBEP20 token,address _user, uint256 amount) internal {
        uint256 bal  = token.balanceOf(address(this));
        if(bal > amount){
            token.safeTransfer(_user,amount);
        }else{
            token.safeTransfer(_user,bal);
            token.mint(_user,amount.sub(bal));
        }
    }


    // Get the referrer address that referred the user
    function getReferrer(address _user) external override view returns (address) {
        return referrers[_user];
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

   
}