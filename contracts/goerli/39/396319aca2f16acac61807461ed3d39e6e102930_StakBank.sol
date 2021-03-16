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
    uint public feePerDecimal;
    uint public decimal;
    uint public minAmountToStake;
    uint public lastDis;
    uint public totalStaked;
    uint public numberDistribution;

    uint private _hardcoin;
    uint private _softcoin;
    uint private _rewardedEth;
    uint private _rewardedUsdt;
    uint private _totalSoftcoinxTime;
    uint private MAXN;

    struct Request {
        uint timestamp;
        uint stakedAmount;
        uint firstDistId;
        uint lastWithdrawDistId;
        bool isUnstaked;
    }
    mapping(address => Request[]) private _eStaker;

    address[] stakeHolder;
    mapping(address => uint) stakeHolderPosInArray;

    struct DetailDistribution {
        uint timestamp;
        uint stdTime;
        uint virtualEthUnitValue;
        uint virtualUsdtUnitValue;
        uint cummVirtualEthUnitValuexTime;
        uint cummvirtualUsdtUnitValuexTime;
    }
    mapping (uint => DetailDistribution) private _detailDistribution;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event UserStaked(address indexed user, uint indexed requestId, uint amount, uint timestamp);
    event UserUnstakedWithId(address indexed user, uint indexed requestId, uint ethReward, uint usdtReward);
    event UserUnstakedAll(address indexed user);
    event AdminDistributeReward(uint ethToReward, uint usdtToReward);
    event UserWithdrawedReward(address indexed user, uint ethReward, uint usdtReward);
    event StakBankConfigurationChanged(address indexed changer, uint timestamp);

    constructor(address _tokenAddress, address _usdt, uint _periodTime, uint _feePerDecimal, uint _decimal) {
        token = IERC20(_tokenAddress);
        usdt = _usdt;
        
        periodTime = _periodTime;
        feePerDecimal = _feePerDecimal;
        decimal = _decimal;
        minAmountToStake = 100;
        lastDis = block.timestamp;
        totalStaked = 0;
        numberDistribution = 0;

        _hardcoin = 0;
        _softcoin = 0;
        _rewardedEth = 0;
        _rewardedUsdt = 0;
        _totalSoftcoinxTime = 0;

        MAXN = 10 ** 30;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    // setter function

    function setPeriodTime(uint _periodTime) external onlyOwner whenNotPaused {
        require(_periodTime > 0, "Minimum time to next distribution must be positive number");

        periodTime = _periodTime;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setFeePerDecimal(uint _feePerDecimal) external onlyOwner whenNotPaused {
        feePerDecimal = _feePerDecimal;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setDecimal(uint _decimal) external onlyOwner whenNotPaused {
        require(_decimal <= 20, "Too large");
        decimal = _decimal;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setMinAmountToStake(uint _minAmountToStake) external onlyOwner whenNotPaused {
        minAmountToStake = _minAmountToStake;
        
        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    // view data func

    function countdownToNextDistribution() public view returns (uint) {
        uint cur = block.timestamp;
        if (cur >= lastDis + periodTime) return 0;
        return (periodTime - (cur - lastDis));
    }

    function estimateNextDistribution() public view returns (uint) {
        return (lastDis.add(periodTime));
    }

    function numEthToReward() public view returns (uint) {
        return ((address(this).balance) - _rewardedEth);
    }

    function numUsdtToReward() public view returns (uint) {
        return (_usdtBalanceOf(address(this)) - _rewardedUsdt);
    }

    function numberOfStakeHolder() public view returns (uint) {
        return stakeHolder.length;
    } 

    function feeCalculator(uint amount) public view returns (uint) {
        uint platformFee = amount.mul(feePerDecimal).div(10 ** decimal);
        return platformFee;
    }

    function stakingOf(address user) public view returns (uint) {
        return (_staking[user]);
    }

    function checkDetailStakingRequest(address user, uint idStake) 
        public view 
        returns (uint timestamp, uint stakedAmount, uint ethReward, uint usdtReward, bool isUnstaked) 
    {
        require(_isHolder(user));
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");

        Request memory request = _eStaker[user][idStake - 1];

        timestamp = request.timestamp;
        stakedAmount = request.stakedAmount;
        isUnstaked = request.isUnstaked;

        if (isUnstaked) {
            ethReward = 0;
            usdtReward = 0;    
        } else {
            ethReward = _calcEthReward(user, idStake);
            usdtReward = _calcUsdtReward(user, idStake);
        }

        return (timestamp, stakedAmount, ethReward, usdtReward, isUnstaked);
    }

    // staking func

    function stake(uint stakedAmount) public payable whenNotPaused {
        require(msg.sender != owner, "Owner cannot stake");
        require(stakedAmount >= minAmountToStake, "Need to stake more token");
        require(totalStaked + stakedAmount <= (10 ** 28), "Reach limit of pool");

        uint platformFee = feeCalculator(stakedAmount);

        require(msg.value >= platformFee);
        require(_deliverTokensFrom(msg.sender, address(this), stakedAmount), "Failed to transfer from staker to StakBank");

        uint current = block.timestamp;

        if (!_isHolder(msg.sender)) {
            stakeHolder.push(msg.sender);
            stakeHolderPosInArray[msg.sender] = stakeHolder.length;
        }

        _createNewRequest(msg.sender, current, stakedAmount);

        address payable admin = address(uint160(address(owner)));
        admin.transfer(platformFee);

        emit UserStaked(msg.sender, _eStaker[msg.sender].length, stakedAmount, current);
    }

    function unstakeWithId(uint idStake) public whenNotPaused {
        // idStake count from 1
        require(_isHolder(msg.sender), "Not a Staker");

        require(!_isUnstaked(msg.sender, idStake), "idStake unstaked");

        Request memory request = _eStaker[msg.sender][idStake - 1];
        
        uint ethReward = _calcEthReward(msg.sender, idStake);
        uint usdtReward = _calcUsdtReward(msg.sender, idStake);

        if (ethReward != 0) {
            address payable staker = address(uint160(address(msg.sender)));
            staker.transfer(ethReward);
        }

        if (usdtReward != 0) {
            _transferUSDT(msg.sender, usdtReward);
        }

        _rewardedEth = _rewardedEth.sub(ethReward);
        _rewardedUsdt = _rewardedUsdt.sub(usdtReward);

        _unstakeId(msg.sender, idStake);
        _deliverTokens(msg.sender, request.stakedAmount);

        if (stakingOf(msg.sender) == 0) {
            _deleteStaker(msg.sender);
        }

        emit UserUnstakedWithId(msg.sender, idStake, ethReward, usdtReward);
    }

    function unstakeAll() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _unstakeAll(msg.sender);
    }

    function withdrawReward() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _withdrawReward(msg.sender);
    }

    function rewardDistribution() public onlyOwner whenNotPaused {
        require(countdownToNextDistribution() == 0, "Wait more time to trigger function");
        require(totalStaked != 0, "0 JST in pool");

        uint current = block.timestamp;
        uint ethToReward = numEthToReward();
        uint usdtToReward = numUsdtToReward();


        (uint pTime, uint stdTime) = _changeToAnotherUnitTime(periodTime);
        uint totalUnit = _hardcoin.mul(pTime);

        uint addUnitSoftcoin = (_softcoin.mul(current)).sub(_totalSoftcoinxTime);
        addUnitSoftcoin = addUnitSoftcoin.div(stdTime);

        totalUnit = totalUnit.add(addUnitSoftcoin);

        uint virtualEthUnitValue = (ethToReward.mul(MAXN)).div(totalUnit);
        uint virtualUsdtUnitValue = ((usdtToReward.mul(MAXN)).div(totalUnit));

        DetailDistribution memory lastDetail = _detailDistribution[ numberDistribution ];

        numberDistribution ++;

        _detailDistribution[ numberDistribution ] = DetailDistribution(current, stdTime, virtualEthUnitValue, virtualUsdtUnitValue,
                                                                    virtualEthUnitValue.mul(pTime) + lastDetail.cummVirtualEthUnitValuexTime, 
                                                                    virtualUsdtUnitValue.mul(pTime) + lastDetail.cummvirtualUsdtUnitValuexTime);

        // reset
        lastDis = block.timestamp;
        _hardcoin = _hardcoin.add(_softcoin);
        _softcoin = 0;
        _totalSoftcoinxTime = 0;

        _rewardedEth = address(this).balance;
        _rewardedUsdt = _usdtBalanceOf(address(this));

        emit AdminDistributeReward(ethToReward, usdtToReward);
    }

    // private staking func

    function _unstakeId(address user, uint idStake) private {
        Request memory request = _eStaker[user][idStake - 1];
        uint stakedAmount = request.stakedAmount;

        _staking[user] = _staking[user].sub(stakedAmount);
        _eStaker[user][idStake - 1].isUnstaked = true;
        
        totalStaked = totalStaked.sub(stakedAmount);
        if (numberDistribution < request.firstDistId) {
            _softcoin = _softcoin.sub(stakedAmount);
            _totalSoftcoinxTime = _totalSoftcoinxTime.sub(stakedAmount.mul(request.timestamp));
        } else {
            _hardcoin = _hardcoin.sub(stakedAmount);
        }
    }

    function _unstakeAll(address user) private {
        _withdrawReward(user);

        uint totalStakedAmount = stakingOf(user);

        for(uint i = 0; i < _eStaker[user].length; i++) {
            if (!_isUnstaked(user, i + 1)) {
                _unstakeId(user, i + 1);
            }
        }

        _deliverTokens(user, totalStakedAmount);
        _deleteStaker(user);
        
        emit UserUnstakedAll(user);
    }

    function _withdrawReward(address user) private {
        uint ethReward = 0;
        uint usdtReward = 0;

        for(uint i = 0; i < _eStaker[user].length; i++) {
            Request memory request = _eStaker[user][i];

            if ((request.isUnstaked) || (numberDistribution < request.firstDistId)) {
                continue;
            }

            ethReward = ethReward.add( _calcEthReward(user, i + 1) );
            usdtReward = usdtReward.add( _calcUsdtReward(user, i + 1) );

            _eStaker[user][i].firstDistId = 0;
            _eStaker[user][i].lastWithdrawDistId = numberDistribution;
        }

        if (ethReward != 0) {
            address payable staker = address(uint160(address(user)));
            staker.transfer(ethReward);

            _rewardedEth = _rewardedEth.sub(ethReward);
        }

        if (usdtReward != 0) {
            _transferUSDT(user, usdtReward);

            _rewardedUsdt = _rewardedUsdt.sub(usdtReward);
        }

        emit UserWithdrawedReward(user, ethReward, usdtReward);
    }
    
    // helper func

    function _createNewRequest(address user, uint current, uint stakedAmount) private {
        _staking[user] = _staking[user].add(stakedAmount);
        totalStaked = totalStaked.add(stakedAmount);
        _softcoin = _softcoin.add(stakedAmount);
        _totalSoftcoinxTime = _totalSoftcoinxTime.add(stakedAmount.mul(current));

        Request memory request = Request(current, stakedAmount, numberDistribution + 1, numberDistribution + 1, false);
        _eStaker[user].push(request);
    }

    function _deleteStaker(address user) private {
        uint posInArray = stakeHolderPosInArray[user];
        stakeHolder[posInArray - 1] = stakeHolder[ stakeHolder.length - 1 ];
        stakeHolderPosInArray[ stakeHolder[posInArray - 1] ] = posInArray;
        stakeHolder.pop();

        delete _eStaker[user];
        delete stakeHolderPosInArray[user];

        // use remain money to reward in next distribution
        if (totalStaked == 0) {
            _rewardedEth = 0;
            _rewardedUsdt = 0;
        }
    }

    function _calcEthReward(address user, uint idStake) private view returns (uint) {
        Request memory request = _eStaker[user][idStake - 1];
        
        uint firstDisId = request.firstDistId;
        if (firstDisId > numberDistribution) return 0;

        uint stakedAmount = request.stakedAmount;
        uint lastWithdrawDistId = request.lastWithdrawDistId;

        uint _cummVirtual = _detailDistribution[numberDistribution].cummVirtualEthUnitValuexTime
                                - _detailDistribution[lastWithdrawDistId].cummVirtualEthUnitValuexTime;

        uint money = stakedAmount.mul(_cummVirtual);

        if (firstDisId != 0) {
            // calc firstDis
            uint virtualFirst = _detailDistribution[firstDisId].virtualEthUnitValue; 

            uint time = ((_detailDistribution[firstDisId].timestamp).sub(request.timestamp));

            virtualFirst = virtualFirst.mul(time).div(_detailDistribution[firstDisId].stdTime);

            money = money.add(stakedAmount.mul(virtualFirst));
        }

        money = money.div(MAXN);
        return money;
    }

    function _calcUsdtReward(address user, uint idStake) private view returns (uint) {
        Request memory request = _eStaker[user][idStake - 1];
        
        uint firstDisId = request.firstDistId;
        if (firstDisId > numberDistribution) return 0;

        uint stakedAmount = request.stakedAmount;
        uint lastWithdrawDistId = request.lastWithdrawDistId;

        uint _cummVirtual = _detailDistribution[numberDistribution].cummvirtualUsdtUnitValuexTime
                                - _detailDistribution[lastWithdrawDistId].cummvirtualUsdtUnitValuexTime;

        uint money = stakedAmount.mul(_cummVirtual);

        if (firstDisId != 0) {
            // calc firstDis
            uint virtualFirst = _detailDistribution[firstDisId].virtualUsdtUnitValue; 

            uint time = ((_detailDistribution[firstDisId].timestamp).sub(request.timestamp));

            virtualFirst = virtualFirst.mul(time).div(_detailDistribution[firstDisId].stdTime);

            money = money.add(stakedAmount.mul(virtualFirst));
        }

        money = money.div(MAXN);
        return money;
    }


    function _deliverTokensFrom(address from, address to, uint amount) private returns (bool) {
        IERC20(token).transferFrom(from, to, amount);
        return true;    
    }

    function _deliverTokens(address to, uint amount) private returns (bool) {
        IERC20(token).transfer(to, amount);
        return true;
    }

    function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _transferUSDT(address to, uint value) private {
        _safeTransfer(usdt, to, value);
    }

    // private view

    function _isHolder(address holder) private view returns (bool) {
        return (_staking[holder] != 0);
    }

    function _isUnstaked(address user, uint idStake) private view returns (bool) {
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");
        return (_eStaker[user][idStake - 1].isUnstaked);
    }

    function _usdtBalanceOf(address user) private view returns (uint) {
        IERC20 USDT = IERC20(usdt);
        return USDT.balanceOf(user);
    }

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

    // close stakbank

    function closeStakBank(uint number) public onlyOwner whenNotPaused {
        require(number <= numberOfStakeHolder(), "larger than number staker in the pool");

        require(numberOfStakeHolder() != 0, "no have any staker in the pool");

        for (uint i = number - 1; i >= 0; i--) {
            _unstakeAll(stakeHolder[i]);
        }
        
        if (numberOfStakeHolder() == 0) {
            address payable admin = address(uint160(address(owner)));
            admin.transfer(address(this).balance);

            _transferUSDT(owner, _usdtBalanceOf(address(this)));
        }
    }

}