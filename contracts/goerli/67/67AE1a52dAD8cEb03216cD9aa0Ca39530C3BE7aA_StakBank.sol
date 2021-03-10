//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

contract StakBank is Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public usdt;

    mapping(address => uint) private _staking;
    
    uint public periodTime;
    uint public feeUnit;
    uint public decimal;
    uint public minAmountToStake;
    uint public lastDis;
    uint public ethRewardedNotWithdraw;
    uint public ustdRewardNotWithdraw;
    uint public totalStaked;

    struct Detail {
        uint timestamp;
        uint stakedAmount;
        uint ethRewardAmount;
        uint usdtRewardAmount;
        bool isUnstaked;
    }

    mapping(address => Detail[]) private _eStaker;

    address[] stakeHolder;
    mapping(address => uint) stakeHolderPosInArray;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event UserStaked(address indexed user, uint amount, uint timestamp);
    event UserUnstakedWithId(address indexed user, uint indexed detailId, uint ethReward, uint usdtReward);
    event UserUnstakedAll(address indexed user);
    event AdminDistributeReward(uint ethToReward, uint ethRewardedInThisDis, uint usdtToReward, uint usdtRewardedInThisDis);
    event UserWithdrawedReward(address indexed user, uint ethReward, uint usdtReward);
    event StakBankConfigurationChanged(address indexed changer, uint timestamp);

    constructor(address _tokenAddress, address _usdt, uint _periodTime, uint _feeUnit, uint _decimal) {
        token = IERC20(_tokenAddress);
        usdt = _usdt;
        periodTime = _periodTime;
        feeUnit = _feeUnit;
        decimal = _decimal;
        minAmountToStake = 100000000000000;
        lastDis = block.timestamp;
        ethRewardedNotWithdraw = 0;
        ustdRewardNotWithdraw = 0;
        totalStaked = 0;
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
        require(value <= 20, "Too large");
        decimal = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    /// @notice Owner can change minimum coin to stake
    /// @param value Min coin with that user can stake
    function setMinAmountToStake(uint value) external onlyOwner {
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

    /// @notice USDT used to reward in next distribution
    function numUsdtToReward() public view returns (uint) {
        return (_usdtBalanceOf(address(this)) - ustdRewardNotWithdraw);
    }

    /// @notice Return eth fee corresponding to an amount of staking coin.
    /// @param amount Staking coin amount
    function feeCalculator(uint amount) public view returns (uint) {
        uint platformFee = amount.mul(feeUnit).div(10 ** decimal);
        return platformFee;
    }

    /// @notice User stake coin
    /// @param stakedAmount Amount of coin you wanna stake.
    function stake(uint stakedAmount) public payable whenNotPaused {
        require(msg.sender != owner, "Owner cannot stake");
        require(stakedAmount >= minAmountToStake, "Need to stake more token");

        uint platformFee = feeCalculator(stakedAmount);

        require(msg.value >= platformFee);
        require(_deliverTokensFrom(msg.sender, address(this), stakedAmount), "Failed to transfer from staker to StakBank");

        uint current = block.timestamp;

        if (!_isHolder(msg.sender)) {
            stakeHolder.push(msg.sender);
            stakeHolderPosInArray[msg.sender] = stakeHolder.length;
        }

        _staking[msg.sender] = _staking[msg.sender].add(stakedAmount);
        totalStaked = totalStaked.add(stakedAmount);

        _createNewTransaction(msg.sender, current, stakedAmount);

        address payable admin = address(uint160(address(owner)));
        admin.transfer(platformFee);

        emit UserStaked(msg.sender, stakedAmount, current);
    }

    /// @notice Get amount of staking coin of an user
    /// @param user User's address you wanna check staking balance
    function stakingOf(address user) public view returns (uint) {
        return (_staking[user]);
    }

    /// @notice User check detail of staking request
    /// @param user address of user want to check
    /// @param idStake id of staking request
    function checkDetailStakingRequest(address user, uint idStake) 
        public view 
        returns (uint timestamp, uint stakedAmount, uint ethReward, uint usdtReward, bool isUnstaked) 
    {
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");
        Detail memory detail = _eStaker[user][idStake - 1];
        timestamp = detail.timestamp;
        stakedAmount = detail.stakedAmount;
        ethReward = detail.ethRewardAmount;
        usdtReward = detail.usdtRewardAmount;
        isUnstaked = detail.isUnstaked;
        return (timestamp, stakedAmount, ethReward, usdtReward, isUnstaked);
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
        require(!_isUnstaked(msg.sender, idStake), "idStake unstaked");
        require(stakingOf(msg.sender) > _eStaker[msg.sender][idStake - 1].stakedAmount, "Cannot unstake the last with this method");

        Detail memory detail = _eStaker[msg.sender][idStake - 1];
        uint ethReward = detail.ethRewardAmount;

        if (ethReward != 0) {
            address payable staker = address(uint160(address(msg.sender)));
            staker.transfer(ethReward);
        }

        uint usdtReward = detail.usdtRewardAmount;
        if (usdtReward != 0) {
            _transferUSDT(msg.sender, usdtReward);
        }

        ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(ethReward);
        ustdRewardNotWithdraw = ustdRewardNotWithdraw.sub(usdtReward);

        unstakeId(msg.sender, idStake);

        emit UserUnstakedWithId(msg.sender, idStake, ethReward, usdtReward);
    }

    /// @notice unstake all of a user
    function _unstakeAll(address sender) private {
        _withdrawReward(sender);

        for(uint i = 0; i < _eStaker[sender].length; i++) {
            if (!_isUnstaked(sender, i + 1)) {
                unstakeId(sender, i + 1);
            }
        }

        uint posInArray = stakeHolderPosInArray[sender];
        stakeHolder[posInArray - 1] = stakeHolder[ stakeHolder.length - 1 ];
        stakeHolderPosInArray[ stakeHolder[posInArray - 1] ] = posInArray;
        stakeHolder.pop();

        delete _eStaker[sender];
        delete stakeHolderPosInArray[sender];

        emit UserUnstakedAll(sender);
    }

    /// @notice User unstake all of staking transaction and get all reward
    function unstakeAll() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _unstakeAll(msg.sender);
    }

    /// @notice withdraw all reward of a user
    function _withdrawReward(address sender) private {
        uint ethReward = 0;
        uint usdtReward = 0;

        for(uint i = 0; i < _eStaker[sender].length; i++) {
            Detail memory detail = _eStaker[sender][i];

            if (detail.isUnstaked) {
                continue;
            }
            ethReward = ethReward.add(detail.ethRewardAmount);
            _eStaker[sender][i].ethRewardAmount = 0;

            usdtReward = usdtReward.add(detail.usdtRewardAmount);
            _eStaker[sender][i].usdtRewardAmount = 0;
        }

        address payable staker = address(uint160(address(sender)));
        staker.transfer(ethReward);
        ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(ethReward);

        _transferUSDT(sender, usdtReward);
        ustdRewardNotWithdraw = ustdRewardNotWithdraw.sub(usdtReward);

        emit UserWithdrawedReward(sender, ethReward, usdtReward);
    }

    /// @notice User can with withdraw all reward. staking coin still in the pool
    function withdrawReward() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _withdrawReward(msg.sender);
    }


    /// @notice Owner can trigger distribution after "periodTime"
    function rewardDistribution() public onlyOwner whenNotPaused {
        uint current = block.timestamp;
        uint timelast = current.sub(lastDis);
        
        require(timelast >= periodTime, "Too soon to trigger reward distribution");
        uint unitTime;
        (timelast, unitTime) = _changeToAnotherUnitTime(timelast);

        uint totalTime = 0;
        for (uint i = 0; i < stakeHolder.length; i++) {
            for (uint j = 0; j < _eStaker[ stakeHolder[i] ].length; j++) {
                Detail memory detail = _eStaker[ stakeHolder[i] ][j];
                if (detail.isUnstaked) continue;
                uint time;
                if (detail.timestamp <= lastDis) {
                    time = timelast.mul(detail.stakedAmount);
                } else {
                    time = ( current - detail.timestamp) / (unitTime);
                    time = time.mul(detail.stakedAmount);
                }
                totalTime = totalTime.add(time);
            }
        }
        
        uint ethToReward = numEthToReward();
        uint ethRewardedInThisDis = 0;

        uint usdtToReward = numUsdtToReward();
        uint usdtRewardedInThisDis = 0;

        if (totalTime != 0) {

            for (uint i = 0; i < stakeHolder.length; i++) {
                for (uint j = 0; j < _eStaker[ stakeHolder[i] ].length; j++) {
                    Detail memory detail = _eStaker[ stakeHolder[i] ][j];
                    if (detail.isUnstaked) continue;
                    uint ethReward = 0;
                    uint usdtReward = 0;

                    uint time = 0;
                    if (detail.timestamp <= lastDis) {
                        time = timelast.mul(detail.stakedAmount);
                    } else {
                        time = ( current - detail.timestamp) / (unitTime);
                        time = time.mul(detail.stakedAmount);
                    }

                    ethReward = ethToReward.mul(time).div(totalTime);
                    usdtReward = usdtToReward.mul(time).div(totalTime);

                    _eStaker[ stakeHolder[i] ][j].ethRewardAmount 
                        = _eStaker[ stakeHolder[i] ][j].ethRewardAmount.add(ethReward);

                    ethRewardedInThisDis = ethRewardedInThisDis.add(ethReward);

                    _eStaker[ stakeHolder[i] ][j].usdtRewardAmount 
                        = _eStaker[ stakeHolder[i] ][j].usdtRewardAmount.add(usdtReward);

                    usdtRewardedInThisDis = usdtRewardedInThisDis.add(usdtReward);

                }
            }
            
        }

        ethRewardedNotWithdraw += ethRewardedInThisDis;
        ustdRewardNotWithdraw += usdtRewardedInThisDis;

        lastDis = block.timestamp;

        emit AdminDistributeReward(ethToReward, ethRewardedInThisDis, usdtToReward, usdtRewardedInThisDis);
    }

    function numberOfStakeHolder() public view returns (uint) {
        return stakeHolder.length;
    }

    /// @notice close stakbank, if too much stakeholder, close sequencely
    function closeStakBank(uint number) public onlyOwner whenNotPaused {
        require(number >= numberOfStakeHolder());
        require(numberOfStakeHolder() != 0);

        for (uint i = number - 1; i >= 0; i--) {
            _unstakeAll(stakeHolder[i]);
        }
        
        if (numberOfStakeHolder() == 0) {
            address payable admin = address(uint160(address(owner)));
            admin.transfer(address(this).balance);

            _transferUSDT(owner, _usdtBalanceOf(address(this)));
        }
    }

    /// @dev Push staking detail in user's staking list
    /// @param user Address of user
    /// @param current Timestamp user stake coin
    /// @param stakedAmount Amount of coin that user stake
    function _createNewTransaction(address user, uint current, uint stakedAmount) private {
        Detail memory detail = Detail(current, stakedAmount, 0, 0, false);
        _eStaker[user].push(detail);
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
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");
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

    /// @notice use to transfer usdt
    function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    /// @notice use to transfer usdt
    function _transferUSDT(address to, uint value) private {
        _safeTransfer(usdt, to, value);
    }

    /// @notice get usdt balance of a user
    function _usdtBalanceOf(address user) private view returns (uint) {
        IERC20 USDT = IERC20(usdt);
        return USDT.balanceOf(user);
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

}