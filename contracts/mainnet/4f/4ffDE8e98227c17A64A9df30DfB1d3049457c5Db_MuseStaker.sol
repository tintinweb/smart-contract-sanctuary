pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MuseStaker {
    IERC20 public MUSE = IERC20(0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81);

    mapping(address => uint256) public shares;
    mapping(address => uint256) public timeLock;
    mapping(address => uint256) public amountLocked;

    uint256 public totalShares;
    uint256 public unlockPeriod = 10 days;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeUnlockPeriod(uint256 _period) external {
        require(msg.sender == owner, "forbidden");
        unlockPeriod = _period;
    }

    function stake(uint256 _amount) public {
        timeLock[msg.sender] = 0; //reset timelock in case they stake twice.
        amountLocked[msg.sender] = amountLocked[msg.sender] + _amount;
        uint256 totalMuse = MUSE.balanceOf(address(this));
        if (totalShares == 0 || totalMuse == 0) {
            shares[msg.sender] = _amount;
            totalShares += _amount;
        } else {
            uint256 bal = (_amount * totalShares) / (totalMuse);
            shares[msg.sender] += bal;
            totalShares += bal;
        }
        MUSE.transferFrom(msg.sender, address(this), _amount);
    }

    function startUnstake() public {
        timeLock[msg.sender] = block.timestamp + unlockPeriod;
    }

    // requires timeLock to be up to 2 days after release tiemstamp.
    function unstake() public {
        uint256 lockedUntil = timeLock[msg.sender];
        timeLock[msg.sender] = 0;
        require(
            lockedUntil != 0 &&
                block.timestamp >= lockedUntil &&
                block.timestamp <= lockedUntil + 2 days,
            "!still locked"
        );
        _unstake();
    }

    function _unstake() internal {
        uint256 bal =
            (shares[msg.sender] * MUSE.balanceOf(address(this))) /
                (totalShares);
        totalShares -= shares[msg.sender];
        shares[msg.sender] = 0; //burns the share from this user;
        amountLocked[msg.sender] = 0;
        MUSE.transfer(msg.sender, bal);
    }

    function claim() public {
        uint256 amount = amountLocked[msg.sender];
        _unstake(); // Send locked muse + reward to user
        stake(amount); // Stake back only the original stake
    }

    function balance(address _user) public view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        uint256 bal =
            (shares[_user] * MUSE.balanceOf(address(this))) / (totalShares);
        return bal;
    }

    function userInfo(address _user)
        public
        view
        returns (
            uint256 bal,
            uint256 claimable,
            uint256 deposited,
            uint256 timelock,
            bool isClaimable,
            uint256 globalShares,
            uint256 globalBalance
        )
    {
        bal = balance(_user);
        if (bal > amountLocked[_user]) {
            claimable = bal - amountLocked[_user];
        }
        deposited = amountLocked[_user];
        timelock = timeLock[_user];
        isClaimable = (timelock != 0 &&
            block.timestamp >= timelock &&
            block.timestamp <= timelock + 2 days);
        globalShares = totalShares;
        globalBalance = MUSE.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}