// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../libraries/ExchangeConstants.sol";
import "../libraries/LiquidVoting.sol";
import "../libraries/SafeCast.sol";
import "../utils/BalanceAccounting.sol";
import "./BaseGovernanceModule.sol";


contract ExchangeGovernance is BaseGovernanceModule, BalanceAccounting {
    using Vote for Vote.Data;
    using LiquidVoting for LiquidVoting.Data;
    using VirtualVote for VirtualVote.Data;
    using SafeCast for uint256;

    event LeftoverGovernanceShareUpdate(address indexed user, uint256 vote, bool isDefault, uint256 amount);
    event LeftoverReferralShareUpdate(address indexed user, uint256 vote, bool isDefault, uint256 amount);

    LiquidVoting.Data private _leftoverGovernanceShare;

    constructor(address _mothership) public BaseGovernanceModule(_mothership) {
        _leftoverGovernanceShare.data.result = ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE.toUint104();
    }

    function parameters() external view returns(uint256 govShare, uint256 refShare) {
        govShare = _leftoverGovernanceShare.data.current();
        refShare = ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(govShare);
    }

    function leftoverGovernanceShare() external view returns(uint256) {
        return _leftoverGovernanceShare.data.current();
    }

    function leftoverGovernanceShareVotes(address user) external view returns(uint256) {
        return _leftoverGovernanceShare.votes[user].get(ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE);
    }

    function virtualLeftoverGovernanceShare() external view returns(uint104, uint104, uint48) {
        return (_leftoverGovernanceShare.data.oldResult, _leftoverGovernanceShare.data.result, _leftoverGovernanceShare.data.time);
    }

    //

    function leftoverReferralShare() external view returns(uint256) {
        return ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(_leftoverGovernanceShare.data.current());
    }

    function leftoverReferralShareVotes(address user) external view returns(uint256) {
        return ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(_leftoverGovernanceShare.votes[user].get(ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE));
    }

    function virtualLeftoverReferralShare() external view returns(uint104, uint104, uint48) {
        return (
            ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(_leftoverGovernanceShare.data.oldResult).toUint104(),
            ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(_leftoverGovernanceShare.data.result).toUint104(),
            _leftoverGovernanceShare.data.time
        );
    }

    ///

    function leftoverShareVote(uint256 govShare) external {
        uint256 refShare = ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(govShare, "Governance share is too high");

        uint256 balance = balanceOf(msg.sender);
        uint256 supply = totalSupply();

        _leftoverGovernanceShare.updateVote(
            msg.sender,
            _leftoverGovernanceShare.votes[msg.sender],
            Vote.init(govShare),
            balance,
            supply,
            ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE,
            _emitLeftoverGovernanceShareVoteUpdate
        );

        _emitLeftoverReferralShareVoteUpdate(msg.sender, refShare, false, balance);
    }

    function discardLeftoverShareVote() external {
        uint256 balance = balanceOf(msg.sender);
        uint256 supply = totalSupply();

        _leftoverGovernanceShare.updateVote(
           msg.sender,
           _leftoverGovernanceShare.votes[msg.sender],
           Vote.init(),
           balance,
           supply,
           ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE,
           _emitLeftoverGovernanceShareVoteUpdate
        );

        _emitLeftoverReferralShareVoteUpdate(msg.sender, ExchangeConstants._DEFAULT_LEFTOVER_REF_SHARE, true, balance);
    }

    function _notifyStakeChanged(address account, uint256 newBalance) internal override {
        uint256 balance = _set(account, newBalance);
        if (newBalance == balance) {
            return;
        }

        Vote.Data memory govShareVote = _leftoverGovernanceShare.votes[account];
        uint256 refShare = ExchangeConstants._LEFTOVER_TOTAL_SHARE.sub(govShareVote.get(ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE));
        uint256 supply = totalSupply();

        _leftoverGovernanceShare.updateBalance(
            account,
            govShareVote,
            balance,
            newBalance,
            supply,
            ExchangeConstants._DEFAULT_LEFTOVER_GOV_SHARE,
            _emitLeftoverGovernanceShareVoteUpdate
        );

        _emitLeftoverReferralShareVoteUpdate(
            account,
            refShare,
            govShareVote.isDefault(),
            newBalance
        );
    }

    function _emitLeftoverGovernanceShareVoteUpdate(address user, uint256 newDefaultShare, bool isDefault, uint256 balance) private {
        emit LeftoverGovernanceShareUpdate(user, newDefaultShare, isDefault, balance);
    }

    function _emitLeftoverReferralShareVoteUpdate(address user, uint256 newDefaultShare, bool isDefault, uint256 balance) private {
        emit LeftoverReferralShareUpdate(user, newDefaultShare, isDefault, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library ExchangeConstants {
    uint256 internal constant _LEFTOVER_TOTAL_SHARE = 1e18;          // 100%
    uint256 internal constant _DEFAULT_LEFTOVER_GOV_SHARE = 0.5e18;  //  50%
    uint256 internal constant _DEFAULT_LEFTOVER_REF_SHARE = 0.5e18;  //  50%
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeCast.sol";
import "./VirtualVote.sol";
import "./Vote.sol";


library LiquidVoting {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Vote for Vote.Data;
    using VirtualVote for VirtualVote.Data;

    struct Data {
        VirtualVote.Data data;
        uint256 _weightedSum;
        uint256 _defaultVotes;
        mapping(address => Vote.Data) votes;
    }

    function updateVote(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 balance,
        uint256 totalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newVote, balance, balance, totalSupply, defaultVote, emitEvent);
    }

    function updateBalance(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newBalance == 0 ? Vote.init() : oldVote, oldBalance, newBalance, newTotalSupply, defaultVote, emitEvent);
    }

    function _update(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) private {
        uint256 oldWeightedSum = self._weightedSum;
        uint256 newWeightedSum = oldWeightedSum;
        uint256 oldDefaultVotes = self._defaultVotes;
        uint256 newDefaultVotes = oldDefaultVotes;

        if (oldVote.isDefault()) {
            newDefaultVotes = newDefaultVotes.sub(oldBalance);
        } else {
            newWeightedSum = newWeightedSum.sub(oldBalance.mul(oldVote.get(defaultVote)));
        }

        if (newVote.isDefault()) {
            newDefaultVotes = newDefaultVotes.add(newBalance);
        } else {
            newWeightedSum = newWeightedSum.add(newBalance.mul(newVote.get(defaultVote)));
        }

        if (newWeightedSum != oldWeightedSum) {
            self._weightedSum = newWeightedSum;
        }

        if (newDefaultVotes != oldDefaultVotes) {
            self._defaultVotes = newDefaultVotes;
        }

        {
            uint256 newResult = newTotalSupply == 0 ? defaultVote : newWeightedSum.add(newDefaultVotes.mul(defaultVote)).div(newTotalSupply);
            VirtualVote.Data memory data = self.data;

            if (newResult != data.result) {
                VirtualVote.Data storage sdata = self.data;
                (sdata.oldResult, sdata.result, sdata.time) = (
                    data.current().toUint104(),
                    newResult.toUint104(),
                    block.timestamp.toUint48()
                );
            }
        }

        if (!newVote.eq(oldVote)) {
            self.votes[user] = newVote;
        }

        emitEvent(user, newVote.get(defaultVote), newVote.isDefault(), newBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeCast {
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value < 2**216, "value does not fit in 216 bits");
        return uint216(value);
    }

    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value < 2**104, "value does not fit in 104 bits");
        return uint104(value);
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "value does not fit in 48 bits");
        return uint48(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "value does not fit in 40 bits");
        return uint40(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract BalanceAccounting {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _set(address account, uint256 amount) internal virtual returns(uint256 oldAmount) {
        oldAmount = _balances[account];
        if (oldAmount != amount) {
            _balances[account] = amount;
            _totalSupply = _totalSupply.add(amount).sub(oldAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../interfaces/IGovernanceModule.sol";


abstract contract BaseGovernanceModule is IGovernanceModule {
    address public immutable mothership;

    modifier onlyMothership {
        require(msg.sender == mothership, "Access restricted to mothership");

        _;
    }

    constructor(address _mothership) public {
        mothership = _mothership;
    }

    function notifyStakesChanged(address[] calldata accounts, uint256[] calldata newBalances) external override onlyMothership {
        require(accounts.length == newBalances.length, "Arrays length should be equal");

        for(uint256 i = 0; i < accounts.length; ++i) {
            _notifyStakeChanged(accounts[i], newBalances[i]);
        }
    }

    function notifyStakeChanged(address account, uint256 newBalance) external override onlyMothership {
        _notifyStakeChanged(account, newBalance);
    }

    function _notifyStakeChanged(address account, uint256 newBalance) internal virtual;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


library VirtualVote {
    using SafeMath for uint256;

    uint256 private constant _VOTE_DECAY_PERIOD = 1 days;

    struct Data {
        uint104 oldResult;
        uint104 result;
        uint48 time;
    }

    function current(VirtualVote.Data memory self) internal view returns(uint256) {
        uint256 timePassed = Math.min(_VOTE_DECAY_PERIOD, block.timestamp.sub(self.time));
        uint256 timeRemain = _VOTE_DECAY_PERIOD.sub(timePassed);
        return uint256(self.oldResult).mul(timeRemain).add(
            uint256(self.result).mul(timePassed)
        ).div(_VOTE_DECAY_PERIOD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


library Vote {
    struct Data {
        uint256 value;
    }

    function eq(Vote.Data memory self, Vote.Data memory vote) internal pure returns(bool) {
        return self.value == vote.value;
    }

    function init() internal pure returns(Vote.Data memory data) {
        return Vote.Data({
            value: 0
        });
    }

    function init(uint256 vote) internal pure returns(Vote.Data memory data) {
        return Vote.Data({
            value: vote + 1
        });
    }

    function isDefault(Data memory self) internal pure returns(bool) {
        return self.value == 0;
    }

    function get(Data memory self, uint256 defaultVote) internal pure returns(uint256) {
        if (self.value > 0) {
            return self.value - 1;
        }
        return defaultVote;
    }

    function get(Data memory self, function() external view returns(uint256) defaultVoteFn) internal view returns(uint256) {
        if (self.value > 0) {
            return self.value - 1;
        }
        return defaultVoteFn();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IGovernanceModule {
    function notifyStakeChanged(address account, uint256 newBalance) external;
    function notifyStakesChanged(address[] calldata accounts, uint256[] calldata newBalances) external;
}