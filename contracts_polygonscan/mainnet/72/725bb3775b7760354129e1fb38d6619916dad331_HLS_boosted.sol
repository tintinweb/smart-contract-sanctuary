// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./IQuickRouter02.sol";
import "./IDquick.sol";
import "./IQuickPair.sol";

import "./IQuickSingleStakingReward.sol";
import "./IQuickDualStakingReward.sol";


/// @title High level system for boosted bunker
library HLS_boosted {    

// ------------------------------------------------- public variables ---------------------------------------------------

    using SafeMath for uint256;

    // HighLevelSystem config
    struct HLSConfig {
        address router; // Address of Quickswap router contract : 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        address staking_reward ; // Determined by bool singleFarm, if true=> single staking reward, if falee=> dual staking reward
        address dQuick_addr ;
    }
    
    // Position
    struct Position {

        address token_a; // user deposit into boost
        address token_b; // user deposit into boost
        address lp_token; // after adding liq into pancake , get lp_token, 就是pancake pair address

        uint256 token_a_amount; // deNormalized
        uint256 token_b_amount; // deNormalized
        uint256 lp_token_amount;
        uint256 liquidity_a;
        uint256 liquidity_b;

        uint256 funds_percentage; // 從cashbox離開的錢的百分比
        uint256 total_debts; // 所有在buncker外面的錢
    }

// ------------------ boosted buncker manipulative function -------------------

    function _addLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {


        (uint256 max_available_staking_a, uint256 max_available_staking_b) = getFreeFunds(_position.token_a, _position.token_b, _position.funds_percentage, false, false);
        
        uint256 max_available_staking_a_slippage = max_available_staking_a.mul(98).div(100);
        uint256 max_available_staking_b_slippage = max_available_staking_b.mul(98).div(100);

        (uint256 reserves0, uint256 reserves1, ) = IQuickPair(_position.lp_token).getReserves();
        uint256 min_a_amnt = IQuickRouter02(self.router).quote(max_available_staking_b_slippage, reserves1, reserves0);
        uint256 min_b_amnt = IQuickRouter02(self.router).quote(max_available_staking_a_slippage, reserves0, reserves1);

        min_a_amnt = max_available_staking_a_slippage.min(min_a_amnt);
        min_b_amnt = max_available_staking_b_slippage.min(min_b_amnt);

        // Approve for PancakeSwap addliquidity
        IERC20(_position.token_a).approve(self.router, max_available_staking_a);
        IERC20(_position.token_b).approve(self.router, max_available_staking_b);
        (uint256 liquidity_a, uint256 liquidity_b, ) = IQuickRouter02(self.router).addLiquidity(_position.token_a, _position.token_b, max_available_staking_a, max_available_staking_b, min_a_amnt, min_b_amnt, address(this), block.timestamp);
        
        // Update posititon amount data
        _position.liquidity_a = liquidity_a;
        _position.liquidity_b = liquidity_b;
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @dev Stakes LP tokens into a farm.
    function _stake(HLSConfig memory self, Position memory _position, bool _single) private {

        uint256 stake_amount = IERC20(_position.lp_token).balanceOf(address(this));
        IERC20(_position.lp_token).approve(self.staking_reward, stake_amount);

        if (_single==true) {
            
            IQuickSingleStakingReward(self.staking_reward).stake(stake_amount);
        }
        else if (_single==false){
            IQuickDualStakingReward(self.staking_reward).stake(stake_amount);
        }

    }

    function _removeLiquidity(HLSConfig memory self, Position memory _position) private returns (Position memory) {
        uint256 token_a_amnt = 0;
        uint256 token_b_amnt = 0;

        IERC20(_position.lp_token).approve(self.router, _position.lp_token_amount);
        IQuickRouter02(self.router).removeLiquidity(_position.token_a, _position.token_b, _position.lp_token_amount, token_a_amnt, token_b_amnt, address(this), block.timestamp);


        // Update posititon amount data
        _position.liquidity_a = 0;
        _position.liquidity_b = 0;
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));
        _position.token_a_amount = IERC20(_position.token_a).balanceOf(address(this));
        _position.token_b_amount = IERC20(_position.token_b).balanceOf(address(this));

        return _position;
    }

    /// @dev Removes liquidity from a given farm.
    function _unstake(HLSConfig memory self, Position memory _position, bool _single) private returns (Position memory) {
        
        uint256 unstake_amount;

        if (_single==true) {
            unstake_amount = IQuickSingleStakingReward(self.staking_reward).balanceOf(address(this));
            IQuickSingleStakingReward(self.staking_reward).withdraw(unstake_amount);
        }
        else if (_single==false){
            unstake_amount = IQuickDualStakingReward(self.staking_reward).balanceOf(address(this));
            IQuickDualStakingReward(self.staking_reward).withdraw(unstake_amount);
        }

        // Update posititon amount data
        _position.lp_token_amount = IERC20(_position.lp_token).balanceOf(address(this));

        return _position;
    }

    /// @dev Main entry function to stake and enter a given position.
    function enterPositionBoosted(HLSConfig memory self, Position memory _position, bool _singleFarm) external returns (Position memory) {
        
        _position = _addLiquidity(self, _position);

        _stake(self, _position, _singleFarm);
        
        _position.total_debts = getTotalDebtsBoosted(_position);

        return _position;
    }

    /// @dev Main exit function to exit and unstake a given position.
    function exitPositionBoosted(HLSConfig memory self, Position memory _position, bool _singleFarm) external returns (Position memory) {
        
        _position = _unstake(self, _position, _singleFarm);

        _position = _removeLiquidity(self, _position);

        _position.total_debts = getTotalDebtsBoosted(_position);

        return _position;
    }

    /// @dev Auto swap "Quick" or WMATIC back to some token desird.
    function autoCompound(address _router , uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        uint256 amountInSlippage = _amountIn.mul(98).div(100);
        uint256[] memory amountOutMinArray = IQuickRouter02(_router).getAmountsOut(amountInSlippage, _path);
        uint256 amountOutMin = amountOutMinArray[amountOutMinArray.length - 1];
        address token = _path[0];
        if (_wrapType == 1) {
            IERC20(token).approve(_router, _amountIn);
            IQuickRouter02(_router).swapExactTokensForTokens(_amountIn, amountOutMin, _path, address(this), block.timestamp);    
        } else if (_wrapType == 2) {
            IERC20(token).approve(_router, _amountIn);
            IQuickRouter02(_router).swapExactTokensForETH(_amountIn, amountOutMin, _path, address(this), block.timestamp);
        } else if (_wrapType == 3) {
            IQuickRouter02(_router).swapExactETHForTokens{value: _amountIn}(amountOutMin, _path, address(this), block.timestamp);
        }
    }

    /// @dev claim dQuick (and WMATIC, if it's dual farm) , transfer dQUick into Quick
    function claimReward(address _staking_reward, address _dQuick, bool _singleFarm) external {

        if ( _singleFarm == true ) {
            IQuickSingleStakingReward(_staking_reward).getReward() ;
        }

        else if ( _singleFarm == false) {  
            IQuickDualStakingReward(_staking_reward).getReward() ;
        }

        uint256 dQuick_balance = IDquick(_dQuick).balanceOf(address(this));
        IDquick(_dQuick).leave(dQuick_balance);

    }


// --------------------- boosted buncker getter function ---------------------

    /// @dev Get Free Funds in bunker , or get the amount needed to enter position
    function getFreeFunds(address token_a, address token_b, uint256 _enterPercentage, bool _getAll, bool _getNormalized) public view returns(uint256, uint256){

        if( _getNormalized == true ) {
            uint256 _a_amt = IERC20(token_a).balanceOf(address(this)) ;
            uint256 _b_amt = IERC20(token_b).balanceOf(address(this));
            uint256 a_norm_amt = _a_amt.mul(10**18).div(10**IERC20(token_a).decimals());
            uint256 b_norm_amt = _b_amt.mul(10**18).div(10**IERC20(token_b).decimals());

            if( _getAll == true ) {
                // return all FreeFunds in cashbox
                return ( a_norm_amt , b_norm_amt );
            }

            else if( _getAll == false ) {
                // return enter_amounts needed to add liquidity
                    return ( a_norm_amt.mul(_enterPercentage).div(100) , b_norm_amt.mul(_enterPercentage).div(100) ) ;
            }

        }

        if( _getNormalized == false ) {
            if( _getAll == true ) {
                // return all FreeFunds in cashbox
                return (
                    IERC20(token_a).balanceOf(address(this)),
                    IERC20(token_b).balanceOf(address(this))
                );
            }

            else if( _getAll == false ) {
                // return enter_amounts needed to add liquidity
                    return (
                        (IERC20(token_a).balanceOf(address(this))).mul(_enterPercentage).div(100),
                        (IERC20(token_b).balanceOf(address(this))).mul(_enterPercentage).div(100)
                    );
            }
        }

    }

    /// @dev Get total value outside of boosted bunker.
    function getTotalDebtsBoosted(Position memory _position) public view returns (uint256) {
        // PancakeSwap staked amount
        (uint256 token_a_amount, uint256 token_b_amount) = getStakedTokenAmount(_position);
        uint256 lp_token_amount = getLpTokenAmountOut(_position.lp_token, token_a_amount, token_b_amount);
        return lp_token_amount;
    }

    //// @dev Get total token "deNormalized" amount that has been added into Quickswap's liquidity pool 
    function getStakedTokenAmount(Position memory _position) private view returns (uint256, uint256) {

        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_position.lp_token).getReserves();
        uint256 total_supply = IQuickPair(_position.lp_token).totalSupply();
        uint256 token_a_amnt = reserve0.mul(_position.lp_token_amount).div(total_supply);
        uint256 token_b_amnt = reserve1.mul(_position.lp_token_amount).div(total_supply);

        return (token_a_amnt, token_b_amnt);

    }

    /** @dev when called from script, given one of the deNormalized input amount, get the other deNormalized input amount needed, and get Normalized total Value of these two inputs.
        @dev when called from this contract, amounts are the same as the inputs, and get Normalized total Value of these two inputs.
        @param _a_amt: deNormalized
        @param _b_amt: deNormalized
        @return _token_a_amount: deNormalized
        @return _token_b_amount: deNormalized
     */
    function getUpdatedAmount(HLSConfig memory self, Position memory _position, uint256 _a_amt, uint256 _b_amt) external view returns (uint256 , uint256 , uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_position.lp_token).getReserves();
        if (_a_amt == 0 && _b_amt > 0) {
            _a_amt = IQuickRouter02(self.router).quote(_b_amt, reserve1, reserve0);
        } else if (_a_amt > 0 && _b_amt == 0) {
            _b_amt = IQuickRouter02(self.router).quote(_a_amt, reserve0, reserve1);            
        } else {
            revert("Input amount incorrect");
        }

        uint256 lp_token_amount = getLpTokenAmountOut(_position.lp_token, _a_amt, _b_amt);

        return (_a_amt, _b_amt, lp_token_amount);
    }

    /// @param _lp_token Quickswap LP token address.
    /// @param _token_a_amount Quickswap pair token a amount.
    /// @param _token_b_amount Quickswap pair token b amount.
    /// @dev Return LP token amount.
    function getLpTokenAmountOut(address _lp_token, uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IQuickPair(_lp_token).getReserves();
        uint256 totalSupply = IQuickPair(_lp_token).totalSupply();
        uint256 token_a_lp_amount = _token_a_amount.mul(totalSupply).div(reserve0);
        uint256 token_b_lp_amount = _token_b_amount.mul(totalSupply).div(reserve1);
        uint256 lp_token_amount = token_a_lp_amount.min(token_b_lp_amount);
        
        return lp_token_amount;
    }

    /// @param _lp_token PancakeSwap LP token address.
    /// @param _lp_token_amount PancakeSwap LP token amount.
    /// @dev Return Pair tokens amount.
    function getLpTokenAmountIn(address _lp_token, uint256 _lp_token_amount) public view returns (uint256, uint256) {
        address token_a = IQuickPair(_lp_token).token0();
        address token_b = IQuickPair(_lp_token).token1();
        uint256 balance_a = IERC20(token_a).balanceOf(_lp_token);
        uint256 balance_b = IERC20(token_b).balanceOf(_lp_token);
        uint256 totalSupply = IQuickPair(_lp_token).totalSupply();
        
        return (_lp_token_amount.mul(balance_a).div(totalSupply), _lp_token_amount.mul(balance_b).div(totalSupply));
    }

}