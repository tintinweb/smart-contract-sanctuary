/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/ISoloMargin.sol

pragma solidity >=0.5.7;
pragma experimental ABIEncoderV2;

library Account {
    enum Status {Normal, Liquid, Vapor}
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {OnePrimary, TwoPrimary, PrimaryAndSecondary}

    enum MarketLayout {ZeroMarkets, OneMarket, TwoMarkets}

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}

library Decimal {
    struct D256 {
        uint256 value;
    }
}

library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}

library Monetary {
    struct Price {
        uint256 value;
    }
    struct Value {
        uint256 value;
    }
}

library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}

library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

abstract contract ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public virtual;

    function getIsGlobalOperator(address operator)
        public
        view
        virtual
        returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        public
        view
        virtual
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        public
        virtual;

    function getAccountValues(Account.Info memory account)
        public
        view
        virtual
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        public
        view
        virtual
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        public
        view
        virtual
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        public
        view
        virtual
        returns (Decimal.D256 memory);

    function getNumMarkets() public view virtual returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        public
        virtual
        returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue)
        public
        virtual;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread)
        public
        virtual;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate)
        public
        virtual;

    function getIsLocalOperator(address owner, address operator)
        public
        view
        virtual
        returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId)
        public
        view
        virtual
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public virtual;

    function getMarginRatio() public view virtual returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        public
        view
        virtual
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId)
        public
        view
        virtual
        returns (bool);

    function getRiskParams()
        public
        view
        virtual
        returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        public
        view
        virtual
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );

    function renounceOwnership() public virtual;

    function getMinBorrowedValue()
        public
        view
        virtual
        returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) public virtual;

    function getMarketPrice(uint256 marketId)
        public
        view
        virtual
        returns (address);

    function owner() public view virtual returns (address);

    function isOwner() public view virtual returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        public
        virtual
        returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) public virtual;

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public virtual;

    function getMarketWithInfo(uint256 marketId)
        public
        view
        virtual
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) public virtual;

    function getLiquidationSpread()
        public
        view
        virtual
        returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId)
        public
        view
        virtual
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        public
        view
        virtual
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) public view virtual returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        public
        view
        virtual
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        public
        view
        virtual
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account)
        public
        view
        virtual
        returns (uint8);

    function getEarningsRate()
        public
        view
        virtual
        returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle)
        public
        virtual;

    function getRiskLimits()
        public
        view
        virtual
        returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        public
        view
        virtual
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) public virtual;

    function ownerSetGlobalOperator(address operator, bool approved)
        public
        virtual;

    function transferOwnership(address newOwner) public virtual;

    function getAdjustedAccountValues(Account.Info memory account)
        public
        view
        virtual
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        public
        view
        virtual
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        public
        view
        virtual
        returns (Interest.Rate memory);
}

// File: contracts/DydxFlashloanBase.sol

pragma solidity >=0.5.7;




contract DydxFlashloanBase {
    using SafeMath for uint256;

    // -- Internal Helper functions -- //

    function _getMarketIdFromTokenAddress(address _solo, address token)
        internal
        view
        returns (uint256)
    {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert("No marketId found for provided token");
    }

    function _getRepaymentAmountInternal(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        // Needs to be overcollateralize
        // Needs to provide +2 wei to be safe
        return amount.add(2);
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }
}

// File: contracts/ICallee.sol

pragma solidity >=0.5.7;


/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
abstract contract ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) public virtual;
}

// File: contracts/FUCK.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

// openzeppelin框架官网：https://docs.openzeppelin.com/contracts/3.x/

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";



// WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
// USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
// DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
// SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
// ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
// USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
// https://my.oschina.net/u/4587589/blog/4868287

// v0.6.2+commit.bacdbe57
// v0.5.7+commit.6da8b019

contract FUCK is ICallee, DydxFlashloanBase {
    struct MyCustomData {
        address token;
        address pairAddress;
        uint256 repayAmount;
        uint256 lendProject;
        uint256[] dexList;
        address[] tokens;
    }

    address uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address soloAddress = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address manager;
    mapping(address => bool) public approvalList;
    mapping(address => uint256) public profitAll; // 累计每个erc20的套利
    mapping(address => mapping(address => uint256)) public profitAddress; // 累计每个地址的每个erc20的套利
    uint256 public percent = 300; // div 10000

    constructor() public {
        manager = msg.sender;
    }

    modifier isManager() {
        require(manager == msg.sender, "Not manager!");
        _;
    }

    function setManager(address _manager) public isManager {
        manager = _manager;
    }

    function setPercent(uint256 _percent) public isManager {
        percent = _percent;
    }

    function dydxLoan(
        address _token,
        uint256 _amount,
        uint256[] calldata _dexList,
        address[] calldata _tokens
    ) external {
        require(
            _dexList.length >= 2 && _dexList.length == _tokens.length,
            "Length inconsistency!"
        );
        approvalToken(_token);
        for (uint256 i = 0; i < _tokens.length; i++) {
            approvalToken(_tokens[i]);
        }
        ISoloMargin solo = ISoloMargin(soloAddress);
        uint256 marketId = _getMarketIdFromTokenAddress(soloAddress, _token);
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(
                MyCustomData({
                    token: _token,
                    pairAddress: address(0),
                    repayAmount: repayAmount,
                    lendProject: uint256(0),
                    dexList: _dexList,
                    tokens: _tokens
                })
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);
        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();
        solo.operate(accountInfos, operations);
    }

    function uniLoan(
        address _token,
        address pairAddress,
        uint256 lendProject,
        uint256 _amount,
        uint256[] calldata _dexList,
        address[] calldata _tokens
    ) external {
        require(
            _dexList.length >= 2 && _dexList.length == _tokens.length,
            "Length inconsistency!"
        );
        approvalToken(_token);
        for (uint256 i = 0; i < _tokens.length; i++) {
            approvalToken(_tokens[i]);
        }
        uint256 _amount0 = 0;
        uint256 _amount1 = 0;
        if (IUniswapV2Pair(pairAddress).token0() == _token) {
            _amount0 = _amount;
        } else {
            _amount1 = _amount;
        }

        bytes memory data =
            abi.encode(
                MyCustomData({
                    token: _token,
                    pairAddress: pairAddress,
                    repayAmount: uint256(0),
                    lendProject: lendProject,
                    dexList: _dexList,
                    tokens: _tokens
                })
            );
        IUniswapV2Pair(pairAddress).swap(
            _amount0,
            _amount1,
            address(this),
            data
        );
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));

        address[] memory path = new address[](2);
        uint256[] memory amounts;
        address _lendToken = address(mcd.token);
        uint256 _repayAmount = mcd.repayAmount.sub(2);
        for (uint256 i = 0; i < mcd.dexList.length; i++) {
            path[0] = address(_lendToken);
            path[1] = address(mcd.tokens[i]);

            if (mcd.dexList[i] == 1) {
                amounts = IUniswapV2Router01(uniRouter)
                    .swapExactTokensForTokens(
                    _repayAmount,
                    0,
                    path,
                    address(this),
                    now + 1800
                );
            }
            if (mcd.dexList[i] == 2) {
                amounts = IUniswapV2Router01(sushiRouter)
                    .swapExactTokensForTokens(
                    _repayAmount,
                    0,
                    path,
                    address(this),
                    now + 1800
                );
            }
            _lendToken = address(mcd.tokens[i]);
            _repayAmount = amounts[1];
        }

        uint256 newBal = IERC20(mcd.token).balanceOf(address(this));

        require(
            newBal > mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );

        uint256 profit = newBal - mcd.repayAmount;
        uint256 transferAmount = (profit * (10000 - percent)) / 10000;
        // bytes4(keccak256(bytes("transfer(address,uint256)"))) = 0xa9059cbb
        (bool success, bytes memory result) =
            mcd.token.call(
                abi.encodeWithSelector(0xa9059cbb, tx.origin, transferAmount)
            );
        require(
            success && (result.length == 0 || abi.decode(result, (bool))),
            "Failed to transfer to sender!"
        );
        profitAll[mcd.token] += profit;
        profitAddress[tx.origin][mcd.token] += profit;
        if (profit > transferAmount) {
            IERC20(mcd.token).transfer(manager, profit - transferAmount);
        }
    }

    function uniswapV2Call(
        address account,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) public {
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));

        address[] memory path = new address[](2);
        uint256[] memory amounts;
        address _lendToken = address(mcd.token);
        uint256 swapResult = IERC20(mcd.token).balanceOf(address(this));
        for (uint256 i = 0; i < mcd.dexList.length; i++) {
            path[0] = address(_lendToken);
            path[1] = address(mcd.tokens[i]);
            if (mcd.dexList[i] == 1) {
                amounts = IUniswapV2Router01(uniRouter)
                    .swapExactTokensForTokens(
                    swapResult,
                    0,
                    path,
                    address(this),
                    now + 1800
                );
            }
            if (mcd.dexList[i] == 2) {
                amounts = IUniswapV2Router01(sushiRouter)
                    .swapExactTokensForTokens(
                    swapResult,
                    0,
                    path,
                    address(this),
                    now + 1800
                );
            }
            _lendToken = address(mcd.tokens[i]);
            swapResult = amounts[1];
        }

        // 计算需要还的数量
        uint256 reply = 0;
        if (mcd.lendProject == 1) {
            path[0] = address(mcd.tokens[mcd.tokens.length - 1]);
            path[1] = address(mcd.token);
            amounts = IUniswapV2Router01(uniRouter).getAmountsIn(
                amount0 > 0 ? amount0 : amount1,
                path
            );
            reply = amounts[0];
        } else if (mcd.lendProject == 2) {
            path[0] = address(mcd.tokens[mcd.tokens.length - 1]);
            path[1] = address(mcd.token);
            amounts = IUniswapV2Router01(sushiRouter).getAmountsIn(
                amount0 > 0 ? amount0 : amount1,
                path
            );
            reply = amounts[0];
        }

        uint256 newBal =
            IERC20(mcd.tokens[mcd.tokens.length - 1]).balanceOf(address(this));

        require(
            newBal > reply,
            "Not enough funds to repay uniswap or sushiswap!"
        );

        IERC20(mcd.tokens[mcd.tokens.length - 1]).transfer(
            mcd.pairAddress,
            reply
        );
        uint256 profit = newBal - reply;
        uint256 transferAmount = (profit * (10000 - percent)) / 10000;
        // bytes4(keccak256(bytes("transfer(address,uint256)"))) = 0xa9059cbb
        (bool success, bytes memory result) =
            address(mcd.tokens[mcd.tokens.length - 1]).call(
                abi.encodeWithSelector(0xa9059cbb, tx.origin, transferAmount)
            );
        require(
            success && (result.length == 0 || abi.decode(result, (bool))),
            "Failed to transfer to sender!"
        );

        profitAll[mcd.tokens[mcd.tokens.length - 1]] += profit;
        profitAddress[tx.origin][mcd.tokens[mcd.tokens.length - 1]] += profit;
        if (profit > transferAmount) {
            IERC20(mcd.tokens[mcd.tokens.length - 1]).transfer(
                manager,
                profit - transferAmount
            );
        }
    }

    function calculate(
        address lendToken,
        uint256 lendNumber,
        uint256 lendProject,
        uint256[] memory dexList,
        address[] memory tokens
    ) public view returns (uint256 swapResult, uint256 reply) {
        require(
            dexList.length >= 2 && dexList.length == tokens.length,
            "Length inconsistency!"
        );
        address[] memory path = new address[](2);
        uint256[] memory amounts;
        address _lendToken = address(lendToken);
        swapResult = lendNumber;
        for (uint256 i = 0; i < dexList.length; i++) {
            path[0] = address(_lendToken);
            path[1] = address(tokens[i]);
            if (dexList[i] == 1) {
                amounts = IUniswapV2Router01(uniRouter).getAmountsOut(
                    swapResult,
                    path
                );
            } else if (dexList[i] == 2) {
                amounts = IUniswapV2Router01(sushiRouter).getAmountsOut(
                    swapResult,
                    path
                );
            } else {
                require(false, "Not the DEX id!");
            }
            _lendToken = tokens[i];
            swapResult = amounts[1];
        }
        // swapResult 最终兑换回来的数量
        reply = lendNumber; // 需要还的数量
        if (lendToken != _lendToken) {
            path[0] = lendToken;
            path[1] = _lendToken;
            if (lendProject == 1) {
                amounts = IUniswapV2Router01(uniRouter).getAmountsOut(
                    lendNumber,
                    path
                );
                reply = amounts[1];
            } else if (lendProject == 2) {
                amounts = IUniswapV2Router01(sushiRouter).getAmountsOut(
                    lendNumber,
                    path
                );
                reply = amounts[1];
            }
        }
    }

    function approvalToken(address _token) public {
        if (!approvalList[_token]) {
            address[] memory adds = new address[](3);
            adds[0] = uniRouter;
            adds[1] = sushiRouter;
            adds[2] = soloAddress;
            // bytes4(keccak256(bytes('approve(address,uint256)'))) = 0x095ea7b3
            for (uint256 i = 0; i < adds.length; i++) {
                (bool success, bytes memory data) =
                    _token.call(
                        abi.encodeWithSelector(0x095ea7b3, adds[i], uint256(-1))
                    );
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    "Approval of failure!"
                );
            }
            approvalList[_token] = true;
        }
    }
}

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);
}