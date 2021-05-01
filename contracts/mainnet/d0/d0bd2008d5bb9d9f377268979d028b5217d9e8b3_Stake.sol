/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


// File contracts/interfaces/IConfig.sol

pragma solidity >=0.8.0;

interface IConfig {
    enum EventType {FUND_CREATED, FUND_UPDATED, STAKE_CREATED, STAKE_UPDATED, REG_CREATED, REG_UPDATED, PFUND_CREATED, PFUND_UPDATED}

    function ceo() external view returns (address);

    function protocolPool() external view returns (address);

    function protocolToken() external view returns (address);

    function feeTo() external view returns (address);

    function nameRegistry() external view returns (address);

    //  function investTokenWhitelist() external view returns (address[] memory);

    function tokenMinFundSize(address token) external view returns (uint256);

    function investFeeRate() external view returns (uint256);

    function redeemFeeRate() external view returns (uint256);

    function claimFeeRate() external view returns (uint256);

    function poolCreationRate() external view returns (uint256);

    function slot0() external view returns (uint256);

    function slot1() external view returns (uint256);

    function slot2() external view returns (uint256);

    function slot3() external view returns (uint256);

    function slot4() external view returns (uint256);

    function notify(EventType _type, address _src) external;
}


// File contracts/interfaces/IStake.sol

pragma solidity >=0.8.0;

interface IStake {
    function claim0(address _owner) external;

    function initialize(
        address stakeToken,
        address rewardToken,
        uint256 start,
        uint256 end,
        uint256 rewardPerBlock
    ) external;
}


// File contracts/libs/TransferHelper.sol

pragma solidity >=0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: APPROVE_FAILED'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/Stake.sol

pragma solidity >=0.8.0;




interface IConfigable {
    function getConfig() external returns (IConfig);
}

contract Stake is IStake {
    event StakeUpdated(
        address indexed staker,
        bool isIncrease,
        uint256 stakeChanged,
        uint256 stakeAmount
    );

    event Claimed(address indexed staker, uint256 reward);

    // stake token address, ERC20
    address public stakeToken;

    bool initialized;

    bool locker;

    // reward token address, ERC20
    address public rewardToken;

    // Mining start date(epoch second)
    uint256 public startDateOfMining;

    // Mining end date(epoch second)
    uint256 public endDateOfMining;

    // controller address
    address controller;

    // reward per Second
    uint256 public rewardPerSecond;

    // timestamp of last updated
    uint256 public lastUpdatedTimestamp;

    uint256 public rewardPerTokenStored;

    // staked total
    uint256 private _totalSupply;

    struct StakerInfo {
        // exclude reward's amount
        uint256 rewardDebt;
        // stake total
        uint256 amount;
        // pending reward
        uint256 reward;
    }

    // staker's StakerInfo
    mapping(address => StakerInfo) public stakers;

    /* ========== MODIFIER ========== */

    modifier stakeable() {
        require(
            block.timestamp <= endDateOfMining,
            "stake not begin or complete"
        );
        _;
    }

    modifier enable() {
        require(initialized, "initialized = false");
        _;
    }

    modifier onlyController {
        require(controller == msg.sender, "only controller");
        _;
    }

    modifier lock() {
        require(locker == false, "locked");
        locker = true;
        _;
        locker = false;
    }

    modifier updateReward(address _staker) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdatedTimestamp = lastTimeRewardApplicable();
        if (_staker != address(0)) {
            stakers[_staker].reward = rewardOf(_staker);
            stakers[_staker].rewardDebt = rewardPerTokenStored;
        }
        _;
    }

    constructor() {}

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
     * @dev initialize contract
     * @param _stake address of stake token
     * @param _reward address of reward token
     * @param _start epoch seconds of mining starts
     * @param _end epoch seconds of mining complete
     * @param _totalReward totalReward
     */
    function initialize(
        address _stake,
        address _reward,
        uint256 _start,
        uint256 _end,
        uint256 _totalReward
    ) external override {
        require(!initialized, "initialized = true");
        // only initialize once
        initialized = true;
        controller = msg.sender;
        stakeToken = _stake;
        rewardToken = _reward;
        startDateOfMining = _start;
        endDateOfMining = _end;
        rewardPerSecond = _totalReward / (_end - _start);
    }

    /**
     * @dev stake token
     * @param _amount amount of token to be staked
     */
    function stake(uint256 _amount)
        external
        enable()
        lock()
        updateReward(msg.sender)
    {
        require(_amount > 0, "amount = 0");
        require(block.timestamp <= endDateOfMining, "stake complete");
        _totalSupply += _amount;
        stakers[msg.sender].amount += _amount;
        TransferHelper.safeTransferFrom(
            stakeToken,
            msg.sender,
            address(this),
            _amount
        );
        emit StakeUpdated(
            msg.sender,
            true,
            _amount,
            stakers[msg.sender].amount
        );
        _notify();
    }

    /**
     * @dev unstake token
     * @param _amount amount of token to be unstaked
     */
    function unstake(uint256 _amount)
        public
        enable()
        lock()
        updateReward(msg.sender)
    {
        require(_amount > 0, "amount = 0");
        require(stakers[msg.sender].amount >= _amount, "insufficient amount");
        _claim(msg.sender);
        _totalSupply -= _amount;
        stakers[msg.sender].amount -= _amount;
        TransferHelper.safeTransfer(stakeToken, msg.sender, _amount);
        emit StakeUpdated(
            msg.sender,
            false,
            _amount,
            stakers[msg.sender].amount
        );
        _notify();
    }

    /**
     * @dev claim rewards
     */
    function claim() external enable() lock() updateReward(msg.sender) {
        _claim(msg.sender);
    }

    /**
     * @dev quit, claim reward + unstake all
     */
    function quit() external enable() lock() updateReward(msg.sender) {
        unstake(stakers[msg.sender].amount);
        _claim(msg.sender);
    }

    /**
     * @dev claim rewards, only owner allowed
     * @param _staker staker address
     */
    function claim0(address _staker)
        external
        override
        onlyController()
        enable()
        updateReward(msg.sender)
    {
        _claim(_staker);
    }

    /* ========== VIEWs ========== */
    function lastTimeRewardApplicable() public view returns (uint256) {
        if (block.timestamp < startDateOfMining) return startDateOfMining;
        return
            block.timestamp > endDateOfMining
                ? endDateOfMining
                : block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0 || block.timestamp < startDateOfMining) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdatedTimestamp) *
                rewardPerSecond) * 1e18) /
            _totalSupply;
    }

    /**
     * @dev amount of stake per address
     * @param _staker staker address
     * @return amount of stake
     */
    function stakeOf(address _staker) external view returns (uint256) {
        return stakers[_staker].amount;
    }

    /**
     * @dev amount of reward per address
     * @param _staker address
     * @return value reward amount of _staker
     */
    function rewardOf(address _staker) public view returns (uint256 value) {
        StakerInfo memory info = stakers[_staker];
        if (info.amount == 0) return 0;
        return
            (info.amount * (rewardPerToken() - info.rewardDebt)) /
            1e18 +
            info.reward;
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    /**
     * @dev claim reward
     * @param _staker address
     */
    function _claim(address _staker) private {
        uint256 reward = stakers[_staker].reward;
        if (reward > 0) {
            stakers[_staker].reward = 0;
            IConfig config = IConfigable(controller).getConfig();
            uint256 claimFeeRate = config.claimFeeRate();
            uint256 out = (reward * (10000 - claimFeeRate)) / 10000;
            uint256 fee = reward - out;
            TransferHelper.safeTransfer(rewardToken, _staker, out);

            if (fee > 0) {
                // transfer to feeTo
                TransferHelper.safeTransfer(rewardToken, config.feeTo(), fee);
            }
            emit Claimed(_staker, reward);
            _notify();
        }
    }

    function _notify() private {
        IConfigable(controller).getConfig().notify(
            IConfig.EventType.STAKE_UPDATED,
            address(this)
        );
    }
}