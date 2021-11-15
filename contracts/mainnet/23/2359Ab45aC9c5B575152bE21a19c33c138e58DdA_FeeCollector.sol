// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IFeeCollector.sol";
import "./utils/BalanceAccounting.sol";


contract FeeCollector is IFeeCollector, BalanceAccounting {
    using SafeERC20 for IERC20;

    event Trade(address indexed token, address indexed trader, uint256 amount, uint256 boughtAmount);
    event UpdateReward(address indexed token, address indexed receiver, uint256 amount);
    event ClaimFrozen(address indexed token, address indexed receiver, uint256 tokenAmount, uint256 swappedTokenAmount);
    event ClaimCurrent(address indexed receiver, uint256 amount);

    struct EpochBalance {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        uint256 traded;
        uint256 tokenBalance;
    }

    struct TokenInfo {
        uint40 lastTime;
        uint216 lastValue;
        mapping(uint256 => EpochBalance) epochBalance;
        uint256 firstUnprocessedEpoch;
        uint256 currentEpoch;
        mapping(address => uint256) firstUserUnprocessedEpoch;
    }

    uint256 private constant _MAX_TIME = 0xfffff;

    mapping(IERC20 => TokenInfo) public tokenInfo;
    IERC20 public immutable token;
    uint256 public immutable minValue;
    uint8 public immutable decimals;

    constructor(
        IERC20 _token,
        uint256 _minValue
    ) {
        token = _token;
        minValue = _minValue;
        decimals = IERC20Metadata(address(_token)).decimals();
    }

    function name() external view returns(string memory) {
        return string(abi.encodePacked("FeeCollector: ", IERC20Metadata(address(token)).name()));
    }

    function symbol() external view returns(string memory) {
        return string(abi.encodePacked("fee-", IERC20Metadata(address(token)).symbol()));
    }

    function getEpochBalance(IERC20 _token, uint256 epoch) external view returns(uint256 totalSupply, uint256 traded, uint256 tokenBalance) {
        EpochBalance storage epochBalance = tokenInfo[_token].epochBalance[epoch];
        (totalSupply, traded, tokenBalance) = (epochBalance.totalSupply, epochBalance.traded, epochBalance.tokenBalance);
    }

    function getUserEpochBalance(IERC20 _token, uint256 epoch, address user) external view returns(uint256 balance) {
        balance = tokenInfo[_token].epochBalance[epoch].balances[user];
    }

    function getFirstUserUnprocessedEpoch(IERC20 _token, address user) external view returns(uint256 firstUserUnprocessedEpoch) {
        firstUserUnprocessedEpoch = tokenInfo[_token].firstUserUnprocessedEpoch[user];
    }

    function decelerationTable() external pure returns(uint256[20] memory ret) {
        ret[0] = 0.9999e36;
        for (uint256 i = 1; i < 20; ++i) {
            ret[i] = ret[i-1] * ret[i-1] / 1e36;
        }
    }

    function value(IERC20 _token) public view returns(uint256 result) {
        return valueForTime(block.timestamp, _token);
    }

    function valueForTime(uint256 time, IERC20 _token) public view returns(uint256 result) {
        uint256 secs = tokenInfo[_token].lastTime;
        result = tokenInfo[_token].lastValue;

        secs = time - secs;
        if (secs > _MAX_TIME) {
            secs = _MAX_TIME;
        }
        if (result < minValue) {
            result = minValue;
        }

        uint256 minValue_ = minValue;
        assembly { // solhint-disable-line no-inline-assembly
            if and(secs, 0x00000F) {
                if and(secs, 0x000001) {
                    result := div(mul(result, 999900000000000000000000000000000000), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000002) {
                    result := div(mul(result, 999800010000000000000000000000000000), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000004) {
                    result := div(mul(result, 999600059996000100000000000000000000), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000008) {
                    result := div(mul(result, 999200279944006999440027999200010000), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }
            }

            if and(secs, 0x0000F0) {
                if and(secs, 0x000010) {
                    result := div(mul(result, 998401199440181956328006856128688560), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000020) {
                    result := div(mul(result, 996804955043593987145855519554957648), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000040) {
                    result := div(mul(result, 993620118399461429792290614928235372), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000080) {
                    result := div(mul(result, 987280939688159750172898466482272707), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }
            }

            if and(secs, 0x000F00) {
                if and(secs, 0x000100) {
                    result := div(mul(result, 974723653871535730138973062438582481), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000200) {
                    result := div(mul(result, 950086201416677390961738571086337286), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000400) {
                    result := div(mul(result, 902663790122371280016479918855854806), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x000800) {
                    result := div(mul(result, 814801917998084346828628782199508463), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }
            }

            if and(secs, 0x00F000) {
                if and(secs, 0x001000) {
                    result := div(mul(result, 663902165573356968243491567819400493), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x002000) {
                    result := div(mul(result, 440766085452993090398118811102456830), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x004000) {
                    result := div(mul(result, 194274742085555207178862579417407102), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x008000) {
                    result := div(mul(result, 37742675412408995610179844414960649), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }
            }

            if and(secs, 0x0F0000) {
                if and(secs, 0x010000) {
                    result := div(mul(result, 1424509547286462546864068778806188), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x020000) {
                    result := div(mul(result, 2029227450310282474813662564103), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x040000) {
                    result := div(mul(result, 4117764045092769930387910), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }

                if and(secs, 0x080000) {
                    result := div(mul(result, 16955980731058), 1000000000000000000000000000000000000)
                    if lt(result, minValue_) {
                        result := minValue_
                        secs := 0
                    }
                }
            }
        }
    }

    function updateRewards(address[] calldata receivers, uint256[] calldata amounts) external override {
        for (uint i = 0; i < receivers.length; i++) {
            _updateReward(IERC20(msg.sender), receivers[i], amounts[i]);
        }
    }

    function updateReward(address receiver, uint256 amount) external override {
        _updateReward(IERC20(msg.sender), receiver, amount);
    }

    function updateRewardNonLP(IERC20 erc20, address receiver, uint256 amount) external override {
        _updateReward(erc20, receiver, amount);
        erc20.safeTransferFrom(msg.sender, address(this), amount);
    }

    function trade(IERC20 erc20, uint256 amount, uint256 minReturn) external {
        TokenInfo storage _token = tokenInfo[erc20];
        uint256 currentEpoch = _token.currentEpoch;
        uint256 firstUnprocessedEpoch = _token.firstUnprocessedEpoch;
        EpochBalance storage epochBalance = _token.epochBalance[firstUnprocessedEpoch];
        EpochBalance storage currentEpochBalance = _token.epochBalance[currentEpoch];

        uint256 currentEpochStored = currentEpoch;

        uint256 unprocessedTotalSupply = epochBalance.totalSupply;
        uint256 unprocessedTokenBalance = unprocessedTotalSupply - epochBalance.traded;
        uint256 tokenBalance = unprocessedTokenBalance;
        if (firstUnprocessedEpoch != currentEpoch) {
            tokenBalance += currentEpochBalance.totalSupply;
        }

        uint256 returnAmount = amount * tokenBalance / value(erc20);
        require(tokenBalance >= returnAmount, "not enough tokens");
        require(returnAmount >= minReturn, "minReturn not met");

        if (firstUnprocessedEpoch == currentEpoch) {
            currentEpoch += 1;
        }

        _updateTokenState(erc20, -int256(returnAmount), currentEpochStored, firstUnprocessedEpoch);

        if (returnAmount <= unprocessedTokenBalance) {
            if (returnAmount == unprocessedTokenBalance) {
                _token.firstUnprocessedEpoch += 1;
            }

            epochBalance.traded += returnAmount;
            epochBalance.tokenBalance += amount;
        } else {
            uint256 amountPart = unprocessedTokenBalance * amount / returnAmount;

            epochBalance.traded = unprocessedTotalSupply;
            epochBalance.tokenBalance += amountPart;

            currentEpochBalance.traded += returnAmount - unprocessedTokenBalance;
            currentEpochBalance.tokenBalance += amount - amountPart;

            _token.firstUnprocessedEpoch += 1;
            currentEpoch += 1;
        }

        if (currentEpoch != currentEpochStored) {
            _token.currentEpoch = currentEpoch;
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        erc20.safeTransfer(msg.sender, returnAmount);
        emit Trade(address(erc20), msg.sender, amount, returnAmount);
    }

    function claim(IERC20[] memory pools) external {
        for (uint256 i = 0; i < pools.length; ++i) {
            TokenInfo storage _token = tokenInfo[pools[i]];
            _collectProcessedEpochs(msg.sender, _token, _token.currentEpoch, _token.firstUnprocessedEpoch);
        }

        uint256 userBalance = balanceOf(msg.sender);
        if (userBalance > 1) {
            // Avoid erasing storage to decrease gas footprint for payments
            unchecked {
                uint256 withdrawn = userBalance - 1;
                _burn(msg.sender, withdrawn);
                token.safeTransfer(msg.sender, withdrawn);
            }
        }
    }

    function claimCurrentEpoch(IERC20 erc20) external {
        TokenInfo storage _token = tokenInfo[erc20];
        EpochBalance storage _epochBalance = _token.epochBalance[_token.currentEpoch];
        uint256 userBalance = _epochBalance.balances[msg.sender];
        if (userBalance > 0) {
            _epochBalance.balances[msg.sender] = 0;
            _epochBalance.totalSupply -= userBalance;
            erc20.safeTransfer(msg.sender, userBalance);
            emit ClaimCurrent(msg.sender, userBalance);
        }
    }

    function claimFrozenEpoch(IERC20 erc20) external {
        TokenInfo storage _token = tokenInfo[erc20];
        uint256 firstUnprocessedEpoch = _token.firstUnprocessedEpoch;
        uint256 currentEpoch = _token.currentEpoch;

        require(firstUnprocessedEpoch + 1 == currentEpoch, "Epoch already finalized");
        require(_token.firstUserUnprocessedEpoch[msg.sender] == firstUnprocessedEpoch, "Epoch funds already claimed");

        _token.firstUserUnprocessedEpoch[msg.sender] = currentEpoch;
        EpochBalance storage epochBalance = _token.epochBalance[firstUnprocessedEpoch];
        uint256 share = epochBalance.balances[msg.sender];

        if (share > 0) {
            uint256 totalSupply = epochBalance.totalSupply;
            epochBalance.balances[msg.sender] = 0;
            epochBalance.totalSupply = totalSupply - share;
            uint256 withdrawnERC20 = _transferTokenShare(erc20, totalSupply - epochBalance.traded, share, totalSupply);
            uint256 withdrawnToken = _transferTokenShare(token, epochBalance.tokenBalance, share, totalSupply);
            epochBalance.tokenBalance -= withdrawnToken;
            emit ClaimFrozen(address(erc20), msg.sender, withdrawnERC20, withdrawnToken);
        }
    }

    function _updateReward(IERC20 erc20, address receiver, uint256 amount) private {
        TokenInfo storage _token = tokenInfo[erc20];
        uint256 currentEpoch = _token.currentEpoch;
        uint256 firstUnprocessedEpoch = _token.firstUnprocessedEpoch;

        _updateTokenState(erc20, int256(amount), currentEpoch, firstUnprocessedEpoch);

        // Add new reward to current epoch
        _token.epochBalance[currentEpoch].balances[receiver] += amount;
        _token.epochBalance[currentEpoch].totalSupply += amount;

        // Collect all processed epochs and advance user token epoch
        _collectProcessedEpochs(receiver, _token, currentEpoch, firstUnprocessedEpoch);
        emit UpdateReward(address(erc20), receiver, amount);
    }

    function _updateTokenState(IERC20 erc20, int256 amount, uint256 currentEpoch, uint256 firstUnprocessedEpoch) private {
        TokenInfo storage _token = tokenInfo[erc20];

        uint256 fee = _token.epochBalance[firstUnprocessedEpoch].totalSupply - _token.epochBalance[firstUnprocessedEpoch].traded;
        if (firstUnprocessedEpoch != currentEpoch) {
            fee += _token.epochBalance[currentEpoch].totalSupply;
        }

        uint256 feeWithAmount = (amount >= 0 ? fee + uint256(amount) : fee - uint256(-amount));
        (
            tokenInfo[erc20].lastTime,
            tokenInfo[erc20].lastValue
        ) = (
            uint40(block.timestamp),
            uint216(valueForTime(block.timestamp, erc20) * feeWithAmount / (fee == 0 ? 1 : fee))
        );
    }

    function _transferTokenShare(IERC20 _token, uint256 balance, uint256 share, uint256 totalSupply) private returns(uint256 amount) {
        amount = balance * share / totalSupply;
        if (amount > 0) {
            _token.safeTransfer(msg.sender, amount);
        }
    }

    function _collectProcessedEpochs(address user, TokenInfo storage _token, uint256 currentEpoch, uint256 tokenEpoch) private {
        uint256 userEpoch = _token.firstUserUnprocessedEpoch[user];

        if (tokenEpoch <= userEpoch) {
            return;
        }

        // Early return for the new users
        if (_token.epochBalance[userEpoch].balances[user] == 0) {
            _token.firstUserUnprocessedEpoch[user] = currentEpoch;
            return;
        }

        uint256 epochCount = Math.min(2, tokenEpoch - userEpoch); // 1 or 2 epochs

        // Claim 1 or 2 processed epochs for the user
        uint256 collected = _collectEpoch(user, _token, userEpoch);
        if (epochCount > 1) {
            collected += _collectEpoch(user, _token, userEpoch + 1);
        }
        _mint(user, collected);

        // Update user token epoch counter
        bool emptySecondEpoch = _token.epochBalance[userEpoch + 1].balances[user] == 0;
        _token.firstUserUnprocessedEpoch[user] = (epochCount == 2 || emptySecondEpoch) ? currentEpoch : userEpoch + 1;
    }

    function _collectEpoch(address user, TokenInfo storage _token, uint256 epoch) private returns(uint256 collected) {
        uint256 share = _token.epochBalance[epoch].balances[user];
        if (share > 0) {
            uint256 tokenBalance = _token.epochBalance[epoch].tokenBalance;
            uint256 totalSupply = _token.epochBalance[epoch].totalSupply;

            collected = tokenBalance * share / totalSupply;

            _token.epochBalance[epoch].balances[user] = 0;
            _token.epochBalance[epoch].totalSupply = totalSupply - share;
            _token.epochBalance[epoch].tokenBalance = tokenBalance - collected;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IFeeCollector {
    function updateReward(address receiver, uint256 amount) external;
    function updateRewardNonLP(IERC20 erc20, address receiver, uint256 amount) external;
    function updateRewards(address[] calldata receivers, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract BalanceAccounting {
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] -= amount;
        unchecked {
            _totalSupply -= amount;
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

