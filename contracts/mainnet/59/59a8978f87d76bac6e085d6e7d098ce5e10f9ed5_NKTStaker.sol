/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

abstract contract NKTContract {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}

abstract contract NKTStoreContract {
    function getStoreBalance() external virtual returns (uint256);
    function giveReward(address recipient, uint256 amount) external virtual returns (bool);
    function withdrawAll(address recipient) external virtual returns (bool);
}

contract NKTStaker is Ownable {
    using SafeMath for uint256;

    NKTContract private _mainTokenContract;                 // main token contract
    NKTStoreContract private _storeWalletContract;          // store wallet contract

    mapping (address => uint256) private _stakedBalances;   // map for stacked balances
    mapping (address => uint256) private _rewards;          // map for rewards
    
    address private _devWallet;                             // dev wallet address
    address[] private _stakers;                             // staker's array
    
    uint256 private _totalStackedAmount = 0;                // total stacked amount
    uint256 private _minStakeAmount = 20e18;                // min stackable amount
    
    uint256 private _rewardPeriod = 3600;                  // seconds of a day
    uint256 private _rewardPortion = 100;                  // reward portion = 1/100
    
    uint256 private _rewardFee = 98;                        // reward fee 98%, rest for dev 2%

    uint256 private _taxFee = 2;                            // tax fee for transaction
    
    uint256 private _minRewardPeriod = 3600;                // min reward period = 1 hour (3600s)
    
    uint256 private _lastTimestamp; // last timestamp that distributed rewards
    
    // Events
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event Claim(address staker, uint256 amount);
    
    constructor (NKTContract mainTokenContract, address devWallet) public {
        _mainTokenContract = mainTokenContract;
        _devWallet = devWallet;
        
    }
    
    function stake(uint256 amount) external {
        require(
            amount >= _minStakeAmount,
            "Too small amount"
        );

        require(
            _mainTokenContract.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "Stake failed"
        );
        
        uint256 taxAmount = amount.mul(_taxFee).div(100);
        uint256 stackedAmount = amount.sub(taxAmount);
        
        if(_stakers.length == 0)
            _lastTimestamp = uint256(now);

        if(_stakedBalances[_msgSender()] == 0)
            _stakers.push(_msgSender());
            
        _stakedBalances[_msgSender()] = _stakedBalances[_msgSender()].add(stackedAmount);
        _totalStackedAmount = _totalStackedAmount.add(stackedAmount);
        
        emit Staked(_msgSender(), stackedAmount);
    }
    
    function unstake(uint256 amount) external {
        require(
            _stakedBalances[_msgSender()] >= amount,
            "Unstake amount exceededs the staked amount."
        );


        require(
            _mainTokenContract.transfer(
                _msgSender(),
                amount
            ),
            "Unstake failed"
        );
        
        _stakedBalances[_msgSender()] = _stakedBalances[_msgSender()].sub(amount);
        _totalStackedAmount = _totalStackedAmount.sub(amount);
        
        if(_stakedBalances[_msgSender()] == 0) {
            for(uint i=0; i<_stakers.length; i++) {
                if(_stakers[i] == _msgSender()) {
                    _stakers[i] = _stakers[_stakers.length-1];
                    _stakers.pop();
                    break;
                }
            }
        }
        emit Unstaked(_msgSender(), amount);
        
        uint256 rewardsAmount = _rewards[_msgSender()];
        if(rewardsAmount > 0) {
            require(
                _storeWalletContract.giveReward(_msgSender(), rewardsAmount),
                "Claim failed."
            );
            _rewards[_msgSender()] = 0;
    	    emit Claim(_msgSender(), rewardsAmount);
        }
    }
    
    function claim(uint256 amount) external {
        require(
            _rewards[_msgSender()] >= amount,
            "Claim amount exceededs the pendnig rewards."
        );
        
        require(
            _storeWalletContract.giveReward(_msgSender(), amount),
            "Claim failed."
        );
        
        _rewards[_msgSender()] = _rewards[_msgSender()].sub(amount);
	    emit Claim(_msgSender(), amount);
    }
    
    function endStake() external {
        uint256 rewardsAmount = _rewards[_msgSender()];
        if(rewardsAmount > 0) {
            require(
                _storeWalletContract.giveReward(_msgSender(), rewardsAmount),
                "Claim failed."
            );
            _rewards[_msgSender()] = 0;
    	    emit Claim(_msgSender(), rewardsAmount);
        }
	    
	    uint256 unstakeAmount = _stakedBalances[_msgSender()];
	    if(unstakeAmount > 0) {
	        require(
                _mainTokenContract.transfer(
                    _msgSender(),
                    unstakeAmount
                ),
                "Unstake failed"
            );
        
	        _stakedBalances[_msgSender()] = 0;
            _totalStackedAmount = _totalStackedAmount.sub(unstakeAmount);
        
            for(uint i=0; i<_stakers.length; i++) {
                if(_stakers[i] == _msgSender()) {
                    _stakers[i] = _stakers[_stakers.length-1];
                    _stakers.pop();
                    break;
                }
            }
            emit Unstaked(_msgSender(), unstakeAmount);
	    }
    }
    
    function calcRewards() external {
        uint256 currentTimestamp = uint256(now);
        uint256 diff = currentTimestamp.sub(_lastTimestamp);
        if(diff >= _rewardPeriod) {
            uint256 rewardDays = diff.div(_rewardPeriod);
            uint256 offsetTimestamp = diff.sub(_rewardPeriod.mul(rewardDays));
            
            uint256 _storeBalance = _storeWalletContract.getStoreBalance();

            for(uint j=0; j<rewardDays; j++) {
                uint256 _totalRewardsAmount = _storeBalance.div(_rewardPortion);

                if(_totalRewardsAmount > 0) {
                    uint256 _rewardForStaker = _totalRewardsAmount.mul(_rewardFee).div(100);
                    uint256 _rewardForDev = _totalRewardsAmount.sub(_rewardForStaker);
                    
                    for(uint i=0; i<_stakers.length; i++) {
                        if(_stakers[i] != address(0)) {
                            _rewards[_stakers[i]] = _rewards[_stakers[i]].add(_stakedBalances[_stakers[i]].mul(_rewardForStaker).div(_totalStackedAmount));
                        }
                    }
                    
                    if(_rewardForDev > 0)
                        _storeWalletContract.giveReward(_devWallet, _rewardForDev);
                }
                _storeBalance = _storeBalance.sub(_totalRewardsAmount);
            }
            
            _lastTimestamp = currentTimestamp.sub(offsetTimestamp);
        }
    }
    
    function withdrawAllFromStore(address recipient) external onlyOwner returns (bool) {
        require(
            recipient != address(0) && recipient != address(this),
            "Should be valid address."
        );
        
        _storeWalletContract.withdrawAll(recipient);
    }
    
    /**
     * Get store wallet
     */
    function getStoreWalletContract() external view returns (address) {
        return address(_storeWalletContract);
    }
     
    /**
     * Get total stacked amount
     */
    function getTotalStackedAmount() external view returns (uint256) {
        return _totalStackedAmount;
    }
    
    /**
     * Get reward amount of staker
     */
    function getRewardOfAccount(address staker) external view returns (uint256) {
        return _rewards[staker];
    }
    
    /**
     * Get stacked amount of staker
     */
    function getStakeAmountOfAccount(address staker) external view returns (uint256) {
        return _stakedBalances[staker];
    }
    
    /**
     * Get min stake amount
     */
    function getMinStakeAmount() external view returns (uint256) {
        return _minStakeAmount;
    }
    
    /**
     * Get rewards period
     */
    function getRewardPeriod() external view returns (uint256) {
        return _rewardPeriod;
    }
    
    /**
     * Get rewards portion
     */
    function getRewardPortion() external view returns (uint256) {
        return _rewardPortion;
    }
    
    /**
     * Get last timestamp that countdown for rewards started
     */
    function getLastTimestamp() external view returns (uint256) {
        return _lastTimestamp;
    }
    
    /**
     * Get staker count
     */
    function getStakerCount() external view returns (uint256) {
        return _stakers.length;
    }
    
     /**
     * Get rewards fee
     */
    function getRewardFee() external view returns (uint256) {
        return _rewardFee;
    }
    
    /**
     * Set store wallet contract address
     */
    function setStoreWalletContract(NKTStoreContract storeWalletContract) external onlyOwner returns (bool) {
        require(address(storeWalletContract) != address(0), 'store wallet contract should not be zero address.');

        _storeWalletContract = storeWalletContract;
        return true;
    }
    
    /**
     * Set reward period
     */
    function setRewardPeriod(uint256 rewardPeriod) external onlyOwner returns (bool) {
        require(rewardPeriod >= _minRewardPeriod, 'reward period should be above min reward period.');

        _rewardPeriod = rewardPeriod;
        return true;
    }

    /**
     * Set rewards portion in store balance. 
     * ex: 1000 => rewardsAmount of one period equals storeAmount.div(1000)
     */
    function setRewardPortion(uint256 rewardPortion) external onlyOwner returns (bool) {
        require(rewardPortion >= 1, 'reward portion should be above 1');

        _rewardPortion = rewardPortion;
        return true;
    }
    
    /**
     * Set rewards portion for stakers in rewards amount. 
     * ex: 98 => 98% (2% for dev)
     */
    function setRewardFee(uint256 rewardFee) external onlyOwner returns (bool) {
        require(rewardFee >= 96 && rewardFee <= 100, 'reward fee should be in 96 ~ 100' );

        _rewardFee = rewardFee;
        _taxFee = uint256(100).sub(_rewardFee);
        return true;
    }
}