/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    function getTwap(uint256 timestamp) external view returns (uint256);
}


pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;


interface IFund {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [ ratioM          0        0 ]
    ///         R = [ ratioA2M  ratioAB        0 ]
    ///             [ ratioB2M        0  ratioAB ]
    ///         ```
    ///
    ///         Amounts of the three tranches `m`, `a` and `b` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ m', a', b' ] = [ m, a, b ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioM;
        uint256 ratioA2M;
        uint256 ratioB2M;
        uint256 ratioAB;
        uint256 timestamp;
    }

    function trancheWeights() external pure returns (uint256 weightA, uint256 weightB);

    function tokenUnderlying() external view returns (address);

    function tokenM() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracle);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function shareTotalSupply(uint256 tranche) external view returns (uint256);

    function shareBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function allShareBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function shareBalanceVersion(address account) external view returns (uint256);

    function shareAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function shareAllowanceVersion(address owner, address spender) external view returns (uint256);

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function exchangeActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function isPrimaryMarketActive(address primaryMarket, uint256 timestamp)
        external
        view
        returns (bool);

    function isExchangeActive(uint256 timestamp) external view returns (bool);

    function getTotalShares() external view returns (uint256);

    function extrapolateNav(uint256 timestamp, uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function calculateNavB(uint256 navM, uint256 navA) external pure returns (uint256);

    function doRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function batchRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transferFrom(
        uint256 tranche,
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function increaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function decreaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) external;

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 ratioM,
        uint256 ratioA2M,
        uint256 ratioB2M,
        uint256 ratioAB
    );
    event Settled(uint256 indexed day, uint256 navM, uint256 navA, uint256 navB);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event Transfer(
        uint256 indexed tranche,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Approval(
        uint256 indexed tranche,
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceM,
        uint256 balanceA,
        uint256 balanceB
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceM,
        uint256 allowanceA,
        uint256 allowanceB
    );
}


pragma solidity >=0.6.10 <0.8.0;



contract Share is IERC20 {
    uint8 public constant decimals = 18;

    string public name;
    string public symbol;
    uint256 private immutable _tranche;

    IFund public fund;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * _tranche is immutable: it can only be set once during construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address fund_,
        uint256 tranche_
    ) public {
        name = name_;
        symbol = symbol_;
        fund = IFund(fund_);
        _tranche = tranche_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return fund.shareTotalSupply(_tranche);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return fund.shareBalanceOf(_tranche, account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        fund.transfer(_tranche, msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return fund.shareAllowance(_tranche, owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        fund.approve(_tranche, msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 newAllowance = fund.transferFrom(_tranche, msg.sender, sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        emit Approval(sender, msg.sender, newAllowance);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 newAllowance = fund.increaseAllowance(_tranche, msg.sender, spender, addedValue);
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 newAllowance =
            fund.decreaseAllowance(_tranche, msg.sender, spender, subtractedValue);
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }
}