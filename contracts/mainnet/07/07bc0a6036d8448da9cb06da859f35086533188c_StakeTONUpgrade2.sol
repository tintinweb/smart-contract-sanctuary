//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IStakeTON.sol";
import {IIStake1Vault} from "../interfaces/IIStake1Vault.sol";
import {IIERC20} from "../interfaces/IIERC20.sol";
import {IWTON} from "../interfaces/IWTON.sol";

import "../libraries/LibTokenStake1.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../connection/TokamakStakeUpgrade2.sol";

// import {
//     ERC165Checker
// } from "@openzeppelin/contracts/introspection/ERC165Checker.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title Stake Contract
/// @notice It can be staked in Tokamak. Can be swapped using Uniswap.
/// Stake contracts can interact with the vault to claim tos tokens
contract StakeTONUpgrade2 is TokamakStakeUpgrade2, IStakeTON {
    using SafeMath for uint256;

    /// @dev event on staking
    /// @param to the sender
    /// @param amount the amount of staking
    event Staked(address indexed to, uint256 amount);

    /// @dev event on claim
    /// @param to the sender
    /// @param amount the amount of claim
    /// @param claimBlock the block of claim
    event Claimed(address indexed to, uint256 amount, uint256 claimBlock);

    /// @dev event on withdrawal
    /// @param to the sender
    /// @param tonAmount the amount of TON withdrawal
    /// @param tosAmount the amount of TOS withdrawal
    event Withdrawal(address indexed to, uint256 tonAmount, uint256 tosAmount);

    /// @dev constructor of StakeTON
    constructor() {}

    /// @dev This contract cannot stake Ether.
    receive() external payable {
        revert("cannot stake Ether");
    }

    /// @dev withdraw
    function withdraw() external override {
        require(endBlock > 0 && endBlock < block.number, "StakeTON: not end");
        (
            address ton,
            address wton,
            address depositManager,
            address seigManager,

        ) = ITokamakRegistry2(stakeRegistry).getTokamak();
        require(
            ton != address(0) &&
                wton != address(0) &&
                depositManager != address(0) &&
                seigManager != address(0),
            "StakeTON: ITokamakRegistry zero"
        );
        if (tokamakLayer2 != address(0)) {
            require(
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) ==
                    0 &&
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    ) ==
                    0,
                "StakeTON: remain amount in tokamak"
            );
        }
        LibTokenStake1.StakedAmount storage staked = userStaked[msg.sender];
        require(!staked.released, "StakeTON: Already withdraw");

        if (!withdrawFlag) {
            withdrawFlag = true;
            if (paytoken == ton) {
                swappedAmountTOS = IIERC20(token).balanceOf(address(this));
                finalBalanceWTON = IIERC20(wton).balanceOf(address(this));
                finalBalanceTON = IIERC20(ton).balanceOf(address(this));
                require(
                    finalBalanceWTON.div(10**9).add(finalBalanceTON) >=
                        totalStakedAmount,
                    "StakeTON: finalBalance is lack"
                );
            }
        }

        uint256 amount = staked.amount;
        require(amount > 0, "StakeTON: Amount wrong");
        staked.releasedBlock = block.number;
        staked.released = true;

        if (paytoken == ton) {
            uint256 tonAmount = 0;
            uint256 wtonAmount = 0;
            uint256 tosAmount = 0;
            if (finalBalanceTON > 0)
                tonAmount = finalBalanceTON.mul(amount).div(totalStakedAmount);
            if (finalBalanceWTON > 0)
                wtonAmount = finalBalanceWTON.mul(amount).div(
                    totalStakedAmount
                );
            if (swappedAmountTOS > 0)
                tosAmount = swappedAmountTOS.mul(amount).div(totalStakedAmount);

            staked.releasedTOSAmount = tosAmount;
            if (wtonAmount > 0)
                staked.releasedAmount = wtonAmount.div(10**9).add(tonAmount);
            else staked.releasedAmount = tonAmount;

            tonWithdraw(ton, wton, tonAmount, wtonAmount, tosAmount);
        } else if (paytoken == address(0)) {
            require(staked.releasedAmount <= amount, "StakeTON: Amount wrong");
            staked.releasedAmount = amount;
            address payable self = address(uint160(address(this)));
            require(self.balance >= amount, "StakeTON: insuffient ETH");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "StakeTON: withdraw failed.");
        } else {
            require(staked.releasedAmount <= amount, "StakeTON: Amount wrong");
            staked.releasedAmount = amount;
            require(
                IIERC20(paytoken).transfer(msg.sender, amount),
                "StakeTON: transfer fail"
            );
        }

        emit Withdrawal(
            msg.sender,
            staked.releasedAmount,
            staked.releasedTOSAmount
        );
    }

    /// @dev withdraw TON
    /// @param ton  TON address
    /// @param wton  WTON address
    /// @param tonAmount  the amount of TON to be withdrawn to msg.sender
    /// @param wtonAmount  the amount of WTON to be withdrawn to msg.sender
    /// @param tosAmount  the amount of TOS to be withdrawn to msg.sender
    function tonWithdraw(
        address ton,
        address wton,
        uint256 tonAmount,
        uint256 wtonAmount,
        uint256 tosAmount
    ) internal {
        if (tonAmount > 0) {
            require(
                IIERC20(ton).balanceOf(address(this)) >= tonAmount,
                "StakeTON: ton balance is lack"
            );

            require(
                IIERC20(ton).transfer(msg.sender, tonAmount),
                "StakeTON: transfer ton fail"
            );
        }
        if (wtonAmount > 0) {
            require(
                IIERC20(wton).balanceOf(address(this)) >= wtonAmount,
                "StakeTON: wton balance is lack"
            );
            require(
                IWTON(wton).swapToTONAndTransfer(msg.sender, wtonAmount),
                "StakeTON: transfer wton fail"
            );
        }
        if (tosAmount > 0) {
            require(
                IIERC20(token).balanceOf(address(this)) >= tosAmount,
                "StakeTON: tos balance is lack"
            );
            require(
                IIERC20(token).transfer(msg.sender, tosAmount),
                "StakeTON: transfer tos fail"
            );
        }
    }

    /// @dev Claim for reward
    function claim() external override lock {
        require(IIStake1Vault(vault).saleClosed(), "StakeTON: not closed");
        uint256 rewardClaim = 0;

        LibTokenStake1.StakedAmount storage staked = userStaked[msg.sender];
        require(
            staked.amount > 0 && staked.claimedBlock < endBlock,
            "StakeTON: claimed"
        );

        rewardClaim = canRewardAmount(msg.sender, block.number);

        require(rewardClaim > 0, "StakeTON: reward is zero");

        uint256 rewardTotal =
            IIStake1Vault(vault).totalRewardAmount(address(this));
        require(
            rewardClaimedTotal.add(rewardClaim) <= rewardTotal,
            "StakeTON: total reward exceeds"
        );

        staked.claimedBlock = block.number;
        staked.claimedAmount = staked.claimedAmount.add(rewardClaim);
        rewardClaimedTotal = rewardClaimedTotal.add(rewardClaim);

        require(
            IIStake1Vault(vault).claim(msg.sender, rewardClaim),
            "StakeTON: fail claim from vault"
        );

        emit Claimed(msg.sender, rewardClaim, block.number);
    }

    /// @dev Returns the amount that can be rewarded
    /// @param account  the account that claimed reward
    /// @param specificBlock the block that claimed reward
    /// @return reward the reward amount that can be taken
    function canRewardAmount(address account, uint256 specificBlock)
        public
        view
        override
        returns (uint256)
    {
        uint256 reward = 0;
        if (specificBlock > endBlock) specificBlock = endBlock;

        if (
            specificBlock < startBlock ||
            userStaked[account].amount == 0 ||
            userStaked[account].claimedBlock > endBlock ||
            userStaked[account].claimedBlock > specificBlock
        ) {
            reward = 0;
        } else {
            uint256 startR = startBlock;
            uint256 endR = endBlock;
            if (startR < userStaked[account].claimedBlock)
                startR = userStaked[account].claimedBlock;
            if (specificBlock < endR) endR = specificBlock;

            uint256[] memory orderedEndBlocks =
                IIStake1Vault(vault).orderedEndBlocksAll();

            if (orderedEndBlocks.length > 0) {
                uint256 _end = 0;
                uint256 _start = startR;
                uint256 _total = 0;
                uint256 blockTotalReward = 0;
                blockTotalReward = IIStake1Vault(vault).blockTotalReward();

                address user = account;
                uint256 amount = userStaked[user].amount;

                for (uint256 i = 0; i < orderedEndBlocks.length; i++) {
                    _end = orderedEndBlocks[i];
                    _total = IIStake1Vault(vault).stakeEndBlockTotal(_end);

                    if (_start > _end) {} else if (endR <= _end) {
                        if (_total > 0) {
                            uint256 _period1 = endR.sub(startR);
                            reward = reward.add(
                                blockTotalReward.mul(_period1).mul(amount).div(
                                    _total
                                )
                            );
                        }
                        break;
                    } else {
                        if (_total > 0) {
                            uint256 _period2 = _end.sub(startR);
                            reward = reward.add(
                                blockTotalReward.mul(_period2).mul(amount).div(
                                    _total
                                )
                            );
                        }
                        startR = _end;
                    }
                }
            }
        }
        return reward;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../libraries/LibTokenStake1.sol";

interface IStakeTON {
    /// @dev Stake amount
    /// @param amount  the amount of staked
    //function stake(uint256 amount) external payable;

    /// @dev Claim for reward
    function claim() external;

    /// @dev withdraw
    function withdraw() external;

    /// @dev Returns the amount that can be rewarded
    /// @param account  the account that claimed reward
    /// @param specificBlock the block that claimed reward
    /// @return reward the reward amount that can be taken
    function canRewardAmount(address account, uint256 specificBlock)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IIStake1Vault {
    function closeSale() external;

    function totalRewardAmount(address _account)
        external
        view
        returns (uint256);

    function claim(address _to, uint256 _amount) external returns (bool);

    function orderedEndBlocksAll() external view returns (uint256[] memory);

    function blockTotalReward() external view returns (uint256);

    function stakeEndBlockTotal(uint256 endblock)
        external
        view
        returns (uint256 totalStakedAmount);

    function saleClosed() external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IIERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IWTON {
    function balanceOf(address account) external view returns (uint256);

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external;

    function swapToTON(uint256 wtonAmount) external returns (bool);

    function swapFromTON(uint256 tonAmount) external returns (bool);

    function swapToTONAndTransfer(address to, uint256 wtonAmount)
        external
        returns (bool);

    function swapFromTONAndTransfer(address to, uint256 tonAmount)
        external
        returns (bool);

    function renounceTonMinter() external;

    function approve(address spender, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibTokenStake1 {
    enum DefiStatus {
        NONE,
        APPROVE,
        DEPOSITED,
        REQUESTWITHDRAW,
        REQUESTWITHDRAWALL,
        WITHDRAW,
        END
    }
    struct DefiInfo {
        string name;
        address router;
        address ext1;
        address ext2;
        uint256 fee;
        address routerV2;
    }
    struct StakeInfo {
        string name;
        uint256 startBlock;
        uint256 endBlock;
        uint256 balance;
        uint256 totalRewardAmount;
        uint256 claimRewardAmount;
    }

    struct StakedAmount {
        uint256 amount;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
        uint256 releasedTOSAmount;
        bool released;
    }

    struct StakedAmountForSTOS {
        uint256 amount;
        uint256 startBlock;
        uint256 periodBlock;
        uint256 rewardPerBlock;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/ITokamakStaker.sol";
import {ITON} from "../interfaces/ITON.sol";
import {IIStake1Vault} from "../interfaces/IIStake1Vault.sol";
import {IIIDepositManager} from "../interfaces/IIIDepositManager.sol";
import {IISeigManager} from "../interfaces/IISeigManager.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../common/AccessibleCommon.sol";

import "../stake/StakeTONStorage.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IERC20BASE2 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IIWTON2 {
    function swapToTON(uint256 wtonAmount) external returns (bool);
}

interface ITokamakRegistry2 {
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function getUniswap()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            address
        );
}

/// @title The connector that integrates tokamak
contract TokamakStakeUpgrade2 is
    StakeTONStorage,
    AccessibleCommon,
    ITokamakStaker
{
    using SafeMath for uint256;

    modifier nonZero(address _addr) {
        require(_addr != address(0), "TokamakStaker: zero address");
        _;
    }

    modifier sameTokamakLayer(address _addr) {
        require(tokamakLayer2 == _addr, "TokamakStaker:different layer");
        _;
    }

    modifier lock() {
        require(_lock == 0, "TokamakStaker:LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    modifier onlyClosed() {
        require(IIStake1Vault(vault).saleClosed(), "TokamakStaker: not closed");
        _;
    }

    /// @dev event on set the registry address
    /// @param registry the registry address
    event SetRegistry(address registry);

    /// @dev event on set the tokamak Layer2 address
    /// @param layer2 the tokamak Layer2 address
    event SetTokamakLayer2(address layer2);

    /// @dev event on staking the staked TON in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param amount the amount that stake to layer2
    event TokamakStaked(address layer2, uint256 amount);

    /// @dev event on request unstaking the wtonAmount in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param amount the amount requested to unstaking
    event TokamakRequestedUnStaking(address layer2, uint256 amount);

    /// @dev event on process unstaking in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    /// @param rn the number of requested unstaking
    /// @param receiveTON if is true ,TON , else is WTON
    event TokamakProcessedUnStaking(
        address layer2,
        uint256 rn,
        bool receiveTON
    );

    /// @dev event on request unstaking the amount of all in layer2 in tokamak
    /// @param layer2 the layer2 address in tokamak
    event TokamakRequestedUnStakingAll(address layer2);

    /// @dev exchange WTON to TOS using uniswap v3
    /// @param caller the sender
    /// @param amountIn the input amount
    /// @return amountOut the amount of exchanged out token

    event ExchangedWTONtoTOS(
        address caller,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev set registry address
    /// @param _registry new registry address
    function setRegistry(address _registry)
        external
        onlyOwner
        nonZero(_registry)
    {
        stakeRegistry = _registry;

        emit SetRegistry(stakeRegistry);
    }

    /// @dev set the tokamak Layer2 address
    /// @param _layer2 new the tokamak Layer2 address
    function setTokamakLayer2(address _layer2) external override onlyOwner {
        require(
            _layer2 != address(0) && tokamakLayer2 != _layer2,
            "TokamakStaker:tokamakLayer2 zero "
        );
        tokamakLayer2 = _layer2;

        emit SetTokamakLayer2(_layer2);
    }

    /// @dev get the addresses that used in uniswap interfaces
    /// @return uniswapRouter the address of uniswapRouter
    /// @return npm the address of positionManagerAddress
    /// @return ext the address of ext
    /// @return fee the amount of fee
    function getUniswapInfo()
        external
        view
        override
        returns (
            address uniswapRouter,
            address npm,
            address ext,
            uint256 fee,
            address uniswapRouterV2
        )
    {
        return ITokamakRegistry2(stakeRegistry).getUniswap();
    }

    /// @dev Change the TON holded in contract have to WTON, or change WTON to TON.
    /// @param amount the amount to be changed
    /// @param toWTON if it's true, TON->WTON , else WTON->TON
    function swapTONtoWTON(uint256 amount, bool toWTON) external override lock {
        checkTokamak();

        if (toWTON) {
            require(
                swapProxy != address(0),
                "TokamakStaker: swapProxy is zero"
            );
            require(
                IERC20BASE2(ton).balanceOf(address(this)) >= amount,
                "TokamakStaker: swapTONtoWTON ton balance is insufficient"
            );
            bytes memory data = abi.encode(swapProxy, swapProxy);
            require(
                ITON(ton).approveAndCall(wton, amount, data),
                "TokamakStaker:swapTONtoWTON approveAndCall fail"
            );
        } else {
            require(
                IERC20BASE2(wton).balanceOf(address(this)) >= amount,
                "TokamakStaker: swapTONtoWTON wton balance is insufficient"
            );
            require(
                IIWTON2(wton).swapToTON(amount),
                "TokamakStaker:swapToTON fail"
            );
        }
    }

    /// @dev If the tokamak addresses is not set, set the addresses.
    function checkTokamak() public {
        if (ton == address(0)) {
            (
                address _ton,
                address _wton,
                address _depositManager,
                address _seigManager,
                address _swapProxy
            ) = ITokamakRegistry2(stakeRegistry).getTokamak();

            ton = _ton;
            wton = _wton;
            depositManager = _depositManager;
            seigManager = _seigManager;
            swapProxy = _swapProxy;
        }
        require(
            ton != address(0) &&
                wton != address(0) &&
                seigManager != address(0) &&
                depositManager != address(0) &&
                swapProxy != address(0),
            "TokamakStaker:tokamak zero"
        );
    }

    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
    {
        require(block.number <= endBlock, "TokamakStaker:period end");
        require(stakeAmount > 0, "TokamakStaker:stakeAmount is zero");

        defiStatus = uint256(LibTokenStake1.DefiStatus.DEPOSITED);

        checkTokamak();

        uint256 globalWithdrawalDelay =
            IIIDepositManager(depositManager).globalWithdrawalDelay();
        require(
            block.number < endBlock.sub(globalWithdrawalDelay),
            "TokamakStaker:period(withdrawalDelay) end"
        );

        if (tokamakLayer2 == address(0)) tokamakLayer2 = _layer2;
        else {
            if (
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) >
                0 ||
                IIIDepositManager(depositManager).pendingUnstaked(
                    tokamakLayer2,
                    address(this)
                ) >
                0
            ) {
                require(
                    tokamakLayer2 == _layer2,
                    "TokamakStaker:different layer"
                );
            } else {
                if (tokamakLayer2 != _layer2) tokamakLayer2 = _layer2;
            }
        }

        require(
            IERC20BASE2(ton).balanceOf(address(this)) >= stakeAmount,
            "TokamakStaker: ton balance is insufficient"
        );
        toTokamak = toTokamak.add(stakeAmount);
        bytes memory data = abi.encode(depositManager, _layer2);
        require(
            ITON(ton).approveAndCall(wton, stakeAmount, data),
            "TokamakStaker:approveAndCall fail"
        );

        emit TokamakStaked(_layer2, stakeAmount);
    }

    function version() external pure returns (string memory) {
        return "phase1.upgrade.v2";
    }

    /// @dev  request unstaking the amount excluding principal   in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount Exists for existing interfaces. not used.
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.REQUESTWITHDRAW);
        requestNum = requestNum.add(1);
        checkTokamak();

        uint256 stakeOf =
            IISeigManager(seigManager).stakeOf(_layer2, address(this));
        require(stakeOf > 0, "TokamakStaker: stakeOf is zero");

        uint256 principalAmount = totalStakedAmount.mul(10**9);

        uint256 availableAmount = 0;
        if (principalAmount > 0 && principalAmount < stakeOf.sub(100)) {
            availableAmount = stakeOf.sub(principalAmount).sub(100);
        }

        require(
            availableAmount > 0,
            "TokamakStaker: no withdraw-able amount not yet"
        );

        IIIDepositManager(depositManager).requestWithdrawal(
            _layer2,
            availableAmount
        );

        emit TokamakRequestedUnStaking(_layer2, availableAmount);
    }

    /// @dev  Check whether unstaking is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return canUnStakingAmount available unStaking amount
    function canTokamakRequestUnStaking(address _layer2)
        external
        view
        returns (uint256 canUnStakingAmount)
    {
        canUnStakingAmount = 0;
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            seigManager != address(0)
        ) {
            uint256 stakeOf =
                IISeigManager(seigManager).stakeOf(_layer2, address(this));
            if (
                stakeOf > 0 &&
                totalStakedAmount > 0 &&
                totalStakedAmount.mul(10**9) < stakeOf
            ) {
                canUnStakingAmount = stakeOf.sub(totalStakedAmount.mul(10**9));
            }
        }
    }

    /// @dev  request unstaking the amount of all in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakRequestUnStakingAll(address _layer2)
        external
        override
        lock
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.REQUESTWITHDRAW);
        requestNum = requestNum.add(1);
        checkTokamak();

        uint256 globalWithdrawalDelay =
            IIIDepositManager(depositManager).globalWithdrawalDelay();

        uint256 stakeOf =
            IISeigManager(seigManager).stakeOf(_layer2, address(this));
        require(stakeOf > 0, "TokamakStaker: stakeOf is zero");

        uint256 interval = globalWithdrawalDelay / 14;

        require(
            block.number > endBlock.sub(globalWithdrawalDelay).sub(interval),
            "TokamakStaker:The executable block has not passed"
        );

        IIIDepositManager(depositManager).requestWithdrawalAll(_layer2);

        emit TokamakRequestedUnStakingAll(_layer2);
    }

    /// @dev  Check whether unstakingAll is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return can whether can tokamakRequestUnStakingAll
    function canTokamakRequestUnStakingAll(address _layer2)
        external
        view
        returns (bool can)
    {
        can = false;
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            depositManager != address(0) &&
            seigManager != address(0)
        ) {
            uint256 globalWithdrawalDelay =
                IIIDepositManager(depositManager).globalWithdrawalDelay();
            uint256 interval = globalWithdrawalDelay / 14;
            uint256 stakeOf =
                IISeigManager(seigManager).stakeOf(_layer2, address(this));
            if (
                stakeOf > 0 &&
                block.number > endBlock.sub(globalWithdrawalDelay).sub(interval)
            ) can = true;
        }
    }

    /// @dev  Check whether unstakingAll is possible in layer2
    /// @param _layer2 the layer2 address in tokamak
    /// @return _block  the block to can tokamakRequestUnStakingAll
    function canTokamakRequestUnStakingAllBlock(address _layer2)
        external
        view
        returns (uint256 _block)
    {
        if (
            tokamakLayer2 != address(0) &&
            tokamakLayer2 == _layer2 &&
            depositManager != address(0)
        ) {
            uint256 globalWithdrawalDelay =
                IIIDepositManager(depositManager).globalWithdrawalDelay();
            uint256 interval = globalWithdrawalDelay / 14;

            if (endBlock > globalWithdrawalDelay.add(interval))
                _block = endBlock.sub(globalWithdrawalDelay).sub(interval);
        }
    }

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2)
        external
        override
        lock
        nonZero(stakeRegistry)
        onlyClosed
        sameTokamakLayer(_layer2)
    {
        defiStatus = uint256(LibTokenStake1.DefiStatus.WITHDRAW);

        checkTokamak();

        uint256 num = 0;
        uint256 pamount = 0;
        (num, pamount) = canTokamakProcessUnStakingCount(_layer2);

        require(num > 0 && pamount > 0, "TokamakStaker: no able request");
        fromTokamak = fromTokamak.add(pamount);
        if (requestNum >= num) requestNum = requestNum.sub(num);

        // receiveTON = false . to WTON
        IIIDepositManager(depositManager).processRequests(_layer2, num, true);

        emit TokamakProcessedUnStaking(_layer2, num, true);
    }

    /// @dev TokamakProcessUnStaking Number and amount of withdrawals possible
    /// @param _layer2 the layer2 address in tokamak
    function canTokamakProcessUnStakingCount(address _layer2)
        public
        view
        nonZero(stakeRegistry)
        nonZero(_layer2)
        onlyClosed
        sameTokamakLayer(_layer2)
        returns (uint256 count, uint256 amount)
    {
        uint128 num = 0;
        uint128 pamount = 0;
        uint256 startIndex =
            IIIDepositManager(depositManager).withdrawalRequestIndex(
                _layer2,
                address(this)
            );
        uint256 numPendingRequests =
            IIIDepositManager(depositManager)
                .numPendingRequests(_layer2, address(this))
                .add(startIndex);

        for (uint256 i = startIndex; i < numPendingRequests; i++) {
            uint128 _block = 0;
            uint128 _amount = 0;
            bool processed = false;
            (_block, _amount, processed) = IIIDepositManager(depositManager)
                .withdrawalRequest(_layer2, address(this), i);

            if (
                processed == false &&
                (uint256(_block) > 0 && uint256(_block) < block.number)
            ) {
                num++;
                pamount += _amount;
            } else {
                break;
            }
        }

        return (uint256(num), uint256(pamount));
    }

    /// @dev exchange holded WTON to TOS using uniswap
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param _sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    /// @return amountOut the amount of exchanged out token
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 _sqrtPriceLimitX96,
        uint256 _kind
    ) external override lock onlyClosed returns (uint256 amountOut) {
        require(block.number <= endBlock, "TokamakStaker: period end");
        require(_kind < 2, "TokamakStaker: not available kind");
        checkTokamak();

        {
            uint256 _amountWTON = IERC20BASE2(wton).balanceOf(address(this));
            uint256 _amountTON = IERC20BASE2(ton).balanceOf(address(this));
            uint256 stakeOf = 0;
            if (tokamakLayer2 != address(0)) {
                stakeOf = IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                );
                stakeOf = stakeOf.add(
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    )
                );
            }
            uint256 holdAmount = _amountWTON;
            if (_amountTON > 0)
                holdAmount = holdAmount.add(_amountTON.mul(10**9));
            require(
                holdAmount >= _amountIn,
                "TokamakStaker: wton insufficient"
            );

            if (stakeOf > 0) holdAmount = holdAmount.add(stakeOf);

            require(
                holdAmount > totalStakedAmount.mul(10**9) &&
                    holdAmount.sub(totalStakedAmount.mul(10**9)) >= _amountIn,
                "TokamakStaker:insufficient"
            );
            if (_amountWTON < _amountIn) {
                bytes memory data = abi.encode(swapProxy, swapProxy);
                uint256 swapTON = _amountIn.sub(_amountWTON).div(10**9);
                require(
                    ITON(ton).approveAndCall(wton, swapTON, data),
                    "TokamakStaker:exchangeWTONtoTOS approveAndCall fail"
                );
            }
        }

        toUniswapWTON = toUniswapWTON.add(_amountIn);
        (address uniswapRouter, , , uint256 _fee, ) =
            ITokamakRegistry2(stakeRegistry).getUniswap();
        require(uniswapRouter != address(0), "TokamakStaker:uniswap zero");
        require(
            IERC20BASE2(wton).approve(uniswapRouter, _amountIn),
            "TokamakStaker:can't approve uniswapRouter"
        );

        //if (_kind == 0) {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wton,
                tokenOut: token,
                fee: uint24(_fee),
                recipient: address(this),
                deadline: _deadline,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: _sqrtPriceLimitX96
            });
        amountOut = ISwapRouter(uniswapRouter).exactInputSingle(params);
        /*
        } else if (_kind == 1) {
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        wton,
                        uint24(_fee),
                        wethAddress,
                        uint24(_fee),
                        token
                    ),
                    recipient: address(this),
                    deadline: _deadline,
                    amountIn: _amountIn,
                    amountOutMinimum: _amountOutMinimum
                });
            amountOut = ISwapRouter(uniswapRouter).exactInput(params);
        } */

        emit ExchangedWTONtoTOS(msg.sender, _amountIn, amountOut);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface ITokamakStaker {
    /// @dev set the tokamak Layer2 address
    /// @param _layer2 new the tokamak Layer2 address
    function setTokamakLayer2(address _layer2) external;

    /// @dev get the addresses yhat used in uniswap interfaces
    /// @return uniswapRouter the address of uniswapV3 Router
    /// @return npm the address of positionManagerAddress
    /// @return ext the address of ext
    /// @return fee the amount of fee
    /// @return uniswapV2Router uniswapV2 router address
    function getUniswapInfo()
        external
        view
        returns (
            address uniswapRouter,
            address npm,
            address ext,
            uint256 fee,
            address uniswapV2Router
        );

    /// @dev Change the TON holded in contract have to WTON, or change WTON to TON.
    /// @param amount the amount to be changed
    /// @param toWTON if it's true, TON->WTON , else WTON->TON
    function swapTONtoWTON(uint256 amount, bool toWTON) external;

    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount) external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount the amount requested to unstaking
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakRequestUnStakingAll(address _layer2) external;

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2) external;

    /// @dev exchange holded WTON to TOS using uniswap-v3
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param _sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 _sqrtPriceLimitX96,
        uint256 _kind
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITON {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external;

    function swapToTON(uint256 wtonAmount) external returns (bool);

    function swapFromTON(uint256 tonAmount) external returns (bool);

    function swapToTONAndTransfer(address to, uint256 wtonAmount)
        external
        returns (bool);

    function swapFromTONAndTransfer(address to, uint256 tonAmount)
        external
        returns (bool);

    function renounceTonMinter() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IIIDepositManager {
    function globalWithdrawalDelay()
        external
        view
        returns (uint256 withdrawalDelay);

    function accStaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function accStakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function accStakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function pendingUnstakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstakedLayer2(address layer2)
        external
        view
        returns (uint256 wtonAmount);

    function accUnstakedAccount(address account)
        external
        view
        returns (uint256 wtonAmount);

    function withdrawalRequestIndex(address layer2, address account)
        external
        view
        returns (uint256 index);

    // solhint-disable-next-line max-line-length
    function withdrawalRequest(
        address layer2,
        address account,
        uint256 index
    )
        external
        view
        returns (
            uint128 withdrawableBlockNumber,
            uint128 amount,
            bool processed
        );

    function WITHDRAWAL_DELAY() external view returns (uint256);

    function deposit(address layer2, uint256 amount) external returns (bool);

    function requestWithdrawal(address layer2, uint256 amount)
        external
        returns (bool);

    function processRequest(address layer2, bool receiveTON)
        external
        returns (bool);

    function requestWithdrawalAll(address layer2) external returns (bool);

    function processRequests(
        address layer2,
        uint256 n,
        bool receiveTON
    ) external returns (bool);

    function numRequests(address layer2, address account)
        external
        view
        returns (uint256);

    function numPendingRequests(address layer2, address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IISeigManager {
    function stakeOf(address layer2, address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./Stake1Storage.sol";

/// @title the storage of StakeTONStorage
contract StakeTONStorage is Stake1Storage {
    /// @dev TON address
    address public ton;

    /// @dev WTON address
    address public wton;

    /// @dev SeigManager address
    address public seigManager;

    /// @dev DepositManager address
    address public depositManager;

    /// @dev swapProxy address
    address public swapProxy;

    /// @dev the layer2 address in Tokamak
    address public tokamakLayer2;

    /// @dev the accumulated TON amount staked into tokamak , in wei unit
    uint256 public toTokamak;

    /// @dev the accumulated WTON amount unstaked from tokamak , in ray unit
    uint256 public fromTokamak;

    /// @dev the accumulated WTON amount swapped using uniswap , in ray unit
    uint256 public toUniswapWTON;

    /// @dev the TOS balance in this contract
    uint256 public swappedAmountTOS;

    /// @dev the TON balance in this contract when withdraw at first
    uint256 public finalBalanceTON;

    /// @dev the WTON balance in this contract when withdraw at first
    uint256 public finalBalanceWTON;

    /// @dev defi status
    uint256 public defiStatus;

    /// @dev the number of requesting unstaking to tokamak , when process unstaking, reset zero.
    uint256 public requestNum;

    /// @dev the withdraw flag, when withdraw at first, set true
    bool public withdrawFlag;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "../libraries/LibTokenStake1.sol";

/// @title The base storage of stakeContract
contract Stake1Storage {
    /// @dev reward token : TOS
    address public token;

    /// @dev registry
    address public stakeRegistry;

    /// @dev paytoken is the token that the user stakes. ( if paytoken is ether, paytoken is address(0) )
    address public paytoken;

    /// @dev A vault that holds TOS rewards.
    address public vault;

    /// @dev the start block for sale.
    uint256 public saleStartBlock;

    /// @dev the staking start block, once staking starts, users can no longer apply for staking.
    uint256 public startBlock;

    /// @dev the staking end block.
    uint256 public endBlock;

    /// @dev the total amount claimed
    uint256 public rewardClaimedTotal;

    /// @dev the total staked amount
    uint256 public totalStakedAmount;

    /// @dev information staked by user
    mapping(address => LibTokenStake1.StakedAmount) public userStaked;

    /// @dev total stakers
    uint256 public totalStakers;

    uint256 internal _lock;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev extra address storage
    address public defiAddr;

    ///@dev for migrate L2
    bool public migratedL2;

    /// @dev user's staked information
    function getUserStaked(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 claimedBlock,
            uint256 claimedAmount,
            uint256 releasedBlock,
            uint256 releasedAmount,
            uint256 releasedTOSAmount,
            bool released
        )
    {
        return (
            userStaked[user].amount,
            userStaked[user].claimedBlock,
            userStaked[user].claimedAmount,
            userStaked[user].releasedBlock,
            userStaked[user].releasedAmount,
            userStaked[user].releasedTOSAmount,
            userStaked[user].released
        );
    }

    /// @dev Give the infomation of this stakeContracts
    /// @return paytoken, vault, [saleStartBlock, startBlock, endBlock], rewardClaimedTotal, totalStakedAmount, totalStakers
    function infos()
        external
        view
        returns (
            address,
            address,
            uint256[3] memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            paytoken,
            vault,
            [saleStartBlock, startBlock, endBlock],
            rewardClaimedTotal,
            totalStakedAmount,
            totalStakers
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
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