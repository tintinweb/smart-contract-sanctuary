// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ICurveFi.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ILPPool.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/IGauge.sol";
import "../../interfaces/WexPolyMaster.sol";


contract MoneyPrinterStrategy is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public vault;
    address public treasury;
    address public communityWallet;
    address public strategist;
    address _initialVault = 0x3DB93e95c9881BC7D9f2C845ce12e97130Ebf5f2;

    IERC20 public constant DAI = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); 
    IERC20 public constant USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public constant USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    
    IERC20 public constant MATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 public constant CRV = IERC20(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    IERC20 public constant QUICK = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    IERC20 public constant Wexpoly = IERC20(0x4c4BF319237D98a30A929A96112EfFa8DA3510EB);
    IERC20 public constant curveLpToken = IERC20(0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171);

    
    IUniswapV2Router02 public constant WexPolyRouter = IUniswapV2Router02(0x3a1D87f206D12415f5b0A33E786967680AAb4f6d);
    IUniswapV2Router02 public constant quickSwapRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    ILPPool public constant DAIUSDTQuickswapPool = ILPPool(0x97Efe8470727FeE250D7158e6f8F63bb4327c8A2);
    
    IGauge public constant rewardGauge = IGauge(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);
    ICurveFi public constant curveFi = ICurveFi(0x445FE580eF8d70FF569aB36e80c647af338db351);
    
    WexPolyMaster public constant wexStakingContract = WexPolyMaster(0xC8Bd86E5a132Ac0bf10134e270De06A8Ba317BFe);
    IUniswapV2Pair public constant WexUSDT_USDCPair = IUniswapV2Pair(0x7242e19A0937ac33472febD69462668a4cf5bbC5);
    IUniswapV2Pair public constant QuickDAI_USDTPair = IUniswapV2Pair(0x59153f27eeFE07E5eCE4f9304EBBa1DA6F53CA88);
        

    uint private valueInPool;

    uint usdtusdcWexPID = 9;

    mapping(IERC20 => int128) curveIds;

    event Yield(uint wexPolyEarned, uint quickEarned, uint wMaticEarned, uint crvEarned, uint valueInDai);

    constructor(address _treasury, address _communityWallet, address _strategist) {
        curveIds[DAI] = 0;
        curveIds[USDC] = 1;
        curveIds[USDT] = 2;
        
        DAI.approve(address(WexPolyRouter), type(uint).max);
        DAI.approve(address(quickSwapRouter), type(uint).max);
        DAI.approve(address(curveFi), type(uint).max);
        USDC.approve(address(WexPolyRouter), type(uint).max);
        USDC.approve(address(quickSwapRouter), type(uint).max);
        USDC.approve(address(curveFi), type(uint).max);
        USDT.approve(address(WexPolyRouter), type(uint).max);
        USDT.approve(address(quickSwapRouter), type(uint).max);
        USDT.approve(address(curveFi), type(uint).max);
        CRV.approve(address(quickSwapRouter), type(uint).max);
        MATIC.approve(address(quickSwapRouter), type(uint).max);
        QUICK.approve(address(quickSwapRouter), type(uint).max);
        Wexpoly.approve(address(quickSwapRouter), type(uint).max);
        curveLpToken.approve(address(rewardGauge), type(uint).max);
        curveLpToken.approve(address(curveFi), type(uint).max);
        WexUSDT_USDCPair.approve(address(wexStakingContract), type(uint).max);
        WexUSDT_USDCPair.approve(address(WexPolyRouter), type(uint).max);
        QuickDAI_USDTPair.approve(address(DAIUSDTQuickswapPool), type(uint).max);
        QuickDAI_USDTPair.approve(address(quickSwapRouter), type(uint).max);

        treasury= _treasury;
        communityWallet = _communityWallet;
        strategist = _strategist;
    }

    modifier onlyVault {
        require(msg.sender == vault, "Only Vault");
        _;
    }

    function deposit(uint _amount, IERC20 _token) external onlyVault{
        _token.safeTransferFrom(vault, address(this), _amount);
        _deposit(_amount, _token);

    }

    function _deposit(uint _amount, IERC20 _token) internal {
        _swapToDepositTokens(_amount, _token);

        uint daiToDeposit = (DAI.balanceOf(address(this))).div(2); 
        uint usdcToDeposit = (USDC.balanceOf(address(this))).div(2);
        uint usdtToDeposit = (USDT.balanceOf(address(this))).div(3);

        _depositToWexPoly(usdtToDeposit, usdcToDeposit);
        _depositToquickSwap(daiToDeposit, usdtToDeposit);
        _depositToCurve();
        
        
    }   


    function withdraw(uint _amount, IERC20 _token) external onlyVault{
        require(_amount <= getValueInPool(), "Invalid amount");
        (uint usdtFromwSwap, uint usdcFromwSwap) = _withdrawFromWexPoly(_amount);
        (uint daiFromQSwap, uint usdtFromQSwap) = _withdrawFromquickSwap(_amount);
        (uint daiFromCurve, uint usdcFromCurve, uint usdtFromCurve) = _withdrawFromCurve(_amount);

        uint daiBalance =  daiFromQSwap.add(daiFromCurve); 
        uint usdcBalance = usdcFromwSwap.add(usdcFromCurve);
        uint usdtBalance = usdtFromQSwap.add(usdtFromCurve).add(usdtFromwSwap);
    
        {
        uint valueRemoved = daiBalance.add(usdtBalance.mul(1e12)).add(usdcBalance.mul(1e12));
        valueInPool = valueRemoved < valueInPool ? valueInPool.sub(valueRemoved) : 0;
        }
        //convert to _token 

        if(_token != DAI)
        curveFi.exchange_underlying(curveIds[DAI], curveIds[_token], daiBalance, 0);
        if(_token != USDC)
        curveFi.exchange_underlying(curveIds[USDC], curveIds[_token], usdcBalance, 0);
        if(_token != USDT)
        curveFi.exchange_underlying(curveIds[USDT], curveIds[_token], usdtBalance, 0);

        _token.safeTransfer(address(vault), _token.balanceOf(address(this)));
    }

    function harvest() external onlyVault {
        
        uint wexPolyEarned = _harvestFromWexPoly();
        uint quickEarned = _harvestFromQuick();
        (uint wMaticEarned, uint crvEarned) = _harvestFromCurve();

        uint valueInDai = DAI.balanceOf(address(this));
        uint fee = valueInDai.div(10); //10%
        uint feeSplit = fee.mul(2).div(5);
        DAI.safeTransfer(treasury, feeSplit);//4 out of 10% to treasury
        DAI.safeTransfer(communityWallet, feeSplit);//4 out of 10% to communityWallet
        DAI.safeTransfer(strategist, fee.sub(feeSplit).sub(feeSplit));//2 out of 10% to strategist

        _deposit(DAI.balanceOf(address(this)), DAI);

        emit Yield(wexPolyEarned, quickEarned, wMaticEarned, crvEarned, valueInDai);
    }

    function migrateFunds(IERC20 _token)external onlyVault{

        //withdraw from wexPoly
        (uint amountStaked,,) = wexStakingContract.userInfo(usdtusdcWexPID, address(this));
        _harvestFromWexPoly();
        wexStakingContract.withdraw(usdtusdcWexPID, amountStaked, false);
        WexPolyRouter.removeLiquidity(address(USDT), address(USDC), amountStaked, 0, 0, address(this), block.timestamp);

        //withdraw from quickSwap
        uint lpTokenBalanceQSwap = DAIUSDTQuickswapPool.balanceOf(address(this));
        _harvestFromQuick();
        DAIUSDTQuickswapPool.withdraw(lpTokenBalanceQSwap);
        quickSwapRouter.removeLiquidity(address(DAI), address(USDT), lpTokenBalanceQSwap, 0, 0, address(this), block.timestamp);

        //withdraw from curve
        uint lpTokenBalanceCurve = rewardGauge.balanceOf(address(this));
        _harvestFromCurve();
        rewardGauge.withdraw(lpTokenBalanceCurve);
        uint[3] memory minAMmounts; //
        minAMmounts[0] = 0;
        minAMmounts[1] = 0;
        minAMmounts[2] = 0;
        curveFi.remove_liquidity(lpTokenBalanceCurve, minAMmounts, true);


        //swap and withdraw
        if(_token != DAI)
        curveFi.exchange_underlying(curveIds[DAI], curveIds[_token], DAI.balanceOf(address(this)), 0);
        if(_token != USDC)
        curveFi.exchange_underlying(curveIds[USDC], curveIds[_token], USDC.balanceOf(address(this)), 0);
        if(_token != USDT)
        curveFi.exchange_underlying(curveIds[USDT], curveIds[_token], USDT.balanceOf(address(this)), 0);

        //All funds are withdrawn, so vaules are set to 0.
        
        valueInPool = 0;
        _token.safeTransfer(address(vault), _token.balanceOf(address(this)));

    }

    function _withdrawFromWexPoly(uint _amount) internal returns (uint _withdrawnUSDT, uint _withdrawnUSDC){
        (uint amountStaked,,) = wexStakingContract.userInfo(usdtusdcWexPID, address(this));
        
        uint USDCUSDTLpToken = amountStaked.mul(_amount).div(getValueInPool());
        wexStakingContract.withdraw(usdtusdcWexPID, USDCUSDTLpToken, false);

        
        (_withdrawnUSDT, _withdrawnUSDC) = WexPolyRouter.removeLiquidity(address(USDT), address(USDC), USDCUSDTLpToken, 0, 0, address(this), block.timestamp);
        
    }

    function _withdrawFromquickSwap(uint _amount) internal returns(uint _withdrawnDAI, uint _withdrawnUSDT){
        
        uint lpTokenBalance = DAIUSDTQuickswapPool.balanceOf(address(this));
        uint DAIUSDTQuickLpToken = lpTokenBalance.mul(_amount).div(getValueInPool());
        
        
        DAIUSDTQuickswapPool.withdraw(DAIUSDTQuickLpToken);
        (_withdrawnDAI, _withdrawnUSDT) = quickSwapRouter.removeLiquidity(address(DAI), address(USDT), DAIUSDTQuickLpToken, 0, 0, address(this), block.timestamp);
    }

    function _withdrawFromCurve(uint _amount) internal returns (uint _withdrawnDAI, uint _withdrawnUSDC, uint _withdrawnUSDT){
        uint lpTokenBalance = rewardGauge.balanceOf(address(this));
        
        uint lpTokenToWithdraw = lpTokenBalance.mul(_amount).div(getValueInPool());
        


        rewardGauge.withdraw(lpTokenToWithdraw);
        uint[3] memory minAMmounts; 
        minAMmounts[0] = 0;
        minAMmounts[1] = 0;
        minAMmounts[2] = 0;

        uint[3] memory withdrawnAmounts = curveFi.remove_liquidity(lpTokenToWithdraw, minAMmounts, true);

        _withdrawnDAI = withdrawnAmounts[0];
        _withdrawnUSDC = withdrawnAmounts[1];
        _withdrawnUSDT = withdrawnAmounts[2];
    }

    function _harvestFromWexPoly() internal returns (uint WexpolyEarned){
        WexpolyEarned = wexStakingContract.pendingWex(usdtusdcWexPID, address(this));
        
        if(WexpolyEarned > 0 ) {
            wexStakingContract.claim(usdtusdcWexPID);

            address[] memory path = new address[](2);
            path[0] = address(Wexpoly);
            path[1] = address(DAI);

            quickSwapRouter.swapExactTokensForTokens(WexpolyEarned, 0, path, address(this), block.timestamp);
        }        
    }



    function _harvestFromQuick() internal returns(uint quickBalance){

        DAIUSDTQuickswapPool.getReward();

        quickBalance = QUICK.balanceOf(address(this));
        if(quickBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = address(QUICK);
            path[1] = address(DAI);

            quickSwapRouter.swapExactTokensForTokens(quickBalance, 0, path, address(this), block.timestamp);
        }

    }

    function _harvestFromCurve() internal returns (uint maticHarvested, uint crvHarvested){
        rewardGauge.claim_rewards(); 

        address[] memory path = new address[](2);
        path[1] = address(DAI);
        maticHarvested = MATIC.balanceOf(address(this));
        if(maticHarvested > 0) {
            path[0] = address(MATIC);    
            quickSwapRouter.swapExactTokensForTokens(MATIC.balanceOf(address(this)), 0, path, address(this), block.timestamp);
        }

        crvHarvested = CRV.balanceOf(address(this));
        if(crvHarvested > 0) {
            path[0] = address(CRV);
            quickSwapRouter.swapExactTokensForTokens(CRV.balanceOf(address(this)), 0, path, address(this), block.timestamp);
        }
        
    }

    function _swapToDepositTokens(uint _amount, IERC20 _token) internal {
        if(_token == USDT) {
            //convert 27.77% to DAI and 27.77% to USDC
            uint amountToSwap = _amount.mul(2777).div(10000);
            curveFi.exchange_underlying(curveIds[_token], curveIds[DAI], amountToSwap, 0);
            curveFi.exchange_underlying(curveIds[_token], curveIds[USDC], amountToSwap, 0);
        }else  {
            //convert 44.44% to USDT
            //27.77% to DAI || USDC depending on the deposit token
            uint amountToUSDT = _amount.mul(4444).div(10000);

            IERC20 _tokenToGet = _token == DAI ? USDC : DAI; //return USDC if sourceToken is DAI, else return DAI.

            curveFi.exchange_underlying(curveIds[_token], curveIds[USDT], amountToUSDT, 0);
            curveFi.exchange_underlying(curveIds[_token], curveIds[_tokenToGet], _amount.mul(2777).div(10000), 0);
        }
    }

    function _depositToWexPoly(uint _usdtAmount, uint _usdcAmount) internal returns (uint usdt_usdcpoolToken){
        uint usdcAdded; uint usdtAdded;
        (usdcAdded, usdtAdded, usdt_usdcpoolToken) = WexPolyRouter.addLiquidity(address(USDC), address(USDT), _usdcAmount, _usdtAmount, 0, 0, address(this), block.timestamp);

        
    
        wexStakingContract.deposit(usdtusdcWexPID, usdt_usdcpoolToken, false);
        //deposit to wexPoly

        valueInPool = valueInPool.add(usdcAdded.mul(1e12)).add(usdtAdded.mul(1e12));
    }

    function _depositToquickSwap(uint _daiAmount, uint _usdtAmount) internal returns(uint dai_usdtpoolToken){

        uint daiAdded; uint usdtAdded;
        (daiAdded,usdtAdded, dai_usdtpoolToken) = quickSwapRouter.addLiquidity(address(DAI), address(USDT), _daiAmount, _usdtAmount, 0, 0, address(this), block.timestamp);

        
        DAIUSDTQuickswapPool.stake(dai_usdtpoolToken);
        valueInPool = valueInPool.add(daiAdded).add(usdtAdded.mul(1e12));
    }


    function _depositToCurve() internal returns (uint lpTokenAmount){
        
        uint daiBalance = DAI.balanceOf(address(this));
        uint usdcBalance = USDC.balanceOf(address(this));
        uint usdtBalance = USDT.balanceOf(address(this));

        curveFi.add_liquidity([daiBalance, usdcBalance, usdtBalance], 0, true);
        
        //deposit to gauge
        lpTokenAmount = curveLpToken.balanceOf(address(this));
        rewardGauge.deposit(lpTokenAmount);

        valueInPool = valueInPool.add(daiBalance).add(usdcBalance.mul(1e12)).add(usdtBalance.mul(1e12));
    }

    function setVault(address _vault) external{
        require(msg.sender == owner() || msg.sender == _initialVault,"Not owner");
        require(vault == address(0), "Cannot set vault");
        vault = _vault;
    }


    function setTreasuryWallet(address _treasury)external onlyVault{
        treasury = _treasury;
    }

    function setCommunityWallet(address _communityWallet)external onlyVault{
        communityWallet = _communityWallet;
    }

    function setStrategist(address _strategist)external onlyVault{
        strategist = _strategist;
    }

    function getValueInPool() public view returns (uint) {
        return valueInPool; 
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface ICurveFi {

  function get_virtual_price() external view returns (uint256);
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(int128 arg0) external view returns (address);

  function underlying_coins(int128 arg0) external view returns (address);

  function balances(int128 arg0) external view returns (uint256);

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
    //uint256 deadline
  ) external returns (uint256);

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

  function remove_liquidity(
    uint256 _amount,
    uint256 deadline,
    uint256[2] calldata min_amounts
  ) external;

  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 deadline
  ) external;

  function add_liquidity(uint[3] memory _amounts, uint _min_mint_amount, bool _use_underlying) external returns (uint);
  function remove_liquidity(uint _amount, uint[3] memory _min_amounts, bool _use_underlying) external returns (uint[3] memory);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.7.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.7.4;


interface ILPPool {
    //================== Callers ==================//
    //function mir() external view returns (IERC20);
    function balanceOf(address account) external view returns (uint256);

    function startTime() external view returns (uint256);

    function totalReward() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    //================== Transactors ==================//

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getReward() external;
}

interface ILendingPool {
      function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
      function withdraw(address asset, uint256 amount, address to) external returns (uint);
}

interface IGauge {
    function balanceOf(address _address) external view returns (uint256);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claim_rewards() external;
}

interface WexPolyMaster {
    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;
    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;
    function claim(uint256 _pid) external;

    function pendingWex(uint _pid, address _user)external view returns (uint);
    function userInfo(uint pid, address userAddress)external view returns (uint amount, uint rewardDebt, uint pendingRewards);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}