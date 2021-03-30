// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IDextokenPool.sol";
import "./IDextokenFactory.sol";
import "./LPToken.sol";


contract DextokenPool is LPToken, IDextokenPool, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /// AMM fee
    uint public constant FEE_BASE      = 10**4; // 0.01%
    uint public constant FEE_FACTOR    = 30;

    IDextokenFactory public factory;

    /// The collateral token
    IERC20 public WETH;

    /// Pooling
    uint public totalLiquidity;
    IERC20 public token0;

    /// Speculative AMM
    struct AMM {
        uint Ct;
        uint Pt;
        uint Nt;
        uint lastUpdateTime;
    }

    /// AMM states
    AMM private _AMM;

    modifier updatePriceTick() {    
        _;
        /// step the price tick (t+1)
        _AMM.lastUpdateTime = _lastPriceTickApplicable();      
    }

    constructor() public {
        factory = IDextokenFactory(msg.sender);
        _AMM.lastUpdateTime = 0;
        totalLiquidity = 0;
    }

    function initialize(address _token0, address _token1, uint _Ct, uint _Pt) 
        external 
    {
        require(msg.sender == address(factory), 'initialize: Forbidden');

        token0 = IERC20(_token0); 
        require(_Ct <= token0.totalSupply(), "initialize: Invalid _Ct");     
        
        /// snapshot of the pooled token
        _AMM.Ct = _Ct;
        _AMM.Pt = _Pt;
        _AMM.Nt = _AMM.Pt.mul(_AMM.Ct).div(1e18);

        /// The collateral token
        WETH = IERC20(_token1);        
    }

    function deposit(uint amount) 
        external 
        nonReentrant
        updatePriceTick()
    {
        require(amount > 0, "deposit: invalid amount");
        uint _totalBalance = getPoolBalance();
        address _token0 = address(token0);
        uint _Ct = _AMM.Ct.add(amount);
        uint _Nt = _AMM.Nt;

        // liquidity at price tick (t)
        uint spotPrice = getSpotPrice(_Ct, _Nt);
        uint liquidity = spotPrice.mul(amount);
        require(liquidity > 0, "deposit: invalid user liquidity");

        _totalBalance = _totalBalance.add(amount);
        uint _totalLiquidity = totalLiquidity.add(liquidity);

        // mint liquidity tokens
        uint mintedTokens = _calcLiquidityToken(_totalLiquidity, _totalBalance, liquidity);

        /// calculate the virtual collateral tokens at price tick (t)
        uint _Mb = WETH.balanceOf(address(this)).mul(mintedTokens).div(totalSupply().add(mintedTokens));

        // move price tick to (t+1) 
        _AMM.Ct = _Ct;
        _AMM.Nt = _Nt.add(_Mb);
        totalLiquidity = _totalLiquidity;

        // mint liquidity token at price tick (t+1)
        _mintLiquidityToken(msg.sender, mintedTokens);
        _tokenSafeTransferFrom(_token0, msg.sender, address(this), amount);
        emit TokenDeposit(_token0, msg.sender, amount, spotPrice);        
    }

    function withdraw(uint tokens) 
        external 
        nonReentrant
        updatePriceTick()
    {
        require(tokens > 0, "withdraw: invalid tokens");
        require(totalSupply() > 0, "withdraw: insufficient liquidity");
        require(balanceOf(msg.sender) >= tokens, "withdraw: insufficient tokens");
        address _token0 = address(token0);
      
        // liquidity at price tick (t)
        uint amount = liquidityTokenToAmount(tokens);

        /// calculate the collateral token shares
        uint balance = WETH.balanceOf(address(this));
        uint amountOut = balance.mul(tokens).div(totalSupply());

        /// Ensure the amountOut is not more than the balance in the contract.
        /// Preventing underflow due to very low values of the balance.        
        require(amountOut <= balance, "withdraw: insufficient ETH balance");

        // prepare for price tick (t+1)
        uint _Ct = _AMM.Ct;
        uint _Nt = _AMM.Nt;
        _Ct = _Ct.sub(amount);
        _Nt = _Nt.sub(amountOut);

        // liquidity at price tick (t+1)        
        uint spotPrice = getSpotPrice(_Ct, _Nt);
        totalLiquidity = spotPrice.mul(getPoolBalance().sub(amount));

        _AMM.Ct = _Ct;
        _AMM.Nt = _Nt;

        _tokenSafeTransfer(_token0, msg.sender, amount);
        _tokenSafeTransfer(address(WETH), msg.sender, amountOut);

        _burnLiquidityToken(msg.sender, tokens);
        emit TokenWithdraw(_token0, msg.sender, amount, spotPrice);
    }

    function swapExactETHForTokens(
        uint amountIn,
        uint minAmountOut,
        uint maxPrice,
        uint deadline
    )
        external 
        nonReentrant
        returns (uint)
    {
        require(WETH.balanceOf(msg.sender) >= amountIn, "swapExactETHForTokens: Insufficient ETH balance");
        require(deadline > _lastPriceTickApplicable(), "swapExactETHForTokens: Invalid transaction");
        require(amountIn > 0, "swapExactETHForTokens: Invalid amountIn");
        uint spotPrice;
        IERC20 _WETH = WETH;

        /// the price tick at (t)
        /// increase the collateral token supply including interests rate        
        {
            spotPrice = getSpotPrice(_AMM.Ct, _AMM.Nt.add(amountIn));
            require(spotPrice <= maxPrice, "swapExactETHForTokens: Invalid price slippage");
        }

        /// check amount out without fees
        uint amountOut = amountIn.mul(1e18).div(spotPrice);
        require(amountOut >= minAmountOut, "swapExactETHForTokens: Invalid amountOut");

        /// split fees and check exact amount out
        uint feeAmountIn = _calcFees(amountIn);
        uint exactAmountIn = amountIn.sub(feeAmountIn);
        uint exactAmountOut = exactAmountIn.mul(1e18).div(spotPrice);

        /// increase the collateral token supply
        _AMM.Nt = _AMM.Nt.add(exactAmountIn);
        spotPrice = getSpotPrice(_AMM.Ct.sub(exactAmountOut), _AMM.Nt);
        totalLiquidity = spotPrice.mul(getPoolBalance().sub(exactAmountOut));

        /// transfer the collateral tokens in
        _tokenSafeTransferFrom(address(_WETH), msg.sender, address(this), amountIn);
        
        /// transfer fees
        _tokenSafeTransfer(address(_WETH), factory.getFeePool(), feeAmountIn);

        /// move to the next price tick (t+1)
        _withdrawAndTransfer(msg.sender, exactAmountOut);

        emit SwapExactETHForTokens(address(this), exactAmountOut, amountIn, spotPrice, msg.sender);
        return exactAmountOut;
    } 

    function swapExactTokensForETH(
        uint amountIn,
        uint minAmountOut,
        uint minPrice,
        uint deadline
    )
        external 
        nonReentrant
        returns (uint)
    {
        require(token0.balanceOf(msg.sender) >= amountIn, "swapExactTokensForETH: Insufficient user balance");    
        require(deadline > _lastPriceTickApplicable(), "swapExactTokensForETH: Invalid order");
        require(amountIn > 0, "swapExactTokensForETH: Invalid amountIn");
        uint _Nt = _AMM.Nt;
        IERC20 _WETH = WETH;

        /// add liquidity at the price tick (t)
        uint spotPrice = getSpotPrice(_AMM.Ct.add(amountIn), _Nt);
        require(spotPrice >= minPrice, "swapExactTokensForETH: Invalid price slippage");

        /// user receives
        uint amountOut = spotPrice.mul(amountIn).div(1e18);
        require(_WETH.balanceOf(address(this)) >= amountOut, "swapExactTokensForETH: Insufficient ETH liquidity");
        require(amountOut >= minAmountOut, "swapExactTokensForETH: Invalid amountOut");

        /// split fees
        uint feeAmountOut = _calcFees(amountOut);
        uint exactAmountOut = amountOut.sub(feeAmountOut);

        /// decrease the collateral token, and add liquidity 
        /// providers' fee shares back to the pool
        _AMM.Nt = _Nt.sub(exactAmountOut);

        totalLiquidity = spotPrice.mul(getPoolBalance().add(amountIn));

        /// move the next price tick (t+1)
        _depositAndTransfer(msg.sender, amountIn);

        /// transfer the collateral token out
        _tokenSafeTransfer(address(_WETH), msg.sender, exactAmountOut);

        emit SwapExactTokensForETH(address(this), exactAmountOut, amountIn, spotPrice, msg.sender);
        return exactAmountOut;
    }

    function getLastUpdateTime() external view returns (uint) {
        return _AMM.lastUpdateTime;
    }  

    function getCirculatingSupply() external view returns (uint) {
        return _AMM.Ct;
    }    

    function getUserbase() external view returns (uint) {
        return _AMM.Nt;
    }

    function getToken() external view returns (address) {
        return address(token0);
    }

    function getTotalLiquidity() external view returns (uint) {
        return totalLiquidity.div(1e18);
    }  

    function liquidityOf(address account) external view returns (uint) {
        return balanceOf(account);
    }

    function liquiditySharesOf(address account) external view returns (uint) {
        uint userTokens = balanceOf(account);
        if (userTokens == 0) {
            return 0;
        }
        return totalSupply()
            .mul(1e18)
            .div(userTokens);
    }  

    function mean() public view returns (uint) {
        return _AMM.Nt
            .mul(_AMM.Pt);
    }

    function getPoolBalance() public view returns (uint) {
        return token0.balanceOf(address(this));
    }

    function getPrice() public view returns (uint) {
        return _AMM.Nt.mul(1e18).div(_AMM.Ct);
    }   

    function getSpotPrice(uint _Ct, uint _Nt) public pure returns (uint) {
        return _Nt.mul(1e18).div(_Ct);
    }

    function liquidityTokenToAmount(uint token) public view returns (uint) {
        if (totalSupply() == 0) {
            return 0;
        }        
        return getPoolBalance()
            .mul(token)
            .div(totalSupply());
    }  

    function liquidityFromAmount(uint amount) public view returns (uint) {
        return getPrice().mul(amount); 
    }

    function _depositAndTransfer(address account, uint amount) 
        internal
        updatePriceTick()
    {
        _AMM.Ct = _AMM.Ct.add(amount);    
        _tokenSafeTransferFrom(address(token0), account, address(this), amount);
    }

    function _withdrawAndTransfer(address account, uint amount) 
        internal
        updatePriceTick()
    {
        _AMM.Ct = _AMM.Ct.sub(amount);    
        _tokenSafeTransfer(address(token0), account, amount);
    }
    
    function _lastPriceTickApplicable() internal view returns (uint) {
        return Math.max(block.timestamp, _AMM.lastUpdateTime);
    }

    function _mintLiquidityToken(address to, uint amount) internal {
        _mint(address(this), amount);
        _transfer(address(this), to, amount);
    }

    function _burnLiquidityToken(address from, uint amount) internal {
        _transfer(from, address(this), amount);
        _burn(address(this), amount);
    } 

    function _calcFees(uint amount) internal pure returns (uint) {
        return amount.mul(FEE_FACTOR).div(FEE_BASE);
    }

    function _calcLiquidityToken(
        uint _totalLiquidity, 
        uint _totalBalance, 
        uint _liquidity
    ) 
        internal 
        pure 
        returns (uint) 
    {
        if (_totalLiquidity == 0) {
            return 0;
        }    
        return _totalBalance
            .mul(_liquidity)
            .div(_totalLiquidity);
    }

    function _tokenSafeTransfer(
        address token,
        address to,
        uint amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "_tokenSafeTransfer failed");
    }

    function _tokenSafeTransferFrom(
        address token,
        address from,
        address to,
        uint amount
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "_tokenSafeTransferFrom failed");
    }                    
}