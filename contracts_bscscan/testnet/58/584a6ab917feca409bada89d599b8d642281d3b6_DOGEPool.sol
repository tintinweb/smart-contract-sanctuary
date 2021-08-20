/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/pool/DogePool.sol


pragma solidity >=0.8.7;

/**
 * @title Doge Pool Contract
 * @author ETHST-TEAM
 * @notice This contract burn ET for Doge
 */
contract DOGEPool {
    IERC20 public dogeContract;
    IERC20 public etContract;

    struct Round {
        bool transferred;
        uint256 dogeAmount;
        uint256 etBurnAmount;
        uint256 userLength;
        address[11] rankUser;
        mapping(address => bool) newUser;
        mapping(address => uint256) userRank;
        mapping(address => uint256) userBurnET;
    }

    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public burnEpoch;

    uint256[11] public ratio = [0, 5, 4, 3, 2, 1, 1, 1, 1, 1, 1];
    uint256 public etBurnTotalAmount;
    uint256 public firstRoundStartTimestamp;
    uint256 public intervalSeconds;
    address public etBurnAddress;
    address public dogeReturnAddress;

    event TransferDOGE(uint256 indexed epoch, uint256 dogeAmount);
    event TransferET(
        uint256 indexed epoch,
        uint256 dogeAmount,
        uint256 etBurnAmount,
        uint256 userLength,
        address[11] rankUser,
        bool indexed transferred
    );
    event BurnET(
        uint256 indexed epoch,
        address indexed sender,
        uint256 etBurnAmount,
        uint256 userRank
    );
    event WithdrawDOGE(address indexed sender, uint256 dogeRewardsAmount);

    /**
     * @param dogeContractAddr Initialize DOGE Contract Address
     * @param etContractAddr Initialize ET Contract Address
     * @param etBurnAddr Initialize ET Burn Address
     * @param dogeReturnAddr Initialize DOGE Return Address
     * @param _firstRoundStartTimestamp Initialize first round start timestamp, should be at 15:00 on a certain day
     * @param _intervalSeconds Initialize interval seconds, 1 day = 86400 seconds
     */
    constructor(
        address dogeContractAddr,
        address etContractAddr,
        address etBurnAddr,
        address dogeReturnAddr,
        uint256 _firstRoundStartTimestamp,
        uint256 _intervalSeconds
    ) {
        dogeContract = IERC20(dogeContractAddr);
        etContract = IERC20(etContractAddr);

        etBurnAddress = etBurnAddr;
        dogeReturnAddress = dogeReturnAddr;
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
     * @dev Get DOGE rewards of a user
     */
    function getDOGERewards(address user) public view returns (uint256) {
        uint256 currentEpoch = getCurrentEpoch();
        uint256 dogeRewards;
        for (uint256 i = 0; i < burnEpoch[user].length; i++) {
            uint256 epoch = burnEpoch[user][i];
            if (epoch < currentEpoch) {
                Round storage round = rounds[epoch];
                if (round.dogeAmount > 0) {
                    dogeRewards +=
                        (((round.dogeAmount * round.userBurnET[user]) /
                            round.etBurnAmount) * 80) /
                        100;
                    if (round.userRank[user] > 0) {
                        dogeRewards +=
                            (round.dogeAmount * ratio[round.userRank[user]]) /
                            100;
                    }
                }
            }
        }
        return dogeRewards;
    }

    /**
     * @dev Transfer DOGE to current round or a future round, should run before 17:00 everyday
     */
    function transferDOGE(uint256 epoch, uint256 dogeAmount) external {
        require(epoch > 0, "The epoch must > 0.");
        uint256 currentEpoch = getCurrentEpoch();
        require(epoch >= currentEpoch, "This round has already ended.");
        dogeContract.transferFrom(msg.sender, address(this), dogeAmount);
        Round storage round = rounds[epoch];
        round.dogeAmount += dogeAmount;

        emit TransferDOGE(epoch, dogeAmount);
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
        } else if (round.dogeAmount > 0) {
            dogeContract.transfer(dogeReturnAddress, round.dogeAmount);
        }

        emit TransferET(
            epoch,
            round.dogeAmount,
            round.etBurnAmount,
            round.userLength,
            round.rankUser,
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
        uint256 i = round.userRank[msg.sender] > 0
            ? round.userRank[msg.sender] - 1
            : (round.userLength + 1 < 10 ? round.userLength + 1 : 10);
        for (i; i > 0; i--) {
            if (
                round.userBurnET[msg.sender] >
                round.userBurnET[round.rankUser[i]]
            ) {
                if (i == 10) {
                    round.userRank[round.rankUser[i]] = 0;
                } else {
                    round.rankUser[i + 1] = round.rankUser[i];
                    round.userRank[round.rankUser[i]] = i + 1;
                }
                round.rankUser[i] = msg.sender;
                round.userRank[msg.sender] = i;
            } else {
                break;
            }
        }
        if (!round.newUser[msg.sender]) {
            round.userLength += 1;
            round.newUser[msg.sender] = true;
        }

        emit BurnET(
            currentEpoch,
            msg.sender,
            etBurnAmount,
            round.userRank[msg.sender]
        );
    }

    /**
     * @dev Withdraw DOGE
     */
    function withdrawDOGE() external {
        uint256 dogeRewardsAmount = getDOGERewards(msg.sender);
        require(dogeRewardsAmount > 0, "You have no DOGE to withdraw.");
        uint256 currentEpoch = getCurrentEpoch();
        if (
            burnEpoch[msg.sender][burnEpoch[msg.sender].length - 1] ==
            currentEpoch
        ) {
            burnEpoch[msg.sender] = [currentEpoch];
        } else {
            delete burnEpoch[msg.sender];
        }
        dogeContract.transfer(msg.sender, dogeRewardsAmount);

        emit WithdrawDOGE(msg.sender, dogeRewardsAmount);
    }

    /**
     * @dev Get Current Epoch DOGE rewards of a user
     */
    function getCurrentEpochDOGERewards(address user)
        external
        view
        returns (uint256)
    {
        uint256 dogeRewards;
        uint256 burnEpochLength = burnEpoch[user].length;
        if (burnEpochLength > 0) {
            uint256 currentEpoch = getCurrentEpoch();
            if (burnEpoch[user][burnEpochLength - 1] == currentEpoch) {
                Round storage round = rounds[currentEpoch];
                if (round.dogeAmount > 0) {
                    dogeRewards +=
                        (((round.dogeAmount * round.userBurnET[user]) /
                            round.etBurnAmount) * 80) /
                        100;
                    if (round.userRank[user] > 0) {
                        dogeRewards +=
                            (round.dogeAmount * ratio[round.userRank[user]]) /
                            100;
                    }
                }
            }
        }
        return dogeRewards;
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
     * @dev Get Round Rank User
     */
    function getRoundRankUser(uint256 epoch)
        external
        view
        returns (address[11] memory rankUser)
    {
        Round storage round = rounds[epoch];
        return round.rankUser;
    }

    /**
     * @dev Get Round User Rank
     */
    function getRoundUserRank(uint256 epoch, address user)
        external
        view
        returns (uint256)
    {
        Round storage round = rounds[epoch];
        return round.userRank[user];
    }

    /**
     * @dev Get Round User Burn ET
     */
    function getRoundUserBurnET(uint256 epoch, address user)
        external
        view
        returns (uint256)
    {
        Round storage round = rounds[epoch];
        return round.userBurnET[user];
    }

    /**
     * @dev Get DOGE balance of this contract
     */
    function getDOGEBalance() external view returns (uint256) {
        return dogeContract.balanceOf(address(this));
    }

    /**
     * @dev Get ET balance of this contract
     */
    function getETBalance() external view returns (uint256) {
        return etContract.balanceOf(address(this));
    }
}