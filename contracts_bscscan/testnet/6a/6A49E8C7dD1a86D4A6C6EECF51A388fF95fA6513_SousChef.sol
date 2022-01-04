// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';

// SousChef is the chef of new tokens. He can make yummy food and he is a fair guy as well as MasterChef.
contract SousChef {

    // Info of each user.
    struct UserInfo {
        uint256 amount;   // How many SYRUP tokens the user has provided.
        uint256 zoinksRewardDebt;  // Reward debt. See explanation below.
        uint256 shaggyRewardDebt;  // Reward debt. See explanation below.
        uint256 scoobyRewardDebt;  // Reward debt. See explanation below.
        uint256 zoinksRewardPending;
        uint256 shaggyRewardPending;
        uint256 scoobyRewardPending;
        //
        // We do some fancy math here. Basically, any point in time, the amount of SYRUPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt + user.rewardPending
        //
        // Whenever a user deposits or withdraws SYRUP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of Pool
    struct PoolInfo {
        uint256 zoinksLastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 shaggyLastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 scoobyLastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 zoinksAccRewardPerShare; // Accumulated reward per share, times 1e12. See below.
        uint256 shaggyAccRewardPerShare; // Accumulated reward per share, times 1e12. See below.
        uint256 scoobyAccRewardPerShare; // Accumulated reward per share, times 1e12. See below.
    }

    // The ZOINKS TOKEN!
    IBEP20 public zoinks;
    // The SHAGGY TOKEN!
    IBEP20 public shaggy;
    // The SCOOBY TOKEN!
    IBEP20 public scooby;

    // rewards created per block.
    uint256 public zoinksRewardPerBlock;

    // rewards created per block.
    uint256 public shaggyRewardPerBlock;

    // rewards created per block.
    uint256 public scoobyRewardPerBlock;

    // Info.
    PoolInfo public poolInfo;
    // Info of each user that stakes Syrup tokens.
    mapping (address => UserInfo) public userInfo;

    // addresses list
    address[] public addressList;

    // The block number when mining starts.
    uint256 public startBlock;
    // The block number when mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    function addressLength() external view returns (uint256) {
        return addressList.length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    // View function to see pending Tokens on frontend.
    function pendingReward(address _user) external view returns (uint256, uint256, uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 zoinksAccRewardPerShare = pool.zoinksAccRewardPerShare;
        uint256 shaggyAccRewardPerShare = pool.shaggyAccRewardPerShare;
        uint256 scoobyAccRewardPerShare = pool.scoobyAccRewardPerShare;

        uint256 zoinksStakedSupply = zoinks.balanceOf(address(this));
        uint256 shaggyStakedSupply = shaggy.balanceOf(address(this));
        uint256 scoobyStakedSupply = scooby.balanceOf(address(this));
        if (block.number > pool.zoinksLastRewardBlock && zoinksStakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.zoinksLastRewardBlock, block.number);
            uint256 zoinksTokenReward = multiplier * zoinksRewardPerBlock;
            zoinksAccRewardPerShare = zoinksAccRewardPerShare + (zoinksTokenReward * (1e12) / (zoinksStakedSupply));
        }

        if (block.number > pool.shaggyLastRewardBlock && shaggyStakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.shaggyLastRewardBlock, block.number);
            uint256 shaggyTokenReward = multiplier * shaggyRewardPerBlock;
            shaggyAccRewardPerShare = zoinksAccRewardPerShare + (shaggyTokenReward * (1e12) / (shaggyStakedSupply));
        }

        if (block.number > pool.scoobyLastRewardBlock && scoobyStakedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.scoobyLastRewardBlock, block.number);
            uint256 scoobyTokenReward = multiplier * scoobyRewardPerBlock;
            scoobyAccRewardPerShare = zoinksAccRewardPerShare + (scoobyTokenReward * (1e12) / (scoobyStakedSupply));
        }

        uint256 zoinksReward = user.amount * (zoinksAccRewardPerShare) / (1e12) - (user.zoinksRewardDebt) + (user.zoinksRewardPending);
        uint256 shaggyReward = user.amount * (shaggyAccRewardPerShare) / (1e12) - (user.shaggyRewardDebt) + (user.shaggyRewardPending);
        uint256 scoobyReward = user.amount * (scoobyAccRewardPerShare) / (1e12) - (user.scoobyRewardDebt) + (user.scoobyRewardPending);
        
        return (zoinksReward, shaggyReward, scoobyReward);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        // if (block.number <= poolInfo.lastRewardBlock) {
        //     return;
        // }
        uint256 zoinksSupply = zoinks.balanceOf(address(this));
        if (zoinksSupply == 0) {
            poolInfo.zoinksLastRewardBlock = block.number;
            // return;
        }
        uint256 zoinksMultiplier = getMultiplier(poolInfo.zoinksLastRewardBlock, block.number);
        uint256 zoinksTokenReward = zoinksMultiplier * zoinksRewardPerBlock;

        poolInfo.zoinksAccRewardPerShare = poolInfo.zoinksAccRewardPerShare + (zoinksTokenReward * (1e12) / (zoinksSupply));
        poolInfo.zoinksLastRewardBlock = block.number;

        uint256 shaggySupply = shaggy.balanceOf(address(this));
        if (shaggySupply == 0) {
            poolInfo.shaggyLastRewardBlock = block.number;
            // return;
        }
        uint256 shaggyMultiplier = getMultiplier(poolInfo.shaggyLastRewardBlock, block.number);
        uint256 shaggyTokenReward = shaggyMultiplier * shaggyRewardPerBlock;

        poolInfo.shaggyAccRewardPerShare = poolInfo.shaggyAccRewardPerShare + (shaggyTokenReward * (1e12) / (shaggySupply));
        poolInfo.shaggyLastRewardBlock = block.number;

        uint256 scoobySupply = scooby.balanceOf(address(this));
        if (scoobySupply == 0) {
            poolInfo.scoobyLastRewardBlock = block.number;
            // return;
        }
        uint256 scoobyMultiplier = getMultiplier(poolInfo.scoobyLastRewardBlock, block.number);
        uint256 scoobyTokenReward = scoobyMultiplier * scoobyRewardPerBlock;

        poolInfo.scoobyAccRewardPerShare = poolInfo.scoobyAccRewardPerShare + (scoobyTokenReward * (1e12) / (scoobySupply));
        poolInfo.scoobyLastRewardBlock = block.number;
    }


    // Deposit Zoinks tokens to SousChef for Reward allocation.
    function depositZoinks(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        zoinks.transfer(address(this), _amount);
        // The deposit behavior before farming will result in duplicate addresses, and thus we will manually remove them when airdropping.
        if (user.amount == 0 && user.zoinksRewardPending == 0 && user.zoinksRewardDebt == 0) {
            addressList.push(address(msg.sender));
        }
        user.zoinksRewardPending = user.amount * (poolInfo.zoinksAccRewardPerShare) / (1e12) - (user.zoinksRewardDebt) + (user.zoinksRewardPending);
        user.amount = user.amount + _amount;
        user.zoinksRewardDebt = user.amount * poolInfo.zoinksAccRewardPerShare / (1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Deposit Shaggy tokens to SousChef for Reward allocation.
    function depositShaggy(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        shaggy.transfer(address(this), _amount);
        // The deposit behavior before farming will result in duplicate addresses, and thus we will manually remove them when airdropping.
        if (user.amount == 0 && user.shaggyRewardPending == 0 && user.shaggyRewardDebt == 0) {
            addressList.push(address(msg.sender));
        }
        user.shaggyRewardPending = user.amount * (poolInfo.shaggyAccRewardPerShare) / (1e12) - (user.shaggyRewardDebt) + (user.shaggyRewardPending);
        user.amount = user.amount + _amount;
        user.shaggyRewardDebt = user.amount * poolInfo.shaggyAccRewardPerShare / (1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Deposit Scooby tokens to SousChef for Reward allocation.
    function depositScooby(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        scooby.transfer(address(this), _amount);
        // The deposit behavior before farming will result in duplicate addresses, and thus we will manually remove them when airdropping.
        if (user.amount == 0 && user.scoobyRewardPending == 0 && user.scoobyRewardDebt == 0) {
            addressList.push(address(msg.sender));
        }
        user.scoobyRewardPending = user.amount * (poolInfo.scoobyAccRewardPerShare) / (1e12) - (user.scoobyRewardDebt) + (user.scoobyRewardPending);
        user.amount = user.amount + _amount;
        user.scoobyRewardDebt = user.amount * poolInfo.scoobyAccRewardPerShare / (1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw Syrup tokens from SousChef.
    function withdraw(uint256 _amount) public {
        require (_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");

        updatePool();
        zoinks.transfer(address(msg.sender), _amount);

        user.zoinksRewardPending = user.amount * (poolInfo.zoinksAccRewardPerShare) / (1e12) - (user.zoinksRewardDebt) + (user.zoinksRewardPending);
        user.amount = user.amount - _amount;
        user.zoinksRewardDebt = user.amount * (poolInfo.zoinksAccRewardPerShare) / (1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        zoinks.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.zoinksRewardDebt = 0;
        user.zoinksRewardPending = 0;
        user.shaggyRewardDebt = 0;
        user.shaggyRewardPending = 0;
        user.scoobyRewardDebt = 0;
        user.scoobyRewardPending = 0;
    }

}