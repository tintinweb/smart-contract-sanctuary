/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

//address:0xdbc5bec5a22714532ad52305bfeb20787f4b2fab
pragma solidity >=0.5.0 <0.8.0;
//SPDX-License-Identifier: MIT
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
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
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
}
interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
interface IReciever {
    function executeOperation(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums, address initiator, bytes calldata params) external returns (bool);
}
interface ICtoken {
    // mint underlying token amount, e.g. ETH
    function mint(uint256 mintAmount) external returns (uint256);
    // redeem Ctoken amount, e.g. LETH
    function redeem(uint256 redeemTokens) external returns (uint256);
    // borrow underlying token amount, e.g. ETH
    function borrow(uint256 borrowAmount) external returns (uint256);
    //repay the underlying token amount, e.g. ETH
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    //call other function after this
    function accrueInterest() external returns (uint256);
    function borrowBalanceStored(address account) external view returns (uint256);
    function exchangeRateStored() external view returns(uint256);
    function getCash() external view returns(uint256);
}
interface ICBNB {
    function repayBorrow() external payable;
}
interface IController {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    function claimCan(address holder) external;
    function getHypotheticalAccountLiquidity(address, address, uint256, uint256) external view returns(uint256, uint256, uint256);
}
interface IOracle {
    function getUnderlyingPrice(address ctoken) external view returns (uint256);
}
interface IPancakeFactory {
    function pairFor(address, address) external view returns (address);
}
interface ILPToken {
    function getReserves() external view returns(uint112, uint112, uint32);
}
contract myChannels {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public admin;
    address public oracle;
    address public controller;
    address public CAN;
    address public pancakeRouter;
    address public pancakeFactory;
    mapping(address => address) public token2ctoken;
    mapping(address => address) public bridge;
    mapping(address => mapping(address => uint256)) public shares;
    mapping(address => uint256) public totalShares;
    mapping(address => bool) public inMarket;
    mapping(address => uint256) public remaining_CAN;
    address[] public path2 = new address[](2);
    address[] public path3 = new address[](3);

    mapping(address => bool) public whiteList;
    bool public opened;

    address public WBNB;
    bool public canDepositReward;
    modifier onlyAdmin {
        require(msg.sender == admin, "not admin");
        _;
    }
    constructor () {
        admin = msg.sender;
        oracle = 0x59b17DD4B570d91eBdE62526A08933E0158c25B8;
        controller = 0x8Cd2449Ed0469D90a7C4321DF585e7913dd6E715;
        CAN = 0xdE9a73272BC2F28189CE3c243e36FaFDA2485212;
        pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        pancakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        path2[0] = CAN;
        path3[0] = CAN;
        opened = false;
        WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }
    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }
    function setDepositReward(uint256 p) external onlyAdmin {
        if (p == 0) canDepositReward = false; else canDepositReward = true;
    }
    function addToken(address token, address ctoken, address bridge_) external onlyAdmin {
        token2ctoken[token] = ctoken;
        bridge[token] = bridge_;
        address[] memory ctokens = new address[](1);
        ctokens[0] = ctoken;
        IController(controller).enterMarkets(ctokens);
        inMarket[token] = true;
    }
    function changeBridge(address token, address bridge_) external onlyAdmin {
        require(inMarket[token] == true, "invalid changing of bridge");
        bridge[token] = bridge_;
    }
    function AmountInChannels(address token, uint256 amount) public view returns (uint256) {
        address ctoken = token2ctoken[token];
        return amount.mul(ICtoken(ctoken).exchangeRateStored()) / 1e18;
    }

    function smallTokens(address tokenA, address tokenB) public pure returns (address) {
        if (tokenA < tokenB) return tokenA; else return tokenB;
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint256, uint256) {
        address _token0 = smallTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = ILPToken(
            IPancakeFactory(pancakeFactory).pairFor(tokenA, tokenB)
        ).getReserves();
        if (_token0 == tokenA) return (reserve0, reserve1); else return (reserve1, reserve0);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint256 ) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) return 0;
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        return numerator / denominator;
    }

    function canExchange(uint amountIn, address[] memory path) public view returns (bool) {
        if (path.length < 2) return false;
        uint[] memory amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            if (amounts[i + 1] == 0) return false;
        }
        return true;
    }
    function depositReward(address token) public {
        if (canDepositReward == false) return;
        uint256 rewards = IERC20(CAN).balanceOf(address(this));
        address ctoken = token2ctoken[token];
        IController(controller).claimCan(address(this));
        rewards = (IERC20(CAN).balanceOf(address(this))).sub(rewards);
        rewards = rewards.add(remaining_CAN[token]);
        uint256 outcome = 0;
        if (bridge[token] == token) {
            path2[1] = token;
            if (canExchange(rewards, path2)) {
				IERC20(CAN).safeIncreaseAllowance(pancakeRouter, rewards);
                outcome = IPancakeRouter(pancakeRouter).swapExactTokensForTokens(rewards, 0, path2, address(this), block.timestamp)[1];
            }
        } else {
            path3[1] = bridge[token];
            path3[2] = token;
            if (canExchange(rewards, path3)) {
				IERC20(CAN).safeIncreaseAllowance(pancakeRouter, rewards);
                outcome = IPancakeRouter(pancakeRouter).swapExactTokensForTokens(rewards, 0, path3, address(this), block.timestamp)[2];
            }
        }
        if (outcome > 0) {
            IERC20(token).safeIncreaseAllowance(ctoken, outcome);
            ICtoken(ctoken).mint(outcome);
			remaining_CAN[token] = 0;
        } else {
			remaining_CAN[token] = rewards;
		}
    }
    function deposit(address token, uint256 amount) external {
        require(inMarket[token] && token != WBNB, "unsupported token");
        require(totalShares[token] > 0 || amount >= 1e8, "invalid amount");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        address ctoken = token2ctoken[token];
        ICtoken(ctoken).accrueInterest();
        depositReward(token);
        if (totalShares[token] == 0) {
            totalShares[token] = 1e18;
            shares[token][msg.sender] = 1e18;
        } else {
            
            uint256 _before = AmountInChannels(token, IERC20(ctoken).balanceOf(address(this)));
            uint256 share = amount.mul(totalShares[token]) / _before;
            shares[token][msg.sender] = shares[token][msg.sender].add(share);
            totalShares[token] = totalShares[token].add(share);
        }
        IERC20(token).safeIncreaseAllowance(ctoken, amount);
        ICtoken(ctoken).mint(amount);
    }
    function withdraw(address token, uint256 share) external {
        require(share <= shares[token][msg.sender], "invalid share");
        depositReward(token);
        uint256 amount = share.mul(IERC20(token2ctoken[token]).balanceOf(address(this))) / totalShares[token];
        uint256 _before = IERC20(token).balanceOf(address(this));
        ICtoken(token2ctoken[token]).redeem(amount);
        uint256 _after = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, _after.sub(_before));
        shares[token][msg.sender] = shares[token][msg.sender] - share;
        totalShares[token] = totalShares[token].sub(share);
    }
    function _calcMaxCashBorrowed(uint256 amountA, uint256 amountB, uint256 cashA, uint256 cashB) internal pure returns (uint256, uint256) {
        if (amountA <= cashA && amountB <= cashB) return (amountA, amountB);
        if (amountA.mul(cashB) > amountB.mul(cashA)) {
            return (cashA, amountB.mul(cashA) / amountA);
        } else {
            return (amountA.mul(cashB) / amountB, cashB);
        }
    }
    function maxLoanAmount(address tokenA, uint256 amountA, address tokenB, uint256 amountB) public view returns(uint256, uint256) {
        address ctokenA = token2ctoken[tokenA];
        address ctokenB = token2ctoken[tokenB];
        (uint256 amount0, uint256 amount1) = _calcMaxCashBorrowed(
            amountA, amountB, ICtoken(ctokenA).getCash(), ICtoken(ctokenB).getCash()
        );
        (, uint256 liquidity, ) = IController(controller).getHypotheticalAccountLiquidity(address(this), address(this), 0, 0);
        liquidity = liquidity.mul(1e18);
        liquidity = liquidity.mul(9) / 10;
        uint256 totalBorrowed = (amount0.mul(IOracle(oracle).getUnderlyingPrice(ctokenA))).add(
            amount1.mul(IOracle(oracle).getUnderlyingPrice(ctokenB))
        );
        if (totalBorrowed <= liquidity) return (amount0, amount1); 
        else return (amount0.mul(liquidity) / totalBorrowed, amount1.mul(liquidity) / totalBorrowed);
    }

    function setWhiteList(address user, uint256 p) external onlyAdmin {
        if (p > 0) whiteList[user] = true; else whiteList[user] = false;
    }
    function setOpened(uint256 p) external onlyAdmin {
        if (p == 0) opened = false; else opened = true;
    }
    function flashLoan(address receiverAddress, address[] calldata assets, uint256[] calldata amounts, uint256[] calldata modes, address onBehalfOf, bytes calldata params, uint16 referralCode) external {
        require(opened || whiteList[receiverAddress], "not in whiteList");
        uint256 _WBNB = address(this).balance;
        {
            uint256[] memory premiums = new uint256[](assets.length);
            for (uint256 i = 0; i < assets.length; ++ i) {
                premiums[i] = 0;
                ICtoken(token2ctoken[assets[i]]).accrueInterest();
            }
            
            for (uint256 i = 0 ; i < assets.length; ++ i) {
                ICtoken(token2ctoken[assets[i]]).borrow(amounts[i]);
                if (assets[i] == WBNB) payable(receiverAddress).call{value: amounts[i]}("");
                else IERC20(assets[i]).safeTransfer(receiverAddress, amounts[i]);
            }
            require(IReciever(receiverAddress).executeOperation(assets, amounts, premiums, msg.sender, params), "unsuccessful operation");
        }
        for (uint256 i = 0 ; i < assets.length; ++ i) {
            if (assets[i] != WBNB) {
                IERC20(assets[i]).safeTransferFrom(receiverAddress, address(this), amounts[i]);
			    IERC20(assets[i]).safeIncreaseAllowance(token2ctoken[assets[i]], amounts[i]);
                ICtoken(token2ctoken[assets[i]]).repayBorrow(amounts[i]);
            } else {
                require(address(this).balance >= _WBNB, "no repay BNB");
                ICBNB(token2ctoken[assets[i]]).repayBorrow{value: amounts[i]}();
            }
        }
    }
    receive() external payable {
    }
}