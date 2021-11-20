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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ILinearVestingHub} from "./interfaces/ILinearVestingHub.sol";
import {Vesting} from "./structs/SVesting.sol";
import {
    _getVestedTkns,
    _getTknMaxWithdraw
} from "./functions/VestingFormulaFunctions.sol";

contract LinearVestingHubHelper {
    // solhint-disable-next-line var-name-mixedcase
    ILinearVestingHub public immutable LINEAR_VESTING_HUB;

    constructor(ILinearVestingHub linearVestingHub_) {
        LINEAR_VESTING_HUB = linearVestingHub_;
    }

    function isLinearVestingHubHealthy() external view returns (bool) {
        return
            LINEAR_VESTING_HUB.TOKEN().balanceOf(address(LINEAR_VESTING_HUB)) ==
            calcTotalBalance();
    }

    function getVestingsPaginated(
        address receiver_,
        uint256 startVestingId_,
        uint256 pageSize_
    ) external view returns (Vesting[] memory vestings) {
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            receiver_
        );
        uint256 endVestingId = nextVestingId > startVestingId_ + pageSize_
            ? startVestingId_ + pageSize_
            : nextVestingId;
        vestings = new Vesting[](endVestingId - startVestingId_);

        uint8 j = 0;
        for (uint256 i = startVestingId_; i < endVestingId; i++) {
            vestings[j] = LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, i);
            j++;
        }
    }

    function getMaxWithdrawByVesting(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? _getTknMaxWithdraw(
                        vesting.tokenBalance,
                        vesting.withdrawnTokens,
                        vesting.startTime,
                        vesting.cliffDuration,
                        vesting.duration
                    )
                    : 0;
        } catch {
            return 0;
        }
    }

    function getMaxWithdrawByReceiver(address receiver_)
        public
        view
        returns (uint256 maxWithdraw)
    {
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            receiver_
        );

        for (uint256 i = 0; i < nextVestingId; i++)
            maxWithdraw += getMaxWithdrawByVesting(receiver_, i);
    }

    function getVestedTkn(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? _getVestedTkns(
                        vesting.tokenBalance,
                        vesting.withdrawnTokens,
                        vesting.startTime,
                        vesting.duration
                    )
                    : 0;
        } catch {
            return 0;
        }
    }

    function getUnvestedTkn(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? vesting.tokenBalance -
                        _getTknMaxWithdraw(
                            vesting.tokenBalance,
                            vesting.withdrawnTokens,
                            vesting.startTime,
                            vesting.cliffDuration,
                            vesting.duration
                        )
                    : 0;
        } catch {
            return 0;
        }
    }

    function calcTotalVestedTokens()
        public
        view
        returns (uint256 totalVestedTkn)
    {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalVestedTkn += getVestedTkn(receivers[i], j);
        }
    }

    function calcTotalUnvestedTokens()
        public
        view
        returns (uint256 totalUnvestedTkn)
    {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalUnvestedTkn += getUnvestedTkn(receivers[i], j);
        }
    }

    function getVestingBalance(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return vesting.receiver != address(0) ? vesting.tokenBalance : 0;
        } catch {
            return 0;
        }
    }

    function calcTotalBalance() public view returns (uint256 totalBalance) {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalBalance += getVestingBalance(receivers[i], j);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

function _getVestedTkns(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 duration_
) view returns (uint256) {
    if (block.timestamp < startDate_) return 0;
    if (block.timestamp >= startDate_ + duration_)
        return tknBalance_ + tknWithdrawn_;
    return
        ((tknBalance_ + tknWithdrawn_) * (block.timestamp - startDate_)) /
        duration_;
}

function _getTknMaxWithdraw(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 cliffDuration_,
    uint256 duration_
) view returns (uint256) {
    // Vesting has not started and/or cliff has not passed
    if (block.timestamp < startDate_ + cliffDuration_) return 0;

    uint256 vestedTkns = _getVestedTkns(
        tknBalance_,
        tknWithdrawn_,
        startDate_,
        duration_
    );

    return vestedTkns > tknWithdrawn_ ? vestedTkns - tknWithdrawn_ : 0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Vesting} from "../structs/SVesting.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILinearVestingHub {
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN() external view returns (IERC20);

    function nextVestingIdByReceiver(address receiver_)
        external
        view
        returns (uint256);

    function vestingsByReceiver(address receiver_, uint256 id_)
        external
        view
        returns (Vesting memory);

    function totalWithdrawn() external view returns (uint256);

    function isReceiver(address receiver_) external view returns (bool);

    function receiverAt(uint256 index_) external view returns (address);

    function receivers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct Vesting {
    uint8 id;
    address receiver;
    uint256 tokenBalance; // remaining token balance
    uint256 withdrawnTokens; //
    uint256 startTime; // vesting start time.
    uint256 cliffDuration; // lockup time.
    uint256 duration;
}