// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract ImPlusToken is ERC20, Ownable {

    uint256 public totalStaking = 0;
    mapping (address => uint256) private _stakeBalances;

    IERC20 public im;
    using SafeMath for uint256;
    mapping(address => uint256) public startLockTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public rewards;
    uint256 public lockTime = 3 days;
    uint256 public staking_apy = 100;

    /**
     * @dev Emitted when `amount` tokens are staked in this contract
     *
     * Note that `amount` may be zero.
     */
    event Stake(address indexed from, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are withdrawn from this contract
     *
     * Note that `amount` may be zero.
     */
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @dev Emitted when `amount` reward tokens are taken from in this contract
     *
     * Note that `amount` may be zero.
     */
    event WithdrawnReward(address indexed to, uint256 amount);


    constructor(IERC20 _im) ERC20("Intelligent Mining Plus Token", "IM+") {
        im = _im;
    }

    function stake(uint256 _amount) external {
        calcReward();

        // Lock the IM in the contract
        bool lockSucceeded = im.transferFrom(_msgSender(), address(this), _amount);
        require(lockSucceeded == true, "Stake failed");

        startLockTime[_msgSender()] = block.timestamp;
        _stakeBalances[_msgSender()] += _amount;
        totalStaking += _amount;

        emit Stake(_msgSender(), _amount);
    }

    function withdrawn(uint256 _share) external {
        uint256 accountBalance = _stakeBalances[_msgSender()];
        require(accountBalance >= _share, "Withdrawn exceeds balance");
        require(_share != 0, "Withdrawn is zero");

        uint256 duration = block.timestamp.sub(startLockTime[_msgSender()]);
        require(duration >= lockTime, "IM Lock not expired yet");

        calcReward();
        _stakeBalances[_msgSender()] -= _share;
        totalStaking -= _share;
        bool withdrawnSucceeded = im.transfer(_msgSender(), _share);
        if (withdrawnSucceeded) {
            emit Withdrawn(_msgSender(), _share);
        }
    }

    function emergencyWithdrawn() external onlyOwner {
        uint256 contractTokenHold = im.balanceOf(address(this));
        uint256 lockFunds = contractTokenHold - totalStaking;
        require(lockFunds > 0, "No lock funds");

        im.transfer(owner(), lockFunds);
    }

    function withdrawnReward() external {
        calcReward();
        uint256 amount = rewards[_msgSender()];
        require(amount != 0, "Withdrawn reward is zero");

        rewards[_msgSender()] = 0;

        _mint(_msgSender(), amount);
        emit WithdrawnReward(_msgSender(), amount);
    }

    function calcReward() internal {
        uint256 lastReward = lastRewardTime[_msgSender()];
        lastRewardTime[_msgSender()] = block.timestamp;

        // We eligible for rewards
        if (lastReward != 0) {
            uint256 duration = block.timestamp.sub(lastReward);
            uint256 amount = _stakeBalances[_msgSender()].mul(staking_apy).mul(duration).div(100).div(365 days);
            rewards[_msgSender()] += amount;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function stakeBalanceOf(address account) public view returns (uint256) {
        return _stakeBalances[account];
    }
}