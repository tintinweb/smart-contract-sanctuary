// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ET Burn Pool Contract
 * @author ETHST-TEAM
 * @notice This contract burn ET
 */
contract ETBurnPool {
    IERC20 public ethContract;
    IERC20 public etContract;

    struct Round {
        bool transferred;
        uint256 ethAmount;
        uint256 etBurnAmount;
        mapping(address => uint256) userBurnET;
    }

    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public burnEpoch;

    uint256 public etBurnTotalAmount;
    uint256 public firstRoundStartTimestamp;
    uint256 public intervalSeconds;
    address public etBurnAddress;
    address public ethReturnAddress;

    event TransferETH(uint256 indexed epoch, uint256 ethAmount);
    event TransferET(
        uint256 indexed epoch,
        uint256 ethAmount,
        uint256 etBurnAmount,
        bool indexed transferred
    );
    event BurnET(
        uint256 indexed epoch,
        address indexed sender,
        uint256 etBurnAmount
    );
    event WithdrawETH(address indexed sender, uint256 ethRewardsAmount);

    /**
     * @param ethContractAddr Initialize ETH Contract Address
     * @param etContractAddr Initialize ET Contract Address
     * @param etBurnAddr Initialize ET Burn Address
     * @param ethReturnAddr Initialize ETH Return Address
     * @param _firstRoundStartTimestamp Initialize first round start timestamp, should be at 17:00 on a certain day
     * @param _intervalSeconds Initialize interval seconds, 1 day = 86400 seconds
     */
    constructor(
        address ethContractAddr,
        address etContractAddr,
        address etBurnAddr,
        address ethReturnAddr,
        uint256 _firstRoundStartTimestamp,
        uint256 _intervalSeconds
    ) {
        ethContract = IERC20(ethContractAddr);
        etContract = IERC20(etContractAddr);

        etBurnAddress = etBurnAddr;
        ethReturnAddress = ethReturnAddr;
        firstRoundStartTimestamp = _firstRoundStartTimestamp;
        intervalSeconds = _intervalSeconds;
    }

    /**
     * @dev Get current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp >= firstRoundStartTimestamp) {
            return
                (block.timestamp - firstRoundStartTimestamp) /
                intervalSeconds +
                1;
        } else {
            return 0;
        }
    }

    /**
     * @dev Get ETH rewards of a user
     */
    function getETHRewards(address user) public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 ethRewards;
        for (uint256 i = 0; i < burnEpoch[user].length; i++) {
            uint256 epoch = burnEpoch[user][i];
            if (epoch < currentEpoch) {
                Round storage round = rounds[epoch];
                if (round.ethAmount > 0) {
                    ethRewards +=
                        (round.ethAmount * round.userBurnET[user]) /
                        round.etBurnAmount;
                }
            }
        }
        return ethRewards;
    }

    /**
     * @dev Transfer ETH to current round or a future round, should run before 17:00 everyday
     */
    function transferETH(uint256 epoch, uint256 ethAmount) external {
        require(epoch > 0, "The epoch must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(epoch >= currentEpoch, "This round has already ended.");
        ethContract.transferFrom(msg.sender, address(this), ethAmount);
        Round storage round = rounds[epoch];
        round.ethAmount += ethAmount;

        emit TransferETH(epoch, ethAmount);
    }

    /**
     * @dev Transfer ET to burn address, should run after 17:00 everyday
     */
    function transferET(uint256 epoch) external {
        require(epoch > 0, "The epoch must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(epoch < currentEpoch, "This round has not ended yet.");
        Round storage round = rounds[epoch];
        if (round.transferred == true)
            revert("This round has already been transferred.");
        round.transferred = true;
        if (round.etBurnAmount > 0) {
            etContract.transfer(etBurnAddress, round.etBurnAmount);
            etBurnTotalAmount += round.etBurnAmount;
        } else if (round.ethAmount > 0) {
            ethContract.transfer(ethReturnAddress, round.ethAmount);
        }

        emit TransferET(
            epoch,
            round.ethAmount,
            round.etBurnAmount,
            round.transferred
        );
    }

    /**
     * @dev Burn ET
     */
    function burnET(uint256 etBurnAmount) external {
        require(etBurnAmount > 0, "ET burn amount must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(currentEpoch > 0, "This activity has not started yet.");
        etContract.transferFrom(msg.sender, address(this), etBurnAmount);
        uint256 burnEpochLength = burnEpoch[msg.sender].length;
        if (burnEpochLength > 0) {
            if (burnEpoch[msg.sender][burnEpochLength - 1] < currentEpoch) {
                burnEpoch[msg.sender].push(currentEpoch);
            }
        } else {
            burnEpoch[msg.sender].push(currentEpoch);
        }
        Round storage round = rounds[currentEpoch];
        round.userBurnET[msg.sender] += etBurnAmount;
        round.etBurnAmount += etBurnAmount;

        emit BurnET(currentEpoch, msg.sender, etBurnAmount);
    }

    /**
     * @dev Withdraw ETH
     */
    function withdrawETH() external {
        uint256 ethRewardsAmount = getETHRewards(msg.sender);
        require(ethRewardsAmount > 0, "You have no ETH to withdraw.");
        uint256 currentEpoch = getCurrentEpoch();
        if (
            burnEpoch[msg.sender][burnEpoch[msg.sender].length - 1] ==
            currentEpoch
        ) {
            burnEpoch[msg.sender] = [currentEpoch];
        } else {
            delete burnEpoch[msg.sender];
        }
        ethContract.transfer(msg.sender, ethRewardsAmount);

        emit WithdrawETH(msg.sender, ethRewardsAmount);
    }

    /**
     * @dev Get current epoch countdown
     */
    function getCurrentEpochCountdown() external view returns (uint256) {
        if (block.timestamp >= firstRoundStartTimestamp) {
            return
                intervalSeconds -
                ((block.timestamp - firstRoundStartTimestamp) %
                    intervalSeconds);
        } else {
            return 0;
        }
    }

    /**
     * @dev Get ETH balance of this contract
     */
    function getETHBalance() external view returns (uint256) {
        return ethContract.balanceOf(address(this));
    }

    /**
     * @dev Get ET balance of this contract
     */
    function getETBalance() external view returns (uint256) {
        return etContract.balanceOf(address(this));
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

