// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./interfaces/IEPoolHelper.sol";
import "./interfaces/IEPool.sol";

import "./EPoolLibrary.sol";

contract EPoolHelper is IEPoolHelper {

    function currentRatio(IEPool ePool, address eToken) external view override returns(uint256) {
        return EPoolLibrary.currentRatio(ePool.getTranche(eToken), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function delta(
        IEPool ePool
    ) external view override returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        return EPoolLibrary.delta(ePool.getTranches(), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function eTokenForTokenATokenB(
        IEPool ePool,
        address eToken,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.eTokenForTokenATokenB(
            ePool.getTranche(eToken), amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
    }

    function tokenATokenBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view override returns (uint256 amountA, uint256 amountB) {
        return EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
    }

    function tokenATokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 _totalA
    ) external view override returns (uint256 amountA, uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenATokenBForTokenA(
            _totalA,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenATokenBForTokenB(
        IEPool ePool,
        address eToken,
        uint256 _totalB
    ) external view override returns (uint256 amountA, uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenATokenBForTokenB(
            _totalB,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 amountA
    ) external view override returns (uint256 amountB) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenBForTokenA(
            amountA,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function tokenAForTokenB(
        IEPool ePool,
        address eToken,
        uint256 amountB
    ) external view override returns (uint256 amountA) {
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 rate = ePool.getRate();
        return EPoolLibrary.tokenAForTokenB(
            amountB,
            EPoolLibrary.currentRatio(ePool.getTranche(eToken), rate, sFactorA, sFactorB),
            rate,
            sFactorA,
            sFactorB
        );
    }

    function totalA(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.totalA(amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function totalB(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view override returns (uint256) {
        return EPoolLibrary.totalB(amountA, amountB, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB());
    }

    function feeAFeeBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view override returns (uint256 feeA, uint256 feeB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        return EPoolLibrary.feeAFeeBForTokenATokenB(amountA, amountB, ePool.feeRate());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./IEPool.sol";

interface IEPoolHelper {

    function currentRatio(IEPool ePool, address eToken) external view returns(uint256);

    function delta(IEPool ePool) external view returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);

    function eTokenForTokenATokenB(
        IEPool ePool,
        address eToken,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function tokenATokenBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 _totalA
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenATokenBForTokenB(
        IEPool ePool,
        address eToken,
        uint256 _totalB
    ) external view returns (uint256 amountA, uint256 amountB);

    function tokenBForTokenA(
        IEPool ePool,
        address eToken,
        uint256 amountA
    ) external view returns (uint256 amountB);

    function tokenAForTokenB(
        IEPool ePool,
        address eToken,
        uint256 amountB
    ) external view returns (uint256 amountA);

    function totalA(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function totalB(
        IEPool ePool,
        uint256 amountA,
        uint256 amountB
    ) external view returns (uint256);

    function feeAFeeBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 feeA, uint256 feeB);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEToken.sol";

interface IEPool {
    struct Tranche {
        IEToken eToken;
        uint256 sFactorE;
        uint256 reserveA;
        uint256 reserveB;
        uint256 targetRatio;
    }

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function tokenA() external view returns (IERC20);

    function tokenB() external view returns (IERC20);

    function sFactorA() external view returns (uint256);

    function sFactorB() external view returns (uint256);

    function getTranche(address eToken) external view returns (Tranche memory);

    function getTranches() external view returns(Tranche[] memory _tranches);

    function addTranche(uint256 targetRatio, string memory eTokenName, string memory eTokenSymbol) external returns (bool);

    function getAggregator() external view returns (address);

    function setAggregator(address oracle, bool inverseRate) external returns (bool);

    function rebalanceMinRDiv() external view returns (uint256);

    function rebalanceInterval() external view returns (uint256);

    function lastRebalance() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function cumulativeFeeA() external view returns (uint256);

    function cumulativeFeeB() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external returns (bool);

    function transferFees() external returns (bool);

    function getRate() external view returns (uint256);

    function rebalance(uint256 fracDelta) external returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);

    function issueExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function redeemExact(address eToken, uint256 amount) external returns (uint256 amountA, uint256 amountB);

    function recover(IERC20 token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IETokenFactory.sol";
import "./interfaces/IEToken.sol";
import "./interfaces/IEPool.sol";
import "./utils/TokenUtils.sol";
import "./utils/Math.sol";

library EPoolLibrary {
    using TokenUtils for IERC20;

    uint256 internal constant sFactorI = 1e18; // internal scaling factor (18 decimals)

    /**
     * @notice Returns the target ratio if reserveA and reserveB are 0 (for initial deposit)
     * currentRatio := (reserveA denominated in tokenB / reserveB denominated in tokenB) with decI decimals
     */
    function currentRatio(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        if (t.reserveA == 0 || t.reserveB == 0) {
            if (t.reserveA == 0 && t.reserveB == 0) return t.targetRatio;
            if (t.reserveA == 0) return 0;
            if (t.reserveB == 0) return type(uint256).max;
        }
        return ((t.reserveA * rate / sFactorA) * sFactorI) / (t.reserveB * sFactorI / sFactorB);
    }

    /**
     * @notice Returns the deviation of reserveA and reserveB from target ratio
     * currentRatio > targetRatio: release TokenA liquidity and add TokenB liquidity
     * currentRatio < targetRatio: add TokenA liquidity and release TokenB liquidity
     * deltaA := abs(t.reserveA, (t.reserveB / rate * t.targetRatio)) / (1 + t.targetRatio)
     * deltaB := deltaA * rate
     */
    function trancheDelta(
        IEPool.Tranche memory t,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange) {
        rChange = (currentRatio(t, rate, sFactorA, sFactorB) < t.targetRatio) ? 1 : 0;
        deltaA = (
            Math.abs(t.reserveA, tokenAForTokenB(t.reserveB, t.targetRatio, rate, sFactorA, sFactorB)) * sFactorA
        ) / (sFactorA + (t.targetRatio * sFactorA / sFactorI));
        // (convert to TokenB precision first to avoid altering deltaA)
        deltaB = ((deltaA * sFactorB / sFactorA) * rate) / sFactorI;
        // round to 0 in case of rounding errors
        if (deltaA == 0 || deltaB == 0) (deltaA, deltaB, rChange) = (0, 0, 0);
    }

    /**
     * @notice Returns the sum of the tranches reserve deltas
     */
    function delta(
        IEPool.Tranche[] memory ts,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        uint256 totalReserveA;
        int256 totalDeltaA;
        int256 totalDeltaB;
        for (uint256 i = 0; i < ts.length; i++) {
            totalReserveA += ts[i].reserveA;
            (uint256 _deltaA, uint256 _deltaB, uint256 _rChange) = trancheDelta(
                ts[i], rate, sFactorA, sFactorB
            );
            (totalDeltaA, totalDeltaB) = (_rChange == 0)
                ? (totalDeltaA - int256(_deltaA), totalDeltaB + int256(_deltaB))
                : (totalDeltaA + int256(_deltaA), totalDeltaB - int256(_deltaB));

        }
        if (totalDeltaA > 0 && totalDeltaB < 0)  {
            (deltaA, deltaB, rChange) = (uint256(totalDeltaA), uint256(-totalDeltaB), 1);
        } else if (totalDeltaA < 0 && totalDeltaB > 0) {
            (deltaA, deltaB, rChange) = (uint256(-totalDeltaA), uint256(totalDeltaB), 0);
        }
        rDiv = (totalReserveA == 0) ? 0 : deltaA * EPoolLibrary.sFactorI / totalReserveA;
    }

    /**
     * @notice how much EToken can be issued, redeemed for amountA and amountB
     * initial issuance / last redemption: sqrt(amountA * amountB)
     * subsequent issuances / non nullifying redemptions: claim on reserve * EToken total supply
     */
    function eTokenForTokenATokenB(
        IEPool.Tranche memory t,
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256) {
        uint256 amountsA = totalA(amountA, amountB, rate, sFactorA, sFactorB);
        if (t.reserveA + t.reserveB == 0) {
            return (Math.sqrt((amountsA * t.sFactorE / sFactorA) * t.sFactorE));
        }
        uint256 reservesA = totalA(t.reserveA, t.reserveB, rate, sFactorA, sFactorB);
        uint256 share = ((amountsA * t.sFactorE / sFactorA) * t.sFactorE) / (reservesA * t.sFactorE / sFactorA);
        return share * t.eToken.totalSupply() / t.sFactorE;
    }

    /**
     * @notice Given an amount of EToken, how much TokenA and TokenB have to be deposited, withdrawn for it
     * initial issuance / last redemption: sqrt(amountA * amountB) -> such that the inverse := EToken amount ** 2
     * subsequent issuances / non nullifying redemptions: claim on EToken supply * reserveA/B
     */
    function tokenATokenBForEToken(
        IEPool.Tranche memory t,
        uint256 amount,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (t.reserveA + t.reserveB == 0) {
            uint256 amountsA = amount * sFactorA / t.sFactorE;
            (amountA, amountB) = tokenATokenBForTokenA(
                amountsA * amountsA / sFactorA , t.targetRatio, rate, sFactorA, sFactorB
            );
        } else {
            uint256 eTokenTotalSupply = t.eToken.totalSupply();
            if (eTokenTotalSupply == 0) return(0, 0);
            uint256 share = amount * t.sFactorE / eTokenTotalSupply;
            amountA = share * t.reserveA / t.sFactorE;
            amountB = share * t.reserveB / t.sFactorE;
        }
    }

    /**
     * @notice Given amountB, which amountA is required such that amountB / amountA is equal to the ratio
     * amountA := amountBInTokenA * ratio
     */
    function tokenAForTokenB(
        uint256 amountB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountB * sFactorI / sFactorB) * ratio) / rate) * sFactorA / sFactorI;
    }

    /**
     * @notice Given amountA, which amountB is required such that amountB / amountA is equal to the ratio
     * amountB := amountAInTokenB / ratio
     */
    function tokenBForTokenA(
        uint256 amountA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns(uint256) {
        return (((amountA * sFactorI / sFactorA) * rate) / ratio) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenA, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := total - (total / (1 + ratio)) == (total * ratio) / (1 + ratio)
     * amountB := (total / (1 + ratio)) * rate
     */
    function tokenATokenBForTokenA(
        uint256 _totalA,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = _totalA - (_totalA * sFactorI / (sFactorI + ratio));
        amountB = (((_totalA * sFactorI / sFactorA) * rate) / (sFactorI + ratio)) * sFactorB / sFactorI;
    }

    /**
     * @notice Given an amount of TokenB, how can it be split up proportionally into amountA and amountB
     * according to the ratio
     * amountA := (total * ratio) / (rate * (1 + ratio))
     * amountB := total / (1 + ratio)
     */
    function tokenATokenBForTokenB(
        uint256 _totalB,
        uint256 ratio,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        amountA = ((((_totalB * sFactorI / sFactorB) * ratio) / (sFactorI + ratio)) * sFactorA) / rate;
        amountB = (_totalB * sFactorI) / (sFactorI + ratio);
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenA
     * totalA := amountA + (amountB / rate)
     */
    function totalA(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalA) {
        return amountA + ((((amountB * sFactorI / sFactorB) * sFactorI) / rate) * sFactorA) / sFactorI;
    }

    /**
     * @notice Return the total value of amountA and amountB denominated in TokenB
     * totalB := amountB + (amountA * rate)
     */
    function totalB(
        uint256 amountA,
        uint256 amountB,
        uint256 rate,
        uint256 sFactorA,
        uint256 sFactorB
    ) internal pure returns (uint256 _totalB) {
        return amountB + ((amountA * rate / sFactorA) * sFactorB) / sFactorI;
    }

    /**
     * @notice Return the withdrawal fee for a given amount of TokenA and TokenB
     * feeA := amountA * feeRate
     * feeB := amountB * feeRate
     */
    function feeAFeeBForTokenATokenB(
        uint256 amountA,
        uint256 amountB,
        uint256 feeRate
    ) internal pure returns (uint256 feeA, uint256 feeB) {
        feeA = amountA * feeRate / EPoolLibrary.sFactorI;
        feeB = amountB * feeRate / EPoolLibrary.sFactorI;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEToken is IERC20 {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    function recover(IERC20 token, uint256 amount) external returns (bool);
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IEToken.sol";

interface IETokenFactory {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function createEToken(string memory name, string memory symbol) external returns (IEToken);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC20Optional.sol";

library TokenUtils {
    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "TokenUtils: no decimals");
        uint8 _decimals = abi.decode(data, (uint8));
        return _decimals;
    }
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.1;

library Math {

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

/**
 * @dev Interface of the the optional methods of the ERC20 standard as defined in the EIP.
 */
interface IERC20Optional {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

