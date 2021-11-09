// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PerpetualOption.sol";


contract SwapFarm is Configurable, ContextUpgradeSafe, Constants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';
	bytes32 internal constant _ecoAddr_         = 'ecoAddr';
	bytes32 internal constant _ecoRatio_        = 'ecoRatio';

    address public WETH;
    address public swapFactory;
    address public factory;
    address public rewardsToken;
    address public distributor;
    address public dao;

	mapping (address => uint) public quota;
	mapping (address => uint) public lep;                // 1: linear, 2: exponential, 3: power
	mapping (address => uint) public period;
	mapping (address => uint) public begin;
    mapping (address => uint) public rewardsDuration;
    mapping (address => uint) public periodFinish;
    mapping (address => uint) public feeBuffer;
    mapping (address => uint) public rewardBuffer;
    mapping (address => uint) public lastUpdateTime;                        // currency => 

    mapping (address => mapping (address => uint)) public swapFees;         // account => currency =>
    mapping (address => mapping (address => uint)) public rewards;
    mapping (address => mapping (address => uint)) public paid;

    function __SwapFarm_init(address governor_, address WETH_, address swapFactory_, address factory_, address rewardsToken_, address distributor_, address dao_, address ecoAddr_) external initializer {
        __Governable_init_unchained(governor_);
        __SwapFarm_init_unchained(WETH_, swapFactory_, factory_, rewardsToken_, distributor_, dao_, ecoAddr_);
    }
    
    function __SwapFarm_init_unchained(address WETH_, address swapFactory_, address factory_, address rewardsToken_, address distributor_, address dao_, address ecoAddr_) public governance {
        WETH        = WETH_;
        swapFactory = swapFactory_;
        factory     = factory_;
        rewardsToken= rewardsToken_;
        distributor = distributor_;
        dao         = dao_;
        config[_ecoAddr_]   = uint(ecoAddr_);
        config[_ecoRatio_]  = 0.1e18;
    }

    function notifyRewardBegin(address currency_, uint quota_, uint lep_, uint period_, uint span_, uint begin_) public governance {
        quota[currency_]            = quota_;
        lep[currency_]              = lep_;         // 1: linear, 2: exponential, 3: power
        period[currency_]           = period_;
        rewardsDuration[currency_]  = span_;
        begin[currency_]            = begin_;
        periodFinish[currency_]     = begin_.add(span_);
        rewardBuffer[currency_]     = rewardQuota(currency_).mul(period_).div(span_);
        lastUpdateTime[currency_]   = begin_;
    }

    function _msgDataWithoutSelector() internal view returns (bytes memory data) {
        data = new bytes(_msgData().length - 4);
        assembly {
            calldatacopy(add(data, 0x20), 4, sub(calldatasize(), 4))
        }
    }
    
    function _genData0() internal view returns (bytes memory data) {
        (address underlying, address currency, , , , , int undMax, int curMax) = abi.decode(_msgDataWithoutSelector(), (address, address, uint, uint, int, int, int, int));
        return abi.encode(_msgSender(), underlying, currency, undMax, curMax);
    }

    function _genData1() internal view returns (bytes memory data) {
        (address underlying, address currency, , , , , , ) = abi.decode(_msgDataWithoutSelector(), (address, address, uint, uint, int, int, int, int));
        return abi.encode(_msgSender(), underlying, currency, int(uint(-1)/2), int(uint(-1)/2));
    }

    function _transfer(address sender, address undOrCur, int vol, int max) internal {
        address WETH_ = WETH;
        uint v = Math.abs(vol);
        if(vol < 0) {
            require(vol <= max, _slippage_too_high_);
            if(undOrCur != WETH_ && sender != address(this))
                IERC20(undOrCur).safeTransfer(sender, v);
        } else if(vol > 0) {
            uint b = IERC20(undOrCur).balanceOf(address(this));
            require(vol <= max, _slippage_too_high_);
            if(b < v)
                IERC20(undOrCur).safeTransferFrom(sender, address(this), v.sub(b));
            else if(b > v && undOrCur != WETH_)
                IERC20(undOrCur).safeTransfer(sender, b.sub(v));
            IERC20(undOrCur).safeApprove2(factory, v);
        }
    }

    function onFlashSwap(address call, address put, int dCall, int dPut, int dUnd, int dCur, bytes memory data) external {
        require(_msgSender() == factory, 'only Factory');
        (address payable sender, address underlying, address currency, int undMax, int curMax) = abi.decode(data, (address, address, address, int, int));

        if(dUnd < 0)
            _transfer(underlying == WETH ? address(this) : sender, underlying, dUnd, undMax);
        if(dCur < 0)
            _transfer(currency   == WETH ? address(this) : sender, currency,   dCur, curMax);

        if(dCall > 0)
            IERC20(call).transfer(sender, uint(dCall));
        if(dPut > 0)
            IERC20(put ).transfer(sender, uint(dPut ));

        if(dCall < 0)
            Factory(factory).transferAuth_(call, sender, address(this), uint(-dCall));
        if(dPut < 0)
            Factory(factory).transferAuth_(put , sender, address(this), uint(-dPut));

        if(dUnd > 0)
            _transfer(sender, underlying, dUnd, undMax);
        if(dCur > 0)
            _transfer(sender, currency,   dCur, curMax);
    }

    function swap(address underlying, address currency, uint priceFloor, uint priceCap, int dCall, int dPut, int undMax, int curMax, uint nLoop) public payable returns (uint reward) {
        require(!_msgSender().isContract() || config[_allowContract_] != 0 || getConfigA(_allowlist_, _msgSender()) != 0, 'No allowContract');

        uint fee = calcFee(underlying, currency, priceFloor, priceCap, dCall, dPut).mul(nLoop);

        if(msg.value > 0)
            IWETH(WETH).deposit{value: msg.value}();
        
        for(uint i=0; i<nLoop; i++)
            if(i % 2 == 0)
                Factory(factory).swap(underlying, currency, priceFloor, priceCap,  dCall,  dPut, int(uint(-1)/2), int(uint(-1)/2), _genData0());
            else
                Factory(factory).swap(underlying, currency, priceFloor, priceCap, -dCall, -dPut, int(uint(-1)/2), int(uint(-1)/2), _genData1());

        uint value = IERC20(WETH).balanceOf(address(this));
        if(value > 0) {
            IWETH(WETH).withdraw(value);
            _msgSender().transfer(value);
        }
        undMax;     curMax;
        
        reward = _swapFarming(currency, fee);
        
        if(dao != address(0)) {
            uint rwd = _getReward(_msgSender(), currency, address(this));
            IERC20(rewardsToken).approve(dao, rwd);
            IStakingPool(dao).stakeTo(rwd, _msgSender());
        }
    }
    
    function calcFee(address underlying, address currency, uint priceFloor, uint priceCap, int dCall, int dPut) public view returns (uint fee) {
        address call = Factory(factory).calls(underlying, currency, priceFloor, priceCap);
        address put  = Factory(factory).puts (underlying, currency, priceFloor, priceCap);
        require(put != address(0), 'Not exist Bull/Bear Token');                                            // single check is sufficient

        (int dUnd, int dCur, , ) = Factory(factory).calcDelta(priceFloor, priceCap, Call(call).totalSupply(), Put(put).totalSupply(), dCall, dPut);

        uint feeRate = Factory(factory).feeRate();
        fee = Math.abs(dUnd).mul(feeRate).div(1e18);
        
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(IUniswapV2Factory(swapFactory).getPair(underlying, currency)).getReserves();
        fee =  currency < underlying ? fee.mul(reserve0) / reserve1 : fee.mul(reserve1) / reserve0;
        
        fee = fee.add(Math.abs(dCur).mul(feeRate).div(1e18));
    }
    
    function _swapFarming(address currency, uint fee) internal returns (uint reward) {
        if(begin[currency] == 0 || begin[currency] >= now || lastUpdateTime[currency] >= now)
            return 0;

        uint rwdEco;
        (reward, rwdEco, rewardBuffer[currency], feeBuffer[currency]) = _swapFarmingable(currency, fee);

        quota[currency] = quota[currency].sub0(reward.add(rwdEco));
        rewards[address(0)][address(0)] = rewards[address(0)][address(0)].add(reward.add(rwdEco));
        rewards[address(config[_ecoAddr_])][currency] = rewards[address(config[_ecoAddr_])][currency].add(rwdEco);
        rewards[_msgSender()][currency] = rewards[_msgSender()][currency].add(reward);
        
        swapFees[_msgSender()][currency] = swapFees[_msgSender()][currency].add(fee);
        swapFees[address( 0 )][currency] = swapFees[address( 0 )][currency].add(fee);
        lastUpdateTime[currency] = now;
        emit SwapFarming(_msgSender(), currency, fee, reward);
    }
    event SwapFarming(address indexed sender, address indexed currency, uint fee, uint reward);
    
    function _swapFarmingable(address currency, uint fee) internal view returns (uint reward, uint rwdEco, uint rwdBuf, uint feeBuf) {
        if(begin[currency] == 0 || begin[currency] >= now || lastUpdateTime[currency] >= now)
            return (0, 0, 0, 0);

        if(now < begin[currency].add(period[currency])) {
            feeBuf = feeBuffer[currency].mul(lastUpdateTime[currency].sub(begin[currency]));
            feeBuf = feeBuf.div(period[currency]).add(fee);
            feeBuf = feeBuf.mul(period[currency].add(now).sub(lastUpdateTime[currency]));
            feeBuf = feeBuf.div(now.sub(begin[currency]));
        } else
            feeBuf = feeBuffer[currency].add(fee);
        rwdBuf = rewardBuffer[currency].add(rewardDelta(currency));
        reward = rwdBuf.mul(fee).div(feeBuf);
        feeBuf = feeBuf.mul(period[currency]).div(period[currency].add(now).sub(lastUpdateTime[currency]));
        rwdBuf = rwdBuf.sub(reward);
        
        if(config[_ecoAddr_] != 0) {
            rwdEco = reward.mul(config[_ecoRatio_]).div(1e18);
            reward = reward.sub(rwdEco);
        }
    }
    
    function swapFarmingable(address currency, uint fee) external view returns (uint reward) {
        (reward, , , ) = _swapFarmingable(currency, fee);
    }
    
    function rewardQuota(address currency) public view returns (uint) {
        return Math.min(quota[currency], Math.min(IERC20(rewardsToken).allowance(distributor, address(this)), IERC20(rewardsToken).balanceOf(distributor)).sub0(rewards[address(0)][address(0)]));
    }
    
    function rewardDelta(address currency) public view returns (uint amt) {
        if(begin[currency] == 0 || begin[currency] >= now || lastUpdateTime[currency] >= now)
            return 0;
            
        amt = rewardQuota(currency);
        
        if(lep[currency] == 3) {                                                              // power
            uint amt2 = amt.mul(lastUpdateTime[currency].add(rewardsDuration[currency]).sub(begin[currency])).div(now.add(rewardsDuration[currency]).sub(begin[currency]));
            amt = amt.sub(amt2);
        } else if(lep[currency] == 2) {                                                       // exponential
            if(now.sub(lastUpdateTime[currency]) < rewardsDuration[currency])
                amt = amt.mul(now.sub(lastUpdateTime[currency])).div(rewardsDuration[currency]);
        }else if(now < periodFinish[currency])                                                // linear
            amt = amt.mul(now.sub(lastUpdateTime[currency])).div(periodFinish[currency].sub(lastUpdateTime[currency]));
        else if(lastUpdateTime[currency] >= periodFinish[currency])
            amt = 0;
    }
    
    function earned(address account, address currency) public view returns (uint) {
        return rewards[account][currency];
    }

    function getReward(address currency) public {
        getRewardA(_msgSender(), currency);
    }
    function getRewardA(address payable acct, address currency) public {
        _getReward(acct, currency, acct);
    }
    function _getReward(address payable acct, address currency, address to) internal returns(uint reward) {
        reward = rewards[acct][currency];
        if (reward > 0) {
            rewards[acct][currency] = 0;
            rewards[address(0)][address(0)] = rewards[address(0)][address(0)].sub0(reward);
            paid[acct][currency] = paid[acct][currency].add(reward);
            paid[address(0)][currency] = paid[address(0)][currency].add(reward);
            IERC20(rewardsToken).safeTransferFrom(distributor, to, reward);
            emit RewardPaid(acct, currency, reward);
        }
    }
    event RewardPaid(address indexed user, address indexed currency, uint256 reward);

    function getRewardAs(address payable acct, address[] calldata currencys) external {
        for(uint i=0; i<currencys.length; i++)
            getRewardA(acct, currencys[i]);
    }
    
    // Reserved storage space to allow for layout changes in the future.
    uint256[32] private ______gap;
}


interface IStakingPool {
    function stakeTo(uint256 amount, address to) external;
}