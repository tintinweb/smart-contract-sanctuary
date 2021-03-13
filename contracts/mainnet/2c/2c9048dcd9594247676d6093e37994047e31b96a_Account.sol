/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

// -- DydxFlashloanBase -- //

contract DydxFlashloanBase {
    using SafeMath for uint256;

    function _getMarketIdFromTokenAddress(address _solo, address token)
        internal
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
        return amount.add(2);
    }

    function _getAccountInfo() internal returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint marketId, uint256 amount)
        internal
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

// -- WyArbiV2 -- //
contract WyArbiV2 is DydxFlashloanBase{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using address_make_payable for address;

    struct MyCustomData {       // 还款信息
        address token;          // token
        uint256 repayAmount;    // 还款数量
    }

    struct StrategyData {       // 策略信息
        address token_want;     // 需要的token
        address token_media;    // 中转token
        address protocol1;      // 协议1地址
        address protocol2;      // 协议2地址
        uint256 in_amount;      // 输入数量
    }

    address superMan;
    address dydxAddress;
    address liquidityPoolAddress;
    address uniswapAddress;
    address WETHAddress;
    address USDTAddress;
    address GasTokenV2;

    mapping (address => mapping (address => int128)) public tokenId;  //protocol地址->token地址->tokenId
    mapping (address => uint256) public functionId;                   //protocol地址->functionId

    bool if_turnout = true;             // 盈利是否转出
    bool if_gastoken = true;            // 是否使用GasToken
    MyCustomData dydx_mcd;              // dydx还款信息
    MyCustomData liquidity_mcd;         // liquidity还款信息
    StrategyData strategy_data;         // 策略信息
    uint256 profit;                     // 盈利数量

    constructor () public {
        superMan = address(tx.origin);
        dydxAddress = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
        liquidityPoolAddress = 0x35fFd6E268610E764fF6944d07760D0EFe5E40E5;
        uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        GasTokenV2 = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

        // curve3pool tokenId DAI USDC USDT
        tokenId[address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7)][address(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = 0;
        tokenId[address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7)][address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 1;
        tokenId[address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7)][address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = 2;

        // curveYpool tokenId DAI USDC USDT
        tokenId[address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)][address(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = 0;
        tokenId[address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)][address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 1;
        tokenId[address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)][address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = 2;
        tokenId[address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)][address(0x0000000000085d4780B73119b644AE5ecd22b376)] = 3;

        // stableswap tokenId USDP DAI USDC USDT
        tokenId[address(0x42d7025938bEc20B69cBae5A77421082407f053A)][address(0x1456688345527bE1f37E9e627DA0837D6f08C925)] = 0;
        tokenId[address(0x42d7025938bEc20B69cBae5A77421082407f053A)][address(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = 1;
        tokenId[address(0x42d7025938bEc20B69cBae5A77421082407f053A)][address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 2;
        tokenId[address(0x42d7025938bEc20B69cBae5A77421082407f053A)][address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = 3;

        // dodo tokenId USDT USDC
        tokenId[address(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD)][address(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = 0;
        tokenId[address(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD)][address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 1;

        // btcswap tokenId TBTC WBTC renBTC sBTC
        tokenId[address(0x4f6A43Ad7cba042606dECaCA730d4CE0A57ac62e)][address(0x8dAEBADE922dF735c38C80C7eBD708Af50815fAa)] = 0;
        tokenId[address(0x4f6A43Ad7cba042606dECaCA730d4CE0A57ac62e)][address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)] = 1;
        tokenId[address(0x4f6A43Ad7cba042606dECaCA730d4CE0A57ac62e)][address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D)] = 2;
        tokenId[address(0x4f6A43Ad7cba042606dECaCA730d4CE0A57ac62e)][address(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6)] = 3;

        // curve3Pool functionId
        functionId[address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7)] = 1;
        // curveYPool functionId
        functionId[address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)] = 2;
        // stableswap functionId
        functionId[address(0x42d7025938bEc20B69cBae5A77421082407f053A)] = 3;
        // component functionId
        functionId[address(0x49519631B404E06ca79C9C7b0dC91648D86F08db)] = 4;
        functionId[address(0x6477960dd932d29518D7e8087d5Ea3D11E606068)] = 4;
        // dodo functionId
        functionId[address(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD)] = 5;
        // btcswap functionId
        functionId[address(0x4f6A43Ad7cba042606dECaCA730d4CE0A57ac62e)] = 6;
        // uniswapv2 functionId
        functionId[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = 7;
        // sushiswap functionId
        functionId[address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)] = 7;
        // balancer functionId
        functionId[address(0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21)] = 8;
    }

    // 发起dydx闪电贷
    function initiateFlashLoanDydx(address _token, uint256 _amount) public {

        ISoloMargin solo = ISoloMargin(dydxAddress);
        uint256 marketId = _getMarketIdFromTokenAddress(dydxAddress, _token);
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(dydxAddress, repayAmount);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);

        // 盈利转出
        if (if_turnout) {
            if (_token == WETHAddress) {
                WETHToETH(profit);
                turnOutETH(profit);
            } else {
                uint256 eth_out = uniswapTokensForETH(_token, profit);
                turnOutETH(eth_out);
            }
        }
    }

    //  dydx闪电贷实现操作
    function callFunction(address sender, Account.Info memory account, bytes memory data) public {
        // 还款信息
        dydx_mcd = abi.decode(data, (MyCustomData));

        // 操作
        uint256 output_amount = operation();

        // 检查盈利
        require(output_amount > dydx_mcd.repayAmount, "no profit!");
        profit = output_amount - dydx_mcd.repayAmount;
    }

    // 操作
    function operation() public returns (uint256) {
        uint256 media_amount = ExchangeBase(
            strategy_data.protocol1,
            strategy_data.token_want,
            strategy_data.token_media,
            strategy_data.in_amount
        );
        if (media_amount == 0) {
            return strategy_data.in_amount;
        }
        uint256 output_amount = ExchangeBase(
            strategy_data.protocol2,
            strategy_data.token_media,
            strategy_data.token_want,
            media_amount
        );
        return output_amount;
    }

    // 入口
    function execute(address token_want, address token_media, address protocol1, address protocol2,
        uint256 in_amount, uint256 free_value) public {

        if (if_gastoken) {
            freeGas(free_value);
        }

        strategy_data.in_amount = in_amount;
        strategy_data.token_want = token_want;
        strategy_data.token_media = token_media;
        strategy_data.protocol1 = protocol1;
        strategy_data.protocol2 = protocol2;

        initiateFlashLoanDydx(token_want, in_amount);
    }

    // ExchangeBase
    function ExchangeBase(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 function_id = functionId[protocol];
        uint256 output_amount = 0;

        if (token_in == USDTAddress) {
            IERC20(token_in).safeApprove(protocol, 0);
            IERC20(token_in).safeApprove(protocol, in_amount);
        } else {
            IERC20(token_in).approve(protocol, in_amount);
        }

        if (function_id == 1) {
            output_amount = ICurveFiExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 2) {
            output_amount = ICurveFiExchangeUnderlying(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 3) {
            output_amount = IStableSwapExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 4) {
            output_amount = IComponentExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 5) {
            output_amount = IDODOExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 6) {
            output_amount = IBTCSwapExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 7) {
            output_amount = IUniswapExchange(protocol, token_in, token_out, in_amount);
        }
        if (function_id == 8) {
            output_amount = IBalancerExchange(protocol, token_in, token_out, in_amount);
        }
        return output_amount;
    }

    // ICurveFiExchange functionId=1
    function ICurveFiExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 balance = IERC20(token_out).balanceOf(address(this));
        ICurveFi(protocol).exchange(tokenId[protocol][token_in], tokenId[protocol][token_out], in_amount, 0);

        return IERC20(token_out).balanceOf(address(this)).sub(balance);
    }

    // ICurveFiExchangeUnderlying functionId=2
    function ICurveFiExchangeUnderlying(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 balance = IERC20(token_out).balanceOf(address(this));
        ICurveFi(protocol).exchange_underlying(tokenId[protocol][token_in], tokenId[protocol][token_out], in_amount, 0);

        return IERC20(token_out).balanceOf(address(this)).sub(balance);
    }

    // IStableSwapExchange functionId=3
    function IStableSwapExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 out_amount = IStableSwap(protocol).exchange_underlying(
            tokenId[protocol][token_in], tokenId[protocol][token_out], in_amount, 0);

        return out_amount;
    }

    // IComponentExchange functionId=4
    function IComponentExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 out_amount = IComponent(protocol).originSwap(token_in, token_out, in_amount, 0, uint256(block.timestamp).add(100));

        return out_amount;
    }

    // IDODOExchange functionId=5  Base=0 Quote=1 只支持token_in=base token_out=quote
    function IDODOExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        int128 token_in_id = tokenId[protocol][token_in];
        int128 token_out_id = tokenId[protocol][token_out];
        uint256 out_amount;
        if (token_in_id == 0 && token_out_id == 1) {
            out_amount = IDODO(protocol).sellBaseToken(in_amount, 0, '');
        } else {
            revert("token_id wrong for dodo!");
        }
        return out_amount;
    }

    // IBTCSwapExchange functionId=6
    function IBTCSwapExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint8 token_in_id = uint8(tokenId[protocol][token_in]);
        uint8 token_out_id = uint8(tokenId[protocol][token_out]);

        uint256 out_amount = IBTCswap(protocol).swap(token_in_id, token_out_id, in_amount, 0, uint256(block.timestamp).add(100));
        return out_amount;
    }

    // IUniswapExchange functionId=7
    function IUniswapExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        address[] memory uniData = new address[](2);
        uniData[0] = token_in;
        uniData[1] = token_out;
        uint[] memory amounts = UniswapV2Router(protocol).swapExactTokensForTokens(in_amount, 0, uniData, address(this),
            uint256(block.timestamp).add(100));
        return uint256(amounts[amounts.length - 1]);
    }

    // IBalancerExchange functionId=8
    function IBalancerExchange(address protocol, address token_in, address token_out, uint256 in_amount) public returns(uint256) {
        uint256 out_amount = IBalancerRouter(protocol).smartSwapExactIn(TokenInterface(token_in),
                                                                        TokenInterface(token_out), in_amount, 0, 1);
        return out_amount;
    }

    // Uniswap
    function uniswapTokensForETH(address token, uint256 amount) public returns(uint256) {
        IERC20(token).safeApprove(uniswapAddress, 0);
        IERC20(token).safeApprove(uniswapAddress, amount);
        address[] memory uniData = new address[](2);
        uniData[0] = token;
        uniData[1] = WETHAddress;
        uint[] memory amounts = UniswapV2Router(uniswapAddress).swapExactTokensForETH(amount, 0, uniData, address(this),
                        uint256(block.timestamp).add(100));
        return uint256(amounts[amounts.length - 1]);
    }

    // get
    function getSuperMan() public view returns(address) {
        return superMan;
    }

    function getDydxAddress() public view returns(address) {
        return dydxAddress;
    }

    function getUniswapAddress() public view returns(address) {
        return uniswapAddress;
    }

    function getGasTokenV2Address() public view returns(address) {
        return GasTokenV2;
    }

    function getTokenId(address protocol, address token) public view returns(int128) {
        return tokenId[protocol][token];
    }

    function getFunctionId(address protocol) public view returns(uint256) {
        return functionId[protocol];
    }

    function getTokenBalance(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // set
    function transferOwnership(address new_owner) public onlyOwner {
        superMan = new_owner;
    }

    function setTokenID(address protocol, address token, int128 id) public onlyOwner {
        tokenId[protocol][token] = id;
    }

    function setFunctionId(address protocol, uint256 id) public onlyOwner {
        functionId[protocol] = id;
    }

    function setIfTurnout(bool tof) public onlyOwner {
        if_turnout = tof;
    }

    function setIfGastoken(bool tof) public onlyOwner {
        if_gastoken = tof;
    }

    function setDydxAddress(address new_address) public onlyOwner {
        dydxAddress = new_address;
    }

    function setUniswapAddress(address new_address) public onlyOwner {
        uniswapAddress = new_address;
    }

    function setGasTokenV2Address(address new_address) public onlyOwner {
        GasTokenV2 = new_address;
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(superMan, amount);
    }

    function transferToken(address token, address recipient, uint256 amount) public onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
    }

    function turnOutETH(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
    }

    function transferETH(address recipient, uint256 amount) public onlyOwner {
        address payable addr = recipient.make_payable();
        addr.transfer(amount);
    }

    function WETHToETH(uint256 amount) public onlyOwner {
        WETH9(WETHAddress).withdraw(amount);
    }

    function storeGas(uint256 value) public onlyOwner {
        IGasToken(GasTokenV2).mint(value);
    }

    function freeGas(uint256 value) public onlyOwner {
        IGasToken(GasTokenV2).freeUpTo(value);
    }

    modifier onlyOwner(){
        require(address(msg.sender) == superMan, "No authority");
        _;
    }

    receive() external payable {}
}

// -- interface -- //
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

// Component
interface IComponent {
    function originSwap (
        address _origin,
        address _target,
        uint _originAmount,
        uint _minTargetAmount,
        uint _deadline
    ) external returns(uint);
}

// Curve.finance
interface ICurveFi {
    function exchange(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount) external;
    function exchange_underlying(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount) external;
}

interface IStableSwap {
    function exchange_underlying(int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount) external returns (uint256);
}

// DODO
interface IDODO {
    function sellBaseToken(uint256 amount, uint256 minReceiveQuote, bytes calldata data) external returns (uint256);
}

// BTCswap
interface IBTCswap{
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external returns (uint256);
}

// Balancer
interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}
interface IBalancerRouter {
    function smartSwapExactIn(TokenInterface tokenIn, TokenInterface tokenOut, uint totalAmountIn,
                              uint minTotalAmountOut, uint nPools)   external returns (uint);
}

// Uniswap
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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// dydx solomargin
interface ISoloMargin {
    function getNumMarkets() external returns (uint256);
    function getMarketTokenAddress(uint256 marketId) external returns (address);
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

// WETH
interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// GasToken
interface IGasToken {
    function mint(uint256 value) external;
    function freeUpTo(uint256 value) external returns (uint256);
}

// -- library -- //
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