// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract LpStaking is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using Address for address;

    uint256 private _startedStakeTime;
    uint256 private _stakedPeriod = 104 weeks;
    uint256 public _totalStakedAmount;
    uint256 public _totalStakedLpAmount;

    uint16[100] _multipliers = [
        100, 104, 108, 112, 115, 119, 122, 125, 128, 131,
        134, 136, 139, 142, 144, 147, 149, 152, 154, 157,
        159, 161, 164, 166, 168, 170, 173, 175, 177, 179,
        181, 183, 185, 187, 189, 191, 193, 195, 197, 199,
        201, 203, 205, 207, 209, 211, 213, 214, 216, 218,
        220, 222, 223, 225, 227, 229, 230, 232, 234, 236,
        237, 239, 241, 242, 244, 246, 247, 249, 251, 252,
        254, 255, 257, 259, 260, 262, 263, 265, 267, 268,
        270, 271, 273, 274, 276, 277, 279, 280, 282, 283,
        285, 286, 288, 289, 291, 292, 294, 295, 297, 298
    ];

    uint128 private constant MIN_LOCK_DURATION = uint128(4);
    uint128 private constant MAX_LOCK_DURATION = uint128(104);

    address public _tokenAddress;
    address public _pairAddress;

    struct StakeInfo {
        uint256 amount;
        uint256 stakedTime;
        uint128 lockWeek;
    }

    mapping(address => StakeInfo[]) public _stakers;

    event Staked(address indexed user, uint256 lpAmount);
    event Withdraw(address indexed user, uint256 lpAmount, uint256 tokenAmount);

    constructor() {
    }

    function start() public onlyOwner {
        _startedStakeTime = block.timestamp;
    }

    function setTokenAddress(address tokenAddress) public onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setPairAddress(address pairAddress) public onlyOwner {
        _pairAddress = pairAddress;
    }

    function getPeriod(uint256 from, uint256 to) private pure returns (uint256) {
        return to.sub(from);
    }

    function calcMultiplier(uint256 numOfWeeks) public view returns (uint256) {
        if (numOfWeeks < 4) {
            return 0;
        } else if (numOfWeeks >= 104) {
            return 300;
        } else {
            return uint256(_multipliers[numOfWeeks - 4]);
        }
    }

    function getCuttPerBlockForReward() public view returns (uint256) {
        if (_totalStakedAmount == 0) {
            return 0;
        } else {
            return
                IBEP20(_tokenAddress)
                    .balanceOf(address(this))
                    .mul(1 ether)
                    .div(_totalStakedAmount)
                    .div(_stakedPeriod);
        }
    }

    function getStakedAmount(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        StakeInfo[] memory staker = _stakers[account];
        return staker[index].amount.mul(calcMultiplier(staker[index].lockWeek));
    }

    function getStakedPeriod(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        StakeInfo[] memory staker = _stakers[account];
        uint256 stakedPeriod = getPeriod(staker[index].stakedTime, block.timestamp);
        return stakedPeriod;
    }

    function getStakedCount(address account)
        public
        view
        returns (uint256)
    {
        StakeInfo[] memory staker = _stakers[account];
        return staker.length;
    }

    function getReward(address account, uint256 index)
        public
        view
        returns (uint256)
    {
        if (getStakedAmount(account, index) <= 0 || _startedStakeTime <= 0) {
            return 0;
        }
        StakeInfo[] memory staker = _stakers[account];
        uint256 stakedPeriod =
            getPeriod(staker[index].stakedTime, block.timestamp);

        if (block.timestamp >= _startedStakeTime.add(_stakedPeriod)) {
            stakedPeriod = getPeriod(
                staker[index].stakedTime,
                _startedStakeTime.add(_stakedPeriod)
            );
        }

        if (stakedPeriod <= 0) {
            return 0;
        }

        uint256 rewardPerblock = getCuttPerBlockForReward();

        uint256 reward =
            rewardPerblock
                .mul(getStakedAmount(account, index))
                .mul(stakedPeriod)
                .div(1 ether);

        return reward;
    }

    function stake(uint256 amount, uint128 lockWeek) public nonReentrant {
        require(!_msgSender().isContract(), "Stake: Could not be contract.");
        require(
            lockWeek >= MIN_LOCK_DURATION && lockWeek <= MAX_LOCK_DURATION,
            "Stake: Invalid lock duration"
        );
        IBEP20(_pairAddress).transferFrom(_msgSender(), address(this), amount);

        StakeInfo[] storage staker = _stakers[_msgSender()];
        staker.push(
            StakeInfo({
                amount: amount,
                stakedTime: block.timestamp,
                lockWeek: lockWeek
            })
        );
        _totalStakedLpAmount = _totalStakedLpAmount.add(amount);
        _totalStakedAmount = _totalStakedAmount.add(
            amount.mul(calcMultiplier(lockWeek))
        );
        emit Staked(_msgSender(), amount);
    }

    function withdrawable(address account, uint256 index)
        public
        view
        returns (bool)
    {

        StakeInfo[] storage staker = _stakers[account];
        require(staker.length > index && index >= 0, "Stake: Invalid index.");

        uint256 stakedPeriod = getPeriod(staker[index].stakedTime, block.timestamp);

        return (stakedPeriod > uint256(staker[index].lockWeek).mul(1 weeks));
    }

    function withdraw(uint256 index, uint256 amount) public nonReentrant {
        require(!_msgSender().isContract(), "Stake: Could not be contract.");

        StakeInfo[] storage staker = _stakers[_msgSender()];
        require(staker.length > index && index >= 0, "Stake: Invalid index.");

        uint256 stakedPeriod = getPeriod(staker[index].stakedTime, block.timestamp);

        require(stakedPeriod > uint256(staker[index].lockWeek).mul(1 weeks));

        uint256 lpAmount = staker[index].amount;

        uint256 reward = getReward(_msgSender(), index);

        uint256 stakedAmount = getStakedAmount(_msgSender(), index);

        if (lpAmount > amount) {
            stakedAmount = stakedAmount.mul(amount).div(lpAmount);
            staker[index].amount = lpAmount.sub(amount);
        } else {
            amount = lpAmount;
            delete staker[index];
        }

        _totalStakedLpAmount = _totalStakedLpAmount.sub(amount);
        _totalStakedAmount = _totalStakedAmount.sub(stakedAmount);

        IBEP20(_pairAddress).transfer(_msgSender(), amount);

        IBEP20(_tokenAddress).transfer(_msgSender(), reward);

        emit Withdraw(_msgSender(), amount, reward);
    }
}