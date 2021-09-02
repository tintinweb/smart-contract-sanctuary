// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './SafeMath.sol';
import './Address.sol';
import './IERC20.sol';
import './SafeERC20.sol';


contract ProfitSharingRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BLOCKS_PER_DAY = 28800;

    // governance
    address public operator;
    address public reserveFund;

    // flags
    bool public initialized = false;  // TODO: here lies the failure - shouldve been later set to True
    bool public publicAllowed = false;

    address public exchangeProxy;
    uint256 private _locked = 0;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        mapping(address => uint256) rewardDebt;
        mapping(address => uint256) reward;
        mapping(address => uint256) accumulatedEarned; // will accumulate every time user harvest
        mapping(address => uint256) lockReward;
        mapping(address => uint256) lockRewardReleased;
        uint256 lastStakeTime;
    }

    // Info of each rewardPool funding.
    struct RewardPoolInfo {
        address rewardToken; // Address of rewardPool token contract.
        uint256 lastRewardBlock; // Last block number that rewardPool distribution occurs.
        uint256 rewardPerBlock; // Reward token amount to distribute per block.
        uint256 accRewardPerShare; // Accumulated rewardPool per share, times 1e18.
        uint256 totalPaidRewards;
    }

    uint256 public startRewardBlock;
    uint256 public endRewardBlock;

    address public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public stakeToken;

    mapping(address => RewardPoolInfo) public rewardPoolInfo;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Initialized(address indexed executor, uint256 at);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address rewardToken, address indexed user, uint256 amount);
    event ResetUserInfo(address indexed user);

    /* ========== Modifiers =============== */

    modifier onlyOperator() {
        require(operator == msg.sender, "ProfitSharingRewardPool: caller is not the operator");
        _;
    }

    modifier onlyExchangeProxy() {
        require(exchangeProxy == msg.sender || operator == msg.sender, "ProfitSharingRewardPool: caller is not the exchangeProxy");
        _;
    }

    modifier onlyReserveFund() {
        require(reserveFund == msg.sender || operator == msg.sender, "ProfitSharingRewardPool: caller is not the reserveFund");
        _;
    }

    modifier lock() {
        require(_locked == 0, "ProfitSharingRewardPool: LOCKED");
        _locked = 1;
        _;
        _locked = 0;
    }

    modifier notInitialized() {
        require(!initialized, "ProfitSharingRewardPool: initialized");
        _;
    }

    modifier checkPublicAllow() {
        require(publicAllowed || msg.sender == operator, "!operator nor !publicAllowed");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _stakeToken,
        address _wbnb,
        address _busd,
        address _reserveFund,
        uint256 _startRewardBlock
    ) public notInitialized {
        require(block.number < _startRewardBlock, "late");

        stakeToken = _stakeToken;
        wbnb = _wbnb;
        busd = _busd;
        reserveFund = _reserveFund;
        startRewardBlock = _startRewardBlock;
        endRewardBlock = _startRewardBlock;

        operator = msg.sender;
        _locked = 0;

        setRewardPool(_wbnb, _startRewardBlock);
        setRewardPool(_busd, _startRewardBlock);

        // initialized = True;   ====>   TODO: this is the missing implementation 
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setExchangeProxy(address _exchangeProxy) external onlyExchangeProxy {
        exchangeProxy = _exchangeProxy;
    }

    function setReserveFund(address _reserveFund) external onlyReserveFund {
        reserveFund = _reserveFund;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getRewardPerBlock(
        address _rewardToken,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        uint256 _rewardPerBlock = rewardPoolInfo[_rewardToken].rewardPerBlock;
        if (_from >= _to || _from >= endRewardBlock) return 0;
        if (_to <= startRewardBlock) return 0;
        if (_from <= startRewardBlock) {
            if (_to <= endRewardBlock) return _to.sub(startRewardBlock).mul(_rewardPerBlock);
            else return endRewardBlock.sub(startRewardBlock).mul(_rewardPerBlock);
        }
        if (_to <= endRewardBlock) return _to.sub(_from).mul(_rewardPerBlock);
        else return endRewardBlock.sub(_from).mul(_rewardPerBlock);
    }

    function getRewardPerBlock(address _rewardToken) external view returns (uint256) {
        return getRewardPerBlock(_rewardToken, block.number, block.number + 1);
    }

    function pendingReward(address _rewardToken, address _account) external view returns (uint256) {
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 lpSupply = IERC20(stakeToken).balanceOf(address(this));
        uint256 _endRewardBlock = endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock && lpSupply != 0) {
            uint256 _incRewardPerShare = getRewardPerBlock(_rewardToken, _lastRewardBlock, _endRewardBlockApplicable).mul(1e18).div(lpSupply);
            _accRewardPerShare = _accRewardPerShare.add(_incRewardPerShare);
        }
        return user.amount.mul(_accRewardPerShare).div(1e18).add(user.reward[_rewardToken]).sub(user.rewardDebt[_rewardToken]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setRewardPool(address _rewardToken, uint256 _startBlock) public lock onlyOperator {
        updateAllRewards();
        rewardPoolInfo[_rewardToken] = RewardPoolInfo({
            rewardToken: _rewardToken, 
            lastRewardBlock: _startBlock, 
            rewardPerBlock: 0, 
            accRewardPerShare: 0, 
            totalPaidRewards: 0
            });
    }

    function allocateMoreRewards(
        uint256 _wbnbAmount,
        uint256 _busdAmount,
        uint256 _days
    ) external onlyReserveFund {
        _allocateMoreRewards(wbnb, _wbnbAmount, _days);
        _allocateMoreRewards(busd, _busdAmount, _days);
        if (_days > 0) {
            if (endRewardBlock < block.number) {
                endRewardBlock = block.number.add(_days.mul(BLOCKS_PER_DAY));
            } else {
                endRewardBlock = endRewardBlock.add(_days.mul(BLOCKS_PER_DAY));
            }
        }
    }

    function _allocateMoreRewards(
        address _rewardToken,
        uint256 _addedReward,
        uint256 _days
    ) internal {
        uint256 _pendingBlocks = (endRewardBlock > block.number) ? endRewardBlock.sub(block.number) : 0;
        if (_pendingBlocks > 0 || _days > 0) {
            updateReward(_rewardToken);
            IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _addedReward);
            uint256 _newPendingReward = rewardPoolInfo[_rewardToken].rewardPerBlock.mul(_pendingBlocks).add(_addedReward);
            uint256 _newPendingBlocks = _pendingBlocks.add(_days.mul(BLOCKS_PER_DAY));
            rewardPoolInfo[_rewardToken].rewardPerBlock = _newPendingReward.div(_newPendingBlocks);
        }
    }

    function updateAllRewards() public {
        updateReward(wbnb);
        updateReward(busd);
    }

    function updateReward(address _rewardToken) public {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _endRewardBlock = endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock) {
            uint256 lpSupply = IERC20(stakeToken).balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 _incRewardPerShare = getRewardPerBlock(_rewardToken, _lastRewardBlock, _endRewardBlockApplicable).mul(1e18).div(lpSupply);
                rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(_incRewardPerShare);
            }
            rewardPool.lastRewardBlock = _endRewardBlockApplicable;
        }
    }

    // Deposit LP tokens
    function _deposit(address _account, uint256 _amount) internal lock {
        UserInfo storage user = userInfo[_account];
        getAllRewards(_account);
        user.amount = user.amount.add(_amount);
        address _wbnb = wbnb;
        address _busd = busd;
        user.rewardDebt[_wbnb] = user.amount.mul(rewardPoolInfo[_wbnb].accRewardPerShare).div(1e18);
        user.rewardDebt[_busd] = user.amount.mul(rewardPoolInfo[_busd].accRewardPerShare).div(1e18);
        emit Deposit(_account, _amount);
    }

    function deposit(uint256 _amount) external {
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
    }

    function depositFor(address _account, uint256 _amount) external onlyExchangeProxy {
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_account, _amount);
    }

    // Withdraw LP tokens.
    function _withdraw(address _account, uint256 _amount) internal lock {
        UserInfo storage user = userInfo[_account];
        getAllRewards(_account);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(stakeToken).safeTransfer(_account, _amount);
        }
        address _wbnb = wbnb;
        address _busd = busd;
        user.rewardDebt[_wbnb] = user.amount.mul(rewardPoolInfo[_wbnb].accRewardPerShare).div(1e18);
        user.rewardDebt[_busd] = user.amount.mul(rewardPoolInfo[_busd].accRewardPerShare).div(1e18);
        emit Withdraw(_account, _amount);
    }

    function withdraw(uint256 _amount) external {
        _withdraw(msg.sender, _amount);
    }

    function claimReward() external {
        getAllRewards(msg.sender);
    }

    function getAllRewards(address _account) public {
        getReward(wbnb, _account);
        getReward(busd, _account);
    }

    function getReward(address _rewardToken, address _account) public {
        updateReward(_rewardToken);
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_rewardToken];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 _pendingReward = user.amount.mul(_accRewardPerShare).div(1e18).sub(user.rewardDebt[_rewardToken]);
        if (_pendingReward > 0) {
            user.accumulatedEarned[_rewardToken] = user.accumulatedEarned[_rewardToken].add(_pendingReward);
            rewardPool.totalPaidRewards = rewardPool.totalPaidRewards.add(_pendingReward);
            user.rewardDebt[_rewardToken] = user.amount.mul(_accRewardPerShare).div(1e18);
            uint256 _paidAmount = user.reward[_rewardToken].add(_pendingReward);
            // Safe reward transfer, just in case if rounding error causes pool to not have enough reward amount
            uint256 _rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
            if (_rewardBalance < _paidAmount) {
                user.reward[_rewardToken] = _paidAmount; // pending, dont claim yet
            } else {
                user.reward[_rewardToken] = 0;
                _safeTokenTransfer(_rewardToken, _account, _paidAmount);
                emit RewardPaid(_rewardToken, _account, _paidAmount);
            }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external lock {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt[wbnb] = 0;
        user.rewardDebt[busd] = 0;
        user.reward[wbnb] = 0;
        user.reward[busd] = 0;
        IERC20(stakeToken).safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    // @garyb9: quality of life function - > not from the real contract!
    function resetUserInfo() external lock {
        UserInfo storage user = userInfo[msg.sender];
        user.amount = 0;
        user.rewardDebt[wbnb] = 0;
        user.rewardDebt[busd] = 0;
        user.reward[wbnb] = 0;
        user.reward[busd] = 0;
        emit ResetUserInfo(msg.sender);
    }

    function _safeTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > _tokenBal) {
            _amount = _tokenBal;
        }
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        require(address(_token) != stakeToken, "stakeToken");
        _token.safeTransfer(to, amount);
    }
}