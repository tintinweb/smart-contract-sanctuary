// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import  "./iBGToken.sol";

// File: contracts/libs/SafeBEP20.sol
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

// File: contracts/MasterChef.sol
pragma experimental ABIEncoderV2;

pragma solidity ^0.6.12;

contract IBGBooster is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;


    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; 
        uint256 depositCheckpoint;
        ClaimInfo claimInfo;
    }

    struct ClaimInfo {
        uint256 stakedAmountTotal;
        uint256 pendingRewardTotal; 
        uint256 settledPendingReward;
        uint256 settledStakedAmount;
        uint256 lastClaimed;
        uint256 claims;
        bool wasPremeture;
        uint256 withdrawlTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. IBGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that IBGs distribution occurs.
        uint256 accIBGPerShare; // Accumulated IBGs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 lockPeriod;
    }

    // The IBG TOKEN!
    IBGToken public ibg;

    // IBG tokens created per block.
    uint256 public ibgPerBlock;
    // Bonus muliplier for early ibg makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    uint256 private MAX_FEE = 500; //5%

    bool public isDepositEnabled = true;

    mapping(address => ClaimInfo) private claimInfo;

    uint256 public ONE_DAY = 1 days;


    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when IBG mining starts.
    uint256 public startBlock;

    uint256 public prematurePaneltyPercent = 25;

    uint256 public withdrawalInstalments = 5;

    uint256 public minClaimTime = uint256(7).mul(ONE_DAY); // 7days

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event onPanalty(uint256 pid,uint256 panaltyAmount,address user);
    event onInstallmentPaid(uint256 pid,address user,uint256 rewardAmount,uint256 principalAmount,uint256 claimNumber);

    constructor(
        IBGToken _ibg,
        address _feeAddress,
        uint256 _ibgPerBlock,
        uint256 _startBlock
    ) public {
        ibg = _ibg;
        feeAddress = _feeAddress;
        ibgPerBlock = _ibgPerBlock;
        startBlock = _startBlock;
        add(6000,_ibg,0,uint256(120).mul(ONE_DAY),false);
        add(8000,_ibg,0,uint256(150).mul(ONE_DAY),false);
        add(10000,_ibg,0,uint256(180).mul(ONE_DAY),false);

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }



    function setDepositEnabled(bool isEnabled) public onlyOwner {
        isDepositEnabled = isEnabled;
    }

    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        uint256 lockPeriod,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= MAX_FEE, 'invalid fee');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accIBGPerShare: 0,
                depositFeeBP: _depositFeeBP,
                lockPeriod:lockPeriod
            })
        );
    }

    // Update the given pool's IBG allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _lockPeriod,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= MAX_FEE, 'invalid fee');
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].lockPeriod = _lockPeriod;

    
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending IBGs on frontend.
    function pendingIBG(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accIBGPerShare = pool.accIBGPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ibgReward = multiplier.mul(ibgPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accIBGPerShare = accIBGPerShare.add(ibgReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accIBGPerShare).div(1e12).sub(user.rewardDebt);
    }

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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ibgReward = multiplier.mul(ibgPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        mintIBG(address(this), ibgReward);

        pool.accIBGPerShare = pool.accIBGPerShare.add(ibgReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }






    // Deposit LP tokens to MasterChef for IBG allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
     
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accIBGPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeIBGTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            require(isDepositEnabled == true, "Deposits are not enabled");
            require(user.depositCheckpoint== 0, "multiple deposits are not allowed");
            uint256 preBal = pool.lpToken.balanceOf(address(this)); // safe deflationary tokens
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterBal  = pool.lpToken.balanceOf(address(this)); // safe deflationary tokens
            _amount = afterBal.sub(preBal);
            
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
            user.depositCheckpoint= block.timestamp;

        }
        user.rewardDebt = user.amount.mul(pool.accIBGPerShare).div(1e12);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.claimInfo.withdrawlTime == 0 , 'cant use this function use claim function');
        uint256 rewardAmount = 0;
        uint256 principalAmount = 0;
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accIBGPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            rewardAmount = pending;
        }
        principalAmount = user.amount;
        user.amount =0;
        user.rewardDebt = user.amount.mul(pool.accIBGPerShare).div(1e12);
        handleWithdrawal(_pid,rewardAmount,principalAmount,msg.sender);
    }


    function handleWithdrawal(uint256 _pid,uint256 rewardAmount ,uint256 principalAmount,address _user) internal{

        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        bool isPreMature = user.depositCheckpoint.add(pool.lockPeriod) > block.timestamp;
        if(isPreMature){
            uint256 panaltyAmount = rewardAmount.mul(prematurePaneltyPercent).div(100);
            if(panaltyAmount > 0){
                safeIBGTransfer(feeAddress, panaltyAmount);
                emit onPanalty(_pid,panaltyAmount,_user);
            }
            rewardAmount = rewardAmount.sub(panaltyAmount);
        }

    
        uint256 principalInstallment = principalAmount.div(5);
        uint256 rewardAmountInstallment = rewardAmount.div(5);


        uint256 paymentSum = principalInstallment.add(rewardAmountInstallment);

        if(paymentSum > 0){
            safeIBGTransfer(_user, paymentSum);
        }
       
        user.claimInfo = ClaimInfo({
                stakedAmountTotal: principalAmount,
                pendingRewardTotal: rewardAmount,
                settledPendingReward: rewardAmountInstallment,
                settledStakedAmount: principalInstallment,
                claims:1,
                lastClaimed: block.timestamp,
                wasPremeture:isPreMature,
                withdrawlTime:block.timestamp
            });
        emit onInstallmentPaid(_pid,_user,rewardAmountInstallment,principalInstallment,1);
    }


    function claimInstallment(uint256 _pid) public {
        ClaimInfo storage _claimInfo =  userInfo[_pid][msg.sender].claimInfo;
        require(_claimInfo.claims > 0," you are not eligible to claim use withdraw first");
        require(_claimInfo.claims <5,"You have claimed all of your installments");
        require(_claimInfo.lastClaimed.add(minClaimTime) <block.timestamp," Withdrawal intrval not passed yet ");

        uint256 principalInstallment = _claimInfo.stakedAmountTotal.div(5);
        uint256 rewardAmountInstallment = _claimInfo.pendingRewardTotal.div(5);


        uint256 paymentSum = principalInstallment.add(rewardAmountInstallment);

        if(paymentSum > 0){
            safeIBGTransfer(msg.sender, paymentSum);
        } 
        _claimInfo.settledPendingReward = _claimInfo.settledPendingReward.add(rewardAmountInstallment);
        _claimInfo.settledStakedAmount = _claimInfo.settledStakedAmount.add(principalInstallment);
        _claimInfo.claims =  _claimInfo.claims.add(1);
        _claimInfo.lastClaimed = block.timestamp;


        emit onInstallmentPaid(_pid,msg.sender,rewardAmountInstallment,principalInstallment,_claimInfo.claims);

    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe ibg transfer function, just in case if rounding error causes pool to not have enough IBGs.
    function safeIBGTransfer(address _to, uint256 _amount) internal {
        uint256 ibgBal = ibg.balanceOf(address(this));
        if (_amount > ibgBal) {
            ibg.transfer(_to, ibgBal);
        } else {
            ibg.transfer(_to, _amount);
        }

    }



    function mintIBG(address _to, uint256 _amount) internal {
        ibg.mint(_to, _amount);
    }


  

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, 'setFeeAddress: FORBIDDEN');
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ibgPerBlock) public onlyOwner {
        massUpdatePools();
        ibgPerBlock = _ibgPerBlock;
    }


    function emergencyDrain() public onlyOwner{
        uint256 bal = ibg.balanceOf(address(this));
        ibg.transfer(msg.sender, bal);
    }
}