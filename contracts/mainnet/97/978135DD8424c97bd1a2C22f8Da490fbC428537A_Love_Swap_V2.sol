pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

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

    function _getWithdrawAction(uint marketId, uint256 amount)
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

    function _getDepositAction(uint marketId, uint256 amount)
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

contract Love_Swap_V2 is DydxFlashloanBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using address_make_payable for address;
    
    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }
    
    address superMan;
    address cofixRouter = 0x26aaD4D82f6c9FA6E34D8c1067429C986A055872;
    address uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address cofiAddress = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;
    address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address dydxAddress = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    uint256 cofixETHSapn = 300 ether;
    uint256 nestPrice = 0.01 ether;
    
    
    constructor() public {
        superMan = address(msg.sender);
        IERC20(USDTAddress).safeApprove(cofixRouter, 10000000000000000);
        IERC20(USDTAddress).safeApprove(uniRouter, 10000000000000000);
    }
    
    function getCofixRouter() public view returns(address) {
        return cofixRouter;
    }
    
    function getUniRouter() public view returns(address) {
        return uniRouter;
    }
    
    function getNestPrice() public view returns(uint256) {
        return nestPrice;
    }
    
    function getSuperMan() public view returns(address) {
        return superMan;
    }
    
    function getCofixETHSapn() public view returns(uint256) {
        return cofixETHSapn;
    }
    
    function setCofixRouter(address _cofixRouter) public onlyOwner {
        cofixRouter = _cofixRouter;
    }
    
    function setUniRouter(address _uniRouter) public onlyOwner {
        uniRouter = _uniRouter;
    }
    
    function setNestPrice(uint256 _amount) public onlyOwner {
        nestPrice = _amount;
    }
    
    function setSuperMan(address _newMan) public onlyOwner {
        superMan = _newMan;
    }
    
    function setCofixETHSapn(uint256 _amount) public onlyOwner {
        cofixETHSapn = _amount;
    }
    
    //  实现操作
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));
        uint256 tokenBalanceBefore = IERC20(mcd.token).balanceOf(address(this));
        // money
        // WETH->ETH
        WETH9(WETHAddress).withdraw(tokenBalanceBefore);
        // ETH->USDT
        uint256 loopTimes = address(this).balance.div(cofixETHSapn);
        for(uint256 i = 0; i < loopTimes; i++) {
            CoFiXRouter(cofixRouter).swapExactETHForTokens{value:cofixETHSapn}(USDTAddress,cofixETHSapn.sub(nestPrice),1,address(this), address(this), uint256(block.timestamp).add(100));
        }
        // USDT->ETH
        uint256 usdtBalance = IERC20(USDTAddress).balanceOf(address(this));
        address[] memory uniData = new address[](2);
        uniData[0] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        uniData[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        UniswapV2Router(uniRouter).swapExactTokensForETH(usdtBalance,1,uniData,address(this),uint256(block.timestamp).add(100));
        // ETH->WETH
        WETH9(WETHAddress).deposit{value:tokenBalanceBefore.add(2)};
        
        uint256 balOfLoanedToken = IERC20(mcd.token).balanceOf(address(this));
        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );
        
    }
    
    function initiateFlashLoan(uint256 _amount)
        external
    {
        ISoloMargin solo = ISoloMargin(dydxAddress);
        uint256 marketId = _getMarketIdFromTokenAddress(dydxAddress, WETHAddress);
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(WETHAddress).approve(dydxAddress, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(MyCustomData({token: WETHAddress, repayAmount: repayAmount}))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }
    

    function moreETH() public payable {
        
    }
    
    function turnOutToken(address token, uint256 amount) public onlyOwner{
        IERC20(token).safeTransfer(superMan, amount);
    }
    
    function turnOutETH(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
    }
    
    function getTokenBalance(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    
    function getETHBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner(){
        require(address(msg.sender) == superMan, "No authority");
        _;
    }
    
    receive() external payable {
        
    }
}

interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface CoFiXRouter {
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
}

interface UniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


library SafeMath {
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
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// dydx


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


abstract contract ISoloMargin{
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public virtual;

    function getIsGlobalOperator(address operator) public virtual returns (bool);

    function getMarketTokenAddress(uint256 marketId)
        public
        virtual
        view
        returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter)
        public virtual;

    function getAccountValues(Account.Info memory account)
        public
        virtual
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId)
        public
        virtual
        returns (address);

    function getMarketInterestSetter(uint256 marketId)
        public
        virtual
        returns (address);

    function getMarketSpreadPremium(uint256 marketId)
        public
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

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) public virtual;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) public virtual;

    function getIsLocalOperator(address owner, address operator)
        public
        virtual
        returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId)
        public
        virtual
        returns (Types.Par memory);

    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public
    virtual;

    function getMarginRatio() public virtual returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId)
        public
        virtual
        returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) public virtual returns (bool);

    function getRiskParams() public virtual returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        public
        virtual
        returns (address[] memory, Types.Par[] memory, Types.Wei[] memory);

    function renounceOwnership() public virtual;

    function getMinBorrowedValue() public virtual returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) public virtual;

    function getMarketPrice(uint256 marketId) public virtual returns (address);

    function owner() public virtual returns (address);

    function isOwner() public virtual returns (bool);

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
    ) public
    virtual;

    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public
    virtual;

    function getMarketWithInfo(uint256 marketId)
        public
        virtual
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) public virtual;

    function getLiquidationSpread() public virtual returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId)
        public
        virtual
        returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId)
        public
        virtual
        returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) public virtual returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId)
        public
        virtual
        returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId)
        public
        virtual
        returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account)
        public
        virtual
        returns (uint8);

    function getEarningsRate() public virtual returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) public virtual;

    function getRiskLimits() public virtual returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId)
        public
        virtual
        returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) public virtual;

    function ownerSetGlobalOperator(address operator, bool approved) public virtual;

    function transferOwnership(address newOwner) public virtual;

    function getAdjustedAccountValues(Account.Info memory account)
        public
        virtual
        returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId)
        public
        virtual
        returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId)
        public
        virtual
        returns (Interest.Rate memory);
}