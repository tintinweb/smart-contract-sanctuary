/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// File: contracts/lib/Types.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

library Types {
    enum RStatus {ONE, ABOVE_ONE, BELOW_ONE}
}

// File: contracts/intf/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

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
}

// File: contracts/lib/InitializableOwnable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/SafeMath.sol


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).divCeil(d);
    }
}

// File: contracts/lib/ReentrancyGuard.sol


/**
 * @title ReentrancyGuard
 * @author DODO Breeder
 *
 * @notice Protect functions from Reentrancy Attack
 */
contract ReentrancyGuard {
    // https://solidity.readthedocs.io/en/latest/control-structures.html?highlight=zero-state#scoping-and-declarations
    // zero-state of _ENTERED_ is false
    bool private _ENTERED_;

    modifier preventReentrant() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }
}

// File: contracts/intf/IOracle.sol



interface IOracle {
    function getPrice() external view returns (uint256);
}

// File: contracts/intf/IDODOLpToken.sol



interface IDODOLpToken {
    function mint(address user, uint256 value) external;

    function burn(address user, uint256 value) external;

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// File: contracts/impl/Storage.sol




/**
 * @title Storage
 * @author DODO Breeder
 *
 * @notice Local Variables
 */
contract Storage is InitializableOwnable, ReentrancyGuard {
    using SafeMath for uint256;

    // ============ Variables for Control ============

    bool internal _INITIALIZED_;
    bool public _CLOSED_;
    bool public _DEPOSIT_QUOTE_ALLOWED_;
    bool public _DEPOSIT_BASE_ALLOWED_;
    bool public _TRADE_ALLOWED_;
    uint256 public _GAS_PRICE_LIMIT_;

    // ============ Advanced Controls ============
    bool public _BUYING_ALLOWED_;
    bool public _SELLING_ALLOWED_;
    uint256 public _BASE_BALANCE_LIMIT_;
    uint256 public _QUOTE_BALANCE_LIMIT_;

    // ============ Core Address ============

    address public _SUPERVISOR_; // could freeze system in emergency
    address public _MAINTAINER_; // collect maintainer fee to buy food for DODO

    address public _BASE_TOKEN_;
    address public _QUOTE_TOKEN_;
    address public _ORACLE_;

    // ============ Variables for PMM Algorithm ============

    uint256 public _LP_FEE_RATE_;
    uint256 public _MT_FEE_RATE_;
    uint256 public _K_;

    Types.RStatus public _R_STATUS_;
    uint256 public _TARGET_BASE_TOKEN_AMOUNT_;
    uint256 public _TARGET_QUOTE_TOKEN_AMOUNT_;
    uint256 public _BASE_BALANCE_;
    uint256 public _QUOTE_BALANCE_;

    address public _BASE_CAPITAL_TOKEN_;
    address public _QUOTE_CAPITAL_TOKEN_;

    // ============ Variables for Final Settlement ============

    uint256 public _BASE_CAPITAL_RECEIVE_QUOTE_;
    uint256 public _QUOTE_CAPITAL_RECEIVE_BASE_;
    mapping(address => bool) public _CLAIMED_;

    // ============ Modifiers ============

    modifier onlySupervisorOrOwner() {
        require(msg.sender == _SUPERVISOR_ || msg.sender == _OWNER_, "NOT_SUPERVISOR_OR_OWNER");
        _;
    }

    modifier notClosed() {
        require(!_CLOSED_, "DODO_CLOSED");
        _;
    }

    // ============ Helper Functions ============

    function _checkDODOParameters() internal view returns (uint256) {
        require(_K_ < DecimalMath.ONE, "K>=1");
        require(_K_ > 0, "K=0");
        require(_LP_FEE_RATE_.add(_MT_FEE_RATE_) < DecimalMath.ONE, "FEE_RATE>=1");
    }

    function getOraclePrice() public view returns (uint256) {
        return IOracle(_ORACLE_).getPrice();
    }

    function getBaseCapitalBalanceOf(address lp) public view returns (uint256) {
        return IDODOLpToken(_BASE_CAPITAL_TOKEN_).balanceOf(lp);
    }

    function getTotalBaseCapital() public view returns (uint256) {
        return IDODOLpToken(_BASE_CAPITAL_TOKEN_).totalSupply();
    }

    function getQuoteCapitalBalanceOf(address lp) public view returns (uint256) {
        return IDODOLpToken(_QUOTE_CAPITAL_TOKEN_).balanceOf(lp);
    }

    function getTotalQuoteCapital() public view returns (uint256) {
        return IDODOLpToken(_QUOTE_CAPITAL_TOKEN_).totalSupply();
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }
}

// File: contracts/intf/IDODOCallee.sol


interface IDODOCallee {
    function dodoCall(
        bool isBuyBaseToken,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;
}

// File: contracts/lib/DODOMath.sol


/**
 * @title DODOMath
 * @author DODO Breeder
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library DODOMath {
    using SafeMath for uint256;

    /*
        Integrate dodo curve fron V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        uint256 fairAmount = DecimalMath.mul(i, V1.sub(V2)); // i*delta
        uint256 V0V0V1V2 = DecimalMath.divCeil(V0.mul(V0).div(V1), V2);
        uint256 penalty = DecimalMath.mul(k, V0V0V1V2); // k(V0^2/V1/V2)
        return DecimalMath.mul(fairAmount, DecimalMath.ONE.sub(k).add(penalty));
    }

    /*
        The same with integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan
        if deltaBSig=true, then Q2>Q1
        if deltaBSig=false, then Q2<Q1
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 Q0,
        uint256 Q1,
        uint256 ideltaB,
        bool deltaBSig,
        uint256 k
    ) internal pure returns (uint256) {
        // calculate -b value and sig
        // -b = (1-k)Q1-kQ0^2/Q1+i*deltaB
        uint256 kQ02Q1 = DecimalMath.mul(k, Q0).mul(Q0).div(Q1); // kQ0^2/Q1
        uint256 b = DecimalMath.mul(DecimalMath.ONE.sub(k), Q1); // (1-k)Q1
        bool minusbSig = true;
        if (deltaBSig) {
            b = b.add(ideltaB); // (1-k)Q1+i*deltaB
        } else {
            kQ02Q1 = kQ02Q1.add(ideltaB); // i*deltaB+kQ0^2/Q1
        }
        if (b >= kQ02Q1) {
            b = b.sub(kQ02Q1);
            minusbSig = true;
        } else {
            b = kQ02Q1.sub(b);
            minusbSig = false;
        }

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mul(
            DecimalMath.ONE.sub(k).mul(4),
            DecimalMath.mul(k, Q0).mul(Q0)
        ); // 4(1-k)kQ0^2
        squareRoot = b.mul(b).add(squareRoot).sqrt(); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = DecimalMath.ONE.sub(k).mul(2); // 2(1-k)
        uint256 numerator;
        if (minusbSig) {
            numerator = b.add(squareRoot);
        } else {
            numerator = squareRoot.sub(b);
        }

        if (deltaBSig) {
            return DecimalMath.divFloor(numerator, denominator);
        } else {
            return DecimalMath.divCeil(numerator, denominator);
        }
    }

    /*
        Start from the integration function
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0
        let fairAmount = i*deltaB
    */
    function _SolveQuadraticFunctionForTarget(
        uint256 V1,
        uint256 k,
        uint256 fairAmount
    ) internal pure returns (uint256 V0) {
        // V0 = V1+V1*(sqrt-1)/2k
        uint256 sqrt = DecimalMath.divCeil(DecimalMath.mul(k, fairAmount).mul(4), V1);
        sqrt = sqrt.add(DecimalMath.ONE).mul(DecimalMath.ONE).sqrt();
        uint256 premium = DecimalMath.divCeil(sqrt.sub(DecimalMath.ONE), k.mul(2));
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mul(V1, DecimalMath.ONE.add(premium));
    }
}

// File: contracts/impl/Pricing.sol


/**
 * @title Pricing
 * @author DODO Breeder
 *
 * @notice DODO Pricing model
 */
contract Pricing is Storage {
    using SafeMath for uint256;

    // ============ R = 1 cases ============

    function _ROneSellBaseToken(uint256 amount, uint256 targetQuoteTokenAmount)
        internal
        view
        returns (uint256 receiveQuoteToken)
    {
        uint256 i = getOraclePrice();
        uint256 Q2 = DODOMath._SolveQuadraticFunctionForTrade(
            targetQuoteTokenAmount,
            targetQuoteTokenAmount,
            DecimalMath.mul(i, amount),
            false,
            _K_
        );
        // in theory Q2 <= targetQuoteTokenAmount
        // however when amount is close to 0, precision problems may cause Q2 > targetQuoteTokenAmount
        return targetQuoteTokenAmount.sub(Q2);
    }

    function _ROneBuyBaseToken(uint256 amount, uint256 targetBaseTokenAmount)
        internal
        view
        returns (uint256 payQuoteToken)
    {
        require(amount < targetBaseTokenAmount, "DODO_BASE_BALANCE_NOT_ENOUGH");
        uint256 B2 = targetBaseTokenAmount.sub(amount);
        payQuoteToken = _RAboveIntegrate(targetBaseTokenAmount, targetBaseTokenAmount, B2);
        return payQuoteToken;
    }

    // ============ R < 1 cases ============

    function _RBelowSellBaseToken(
        uint256 amount,
        uint256 quoteBalance,
        uint256 targetQuoteAmount
    ) internal view returns (uint256 receieQuoteToken) {
        uint256 i = getOraclePrice();
        uint256 Q2 = DODOMath._SolveQuadraticFunctionForTrade(
            targetQuoteAmount,
            quoteBalance,
            DecimalMath.mul(i, amount),
            false,
            _K_
        );
        return quoteBalance.sub(Q2);
    }

    function _RBelowBuyBaseToken(
        uint256 amount,
        uint256 quoteBalance,
        uint256 targetQuoteAmount
    ) internal view returns (uint256 payQuoteToken) {
        // Here we don't require amount less than some value
        // Because it is limited at upper function
        // See Trader.queryBuyBaseToken
        uint256 i = getOraclePrice();
        uint256 Q2 = DODOMath._SolveQuadraticFunctionForTrade(
            targetQuoteAmount,
            quoteBalance,
            DecimalMath.mulCeil(i, amount),
            true,
            _K_
        );
        return Q2.sub(quoteBalance);
    }

    function _RBelowBackToOne() internal view returns (uint256 payQuoteToken) {
        // important: carefully design the system to make sure spareBase always greater than or equal to 0
        uint256 spareBase = _BASE_BALANCE_.sub(_TARGET_BASE_TOKEN_AMOUNT_);
        uint256 price = getOraclePrice();
        uint256 fairAmount = DecimalMath.mul(spareBase, price);
        uint256 newTargetQuote = DODOMath._SolveQuadraticFunctionForTarget(
            _QUOTE_BALANCE_,
            _K_,
            fairAmount
        );
        return newTargetQuote.sub(_QUOTE_BALANCE_);
    }

    // ============ R > 1 cases ============

    function _RAboveBuyBaseToken(
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal view returns (uint256 payQuoteToken) {
        require(amount < baseBalance, "DODO_BASE_BALANCE_NOT_ENOUGH");
        uint256 B2 = baseBalance.sub(amount);
        return _RAboveIntegrate(targetBaseAmount, baseBalance, B2);
    }

    function _RAboveSellBaseToken(
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal view returns (uint256 receiveQuoteToken) {
        // here we don't require B1 <= targetBaseAmount
        // Because it is limited at upper function
        // See Trader.querySellBaseToken
        uint256 B1 = baseBalance.add(amount);
        return _RAboveIntegrate(targetBaseAmount, B1, baseBalance);
    }

    function _RAboveBackToOne() internal view returns (uint256 payBaseToken) {
        // important: carefully design the system to make sure spareBase always greater than or equal to 0
        uint256 spareQuote = _QUOTE_BALANCE_.sub(_TARGET_QUOTE_TOKEN_AMOUNT_);
        uint256 price = getOraclePrice();
        uint256 fairAmount = DecimalMath.divFloor(spareQuote, price);
        uint256 newTargetBase = DODOMath._SolveQuadraticFunctionForTarget(
            _BASE_BALANCE_,
            _K_,
            fairAmount
        );
        return newTargetBase.sub(_BASE_BALANCE_);
    }

    // ============ Helper functions ============

    function getExpectedTarget() public view returns (uint256 baseTarget, uint256 quoteTarget) {
        uint256 Q = _QUOTE_BALANCE_;
        uint256 B = _BASE_BALANCE_;
        if (_R_STATUS_ == Types.RStatus.ONE) {
            return (_TARGET_BASE_TOKEN_AMOUNT_, _TARGET_QUOTE_TOKEN_AMOUNT_);
        } else if (_R_STATUS_ == Types.RStatus.BELOW_ONE) {
            uint256 payQuoteToken = _RBelowBackToOne();
            return (_TARGET_BASE_TOKEN_AMOUNT_, Q.add(payQuoteToken));
        } else if (_R_STATUS_ == Types.RStatus.ABOVE_ONE) {
            uint256 payBaseToken = _RAboveBackToOne();
            return (B.add(payBaseToken), _TARGET_QUOTE_TOKEN_AMOUNT_);
        }
    }

    function getMidPrice() public view returns (uint256 midPrice) {
        (uint256 baseTarget, uint256 quoteTarget) = getExpectedTarget();
        if (_R_STATUS_ == Types.RStatus.BELOW_ONE) {
            uint256 R = DecimalMath.divFloor(
                quoteTarget.mul(quoteTarget).div(_QUOTE_BALANCE_),
                _QUOTE_BALANCE_
            );
            R = DecimalMath.ONE.sub(_K_).add(DecimalMath.mul(_K_, R));
            return DecimalMath.divFloor(getOraclePrice(), R);
        } else {
            uint256 R = DecimalMath.divFloor(
                baseTarget.mul(baseTarget).div(_BASE_BALANCE_),
                _BASE_BALANCE_
            );
            R = DecimalMath.ONE.sub(_K_).add(DecimalMath.mul(_K_, R));
            return DecimalMath.mul(getOraclePrice(), R);
        }
    }

    function _RAboveIntegrate(
        uint256 B0,
        uint256 B1,
        uint256 B2
    ) internal view returns (uint256) {
        uint256 i = getOraclePrice();
        return DODOMath._GeneralIntegrate(B0, B1, B2, i, _K_);
    }

    // function _RBelowIntegrate(
    //     uint256 Q0,
    //     uint256 Q1,
    //     uint256 Q2
    // ) internal view returns (uint256) {
    //     uint256 i = getOraclePrice();
    //     i = DecimalMath.divFloor(DecimalMath.ONE, i); // 1/i
    //     return DODOMath._GeneralIntegrate(Q0, Q1, Q2, i, _K_);
    // }
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/impl/Settlement.sol


/**
 * @title Settlement
 * @author DODO Breeder
 *
 * @notice Functions for assets settlement
 */
contract Settlement is Storage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Events ============

    event Donate(uint256 amount, bool isBaseToken);

    event ClaimAssets(address indexed user, uint256 baseTokenAmount, uint256 quoteTokenAmount);

    // ============ Assets IN/OUT Functions ============

    function _baseTokenTransferIn(address from, uint256 amount) internal {
        require(_BASE_BALANCE_.add(amount) <= _BASE_BALANCE_LIMIT_, "BASE_BALANCE_LIMIT_EXCEEDED");
        IERC20(_BASE_TOKEN_).safeTransferFrom(from, address(this), amount);
        _BASE_BALANCE_ = _BASE_BALANCE_.add(amount);
    }

    function _quoteTokenTransferIn(address from, uint256 amount) internal {
        require(
            _QUOTE_BALANCE_.add(amount) <= _QUOTE_BALANCE_LIMIT_,
            "QUOTE_BALANCE_LIMIT_EXCEEDED"
        );
        IERC20(_QUOTE_TOKEN_).safeTransferFrom(from, address(this), amount);
        _QUOTE_BALANCE_ = _QUOTE_BALANCE_.add(amount);
    }

    function _baseTokenTransferOut(address to, uint256 amount) internal {
        IERC20(_BASE_TOKEN_).safeTransfer(to, amount);
        _BASE_BALANCE_ = _BASE_BALANCE_.sub(amount);
    }

    function _quoteTokenTransferOut(address to, uint256 amount) internal {
        IERC20(_QUOTE_TOKEN_).safeTransfer(to, amount);
        _QUOTE_BALANCE_ = _QUOTE_BALANCE_.sub(amount);
    }

    // ============ Donate to Liquidity Pool Functions ============

    function _donateBaseToken(uint256 amount) internal {
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.add(amount);
        emit Donate(amount, true);
    }

    function _donateQuoteToken(uint256 amount) internal {
        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.add(amount);
        emit Donate(amount, false);
    }

    function donateBaseToken(uint256 amount) external preventReentrant {
        _baseTokenTransferIn(msg.sender, amount);
        _donateBaseToken(amount);
    }

    function donateQuoteToken(uint256 amount) external preventReentrant {
        _quoteTokenTransferIn(msg.sender, amount);
        _donateQuoteToken(amount);
    }

    // ============ Final Settlement Functions ============

    // last step to shut down dodo
    function finalSettlement() external onlyOwner notClosed {
        _CLOSED_ = true;
        _DEPOSIT_QUOTE_ALLOWED_ = false;
        _DEPOSIT_BASE_ALLOWED_ = false;
        _TRADE_ALLOWED_ = false;
        uint256 totalBaseCapital = getTotalBaseCapital();
        uint256 totalQuoteCapital = getTotalQuoteCapital();

        if (_QUOTE_BALANCE_ > _TARGET_QUOTE_TOKEN_AMOUNT_) {
            uint256 spareQuote = _QUOTE_BALANCE_.sub(_TARGET_QUOTE_TOKEN_AMOUNT_);
            _BASE_CAPITAL_RECEIVE_QUOTE_ = DecimalMath.divFloor(spareQuote, totalBaseCapital);
        } else {
            _TARGET_QUOTE_TOKEN_AMOUNT_ = _QUOTE_BALANCE_;
        }

        if (_BASE_BALANCE_ > _TARGET_BASE_TOKEN_AMOUNT_) {
            uint256 spareBase = _BASE_BALANCE_.sub(_TARGET_BASE_TOKEN_AMOUNT_);
            _QUOTE_CAPITAL_RECEIVE_BASE_ = DecimalMath.divFloor(spareBase, totalQuoteCapital);
        } else {
            _TARGET_BASE_TOKEN_AMOUNT_ = _BASE_BALANCE_;
        }

        _R_STATUS_ = Types.RStatus.ONE;
    }

    // claim remaining assets after final settlement
    function claimAssets() external preventReentrant {
        require(_CLOSED_, "DODO_NOT_CLOSED");
        require(!_CLAIMED_[msg.sender], "ALREADY_CLAIMED");
        _CLAIMED_[msg.sender] = true;

        uint256 quoteCapital = getQuoteCapitalBalanceOf(msg.sender);
        uint256 baseCapital = getBaseCapitalBalanceOf(msg.sender);

        uint256 quoteAmount = 0;
        if (quoteCapital > 0) {
            quoteAmount = _TARGET_QUOTE_TOKEN_AMOUNT_.mul(quoteCapital).div(getTotalQuoteCapital());
        }
        uint256 baseAmount = 0;
        if (baseCapital > 0) {
            baseAmount = _TARGET_BASE_TOKEN_AMOUNT_.mul(baseCapital).div(getTotalBaseCapital());
        }

        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.sub(quoteAmount);
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.sub(baseAmount);

        quoteAmount = quoteAmount.add(DecimalMath.mul(baseCapital, _BASE_CAPITAL_RECEIVE_QUOTE_));
        baseAmount = baseAmount.add(DecimalMath.mul(quoteCapital, _QUOTE_CAPITAL_RECEIVE_BASE_));

        _baseTokenTransferOut(msg.sender, baseAmount);
        _quoteTokenTransferOut(msg.sender, quoteAmount);

        IDODOLpToken(_BASE_CAPITAL_TOKEN_).burn(msg.sender, baseCapital);
        IDODOLpToken(_QUOTE_CAPITAL_TOKEN_).burn(msg.sender, quoteCapital);

        emit ClaimAssets(msg.sender, baseAmount, quoteAmount);
        return;
    }

    // in case someone transfer to contract directly
    function retrieve(address token, uint256 amount) external onlyOwner {
        if (token == _BASE_TOKEN_) {
            require(
                IERC20(_BASE_TOKEN_).balanceOf(address(this)) >= _BASE_BALANCE_.add(amount),
                "DODO_BASE_BALANCE_NOT_ENOUGH"
            );
        }
        if (token == _QUOTE_TOKEN_) {
            require(
                IERC20(_QUOTE_TOKEN_).balanceOf(address(this)) >= _QUOTE_BALANCE_.add(amount),
                "DODO_QUOTE_BALANCE_NOT_ENOUGH"
            );
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}

// File: contracts/impl/Trader.sol


/**
 * @title Trader
 * @author DODO Breeder
 *
 * @notice Functions for trader operations
 */
contract Trader is Storage, Pricing, Settlement {
    using SafeMath for uint256;

    // ============ Events ============

    event SellBaseToken(address indexed seller, uint256 payBase, uint256 receiveQuote);

    event BuyBaseToken(address indexed buyer, uint256 receiveBase, uint256 payQuote);

    event ChargeMaintainerFee(address indexed maintainer, bool isBaseToken, uint256 amount);

    // ============ Modifiers ============

    modifier tradeAllowed() {
        require(_TRADE_ALLOWED_, "TRADE_NOT_ALLOWED");
        _;
    }

    modifier buyingAllowed() {
        require(_BUYING_ALLOWED_, "BUYING_NOT_ALLOWED");
        _;
    }

    modifier sellingAllowed() {
        require(_SELLING_ALLOWED_, "SELLING_NOT_ALLOWED");
        _;
    }

    modifier gasPriceLimit() {
        require(tx.gasprice <= _GAS_PRICE_LIMIT_, "GAS_PRICE_EXCEED");
        _;
    }

    // ============ Trade Functions ============

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external tradeAllowed sellingAllowed gasPriceLimit preventReentrant returns (uint256) {
        // query price
        (
            uint256 receiveQuote,
            uint256 lpFeeQuote,
            uint256 mtFeeQuote,
            Types.RStatus newRStatus,
            uint256 newQuoteTarget,
            uint256 newBaseTarget
        ) = _querySellBaseToken(amount);
        require(receiveQuote >= minReceiveQuote, "SELL_BASE_RECEIVE_NOT_ENOUGH");

        // settle assets
        _quoteTokenTransferOut(msg.sender, receiveQuote);
        if (data.length > 0) {
            IDODOCallee(msg.sender).dodoCall(false, amount, receiveQuote, data);
        }
        _baseTokenTransferIn(msg.sender, amount);
        if (mtFeeQuote != 0) {
            _quoteTokenTransferOut(_MAINTAINER_, mtFeeQuote);
            emit ChargeMaintainerFee(_MAINTAINER_, false, mtFeeQuote);
        }

        // update TARGET
        if (_TARGET_QUOTE_TOKEN_AMOUNT_ != newQuoteTarget) {
            _TARGET_QUOTE_TOKEN_AMOUNT_ = newQuoteTarget;
        }
        if (_TARGET_BASE_TOKEN_AMOUNT_ != newBaseTarget) {
            _TARGET_BASE_TOKEN_AMOUNT_ = newBaseTarget;
        }
        if (_R_STATUS_ != newRStatus) {
            _R_STATUS_ = newRStatus;
        }

        _donateQuoteToken(lpFeeQuote);
        emit SellBaseToken(msg.sender, amount, receiveQuote);

        return receiveQuote;
    }

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external tradeAllowed buyingAllowed gasPriceLimit preventReentrant returns (uint256) {
        // query price
        (
            uint256 payQuote,
            uint256 lpFeeBase,
            uint256 mtFeeBase,
            Types.RStatus newRStatus,
            uint256 newQuoteTarget,
            uint256 newBaseTarget
        ) = _queryBuyBaseToken(amount);
        require(payQuote <= maxPayQuote, "BUY_BASE_COST_TOO_MUCH");

        // settle assets
        _baseTokenTransferOut(msg.sender, amount);
        if (data.length > 0) {
            IDODOCallee(msg.sender).dodoCall(true, amount, payQuote, data);
        }
        _quoteTokenTransferIn(msg.sender, payQuote);
        if (mtFeeBase != 0) {
            _baseTokenTransferOut(_MAINTAINER_, mtFeeBase);
            emit ChargeMaintainerFee(_MAINTAINER_, true, mtFeeBase);
        }

        // update TARGET
        if (_TARGET_QUOTE_TOKEN_AMOUNT_ != newQuoteTarget) {
            _TARGET_QUOTE_TOKEN_AMOUNT_ = newQuoteTarget;
        }
        if (_TARGET_BASE_TOKEN_AMOUNT_ != newBaseTarget) {
            _TARGET_BASE_TOKEN_AMOUNT_ = newBaseTarget;
        }
        if (_R_STATUS_ != newRStatus) {
            _R_STATUS_ = newRStatus;
        }

        _donateBaseToken(lpFeeBase);
        emit BuyBaseToken(msg.sender, amount, payQuote);

        return payQuote;
    }

    // ============ Query Functions ============

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote) {
        (receiveQuote, , , , , ) = _querySellBaseToken(amount);
        return receiveQuote;
    }

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote) {
        (payQuote, , , , , ) = _queryBuyBaseToken(amount);
        return payQuote;
    }

    function _querySellBaseToken(uint256 amount)
        internal
        view
        returns (
            uint256 receiveQuote,
            uint256 lpFeeQuote,
            uint256 mtFeeQuote,
            Types.RStatus newRStatus,
            uint256 newQuoteTarget,
            uint256 newBaseTarget
        )
    {
        (newBaseTarget, newQuoteTarget) = getExpectedTarget();

        uint256 sellBaseAmount = amount;

        if (_R_STATUS_ == Types.RStatus.ONE) {
            // case 1: R=1
            // R falls below one
            receiveQuote = _ROneSellBaseToken(sellBaseAmount, newQuoteTarget);
            newRStatus = Types.RStatus.BELOW_ONE;
        } else if (_R_STATUS_ == Types.RStatus.ABOVE_ONE) {
            uint256 backToOnePayBase = newBaseTarget.sub(_BASE_BALANCE_);
            uint256 backToOneReceiveQuote = _QUOTE_BALANCE_.sub(newQuoteTarget);
            // case 2: R>1
            // complex case, R status depends on trading amount
            if (sellBaseAmount < backToOnePayBase) {
                // case 2.1: R status do not change
                receiveQuote = _RAboveSellBaseToken(sellBaseAmount, _BASE_BALANCE_, newBaseTarget);
                newRStatus = Types.RStatus.ABOVE_ONE;
                if (receiveQuote > backToOneReceiveQuote) {
                    // [Important corner case!] may enter this branch when some precision problem happens. And consequently contribute to negative spare quote amount
                    // to make sure spare quote>=0, mannually set receiveQuote=backToOneReceiveQuote
                    receiveQuote = backToOneReceiveQuote;
                }
            } else if (sellBaseAmount == backToOnePayBase) {
                // case 2.2: R status changes to ONE
                receiveQuote = backToOneReceiveQuote;
                newRStatus = Types.RStatus.ONE;
            } else {
                // case 2.3: R status changes to BELOW_ONE
                receiveQuote = backToOneReceiveQuote.add(
                    _ROneSellBaseToken(sellBaseAmount.sub(backToOnePayBase), newQuoteTarget)
                );
                newRStatus = Types.RStatus.BELOW_ONE;
            }
        } else {
            // _R_STATUS_ == Types.RStatus.BELOW_ONE
            // case 3: R<1
            receiveQuote = _RBelowSellBaseToken(sellBaseAmount, _QUOTE_BALANCE_, newQuoteTarget);
            newRStatus = Types.RStatus.BELOW_ONE;
        }

        // count fees
        lpFeeQuote = DecimalMath.mul(receiveQuote, _LP_FEE_RATE_);
        mtFeeQuote = DecimalMath.mul(receiveQuote, _MT_FEE_RATE_);
        receiveQuote = receiveQuote.sub(lpFeeQuote).sub(mtFeeQuote);

        return (receiveQuote, lpFeeQuote, mtFeeQuote, newRStatus, newQuoteTarget, newBaseTarget);
    }

    function _queryBuyBaseToken(uint256 amount)
        internal
        view
        returns (
            uint256 payQuote,
            uint256 lpFeeBase,
            uint256 mtFeeBase,
            Types.RStatus newRStatus,
            uint256 newQuoteTarget,
            uint256 newBaseTarget
        )
    {
        (newBaseTarget, newQuoteTarget) = getExpectedTarget();

        // charge fee from user receive amount
        lpFeeBase = DecimalMath.mul(amount, _LP_FEE_RATE_);
        mtFeeBase = DecimalMath.mul(amount, _MT_FEE_RATE_);
        uint256 buyBaseAmount = amount.add(lpFeeBase).add(mtFeeBase);

        if (_R_STATUS_ == Types.RStatus.ONE) {
            // case 1: R=1
            payQuote = _ROneBuyBaseToken(buyBaseAmount, newBaseTarget);
            newRStatus = Types.RStatus.ABOVE_ONE;
        } else if (_R_STATUS_ == Types.RStatus.ABOVE_ONE) {
            // case 2: R>1
            payQuote = _RAboveBuyBaseToken(buyBaseAmount, _BASE_BALANCE_, newBaseTarget);
            newRStatus = Types.RStatus.ABOVE_ONE;
        } else if (_R_STATUS_ == Types.RStatus.BELOW_ONE) {
            uint256 backToOnePayQuote = newQuoteTarget.sub(_QUOTE_BALANCE_);
            uint256 backToOneReceiveBase = _BASE_BALANCE_.sub(newBaseTarget);
            // case 3: R<1
            // complex case, R status may change
            if (buyBaseAmount < backToOneReceiveBase) {
                // case 3.1: R status do not change
                // no need to check payQuote because spare base token must be greater than zero
                payQuote = _RBelowBuyBaseToken(buyBaseAmount, _QUOTE_BALANCE_, newQuoteTarget);
                newRStatus = Types.RStatus.BELOW_ONE;
            } else if (buyBaseAmount == backToOneReceiveBase) {
                // case 3.2: R status changes to ONE
                payQuote = backToOnePayQuote;
                newRStatus = Types.RStatus.ONE;
            } else {
                // case 3.3: R status changes to ABOVE_ONE
                payQuote = backToOnePayQuote.add(
                    _ROneBuyBaseToken(buyBaseAmount.sub(backToOneReceiveBase), newBaseTarget)
                );
                newRStatus = Types.RStatus.ABOVE_ONE;
            }
        }

        return (payQuote, lpFeeBase, mtFeeBase, newRStatus, newQuoteTarget, newBaseTarget);
    }
}

// File: contracts/impl/LiquidityProvider.sol


/**
 * @title LiquidityProvider
 * @author DODO Breeder
 *
 * @notice Functions for liquidity provider operations
 */
contract LiquidityProvider is Storage, Pricing, Settlement {
    using SafeMath for uint256;

    // ============ Events ============

    event Deposit(
        address indexed payer,
        address indexed receiver,
        bool isBaseToken,
        uint256 amount,
        uint256 lpTokenAmount
    );

    event Withdraw(
        address indexed payer,
        address indexed receiver,
        bool isBaseToken,
        uint256 amount,
        uint256 lpTokenAmount
    );

    event ChargePenalty(address indexed payer, bool isBaseToken, uint256 amount);

    // ============ Modifiers ============

    modifier depositQuoteAllowed() {
        require(_DEPOSIT_QUOTE_ALLOWED_, "DEPOSIT_QUOTE_NOT_ALLOWED");
        _;
    }

    modifier depositBaseAllowed() {
        require(_DEPOSIT_BASE_ALLOWED_, "DEPOSIT_BASE_NOT_ALLOWED");
        _;
    }

    modifier dodoNotClosed() {
        require(!_CLOSED_, "DODO_CLOSED");
        _;
    }

    // ============ Routine Functions ============

    function withdrawBase(uint256 amount) external returns (uint256) {
        return withdrawBaseTo(msg.sender, amount);
    }

    function depositBase(uint256 amount) external returns (uint256) {
        return depositBaseTo(msg.sender, amount);
    }

    function withdrawQuote(uint256 amount) external returns (uint256) {
        return withdrawQuoteTo(msg.sender, amount);
    }

    function depositQuote(uint256 amount) external returns (uint256) {
        return depositQuoteTo(msg.sender, amount);
    }

    function withdrawAllBase() external returns (uint256) {
        return withdrawAllBaseTo(msg.sender);
    }

    function withdrawAllQuote() external returns (uint256) {
        return withdrawAllQuoteTo(msg.sender);
    }

    // ============ Deposit Functions ============

    function depositQuoteTo(address to, uint256 amount)
        public
        preventReentrant
        depositQuoteAllowed
        returns (uint256)
    {
        (, uint256 quoteTarget) = getExpectedTarget();
        uint256 totalQuoteCapital = getTotalQuoteCapital();
        uint256 capital = amount;
        if (totalQuoteCapital == 0) {
            // give remaining quote token to lp as a gift
            capital = amount.add(quoteTarget);
        } else if (quoteTarget > 0) {
            capital = amount.mul(totalQuoteCapital).div(quoteTarget);
        }

        // settlement
        _quoteTokenTransferIn(msg.sender, amount);
        _mintQuoteCapital(to, capital);
        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.add(amount);

        emit Deposit(msg.sender, to, false, amount, capital);
        return capital;
    }

    function depositBaseTo(address to, uint256 amount)
        public
        preventReentrant
        depositBaseAllowed
        returns (uint256)
    {
        (uint256 baseTarget, ) = getExpectedTarget();
        uint256 totalBaseCapital = getTotalBaseCapital();
        uint256 capital = amount;
        if (totalBaseCapital == 0) {
            // give remaining base token to lp as a gift
            capital = amount.add(baseTarget);
        } else if (baseTarget > 0) {
            capital = amount.mul(totalBaseCapital).div(baseTarget);
        }

        // settlement
        _baseTokenTransferIn(msg.sender, amount);
        _mintBaseCapital(to, capital);
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.add(amount);

        emit Deposit(msg.sender, to, true, amount, capital);
        return capital;
    }

    // ============ Withdraw Functions ============

    function withdrawQuoteTo(address to, uint256 amount)
        public
        preventReentrant
        dodoNotClosed
        returns (uint256)
    {
        // calculate capital
        (, uint256 quoteTarget) = getExpectedTarget();
        uint256 totalQuoteCapital = getTotalQuoteCapital();
        require(totalQuoteCapital > 0, "NO_QUOTE_LP");

        uint256 requireQuoteCapital = amount.mul(totalQuoteCapital).divCeil(quoteTarget);
        require(
            requireQuoteCapital <= getQuoteCapitalBalanceOf(msg.sender),
            "LP_QUOTE_CAPITAL_BALANCE_NOT_ENOUGH"
        );

        // handle penalty, penalty may exceed amount
        uint256 penalty = getWithdrawQuotePenalty(amount);
        require(penalty < amount, "PENALTY_EXCEED");

        // settlement
        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.sub(amount);
        _burnQuoteCapital(msg.sender, requireQuoteCapital);
        _quoteTokenTransferOut(to, amount.sub(penalty));
        _donateQuoteToken(penalty);

        emit Withdraw(msg.sender, to, false, amount.sub(penalty), requireQuoteCapital);
        emit ChargePenalty(msg.sender, false, penalty);

        return amount.sub(penalty);
    }

    function withdrawBaseTo(address to, uint256 amount)
        public
        preventReentrant
        dodoNotClosed
        returns (uint256)
    {
        // calculate capital
        (uint256 baseTarget, ) = getExpectedTarget();
        uint256 totalBaseCapital = getTotalBaseCapital();
        require(totalBaseCapital > 0, "NO_BASE_LP");

        uint256 requireBaseCapital = amount.mul(totalBaseCapital).divCeil(baseTarget);
        require(
            requireBaseCapital <= getBaseCapitalBalanceOf(msg.sender),
            "LP_BASE_CAPITAL_BALANCE_NOT_ENOUGH"
        );

        // handle penalty, penalty may exceed amount
        uint256 penalty = getWithdrawBasePenalty(amount);
        require(penalty <= amount, "PENALTY_EXCEED");

        // settlement
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.sub(amount);
        _burnBaseCapital(msg.sender, requireBaseCapital);
        _baseTokenTransferOut(to, amount.sub(penalty));
        _donateBaseToken(penalty);

        emit Withdraw(msg.sender, to, true, amount.sub(penalty), requireBaseCapital);
        emit ChargePenalty(msg.sender, true, penalty);

        return amount.sub(penalty);
    }

    // ============ Withdraw all Functions ============

    function withdrawAllQuoteTo(address to)
        public
        preventReentrant
        dodoNotClosed
        returns (uint256)
    {
        uint256 withdrawAmount = getLpQuoteBalance(msg.sender);
        uint256 capital = getQuoteCapitalBalanceOf(msg.sender);

        // handle penalty, penalty may exceed amount
        uint256 penalty = getWithdrawQuotePenalty(withdrawAmount);
        require(penalty <= withdrawAmount, "PENALTY_EXCEED");

        // settlement
        _TARGET_QUOTE_TOKEN_AMOUNT_ = _TARGET_QUOTE_TOKEN_AMOUNT_.sub(withdrawAmount);
        _burnQuoteCapital(msg.sender, capital);
        _quoteTokenTransferOut(to, withdrawAmount.sub(penalty));
        _donateQuoteToken(penalty);

        emit Withdraw(msg.sender, to, false, withdrawAmount, capital);
        emit ChargePenalty(msg.sender, false, penalty);

        return withdrawAmount.sub(penalty);
    }

    function withdrawAllBaseTo(address to) public preventReentrant dodoNotClosed returns (uint256) {
        uint256 withdrawAmount = getLpBaseBalance(msg.sender);
        uint256 capital = getBaseCapitalBalanceOf(msg.sender);

        // handle penalty, penalty may exceed amount
        uint256 penalty = getWithdrawBasePenalty(withdrawAmount);
        require(penalty <= withdrawAmount, "PENALTY_EXCEED");

        // settlement
        _TARGET_BASE_TOKEN_AMOUNT_ = _TARGET_BASE_TOKEN_AMOUNT_.sub(withdrawAmount);
        _burnBaseCapital(msg.sender, capital);
        _baseTokenTransferOut(to, withdrawAmount.sub(penalty));
        _donateBaseToken(penalty);

        emit Withdraw(msg.sender, to, true, withdrawAmount, capital);
        emit ChargePenalty(msg.sender, true, penalty);

        return withdrawAmount.sub(penalty);
    }

    // ============ Helper Functions ============

    function _mintBaseCapital(address user, uint256 amount) internal {
        IDODOLpToken(_BASE_CAPITAL_TOKEN_).mint(user, amount);
    }

    function _mintQuoteCapital(address user, uint256 amount) internal {
        IDODOLpToken(_QUOTE_CAPITAL_TOKEN_).mint(user, amount);
    }

    function _burnBaseCapital(address user, uint256 amount) internal {
        IDODOLpToken(_BASE_CAPITAL_TOKEN_).burn(user, amount);
    }

    function _burnQuoteCapital(address user, uint256 amount) internal {
        IDODOLpToken(_QUOTE_CAPITAL_TOKEN_).burn(user, amount);
    }

    // ============ Getter Functions ============

    function getLpBaseBalance(address lp) public view returns (uint256 lpBalance) {
        uint256 totalBaseCapital = getTotalBaseCapital();
        (uint256 baseTarget, ) = getExpectedTarget();
        if (totalBaseCapital == 0) {
            return 0;
        }
        lpBalance = getBaseCapitalBalanceOf(lp).mul(baseTarget).div(totalBaseCapital);
        return lpBalance;
    }

    function getLpQuoteBalance(address lp) public view returns (uint256 lpBalance) {
        uint256 totalQuoteCapital = getTotalQuoteCapital();
        (, uint256 quoteTarget) = getExpectedTarget();
        if (totalQuoteCapital == 0) {
            return 0;
        }
        lpBalance = getQuoteCapitalBalanceOf(lp).mul(quoteTarget).div(totalQuoteCapital);
        return lpBalance;
    }

    function getWithdrawQuotePenalty(uint256 amount) public view returns (uint256 penalty) {
        require(amount <= _QUOTE_BALANCE_, "DODO_QUOTE_BALANCE_NOT_ENOUGH");
        if (_R_STATUS_ == Types.RStatus.BELOW_ONE) {
            uint256 spareBase = _BASE_BALANCE_.sub(_TARGET_BASE_TOKEN_AMOUNT_);
            uint256 price = getOraclePrice();
            uint256 fairAmount = DecimalMath.mul(spareBase, price);
            uint256 targetQuote = DODOMath._SolveQuadraticFunctionForTarget(
                _QUOTE_BALANCE_,
                _K_,
                fairAmount
            );
            // if amount = _QUOTE_BALANCE_, div error
            uint256 targetQuoteWithWithdraw = DODOMath._SolveQuadraticFunctionForTarget(
                _QUOTE_BALANCE_.sub(amount),
                _K_,
                fairAmount
            );
            return targetQuote.sub(targetQuoteWithWithdraw.add(amount));
        } else {
            return 0;
        }
    }

    function getWithdrawBasePenalty(uint256 amount) public view returns (uint256 penalty) {
        require(amount <= _BASE_BALANCE_, "DODO_BASE_BALANCE_NOT_ENOUGH");
        if (_R_STATUS_ == Types.RStatus.ABOVE_ONE) {
            uint256 spareQuote = _QUOTE_BALANCE_.sub(_TARGET_QUOTE_TOKEN_AMOUNT_);
            uint256 price = getOraclePrice();
            uint256 fairAmount = DecimalMath.divFloor(spareQuote, price);
            uint256 targetBase = DODOMath._SolveQuadraticFunctionForTarget(
                _BASE_BALANCE_,
                _K_,
                fairAmount
            );
            // if amount = _BASE_BALANCE_, div error
            uint256 targetBaseWithWithdraw = DODOMath._SolveQuadraticFunctionForTarget(
                _BASE_BALANCE_.sub(amount),
                _K_,
                fairAmount
            );
            return targetBase.sub(targetBaseWithWithdraw.add(amount));
        } else {
            return 0;
        }
    }
}

// File: contracts/impl/Admin.sol


/**
 * @title Admin
 * @author DODO Breeder
 *
 * @notice Functions for admin operations
 */
contract Admin is Storage {
    // ============ Events ============

    event UpdateGasPriceLimit(uint256 oldGasPriceLimit, uint256 newGasPriceLimit);

    event UpdateLiquidityProviderFeeRate(
        uint256 oldLiquidityProviderFeeRate,
        uint256 newLiquidityProviderFeeRate
    );

    event UpdateMaintainerFeeRate(uint256 oldMaintainerFeeRate, uint256 newMaintainerFeeRate);

    event UpdateK(uint256 oldK, uint256 newK);

    // ============ Params Setting Functions ============

    function setOracle(address newOracle) external onlyOwner {
        _ORACLE_ = newOracle;
    }

    function setSupervisor(address newSupervisor) external onlyOwner {
        _SUPERVISOR_ = newSupervisor;
    }

    function setMaintainer(address newMaintainer) external onlyOwner {
        _MAINTAINER_ = newMaintainer;
    }

    function setLiquidityProviderFeeRate(uint256 newLiquidityPorviderFeeRate) external onlyOwner {
        emit UpdateLiquidityProviderFeeRate(_LP_FEE_RATE_, newLiquidityPorviderFeeRate);
        _LP_FEE_RATE_ = newLiquidityPorviderFeeRate;
        _checkDODOParameters();
    }

    function setMaintainerFeeRate(uint256 newMaintainerFeeRate) external onlyOwner {
        emit UpdateMaintainerFeeRate(_MT_FEE_RATE_, newMaintainerFeeRate);
        _MT_FEE_RATE_ = newMaintainerFeeRate;
        _checkDODOParameters();
    }

    function setK(uint256 newK) external onlyOwner {
        emit UpdateK(_K_, newK);
        _K_ = newK;
        _checkDODOParameters();
    }

    function setGasPriceLimit(uint256 newGasPriceLimit) external onlySupervisorOrOwner {
        emit UpdateGasPriceLimit(_GAS_PRICE_LIMIT_, newGasPriceLimit);
        _GAS_PRICE_LIMIT_ = newGasPriceLimit;
    }

    // ============ System Control Functions ============

    function disableTrading() external onlySupervisorOrOwner {
        _TRADE_ALLOWED_ = false;
    }

    function enableTrading() external onlyOwner notClosed {
        _TRADE_ALLOWED_ = true;
    }

    function disableQuoteDeposit() external onlySupervisorOrOwner {
        _DEPOSIT_QUOTE_ALLOWED_ = false;
    }

    function enableQuoteDeposit() external onlyOwner notClosed {
        _DEPOSIT_QUOTE_ALLOWED_ = true;
    }

    function disableBaseDeposit() external onlySupervisorOrOwner {
        _DEPOSIT_BASE_ALLOWED_ = false;
    }

    function enableBaseDeposit() external onlyOwner notClosed {
        _DEPOSIT_BASE_ALLOWED_ = true;
    }

    // ============ Advanced Control Functions ============

    function disableBuying() external onlySupervisorOrOwner {
        _BUYING_ALLOWED_ = false;
    }

    function enableBuying() external onlyOwner notClosed {
        _BUYING_ALLOWED_ = true;
    }

    function disableSelling() external onlySupervisorOrOwner {
        _SELLING_ALLOWED_ = false;
    }

    function enableSelling() external onlyOwner notClosed {
        _SELLING_ALLOWED_ = true;
    }

    function setBaseBalanceLimit(uint256 newBaseBalanceLimit) external onlyOwner notClosed {
        _BASE_BALANCE_LIMIT_ = newBaseBalanceLimit;
    }

    function setQuoteBalanceLimit(uint256 newQuoteBalanceLimit) external onlyOwner notClosed {
        _QUOTE_BALANCE_LIMIT_ = newQuoteBalanceLimit;
    }
}

// File: contracts/lib/Ownable.sol


/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/impl/DODOLpToken.sol


/**
 * @title DODOLpToken
 * @author DODO Breeder
 *
 * @notice Tokenize liquidity pool assets. An ordinary ERC20 contract with mint and burn functions
 */
contract DODOLpToken is Ownable {
    using SafeMath for uint256;

    string public symbol = "DLP";
    address public originToken;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // ============ Events ============

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Mint(address indexed user, uint256 value);

    event Burn(address indexed user, uint256 value);

    // ============ Functions ============

    constructor(address _originToken) public {
        originToken = _originToken;
    }

    function name() public view returns (string memory) {
        string memory lpTokenSuffix = "_DODO_LP_TOKEN_";
        return string(abi.encodePacked(IERC20(originToken).name(), lpTokenSuffix));
    }

    function decimals() public view returns (uint8) {
        return IERC20(originToken).decimals();
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address user, uint256 value) external onlyOwner {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function burn(address user, uint256 value) external onlyOwner {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }
}

// File: contracts/dodo.sol



/**
 * @title DODO
 * @author DODO Breeder
 *
 * @notice Entrance for users
 */
contract DODO is Admin, Trader, LiquidityProvider {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _INITIALIZED_ = true;

        // constructor
        _OWNER_ = owner;
        emit OwnershipTransferred(address(0), _OWNER_);

        _SUPERVISOR_ = supervisor;
        _MAINTAINER_ = maintainer;
        _BASE_TOKEN_ = baseToken;
        _QUOTE_TOKEN_ = quoteToken;
        _ORACLE_ = oracle;

        _DEPOSIT_BASE_ALLOWED_ = false;
        _DEPOSIT_QUOTE_ALLOWED_ = false;
        _TRADE_ALLOWED_ = false;
        _GAS_PRICE_LIMIT_ = gasPriceLimit;

        // Advanced controls are disabled by default
        _BUYING_ALLOWED_ = true;
        _SELLING_ALLOWED_ = true;
        uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        _BASE_BALANCE_LIMIT_ = MAX_INT;
        _QUOTE_BALANCE_LIMIT_ = MAX_INT;

        _LP_FEE_RATE_ = lpFeeRate;
        _MT_FEE_RATE_ = mtFeeRate;
        _K_ = k;
        _R_STATUS_ = Types.RStatus.ONE;

        _BASE_CAPITAL_TOKEN_ = address(new DODOLpToken(_BASE_TOKEN_));
        _QUOTE_CAPITAL_TOKEN_ = address(new DODOLpToken(_QUOTE_TOKEN_));

        _checkDODOParameters();
    }
}