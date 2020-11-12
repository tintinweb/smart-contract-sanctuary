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

abstract contract ZSecTokenContract {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}

abstract contract ZSECStoreContract {
    function getStoreBalance() external view virtual returns (uint256);
    function giveReward(address recipient, uint256 amount) external virtual returns (bool);
}

contract ZSECStaker is Ownable {
    using SafeMath for uint256;

    ZSecTokenContract private _mainTokenContract;           // main token contract
    ZSECStoreContract private _storeWalletContract;         // store wallet contract

    struct _stakerData {
        uint256 startTimestamp;     // When the staking started in unix time (block.timesamp)
        uint256 lastTimestamp;      // When the last staking reward was claimed in unix time (block.timestamp)
        uint256 stackedAmount;      // Staked Amount
    }
    
    mapping (address => _stakerData) private _stakerMap;        // map for staker's data
    mapping (address => uint256) private _rewardsMap;           // map for rewards
    
    address private _devWallet;                                 // dev wallet address

    uint256 private _totalStackedAmount = 0;                    // total stacked amount
    uint256 private _minStakeAmount = 20e18;                    // min stackable amount
    
    uint256 private _rewardPeriod = 86400;                      //seconds of a day
    uint256 private _rewardPortion = 200;                       // reward portion  0.5% = 1/200
    
    uint256 private _rewardMaxDays = 60;                        // rewards max days
    uint256 private _minRewardPeriod = 3600;                    // min reward period = 1 hour (3600s)
    uint256 private _stakerCount;                               // staker count

    
    
    // Events
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event Claim(address staker, uint256 amount);
    
    constructor (ZSecTokenContract mainTokenContract) public {
        _mainTokenContract = mainTokenContract;
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
        
        if(_stakerMap[_msgSender()].stackedAmount == 0) {
            _stakerMap[_msgSender()].startTimestamp = uint256(now);
            _stakerMap[_msgSender()].lastTimestamp = uint256(now);
            _stakerCount = _stakerCount.add(uint256(1));
        }

        _stakerMap[_msgSender()].stackedAmount = _stakerMap[_msgSender()].stackedAmount.add(amount);
        _totalStackedAmount = _totalStackedAmount.add(amount);
        
        emit Staked(_msgSender(), amount);
    }
    
    function unstack(uint256 amount) external {
        require(
            _stakerMap[_msgSender()].stackedAmount >= amount,
            "Stake amount exceeded"
        );

        require(
            _mainTokenContract.transfer(
                _msgSender(),
                amount
            ),
            "Stake failed"
        );
        
        _stakerMap[_msgSender()].stackedAmount = _stakerMap[_msgSender()].stackedAmount.sub(amount);
        _totalStackedAmount = _totalStackedAmount.sub(amount);
        
        if(_stakerMap[_msgSender()].stackedAmount == 0) {
            _stakerCount = _stakerCount.sub(uint256(1));
        }
        
        emit Unstaked(_msgSender(), amount);
    }
    
    function claim(uint256 amount) external {
        require(
            _rewardsMap[_msgSender()] >= amount,
            "Claim amount exceeded"
        );
        
        _storeWalletContract.giveReward(_msgSender(), amount);
        _rewardsMap[_msgSender()] = _rewardsMap[_msgSender()].sub(amount);
        
        emit Claim(_msgSender(), amount);
    }
    
    function calcRewards() external returns (bool) {
        uint256 currentTimestamp = uint256(now);
        uint256 diff = currentTimestamp.sub(_stakerMap[_msgSender()].lastTimestamp);
        if(diff >= _rewardPeriod) {
            uint256 rewardDays = diff.div(_rewardPeriod);
            uint256 offsetTimestamp = diff.sub(_rewardPeriod.mul(rewardDays));

            if(rewardDays > _rewardMaxDays)
                return false;

            uint256 rewardsAmount = _stakerMap[_msgSender()].stackedAmount.div(_rewardPortion).mul(rewardDays);
            _rewardsMap[_msgSender()] = _rewardsMap[_msgSender()].add(rewardsAmount);
            
            _stakerMap[_msgSender()].lastTimestamp = currentTimestamp.sub(offsetTimestamp);
            
            return true;
        }
        return false;
    }
    
    /**
     * Get Functions 
     */
    function getStoreWalletContract() external view returns (address) {
        return address(_storeWalletContract);
    }
    
    function getTotalStackedAmount() external view returns (uint256) {
        return _totalStackedAmount;
    }
    
    function getRewardOfAccount(address staker) external view returns (uint256) {
        return _rewardsMap[staker];
    }
    
    function getStakeAmountOfAccount(address staker) external view returns (uint256) {
        return _stakerMap[staker].stackedAmount;
    }
    
    function getStakerCount() external view returns (uint256) {
        return _stakerCount;
    }
    
    function getMinStakeAmount() external view returns (uint256) {
        return _minStakeAmount;
    }
    
    function getRewardPeriod() external view returns (uint256) {
        return _rewardPeriod;
    }
    
    function getRewardPortion() external view returns (uint256) {
        return _rewardPortion;
    }
    
    function getStartTimestamp(address staker) external view returns (uint256) {
        return _stakerMap[staker].startTimestamp;
    }
    
    function getLastTimestamp(address staker) external view returns (uint256) {
        return _stakerMap[staker].lastTimestamp;
    }
    
    /**
     * Set Functions 
     */
    function setStoreWalletContract(ZSECStoreContract storeWalletContract) external onlyOwner returns (bool) {
        if(address(storeWalletContract) == address(0))
            return false;
            
        _storeWalletContract = storeWalletContract;
        return true;
    }
    
    function setRewardPeriod(uint256 rewardPeriod) external onlyOwner returns (bool) {
        if(rewardPeriod <= _minRewardPeriod)
            return false;
        
        _rewardPeriod = rewardPeriod;
        return true;
    }
    
    function setRewardPortion(uint256 rewardPortion) external onlyOwner returns (bool) {
        if(rewardPortion < 1)
            return false;

        _rewardPortion = rewardPortion;
        return true;
    }
}