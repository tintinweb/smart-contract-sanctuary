// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./CErc20Delegator.sol";
import "./ComptrollerInterface.sol";

/// @title High level system for fixed bunker
library HLS_fixed {

// ------------------------------------------------- public variables ---------------------------------------------------

    using SafeMath for uint256;

    // Position
    struct Position {
        uint256 token_amount;
        uint256 crtoken_amount; // balanceOf(supply_crtoken)
        uint256 supply_amount; // 紀錄supply給cream多少

        address token; // user deposit into charge ,  在boost時用來當作計算token_a,token_b的價值基準
        address supply_crtoken; // 類似我們的cashbox address
        
        uint256 funds_percentage; // 從cashbox離開的錢的百分比
        uint256 total_debts; // 所有在buncker外面的錢
    }

// --------------------------------------------------- fixed buncker ----------------------------------------------------


    /// @dev Supplies 'amount' worth of tokens to cream.
    function _supplyCream(Position memory _position) private returns(Position memory) {
        uint256 supply_amount = IERC20(_position.token).balanceOf(address(this)).mul(_position.funds_percentage).div(100);
        
        // Approve for Cream borrow 
        IERC20(_position.token).approve(_position.supply_crtoken, supply_amount);
        require(CErc20Delegator(_position.supply_crtoken).mint(supply_amount) == 0, "Supply not work");

        // Update posititon amount data
        _position.token_amount = IERC20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_amount = supply_amount;

        return _position;
    }

    /// @dev Redeem amount worth of crtokens back.
    function _redeemCream(Position memory _position) private returns (Position memory) {
        uint256 redeem_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));

        // Approve for Cream redeem
        IERC20(_position.supply_crtoken).approve(_position.supply_crtoken, redeem_amount);
        require(CErc20Delegator(_position.supply_crtoken).redeem(redeem_amount) == 0, "Redeem not work");

        // Update posititon amount data
        _position.token_amount = IERC20(_position.token).balanceOf(address(this));
        _position.crtoken_amount = IERC20(_position.supply_crtoken).balanceOf(address(this));
        _position.supply_amount = 0;

        return _position;
    }

    /// @dev Main entry function to borrow and enter a given position.
    function enterPositionFixed(Position memory _position) external returns (Position memory) { 
        // Supply position
        _position = _supplyCream(_position);
        _position.total_debts = getTotalDebtsFixed(_position);

        return _position;
    }

    /// @dev Main exit function to exit and repay a given position.
    function exitPositionFixed(Position memory _position) external returns (Position memory) {
        // Redeem
        _position = _redeemCream(_position);
        _position.total_debts = getTotalDebtsFixed(_position);

        return _position;
    }


    /// @dev Return total debts for fixed bunker.
    function getTotalDebtsFixed(Position memory _position) private pure returns (uint256) {
        
        return _position.supply_amount;
    }


}