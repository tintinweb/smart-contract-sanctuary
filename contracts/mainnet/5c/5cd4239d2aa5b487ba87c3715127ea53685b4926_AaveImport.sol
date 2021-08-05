/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

pragma solidity ^0.6.0; 

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
        Buy, // buy an amount of some token (public virtually)
        Sell, // sell an amount of some token (public virtually)
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

    function getIsGlobalOperator(address operator) public virtual view returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        public virtual
        view
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        public virtual;

    function getAccountValues(Account.Info memory account)
        public virtual
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        public virtual
        view
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        public virtual
        view
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        public virtual
        view
        returns (Decimal.D256 memory);

    function getNumMarkets() public virtual view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        public virtual
        returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue)
        public virtual;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) public virtual;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) public virtual;

    function getIsLocalOperator(address owner, address operator)
        public virtual
        view
        returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId)
        public virtual
        view
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public virtual;

    function getMarginRatio() public virtual view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        public virtual
        view
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) public virtual view returns (bool);

    function getRiskParams() public virtual view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        public virtual
        view
        returns (address[] memory, Types.Par[] memory, Types.Wei[] memory);

    function renounceOwnership() public virtual;

    function getMinBorrowedValue() public virtual view returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) public virtual;

    function getMarketPrice(uint256 marketId) public virtual view returns (address);

    function owner() public virtual view returns (address);

    function isOwner() public virtual view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        public virtual
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
        public virtual
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) public virtual;

    function getLiquidationSpread() public virtual view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId)
        public virtual
        view
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        public virtual
        view
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) public virtual view returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        public virtual
        view
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        public virtual
        view
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account)
        public virtual
        view
        returns (uint8);

    function getEarningsRate() public virtual view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) public virtual;

    function getRiskLimits() public virtual view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        public virtual
        view
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) public virtual;

    function ownerSetGlobalOperator(address operator, bool approved) public virtual;

    function transferOwnership(address newOwner) public virtual;

    function getAdjustedAccountValues(Account.Info memory account)
        public virtual
        view
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        public virtual
        view
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        public virtual
        view
        returns (Interest.Rate memory);
} interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
} library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
} library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} abstract contract TokenInterface {
	address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
} abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
} contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
} contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
} abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    // function execute(bytes memory _code, bytes memory _data)
    //     public
    //     payable
    //     virtual
    //     returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public virtual payable returns (bool);
}


contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
} contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
} contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
} abstract contract IAToken {
    function redeem(uint256 _amount) external virtual;
    function balanceOf(address _owner) external virtual view returns (uint256 balance);
} abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external virtual payable;
	function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external virtual;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external virtual;
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual payable;
	function swapBorrowRateMode(address _reserve) external virtual;
    function getReserves() external virtual view returns(address[] memory);

    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,               // reserve total liquidity
            uint256 availableLiquidity,           // reserve available liquidity for borrowing
            uint256 totalBorrowsStable,           // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable,         // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate,                // current deposit APY of the reserve for depositors, in Ray units.
            uint256 variableBorrowRate,           // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate,             // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate,      // current average stable borrow rate
            uint256 utilizationRate,              // expressed as total borrows/total liquidity.
            uint256 liquidityIndex,               // cumulative liquidity index
            uint256 variableBorrowIndex,          // cumulative variable borrow index
            address aTokenAddress,                // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp            // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external virtual
        view
        returns (
            uint256 totalLiquidityETH,            // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH,           // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH,              // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH,                 // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH,          // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold,  // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv,                          // user average Loan-to-Value between all the collaterals
            uint256 healthFactor                  // user current Health Factor
    );    

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external virtual
        view
        returns (
            uint256 currentATokenBalance,         // user current reserve aToken balance
            uint256 currentBorrowBalance,         // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance,       // user balance of borrowed asset
            uint256 borrowRateMode,               // user borrow rate mode either Stable or Variable
            uint256 borrowRate,                   // user current borrow rate APY
            uint256 liquidityRate,                // user current earn rate on _reserve
            uint256 originationFee,               // user outstanding loan origination fee
            uint256 variableBorrowIndex,          // user variable cumulative index
            uint256 lastUpdateTimestamp,          // Timestamp of the last data update
            bool usageAsCollateralEnabled         // Whether the user's current reserve is enabled as a collateral
    );

    function getReserveConfigurationData(address _reserve)
        external virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
    );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public virtual view returns (address);
    function getReserveConfiguration(address _reserve)
        external virtual
        view
        returns (uint256, uint256, uint256, bool);
    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public virtual
        view
        returns (uint256);

    function getReserveCurrentLiquidityRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentVariableBorrowRate(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveCurrentStableBorrowRate(address _reserve) 
        public virtual
        view
        returns (uint256);
    function getReserveTotalLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveAvailableLiquidity(address _reserve)
        public virtual
        view
        returns (uint256);
    function getReserveTotalBorrowsVariable(address _reserve)
        public virtual
        view
        returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public virtual
        view
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
} /**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */
abstract contract ILendingPoolAddressesProvider {

    function getLendingPool() public virtual view returns (address);
    function getLendingPoolCore() public virtual view returns (address payable);
    function getLendingPoolConfigurator() public virtual view returns (address);
    function getLendingPoolDataProvider() public virtual view returns (address);
    function getLendingPoolParametersProvider() public virtual view returns (address);
    function getTokenDistributor() public virtual view returns (address);
    function getFeeProvider() public virtual view returns (address);
    function getLendingPoolLiquidationManager() public virtual view returns (address);
    function getLendingPoolManager() public virtual view returns (address);
    function getPriceOracle() public virtual view returns (address);
    function getLendingRateOracle() public virtual view returns (address);
} /************
@title IPriceOracleGetterAave interface
@notice Interface for the Aave price oracle.*/
abstract contract IPriceOracleGetterAave {
    function getAssetPrice(address _asset) external virtual view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external virtual view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external virtual view returns(address);
    function getFallbackOracle() external virtual view returns(address);
} contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
        admin = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
} contract BotRegistry is AdminAuth {

    mapping (address => bool) public botList;

    constructor() public {
        botList[0x776B4a13093e30B05781F97F6A4565B6aa8BE330] = true;

        botList[0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF] = true;
        botList[0xa5d330F6619d6bF892A5B87D80272e1607b3e34D] = true;
        botList[0x5feB4DeE5150B589a7f567EA7CADa2759794A90A] = true;
        botList[0x7ca06417c1d6f480d3bB195B80692F95A6B66158] = true;
    }

    function setBot(address _botAddr, bool _state) public onlyOwner {
        botList[_botAddr] = _state;
    }

} contract AaveHelper is DSMath {

    using SafeERC20 for ERC20;

    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant MANUAL_SERVICE_FEE = 400; // 0.25% Fee
    uint public constant AUTOMATIC_SERVICE_FEE = 333; // 0.3% Fee

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

	address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    uint public constant NINETY_NINE_PERCENT_WEI = 990000000000000000;
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @param _collateralAddress underlying token address
    /// @param _user users address
	function getMaxCollateral(address _collateralAddress, address _user) public view returns (uint256) {
        address lendingPoolAddressDataProvider = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolDataProvider();
        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        uint256 pow10 = 10 ** (18 - _getDecimals(_collateralAddress));

        // fetch all needed data
        (,uint256 totalCollateralETH, uint256 totalBorrowsETH,,uint256 currentLTV,,,) = ILendingPool(lendingPoolAddressDataProvider).calculateUserGlobalData(_user);
        (,uint256 tokenLTV,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_collateralAddress);
        uint256 collateralPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_collateralAddress);
        uint256 userTokenBalance = ILendingPool(lendingPoolCoreAddress).getUserUnderlyingAssetBalance(_collateralAddress, _user);
        uint256 userTokenBalanceEth = wmul(userTokenBalance * pow10, collateralPrice);

		// if borrow is 0, return whole user balance
        if (totalBorrowsETH == 0) {
        	return userTokenBalance;
        }

        uint256 maxCollateralEth = div(sub(mul(currentLTV, totalCollateralETH), mul(totalBorrowsETH, 100)), currentLTV);
		/// @dev final amount can't be higher than users token balance
        maxCollateralEth = maxCollateralEth > userTokenBalanceEth ? userTokenBalanceEth : maxCollateralEth;

        // might happen due to wmul precision
        if (maxCollateralEth >= totalCollateralETH) {
        	return wdiv(totalCollateralETH, collateralPrice) / pow10;
        }

        // get sum of all other reserves multiplied with their liquidation thresholds by reversing formula
        uint256 a = sub(wmul(currentLTV, totalCollateralETH), wmul(tokenLTV, userTokenBalanceEth));
        // add new collateral amount multiplied by its threshold, and then divide with new total collateral
        uint256 newLiquidationThreshold = wdiv(add(a, wmul(sub(userTokenBalanceEth, maxCollateralEth), tokenLTV)), sub(totalCollateralETH, maxCollateralEth));

        // if new threshold is lower than first one, calculate new max collateral with newLiquidationThreshold
        if (newLiquidationThreshold < currentLTV) {
        	maxCollateralEth = div(sub(mul(newLiquidationThreshold, totalCollateralETH), mul(totalBorrowsETH, 100)), newLiquidationThreshold);
        	maxCollateralEth = maxCollateralEth > userTokenBalanceEth ? userTokenBalanceEth : maxCollateralEth;
        }

		return wmul(wdiv(maxCollateralEth, collateralPrice) / pow10, NINETY_NINE_PERCENT_WEI);
	}

	/// @param _borrowAddress underlying token address
	/// @param _user users address
	function getMaxBorrow(address _borrowAddress, address _user) public view returns (uint256) {
		address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
		address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

		(,,,,uint256 availableBorrowsETH,,,) = ILendingPool(lendingPoolAddress).getUserAccountData(_user);

		uint256 borrowPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_borrowAddress);

		return wmul(wdiv(availableBorrowsETH, borrowPrice) / (10 ** (18 - _getDecimals(_borrowAddress))), NINETY_NINE_PERCENT_WEI);
	}

    function getMaxBoost(address _borrowAddress, address _collateralAddress, address _user) public view returns (uint256) {
        address lendingPoolAddressDataProvider = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolDataProvider();
        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        (,uint256 totalCollateralETH, uint256 totalBorrowsETH,,uint256 currentLTV,,,) = ILendingPool(lendingPoolAddressDataProvider).calculateUserGlobalData(_user);
        (,uint256 tokenLTV,,) = ILendingPool(lendingPoolCoreAddress).getReserveConfiguration(_collateralAddress);
        totalCollateralETH = div(mul(totalCollateralETH, currentLTV), 100);

        uint256 availableBorrowsETH = wmul(mul(div(sub(totalCollateralETH, totalBorrowsETH), sub(100, tokenLTV)), 100), NINETY_NINE_PERCENT_WEI);
        uint256 borrowPrice = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_borrowAddress);

        return wdiv(availableBorrowsETH, borrowPrice) / (10 ** (18 - _getDecimals(_borrowAddress)));
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getFee(uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint feeAmount) {
        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();

        uint fee = MANUAL_SERVICE_FEE;

        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            fee = AUTOMATIC_SERVICE_FEE;
        }

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddr);

            _gasCost = wdiv(_gasCost, price) / (10 ** (18 - _getDecimals(_tokenAddr)));

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        if (_tokenAddr == ETH_ADDR) {
            WALLET_ADDR.transfer(feeAmount);
        } else {
            ERC20(_tokenAddr).safeTransfer(WALLET_ADDR, feeAmount);
        }
    }

    /// @notice Calculates the gas cost for transaction
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _tokenAddr token addr. of token we are getting for the fee
    /// @return gasCost The amount we took for the gas cost
    function getGasCost(uint _amount, address _user, uint _gasCost, address _tokenAddr) internal returns (uint gasCost) {

        if (_gasCost == 0) return 0;

        address priceOracleAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getPriceOracle();
        uint256 price = IPriceOracleGetterAave(priceOracleAddress).getAssetPrice(_tokenAddr);

        _gasCost = wmul(_gasCost, price);
        gasCost = _gasCost;

        // fee can't go over 20% of the whole amount
        if (gasCost > (_amount / 5)) {
            gasCost = _amount / 5;
        }

        if (_tokenAddr == ETH_ADDR) {
            WALLET_ADDR.transfer(gasCost);
        } else {
            ERC20(_tokenAddr).safeTransfer(WALLET_ADDR, gasCost);
        }
    }


    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(payable(address(this)));

        return proxy.owner();
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    /// @notice Send specific amount from contract to specific user
    /// @param _token Token we are trying to send
    /// @param _user User that should receive funds
    /// @param _amount Amount that should be sent
    function sendContractBalance(address _token, address _user, uint _amount) public {
        if (_amount == 0) return;

        if (_token == ETH_ADDR) {
            payable(_user).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_user, _amount);
        }
    }

    function sendFullContractBalance(address _token, address _user) public {
        if (_token == ETH_ADDR) {
            sendContractBalance(_token, _user, address(this).balance);
        } else {
            sendContractBalance(_token, _user, ERC20(_token).balanceOf(address(this)));
        }
    }

    function _getDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return ERC20(_token).decimals();
    }
} 








// weth->eth
// deposit eth for users proxy
// borrow users token from proxy
// repay on behalf of user
// pull user supply
// take eth amount from supply (if needed more, borrow it?)
// return eth to sender

/// @title Import Aave position from account to wallet
contract AaveImport is AaveHelper, AdminAuth {

    using SafeERC20 for ERC20;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant BASIC_PROXY = 0xF499FB2feb3351aEA373723a6A0e8F6BE6fBF616;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    address public constant PULL_TOKENS_PROXY = 0x45431b79F783e0BF0fe7eF32D06A3e061780bfc4;

    function callFunction(
        address,
        Account.Info memory,
        bytes memory data
    ) public {

        (
            address collateralToken,
            address borrowToken,
            uint256 ethAmount,
            address proxy
        )
        = abi.decode(data, (address,address,uint256,address));

        address user = DSProxy(payable(proxy)).owner();

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        address aCollateralToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(collateralToken);
        address aBorrowToken = ILendingPool(lendingPoolCoreAddress).getReserveATokenAddress(borrowToken);
        uint256 globalBorrowAmount = 0;

        { // avoid stack too deep
            // deposit eth on behalf of proxy
            DSProxy(payable(proxy)).execute{value: ethAmount}(BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
            // borrow needed amount to repay users borrow
            (,uint256 borrowAmount,,uint256 borrowRateMode,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(borrowToken, user);
            borrowAmount += originationFee;
            DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("borrow(address,uint256,uint256)", borrowToken, borrowAmount, borrowRateMode));
            globalBorrowAmount = borrowAmount;
        }

        // payback on behalf of user
        if (borrowToken != ETH_ADDR) {
            ERC20(borrowToken).safeApprove(proxy, globalBorrowAmount);
            DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,bool,address)", borrowToken, aBorrowToken, 0, true, user));
        } else {
            DSProxy(payable(proxy)).execute{value: globalBorrowAmount}(BASIC_PROXY, abi.encodeWithSignature("paybackOnBehalf(address,address,uint256,bool,address)", borrowToken, aBorrowToken, 0, true, user));
        }

         // pull coll tokens
        DSProxy(payable(proxy)).execute(PULL_TOKENS_PROXY, abi.encodeWithSignature("pullTokens(address,uint256)", aCollateralToken, ERC20(aCollateralToken).balanceOf(user)));


        // enable as collateral
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("setUserUseReserveAsCollateralIfNeeded(address)", collateralToken));

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));


        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external payable {
        // deposit eth and get weth
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit{value: (address(this).balance)}();
        }
    }
}