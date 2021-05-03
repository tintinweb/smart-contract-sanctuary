// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";
import "./SafeMath.sol";

contract ImPlusToken is ERC20 {

    mapping (address => uint256) private _balances;

    IERC20 public im;
    using SafeMath for uint256;
    mapping(address => uint256) public startLockTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public rewards;
    uint256 public lockTime = 3 days;
    uint256 public staking_apy = 100;

    constructor(IERC20 _im) ERC20("Intelligent Mining Plus Token", "IM+") {
        im = _im;
    }

    function stake(uint256 _amount) public {
        calcReward();

        im.transferFrom(_msgSender(), address(this), _amount);
        // Lock the IM in the contract
        startLockTime[_msgSender()] = block.timestamp;
        _balances[_msgSender()] += _amount;
    }

    function withdrawn(uint256 _share) public {
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= _share, "Stake withdrawn exceeds balance");

        uint256 duration = block.timestamp.sub(startLockTime[_msgSender()]);
        require(duration >= lockTime, "IM Lock not expired yet");

        calcReward();
        _balances[_msgSender()] -= _share;

        im.transfer(_msgSender(), _share);
    }

    function withdrawnReward() public {
        calcReward();
        uint256 amount = rewards[_msgSender()];
        rewards[_msgSender()] = 0;

        _mint(_msgSender(), amount);
    }

    function calcReward() internal {
        uint256 lastReward = lastRewardTime[_msgSender()];
        lastRewardTime[_msgSender()] = block.timestamp;

        // We eligible for rewards
        if (lastReward != 0) {
            uint256 duration = block.timestamp.sub(lastReward);
            uint256 amount = _balances[_msgSender()].mul(staking_apy).div(100).mul(duration).div(365 days);
            rewards[_msgSender()] += amount;
        }
    }
}