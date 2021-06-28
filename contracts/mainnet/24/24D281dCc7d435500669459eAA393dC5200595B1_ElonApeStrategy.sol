// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICurveSwap {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external;
}

interface IBalancerSwap {
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);
}

interface ISushiSwap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract ElonApeStrategy is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // 18 decimals
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // 6 decimals
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // 6 decimals
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); // 18 decimals
    IERC20 private constant sUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51); // 18 decimals

    // DeXes
    ICurveSwap private constant _cSwap = ICurveSwap(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    IBalancerSwap private constant _bSwap = IBalancerSwap(0x055dB9AFF4311788264798356bbF3a733AE181c6);
    ISushiSwap private constant _sSwap = ISushiSwap(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    // Farms
    IERC20 private constant sTSLA = IERC20(0x918dA91Ccbc32B7a6A0cc4eCd5987bbab6E31e6D); // 18 decimals
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // 8 decimals
    IERC20 private constant renDOGE = IERC20(0x3832d2F059E55934220881F831bE501D180671A7); // 8 decimals

    // Others
    address public vault;
    uint256[] public weights; // [sTSLA, WBTC, renDOGE]
    uint256 private constant DENOMINATOR = 10000;
    bool public isVesting;

    event AmtToInvest(uint256 _amount); // In USD (6 decimals)
    event CurrentComposition(uint256 _poolSTSLA, uint256 _poolWBTC, uint256 _poolRenDOGE); // in USD (6 decimals)
    event TargetComposition(uint256 _poolSTSLA, uint256 _poolWBTC, uint256 _poolRenDOGE); // in USD (6 decimals)

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    constructor(uint256[] memory _weights) {
        weights = _weights;

        // Curve
        USDT.safeApprove(address(_cSwap), type(uint256).max);
        USDC.safeApprove(address(_cSwap), type(uint256).max);
        DAI.safeApprove(address(_cSwap), type(uint256).max);
        sUSD.safeApprove(address(_cSwap), type(uint256).max);
        // Balancer
        sUSD.safeApprove(address(_bSwap), type(uint256).max);
        sTSLA.safeApprove(address(_bSwap), type(uint256).max);
        // Sushi
        USDT.safeApprove(address(_sSwap), type(uint256).max);
        USDC.safeApprove(address(_sSwap), type(uint256).max);
        DAI.safeApprove(address(_sSwap), type(uint256).max);
        WETH.safeApprove(address(_sSwap), type(uint256).max);
        WBTC.safeApprove(address(_sSwap), type(uint256).max);
        renDOGE.safeApprove(address(_sSwap), type(uint256).max);
    }

    /// @notice Function to set vault address that interact with this contract. This function can only execute once when deployment.
    /// @param _vault Address of vault contract 
    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    /// @notice Function to invest Stablecoins into farms
    /// @param _amountUSDT 6 decimals
    /// @param _amountUSDC 6 decimals
    /// @param _amountDAI 18 decimals
    function invest(uint256 _amountUSDT, uint256 _amountUSDC, uint256 _amountDAI) external onlyVault {
        if (_amountUSDT > 0) {
            USDT.safeTransferFrom(address(vault), address(this), _amountUSDT);
        }
        if (_amountUSDC > 0) {
            USDC.safeTransferFrom(address(vault), address(this), _amountUSDC);
        }
        if (_amountDAI > 0) {
            DAI.safeTransferFrom(address(vault), address(this), _amountDAI);
        }
        uint256 _totalInvestInUSD = _amountUSDT.add(_amountUSDC).add(_amountDAI.div(1e12));
        require(_totalInvestInUSD > 0, "Not enough Stablecoin to invest");
        emit AmtToInvest(_totalInvestInUSD);

        (uint256 _poolSTSLA, uint256 _poolWBTC, uint256 _poolRenDOGE) = getFarmsPool();
        uint256 _totalPool = _poolSTSLA.add(_poolWBTC).add(_poolRenDOGE).add(_totalInvestInUSD);
        // Calculate target composition for each farm
        uint256 _poolSTSLATarget = _totalPool.mul(weights[0]).div(DENOMINATOR);
        uint256 _poolWBTCTarget = _totalPool.mul(weights[1]).div(DENOMINATOR);
        uint256 _poolRenDOGETarget = _totalPool.mul(weights[2]).div(DENOMINATOR);
        emit CurrentComposition(_poolSTSLA, _poolWBTC, _poolRenDOGE);
        emit TargetComposition(_poolSTSLATarget, _poolWBTCTarget, _poolRenDOGETarget);
        // If there is no negative value(need to swap out from farm in order to drive back the composition)
        // We proceed with invest funds into 3 farms and drive composition back to target
        // Else, we invest all the funds into the farm that is furthest from target composition
        if (
            _poolSTSLATarget > _poolSTSLA &&
            _poolWBTCTarget > _poolWBTC &&
            _poolRenDOGETarget > _poolRenDOGE
        ) {
            // Invest Stablecoins into sTSLA
            _investSTSLA(_poolSTSLATarget.sub(_poolSTSLA), _totalInvestInUSD);
            // WETH needed for _investWBTC() and _investRenDOGE() instead of Stablecoins
            // We can execute swap from Stablecoins to WETH in both function,
            // but since swapping is expensive, we swap it once and split WETH to these 2 functions
            uint256 _WETHBalance = _swapAllStablecoinsToWETH();
            // Get the ETH amount of USD to invest for WBTC and renDOGE
            uint256 _investWBTCAmtInUSD = _poolWBTCTarget.sub(_poolWBTC);
            uint256 _investRenDOGEAmtInUSD = _poolRenDOGETarget.sub(_poolRenDOGE);
            uint256 _investWBTCAmtInETH = _WETHBalance.mul(_investWBTCAmtInUSD).div(_investWBTCAmtInUSD.add(_investRenDOGEAmtInUSD));
            // Invest ETH into sTSLA
            _investWBTC(_investWBTCAmtInETH);
            // Invest ETH into renDOGE
            _investRenDOGE(_WETHBalance.sub(_investWBTCAmtInETH));
        } else {
            // Invest all the funds to the farm that is furthest from target composition
            uint256 _furthest;
            uint256 _farmIndex;
            uint256 _diff;
            // 1. Find out the farm that is furthest from target composition
            if (_poolSTSLATarget > _poolSTSLA) {
                _furthest = _poolSTSLATarget.sub(_poolSTSLA);
                _farmIndex = 0;
            }
            if (_poolWBTCTarget > _poolWBTC) {
                _diff = _poolWBTCTarget.sub(_poolWBTC);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 1;
                }
            }
            if (_poolRenDOGETarget > _poolRenDOGE) {
                _diff = _poolRenDOGETarget.sub(_poolRenDOGE);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 2;
                }
            }
            // 2. Put all the yield into the farm that is furthest from target composition
            if (_farmIndex == 0) {
                _investSTSLA(_totalInvestInUSD, _totalInvestInUSD);
            } else {
                uint256 _WETHBalance = _swapAllStablecoinsToWETH();
                if (_farmIndex == 1) {
                    _investWBTC(_WETHBalance);
                } else {
                    _investRenDOGE(_WETHBalance);
                }
            }
        }
    }

    /// @notice Function to swap funds into sTSLA
    /// @param _amount Amount to invest in sTSLA in USD (6 decimals)
    /// @param _totalInvestInUSD Total amount of USD to invest (6 decimals)
    function _investSTSLA(uint256 _amount, uint256 _totalInvestInUSD) private {
        // Swap Stablecoins to sUSD with Curve
        uint256 _USDTBalance = USDT.balanceOf(address(this));
        if (_USDTBalance > 1e6) { // Set minimum swap amount to avoid error
            _cSwap.exchange(2, 3, _USDTBalance.mul(_amount).div(_totalInvestInUSD), 0);
        }
        uint256 _USDCBalance = USDC.balanceOf(address(this));
        if (_USDCBalance > 1e6) {
            _cSwap.exchange(1, 3, _USDCBalance.mul(_amount).div(_totalInvestInUSD), 0);
        }
        uint256 _DAIBalance = DAI.balanceOf(address(this));
        if (_DAIBalance > 1e18) {
            _cSwap.exchange(0, 3, _DAIBalance.mul(_amount).div(_totalInvestInUSD), 0);
        }
        uint256 _sUSDBalance = sUSD.balanceOf(address(this));
        // Swap sUSD to sTSLA with Balancer
        _bSwap.swapExactAmountIn(address(sUSD), _sUSDBalance, address(sTSLA), 0, type(uint256).max);
    }

    /// @notice Function to swap funds into WBTC
    /// @param _amount Amount to invest in ETH
    function _investWBTC(uint256 _amount) private {
        _swapExactTokensForTokens(address(WETH), address(WBTC), _amount);
    }

    /// @notice Function to swap funds into renDOGE
    /// @param _amount Amount to invest in ETH
    function _investRenDOGE(uint256 _amount) private {
        _swapExactTokensForTokens(address(WETH), address(renDOGE), _amount);
    }

    /// @notice Function to swap all available Stablecoins to WETH
    /// @return Balance of received WETH
    function _swapAllStablecoinsToWETH() private returns (uint256) {
        uint256 _USDTBalance = USDT.balanceOf(address(this));
        if (_USDTBalance > 1e6) { // Set minimum swap amount to avoid error
            _swapExactTokensForTokens(address(USDT), address(WETH), _USDTBalance);
        }
        uint256 _USDCBalance = USDC.balanceOf(address(this));
        if (_USDCBalance > 1e6) {
            _swapExactTokensForTokens(address(USDC), address(WETH), _USDCBalance);
        }
        uint256 _DAIBalance = DAI.balanceOf(address(this));
        if (_DAIBalance > 1e18) {
            _swapExactTokensForTokens(address(DAI), address(WETH), _DAIBalance);
        }
        return WETH.balanceOf(address(this));
    }

    /// @notice Function to withdraw Stablecoins from farms if withdraw amount > amount keep in vault
    /// @param _amount Amount to withdraw in USD (6 decimals)
    /// @param _tokenIndex Type of Stablecoin to withdraw
    /// @return Amount of actual withdraw in USD (6 decimals)
    function withdraw(uint256 _amount, uint256 _tokenIndex) external onlyVault returns (uint256) {
        uint256 _totalPool = getTotalPool();
        // Determine type of Stablecoin to withdraw
        (IERC20 _token, int128 _curveIndex) = _determineTokenTypeAndCurveIndex(_tokenIndex);
        uint256 _withdrawAmt;
        if (!isVesting) {
            // Swap sTSLA to Stablecoin
            uint256 _sTSLAAmtToWithdraw = (sTSLA.balanceOf(address(this))).mul(_amount).div(_totalPool);
            _withdrawSTSLA(_sTSLAAmtToWithdraw, _curveIndex);
            // Swap WBTC to WETH
            uint256 _WBTCAmtToWithdraw = (WBTC.balanceOf(address(this))).mul(_amount).div(_totalPool);
            _swapExactTokensForTokens(address(WBTC), address(WETH), _WBTCAmtToWithdraw);
            // Swap renDOGE to WETH
            uint256 _renDOGEAmtToWithdraw = (renDOGE.balanceOf(address(this))).mul(_amount).div(_totalPool);
            _swapExactTokensForTokens(address(renDOGE), address(WETH), _renDOGEAmtToWithdraw);
            // Swap WETH to Stablecoin
            _swapExactTokensForTokens(address(WETH), address(_token), WETH.balanceOf(address(this)));
            _withdrawAmt = _token.balanceOf(address(this));
        } else {
            uint256 _withdrawAmtInETH = (WETH.balanceOf(address(this))).mul(_amount).div(_totalPool);
            // Swap WETH to Stablecoin
            uint256[] memory _amountsOut = _swapExactTokensForTokens(address(WETH), address(_token), _withdrawAmtInETH);
            _withdrawAmt = _amountsOut[1];
        }
        _token.safeTransfer(address(vault), _withdrawAmt);
        if (_token == DAI) { // To make consistency of 6 decimals return
            _withdrawAmt = _withdrawAmt.div(1e12);
        }
        return _withdrawAmt;
    }

    /// @param _amount Amount of sTSLA to withdraw (18 decimals)
    /// @param _curveIndex Index of Stablecoin to swap in Curve
    function _withdrawSTSLA(uint256 _amount, int128 _curveIndex) private {
        (uint256 _amountOut,) = _bSwap.swapExactAmountIn(address(sTSLA), _amount, address(sUSD), 0, type(uint256).max);
        _cSwap.exchange(3, _curveIndex, _amountOut, 0);
    }

    /// @notice Function to release Stablecoin to vault by swapping out farm
    /// @param _tokenIndex Type of Stablecoin to release (0 for USDT, 1 for USDC, 2 for DAI)
    /// @param _farmIndex Type of farm to swap out (0 for sTSLA, 1 for WBTC, 2 for renDOGE)
    /// @param _amount Amount of Stablecoin to release (6 decimals)
    function releaseStablecoinsToVault(uint256 _tokenIndex, uint256 _farmIndex, uint256 _amount) external onlyVault {
        // Determine type of Stablecoin to release
        (IERC20 _token, int128 _curveIndex) = _determineTokenTypeAndCurveIndex(_tokenIndex);
        // Swap out farm token to Stablecoin
        if (_farmIndex == 0) {
            _amount = _amount.mul(1e12);
            _bSwap.swapExactAmountOut(address(sTSLA), type(uint256).max, address(sUSD), _amount, type(uint256).max);
            _cSwap.exchange(3, _curveIndex, _amount, 0);
            _token.safeTransfer(address(vault), _token.balanceOf(address(this)));
        } else {
            if (_token == DAI) { // Follow DAI decimals
                _amount = _amount.mul(1e12);
            }
            // Get amount of WETH from Stablecoin input as amount out swapping from farm
            uint256[] memory _amountsOut = _sSwap.getAmountsOut(_amount, _getPath(address(_token), address(WETH)));
            IERC20 _farm;
            if (_farmIndex == 1) {
                _farm = WBTC;
            } else {
                _farm = renDOGE;
            }
            // Swap farm to exact amount of WETH above
            _sSwap.swapTokensForExactTokens(_amountsOut[1], type(uint256).max, _getPath(address(_farm), address(WETH)), address(this), block.timestamp);
            // Swap WETH to Stablecoin
            _sSwap.swapExactTokensForTokens(_amountsOut[1], 0, _getPath(address(WETH), address(_token)), address(vault), block.timestamp);
        }
    }

    /// @notice Function to withdraw all funds from all farms and swap to WETH
    function emergencyWithdraw() external onlyVault {
        // sTSLA -> sUSD -> USDT -> WETH
        _withdrawSTSLA(sTSLA.balanceOf(address(this)), 2);
        _swapExactTokensForTokens(address(USDT), address(WETH), USDT.balanceOf(address(this)));
        // WBTC -> WETH
        _swapExactTokensForTokens(address(WBTC), address(WETH), WBTC.balanceOf(address(this)));
        // renDOGE -> WETH
        _swapExactTokensForTokens(address(renDOGE), address(WETH), renDOGE.balanceOf(address(this)));

        isVesting = true;
    }

    /// @notice Function to invest WETH into farms
    function reinvest() external onlyVault {
        isVesting = false;
        uint256 _WETHBalance = WETH.balanceOf(address(this));
        // sTSLA (WETH -> USDT -> sUSD -> sTSLA)
        _swapExactTokensForTokens(address(WETH), address(USDT), _WETHBalance.mul(weights[0]).div(DENOMINATOR));
        _investSTSLA(1, 1); // Invest all avalaible Stablecoins
        // WBTC (WETH -> WBTC)
        _investWBTC(_WETHBalance.mul(weights[1]).div(DENOMINATOR));
        // renDOGE (WETH -> renDOGE)
        _investRenDOGE(WETH.balanceOf(address(this)));
    }

    /// @notice Function to approve vault to migrate funds from this contract to new strategy contract
    function approveMigrate() external onlyOwner {
        require(isVesting, "Not in vesting state");
        WETH.safeApprove(address(vault), type(uint256).max);
    }

    /// @notice Function to set weight of farms
    /// @param _weights Array with new weight(percentage) of farms (3 elements, DENOMINATOR = 10000)
    function setWeights(uint256[] memory _weights) external onlyVault {
        weights = _weights;
    }

    /// @notice Function to swap tokens with Sushi
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @param _amountIn Amount of token to be swapped
    /// @return _amounts Array that contains amounts of swapped tokens
    function _swapExactTokensForTokens(address _tokenA, address _tokenB, uint256 _amountIn) private returns (uint256[] memory _amounts) {
        address[] memory _path = _getPath(_tokenA, _tokenB);
        uint256[] memory _amountsOut = _sSwap.getAmountsOut(_amountIn, _path);
        if (_amountsOut[1] > 0) {
            _amounts = _sSwap.swapExactTokensForTokens(_amountIn, 0, _path, address(this), block.timestamp);
        }
    }

    /// @notice Function to get path for Sushi swap functions
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @return Array of addresses
    function _getPath(address _tokenA, address _tokenB) private pure returns (address[] memory) {
        address[] memory _path = new address[](2);
        _path[0] = _tokenA;
        _path[1] = _tokenB;
        return _path;
    }

    /// @notice Function to determine type of Stablecoin and Curve index for Stablecoin
    /// @param _tokenIndex Type of Stablecoin
    /// @return Type of Stablecoin in IERC20 and Curve index for Stablecoin
    function _determineTokenTypeAndCurveIndex(uint256 _tokenIndex) private pure returns (IERC20, int128) {
        IERC20 _token;
        int128 _curveIndex;
        if (_tokenIndex == 0) {
            _token = USDT;
            _curveIndex = 2;
        } else if (_tokenIndex == 1) {
            _token = USDC;
            _curveIndex = 1;
        } else {
            _token = DAI;
            _curveIndex = 0;
        }
        return (_token, _curveIndex);
    }

    /// @notice Function to get current price of ETH
    /// @return Current price of ETH in USD (8 decimals)
    function _getCurrentPriceOfETHInUSD() private view returns (uint256) {
        IChainlink _pricefeed = IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        return uint256(_pricefeed.latestAnswer());
    }

    /// @notice Get total pool (sum of 3 tokens)
    /// @return Total pool in USD (6 decimals)
    function getTotalPool() public view returns (uint256) {
        if (!isVesting) {
            (uint256 _poolSTSLA, uint256 _poolWBTC, uint256 _poolrenDOGE) = getFarmsPool();
            return _poolSTSLA.add(_poolWBTC).add(_poolrenDOGE);
        } else {
            uint256 _price = _getCurrentPriceOfETHInUSD();
            return (WETH.balanceOf(address(this))).mul(_price).div(1e20);
        }
    }

    /// @notice Get current farms pool (current composition)
    /// @return Each farm pool in USD (6 decimals)
    function getFarmsPool() public view returns (uint256, uint256, uint256) {
        uint256 _price = _getCurrentPriceOfETHInUSD();
        // sTSLA
        uint256 _sTSLAPriceInUSD = _bSwap.getSpotPrice(address(sUSD), address(sTSLA)); // 18 decimals
        uint256 _poolSTSLA = (sTSLA.balanceOf(address(this))).mul(_sTSLAPriceInUSD).div(1e30);
        // WBTC
        uint256[] memory _WBTCPriceInETH = _sSwap.getAmountsOut(1e8, _getPath(address(WBTC), address(WETH)));
        uint256 _poolWBTC = (WBTC.balanceOf(address(this))).mul(_WBTCPriceInETH[1].mul(_price)).div(1e28);
        // renDOGE
        uint256[] memory _renDOGEPriceInETH = _sSwap.getAmountsOut(1e8, _getPath(address(renDOGE), address(WETH)));
        uint256 _poolrenDOGE = (renDOGE.balanceOf(address(this))).mul(_renDOGEPriceInETH[1].mul(_price)).div(1e28);

        return (_poolSTSLA, _poolWBTC, _poolrenDOGE);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}