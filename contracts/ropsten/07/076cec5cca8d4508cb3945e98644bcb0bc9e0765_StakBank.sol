//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";


contract StakBank is Ownable, Pausable {
    using SafeMath for uint;
    IERC20 public token;

    mapping(address => uint) private _staking;
    
    uint public periodTime;
    uint public feeUnit;
    uint public minAmountToStake;
    uint public lastDis;
    uint public decimal;
    uint public ethRewardedNotWithdraw;
    uint public totalStaked;

    // fixed! | 0.0006 eth =  600000000000000 wei = (10^9/0.0001)*60(second|minute)->pool can hold max 1 billion JST
    uint public minEthNeededToReward; 

    uint private _cummEth;
    uint private _totalStakedBeforeLastDis;

    // fixed! | 0.0001 JST = 100000000000000 | Number of staked (JST) coin to be rewarded = 0.0001 * N
    uint private unitCoinToDivide; 

    struct Transaction {
        address staker;
        uint timestamp;
        uint coinToCalcReward;
        uint detailId;
    }

    Transaction[] private stakingTrans;
    
    // each staking of each user
    struct Detail {
        uint stakedAmount;
        uint coinToCalcReward;
        uint ethFirstReward;
        uint cummEthLastWithdraw;
        bool isOldCoin;
        bool isUnstaked;
    }

    mapping(address => Detail[]) private _eStaker;
    
    event UserStaked(address indexed user, uint amount, uint timestamp);
    event UserUnstakedWithId(address indexed user, uint indexed detailId, uint rewardAmount);
    event UserUnstakedAll(address indexed user);
    event AdminDistributeReward(uint ethToReward, uint ethRewardedInThisDis);
    event UserWithdrawedReward(address indexed user, uint rewardAmount);
    event StakBankConfigurationChanged(address indexed changer, uint timestamp);

    constructor(address _tokenAddress, uint _periodTime, uint _feeUnit, uint _decimal) {
        token = IERC20(_tokenAddress);
        periodTime = _periodTime;
        feeUnit = _feeUnit;
        minAmountToStake = 100000000000000;
        lastDis = block.timestamp;
        decimal = _decimal;
        minEthNeededToReward = 600000000000000;
        totalStaked = 0;

        unitCoinToDivide = 100000000000000;
        ethRewardedNotWithdraw = 0;
        _cummEth = 0;
        _totalStakedBeforeLastDis = 0;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    /// @notice Owner can change minimum time to trigger distribution
    /// @param value Time you wanna change to.
    function setPeriodTime(uint value) external onlyOwner {
        require(value > 0, "Minimum time to next distribution must be positive number");

        periodTime = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    /// @dev platformFee = staked_coin * FeeUnit / (10 ^ Decimal)
    /// @param value FeeUnit in above formula
    function setFeeUnit(uint value) external onlyOwner {
        feeUnit = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    /// @dev platformFee = staked_coin * FeeUnit / (10 ^ Decimal)
    /// @param value Decimal in above formula
    function setDecimal(uint value) external onlyOwner {
        decimal = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    /// @notice Owner can change minimum coin to stake but that number must not lower than 0.0001 JST
    /// @param value Min coin with that user can stake
    function setMinAmountToStake(uint value) external onlyOwner {
        require(value >= unitCoinToDivide, "Lower than 0.0001 JST");

        minAmountToStake = value;
        
        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    /// @notice Countdown seconds to next reward distribution
    function nextDistribution() public view returns (uint) {
        uint cur = block.timestamp;
        if (cur >= lastDis + periodTime) return 0;
        return (periodTime - (cur - lastDis));
    }

    /// @notice Eth used to reward in next distribution
    function numEthToReward() public view returns (uint) {
        return ((address(this).balance) - ethRewardedNotWithdraw);
    }

    /// @notice Return eth fee corresponding to an amount of staking coin.
    /// @param amount Staking coin amount
    function feeCalculator(uint amount) public view returns (uint) {
        uint remainder = amount % unitCoinToDivide;
        amount = amount.sub(remainder);
        uint platformFee = amount.mul(feeUnit).div(10 ** decimal);
        return platformFee;
    }

    /// @notice User stake coin
    /// @param stakedAmount Amount of coin you wanna stake.
    /// @dev Not using remainder of stakedAmount with unitCoinToDivide to calc reward
    function stake(uint stakedAmount) public payable whenNotPaused {
        require(msg.sender != owner, "Owner cannot stake");
        require(stakedAmount >= minAmountToStake, "Need to stake more token");
        require(totalStaked + stakedAmount <= (10 ** 27), "Reached limit coin in pool");

        uint platformFee = feeCalculator(stakedAmount);

        require(msg.value >= platformFee);
        require(_deliverTokensFrom(msg.sender, address(this), stakedAmount), "Failed to transfer from staker to StakBank");
        
        uint current = block.timestamp;

        _staking[msg.sender] = _staking[msg.sender].add(stakedAmount);
        totalStaked = totalStaked.add(stakedAmount);

        uint remainder = stakedAmount % unitCoinToDivide;
        uint coinToCalcReward = stakedAmount - remainder;

        _createNewTransaction(msg.sender, current, stakedAmount, coinToCalcReward);

        address payable admin = address(uint(address(owner)));
        admin.transfer(platformFee);

        emit UserStaked(msg.sender, stakedAmount, current);
    }

    /// @notice Get amount of staking coin of an user
    /// @param user User'address you wanna check staking balance
    function stakingOf(address user) public view returns (uint) {
        return (_staking[user]);
    }

    /// @dev Send back staking coin to user. Decrease total amount of staking coin in pool. Mark transaction as unstaked.
    /// @param sender User wanna unstake
    /// @param idStake Order of staking transaction user wanna unstake
    function unstakeId(address sender, uint idStake) private {
        Detail memory detail = _eStaker[sender][idStake - 1];
        uint coinNum = detail.stakedAmount;

        _deliverTokens(sender, coinNum);

        _staking[sender] = _staking[sender].sub(coinNum);

        _eStaker[sender][idStake - 1].isUnstaked = true;

        totalStaked = totalStaked.sub(coinNum);
    }

    /// @notice User can unstake with idStake, get reward of that staking transaction
    /// @param idStake Order of staking transaction user wanna unstake
    /// @dev Order will be count from 0 when user unstake all
    function unstakeWithId(uint idStake) public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        require(_eStaker[msg.sender].length > 1, "Cannot unstake the last with this method");
        require(!_isUnstaked(msg.sender, idStake), "idStake unstaked");

        Detail memory detail = _eStaker[msg.sender][idStake - 1];
        uint reward = 0;

        if (detail.isOldCoin) {
            _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.sub(detail.coinToCalcReward);
            reward = _cummEth.sub(detail.cummEthLastWithdraw);

            uint numUnitCoin = (detail.coinToCalcReward).div(unitCoinToDivide);
            reward = reward.mul(numUnitCoin);
            reward = reward.add(detail.ethFirstReward);

            address payable staker = address(uint160(address(msg.sender)));
            staker.transfer(reward);

            ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(reward);
        }

        unstakeId(msg.sender, idStake);

        emit UserUnstakedWithId(msg.sender, idStake, reward);
    }

    /// @notice User unstake all of staking transaction and get all reward
    function unstakeAll() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");

        withdrawReward();

        for(uint i = 0; i < _eStaker[msg.sender].length; i++) {
            if (!_isUnstaked(msg.sender, i + 1)) {
                unstakeId(msg.sender, i + 1);
            }
        }

        delete _eStaker[msg.sender];

        emit UserUnstakedAll(msg.sender);
    }

    /// @notice Owner can trigger distribution after "periodTime"
    /// @dev Still encourage trigger this function when pool has not enough Eth to Reward (0.0006 eth). Users dont receive any eth
    function rewardDistribution() public onlyOwner whenNotPaused {
        uint current = block.timestamp;
        uint timelast = current.sub(lastDis);
        
        require(timelast >= periodTime, "Too soon to trigger reward distribution");

        uint ethToReward = numEthToReward();

        if (ethToReward < minEthNeededToReward) { // --> not distribution when too few eth
            _notEnoughEthToReward();
            return;
        }
        
        uint unitTime;
        (timelast, unitTime) = _changeToAnotherUnitTime(timelast);
        
        uint UnitCoinNumberBeforeLastDis = _totalStakedBeforeLastDis.div(unitCoinToDivide);
        uint totalTime = timelast.mul(UnitCoinNumberBeforeLastDis);

        for(uint i = 0; i < stakingTrans.length; i++) {
            Transaction memory transaction = stakingTrans[i];

            if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                continue;
            }

            uint numTimeWithStandardUnit = (current.sub(transaction.timestamp)).div(unitTime);
            uint numUnitCoin = (transaction.coinToCalcReward).div(unitCoinToDivide);

            totalTime = totalTime.add(numUnitCoin.mul(numTimeWithStandardUnit));
        }

        uint ethRewardedInThisDis = 0;

        if (totalTime > 0) {
            uint unitValue = ethToReward.div(totalTime);
            _cummEth = _cummEth.add(unitValue.mul(timelast));

            for(uint i = 0; i < stakingTrans.length; i++) {
                Transaction memory transaction = stakingTrans[i];

                if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                    continue;
                }

                uint idStake = transaction.detailId;
                _eStaker[ transaction.staker ][ idStake - 1 ].cummEthLastWithdraw = _cummEth;
                
                uint numTimeWithStandardUnit = (current.sub(transaction.timestamp)).div(unitTime);
                uint numUnitCoin = (transaction.coinToCalcReward).div(unitCoinToDivide);

                _eStaker[ transaction.staker ][ idStake - 1 ].ethFirstReward = unitValue.mul(numUnitCoin).mul(numTimeWithStandardUnit);
 
                _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.add(transaction.coinToCalcReward);
                _eStaker[ transaction.staker ][ idStake - 1 ].isOldCoin = true;
            }

            delete stakingTrans;
            ethRewardedInThisDis = unitValue.mul(totalTime);
            ethRewardedNotWithdraw = ethRewardedNotWithdraw.add(ethRewardedInThisDis);
        }

        lastDis = block.timestamp;

        emit AdminDistributeReward(ethToReward, ethRewardedInThisDis);
    }

    /// @notice User can with withdraw all reward. staking coin still in the pool
    function withdrawReward() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");

        uint userReward = 0;

        for(uint i = 0; i < _eStaker[msg.sender].length; i++) {
            Detail memory detail = _eStaker[msg.sender][i];

            if (!detail.isOldCoin || detail.isUnstaked) {
                continue;
            }

            uint numUnitCoin = (detail.coinToCalcReward).div(unitCoinToDivide);

            uint addEth = (numUnitCoin).mul(_cummEth.sub(detail.cummEthLastWithdraw));
            addEth = addEth.add(detail.ethFirstReward);
            userReward = userReward.add(addEth);

            _eStaker[msg.sender][i].ethFirstReward = 0;
            _eStaker[msg.sender][i].cummEthLastWithdraw = _cummEth;
        }

        address payable staker = address(uint(address(msg.sender)));

        staker.transfer(userReward);

        ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(userReward);

        emit UserWithdrawedReward(msg.sender, userReward);
    }

    /// @dev Push staking detail in user's staking list
    /// @dev coinToCalcReward = stakedAmount - stakedAmount % unitCoinToDivide
    /// @param user Address of user
    /// @param current Timestamp user stake coin
    /// @param stakedAmount Amount of coin that user stake
    /// @param coinToCalcReward Coin using to calc reward
    function _createNewTransaction(address user, uint current, uint stakedAmount, uint coinToCalcReward) private {
        Detail memory detail = Detail(stakedAmount, coinToCalcReward, 0, 0, false, false);
        _eStaker[user].push(detail);

        Transaction memory t = Transaction(user, current, coinToCalcReward, _eStaker[user].length);
        stakingTrans.push(t);
    }

    /// @dev Check if a user is a holder
    /// @param holder address of user
    function _isHolder(address holder) private view returns (bool) {
        return (_staking[holder] != 0);
    }

    /// @dev Check if an idStake unstaked?
    /// @param user Address of user
    /// @param idStake Id of Staking transaction
    function _isUnstaked(address user, uint idStake) private view returns (bool) {
        if ((idStake < 1) || (idStake > _eStaker[user].length)) {
            return true;
        }
        return (_eStaker[user][idStake - 1].isUnstaked);
    }

    /// @dev Transfer coin into pool to stake
    /// @param from User's address
    /// @param to StakBank's address
    /// @param amount Amount of staking coin
    function _deliverTokensFrom(address from, address to, uint amount) private returns (bool) {
        IERC20(token).transferFrom(from, to, amount);
        return true;    
    }

    /// @dev Transfer coin from pool back to user
    /// @param to User's address
    /// @param amount Amount of staking coin
    function _deliverTokens(address to, uint amount) private returns (bool) {
        IERC20(token).transfer(to, amount);
        return true;
    }

    /// @dev Change amount of seconds to reasonable time unit
    /// @param second Amount of second
    function _changeToAnotherUnitTime(uint second) private pure returns (uint, uint) {
        uint unitTime = 1;
        if (second <= 60) return (second, 1);

        unitTime = unitTime.mul(60);
        uint minute = second / unitTime;
        if (minute <= 60) return (minute, unitTime);

        unitTime = unitTime.mul(60);
        uint hour = second / unitTime;
        if (hour <= 24) return (hour, unitTime);

        unitTime = unitTime.mul(24);
        uint day = second / unitTime;
        if (day <= 30) return (day, unitTime);

        unitTime = unitTime.mul(30);
        uint month = second / unitTime;
        if (month <= 12) return (month, unitTime);

        unitTime = unitTime.mul(12);
        uint year = second / unitTime;
        if (year > 50) year = 50;
        return (year, unitTime);
    } 

    /// @dev Handle when pool not has enough Eth to Reward
    function _notEnoughEthToReward() private {
        for(uint i = 0; i < stakingTrans.length; i++) {
            Transaction memory transaction = stakingTrans[i];

            if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                continue;
            }

            uint idStake = transaction.detailId;
            _eStaker[ transaction.staker ][ idStake - 1 ].cummEthLastWithdraw = _cummEth;

            _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.add(transaction.coinToCalcReward);
            _eStaker[ transaction.staker ][ idStake - 1 ].isOldCoin = true;
        }

        delete stakingTrans;
    }

}