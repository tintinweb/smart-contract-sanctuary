// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}


interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external;
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInBNB() external view returns (uint);
    function depositFee() external view returns (uint);
    function isWhitelisted(address) external view returns (bool);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract DaoSafuStrategyTestnet is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant CAKE  = IERC20Upgradeable(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IERC20Upgradeable public constant WBNB = IERC20Upgradeable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20Upgradeable public constant WETH = IERC20Upgradeable(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IERC20Upgradeable public constant BUSD = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20Upgradeable public constant BTCB = IERC20Upgradeable(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);

    IERC20Upgradeable public constant BTCBWETH = IERC20Upgradeable(0xD171B26E4484402de70e3Ea256bE5A2630d7e88D);
    IERC20Upgradeable public constant BTCBBNB = IERC20Upgradeable(0x61EB789d75A95CAa3fF50ed7E47b96c132fEc082);
    IERC20Upgradeable public constant CAKEBNB = IERC20Upgradeable(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
    IERC20Upgradeable public constant BTCBBUSD = IERC20Upgradeable(0xF45cd219aEF8618A92BAa7aD848364a158a24F33);

    IRouter public constant PnckRouter = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IDaoL1Vault public BTCBWETHVault;
    IDaoL1Vault public BTCBBNBVault;
    IDaoL1Vault public CAKEBNBVault;
    IDaoL1Vault public BTCBBUSDVault;
    

    uint constant BTCBETHTargetPerc = 5000;
    uint constant BTCBBNBTargetPerc = 2000;
    uint constant CAKEBNBTargetPerc = 2000;
    uint constant BTCBBUSDTargetPerc = 1000;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint BTCBETHTargetPool, uint BTCBBNBTargetPool, uint CAKEBNBPool, uint BTCBBUSDTargetPool);
    event CurrentComposition (uint BTCBETHTargetPool, uint BTCBBNBTargetPool, uint CAKEBNBCurrentPool, uint BTCBBUSDCurrentPool);
    event InvestBTCBETH(uint BNBAmt, uint BTCBWETHAmt);
    event InvestBTCBBNB(uint BNBAmt, uint BTCBBNBAmt);
    event InvestCAKEBNB(uint BNBAmt, uint CAKEBNBAmt);
    event InvestBTCBBUSD(uint BNBAmt, uint BTCBBUSDAmt);
    event Withdraw(uint amount, uint BNBAmt);
    event WithdrawBTCBETH(uint lpTokenAmt, uint BNBAmt);
    event WithdrawBTCBBNB(uint lpTokenAmt, uint BNBAmt);
    event WithdrawCAKEBNB(uint lpTokenAmt, uint BNBAmt);
    event WithdrawBTCBBUSD(uint lpTokenAmt, uint BNBAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint BNBAmt);
    event EmergencyWithdraw(uint BNBAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(IDaoL1Vault _BTCBWETHVault, IDaoL1Vault _BTCBBNBVault, IDaoL1Vault _CAKEBNBVault, 
        IDaoL1Vault _BTCBBUSDVault) external initializer {
        __Ownable_init();

        BTCBWETHVault = _BTCBWETHVault;
        BTCBBNBVault = _BTCBBNBVault;
        CAKEBNBVault = _CAKEBNBVault;
        BTCBBUSDVault = _BTCBBUSDVault;

        profitFeePerc = 2000;

/*         CAKE.safeApprove(address(PnckRouter), type(uint).max);
        WBNB.safeApprove(address(PnckRouter), type(uint).max);
        WETH.safeApprove(address(PnckRouter), type(uint).max);
        BUSD.safeApprove(address(PnckRouter), type(uint).max);
        BTCB.safeApprove(address(PnckRouter), type(uint).max);

        BTCBWETH.safeApprove(address(BTCBWETHVault), type(uint).max);
        BTCBBNB.safeApprove(address(BTCBBNBVault), type(uint).max);
        CAKEBNB.safeApprove(address(CAKEBNBVault), type(uint).max);
        BTCBBUSD.safeApprove(address(BTCBBUSDVault), type(uint).max);

        BTCBWETH.safeApprove(address(PnckRouter), type(uint).max);
        BTCBBNB.safeApprove(address(PnckRouter), type(uint).max);
        CAKEBNB.safeApprove(address(PnckRouter), type(uint).max);
        BTCBBUSD.safeApprove(address(PnckRouter), type(uint).max); */

    }

    function invest(uint WBNBAmt) external onlyVault {
        WBNB.safeTransferFrom(vault, address(this), WBNBAmt);
        WBNBAmt = WBNB.balanceOf(address(this));
        
        uint[] memory pools = getEachPool();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + WBNBAmt;
        uint BTCBETHTargetPool = pool * 5000 / 10000; // 50%
        uint BTCBBNBTargetPool = pool * 2000 / 10000; // 20%
        uint CAKEBNBTargetPool = BTCBBNBTargetPool; // 20%
        uint BTCBBUSDTargetPool = pool * 1000 / 10000; // 10%

        // Rebalancing invest
        if (
            BTCBETHTargetPool > pools[0] &&
            BTCBBNBTargetPool > pools[1] &&
            CAKEBNBTargetPool > pools[2] &&
            BTCBBUSDTargetPool > pools[3]
        ) {
            _investBTCBETH(BTCBETHTargetPool - pools[0]);
            _investBTCBBNB((BTCBBNBTargetPool - pools[1]));
            _investCAKEBNB((CAKEBNBTargetPool - pools[2]));
            _investBTCBBUSD((BTCBBUSDTargetPool - pools[3]));
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (BTCBETHTargetPool > pools[0]) {
                diff = BTCBETHTargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (BTCBBNBTargetPool > pools[1]) {
                diff = BTCBBNBTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (CAKEBNBTargetPool > pools[2]) {
                diff = CAKEBNBTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (BTCBBUSDTargetPool > pools[3]) {
                diff = BTCBBUSDTargetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }

            if (farmIndex == 0) _investBTCBETH(WBNBAmt);
            else if (farmIndex == 1) _investBTCBBNB(WBNBAmt);
            else if (farmIndex == 2) _investCAKEBNB(WBNBAmt);
            else _investBTCBBUSD(WBNBAmt);
        }

        emit TargetComposition(BTCBETHTargetPool, BTCBBNBTargetPool, CAKEBNBTargetPool, BTCBBUSDTargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3]);
    }


    function _investBTCBETH(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt/2;

        _swap(address(WBNB), address(WETH), _amt, 0);
        _swap(address(WBNB), address(BTCB), _amt, 0);

        uint _wethAmt = WETH.balanceOf(address(this));
        uint _BTCBAmt = BTCB.balanceOf(address(this));
        
        uint lpTokens = _addLiquidity(address(WETH), address(BTCB), _wethAmt, _BTCBAmt);

        BTCBWETHVault.deposit(lpTokens);

        emit InvestBTCBETH(_wbnbAmt, lpTokens);
    }

    function _investBTCBBNB(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;
        _swap(address(WBNB), address(BTCB), _amt, 0);

        uint _BTCBAmt = BTCB.balanceOf(address(this));
        uint lpTokens = _addLiquidity(address(WBNB), address(BTCB), _amt, _BTCBAmt);

        BTCBBNBVault.deposit(lpTokens);

        emit InvestBTCBBNB(_wbnbAmt, lpTokens);
    }

    function _investCAKEBNB(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;
        _swap(address(WBNB), address(CAKE), _amt, 0);

        uint _CAKEAmt = CAKE.balanceOf(address(this));
        uint lpTokens = _addLiquidity(address(WBNB), address(CAKE), _amt, _CAKEAmt);

        CAKEBNBVault.deposit(lpTokens);

        emit InvestCAKEBNB(_wbnbAmt, lpTokens);
    }

    function _investBTCBBUSD(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;

        _swap(address(WBNB), address(BTCB), _amt, 0);
        _swap(address(WBNB), address(BUSD), _amt, 0);

        uint _BTCBAmt = BTCB.balanceOf(address(this));
        uint _BUSDAmt = BUSD.balanceOf(address(this));

        uint lpTokens = _addLiquidity(address(BTCB), address(BUSD), _BTCBAmt, _BUSDAmt);

        BTCBBUSDVault.deposit(lpTokens);

        emit InvestBTCBBUSD(_wbnbAmt, lpTokens);
    }

    function withdraw(uint amount, uint[] calldata tokenPrice) external onlyVault returns (uint WBNBAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        
        uint WBNBAmtBefore = WBNB.balanceOf(address(this));
        _withdrawBTCBETH(sharePerc, tokenPrice[0], tokenPrice[1]); //(, btcPriceInBNB, ETHPriceInBNB)
        _withdrawBTCBBNB(sharePerc, tokenPrice[0]); //(, btcPriceInBNB)
        _withdrawCAKEBNB(sharePerc, tokenPrice[2]); //(, cakePriceInBNB)
        _withdrawBTCBBUSD(sharePerc, tokenPrice[0], tokenPrice[3]); //(,btcPriceInBNB, busdPriceInBNB)
        WBNBAmt = WBNB.balanceOf(address(this)) - WBNBAmtBefore;
        WBNB.safeTransfer(vault, WBNBAmt);

        emit Withdraw(amount, WBNBAmt);
    }

    
    function _withdrawBTCBETH(uint _sharePerc, uint btcPriceInBnb, uint ethPriceInBNB) private {
        BTCBWETHVault.withdraw(BTCBWETHVault.balanceOf(address(this)) * _sharePerc / 1e18 );
    
        uint _amt = BTCBWETH.balanceOf(address(this));

        (uint _amtBTCB, uint _amtWETH) = _removeLiquidity(address(BTCB), address(WETH), _amt);

        uint minBNB = _amtBTCB * btcPriceInBnb / 1e18;
        uint _wBNBAmt = _swap(address(BTCB), address(WBNB), _amtBTCB, minBNB);

        minBNB = _amtWETH * ethPriceInBNB / 1e18;
        _wBNBAmt += _swap(address(WETH), address(WBNB), _amtWETH, minBNB);

        emit WithdrawBTCBETH(_amt, _wBNBAmt);
    }


    function _withdrawBTCBBNB(uint _sharePerc, uint btcPriceInBnb) private {
        BTCBBNBVault.withdraw(BTCBBNBVault.balanceOf(address(this)) * _sharePerc / 1e18 );
        uint _amt = BTCBBNB.balanceOf(address(this));

        (uint _amtBTCB, uint _amtBNB) = _removeLiquidity(address(BTCB), address(WBNB), _amt);

        uint minAmount = _amtBTCB * btcPriceInBnb / 1e18;
        _amtBNB += _swap(address(BTCB), address(WBNB), _amtBTCB, minAmount);

        emit WithdrawBTCBBNB(_amt, _amtBNB);
    }

    function _withdrawCAKEBNB(uint _sharePerc, uint cakePriceInBNB) private {
        CAKEBNBVault.withdraw(CAKEBNBVault.balanceOf(address(this)) * _sharePerc / 1e18 );
        uint _amt = CAKEBNB.balanceOf(address(this));
        (uint _amtCake, uint _amtBNB) = _removeLiquidity(address(CAKE), address(WBNB), _amt);

        uint minAmount = _amtCake * cakePriceInBNB / 1e18;
        _amtBNB += _swap(address(CAKE), address(WBNB), _amtCake, minAmount);

        emit WithdrawCAKEBNB(_amt, _amtBNB);
    }

    // function _withdrawBTCBBUSD(uint _amount, uint _allPool) private {
    function _withdrawBTCBBUSD(uint _sharePerc, uint btcPriceInBNB, uint busdPriceInBNB) private {
        BTCBBUSDVault.withdraw(BTCBBUSDVault.balanceOf(address(this)) * _sharePerc / 1e18);
        uint _amt = BTCBBUSD.balanceOf(address(this));

        (uint _amtBTCB, uint _amtBUSD) = _removeLiquidity(address(BTCB), address(BUSD), _amt);

        uint minAmount = _amtBTCB * btcPriceInBNB /1e18;
        uint _wBNBAmt = _swap(address(BTCB), address(WBNB), _amtBTCB, minAmount);

        minAmount = _amtBUSD * busdPriceInBNB / 1e18;
        _wBNBAmt += _swap(address(BUSD), address(WBNB), _amtBUSD, minAmount);

        emit WithdrawBTCBBUSD(_amt, _wBNBAmt);
    }

    function collectProfitAndUpdateWatermark() external onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD();
        
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
            watermark = currentWatermark - fee;
        }
        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) external onlyVault {
        
        uint lastWatermark = watermark;
        watermark = signs == true ? watermark + amount : watermark - amount;
        emit AdjustWatermark(watermark, lastWatermark);
    }

    function _swap(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](2);

        path[0] = _tokenA;
        path[1] = _tokenB;


        return (PnckRouter.swapExactTokensForTokens(_amt , _minAmount, path, address(this), block.timestamp))[1];
    }

    function _addLiquidity(address _tokenA, address _tokenB, uint _amtA, uint _amtB) private returns (uint liquidity) {
        (,,liquidity) = PnckRouter.addLiquidity(_tokenA, _tokenB, _amtA, _amtB, 0, 0, address(this), block.timestamp);
    }

    function _removeLiquidity(address _tokenA, address _tokenB, uint _amt) private returns (uint _amtA, uint _amtB) {
        (_amtA, _amtB) = PnckRouter.removeLiquidity(_tokenA, _tokenB, _amt, 0, 0, address(this), block.timestamp);
    }

    /// @param amount Amount to reimburse to vault contract in ETH
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint WBNBAmt) {
        if (farmIndex == 0) _withdrawBTCBETH(amount * 1e18 / getBTCBETHPool(), 0, 0); 
        else if (farmIndex == 1) _withdrawBTCBBNB(amount * 1e18 / getBTCBBNBPool(), 0);
        else if (farmIndex == 2) _withdrawCAKEBNB(amount * 1e18 / getCAKEBNBPool(), 0);
        else if (farmIndex == 3) _withdrawBTCBBUSD(amount * 1e18 / getBTCBBUSDPool(), 0, 0);
        WBNBAmt = WBNB.balanceOf(address(this));
        WBNB.safeTransfer(vault, WBNBAmt);
        emit Reimburse(WBNBAmt);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        _withdrawBTCBETH(1e18, 0, 0); 
        _withdrawBTCBBNB(1e18, 0);
        _withdrawCAKEBNB(1e18, 0);
        _withdrawBTCBBUSD(1e18, 0, 0);
        uint WBNBAmt = WBNB.balanceOf(address(this));
        WBNB.safeTransfer(vault, WBNBAmt);
        watermark = 0;
        emit EmergencyWithdraw(WBNBAmt);
    }

    function getBTCBETHPool() private view  returns (uint) {
        return BTCBWETHVault.getAllPoolInBNB();
    }

    function getBTCBBNBPool() private view returns (uint) {
        return BTCBBNBVault.getAllPoolInBNB();
    }

    function getCAKEBNBPool() private view returns (uint) {
        return CAKEBNBVault.getAllPoolInBNB();
    }

    function getBTCBBUSDPool() private view returns (uint) {
        return BTCBBUSDVault.getAllPoolInBNB();
    }

    function getEachPool() private view returns (uint[] memory pools) {
        pools = new uint[](4);
        pools[0] = getBTCBETHPool();
        pools[1] = getBTCBBNBPool();
        pools[2] = getCAKEBNBPool();
        pools[3] = getBTCBBUSDPool();
    }

    function getAllPool() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2] + pools[3];
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint BNBPriceInUSD = uint(IChainlink(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526).latestAnswer()); // 8 decimals
        require(BNBPriceInUSD > 0, "ChainLink error");
        return getAllPool() * BNBPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool();
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3];
        percentages = new uint[](4);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

