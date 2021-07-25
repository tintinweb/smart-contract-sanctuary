/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface ve {
    function locked__end(address) external view returns (uint);
    function deposit_for(address, uint) external;
}

contract distribution {
    address constant _ibff = 0xb347132eFf18a3f63426f4988ef626d2CbE274F5;
    address constant _ibeurlp = 0xa2D81bEdf22201A77044CDF3Ab4d9dC1FfBc391B;
    address constant _veibff = 0x4D0518C9136025903751209dDDdf6C67067357b1;
    address constant _vedist = 0x83893c4A42F8654c2dd4FF7b4a7cd0e33ae8C859;
    
    uint constant DURATION = 7 days;
    uint constant PRECISION = 10 ** 18;
    uint constant MAXTIME = 4 * 365 * 86400;
    
    uint rewardRate;
    uint periodFinish;
    uint lastUpdateTime;
    uint rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION / totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate * DURATION;
    }

    function deposit(uint amount) external update(msg.sender) {
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        safeTransferFrom(_ibeurlp, amount);
    }

    function withdraw(uint amount) public update(msg.sender) {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        safeTransfer(_ibeurlp, msg.sender, amount);
    }

    function getReward() public update(msg.sender) {
        uint _reward = rewards[msg.sender];
        uint _user_lock = ve(_veibff).locked__end(msg.sender);
        uint _adj = Math.min(_reward * _user_lock / (block.timestamp + MAXTIME), _reward);
        if (_adj > 0) {
            rewards[msg.sender] = 0;
            erc20(_ibff).approve(_veibff, _adj);
            ve(_veibff).deposit_for(msg.sender, _adj);
            safeTransfer(_ibff, _vedist, _reward - _adj);
        }
    }

    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }
    
    function notify(uint amount) external update(address(0)) {
        safeTransferFrom(_ibff, amount);
        if (block.timestamp >= periodFinish) {
            rewardRate = amount / DURATION;
        } else {
            uint _remaining = periodFinish - block.timestamp;
            uint _leftover = _remaining * rewardRate;
            rewardRate = (amount + _leftover) / DURATION;
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
    }

    modifier update(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function safeTransferFrom(address token, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, msg.sender, address(this), value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}